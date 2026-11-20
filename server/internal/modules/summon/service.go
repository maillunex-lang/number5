package summon

import (
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"math/rand"

	"github.com/maillunex-lang/number5/server/internal/domain"
	"github.com/maillunex-lang/number5/server/internal/modules/content"
	"github.com/maillunex-lang/number5/server/internal/store"
)

type Service struct {
	Store   store.Store
	Catalog *content.Catalog
}

type RollRequest struct {
	BannerID       string `json:"banner_id"`
	Count          int    `json:"count"` // 1 or 10
	IdempotencyKey string `json:"idempotency_key"`
}

type RollResult struct {
	HeroID   string `json:"hero_id"`
	Rarity   string `json:"rarity"`
	IsNew    bool   `json:"is_new"`
	Shards   int    `json:"shards_gained"`
	Position int    `json:"position"`
}

type RollResponse struct {
	OrderID  string       `json:"order_id"`
	BannerID string       `json:"banner_id"`
	Results  []RollResult `json:"results"`
	Pity     domain.PityState `json:"pity"`
	Replayed bool         `json:"replayed,omitempty"`
}

func (s *Service) Banners() []content.Banner {
	out := []content.Banner{}
	for _, b := range s.Catalog.Gacha.Banners {
		if b.Enabled {
			out = append(out, b)
		}
	}
	return out
}

func (s *Service) Pity(accountID domain.AccountID) ([]domain.PityState, error) {
	out := []domain.PityState{}
	for _, b := range s.Catalog.Gacha.Banners {
		p, err := s.Store.GetPity(accountID, b.ID)
		if err != nil {
			p = domain.PityState{BannerID: b.ID}
		}
		if p.BannerID == "" {
			p.BannerID = b.ID
		}
		out = append(out, p)
	}
	return out, nil
}

