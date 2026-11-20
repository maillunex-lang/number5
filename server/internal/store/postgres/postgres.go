// Package postgres implements store.Store on PostgreSQL (TZ-A).
// Compiles without a live DB; Open requires DATABASE_URL / running Postgres.
package postgres

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/maillunex-lang/number5/server/migrations"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/maillunex-lang/number5/server/internal/domain"
	"github.com/maillunex-lang/number5/server/internal/store"
)

type Store struct {
	pool    *pgxpool.Pool
	starter []domain.Balance
	clock   store.Clock
}

func Open(ctx context.Context, databaseURL string, starter []domain.Balance) (*Store, error) {
	if databaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL empty")
	}
	pool, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		return nil, err
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	if starter == nil {
		starter = store.DefaultStarterBalances()
	}
	return &Store{pool: pool, starter: starter, clock: store.RealClock{}}, nil
}

func (s *Store) Close() {
	if s.pool != nil {
		s.pool.Close()
	}
}

func (s *Store) Migrate(ctx context.Context) error {
	return migrations.Apply(ctx, s.pool)
}

func (s *Store) now() time.Time {
	if s.clock != nil {
		return s.clock.Now()
	}
	return time.Now().UTC()
}

func (s *Store) CreateGuest(starterHeroes []string) (domain.Account, domain.Session, error) {
	ctx := context.Background()
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return domain.Account{}, domain.Session{}, err
	}
	defer tx.Rollback(ctx)

	var id string
	now := s.now()
	err = tx.QueryRow(ctx,
		`INSERT INTO accounts (is_guest, status) VALUES (true, 'active') RETURNING id::text`).Scan(&id)
	if err != nil {
		return domain.Account{}, domain.Session{}, err
	}
	acc := domain.Account{ID: domain.AccountID(id), IsGuest: true, Status: "active", CreatedAt: now}

	_, err = tx.Exec(ctx, `INSERT INTO player_profiles(account_id,nickname,level,xp) VALUES ($1::uuid,'Гость-' || left($1::text,6),1,0)`, id)
	if err != nil {
		return domain.Account{}, domain.Session{}, err
	}

	tok := store.NewID("tok")
	exp := now.Add(30 * 24 * time.Hour)
	_, err = tx.Exec(ctx,
		`INSERT INTO sessions (account_id, refresh_hash, expires_at) VALUES ($1::uuid, $2, $3)`,
		id, tok, exp)
	if err != nil {
		return domain.Account{}, domain.Session{}, err
	}

	for _, b := range s.starter {
		_, err = tx.Exec(ctx,
			`INSERT INTO wallet_balances (account_id, resource_id, amount, version) VALUES ($1::uuid, $2, $3, 1)`,
			id, b.ResourceID, b.Amount)
		if err != nil {
			return domain.Account{}, domain.Session{}, err
		}
		_, err = tx.Exec(ctx, `
			INSERT INTO wallet_ledger (account_id, resource_id, delta, source_type, source_id, idempotency_key)
			VALUES ($1::uuid, $2, $3, 'starter', 'guest_create', $4)`,
			id, b.ResourceID, b.Amount, "starter:"+id+":"+b.ResourceID)
		if err != nil {
			return domain.Account{}, domain.Session{}, err
		}
	}
	for _, hid := range starterHeroes {
		_, err = tx.Exec(ctx,
			`INSERT INTO heroes_owned (account_id, hero_id, stars, level, shards) VALUES ($1::uuid, $2, 1, 1, 0)`,
			id, hid)
		if err != nil {
			return domain.Account{}, domain.Session{}, err
		}
	}
	slots := append([]string{}, starterHeroes...)
	for len(slots) < 5 {
		slots = append(slots, "")
	}
	if len(slots) > 5 {
		slots = slots[:5]
	}
	for i, hid := range slots {
		_, err = tx.Exec(ctx,
			`INSERT INTO formations (account_id, mode, slot, hero_id) VALUES ($1::uuid, 'campaign', $2, NULLIF($3, ''))`,
			id, i, hid)
		if err != nil {
			return domain.Account{}, domain.Session{}, err
		}
	}
	_, err = tx.Exec(ctx,
		`INSERT INTO campaign_progress (account_id, current_stage, unlocked_chapter) VALUES ($1::uuid, 'CH01-01', 1)`, id)
	if err != nil {
		return domain.Account{}, domain.Session{}, err
	}
	_, err = tx.Exec(ctx,
		`INSERT INTO afk_state (account_id, last_claim_at, chapter) VALUES ($1::uuid, $2, 1)`,
		id, now.Add(-2*time.Hour))
	if err != nil {
		return domain.Account{}, domain.Session{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return domain.Account{}, domain.Session{}, err
	}
	return acc, domain.Session{Token: tok, AccountID: acc.ID, ExpiresAt: exp}, nil
}

