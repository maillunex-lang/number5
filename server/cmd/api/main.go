package main

import (
	"log"
	"net/http"
	"os"

	"github.com/maillunex-lang/number5/server/internal/config"
	"github.com/maillunex-lang/number5/server/internal/httpapi"
)

func main() {
	cfg := config.Load()
	mux := httpapi.NewMux(cfg)
	log.Printf("lunex-api listening on %s (env=%s) — CORE-01 skeleton, not full game server", cfg.HTTPAddr, cfg.AppEnv)
	if err := http.ListenAndServe(cfg.HTTPAddr, mux); err != nil {
		log.Println(err)
		os.Exit(1)
	}
}
