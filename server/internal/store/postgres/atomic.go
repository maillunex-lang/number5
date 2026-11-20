package postgres

import (
	"context"
	"database/sql"
	"encoding/binary"
	"encoding/json"
	"errors"
	"hash/fnv"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/maillunex-lang/number5/server/internal/domain"
	"github.com/maillunex-lang/number5/server/internal/store"
)

// RunAtomic runs fn inside a single Postgres transaction (TD-ATOMIC).
func (s *Store) RunAtomic(accountID domain.AccountID, fn func(store.Ops) error) error {
	ctx := context.Background()
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	ops := &pgOps{s: s, tx: tx, ctx: ctx, accountID: accountID}
	if err := fn(ops); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

type pgOps struct {
	s         *Store
	tx        pgx.Tx
	ctx       context.Context
	accountID domain.AccountID
}

func (o *pgOps) ApplyLedger(entries []domain.LedgerEntry, idempotencyKey, requestHash string, response []byte, statusCode int) (bool, error) {
	return applyLedgerTx(o.ctx, o.tx, o.s.now(), o.accountID, entries, idempotencyKey, requestHash, response, statusCode)
}

func (o *pgOps) PatchIdempotencyResponse(key string, body []byte, status int) error {
	ct, err := o.tx.Exec(o.ctx, `
		UPDATE idempotency_keys SET response_json = $3, status_code = $4
		WHERE account_id = $1::uuid AND key = $2`, string(o.accountID), key, body, status)
	if err != nil {
		return err
	}
	if ct.RowsAffected() == 0 {
		return store.ErrNotFound
	}
	return nil
}

func (o *pgOps) GetIdempotency(key string) (domain.IdempotencyRecord, error) {
	var rec domain.IdempotencyRecord
	var body []byte
	err := o.tx.QueryRow(o.ctx, `
		SELECT request_hash, response_json, status_code, created_at
		FROM idempotency_keys WHERE account_id = $1::uuid AND key = $2`,
		string(o.accountID), key).Scan(&rec.RequestHash, &body, &rec.StatusCode, &rec.CreatedAt)
	if err != nil {
		return domain.IdempotencyRecord{}, store.ErrNotFound
	}
	rec.AccountID = o.accountID
	rec.Key = key
	rec.ResponseJSON = body
	return rec, nil
}

func (o *pgOps) MarkBattleClaimed(id string) error {
	_, err := o.tx.Exec(o.ctx, `UPDATE battle_instances SET claimed = true WHERE id = $1`, id)
	return err
}

func (o *pgOps) SaveCampaign(prog domain.CampaignProgress) error {
	_, err := o.tx.Exec(o.ctx, `
		UPDATE campaign_progress SET current_stage = $2, unlocked_chapter = $3, updated_at = now()
		WHERE account_id = $1::uuid`, string(o.accountID), prog.CurrentStage, prog.UnlockedChapter)
	if err != nil {
		return err
	}
	for _, sc := range prog.Stages {
		var claimed any
		if sc.FirstClearClaimed {
			claimed = o.s.now()
		}
		_, err = o.tx.Exec(o.ctx, `
			INSERT INTO campaign_stages (account_id, stage_id, stars, clears, first_clear_claimed_at)
			VALUES ($1::uuid, $2, $3, $4, $5)
			ON CONFLICT (account_id, stage_id) DO UPDATE
			SET stars = EXCLUDED.stars, clears = EXCLUDED.clears,
			    first_clear_claimed_at = COALESCE(campaign_stages.first_clear_claimed_at, EXCLUDED.first_clear_claimed_at)`,
			string(o.accountID), sc.StageID, sc.Stars, sc.Clears, claimed)
		if err != nil {
			return err
		}
	}
	return nil
}

func (o *pgOps) SetAFK(st domain.AFKState) error {
	_, err := o.tx.Exec(o.ctx,
		`UPDATE afk_state SET last_claim_at = $2, chapter = $3 WHERE account_id = $1::uuid`,
		string(o.accountID), st.LastClaimAt, st.Chapter)
	return err
}

func (o *pgOps) SaveMail(msg domain.MailMessage) error {
	atts, _ := json.Marshal(msg.Attachments)
	_, err := o.tx.Exec(o.ctx, `
		INSERT INTO mail_messages (id, account_id, template_id, category, subject, body, status, attachments_json, created_at, expires_at)
		VALUES ($1, $2::uuid, $3, $4, $5, $6, $7, $8, $9, $10)
		ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status, attachments_json = EXCLUDED.attachments_json`,
		msg.ID, string(o.accountID), msg.TemplateID, msg.Category, msg.Subject, msg.Body, msg.Status, atts, msg.CreatedAt, msg.ExpiresAt)
	return err
}

func (o *pgOps) UpsertHero(hero domain.HeroOwned) error {
	_, err := o.tx.Exec(o.ctx, `
		INSERT INTO heroes_owned (account_id, hero_id, stars, level, shards)
		VALUES ($1::uuid, $2, $3, $4, $5)
		ON CONFLICT (account_id, hero_id) DO UPDATE
		SET stars = EXCLUDED.stars, level = EXCLUDED.level, shards = EXCLUDED.shards`,
		string(o.accountID), hero.HeroID, hero.Stars, hero.Level, hero.Shards)
	return err
}

func (o *pgOps) SetPity(pity domain.PityState) error {
	_, err := o.tx.Exec(o.ctx, `
		INSERT INTO summon_pity (account_id, banner_id, ssr_count, ur_count)
		VALUES ($1::uuid, $2, $3, $4)
		ON CONFLICT (account_id, banner_id) DO UPDATE
		SET ssr_count = EXCLUDED.ssr_count, ur_count = EXCLUDED.ur_count`,
		string(o.accountID), pity.BannerID, pity.SSR, pity.UR)
	return err
}

func (o *pgOps) SaveStoreOrder(order domain.StoreOrder) error {
	grants, _ := json.Marshal(order.Grants)
	_, err := o.tx.Exec(o.ctx, `
		INSERT INTO store_orders (id, account_id, sku, status, grants_json, vip_xp, idempotency_key, created_at, confirmed_at)
		VALUES ($1, $2::uuid, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status, confirmed_at = EXCLUDED.confirmed_at, grants_json = EXCLUDED.grants_json`,
		order.ID, string(order.AccountID), order.SKU, order.Status, grants, order.VipXP, order.IdempotencyKey, order.CreatedAt, order.ConfirmedAt)
	return err
}

func (o *pgOps) GetBattle(id string) (domain.BattleInstance, error) {
	var b domain.BattleInstance
	var squad, result []byte
	var acc string
	err := o.tx.QueryRow(o.ctx, `
		SELECT id, account_id::text, mode, stage_id, squad_json, seed, status, started_at, finished_at, result_json, config_version, claimed
		FROM battle_instances WHERE id = $1 FOR UPDATE`, id).Scan(
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

func (o *pgOps) GetCampaign() (domain.CampaignProgress, error) {
	var prog domain.CampaignProgress
	err := o.tx.QueryRow(o.ctx,
		`SELECT current_stage, unlocked_chapter FROM campaign_progress WHERE account_id = $1::uuid`,
		string(o.accountID)).Scan(&prog.CurrentStage, &prog.UnlockedChapter)
	if err != nil {
		return domain.CampaignProgress{}, store.ErrNotFound
	}
	prog.Stages = map[string]domain.StageClear{}
	rows, err := o.tx.Query(o.ctx,
		`SELECT stage_id, stars, clears, first_clear_claimed_at IS NOT NULL FROM campaign_stages WHERE account_id = $1::uuid`,
		string(o.accountID))
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

func (o *pgOps) GetAFK() (domain.AFKState, error) {
	var st domain.AFKState
	err := o.tx.QueryRow(o.ctx,
		`SELECT last_claim_at, chapter FROM afk_state WHERE account_id = $1::uuid FOR UPDATE`,
		string(o.accountID)).Scan(&st.LastClaimAt, &st.Chapter)
	if err != nil {
		return domain.AFKState{}, store.ErrNotFound
	}
	return st, nil
}

func (o *pgOps) GetMail(mailID string) (domain.MailMessage, error) {
	var m domain.MailMessage
	var atts []byte
	var exp sql.NullTime
	err := o.tx.QueryRow(o.ctx, `
		SELECT id, template_id, category, subject, body, status, attachments_json, created_at, expires_at
		FROM mail_messages WHERE account_id = $1::uuid AND id = $2 FOR UPDATE`,
		string(o.accountID), mailID).Scan(
		&m.ID, &m.TemplateID, &m.Category, &m.Subject, &m.Body, &m.Status, &atts, &m.CreatedAt, &exp)
	if err != nil {
		return domain.MailMessage{}, store.ErrNotFound
	}
	_ = json.Unmarshal(atts, &m.Attachments)
	if exp.Valid {
		t := exp.Time
		m.ExpiresAt = &t
	}
	return m, nil
}

func (o *pgOps) ListHeroes() ([]domain.HeroOwned, error) {
	rows, err := o.tx.Query(o.ctx,
		`SELECT hero_id, stars, level, shards FROM heroes_owned WHERE account_id = $1::uuid`, string(o.accountID))
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

func (o *pgOps) GetPity(bannerID string) (domain.PityState, error) {
	var p domain.PityState
	err := o.tx.QueryRow(o.ctx,
		`SELECT banner_id, ssr_count, ur_count FROM summon_pity WHERE account_id = $1::uuid AND banner_id = $2 FOR UPDATE`,
		string(o.accountID), bannerID).Scan(&p.BannerID, &p.SSR, &p.UR)
	if err != nil {
		return domain.PityState{BannerID: bannerID}, nil
	}
	return p, nil
}

func (o *pgOps) GetStoreOrder(id string) (domain.StoreOrder, error) {
	var oorder domain.StoreOrder
	var grants []byte
	var acc string
	var confirmed sql.NullTime
	err := o.tx.QueryRow(o.ctx, `
		SELECT id, account_id::text, sku, status, grants_json, vip_xp, idempotency_key, created_at, confirmed_at
		FROM store_orders WHERE id = $1 FOR UPDATE`, id).Scan(
		&oorder.ID, &acc, &oorder.SKU, &oorder.Status, &grants, &oorder.VipXP, &oorder.IdempotencyKey, &oorder.CreatedAt, &confirmed)
	if err != nil {
		return domain.StoreOrder{}, store.ErrNotFound
	}
	oorder.AccountID = domain.AccountID(acc)
	_ = json.Unmarshal(grants, &oorder.Grants)
	if confirmed.Valid {
		t := confirmed.Time
		oorder.ConfirmedAt = &t
	}
	return oorder, nil
}

func (o *pgOps) WalletBalances() ([]domain.Balance, error) {
	rows, err := o.tx.Query(o.ctx,
		`SELECT resource_id, amount, version FROM wallet_balances WHERE account_id = $1::uuid`, string(o.accountID))
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

// applyLedgerTx applies wallet mutations with row locks (TD-PG-RACE).
func applyLedgerTx(ctx context.Context, tx pgx.Tx, now time.Time, accountID domain.AccountID, entries []domain.LedgerEntry, idempotencyKey, requestHash string, response []byte, statusCode int) (bool, error) {
	// Serialize concurrent ops that share the same idempotency key.
	lockKey := advisoryLockKey(string(accountID) + "|" + idempotencyKey)
	if _, err := tx.Exec(ctx, `SELECT pg_advisory_xact_lock($1)`, lockKey); err != nil {
		return false, err
	}

	var existingHash string
	err := tx.QueryRow(ctx,
		`SELECT request_hash FROM idempotency_keys WHERE account_id = $1::uuid AND key = $2`,
		string(accountID), idempotencyKey).Scan(&existingHash)
	if err == nil {
		if existingHash != requestHash {
			return false, store.ErrConflict
		}
		return true, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return false, err
	}

	for _, e := range entries {
		if _, err := tx.Exec(ctx, `
			INSERT INTO wallet_balances (account_id, resource_id, amount, version)
			VALUES ($1::uuid, $2, 0, 0)
			ON CONFLICT (account_id, resource_id) DO NOTHING`,
			string(accountID), e.ResourceID); err != nil {
			return false, err
		}
		var amt int64
		if err := tx.QueryRow(ctx,
			`SELECT amount FROM wallet_balances WHERE account_id = $1::uuid AND resource_id = $2 FOR UPDATE`,
			string(accountID), e.ResourceID).Scan(&amt); err != nil {
			return false, err
		}
		if amt+e.Delta < 0 {
			return false, store.ErrInsufficient
		}
	}
	for _, e := range entries {
		if _, err := tx.Exec(ctx, `
			UPDATE wallet_balances
			SET amount = amount + $3, version = version + 1
			WHERE account_id = $1::uuid AND resource_id = $2`,
			string(accountID), e.ResourceID, e.Delta); err != nil {
			return false, err
		}
		if _, err := tx.Exec(ctx, `
			INSERT INTO wallet_ledger (account_id, resource_id, delta, source_type, source_id, period_key, config_version, idempotency_key, created_at)
			VALUES ($1::uuid, $2, $3, $4, $5, $6, $7, $8, $9)`,
			string(accountID), e.ResourceID, e.Delta, e.SourceType, e.SourceID, e.PeriodKey, e.ConfigVersion, idempotencyKey, now); err != nil {
			return false, err
		}
	}
	if _, err := tx.Exec(ctx, `
		INSERT INTO idempotency_keys (account_id, key, request_hash, response_json, status_code, created_at)
		VALUES ($1::uuid, $2, $3, $4, $5, $6)`,
		string(accountID), idempotencyKey, requestHash, response, statusCode, now); err != nil {
		return false, err
	}
	return false, nil
}

func advisoryLockKey(s string) int64 {
	h := fnv.New64a()
	_, _ = h.Write([]byte(s))
	sum := h.Sum(nil)
	// signed int64 for pg_advisory_xact_lock(bigint)
	return int64(binary.BigEndian.Uint64(sum))
}