func (s *Store) AccountBySession(token string) (domain.Account, error) {
	ctx := context.Background()
	var id, status, email string
	var isGuest bool
	var created time.Time
	err := s.pool.QueryRow(ctx, `
		SELECT a.id::text, COALESCE(a.email, ''), a.is_guest, a.status, a.created_at
		FROM sessions sess
		JOIN accounts a ON a.id = sess.account_id
		WHERE sess.refresh_hash = $1 AND sess.revoked_at IS NULL AND sess.expires_at > now()`,
		token).Scan(&id, &email, &isGuest, &status, &created)
	if err != nil {
		return domain.Account{}, store.ErrUnauthorized
	}
	if status != "active" {
		return domain.Account{}, store.ErrUnauthorized
	}
	return domain.Account{ID: domain.AccountID(id), Email: email, IsGuest: isGuest, Status: status, CreatedAt: created}, nil
}

func (s *Store) WalletBalances(accountID domain.AccountID) ([]domain.Balance, error) {
	ctx := context.Background()
	rows, err := s.pool.Query(ctx,
		`SELECT resource_id, amount, version FROM wallet_balances WHERE account_id = $1::uuid`, string(accountID))
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.Balance{}
	for rows.Next() {
		var b domain.Balance
		if err := rows.Scan(&b.ResourceID, &b.Amount, &b.Version); err != nil {
			return nil, err
		}
		out = append(out, b)
	}
	if len(out) == 0 {
		return nil, store.ErrNotFound
	}
	return out, nil
}

func (s *Store) GetIdempotency(accountID domain.AccountID, key string) (domain.IdempotencyRecord, error) {
	ctx := context.Background()
	var rec domain.IdempotencyRecord
	var body []byte
	err := s.pool.QueryRow(ctx, `
		SELECT request_hash, response_json, status_code, created_at
		FROM idempotency_keys WHERE account_id = $1::uuid AND key = $2`,
		string(accountID), key).Scan(&rec.RequestHash, &body, &rec.StatusCode, &rec.CreatedAt)
	if err != nil {
		return domain.IdempotencyRecord{}, store.ErrNotFound
	}
	rec.AccountID = accountID
	rec.Key = key
	rec.ResponseJSON = body
	return rec, nil
}

func (s *Store) PatchIdempotencyResponse(accountID domain.AccountID, key string, body []byte, status int) error {
	ctx := context.Background()
	ct, err := s.pool.Exec(ctx, `
		UPDATE idempotency_keys SET response_json = $3, status_code = $4
		WHERE account_id = $1::uuid AND key = $2`, string(accountID), key, body, status)
	if err != nil {
		return err
	}
	if ct.RowsAffected() == 0 {
		return store.ErrNotFound
	}
	return nil
}

