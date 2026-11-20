package battle

import (
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"fmt"
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

type StartRequest struct {
	StageID        string `json:"stage_id"`
	Mode           string `json:"mode"`
	IdempotencyKey string `json:"idempotency_key"`
}

type BattleResponse struct {
	BattleID      string           `json:"battle_id"`
	StageID       string           `json:"stage_id"`
	Victory       bool             `json:"victory"`
	Seed          int64            `json:"seed"`
	Timeline      []map[string]any `json:"timeline"`
	ConfigVersion string           `json:"config_version"`
	Claimed       bool             `json:"claimed"`
	Replayed      bool             `json:"replayed,omitempty"`
}

type ClaimResponse struct {
	BattleID string           `json:"battle_id"`
	Rewards  map[string]int64 `json:"rewards"`
	Replayed bool             `json:"replayed"`
	Progress campaignLite     `json:"progress"`
}

type campaignLite struct {
	CurrentStage string `json:"current_stage"`
}

func (s *Service) now() time.Time {
	if s.Clock != nil {
		return s.Clock.Now()
	}
	return time.Now().UTC()
}

func (s *Service) Start(accountID domain.AccountID, req StartRequest) (status int, body []byte, err error) {
	if req.StageID == "" || req.IdempotencyKey == "" {
		return 422, errJSON("invalid", "stage_id and idempotency_key required"), nil
	}
	if req.Mode == "" {
		req.Mode = "campaign"
	}
	hash := hashStart(req)
	if rec, e := s.Store.GetIdempotency(accountID, req.IdempotencyKey); e == nil {
		if rec.RequestHash != hash {
			return 409, errJSON("conflict", "idempotency key reused with different payload"), nil
		}
		var cached BattleResponse
		_ = json.Unmarshal(rec.ResponseJSON, &cached)
		cached.Replayed = true
		return rec.StatusCode, mustJSON(cached), nil
	}

	prog, err := s.Store.GetCampaign(accountID)
	if err != nil {
		return 500, errJSON("internal", err.Error()), nil
	}
	// Allow current stage or already cleared stages for replay.
	if req.StageID != prog.CurrentStage {
		if _, ok := prog.Stages[req.StageID]; !ok {
			return 403, errJSON("forbidden", "stage not available"), nil
		}
	}

	form, err := s.Store.GetFormation(accountID, req.Mode)
	if err != nil {
		return 500, errJSON("internal", err.Error()), nil
	}
	squad := []string{}
	for _, id := range form.Slots {
		if id != "" {
			squad = append(squad, id)
		}
	}
	if len(squad) == 0 {
		return 422, errJSON("invalid", "empty formation"), nil
	}

	enc, ok := s.Catalog.Encounter(req.StageID)
	if !ok {
		return 404, errJSON("not_found", "encounter missing for stage"), nil
	}

	seed := seedFrom(accountID, req.StageID, req.IdempotencyKey)
	victory, timeline := simulate(seed, squad, enc)

	b := domain.BattleInstance{
		ID: store.NewID("bat"), AccountID: accountID, Mode: req.Mode, StageID: req.StageID,
		Squad: squad, Seed: seed, Status: "finished", Victory: victory, Timeline: timeline,
		ConfigVersion: s.Catalog.Version, StartedAt: s.now(), FinishedAt: s.now(),
	}
	if err := s.Store.SaveBattle(b); err != nil {
		return 500, errJSON("internal", err.Error()), nil
	}
	out := BattleResponse{
		BattleID: b.ID, StageID: b.StageID, Victory: victory, Seed: seed,
		Timeline: timeline, ConfigVersion: b.ConfigVersion,
	}
	body = mustJSON(out)
	_, err = s.Store.ApplyLedger(accountID, nil, req.IdempotencyKey, hash, body, 200)
	if err != nil && err != store.ErrConflict {
		// Allow empty ledger idempotency record via ApplyLedger with nil entries — need to support that
		return 500, errJSON("internal", err.Error()), nil
	}
	if patcher, ok := s.Store.(interface {
		PatchIdempotencyResponse(domain.AccountID, string, []byte, int) error
	}); ok {
		_ = patcher.PatchIdempotencyResponse(accountID, req.IdempotencyKey, body, 200)
	}
	return 200, body, nil
}

func (s *Service) Claim(accountID domain.AccountID, battleID, idempotencyKey string) (status int, body []byte, err error) {
	if battleID == "" || idempotencyKey == "" {
		return 422, errJSON("invalid", "battle id and idempotency_key required"), nil
	}
	hash := hashClaim(battleID, idempotencyKey)
	if rec, e := s.Store.GetIdempotency(accountID, idempotencyKey); e == nil {
		if rec.RequestHash != hash {
			return 409, errJSON("conflict", "idempotency key reused with different payload"), nil
		}
		var cached ClaimResponse
		_ = json.Unmarshal(rec.ResponseJSON, &cached)
		cached.Replayed = true
		return rec.StatusCode, mustJSON(cached), nil
	}

	b, err := s.Store.GetBattle(battleID)
	if err != nil {
		return 404, errJSON("not_found", "battle not found"), nil
	}
	if b.AccountID != accountID {
		return 403, errJSON("forbidden", "not your battle"), nil
	}
	if !b.Victory {
		return 422, errJSON("invalid", "cannot claim defeat"), nil
	}
	if b.Claimed {
		return 409, errJSON("conflict", "already claimed"), nil
	}

	rewards := map[string]int64{}
	loot, ok := s.Catalog.StageLoot(b.StageID)
	prog, _ := s.Store.GetCampaign(accountID)
	first := true
	if st, ok2 := prog.Stages[b.StageID]; ok2 && st.FirstClearClaimed {
		first = false
	}
	if ok && first {
		for k, v := range loot.FirstClear {
			rewards[k] = int64(v)
		}
	} else {
		rewards["gold"] = 500
		rewards["hero_xp"] = 200
	}

	entries := make([]domain.LedgerEntry, 0, len(rewards))
	for rid, amt := range rewards {
		entries = append(entries, domain.LedgerEntry{
			ResourceID: rid, Delta: amt, SourceType: "battle_claim", SourceID: battleID,
			ConfigVersion: s.Catalog.Version,
		})
	}
	bodyPlaceholder := []byte(`{}`)
	_, err = s.Store.ApplyLedger(accountID, entries, idempotencyKey, hash, bodyPlaceholder, 200)
	if err != nil {
		if err == store.ErrConflict {
			return 409, errJSON("conflict", err.Error()), nil
		}
		return 500, errJSON("internal", err.Error()), nil
	}
	_ = s.Store.MarkBattleClaimed(battleID)

	// update campaign
	st := prog.Stages[b.StageID]
	st.StageID = b.StageID
	st.Clears++
	st.Stars = 3
	st.FirstClearClaimed = true
	prog.Stages[b.StageID] = st
	if b.StageID == prog.CurrentStage {
		prog.CurrentStage = s.Catalog.NextStage(b.StageID)
	}
	_ = s.Store.SaveCampaign(accountID, prog)

	out := ClaimResponse{
		BattleID: battleID, Rewards: rewards, Progress: campaignLite{CurrentStage: prog.CurrentStage},
	}
	body = mustJSON(out)
	if patcher, ok := s.Store.(interface {
		PatchIdempotencyResponse(domain.AccountID, string, []byte, int) error
	}); ok {
		_ = patcher.PatchIdempotencyResponse(accountID, idempotencyKey, body, 200)
	}
	return 200, body, nil
}

func simulate(seed int64, squad []string, enc content.Encounter) (bool, []map[string]any) {
	// Deterministic lightweight sim: squad size vs encounter power proxy.
	power := int64(len(squad)) * 1000
	enemyPower := int64(len(enc.Slots)) * 700
	r := seed%100 + 1
	victory := power+r >= enemyPower
	tl := []map[string]any{
		{"t": 0, "type": "start", "squad": squad, "enemies": len(enc.Slots)},
		{"t": 30, "type": "tick", "note": "auto combat"},
		{"t": 90, "type": "end", "victory": victory},
	}
	return victory, tl
}

func seedFrom(accountID domain.AccountID, stageID, key string) int64 {
	sum := sha256.Sum256([]byte(string(accountID) + "|" + stageID + "|" + key))
	return int64(binary.BigEndian.Uint64(sum[:8]) & 0x7fffffffffffffff)
}

func hashStart(req StartRequest) string {
	raw := fmt.Sprintf("%s|%s|%s", req.StageID, req.Mode, req.IdempotencyKey)
	sum := sha256.Sum256([]byte(raw))
	return hex.EncodeToString(sum[:])
}

func hashClaim(battleID, key string) string {
	sum := sha256.Sum256([]byte(battleID + "|" + key))
	return hex.EncodeToString(sum[:])
}

func mustJSON(v any) []byte {
	b, _ := json.Marshal(v)
	return b
}

func errJSON(code, message string) []byte {
	return mustJSON(map[string]any{"error": map[string]string{"code": code, "message": message}})
}
