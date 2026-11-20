package store

import "github.com/maillunex-lang/number5/server/internal/domain"

type memSnap struct {
	wallet  map[string]domain.Balance
	idem    map[string]domain.IdempotencyRecord
	heroes  map[string]domain.HeroOwned
	pity    map[string]domain.PityState
	mail    map[string]domain.MailMessage
	orders  map[string]domain.StoreOrder
	campaign *domain.CampaignProgress
	afk      *domain.AFKState
	battles  map[string]domain.BattleInstance
	ledgerN  int
}

// RunAtomic holds the memory mutex for the whole callback and rolls back account-scoped
// mutations if fn returns an error (TD-ATOMIC parity with Postgres transactions).
func (m *Memory) RunAtomic(accountID domain.AccountID, fn func(Ops) error) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	snap := m.snapshotLocked(accountID)
	err := fn(&memOps{m: m, accountID: accountID})
	if err != nil {
		m.restoreLocked(accountID, snap)
	}
	return err
}

func (m *Memory) snapshotLocked(accountID domain.AccountID) memSnap {
	s := memSnap{ledgerN: len(m.ledger), battles: map[string]domain.BattleInstance{}}
	if w, ok := m.wallet[accountID]; ok {
		s.wallet = map[string]domain.Balance{}
		for k, v := range w {
			s.wallet[k] = v
		}
	}
	s.idem = map[string]domain.IdempotencyRecord{}
	prefix := string(accountID) + "|"
	for k, v := range m.idem {
		if len(k) >= len(prefix) && k[:len(prefix)] == prefix {
			cp := v
			cp.ResponseJSON = append([]byte(nil), v.ResponseJSON...)
			s.idem[k] = cp
		}
	}
	if hs, ok := m.heroes[accountID]; ok {
		s.heroes = map[string]domain.HeroOwned{}
		for k, v := range hs {
			s.heroes[k] = v
		}
	}
	if pm, ok := m.pity[accountID]; ok {
		s.pity = map[string]domain.PityState{}
		for k, v := range pm {
			s.pity[k] = v
		}
	}
	if box, ok := m.mail[accountID]; ok {
		s.mail = map[string]domain.MailMessage{}
		for k, v := range box {
			s.mail[k] = v
		}
	}
	s.orders = map[string]domain.StoreOrder{}
	for k, v := range m.orders {
		if v.AccountID == accountID {
			s.orders[k] = v
		}
	}
	if p, ok := m.campaign[accountID]; ok {
		cp := p
		cp.Stages = map[string]domain.StageClear{}
		for k, v := range p.Stages {
			cp.Stages[k] = v
		}
		s.campaign = &cp
	}
	if a, ok := m.afk[accountID]; ok {
		aa := a
		s.afk = &aa
	}
	for id, b := range m.battles {
		if b.AccountID == accountID {
			s.battles[id] = b
		}
	}
	return s
}

func (m *Memory) restoreLocked(accountID domain.AccountID, s memSnap) {
	if s.wallet != nil {
		m.wallet[accountID] = s.wallet
	}
	prefix := string(accountID) + "|"
	for k := range m.idem {
		if len(k) >= len(prefix) && k[:len(prefix)] == prefix {
			if _, ok := s.idem[k]; !ok {
				delete(m.idem, k)
			}
		}
	}
	for k, v := range s.idem {
		m.idem[k] = v
	}
	if s.heroes != nil {
		m.heroes[accountID] = s.heroes
	}
	if s.pity != nil {
		m.pity[accountID] = s.pity
	}
	if s.mail != nil {
		m.mail[accountID] = s.mail
	}
	for k, v := range m.orders {
		if v.AccountID == accountID {
			if _, ok := s.orders[k]; !ok {
				delete(m.orders, k)
			}
		}
	}
	for k, v := range s.orders {
		m.orders[k] = v
	}
	if s.campaign != nil {
		m.campaign[accountID] = *s.campaign
	}
	if s.afk != nil {
		m.afk[accountID] = *s.afk
	}
	for id, b := range m.battles {
		if b.AccountID == accountID {
			if _, ok := s.battles[id]; !ok {
				delete(m.battles, id)
			}
		}
	}
	for id, b := range s.battles {
		m.battles[id] = b
	}
	if len(m.ledger) > s.ledgerN {
		m.ledger = m.ledger[:s.ledgerN]
	}
}

type memOps struct {
	m         *Memory
	accountID domain.AccountID
}