func (s *Store) ApplyLedger(accountID domain.AccountID, entries []domain.LedgerEntry, idempotencyKey, requestHash string, response []byte, statusCode int) (bool, error) {
	ctx := context.Background()
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return false, err
	}
	defer tx.Rollback(ctx)

	var existingHash string
	err = tx.QueryRow(ctx,
		`SELECT request_hash FROM idempotency_keys WHERE account_id = $1::uuid AND key = $2`,
		string(accountID), idempotencyKey).Scan(&existingHash)
	if err == nil {
		if existingHash != requestHash {
			return false, store.ErrConflict
		}
		return true, nil
	}

	for _, e := range entries {
		var amt int64
		err = tx.QueryRow(ctx,
			`SELECT amount FROM wallet_balances WHERE account_id = $1::uuid AND resource_id = $2`,
			string(accountID), e.ResourceID).Scan(&amt)
		if err != nil {
			amt = 0
		}
		if amt+e.Delta < 0 {
			return false, store.ErrInsufficient
		}
	}
	now := s.now()
	for _, e := range entries {
		_, err = tx.Exec(ctx, `
			INSERT INTO wallet_balances (account_id, resource_id, amount, version)
			VALUES ($1::uuid, $2, $3, 1)
			ON CONFLICT (account_id, resource_id) DO UPDATE
			SET amount = wallet_balances.amount + EXCLUDED.amount, version = wallet_balances.version + 1`,
			string(accountID), e.ResourceID, e.Delta)
		if err != nil {
			return false, err
		}
		_, err = tx.Exec(ctx, `
			INSERT INTO wallet_ledger (account_id, resource_id, delta, source_type, source_id, period_key, config_version, idempotency_key, created_at)
			VALUES ($1::uuid, $2, $3, $4, $5, $6, $7, $8, $9)`,
			string(accountID), e.ResourceID, e.Delta, e.SourceType, e.SourceID, e.PeriodKey, e.ConfigVersion, idempotencyKey, now)
		if err != nil {
			return false, err
		}
	}
	_, err = tx.Exec(ctx, `
		INSERT INTO idempotency_keys (account_id, key, request_hash, response_json, status_code, created_at)
		VALUES ($1::uuid, $2, $3, $4, $5, $6)`,
		string(accountID), idempotencyKey, requestHash, response, statusCode, now)
	if err != nil {
		return false, err
	}
	return false, tx.Commit(ctx)
}

func (s *Store) ListHeroes(accountID domain.AccountID) ([]domain.HeroOwned, error) {
	ctx := context.Background()
	rows, err := s.pool.Query(ctx,
		`SELECT hero_id, stars, level, shards FROM heroes_owned WHERE account_id = $1::uuid`, string(accountID))
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.HeroOwned{}
	for rows.Next() {
		var h domain.HeroOwned
		if err := rows.Scan(&h.HeroID, &h.Stars, &h.Level, &h.Shards); err != nil {
			return nil, err
		}
		out = append(out, h)
	}
	return out, nil
}

func (s *Store) UpsertHero(accountID domain.AccountID, hero domain.HeroOwned) error {
	ctx := context.Background()
	_, err := s.pool.Exec(ctx, `
		INSERT INTO heroes_owned (account_id, hero_id, stars, level, shards)
		VALUES ($1::uuid, $2, $3, $4, $5)
		ON CONFLICT (account_id, hero_id) DO UPDATE
		SET stars = EXCLUDED.stars, level = EXCLUDED.level, shards = EXCLUDED.shards`,
		string(accountID), hero.HeroID, hero.Stars, hero.Level, hero.Shards)
	return err
}

func (s *Store) GetFormation(accountID domain.AccountID, mode string) (domain.Formation, error) {
	ctx := context.Background()
	rows, err := s.pool.Query(ctx,
		`SELECT slot, COALESCE(hero_id, '') FROM formations WHERE account_id = $1::uuid AND mode = $2 ORDER BY slot`,
		string(accountID), mode)
	if err != nil {
		return domain.Formation{}, err
	}
	defer rows.Close()
	slots := make([]string, 5)
	found := false
	for rows.Next() {
		var slot int
		var hid string
		if err := rows.Scan(&slot, &hid); err != nil {
			return domain.Formation{}, err
		}
		if slot >= 0 && slot < 5 {
			slots[slot] = hid
			found = true
		}
	}
	if !found {
		return domain.Formation{}, store.ErrNotFound
	}
	return domain.Formation{Mode: mode, Slots: slots}, nil
}

