package main

import (
	"log"
	"net/http"
	"os"

	"github.com/maillunex-lang/number5/server/internal/config"
	"github.com/maillunex-lang/number5/server/internal/httpapi"
	"github.com/maillunex-lang/number5/server/internal/modules/auth"
	"github.com/maillunex-lang/number5/server/internal/modules/content"
	"github.com/maillunex-lang/number5/server/internal/modules/wallet"
	"github.com/maillunex-lang/number5/server/internal/store"
)

func main() {
	cfg := config.Load()
	mem := store.NewMemory(nil)
	authSvc := &auth.Service{Store: mem}
	cfgVer := "unknown"
	if info, err := content.ReadActive(cfg.ContentPackagesRoot); err == nil {
		cfgVer = info.Version
	}
	walletSvc := &wallet.Service{
		Store:          mem,
		ConfigVersion:  cfgVer,
		AllowTestGrant: cfg.AppEnv == "dev" || cfg.AppEnv == "test",
	}
	mux := httpapi.NewMux(httpapi.Deps{
		Config: cfg,
		Store:  mem,
		Auth:   authSvc,
		Wallet: walletSvc,
	})
	log.Printf("lunex-api listening on %s (env=%s store=memory config=%s)", cfg.HTTPAddr, cfg.AppEnv, cfgVer)
	if err := http.ListenAndServe(cfg.HTTPAddr, mux); err != nil {
		log.Println(err)
		os.Exit(1)
	}
}
