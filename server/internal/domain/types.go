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
