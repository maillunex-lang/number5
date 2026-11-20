package store

import (
	"errors"

	"github.com/maillunex-lang/number5/server/internal/domain"
)

var (
	ErrNotFound      = errors.New("not found")
	ErrConflict      = errors.New("conflict")
	ErrUnauthorized  = errors.New("unauthorized")
	ErrInsufficient  = errors.New("insufficient funds")
)

// Store is the persistence boundary. Memory now; Postgres later (TZ-A §3).
type Store interface {
	CreateGuest() (domain.Account, domain.Session, error)
	AccountBySession(token string) (domain.Account, error)

	WalletBalances(accountID domain.AccountID) ([]domain.Balance, error)
	// ApplyLedger applies deltas atomically with idempotency on (account, key, resource, source_type).
	// Same key+same params → replay; same key+different params → ErrConflict.
	ApplyLedger(accountID domain.AccountID, entries []domain.LedgerEntry, idempotencyKey, requestHash string, response []byte, statusCode int) (replayed bool, err error)
	GetIdempotency(accountID domain.AccountID, key string) (domain.IdempotencyRecord, error)
}