func (s *Store) SetFormation(accountID domain.AccountID, form domain.Formation) error {
	ctx := context.Background()
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	_, err = tx.Exec(ctx, `DELETE FROM formations WHERE account_id = $1::uuid AND mode = $2`, string(accountID), form.Mode)
	if err != nil {
		return err
	}
	slots := form.Slots
	for len(slots) < 5 {
		slots = append(slots, "")
	}
	for i := 0; i < 5; i++ {
		_, err = tx.Exec(ctx,
			`INSERT INTO formations (account_id, mode, slot, hero_id) VALUES ($1::uuid, $2, $3, NULLIF($4, ''))`,
			string(accountID), form.Mode, i, slots[i])
		if err != nil {
			return err
		}
	}
	return tx.Commit(ctx)
}

func (s *Store) GetCampaign(accountID domain.AccountID) (domain.CampaignProgress, error) {
	ctx := context.Background()
	var prog domain.CampaignProgress
	err := s.pool.QueryRow(ctx,
		`SELECT current_stage, unlocked_chapter FROM campaign_progress WHERE account_id = $1::uuid`,
		string(accountID)).Scan(&prog.CurrentStage, &prog.UnlockedChapter)
	if err != nil {
		return domain.CampaignProgress{}, store.ErrNotFound
	}
	prog.Stages = map[string]domain.StageClear{}
	rows, err := s.pool.Query(ctx,
		`SELECT stage_id, stars, clears, first_clear_claimed_at IS NOT NULL FROM campaign_stages WHERE account_id = $1::uuid`,
		string(accountID))
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var sc domain.StageClear
			if err := rows.Scan(&sc.StageID, &sc.Stars, &sc.Clears, &sc.FirstClearClaimed); err != nil {
				return prog, err
			}
			prog.Stages[sc.StageID] = sc
		}
	}
	return prog, nil
}

func (s *Store) SaveCampaign(accountID domain.AccountID, prog domain.CampaignProgress) error {
	ctx := context.Background()
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	_, err = tx.Exec(ctx, `
		UPDATE campaign_progress SET current_stage = $2, unlocked_chapter = $3, updated_at = now()
		WHERE account_id = $1::uuid`, string(accountID), prog.CurrentStage, prog.UnlockedChapter)
	if err != nil {
		return err
	}
	for _, sc := range prog.Stages {
		var claimed any
		if sc.FirstClearClaimed {
			claimed = s.now()
		}
		_, err = tx.Exec(ctx, `
			INSERT INTO campaign_stages (account_id, stage_id, stars, clears, first_clear_claimed_at)
			VALUES ($1::uuid, $2, $3, $4, $5)
			ON CONFLICT (account_id, stage_id) DO UPDATE
			SET stars = EXCLUDED.stars, clears = EXCLUDED.clears,
			    first_clear_claimed_at = COALESCE(campaign_stages.first_clear_claimed_at, EXCLUDED.first_clear_claimed_at)`,
			string(accountID), sc.StageID, sc.Stars, sc.Clears, claimed)
		if err != nil {
			return err
		}
	}
	return tx.Commit(ctx)
}

func (s *Store) SaveBattle(b domain.BattleInstance) error {
	ctx := context.Background()
	squad, _ := json.Marshal(b.Squad)
	result, _ := json.Marshal(map[string]any{"victory": b.Victory, "timeline": b.Timeline})
	_, err := s.pool.Exec(ctx, `
		INSERT INTO battle_instances (id, account_id, mode, stage_id, squad_json, seed, status, started_at, finished_at, result_json, config_version, claimed)
		VALUES ($1, $2::uuid, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status, finished_at = EXCLUDED.finished_at,
			result_json = EXCLUDED.result_json, claimed = EXCLUDED.claimed`,
		b.ID, string(b.AccountID), b.Mode, b.StageID, squad, b.Seed, b.Status, b.StartedAt, b.FinishedAt, result, b.ConfigVersion, b.Claimed)
	return err
}

