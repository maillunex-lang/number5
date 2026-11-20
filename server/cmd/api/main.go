package main

import (
	"log"
	"net/http"
	"os"

	"github.com/maillunex-lang/number5/server/internal/config"
	"github.com/maillunex-lang/number5/server/internal/httpapi"
	"github.com/maillunex-lang/number5/server/internal/modules/afk"
	"github.com/maillunex-lang/number5/server/internal/modules/auth"
	"github.com/maillunex-lang/number5/server/internal/modules/battle"
	"github.com/maillunex-lang/number5/server/internal/modules/campaign"
	"github.com/maillunex-lang/number5/server/internal/modules/content"
	"github.com/maillunex-lang/number5/server/internal/modules/heroes"
	"github.com/maillunex-lang/number5/server/internal/modules/mail"
	"github.com/maillunex-lang/number5/server/internal/modules/summon"
	"github.com/maillunex-lang/number5/server/internal/modules/wallet"
	"github.com/maillunex-lang/number5/server/internal/store"
)

func main() {
	cfg := config.Load()
	cat, err := content.LoadCatalog(cfg.ContentPackagesRoot)
	if err != nil {
		log.Printf("warning: content catalog: %v (some modules may fail)", err)
	}
	mem := store.NewMemory(nil)
	starter := []string{"H01", "H02", "H03", "H04", "H05"}
	if cat != nil && len(cat.Heroes.DefaultSquad) > 0 {
		starter = cat.Heroes.DefaultSquad
	}
	cfgVer := "unknown"
	if cat != nil {
		cfgVer = cat.Version
	}
	deps := httpapi.Deps{
		Config: cfg,
		Store:  mem,
		Auth:   &auth.Service{Store: mem, StarterHeroes: starter},
		Wallet: &wallet.Service{Store: mem, ConfigVersion: cfgVer, AllowTestGrant: cfg.AppEnv == "dev" || cfg.AppEnv == "test"},
		Heroes: &heroes.Service{Store: mem},
		Campaign: &campaign.Service{Store: mem},
	}
	if cat != nil {
		deps.Battle = &battle.Service{Store: mem, Catalog: cat}
		deps.Summon = &summon.Service{Store: mem, Catalog: cat}
		deps.AFK = &afk.Service{Store: mem, Catalog: cat}
		deps.Mail = &mail.Service{Store: mem, Catalog: cat}
	}
	mux := httpapi.NewMux(deps)
	log.Printf("lunex-api listening on %s (env=%s store=memory config=%s)", cfg.HTTPAddr, cfg.AppEnv, cfgVer)
	if err := http.ListenAndServe(cfg.HTTPAddr, mux); err != nil {
		log.Println(err)
		os.Exit(1)
	}
}