func (o *memOps) ApplyLedger(entries []domain.LedgerEntry, idempotencyKey, requestHash string, response []byte, statusCode int) (bool, error) {
	return o.m.applyLedgerLocked(o.accountID, entries, idempotencyKey, requestHash, response, statusCode)
}

func (o *memOps) PatchIdempotencyResponse(key string, body []byte, status int) error {
	return o.m.patchIdempotencyLocked(o.accountID, key, body, status)
}

func (o *memOps) GetIdempotency(key string) (domain.IdempotencyRecord, error) {
	return o.m.getIdempotencyLocked(o.accountID, key)
}

func (o *memOps) MarkBattleClaimed(id string) error {
	b, ok := o.m.battles[id]
	if !ok {
		return ErrNotFound
	}
	b.Claimed = true
	o.m.battles[id] = b
	return nil
}

func (o *memOps) SaveCampaign(prog domain.CampaignProgress) error {
	if _, ok := o.m.campaign[o.accountID]; !ok {
		return ErrNotFound
	}
	o.m.campaign[o.accountID] = prog
	return nil
}

func (o *memOps) SetAFK(st domain.AFKState) error {
	if _, ok := o.m.afk[o.accountID]; !ok {
		return ErrNotFound
	}
	o.m.afk[o.accountID] = st
	return nil
}

func (o *memOps) SaveMail(msg domain.MailMessage) error {
	box, ok := o.m.mail[o.accountID]
	if !ok {
		return ErrNotFound
	}
	box[msg.ID] = msg
	return nil
}

func (o *memOps) UpsertHero(hero domain.HeroOwned) error {
	hs, ok := o.m.heroes[o.accountID]
	if !ok {
		return ErrNotFound
	}
	hs[hero.HeroID] = hero
	return nil
}

func (o *memOps) SetPity(pity domain.PityState) error {
	pm, ok := o.m.pity[o.accountID]
	if !ok {
		pm = map[string]domain.PityState{}
		o.m.pity[o.accountID] = pm
	}
	pm[pity.BannerID] = pity
	return nil
}

func (o *memOps) SaveStoreOrder(order domain.StoreOrder) error {
	o.m.orders[order.ID] = order
	return nil
}

func (o *memOps) GetBattle(id string) (domain.BattleInstance, error) {
	b, ok := o.m.battles[id]
	if !ok {
		return domain.BattleInstance{}, ErrNotFound
	}
	return b, nil
}

func (o *memOps) GetCampaign() (domain.CampaignProgress, error) {
	p, ok := o.m.campaign[o.accountID]
	if !ok {
		return domain.CampaignProgress{}, ErrNotFound
	}
	cp := p
	cp.Stages = map[string]domain.StageClear{}
	for k, v := range p.Stages {
		cp.Stages[k] = v
	}
	return cp, nil
}

func (o *memOps) GetAFK() (domain.AFKState, error) {
	st, ok := o.m.afk[o.accountID]
	if !ok {
		return domain.AFKState{}, ErrNotFound
	}
	return st, nil
}

func (o *memOps) GetMail(mailID string) (domain.MailMessage, error) {
	box, ok := o.m.mail[o.accountID]
	if !ok {
		return domain.MailMessage{}, ErrNotFound
	}
	msg, ok := box[mailID]
	if !ok {
		return domain.MailMessage{}, ErrNotFound
	}
	return msg, nil
}

func (o *memOps) ListHeroes() ([]domain.HeroOwned, error) {
	hs, ok := o.m.heroes[o.accountID]
	if !ok {
		return nil, ErrNotFound
	}
	out := make([]domain.HeroOwned, 0, len(hs))
	for _, h := range hs {
		out = append(out, h)
	}
	return out, nil
}

func (o *memOps) GetPity(bannerID string) (domain.PityState, error) {
	pm, ok := o.m.pity[o.accountID]
	if !ok {
		return domain.PityState{BannerID: bannerID}, nil
	}
	p, ok := pm[bannerID]
	if !ok {
		return domain.PityState{BannerID: bannerID}, nil
	}
	return p, nil
}

func (o *memOps) GetStoreOrder(id string) (domain.StoreOrder, error) {
	ord, ok := o.m.orders[id]
	if !ok {
		return domain.StoreOrder{}, ErrNotFound
	}
	return ord, nil
}

func (o *memOps) WalletBalances() ([]domain.Balance, error) {
	w, ok := o.m.wallet[o.accountID]
	if !ok {
		return nil, ErrNotFound
	}
	out := make([]domain.Balance, 0, len(w))
	for _, b := range w {
		out = append(out, b)
	}
	return out, nil
}
