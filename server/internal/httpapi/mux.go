package httpapi

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/maillunex-lang/number5/server/internal/config"
	"github.com/maillunex-lang/number5/server/internal/domain"
	"github.com/maillunex-lang/number5/server/internal/modules/auth"
	"github.com/maillunex-lang/number5/server/internal/modules/content"
	"github.com/maillunex-lang/number5/server/internal/modules/wallet"
	"github.com/maillunex-lang/number5/server/internal/store"
)

type Deps struct {
	Config config.Config
	Store  store.Store
	Auth   *auth.Service
	Wallet *wallet.Service
}

func NewMux(d Deps) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/v1/health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"ok":      true,
			"service": "lunex-core-api",
			"note":    "CORE-01 slice · auth guest + wallet (memory) · see docs/TZ_A_FOUNDATION.md",
			"env":     d.Config.AppEnv,
			"time":    time.Now().UTC().Format(time.RFC3339),
			"db":      d.Config.DatabaseURL != "",
			"store":   "memory",
			"modules": []string{"auth.guest", "wallet", "wallet.grant-test", "content.active"},
		})
	})
	mux.HandleFunc("GET /api/v1/content/active", func(w http.ResponseWriter, r *http.Request) {
		info, err := content.ReadActive(d.Config.ContentPackagesRoot)
		if err != nil {
			writeErr(w, http.StatusInternalServerError, "content_unavailable", err.Error())
			return
		}
		writeJSON(w, http.StatusOK, info)
	})

	mux.HandleFunc("POST /api/v1/auth/guest", func(w http.ResponseWriter, r *http.Request) {
		res, err := d.Auth.CreateGuest()
		if err != nil {
			writeErr(w, http.StatusInternalServerError, "auth_failed", err.Error())
			return
		}
		writeJSON(w, http.StatusOK, res)
	})

	mux.HandleFunc("GET /api/v1/wallet", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		res, err := d.Wallet.Get(acc.ID)
		if err != nil {
			writeErr(w, http.StatusInternalServerError, "wallet_failed", err.Error())
			return
		}
		writeJSON(w, http.StatusOK, res)
	})

	mux.HandleFunc("POST /api/v1/wallet/grant-test", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		var req wallet.GrantRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeErr(w, http.StatusBadRequest, "bad_json", err.Error())
			return
		}
		if req.IdempotencyKey == "" {
			req.IdempotencyKey = r.Header.Get("Idempotency-Key")
		}
		status, body, err := d.Wallet.GrantTestAtomic(acc.ID, req)
		if err != nil {
			writeErr(w, http.StatusInternalServerError, "grant_failed", err.Error())
			return
		}
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.WriteHeader(status)
		_, _ = w.Write(body)
	})

	for _, path := range []string{
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
	} {
		p := path
		mux.HandleFunc("POST "+p, notImplemented)
	}
	return mux
}

func requireAuth(w http.ResponseWriter, r *http.Request, authSvc *auth.Service) (domain.Account, bool) {
	h := r.Header.Get("Authorization")
	token := ""
	if len(h) >= 7 && strings.EqualFold(h[:7], "bearer ") {
		token = strings.TrimSpace(h[7:])
	}
	acc, err := authSvc.AccountFromBearer(token)
	if err != nil {
		writeErr(w, http.StatusUnauthorized, "unauthorized", "missing or invalid bearer token")
		return domain.Account{}, false
	}
	return acc, true
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
