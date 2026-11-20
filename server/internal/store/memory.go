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
	mu         sync.Mutex
	accounts   map[domain.AccountID]domain.Account
	sessions   map[string]domain.Session
	wallet     map[domain.AccountID]map[string]domain.Balance
	ledger     []domain.LedgerEntry
	idem       map[string]domain.IdempotencyRecord
	heroes     map[domain.AccountID]map[string]domain.HeroOwned
	formations map[domain.AccountID]map[string]domain.Formation
	campaign   map[domain.AccountID]domain.CampaignProgress
	battles    map[string]domain.BattleInstance
	pity       map[domain.AccountID]map[string]domain.PityState
	afk        map[domain.AccountID]domain.AFKState
	mail       map[domain.AccountID]map[string]domain.MailMessage
	starter    []domain.Balance
	clock      Clock
}

func NewMemory(starter []domain.Balance) *Memory {
	if starter == nil {
		starter = DefaultStarterBalances()
	}
	return &Memory{
		accounts:   map[domain.AccountID]domain.Account{},
		sessions:   map[string]domain.Session{},
		wallet:     map[domain.AccountID]map[string]domain.Balance{},
		idem:       map[string]domain.IdempotencyRecord{},
		heroes:     map[domain.AccountID]map[string]domain.HeroOwned{},
		formations: map[domain.AccountID]map[string]domain.Formation{},
		campaign:   map[domain.AccountID]domain.CampaignProgress{},
		battles:    map[string]domain.BattleInstance{},
		pity:       map[domain.AccountID]map[string]domain.PityState{},
		afk:        map[domain.AccountID]domain.AFKState{},
		mail:       map[domain.AccountID]map[string]domain.MailMessage{},
		starter:    starter,
		clock:      RealClock{},
	}
}

func (m *Memory) SetClock(c Clock) { m.clock = c }

func DefaultStarterBalances() []domain.Balance {
	return []domain.Balance{
		{ResourceID: "gold", Amount: 100_000},
		{ResourceID: "diamonds", Amount: 600},
		{ResourceID: "hero_xp", Amount: 20_000},
		{ResourceID: "essence", Amount: 500},
		{ResourceID: "summon_scroll", Amount: 20},
	}
}

func (m *Memory) CreateGuest(starterHeroes []string) (domain.Account, domain.Session, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	now := m.clock.Now()
	id := domain.AccountID(newID("acc"))
	acc := domain.Account{ID: id, IsGuest: true, Status: "active", CreatedAt: now}
	m.accounts[id] = acc
	tok := newID("tok")
	sess := domain.Session{Token: tok, AccountID: id, ExpiresAt: now.Add(30 * 24 * time.Hour)}
	m.sessions[tok] = sess

	w := map[string]domain.Balance{}
	for _, b := range m.starter {
		w[b.ResourceID] = domain.Balance{ResourceID: b.ResourceID, Amount: b.Amount, Version: 1}
		m.ledger = append(m.ledger, domain.LedgerEntry{
			ID: newID("led"), AccountID: id, ResourceID: b.ResourceID, Delta: b.Amount,
			SourceType: "starter", SourceID: "guest_create",
			IdempotencyKey: "starter:" + string(id) + ":" + b.ResourceID, CreatedAt: now,
		})
	}
	m.wallet[id] = w

	hs := map[string]domain.HeroOwned{}
	for _, hid := range starterHeroes {
		hs[hid] = domain.HeroOwned{HeroID: hid, Stars: 1, Level: 1, Shards: 0}
	}
	m.heroes[id] = hs
	slots := append([]string{}, starterHeroes...)
	for len(slots) < 5 {
		slots = append(slots, "")
	}
	if len(slots) > 5 {
		slots = slots[:5]
	}
	m.formations[id] = map[string]domain.Formation{
		"campaign": {Mode: "campaign", Slots: slots},
	}
	m.campaign[id] = domain.CampaignProgress{
		CurrentStage: "CH01-01", UnlockedChapter: 1, Stages: map[string]domain.StageClear{},
	}
	// Seed AFK as already accumulating so first claim works in smoke/tests.
	m.afk[id] = domain.AFKState{LastClaimAt: now.Add(-2 * time.Hour), Chapter: 1}
	m.pity[id] = map[string]domain.PityState{}
	m.mail[id] = map[string]domain.MailMessage{}
	return acc, sess, nil
}

