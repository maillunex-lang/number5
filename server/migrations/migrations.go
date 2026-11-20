// Package migrations embeds the versioned PostgreSQL schema in the API binary.
package migrations

import (
	"context"
	"embed"
	"fmt"
	"io/fs"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

//go:embed *.sql
var scripts embed.FS

// Apply serializes startup across API replicas and records only committed scripts.
func Apply(ctx context.Context, pool *pgxpool.Pool) error {
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, "SELECT pg_advisory_xact_lock(5829317001)"); err != nil {
			return err
		}
		if _, err := tx.Exec(ctx, "CREATE TABLE IF NOT EXISTS lunex_schema_migrations (filename text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())"); err != nil {
			return err
		}
		names, err := fs.Glob(scripts, "*.sql")
		if err != nil {
			return err
		}
		for _, name := range names {
			var applied bool
			if err := tx.QueryRow(ctx, "SELECT EXISTS (SELECT 1 FROM lunex_schema_migrations WHERE filename=$1)", name).Scan(&applied); err != nil {
				return err
			}
			if applied {
				continue
			}
			sql, err := scripts.ReadFile(name)
			if err != nil {
				return err
			}
			if _, err := tx.Exec(ctx, string(sql)); err != nil {
				return fmt.Errorf("apply %s: %w", name, err)
			}
			if _, err := tx.Exec(ctx, "INSERT INTO lunex_schema_migrations(filename) VALUES ($1)", name); err != nil {
				return err
			}
		}
		return nil
	})
}