func (s *Service) Roll(accountID domain.AccountID, req RollRequest) (status int, body []byte, err error) {
	if req.BannerID == "" || req.IdempotencyKey == "" || (req.Count != 1 && req.Count != 10) {
		return 422, errJSON("invalid", "banner_id, count 1|10, idempotency_key required"), nil
	}
	banner, ok := s.Catalog.Banner(req.BannerID)
	if !ok || !banner.Enabled {
		return 404, errJSON("not_found", "banner"), nil
	}
	hash := hashRoll(req)
	if rec, e := s.Store.GetIdempotency(accountID, req.IdempotencyKey); e == nil {
		if rec.RequestHash != hash {
			return 409, errJSON("conflict", "idempotency key reused with different payload"), nil
		}
		var cached RollResponse
		_ = json.Unmarshal(rec.ResponseJSON, &cached)
		cached.Replayed = true
		return rec.StatusCode, mustJSON(cached), nil
	}

	costs := banner.CostX1
	if req.Count == 10 {
		costs = banner.CostX10
	}
	entries := make([]domain.LedgerEntry, 0, len(costs))
	for _, c := range costs {
		entries = append(entries, domain.LedgerEntry{
			ResourceID: c.ResourceID, Delta: -c.Amount,
			SourceType: "summon_roll", SourceID: req.IdempotencyKey,
			ConfigVersion: s.Catalog.Version,
		})
	}

	var outStatus int
	err = store.Run(s.Store, accountID, func(ops store.Ops) error {
		if rec, e := ops.GetIdempotency(req.IdempotencyKey); e == nil {
			if rec.RequestHash != hash {
				outStatus = 409
				body = errJSON("conflict", "idempotency key reused with different payload")
				return nil
			}
			var cached RollResponse
			_ = json.Unmarshal(rec.ResponseJSON, &cached)
			cached.Replayed = true
			outStatus = rec.StatusCode
			body = mustJSON(cached)
			return nil
		}
		if _, e := ops.ApplyLedger(entries, req.IdempotencyKey, hash, []byte(`{}`), 200); e != nil {
			return e
		}

		pity, _ := ops.GetPity(req.BannerID)
		pity.BannerID = req.BannerID

		seedBytes := sha256.Sum256([]byte(string(accountID) + "|" + req.IdempotencyKey))
		rng := rand.New(rand.NewSource(int64(binary.BigEndian.Uint64(seedBytes[:8]))))

		owned, _ := ops.ListHeroes()
		own := map[string]domain.HeroOwned{}
		for _, h := range owned {
			own[h.HeroID] = h
		}

		results := make([]RollResult, 0, req.Count)
		for i := 0; i < req.Count; i++ {
			rarity := rollRarity(rng, banner, &pity, i, req.Count)
			heroID := pickHero(rng, banner.Pools[rarity])
			if heroID == "" {
				heroID = "H16"
				rarity = "N"
			}
			res := RollResult{HeroID: heroID, Rarity: rarity, Position: i + 1}
			if h, ok := own[heroID]; ok {
				res.IsNew = false
				res.Shards = s.Catalog.Gacha.DupeTo
				h.Shards += res.Shards
				own[heroID] = h
				if e := ops.UpsertHero(h); e != nil {
					return e
				}
			} else {
				res.IsNew = true
				h := domain.HeroOwned{HeroID: heroID, Stars: 1, Level: 1}
				own[heroID] = h
				if e := ops.UpsertHero(h); e != nil {
					return e
				}
			}
			results = append(results, res)
		}
		if e := ops.SetPity(pity); e != nil {
			return e
		}

		orderID := store.NewID("sum")
		out := RollResponse{OrderID: orderID, BannerID: req.BannerID, Results: results, Pity: pity}
		body = mustJSON(out)
		outStatus = 200
		return ops.PatchIdempotencyResponse(req.IdempotencyKey, body, 200)
	})
	if err != nil {
		if err == store.ErrInsufficient {
			return 422, errJSON("insufficient", "not enough resources"), nil
		}
		if err == store.ErrConflict {
			return 409, errJSON("conflict", err.Error()), nil
		}
		return 500, errJSON("internal", err.Error()), nil
	}
	if outStatus == 0 {
		outStatus = 200
	}
	return outStatus, body, nil
}

func rollRarity(rng *rand.Rand, banner content.Banner, pity *domain.PityState, idx, count int) string {
	pity.SSR++
	if pityInt(banner.Pity, "ur_every") > 0 {
		pity.UR++
	}
	// hard pity
	if every := pityInt(banner.Pity, "ssr_every"); every > 0 && pity.SSR >= every {
		pity.SSR = 0
		return "SSR"
	}
	if banner.Pity["ur_every"] != nil {
		_ = pityInt(banner.Pity, "ur_every")
	}
	// x10 guarantee SR+ on last pull if none yet — simplified: force SR on position 10
	if count == 10 && idx == 9 && banner.X10Guarantee == "SR+" {
		return "SR"
	}
	roll := rng.Intn(10000) // basis points
	acc := 0
	order := []string{"UR", "SSR", "SR", "R", "N"}
	for _, r := range order {
		acc += banner.RatesBP[r]
		if roll < acc {
			if r == "SSR" || r == "UR" {
				pity.SSR = 0
			}
			if r == "UR" {
				pity.UR = 0
			}
			return r
		}
	}
	return "N"
}

func pickHero(rng *rand.Rand, pool []string) string {
	if len(pool) == 0 {
		return ""
	}
	return pool[rng.Intn(len(pool))]
}

func pityInt(m map[string]any, key string) int {
	v, ok := m[key]
	if !ok || v == nil {
		return 0
	}
	switch n := v.(type) {
	case float64:
		return int(n)
	case int:
		return n
	case json.Number:
		i, _ := n.Int64()
		return int(i)
	default:
		return 0
	}
}

func hashRoll(req RollRequest) string {
	raw := fmt.Sprintf("%s|%d|%s", req.BannerID, req.Count, req.IdempotencyKey)
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
