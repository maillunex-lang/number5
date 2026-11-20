package httpapi

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/maillunex-lang/number5/server/internal/config"
	"github.com/maillunex-lang/number5/server/internal/modules/content"
)

func NewMux(cfg config.Config) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/v1/health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"ok":      true,
			"service": "lunex-core-api",
			"note":    "CORE-01 skeleton · see docs/TZ_A_FOUNDATION.md · not player progress authority yet",
			"env":     cfg.AppEnv,
			"time":    time.Now().UTC().Format(time.RFC3339),
			"db":      cfg.DatabaseURL != "",
		})
	})
	mux.HandleFunc("GET /api/v1/content/active", func(w http.ResponseWriter, r *http.Request) {
		info, err := content.ReadActive(cfg.ContentPackagesRoot)
		if err != nil {
			writeErr(w, http.StatusInternalServerError, "content_unavailable", err.Error())
			return
		}
		writeJSON(w, http.StatusOK, info)
	})

	// Stubs: registered so OpenAPI/route audit matches TZ-A; return 501 until modules land.
	for _, path := range []string{
		"/api/v1/wallet",
		"/api/v1/campaign/progress",
		"/api/v1/heroes/collection",
		"/api/v1/summon/banners",
		"/api/v1/afk",
		"/api/v1/mail",
	} {
		p := path
		mux.HandleFunc("GET "+p, notImplemented)
	}
	for _, path := range []string{
		"/api/v1/battle/start",
		"/api/v1/summon/roll",
		"/api/v1/afk/claim",
		"/api/v1/auth/guest",
	} {
		p := path
		mux.HandleFunc("POST "+p, notImplemented)
	}
	return mux
}

func notImplemented(w http.ResponseWriter, _ *http.Request) {
	writeErr(w, http.StatusNotImplemented, "not_implemented", "CORE-01 module pending — TZ-A §4")
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeErr(w http.ResponseWriter, status int, code, message string) {
	writeJSON(w, status, map[string]any{
		"error": map[string]string{"code": code, "message": message},
	})
}
