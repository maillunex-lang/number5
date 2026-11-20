package store

import "github.com/maillunex-lang/number5/server/internal/domain"

// Ops is the mutation surface available inside RunAtomic.
// All calls share one transaction (Postgres) or one mutex critical section (Memory).
type Ops interface {
	ApplyLedger(entries []domain.LedgerEntry, idempotencyKey, requestHash string, response []byte, statusCode int) (replayed bool, err error)
	PatchIdempotencyResponse(key string, body []byte, status int) error
	GetIdempotency(key string) (domain.IdempotencyRecord, error)

	MarkBattleClaimed(id string) error
	SaveCampaign(prog domain.CampaignProgress) error
	SetAFK(st domain.AFKState) error
	SaveMail(msg domain.MailMessage) error
	UpsertHero(hero domain.HeroOwned) error
	SetPity(pity domain.PityState) error
	SaveStoreOrder(order domain.StoreOrder) error

	GetBattle(id string) (domain.BattleInstance, error)
	GetCampaign() (domain.CampaignProgress, error)
	GetAFK() (domain.AFKState, error)
	GetMail(mailID string) (domain.MailMessage, error)
	ListHeroes() ([]domain.HeroOwned, error)
	GetPity(bannerID string) (domain.PityState, error)
	GetStoreOrder(id string) (domain.StoreOrder, error)
	WalletBalances() ([]domain.Balance, error)
}

// Runner stores that can run multi-step economy mutations atomically.
type Runner interface {
	RunAtomic(accountID domain.AccountID, fn func(Ops) error) error
}

// Run executes fn atomically when s implements Runner; otherwise runs sequentially
// through a Store-backed adapter (dev/memory fallback without nested TX).
func Run(s Store, accountID domain.AccountID, fn func(Ops) error) error {
	if r, ok := s.(Runner); ok {
		return r.RunAtomic(accountID, fn)
	}
	return fn(&storeOps{s: s, accountID: accountID})
}

type storeOps struct {
	s         Store
	accountID domain.AccountID
}

func (o *storeOps) ApplyLedger(entries []domain.LedgerEntry, idempotencyKey, requestHash string, response []byte, statusCode int) (bool, error) {
	return o.s.ApplyLedger(o.accountID, entries, idempotencyKey, requestHash, response, statusCode)
}

func (o *storeOps) PatchIdempotencyResponse(key string, body []byte, status int) error {
	if p, ok := o.s.(interface {
		PatchIdempotencyResponse(domain.AccountID, string, []byte, int) error
	}); ok {
		return p.PatchIdempotencyResponse(o.accountID, key, body, status)
	}
	return nil
}

func (o *storeOps) GetIdempotency(key string) (domain.IdempotencyRecord, error) {
	return o.s.GetIdempotency(o.accountID, key)
}

func (o *storeOps) MarkBattleClaimed(id string) error { return o.s.MarkBattleClaimed(id) }
func (o *storeOps) SaveCampaign(prog domain.CampaignProgress) error {
	return o.s.SaveCampaign(o.accountID, prog)
}
func (o *storeOps) SetAFK(st domain.AFKState) error { return o.s.SetAFK(o.accountID, st) }
func (o *storeOps) SaveMail(msg domain.MailMessage) error {
	return o.s.SaveMail(o.accountID, msg)
}
func (o *storeOps) UpsertHero(hero domain.HeroOwned) error {
	return o.s.UpsertHero(o.accountID, hero)
}
func (o *storeOps) SetPity(pity domain.PityState) error { return o.s.SetPity(o.accountID, pity) }
func (o *storeOps) SaveStoreOrder(order domain.StoreOrder) error {
	return o.s.SaveStoreOrder(order)
}
func (o *storeOps) GetBattle(id string) (domain.BattleInstance, error) { return o.s.GetBattle(id) }
func (o *storeOps) GetCampaign() (domain.CampaignProgress, error) {
	return o.s.GetCampaign(o.accountID)
}
func (o *storeOps) GetAFK() (domain.AFKState, error) { return o.s.GetAFK(o.accountID) }
func (o *storeOps) GetMail(mailID string) (domain.MailMessage, error) {
	return o.s.GetMail(o.accountID, mailID)
}
func (o *storeOps) ListHeroes() ([]domain.HeroOwned, error) { return o.s.ListHeroes(o.accountID) }
func (o *storeOps) GetPity(bannerID string) (domain.PityState, error) {
	return o.s.GetPity(o.accountID, bannerID)
}
func (o *storeOps) GetStoreOrder(id string) (domain.StoreOrder, error) {
	return o.s.GetStoreOrder(id)
}
func (o *storeOps) WalletBalances() ([]domain.Balance, error) {
	return o.s.WalletBalances(o.accountID)
}