func (s *Store) GetBattle(id string) (domain.BattleInstance, error) {
	ctx := context.Background()
	var b domain.BattleInstance
	var squad, result []byte
	var acc string
	err := s.pool.QueryRow(ctx, `
		SELECT id, account_id::text, mode, stage_id, squad_json, seed, status, started_at, finished_at, result_json, config_version, claimed
		FROM battle_instances WHERE id = $1`, id).Scan(
		&b.ID, &acc, &b.Mode, &b.StageID, &squad, &b.Seed, &b.Status, &b.StartedAt, &b.FinishedAt, &result, &b.ConfigVersion, &b.Claimed)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return domain.BattleInstance{}, store.ErrNotFound
		}
		return domain.BattleInstance{}, err
	}
	b.AccountID = domain.AccountID(acc)
	_ = json.Unmarshal(squad, &b.Squad)
	var parsed map[string]any
	if json.Unmarshal(result, &parsed) == nil {
		b.Victory, _ = parsed["victory"].(bool)
		if tl, ok := parsed["timeline"].([]any); ok {
			for _, item := range tl {
				if m, ok := item.(map[string]any); ok {
					b.Timeline = append(b.Timeline, m)
				}
			}
		}
	}
	return b, nil
}

func (s *Store) MarkBattleClaimed(id string) error {
	ctx := context.Background()
	_, err := s.pool.Exec(ctx, `UPDATE battle_instances SET claimed = true WHERE id = $1`, id)
	return err
}

func (s *Store) GetPity(accountID domain.AccountID, bannerID string) (domain.PityState, error) {
	ctx := context.Background()
	var p domain.PityState
	err := s.pool.QueryRow(ctx,
		`SELECT banner_id, ssr_count, ur_count FROM summon_pity WHERE account_id = $1::uuid AND banner_id = $2`,
		string(accountID), bannerID).Scan(&p.BannerID, &p.SSR, &p.UR)
	if err != nil {
		return domain.PityState{BannerID: bannerID}, nil
	}
	return p, nil
}

func (s *Store) SetPity(accountID domain.AccountID, pity domain.PityState) error {
	ctx := context.Background()
	_, err := s.pool.Exec(ctx, `
		INSERT INTO summon_pity (account_id, banner_id, ssr_count, ur_count)
		VALUES ($1::uuid, $2, $3, $4)
		ON CONFLICT (account_id, banner_id) DO UPDATE
		SET ssr_count = EXCLUDED.ssr_count, ur_count = EXCLUDED.ur_count`,
		string(accountID), pity.BannerID, pity.SSR, pity.UR)
	return err
}

func (s *Store) GetAFK(accountID domain.AccountID) (domain.AFKState, error) {
	ctx := context.Background()
	var st domain.AFKState
	err := s.pool.QueryRow(ctx,
		`SELECT last_claim_at, chapter FROM afk_state WHERE account_id = $1::uuid`, string(accountID)).
		Scan(&st.LastClaimAt, &st.Chapter)
	if err != nil {
		return domain.AFKState{}, store.ErrNotFound
	}
	return st, nil
}

func (s *Store) SetAFK(accountID domain.AccountID, st domain.AFKState) error {
	ctx := context.Background()
	_, err := s.pool.Exec(ctx,
		`UPDATE afk_state SET last_claim_at = $2, chapter = $3 WHERE account_id = $1::uuid`,
		string(accountID), st.LastClaimAt, st.Chapter)
	return err
}

func (s *Store) ListMail(accountID domain.AccountID) ([]domain.MailMessage, error) {
	ctx := context.Background()
	rows, err := s.pool.Query(ctx, `
		SELECT id, template_id, category, subject, body, status, attachments_json, created_at, expires_at
		FROM mail_messages WHERE account_id = $1::uuid ORDER BY created_at`, string(accountID))
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.MailMessage{}
	for rows.Next() {
		var m domain.MailMessage
		var atts []byte
		var exp sql.NullTime
		if err := rows.Scan(&m.ID, &m.TemplateID, &m.Category, &m.Subject, &m.Body, &m.Status, &atts, &m.CreatedAt, &exp); err != nil {
			return nil, err
		}
		_ = json.Unmarshal(atts, &m.Attachments)
		if exp.Valid {
			t := exp.Time
			m.ExpiresAt = &t
		}
		out = append(out, m)
	}
	return out, nil
}

