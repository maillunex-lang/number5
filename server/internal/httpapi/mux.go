package httpapi

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/maillunex-lang/number5/server/internal/config"
	"github.com/maillunex-lang/number5/server/internal/domain"
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

type Deps struct {
	Config   config.Config
	Store    store.Store
	Auth     *auth.Service
	Wallet   *wallet.Service
	Heroes   *heroes.Service
	Campaign *campaign.Service
	Battle   *battle.Service
	Summon   *summon.Service
	AFK      *afk.Service
	Mail     *mail.Service
}

func NewMux(d Deps) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/v1/health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"ok":      true,
			"service": "lunex-core-api",
			"note":    "CORE-01 memory slice · auth/wallet/heroes/campaign/battle/summon/afk/mail",
			"env":     d.Config.AppEnv,
			"time":    time.Now().UTC().Format(time.RFC3339),
			"db":      d.Config.DatabaseURL != "",
			"store":   "memory",
			"modules": []string{"auth", "wallet", "heroes", "campaign", "battle", "summon", "afk", "mail", "content"},
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
		st, body, err := d.Wallet.GrantTestAtomic(acc.ID, req)
		writeRaw(w, st, body, err)
	})

	mux.HandleFunc("GET /api/v1/heroes/collection", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		res, err := d.Heroes.Collection(acc.ID)
		if err != nil {
			writeErr(w, http.StatusInternalServerError, "heroes_failed", err.Error())
			return
		}
		writeJSON(w, http.StatusOK, res)
	})
	mux.HandleFunc("GET /api/v1/formations/{mode}", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		res, err := d.Heroes.GetFormation(acc.ID, r.PathValue("mode"))
		if err != nil {
			writeErr(w, http.StatusInternalServerError, "formation_failed", err.Error())
			return
		}
		writeJSON(w, http.StatusOK, res)
	})
	mux.HandleFunc("PUT /api/v1/formations/{mode}", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		var form domain.Formation
		if err := json.NewDecoder(r.Body).Decode(&form); err != nil {
			writeErr(w, http.StatusBadRequest, "bad_json", err.Error())
			return
		}
		form.Mode = r.PathValue("mode")
		if err := d.Heroes.SetFormation(acc.ID, form); err != nil {
			writeErr(w, http.StatusUnprocessableEntity, "invalid", err.Error())
			return
		}
		writeJSON(w, http.StatusOK, form)
	})

	mux.HandleFunc("GET /api/v1/campaign/progress", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		res, err := d.Campaign.Progress(acc.ID)
		if err != nil {
			writeErr(w, http.StatusInternalServerError, "campaign_failed", err.Error())
			return
		}
		writeJSON(w, http.StatusOK, res)
	})

	mux.HandleFunc("POST /api/v1/battle/start", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		var req battle.StartRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeErr(w, http.StatusBadRequest, "bad_json", err.Error())
			return
		}
		if req.IdempotencyKey == "" {
			req.IdempotencyKey = r.Header.Get("Idempotency-Key")
		}
		st, body, err := d.Battle.Start(acc.ID, req)
		writeRaw(w, st, body, err)
	})
	mux.HandleFunc("POST /api/v1/battle/{id}/claim", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		key := r.Header.Get("Idempotency-Key")
		var payload struct {
			IdempotencyKey string `json:"idempotency_key"`
		}
		_ = json.NewDecoder(r.Body).Decode(&payload)
		if key == "" {
			key = payload.IdempotencyKey
		}
		st, body, err := d.Battle.Claim(acc.ID, r.PathValue("id"), key)
		writeRaw(w, st, body, err)
	})

	mux.HandleFunc("GET /api/v1/summon/banners", func(w http.ResponseWriter, r *http.Request) {
		if _, ok := requireAuth(w, r, d.Auth); !ok {
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"banners": d.Summon.Banners()})
	})
	mux.HandleFunc("POST /api/v1/summon/roll", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		var req summon.RollRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeErr(w, http.StatusBadRequest, "bad_json", err.Error())
			return
		}
		if req.IdempotencyKey == "" {
			req.IdempotencyKey = r.Header.Get("Idempotency-Key")
		}
		st, body, err := d.Summon.Roll(acc.ID, req)
		writeRaw(w, st, body, err)
	})

	mux.HandleFunc("GET /api/v1/afk", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		res, err := d.AFK.Status(acc.ID)
		if err != nil {
			writeErr(w, http.StatusInternalServerError, "afk_failed", err.Error())
			return
		}
		writeJSON(w, http.StatusOK, res)
	})
	mux.HandleFunc("POST /api/v1/afk/claim", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		key := r.Header.Get("Idempotency-Key")
		var payload struct {
			IdempotencyKey string `json:"idempotency_key"`
		}
		_ = json.NewDecoder(r.Body).Decode(&payload)
		if key == "" {
			key = payload.IdempotencyKey
		}
		st, body, err := d.AFK.Claim(acc.ID, key)
		writeRaw(w, st, body, err)
	})

	mux.HandleFunc("GET /api/v1/mail", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		res, err := d.Mail.List(acc.ID)
		if err != nil {
			writeErr(w, http.StatusInternalServerError, "mail_failed", err.Error())
			return
		}
		writeJSON(w, http.StatusOK, res)
	})
	mux.HandleFunc("POST /api/v1/mail/{id}/claim", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		key := r.Header.Get("Idempotency-Key")
		var payload struct {
			IdempotencyKey string `json:"idempotency_key"`
		}
		_ = json.NewDecoder(r.Body).Decode(&payload)
		if key == "" {
			key = payload.IdempotencyKey
		}
		st, body, err := d.Mail.Claim(acc.ID, r.PathValue("id"), key)
		writeRaw(w, st, body, err)
	})

	return mux
}

func writeRaw(w http.ResponseWriter, status int, body []byte, err error) {
	if err != nil {
		writeErr(w, http.StatusInternalServerError, "internal", err.Error())
		return
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_, _ = w.Write(body)
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
