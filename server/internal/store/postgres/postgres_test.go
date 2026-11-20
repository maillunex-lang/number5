package postgres

import (
	"os"
	"testing"
)

func TestOpenSkippedWithoutDatabaseURL(t *testing.T) {
	if os.Getenv("DATABASE_URL") != "" {
		t.Skip("DATABASE_URL set — use integration env for live Open")
	}
	// Package must compile; live Open is blocked without Docker/VPS.
}
