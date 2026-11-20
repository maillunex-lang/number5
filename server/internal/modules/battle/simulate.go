package battle

import (
	"fmt"
	"math"

	"github.com/maillunex-lang/number5/server/internal/modules/content"
)

type combatUnit struct {
	ID      string
	Name    string
	Side    string // ally | enemy
	HP      float64
	MaxHP   float64
	Atk     float64
	Energy  float64
	Alive   bool
	Tint    string
	EnemyID string
}

// simulate runs a deterministic auto-combat and returns victory + compact timeline for client playback.
func simulate(seed int64, squad []string, enc content.Encounter, cat *content.Catalog) (bool, []map[string]any) {
	rng := newBattleRNG(seed)
	stagePower := 10000
	if cat != nil {
		stagePower = cat.StagePower(enc.StageID)
	}

	allies := make([]*combatUnit, 0, len(squad))
	for _, id := range squad {
		u := buildAlly(id, cat)
		allies = append(allies, u)
	}
	enemies := buildEnemies(enc, stagePower, cat)

	tl := make([]map[string]any, 0, 64)
	tl = append(tl, map[string]any{
		"t":       0.0,
		"type":    "start",
		"allies":  unitsSnapshot(allies),
		"enemies": unitsSnapshot(enemies),
	})

	const tick = 0.35
	const maxT = 90.0
	t := 0.0
	for t < maxT {
		if !anyAlive(allies) || !anyAlive(enemies) {
			break
		}
		t += tick
		order := livingUnits(allies, enemies)
		rng.Shuffle(len(order), func(i, j int) { order[i], order[j] = order[j], order[i] })

		for _, u := range order {
			if !u.Alive {
				continue
			}
			targets := enemies
			if u.Side == "enemy" {
				targets = allies
			}
			living := livingOnly(targets)
			if len(living) == 0 {
				continue
			}
			u.Energy = math.Min(100, u.Energy+18+rng.Float64()*10)
			target := living[rng.Intn(len(living))]
			dmg := u.Atk * (0.85 + rng.Float64()*0.3)
			skill := u.Energy >= 100
			if skill {
				dmg *= 1.85
				u.Energy = 0
			}
			target.HP = math.Max(0, target.HP-dmg)
			ev := map[string]any{
				"t":      round1(t),
				"type":   "hit",
				"actor":  u.ID,
				"target": target.ID,
				"damage": int(math.Round(dmg)),
				"skill":  skill,
				"hp":     int(math.Round(target.HP)),
				"energy": int(math.Round(u.Energy)),
			}
			tl = append(tl, ev)
			if target.HP <= 0 && target.Alive {
				target.Alive = false
				tl = append(tl, map[string]any{
					"t":    round1(t),
					"type": "death",
					"unit": target.ID,
				})
			}
		}
	}

	victory := anyAlive(allies) && !anyAlive(enemies)
	if anyAlive(allies) && anyAlive(enemies) {
		// timeout: higher remaining HP ratio wins
		victory = totalHP(allies) >= totalHP(enemies)
	}
	tl = append(tl, map[string]any{
		"t":       round1(math.Min(t, maxT)),
		"type":    "end",
		"victory": victory,
	})
	return victory, tl
}

func buildAlly(heroID string, cat *content.Catalog) *combatUnit {
	name := heroID
	hp := 1200.0
	atk := 140.0
	tint := "#888888"
	if cat != nil {
		if h, ok := cat.HeroByID(heroID); ok {
			if n, ok := h["name"].(string); ok && n != "" {
				name = n
			}
			if t, ok := h["tint"].(string); ok {
				tint = t
			}
			level := asInt(h["level"], 1)
			base, _ := h["base_stats"].(map[string]any)
			if base != nil {
				baseHP := asFloat(base["hp"], 1000)
				baseAtk := asFloat(base["atk"], 120)
				hp = math.Round(baseHP * (1.0 + 0.075*float64(level-1)))
				atk = math.Round(baseAtk * (1.0 + 0.060*float64(level-1)))
			}
		}
	}
	return &combatUnit{ID: heroID, Name: name, Side: "ally", HP: hp, MaxHP: hp, Atk: atk, Alive: true, Tint: tint}
}

