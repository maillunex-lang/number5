package afk

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

type StatusResponse struct {
	AccumulatedSec int64            `json:"accumulated_sec"`
	CapSec         int64            `json:"cap_sec"`
	Preview        map[string]int64 `json:"preview"`
	Chapter        int              `json:"chapter"`
	LastClaimAt    string           `json:"last_claim_at"`
	CanClaim       bool             `json:"can_claim"`
}

type ClaimResponse struct {
	Rewards  map[string]int64 `json:"rewards"`
	Replayed bool             `json:"replayed"`
	Status   StatusResponse   `json:"status"`
}

func (s *Service) now() time.Time {
	if s.Clock != nil {
		return s.Clock.Now()
	}
	return time.Now().UTC()
}

func (s *Service) Status(accountID domain.AccountID) (StatusResponse, error) {
	st, err := s.Store.GetAFK(accountID)
	if err != nil {
		return StatusResponse{}, err
	}
	cfg := s.Catalog.Liveops.AFK
	capSec := int64(cfg.CapHours * 3600)
	elapsed := int64(s.now().Sub(st.LastClaimAt).Seconds())
	if elapsed < 0 {
		elapsed = 0
	}
	if elapsed > capSec {
		elapsed = capSec
	}
	rate := s.rateFor(st.Chapter)
	preview := map[string]int64{
		"gold":     rate.GoldPerHour * elapsed / 3600,
		"hero_xp":  rate.HeroXPPerHour * elapsed / 3600,
		"essence":  rate.EssencePerHour * elapsed / 3600,
	}
	return StatusResponse{
		AccumulatedSec: elapsed,
		CapSec:         capSec,
		Preview:        preview,
		Chapter:        st.Chapter,
		LastClaimAt:    st.LastClaimAt.Format(time.RFC3339),
		CanClaim:       elapsed >= int64(cfg.MinClaimSeconds),
	}, nil
}

func (s *Service) Claim(accountID domain.AccountID, idempotencyKey string) (status int, body []byte, err error) {
	if idempotencyKey == "" {
		return 422, errJSON("invalid", "idempotency_key required"), nil
	}
	hash := hashKey(idempotencyKey)
	if rec, e := s.Store.GetIdempotency(accountID, idempotencyKey); e == nil {
		if rec.RequestHash != hash {
			return 409, errJSON("conflict", "idempotency key reused"), nil
		}
		var cached ClaimResponse
		_ = json.Unmarshal(rec.ResponseJSON, &cached)
		cached.Replayed = true
		return rec.StatusCode, mustJSON(cached), nil
	}

	stStatus, err := s.Status(accountID)
	if err != nil {
		return 500, errJSON("internal", err.Error()), nil
	}
	if !stStatus.CanClaim {
		return 422, errJSON("too_early", "min claim interval not reached"), nil
	}
	rewards := stStatus.Preview
	entries := make([]domain.LedgerEntry, 0, len(rewards))
	for rid, amt := range rewards {
		if amt <= 0 {
			continue
		}
		entries = append(entries, domain.LedgerEntry{
			ResourceID: rid, Delta: amt, SourceType: "afk_claim", SourceID: idempotencyKey,
			ConfigVersion: s.Catalog.Version,
		})
	}
	_, err = s.Store.ApplyLedger(accountID, entries, idempotencyKey, hash, []byte(`{}`), 200)
	if err != nil {
		if err == store.ErrConflict {
			return 409, errJSON("conflict", err.Error()), nil
		}
		return 500, errJSON("internal", err.Error()), nil
	}
	st, _ := s.Store.GetAFK(accountID)
	st.LastClaimAt = s.now()
	_ = s.Store.SetAFK(accountID, st)
	newStatus, _ := s.Status(accountID)
	out := ClaimResponse{Rewards: rewards, Status: newStatus}
	body = mustJSON(out)
	if patcher, ok := s.Store.(interface {
		PatchIdempotencyResponse(domain.AccountID, string, []byte, int) error
	}); ok {
		_ = patcher.PatchIdempotencyResponse(accountID, idempotencyKey, body, 200)
	}
	return 200, body, nil
}

func (s *Service) rateFor(chapter int) content.AFKRate {
	var best content.AFKRate
	for _, r := range s.Catalog.Liveops.AFK.RatesByChapter {
		if r.Chapter <= chapter && r.Chapter >= best.Chapter {
			best = r
		}
	}
	if best.Chapter == 0 && len(s.Catalog.Liveops.AFK.RatesByChapter) > 0 {
		return s.Catalog.Liveops.AFK.RatesByChapter[0]
	}
	return best
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
