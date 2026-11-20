package mail

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"time"

	"github.com/maillunex-lang/number5/server/internal/domain"
	"github.com/maillunex-lang/number5/server/internal/modules/content"
	"github.com/maillunex-lang/number5/server/internal/store"
)

type Service struct {
	Store   store.Store
	Catalog *content.Catalog
	Clock   store.Clock
}

func (s *Service) now() time.Time {
	if s.Clock != nil {
		return s.Clock.Now()
	}
	return time.Now().UTC()
}

func (s *Service) SeedDemo(accountID domain.AccountID) error {
	existing, err := s.Store.ListMail(accountID)
	if err != nil {
		return err
	}
	if len(existing) > 0 {
		return nil
	}
	msgs := []domain.MailMessage{}
	for i, d := range s.Catalog.Mail.DemoInbox {
		status := "unread"
		if !d.Unread {
			status = "read"
		}
		atts := []domain.MailAttach{}
		if i == 0 {
			atts = []domain.MailAttach{{ResourceID: "diamonds", Amount: 50}}
		}
		id := d.ID
		if id == "" {
			id = store.NewID("mail")
		}
		msgs = append(msgs, domain.MailMessage{
			ID: id, TemplateID: d.TemplateID, Category: d.Category,
			Subject: d.Title, Body: d.Body, Status: status,
			Attachments: atts, CreatedAt: s.now(),
		})
	}
	if len(msgs) == 0 {
		msgs = append(msgs, domain.MailMessage{
			ID: store.NewID("mail"), TemplateID: "MAIL_WELCOME", Category: "system",
			Subject: "Добро пожаловать", Body: "Стартовый подарок", Status: "unread",
			Attachments: []domain.MailAttach{{ResourceID: "gold", Amount: 1000}},
			CreatedAt: s.now(),
		})
	}
	return s.Store.SeedMail(accountID, msgs)
}

type ListResponse struct {
	Messages []domain.MailMessage `json:"messages"`
	Unread   int                  `json:"unread"`
}

func (s *Service) List(accountID domain.AccountID) (ListResponse, error) {
	_ = s.SeedDemo(accountID)
	msgs, err := s.Store.ListMail(accountID)
	if err != nil {
		return ListResponse{}, err
	}
	unread := 0
	for _, m := range msgs {
		if m.Status == "unread" {
			unread++
		}
	}
	return ListResponse{Messages: msgs, Unread: unread}, nil
}

type ClaimResponse struct {
	MailID   string           `json:"mail_id"`
	Rewards  map[string]int64 `json:"rewards"`
	Replayed bool             `json:"replayed"`
}

type ClaimAllResponse struct {
	Claimed []ClaimResponse `json:"claimed"`
	Count   int             `json:"count"`
	Replayed bool           `json:"replayed,omitempty"`
}

