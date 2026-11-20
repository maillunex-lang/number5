package content

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
)

type Catalog struct {
	Root     string
	Version  string
	Heroes   HeroesDoc
	Gacha    GachaDoc
	Loot     LootDoc
	Campaign CampaignDoc
	Liveops  LiveopsDoc
	Mail     MailDoc
	Enemies  EnemiesDoc
	Economy  EconomyDoc
}

type EconomyDoc struct {
	Mode       string          `json:"mode"`
	Offers     []StoreOffer    `json:"offers"`
	Categories json.RawMessage `json:"categories"`
}

type StoreOffer struct {
	SKU              string           `json:"sku"`
	Title            string           `json:"title"`
	NominalPriceRub  int              `json:"nominal_price_rub"`
	PayablePriceRub  int              `json:"payable_price_rub"`
	Type             string           `json:"type"`
	Grants           []Cost         `json:"grants"`
	VipXP            int            `json:"vip_xp"`
	Limits           map[string]any `json:"limits"`
	Enabled          bool           `json:"enabled"`
	CTA              string         `json:"cta"`
}

type HeroesDoc struct {
	Heroes       []map[string]any `json:"heroes"`
	DefaultSquad []string         `json:"default_squad"`
}

type GachaDoc struct {
	Banners []Banner `json:"banners"`
	DupeTo  int      `json:"dupe_to_shards"`
}

type Banner struct {
	ID          string                       `json:"id"`
	Name        string                       `json:"name"`
	CostX1      []Cost                       `json:"cost_x1"`
	CostX10     []Cost                       `json:"cost_x10"`
	RatesBP      map[string]int `json:"rates_bp"`
	Pity         map[string]any `json:"pity"`
	X10Guarantee string         `json:"x10_guarantee"`
	Pools       map[string][]string          `json:"pools"`
	Enabled     bool                         `json:"enabled"`
}

type Cost struct {
	ResourceID string `json:"resource_id"`
	Amount     int64  `json:"amount"`
}

type LootDoc struct {
	StageBindings []StageLoot `json:"stage_bindings"`
}

type StageLoot struct {
	StageID      string         `json:"stage_id"`
	LootTableID  string         `json:"loot_table_id"`
	FirstClear   map[string]int `json:"first_clear"`
	StageKind    string         `json:"stage_kind"`
}

type CampaignDoc struct {
	CurrentStage string           `json:"current_stage"`
	Stages       []map[string]any `json:"stages"`
}

type LiveopsDoc struct {
	AFK AFKConfig `json:"afk"`
}

type AFKConfig struct {
	UnlockStage      string         `json:"unlock_stage"`
	CapHours         float64        `json:"cap_hours"`
	MinClaimSeconds  int            `json:"min_claim_seconds"`
	RatesByChapter   []AFKRate      `json:"rates_by_chapter"`
}

type AFKRate struct {
	Chapter       int   `json:"chapter"`
	GoldPerHour   int64 `json:"gold_per_hour"`
	HeroXPPerHour int64 `json:"hero_xp_per_hour"`
	EssencePerHour int64 `json:"essence_per_hour"`
}

type MailDoc struct {
	Templates []map[string]any `json:"templates"`
	DemoInbox []DemoMail       `json:"demo_inbox"`
}

type DemoMail struct {
	ID          string `json:"id"`
	TemplateID  string `json:"template_id"`
	Category    string `json:"category"`
	Title       string `json:"title"`
	Body        string `json:"body"`
	Unread      bool   `json:"unread"`
}

type EnemiesDoc struct {
	Encounters []Encounter `json:"encounters"`
}

type Encounter struct {
	StageID string          `json:"stage_id"`
	Slots   []map[string]any `json:"slots"`
}

var (
	catalogMu sync.Mutex
	cached    *Catalog
)

func LoadCatalog(root string) (*Catalog, error) {
	catalogMu.Lock()
	defer catalogMu.Unlock()
	if cached != nil && cached.Root == root {
		return cached, nil
	}
	info, err := ReadActive(root)
	if err != nil {
		return nil, err
	}
	base := filepath.Join(root, info.Version)
	c := &Catalog{Root: root, Version: info.Version}
	if err := readJSON(filepath.Join(base, "heroes.json"), &c.Heroes); err != nil {
		return nil, err
	}
	if err := readJSON(filepath.Join(base, "gacha.json"), &c.Gacha); err != nil {
		return nil, err
	}
	if c.Gacha.DupeTo == 0 {
		c.Gacha.DupeTo = 30
	}
	if err := readJSON(filepath.Join(base, "loot_tables.json"), &c.Loot); err != nil {
		return nil, err
	}
	if err := readJSON(filepath.Join(base, "campaign.json"), &c.Campaign); err != nil {
		return nil, err
	}
	if err := readJSON(filepath.Join(base, "liveops.json"), &c.Liveops); err != nil {
		return nil, err
	}
	if err := readJSON(filepath.Join(base, "mail.json"), &c.Mail); err != nil {
		return nil, err
	}
	if err := readJSON(filepath.Join(base, "enemies.json"), &c.Enemies); err != nil {
		return nil, err
	}
	if err := readJSON(filepath.Join(base, "economy.json"), &c.Economy); err != nil {
		return nil, err
	}
	cached = c
	return c, nil
}

func (c *Catalog) Offer(sku string) (StoreOffer, bool) {
	for _, o := range c.Economy.Offers {
		if o.SKU == sku {
			return o, true
		}
	}
	return StoreOffer{}, false
}

func (c *Catalog) StageLoot(stageID string) (StageLoot, bool) {
	for _, b := range c.Loot.StageBindings {
		if b.StageID == stageID {
			return b, true
		}
	}
	return StageLoot{}, false
}

func (c *Catalog) Banner(id string) (Banner, bool) {
	for _, b := range c.Gacha.Banners {
		if b.ID == id {
			return b, true
		}
	}
	return Banner{}, false
}

func (c *Catalog) Encounter(stageID string) (Encounter, bool) {
	for _, e := range c.Enemies.Encounters {
		if e.StageID == stageID {
			return e, true
		}
	}
	return Encounter{}, false
}

func (c *Catalog) NextStage(stageID string) string {
	for i, s := range c.Campaign.Stages {
		id, _ := s["id"].(string)
		if id == stageID && i+1 < len(c.Campaign.Stages) {
			nid, _ := c.Campaign.Stages[i+1]["id"].(string)
			return nid
		}
	}
	return stageID
}

func (c *Catalog) HeroRarity(heroID string) string {
	for _, h := range c.Heroes.Heroes {
		if fmt.Sprint(h["id"]) == heroID {
			if rc, ok := h["rarity_code"].(string); ok && rc != "" {
				return rc
			}
			if r, ok := h["rarity"].(string); ok {
				switch r {
				case "common":
					return "N"
				case "rare":
					return "R"
				case "epic":
					return "SR"
				case "legendary":
					return "SSR"
				}
			}
		}
	}
	return "N"
}

func readJSON(path string, dest any) error {
	raw, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	return json.Unmarshal(raw, dest)
}