func buildEnemies(enc content.Encounter, stagePower int, cat *content.Catalog) []*combatUnit {
	out := make([]*combatUnit, 0, len(enc.Slots))
	if len(enc.Slots) == 0 {
		for i := 0; i < 5; i++ {
			hp := float64(800 + stagePower/12 + i*40)
			atk := float64(90 + stagePower/100 + i*8)
			id := fmt.Sprintf("e_%s_%d", enc.StageID, i)
			out = append(out, &combatUnit{
				ID: id, Name: "Враг разлома", Side: "enemy",
				HP: hp, MaxHP: hp, Atk: atk, Alive: true, Tint: "#6A5A50",
			})
		}
		return out
	}
	for i, slot := range enc.Slots {
		eid := fmt.Sprint(slot["enemy_id"])
		level := asInt(slot["level"], 5)
		tier := fmt.Sprint(slot["tier"])
		mult := 1.0
		switch tier {
		case "elite":
			mult = 1.35
		case "boss":
			mult = 2.2
		}
		name := eid
		tint := "#6A5A50"
		if cat != nil {
			meta := cat.EnemyMeta(eid)
			if n, ok := meta["name"].(string); ok && n != "" {
				name = n
			}
		}
		hp := float64(int(float64(900+stagePower/14+level*35) * mult))
		atk := float64(int(float64(95+stagePower/110+level*6) * mult))
		id := fmt.Sprintf("%s_%d", eid, i)
		out = append(out, &combatUnit{
			ID: id, Name: name, Side: "enemy", EnemyID: eid,
			HP: hp, MaxHP: hp, Atk: atk, Alive: true, Tint: tint,
		})
	}
	return out
}

func unitsSnapshot(units []*combatUnit) []map[string]any {
	out := make([]map[string]any, 0, len(units))
	for _, u := range units {
		out = append(out, map[string]any{
			"id":       u.ID,
			"name":     u.Name,
			"side":     u.Side,
			"hp":       int(math.Round(u.MaxHP)),
			"max_hp":   int(math.Round(u.MaxHP)),
			"atk":      int(math.Round(u.Atk)),
			"tint":     u.Tint,
			"enemy_id": u.EnemyID,
		})
	}
	return out
}

func livingUnits(allies, enemies []*combatUnit) []*combatUnit {
	out := make([]*combatUnit, 0, len(allies)+len(enemies))
	out = append(out, livingOnly(allies)...)
	out = append(out, livingOnly(enemies)...)
	return out
}

func livingOnly(units []*combatUnit) []*combatUnit {
	out := make([]*combatUnit, 0, len(units))
	for _, u := range units {
		if u.Alive {
			out = append(out, u)
		}
	}
	return out
}

func anyAlive(units []*combatUnit) bool {
	for _, u := range units {
		if u.Alive {
			return true
		}
	}
	return false
}

func totalHP(units []*combatUnit) float64 {
	sum := 0.0
	for _, u := range units {
		if u.Alive {
			sum += u.HP
		}
	}
	return sum
}

func round1(v float64) float64 {
	return math.Round(v*10) / 10
}

func asInt(v any, def int) int {
	switch n := v.(type) {
	case float64:
		return int(n)
	case int:
		return n
	case int64:
		return int(n)
	default:
		return def
	}
}

func asFloat(v any, def float64) float64 {
	switch n := v.(type) {
	case float64:
		return n
	case int:
		return float64(n)
	case int64:
		return float64(n)
	default:
		return def
	}
}

// battleRNG is a tiny deterministic LCG so tests stay stable without math/rand global state.
type battleRNG struct{ state uint64 }

func newBattleRNG(seed int64) *battleRNG {
	s := uint64(seed)
	if s == 0 {
		s = 0x9e3779b97f4a7c15
	}
	return &battleRNG{state: s}
}

func (r *battleRNG) next() uint64 {
	r.state = r.state*6364136223846793005 + 1
	return r.state
}

func (r *battleRNG) Float64() float64 {
	return float64(r.next()>>11) / (1 << 53)
}

func (r *battleRNG) Intn(n int) int {
	if n <= 0 {
		return 0
	}
	return int(r.next() % uint64(n))
}

func (r *battleRNG) Shuffle(n int, swap func(i, j int)) {
	for i := n - 1; i > 0; i-- {
		j := r.Intn(i + 1)
		swap(i, j)
	}
}
