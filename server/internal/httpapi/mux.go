package httpapi

import (
	"encoding/json"
	"log"
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
	"github.com/maillunex-lang/number5/server/internal/modules/shop"
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
	Shop     *shop.Service
}

func NewMux(d Deps) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/v1/health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"ok":      true,
			"service": "lunex-core-api",
			"note":    "CORE-01 · auth…store VIRTUAL_FREE",
			"env":     d.Config.AppEnv,
			"time":    time.Now().UTC().Format(time.RFC3339),
			"db":      d.Config.DatabaseURL != "",
			"store":   storeKind(d.Store),
			"modules": []string{"auth", "wallet", "heroes", "campaign", "battle", "summon", "afk", "mail", "shop", "content"},
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

	// Credential endpoints: Memory (dev/test) and Postgres (prod) both implement Register/Login/Link.
	mux.HandleFunc("POST /api/v1/auth/register", func(w http.ResponseWriter, r *http.Request) {
		var p struct {
			Email    string `json:"email"`
			Password string `json:"password"`
		}
		if json.NewDecoder(http.MaxBytesReader(w, r.Body, 4096)).Decode(&p) != nil || !validCredentials(p.Email, p.Password) {
			writeErr(w, 400, "invalid_credentials", "Invalid email or password")
			return
		}
		st, ok := d.Store.(interface {
			RegisterAccount(string, string) (domain.Account, domain.Session, error)
		})
		if !ok {
			writeErr(w, 503, "unavailable", "Registration unavailable")
			return
		}
		acc, sess, err := st.RegisterAccount(p.Email, p.Password)
		if err != nil {
			writeErr(w, 409, "registration_failed", "Account could not be created")
			return
		}
		writeJSON(w, 200, map[string]any{"account_id": acc.ID, "access_token": sess.Token, "is_guest": false, "email": acc.Email})
	})
	mux.HandleFunc("POST /api/v1/auth/login", func(w http.ResponseWriter, r *http.Request) {
		var p struct {
			Email    string `json:"email"`
			Password string `json:"password"`
		}
		if json.NewDecoder(http.MaxBytesReader(w, r.Body, 4096)).Decode(&p) != nil {
			writeErr(w, 400, "invalid_request", "Invalid request")
			return
		}
		st, ok := d.Store.(interface {
			LoginAccount(string, string) (domain.Account, domain.Session, error)
		})
		if !ok {
			writeErr(w, 503, "unavailable", "Login unavailable")
			return
		}
		acc, sess, err := st.LoginAccount(p.Email, p.Password)
		if err != nil {
			writeErr(w, 401, "invalid_credentials", "Invalid email or password")
			return
		}
		writeJSON(w, 200, map[string]any{"account_id": acc.ID, "access_token": sess.Token, "is_guest": false, "email": acc.Email})
	})
	mux.HandleFunc("POST /api/v1/auth/link", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		if !acc.IsGuest {
			writeErr(w, 409, "already_linked", "Already linked")
			return
		}
		var p struct {
			Email    string `json:"email"`
			Password string `json:"password"`
		}
		if json.NewDecoder(http.MaxBytesReader(w, r.Body, 4096)).Decode(&p) != nil || !validCredentials(p.Email, p.Password) {
			writeErr(w, 400, "invalid_credentials", "Invalid email or password")
			return
		}
		st, ok := d.Store.(interface {
			LinkGuest(domain.AccountID, string, string) error
		})
		if !ok {
			writeErr(w, 503, "unavailable", "Link unavailable")
			return
		}
		if err := st.LinkGuest(acc.ID, p.Email, p.Password); err != nil {
			writeErr(w, 409, "link_failed", "Email already used or link unavailable")
			return
		}
		email := strings.ToLower(strings.TrimSpace(p.Email))
		writeJSON(w, 200, map[string]any{"ok": true, "is_guest": false, "email": email})
	})
	mux.HandleFunc("POST /api/v1/auth/logout", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		_ = acc
		token := ""
		h := r.Header.Get("Authorization")
		if len(h) >= 7 && strings.EqualFold(h[:7], "bearer ") {
			token = strings.TrimSpace(h[7:])
		}
		if rev, ok := d.Store.(interface{ RevokeSession(string) error }); ok && token != "" {
			_ = rev.RevokeSession(token)
		}
		writeJSON(w, 200, map[string]any{"ok": true})
	})
	mux.HandleFunc("GET /api/v1/auth/me", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		writeJSON(w, 200, map[string]any{"account_id": acc.ID, "is_guest": acc.IsGuest, "email": acc.Email})
	})

	mux.HandleFunc("GET /api/v1/player/profile", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		profiles, ok := d.Store.(interface {
			ReadPlayerProfile(domain.AccountID) (string, int, int64, error)
		})
		if !ok {
			writeErr(w, http.StatusServiceUnavailable, "profile_unavailable", "Profile storage unavailable")
			return
		}
		nickname, level, xp, err := profiles.ReadPlayerProfile(acc.ID)
		if err != nil {
			log.Printf("player profile: %v", err)
			writeErr(w, http.StatusInternalServerError, "profile_failed", "Profile unavailable")
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"nickname": nickname, "level": level, "xp": xp, "account_id": string(acc.ID)})
	})

	mux.HandleFunc("POST /api/v1/player/heartbeat", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		presence, ok := d.Store.(interface{ TouchPresence(domain.AccountID) error })
		if !ok {
			writeErr(w, http.StatusServiceUnavailable, "presence_unavailable", "Presence storage not supported")
			return
		}
		if err := presence.TouchPresence(acc.ID); err != nil {
			writeErr(w, http.StatusInternalServerError, "presence_failed", "Cannot update presence")
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"ok": true})
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
	mux.HandleFunc("GET /api/v1/battle/{id}", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		res, err := d.Battle.Get(acc.ID, r.PathValue("id"))
		if err != nil {
			if err == store.ErrForbidden {
				writeErr(w, http.StatusForbidden, "forbidden", "battle")
				return
			}
			writeErr(w, http.StatusNotFound, "not_found", "battle")
			return
		}
		writeJSON(w, http.StatusOK, res)
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
	mux.HandleFunc("GET /api/v1/summon/pity", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		pity, err := d.Summon.Pity(acc.ID)
		if err != nil {
			writeErr(w, http.StatusInternalServerError, "pity_failed", err.Error())
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"pity": pity})
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
	mux.HandleFunc("POST /api/v1/mail/claim-all", func(w http.ResponseWriter, r *http.Request) {
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
		st, body, err := d.Mail.ClaimAll(acc.ID, key)
		writeRaw(w, st, body, err)
	})

	mux.HandleFunc("GET /api/v1/store/catalog", func(w http.ResponseWriter, r *http.Request) {
		if _, ok := requireAuth(w, r, d.Auth); !ok {
			return
		}
		if d.Shop == nil {
			writeErr(w, http.StatusServiceUnavailable, "unavailable", "shop")
			return
		}
		writeJSON(w, http.StatusOK, d.Shop.CatalogView())
	})
	mux.HandleFunc("POST /api/v1/store/orders", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		if d.Shop == nil {
			writeErr(w, http.StatusServiceUnavailable, "unavailable", "shop")
			return
		}
		var req shop.CreateOrderRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeErr(w, http.StatusBadRequest, "bad_json", err.Error())
			return
		}
		if req.IdempotencyKey == "" {
			req.IdempotencyKey = r.Header.Get("Idempotency-Key")
		}
		st, body, err := d.Shop.CreateOrder(acc.ID, req)
		writeRaw(w, st, body, err)
	})
	mux.HandleFunc("GET /api/v1/store/orders/{id}", func(w http.ResponseWriter, r *http.Request) {
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		if d.Shop == nil {
			writeErr(w, http.StatusServiceUnavailable, "unavailable", "shop")
			return
		}
		o, err := d.Shop.GetOrder(acc.ID, r.PathValue("id"))
		if err != nil {
			if err == store.ErrForbidden {
				writeErr(w, http.StatusForbidden, "forbidden", "order")
				return
			}
			writeErr(w, http.StatusNotFound, "not_found", "order")
			return
		}
		writeJSON(w, http.StatusOK, o)
	})
	mux.HandleFunc("POST /api/v1/store/orders/{id}/confirm-test", func(w http.ResponseWriter, r *http.Request) {
		if d.Config.AppEnv != "test" {
			writeErr(w, http.StatusForbidden, "test_only", "disabled outside test environment")
			return
		}
		acc, ok := requireAuth(w, r, d.Auth)
		if !ok {
			return
		}
		if d.Shop == nil {
			writeErr(w, http.StatusServiceUnavailable, "unavailable", "shop")
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
		st, body, err := d.Shop.ConfirmTest(acc.ID, r.PathValue("id"), key)
		writeRaw(w, st, body, err)
	})

	return mux
}

func storeKind(st store.Store) string {
	if _, ok := st.(*store.Memory); ok {
		return "memory"
	}
	return "postgres"
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

func validCredentials(email, password string) bool {
	email = strings.TrimSpace(email)
	return len(email) >= 5 && len(email) <= 254 && strings.Count(email, "@") == 1 && !strings.ContainsAny(email, " \n\r\t") && len(password) >= 10 && len(password) <= 128
}