func (s *Store) GetMail(accountID domain.AccountID, mailID string) (domain.MailMessage, error) {
	msgs, err := s.ListMail(accountID)
	if err != nil {
		return domain.MailMessage{}, err
	}
	for _, m := range msgs {
		if m.ID == mailID {
			return m, nil
		}
	}
	return domain.MailMessage{}, store.ErrNotFound
}

func (s *Store) SaveMail(accountID domain.AccountID, msg domain.MailMessage) error {
	ctx := context.Background()
	atts, _ := json.Marshal(msg.Attachments)
	_, err := s.pool.Exec(ctx, `
		INSERT INTO mail_messages (id, account_id, template_id, category, subject, body, status, attachments_json, created_at, expires_at)
		VALUES ($1, $2::uuid, $3, $4, $5, $6, $7, $8, $9, $10)
		ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status, attachments_json = EXCLUDED.attachments_json`,
		msg.ID, string(accountID), msg.TemplateID, msg.Category, msg.Subject, msg.Body, msg.Status, atts, msg.CreatedAt, msg.ExpiresAt)
	return err
}

func (s *Store) SeedMail(accountID domain.AccountID, msgs []domain.MailMessage) error {
	for _, m := range msgs {
		if err := s.SaveMail(accountID, m); err != nil {
			return err
		}
	}
	return nil
}

func (s *Store) SaveStoreOrder(order domain.StoreOrder) error {
	ctx := context.Background()
	grants, _ := json.Marshal(order.Grants)
	_, err := s.pool.Exec(ctx, `
		INSERT INTO store_orders (id, account_id, sku, status, grants_json, vip_xp, idempotency_key, created_at, confirmed_at)
		VALUES ($1, $2::uuid, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status, confirmed_at = EXCLUDED.confirmed_at`,
		order.ID, string(order.AccountID), order.SKU, order.Status, grants, order.VipXP, order.IdempotencyKey, order.CreatedAt, order.ConfirmedAt)
	return err
}

func (s *Store) GetStoreOrder(id string) (domain.StoreOrder, error) {
	ctx := context.Background()
	var o domain.StoreOrder
	var grants []byte
	var acc string
	var confirmed sql.NullTime
	err := s.pool.QueryRow(ctx, `
		SELECT id, account_id::text, sku, status, grants_json, vip_xp, idempotency_key, created_at, confirmed_at
		FROM store_orders WHERE id = $1`, id).Scan(
		&o.ID, &acc, &o.SKU, &o.Status, &grants, &o.VipXP, &o.IdempotencyKey, &o.CreatedAt, &confirmed)
	if err != nil {
		return domain.StoreOrder{}, store.ErrNotFound
	}
	o.AccountID = domain.AccountID(acc)
	_ = json.Unmarshal(grants, &o.Grants)
	if confirmed.Valid {
		t := confirmed.Time
		o.ConfirmedAt = &t
	}
	return o, nil
}

// TouchPresence records last authenticated activity without changing gameplay data.
func (s *Store) TouchPresence(accountID domain.AccountID) error {
	_, err := s.pool.Exec(context.Background(),
		`INSERT INTO player_profiles(account_id,nickname,last_seen_at)
      VALUES ($1::uuid, 'Гость-' || left($1::text,6), now())
      ON CONFLICT(account_id) DO UPDATE SET last_seen_at=now()`, string(accountID))
	return err
}

// ReadPlayerProfile is the server-owned commander identity.
func (s *Store) ReadPlayerProfile(accountID domain.AccountID) (string, int, int64, error) {
	var nickname string
	var level int
	var xp int64
	err := s.pool.QueryRow(context.Background(),
		`SELECT COALESCE(p.nickname, (CASE WHEN a.is_guest THEN 'Гость-' ELSE 'Игрок-' END) || left(a.id::text, 6)),
		        COALESCE(p.level, 1), COALESCE(p.xp, 0)
		   FROM accounts a
		   LEFT JOIN player_profiles p ON p.account_id=a.id
		  WHERE a.id=$1::uuid`,
		string(accountID)).Scan(&nickname, &level, &xp)
	return nickname, level, xp, err
}