func (m *Memory) AccountBySession(token string) (domain.Account, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	sess, ok := m.sessions[token]
	if !ok || m.clock.Now().After(sess.ExpiresAt) {
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

func (m *Memory) ApplyLedger(accountID domain.AccountID, entries []domain.LedgerEntry, idempotencyKey, requestHash string, response []byte, statusCode int) (bool, error) {
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
	for _, e := range entries {
		cur := w[e.ResourceID]
		if cur.Amount+e.Delta < 0 {
			return false, ErrInsufficient
		}
	}
	now := m.clock.Now()
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
		AccountID: accountID, Key: idempotencyKey, RequestHash: requestHash,
		ResponseJSON: append([]byte(nil), response...), StatusCode: statusCode, CreatedAt: now,
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

func (m *Memory) ListHeroes(accountID domain.AccountID) ([]domain.HeroOwned, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	hs, ok := m.heroes[accountID]
	if !ok {
		return nil, ErrNotFound
	}
	out := make([]domain.HeroOwned, 0, len(hs))
	for _, h := range hs {
		out = append(out, h)
	}
	return out, nil
}

func (m *Memory) UpsertHero(accountID domain.AccountID, hero domain.HeroOwned) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	hs, ok := m.heroes[accountID]
	if !ok {
		return ErrNotFound
	}
	hs[hero.HeroID] = hero
	return nil
}

func (m *Memory) GetFormation(accountID domain.AccountID, mode string) (domain.Formation, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	fm, ok := m.formations[accountID]
	if !ok {
		return domain.Formation{}, ErrNotFound
	}
	f, ok := fm[mode]
	if !ok {
		return domain.Formation{Mode: mode, Slots: []string{"", "", "", "", ""}}, nil
	}
	return f, nil
}

func (m *Memory) SetFormation(accountID domain.AccountID, form domain.Formation) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	fm, ok := m.formations[accountID]
	if !ok {
		return ErrNotFound
	}
	fm[form.Mode] = form
	return nil
}

func (m *Memory) GetCampaign(accountID domain.AccountID) (domain.CampaignProgress, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	p, ok := m.campaign[accountID]
	if !ok {
		return domain.CampaignProgress{}, ErrNotFound
	}
	// deep copy stages map
	cp := p
	cp.Stages = map[string]domain.StageClear{}
	for k, v := range p.Stages {
		cp.Stages[k] = v
	}
	return cp, nil
}

func (m *Memory) SaveCampaign(accountID domain.AccountID, prog domain.CampaignProgress) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if _, ok := m.campaign[accountID]; !ok {
		return ErrNotFound
	}
	m.campaign[accountID] = prog
	return nil
}

func (m *Memory) SaveBattle(b domain.BattleInstance) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.battles[b.ID] = b
	return nil
}

func (m *Memory) GetBattle(id string) (domain.BattleInstance, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	b, ok := m.battles[id]
	if !ok {
		return domain.BattleInstance{}, ErrNotFound
	}
	return b, nil
}

func (m *Memory) MarkBattleClaimed(id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	b, ok := m.battles[id]
	if !ok {
		return ErrNotFound
	}
	b.Claimed = true
	m.battles[id] = b
	return nil
}

func (m *Memory) GetPity(accountID domain.AccountID, bannerID string) (domain.PityState, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	pm, ok := m.pity[accountID]
	if !ok {
		return domain.PityState{}, ErrNotFound
	}
	p, ok := pm[bannerID]
	if !ok {
		return domain.PityState{BannerID: bannerID}, nil
	}
	return p, nil
}

func (m *Memory) SetPity(accountID domain.AccountID, pity domain.PityState) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	pm, ok := m.pity[accountID]
	if !ok {
		return ErrNotFound
	}
	pm[pity.BannerID] = pity
	return nil
}

func (m *Memory) GetAFK(accountID domain.AccountID) (domain.AFKState, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	st, ok := m.afk[accountID]
	if !ok {
		return domain.AFKState{}, ErrNotFound
	}
	return st, nil
}

func (m *Memory) SetAFK(accountID domain.AccountID, st domain.AFKState) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if _, ok := m.afk[accountID]; !ok {
		return ErrNotFound
	}
	m.afk[accountID] = st
	return nil
}

func (m *Memory) ListMail(accountID domain.AccountID) ([]domain.MailMessage, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	box, ok := m.mail[accountID]
	if !ok {
		return nil, ErrNotFound
	}
	out := make([]domain.MailMessage, 0, len(box))
	for _, msg := range box {
		out = append(out, msg)
	}
	return out, nil
}

func (m *Memory) GetMail(accountID domain.AccountID, mailID string) (domain.MailMessage, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	box, ok := m.mail[accountID]
	if !ok {
		return domain.MailMessage{}, ErrNotFound
	}
	msg, ok := box[mailID]
	if !ok {
		return domain.MailMessage{}, ErrNotFound
	}
	return msg, nil
}

func (m *Memory) SaveMail(accountID domain.AccountID, msg domain.MailMessage) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	box, ok := m.mail[accountID]
	if !ok {
		return ErrNotFound
	}
	box[msg.ID] = msg
	return nil
}

func (m *Memory) SeedMail(accountID domain.AccountID, msgs []domain.MailMessage) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	box, ok := m.mail[accountID]
	if !ok {
		return ErrNotFound
	}
	for _, msg := range msgs {
		box[msg.ID] = msg
	}
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

// NewID exported for modules that need IDs without store lock.
func NewID(prefix string) string { return newID(prefix) }