func (s *Service) ClaimAll(accountID domain.AccountID, idempotencyKey string) (status int, body []byte, err error) {
	if idempotencyKey == "" {
		return 422, errJSON("invalid", "idempotency_key required"), nil
	}
	hash := hashKey("claim-all|" + idempotencyKey)
	if rec, e := s.Store.GetIdempotency(accountID, idempotencyKey); e == nil {
		if rec.RequestHash != hash {
			return 409, errJSON("conflict", "idempotency key reused"), nil
		}
		var cached ClaimAllResponse
		_ = json.Unmarshal(rec.ResponseJSON, &cached)
		cached.Replayed = true
		return rec.StatusCode, mustJSON(cached), nil
	}
	_ = s.SeedDemo(accountID)
	msgs, err := s.Store.ListMail(accountID)
	if err != nil {
		return 500, errJSON("internal", err.Error()), nil
	}
	claimed := []ClaimResponse{}
	entries := []domain.LedgerEntry{}
	for _, msg := range msgs {
		if msg.Status == "claimed" {
			continue
		}
		rewards := map[string]int64{}
		has := false
		for i, a := range msg.Attachments {
			if a.Claimed || a.Amount <= 0 {
				continue
			}
			has = true
			rewards[a.ResourceID] += a.Amount
			entries = append(entries, domain.LedgerEntry{
				ResourceID: a.ResourceID, Delta: a.Amount,
				SourceType: "mail_claim_all", SourceID: msg.ID,
				ConfigVersion: s.Catalog.Version,
			})
			msg.Attachments[i].Claimed = true
		}
		if !has && len(msg.Attachments) == 0 {
			msg.Status = "claimed"
			_ = s.Store.SaveMail(accountID, msg)
			continue
		}
		if !has {
			continue
		}
		msg.Status = "claimed"
		_ = s.Store.SaveMail(accountID, msg)
		claimed = append(claimed, ClaimResponse{MailID: msg.ID, Rewards: rewards})
	}
	_, err = s.Store.ApplyLedger(accountID, entries, idempotencyKey, hash, []byte(`{}`), 200)
	if err != nil {
		if err == store.ErrConflict {
			return 409, errJSON("conflict", err.Error()), nil
		}
		return 500, errJSON("internal", err.Error()), nil
	}
	out := ClaimAllResponse{Claimed: claimed, Count: len(claimed)}
	body = mustJSON(out)
	if patcher, ok := s.Store.(interface {
		PatchIdempotencyResponse(domain.AccountID, string, []byte, int) error
	}); ok {
		_ = patcher.PatchIdempotencyResponse(accountID, idempotencyKey, body, 200)
	}
	return 200, body, nil
}

func (s *Service) Claim(accountID domain.AccountID, mailID, idempotencyKey string) (status int, body []byte, err error) {
	if mailID == "" || idempotencyKey == "" {
		return 422, errJSON("invalid", "mail id and idempotency_key required"), nil
	}
	hash := hashKey(mailID + "|" + idempotencyKey)
	if rec, e := s.Store.GetIdempotency(accountID, idempotencyKey); e == nil {
		if rec.RequestHash != hash {
			return 409, errJSON("conflict", "idempotency key reused"), nil
		}
		var cached ClaimResponse
		_ = json.Unmarshal(rec.ResponseJSON, &cached)
		cached.Replayed = true
		return rec.StatusCode, mustJSON(cached), nil
	}
	msg, err := s.Store.GetMail(accountID, mailID)
	if err != nil {
		return 404, errJSON("not_found", "mail"), nil
	}
	if msg.Status == "claimed" {
		return 409, errJSON("conflict", "already claimed"), nil
	}
	rewards := map[string]int64{}
	entries := []domain.LedgerEntry{}
	for i, a := range msg.Attachments {
		if a.Claimed || a.Amount <= 0 {
			continue
		}
		rewards[a.ResourceID] += a.Amount
		entries = append(entries, domain.LedgerEntry{
			ResourceID: a.ResourceID, Delta: a.Amount,
			SourceType: "mail_claim", SourceID: mailID,
			ConfigVersion: s.Catalog.Version,
		})
		msg.Attachments[i].Claimed = true
	}
	_, err = s.Store.ApplyLedger(accountID, entries, idempotencyKey, hash, []byte(`{}`), 200)
	if err != nil {
		if err == store.ErrConflict {
			return 409, errJSON("conflict", err.Error()), nil
		}
		return 500, errJSON("internal", err.Error()), nil
	}
	msg.Status = "claimed"
	_ = s.Store.SaveMail(accountID, msg)
	out := ClaimResponse{MailID: mailID, Rewards: rewards}
	body = mustJSON(out)
	if patcher, ok := s.Store.(interface {
		PatchIdempotencyResponse(domain.AccountID, string, []byte, int) error
	}); ok {
		_ = patcher.PatchIdempotencyResponse(accountID, idempotencyKey, body, 200)
	}
	return 200, body, nil
}

func hashKey(key string) string {
	sum := sha256.Sum256([]byte(key))
	return hex.EncodeToString(sum[:])
}

func mustJSON(v any) []byte {
	b, _ := json.Marshal(v)
	return b
}

func errJSON(code, message string) []byte {
	return mustJSON(map[string]any{"error": map[string]string{"code": code, "message": message}})
}
