package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/maillunex-lang/number5/server/internal/config"
	"github.com/maillunex-lang/number5/server/internal/httpapi"
	"github.com/maillunex-lang/number5/server/internal/modules/afk"
	"github.com/maillunex-lang/number5/server/internal/modules/auth"
	"github.com/maillunex-lang/number5/server/internal/modules/battle"
	"github.com/maillunex-lang/number5/server/internal/modules/campaign"
	"github.com/maillunex-lang/number5/server/internal/modules/content"
	"github.com/maillunex-lang/number5/server/internal/modules/heroes"
	"github.com/maillunex-lang/number5/server/internal/modules/mail"
	"github.com/maillunex-lang/number5/server/internal/modules/shop"
	"github.com/maillunex-lang/number5/server/internal/modules/summon"
	"github.com/maillunex-lang/number5/server/internal/modules/wallet"
	"github.com/maillunex-lang/number5/server/internal/store"
	"github.com/maillunex-lang/number5/server/internal/store/postgres"
)

func main() {
	cfg := config.Load()
	cat, err := content.LoadCatalog(cfg.ContentPackagesRoot)
	if err != nil {
		log.Printf("warning: content catalog: %v (some modules may fail)", err)
	}
	starterHeroes := []string{"H01", "H02", "H03", "H04", "H05"}
	if cat != nil && len(cat.Heroes.DefaultSquad) > 0 {
		starterHeroes = cat.Heroes.DefaultSquad
	}
	cfgVer := "unknown"
	if cat != nil {
		cfgVer = cat.Version
	}

	st, storeName := openStore(cfg)
	deps := httpapi.Deps{
		Config:   cfg,
		Store:    st,
		Auth:     &auth.Service{Store: st, StarterHeroes: starterHeroes},
		Wallet:   &wallet.Service{Store: st, ConfigVersion: cfgVer, AllowTestGrant: cfg.AppEnv == "dev" || cfg.AppEnv == "test"},
		Heroes:   &heroes.Service{Store: st},
		Campaign: &campaign.Service{Store: st},
	}
	if cat != nil {
		deps.Battle = &battle.Service{Store: st, Catalog: cat}
		deps.Summon = &summon.Service{Store: st, Catalog: cat}
		deps.AFK = &afk.Service{Store: st, Catalog: cat}
		deps.Mail = &mail.Service{Store: st, Catalog: cat}
		deps.Shop = &shop.Service{Store: st, Catalog: cat}
	}
	mux := httpapi.NewMux(deps)
	log.Printf("lunex-api listening on %s (env=%s store=%s config=%s)", cfg.HTTPAddr, cfg.AppEnv, storeName, cfgVer)
	if err := http.ListenAndServe(cfg.HTTPAddr, mux); err != nil {
		log.Println(err)
		os.Exit(1)
	}
}

func openStore(cfg config.Config) (store.Store, string) {
	if cfg.DatabaseURL == "" {
		log.Printf("store: memory (set DATABASE_URL for postgres)")
		return store.NewMemory(nil), "memory"
	}
	ctx, cancel := context.WithTimeout(context.Background(), 8*time.Second)
	defer cancel()
	pg, err := postgres.Open(ctx, cfg.DatabaseURL, nil)
	if err != nil {
		log.Printf("store: postgres unavailable (%v) · falling back to memory", err)
		return store.NewMemory(nil), "memory"
	}
	mig := filepath.Join("migrations", "0001_init.sql")
	if _, err := os.Stat(mig); err != nil {
		mig = filepath.Join("..", "migrations", "0001_init.sql")
	}
	if err := pg.Migrate(ctx, mig); err != nil {
		log.Printf("store: migrate failed (%v) · falling back to memory", err)
		pg.Close()
		return store.NewMemory(nil), "memory"
	}
	log.Printf("store: postgres")
	return pg, "postgres"
}
