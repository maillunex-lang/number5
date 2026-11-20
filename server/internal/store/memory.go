package store

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"sync"
	"time"

	"github.com/maillunex-lang/number5/server/internal/domain"
)

type Memory struct {
	mu       sync.Mutex
	accounts map[domain.AccountID]domain.Account
	sessions map[string]domain.Session
	wallet   map[domain.AccountID]map[string]domain.Balance
	ledger   []domain.LedgerEntry
	idem     map[string]domain.IdempotencyRecord // accountID|key
	starter  []domain.Balance
}

func NewMemory(starter []domain.Balance) *Memory {
	if starter == nil {
		starter = DefaultStarterBalances()
	}
	return &Memory{
		accounts: map[domain.AccountID]domain.Account{},
		sessions: map[string]domain.Session{},
		wallet:   map[domain.AccountID]map[string]domain.Balance{},
		idem:     map[string]domain.IdempotencyRecord{},
		starter:  starter,
	}
}

func DefaultStarterBalances() []domain.Balance {
	return []domain.Balance{
		{ResourceID: "gold", Amount: 100_000},
		{ResourceID: "diamonds", Amount: 600},
		{ResourceID: "hero_xp", Amount: 20_000},
		{ResourceID: "essence", Amount: 500},
		{ResourceID: "summon_scroll", Amount: 10},
	}
}

func (m *Memory) CreateGuest() (domain.Account, domain.Session, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	id := domain.AccountID(newID("acc"))
	acc := domain.Account{
		ID:        id,
		IsGuest:   true,
		Status:    "active",
		CreatedAt: time.Now().UTC(),
	}
	m.accounts[id] = acc
	tok := newID("tok")
	sess := domain.Session{
		Token:     tok,
		AccountID: id,
		ExpiresAt: time.Now().UTC().Add(30 * 24 * time.Hour),
	}
	m.sessions[tok] = sess
	w := map[string]domain.Balance{}
	for _, b := range m.starter {
		w[b.ResourceID] = domain.Balance{ResourceID: b.ResourceID, Amount: b.Amount, Version: 1}
		m.ledger = append(m.ledger, domain.LedgerEntry{
			ID:             newID("led"),
			AccountID:      id,
			ResourceID:     b.ResourceID,
			Delta:          b.Amount,
			SourceType:     "starter",
			SourceID:       "guest_create",
			IdempotencyKey: "starter:" + string(id) + ":" + b.ResourceID,
			CreatedAt:      time.Now().UTC(),
		})
	}
	m.wallet[id] = w
	return acc, sess, nil
}

func (m *Memory) AccountBySession(token string) (domain.Account, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	sess, ok := m.sessions[token]
	if !ok || time.Now().UTC().After(sess.ExpiresAt) {
		return domain.Account{}, ErrUnauthorized
	}
	acc, ok := m.accounts[sess.AccountID]
	if !ok || acc.Status != "active" {
		return domain.Account{}, ErrUnauthorized
	}
	return acc, nil
}

func (m *Memory) WalletBalances(accountID domain.AccountID) ([]domain.Balance, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	w, ok := m.wallet[accountID]
	if !ok {
		return nil, ErrNotFound
	}
	out := make([]domain.Balance, 0, len(w))
	for _, b := range w {
		out = append(out, b)
	}
	return out, nil
}

func (m *Memory) GetIdempotency(accountID domain.AccountID, key string) (domain.IdempotencyRecord, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	rec, ok := m.idem[idemKey(accountID, key)]
	if !ok {
		return domain.IdempotencyRecord{}, ErrNotFound
	}
	return rec, nil
}

func (m *Memory) ApplyLedger(
	accountID domain.AccountID,
	entries []domain.LedgerEntry,
	idempotencyKey, requestHash string,
	response []byte,
	statusCode int,
) (bool, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	ik := idemKey(accountID, idempotencyKey)
	if rec, ok := m.idem[ik]; ok {
		if rec.RequestHash != requestHash {
			return false, ErrConflict
		}
		return true, nil
	}

	w, ok := m.wallet[accountID]
	if !ok {
		return false, ErrNotFound
	}
	// validate
	for _, e := range entries {
		cur := w[e.ResourceID]
		if cur.Amount+e.Delta < 0 {
			return false, ErrInsufficient
		}
	}
	now := time.Now().UTC()
	for _, e := range entries {
		cur := w[e.ResourceID]
		cur.ResourceID = e.ResourceID
		cur.Amount += e.Delta
		cur.Version++
		w[e.ResourceID] = cur
		e.ID = newID("led")
		e.AccountID = accountID
		e.IdempotencyKey = idempotencyKey
		e.CreatedAt = now
		m.ledger = append(m.ledger, e)
	}
	m.wallet[accountID] = w
	m.idem[ik] = domain.IdempotencyRecord{
		AccountID:    accountID,
		Key:          idempotencyKey,
		RequestHash:  requestHash,
		ResponseJSON: append([]byte(nil), response...),
		StatusCode:   statusCode,
		CreatedAt:    now,
	}
	return false, nil
}

func (m *Memory) PatchIdempotencyResponse(accountID domain.AccountID, key string, body []byte, status int) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	ik := idemKey(accountID, key)
	rec, ok := m.idem[ik]
	if !ok {
		return ErrNotFound
	}
	rec.ResponseJSON = append([]byte(nil), body...)
	rec.StatusCode = status
	m.idem[ik] = rec
	return nil
}

func idemKey(accountID domain.AccountID, key string) string {
	return string(accountID) + "|" + key
}

func newID(prefix string) string {
	var b [8]byte
	_, _ = rand.Read(b[:])
	return fmt.Sprintf("%s_%s", prefix, hex.EncodeToString(b[:]))
}
