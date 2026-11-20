package domain

import "time"

type AccountID string

type Account struct {
	ID        AccountID
	Email     string
	IsGuest   bool
	Status    string
	CreatedAt time.Time
}

type Session struct {
	Token     string
	AccountID AccountID
	ExpiresAt time.Time
}

type Balance struct {
	ResourceID string `json:"resource_id"`
	Amount     int64  `json:"amount"`
	Version    int    `json:"version"`
}

type LedgerEntry struct {
	ID             string
	AccountID      AccountID
	ResourceID     string
	Delta          int64
	SourceType     string
	SourceID       string
	PeriodKey      string
	ConfigVersion  string
	IdempotencyKey string
	CreatedAt      time.Time
}

type IdempotencyRecord struct {
	AccountID    AccountID
	Key          string
	RequestHash  string
	ResponseJSON []byte
	StatusCode   int
	CreatedAt    time.Time
}

type HeroOwned struct {
	HeroID string `json:"hero_id"`
	Stars  int    `json:"stars"`
	Level  int    `json:"level"`
	Shards int    `json:"shards"`
}

type Formation struct {
	Mode  string   `json:"mode"`
	Slots []string `json:"slots"` // 5 hero ids
}

type CampaignProgress struct {
	CurrentStage    string         `json:"current_stage"`
	UnlockedChapter int            `json:"unlocked_chapter"`
	Stages          map[string]StageClear `json:"-"`
}

type StageClear struct {
	StageID            string
	Stars              int
	Clears             int
	FirstClearClaimed  bool
}

type BattleInstance struct {
	ID            string
	AccountID     AccountID
	Mode          string
	StageID       string
	Squad         []string
	Seed          int64
	Status        string // finished
	Victory       bool
	Timeline      []map[string]any
	ConfigVersion string
	StartedAt     time.Time
	FinishedAt    time.Time
	Claimed       bool
}

type PityState struct {
	BannerID string `json:"banner_id"`
	SSR      int    `json:"ssr"`
	UR       int    `json:"ur"`
}

type AFKState struct {
	LastClaimAt time.Time `json:"last_claim_at"`
	Chapter     int       `json:"chapter"`
}

type MailMessage struct {
	ID          string         `json:"id"`
	TemplateID  string         `json:"template_id"`
	Category    string         `json:"category"`
	Subject     string         `json:"subject"`
	Body        string         `json:"body"`
	Status      string         `json:"status"` // unread|read|claimed
	Attachments []MailAttach   `json:"attachments"`
	CreatedAt   time.Time      `json:"created_at"`
	ExpiresAt   *time.Time     `json:"expires_at,omitempty"`
}

type MailAttach struct {
	ResourceID string `json:"resource_id"`
	Amount     int64  `json:"amount"`
	Claimed    bool   `json:"claimed"`
}
