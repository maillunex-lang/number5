package store

import (
	"errors"
	"time"

	"github.com/maillunex-lang/number5/server/internal/domain"
)

var (
	ErrNotFound     = errors.New("not found")
	ErrConflict     = errors.New("conflict")
	ErrUnauthorized = errors.New("unauthorized")
	ErrInsufficient = errors.New("insufficient funds")
	ErrForbidden    = errors.New("forbidden")
)

// Store is the persistence boundary. Memory now; Postgres later (TZ-A §3).
type Store interface {
	CreateGuest(starterHeroes []string) (domain.Account, domain.Session, error)
	AccountBySession(token string) (domain.Account, error)

	WalletBalances(accountID domain.AccountID) ([]domain.Balance, error)
	ApplyLedger(accountID domain.AccountID, entries []domain.LedgerEntry, idempotencyKey, requestHash string, response []byte, statusCode int) (replayed bool, err error)
	GetIdempotency(accountID domain.AccountID, key string) (domain.IdempotencyRecord, error)

	ListHeroes(accountID domain.AccountID) ([]domain.HeroOwned, error)
	UpsertHero(accountID domain.AccountID, hero domain.HeroOwned) error
	GetFormation(accountID domain.AccountID, mode string) (domain.Formation, error)
	SetFormation(accountID domain.AccountID, form domain.Formation) error

	GetCampaign(accountID domain.AccountID) (domain.CampaignProgress, error)
	SaveCampaign(accountID domain.AccountID, prog domain.CampaignProgress) error

	SaveBattle(b domain.BattleInstance) error
	GetBattle(id string) (domain.BattleInstance, error)
	MarkBattleClaimed(id string) error

	GetPity(accountID domain.AccountID, bannerID string) (domain.PityState, error)
	SetPity(accountID domain.AccountID, pity domain.PityState) error

	GetAFK(accountID domain.AccountID) (domain.AFKState, error)
	SetAFK(accountID domain.AccountID, st domain.AFKState) error

	ListMail(accountID domain.AccountID) ([]domain.MailMessage, error)
	GetMail(accountID domain.AccountID, mailID string) (domain.MailMessage, error)
	SaveMail(accountID domain.AccountID, msg domain.MailMessage) error
	SeedMail(accountID domain.AccountID, msgs []domain.MailMessage) error

	SaveStoreOrder(order domain.StoreOrder) error
	GetStoreOrder(id string) (domain.StoreOrder, error)
}

type Clock interface {
	Now() time.Time
}

type RealClock struct{}

func (RealClock) Now() time.Time { return time.Now().UTC() }
