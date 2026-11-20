package wallet

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"sort"

	"github.com/maillunex-lang/number5/server/internal/domain"
	"github.com/maillunex-lang/number5/server/internal/store"
)

type Service struct {
	Store          store.Store
	ConfigVersion  string
	AllowTestGrant bool
}

type WalletResponse struct {
	Balances      []domain.Balance `json:"balances"`
	ConfigVersion string           `json:"config_version"`
}

type GrantRequest struct {
	ResourceID     string `json:"resource_id"`
	Amount         int64  `json:"amount"`
	IdempotencyKey string `json:"idempotency_key"`
	SourceType     string `json:"source_type"`
	SourceID       string `json:"source_id"`
}

type GrantResponse struct {
	Balances []domain.Balance `json:"balances"`
	Replayed bool             `json:"replayed"`
	Granted  int64            `json:"granted"`
	Resource string           `json:"resource_id"`
}

type idemPatcher interface {
	PatchIdempotencyResponse(accountID domain.AccountID, key string, body []byte, status int) error
}

func (s *Service) Get(accountID domain.AccountID) (WalletResponse, error) {
	b, err := s.Store.WalletBalances(accountID)
	if err != nil {
		return WalletResponse{}, err
	}
	sort.Slice(b, func(i, j int) bool { return b[i].ResourceID < b[j].ResourceID })
	return WalletResponse{Balances: b, ConfigVersion: s.ConfigVersion}, nil
}

func (s *Service) GrantTestAtomic(accountID domain.AccountID, req GrantRequest) (status int, body []byte, err error) {
	if !s.AllowTestGrant {
		return 403, errJSON("forbidden", "test grant disabled"), nil
	}
	if req.Amount <= 0 || req.ResourceID == "" || req.IdempotencyKey == "" {
		return 422, errJSON("invalid", "resource_id, amount>0, idempotency_key required"), nil
	}
	if req.SourceType == "" {
		req.SourceType = "test_grant"
	}
	if req.SourceID == "" {
		req.SourceID = req.IdempotencyKey
	}
	hash := hashGrant(req)

	if rec, e := s.Store.GetIdempotency(accountID, req.IdempotencyKey); e == nil {
		if rec.RequestHash != hash {
			return 409, errJSON("conflict", "idempotency key reused with different payload"), nil
		}
		// Mark replay in response copy without mutating ledger.
		var cached GrantResponse
		if json.Unmarshal(rec.ResponseJSON, &cached) == nil {
			cached.Replayed = true
			return rec.StatusCode, mustJSON(cached), nil
		}
		return rec.StatusCode, rec.ResponseJSON, nil
	}

	entry := domain.LedgerEntry{
		ResourceID:    req.ResourceID,
		Delta:         req.Amount,
		SourceType:    req.SourceType,
		SourceID:      req.SourceID,
		ConfigVersion: s.ConfigVersion,
	}
	replayed, err := s.Store.ApplyLedger(accountID, []domain.LedgerEntry{entry}, req.IdempotencyKey, hash, []byte(`{}`), 200)
	if err != nil {
		if err == store.ErrConflict {
			return 409, errJSON("conflict", err.Error()), nil
		}
		return 500, errJSON("internal", err.Error()), nil
	}
	balances, err := s.Store.WalletBalances(accountID)
	if err != nil {
		return 500, errJSON("internal", err.Error()), nil
	}
	sort.Slice(balances, func(i, j int) bool { return balances[i].ResourceID < balances[j].ResourceID })
	out := GrantResponse{Balances: balances, Replayed: replayed, Granted: req.Amount, Resource: req.ResourceID}
	body = mustJSON(out)
	if patcher, ok := s.Store.(idemPatcher); ok {
		_ = patcher.PatchIdempotencyResponse(accountID, req.IdempotencyKey, body, 200)
	}
	return 200, body, nil
}

func hashGrant(req GrantRequest) string {
	raw := fmt.Sprintf("%s|%d|%s|%s|%s", req.ResourceID, req.Amount, req.SourceType, req.SourceID, req.IdempotencyKey)
	sum := sha256.Sum256([]byte(raw))
	return hex.EncodeToString(sum[:])
}

func mustJSON(v any) []byte {
	b, _ := json.Marshal(v)
	return b
}

func errJSON(code, message string) []byte {
	return mustJSON(map[string]any{"error": map[string]string{"code": code, "message": message}})
}
