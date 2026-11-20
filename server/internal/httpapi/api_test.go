package httpapi_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"runtime"
	"testing"

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
)

func packagesRoot(t *testing.T) string {
	t.Helper()
	_, file, _, _ := runtime.Caller(0)
	root := filepath.Clean(filepath.Join(filepath.Dir(file), "..", "..", "..", "content", "packages"))
	return root
}

func setup(t *testing.T) http.Handler {
	t.Helper()
	root := packagesRoot(t)
	cat, err := content.LoadCatalog(root)
	if err != nil {
		t.Fatal(err)
	}
	mem := store.NewMemory(nil)
	return httpapi.NewMux(httpapi.Deps{
		Config:   config.Config{AppEnv: "test", ContentPackagesRoot: root},
		Store:    mem,
		Auth:     &auth.Service{Store: mem, StarterHeroes: cat.Heroes.DefaultSquad},
		Wallet:   &wallet.Service{Store: mem, ConfigVersion: cat.Version, AllowTestGrant: true},
		Heroes:   &heroes.Service{Store: mem},
		Campaign: &campaign.Service{Store: mem},
		Battle:   &battle.Service{Store: mem, Catalog: cat},
		Summon:   &summon.Service{Store: mem, Catalog: cat},
		AFK:      &afk.Service{Store: mem, Catalog: cat},
		Mail:     &mail.Service{Store: mem, Catalog: cat},
		Shop:     &shop.Service{Store: mem, Catalog: cat},
	})
}

func guestToken(t *testing.T, h http.Handler) string {
	t.Helper()
	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, httptest.NewRequest(http.MethodPost, "/api/v1/auth/guest", nil))
	if rr.Code != 200 {
		t.Fatalf("guest %d %s", rr.Code, rr.Body.String())
	}
	var guest auth.GuestResponse
	_ = json.Unmarshal(rr.Body.Bytes(), &guest)
	return guest.AccessToken
}

func TestGuestWalletIdempotentGrant(t *testing.T) {
	h := setup(t)
	tok := guestToken(t, h)
	body := []byte(`{"resource_id":"diamonds","amount":50,"idempotency_key":"g1"}`)
	do := func() *httptest.ResponseRecorder {
		r, _ := http.NewRequest(http.MethodPost, "/api/v1/wallet/grant-test", bytes.NewReader(body))
		r.Header.Set("Authorization", "Bearer "+tok)
		out := httptest.NewRecorder()
		h.ServeHTTP(out, r)
		return out
	}
	if do().Code != 200 || do().Code != 200 {
		t.Fatal("grant failed")
	}
}

func TestFullLoopBattleSummonAfkMail(t *testing.T) {
	h := setup(t)
	tok := guestToken(t, h)
	authH := func(method, path string, body []byte) *httptest.ResponseRecorder {
		var r *http.Request
		if body != nil {
			r, _ = http.NewRequest(method, path, bytes.NewReader(body))
			r.Header.Set("Content-Type", "application/json")
		} else {
			r, _ = http.NewRequest(method, path, nil)
		}
		r.Header.Set("Authorization", "Bearer "+tok)
		rr := httptest.NewRecorder()
		h.ServeHTTP(rr, r)
		return rr
	}

	rr := authH(http.MethodGet, "/api/v1/heroes/collection", nil)
	if rr.Code != 200 {
		t.Fatalf("heroes %d %s", rr.Code, rr.Body.String())
	}
	rr = authH(http.MethodGet, "/api/v1/campaign/progress", nil)
	if rr.Code != 200 {
		t.Fatalf("campaign %d %s", rr.Code, rr.Body.String())
	}

	rr = authH(http.MethodPost, "/api/v1/battle/start", []byte(`{"stage_id":"CH01-01","idempotency_key":"b1"}`))
	if rr.Code != 200 {
		t.Fatalf("battle start %d %s", rr.Code, rr.Body.String())
	}
	var bat map[string]any
	_ = json.Unmarshal(rr.Body.Bytes(), &bat)
	if bat["victory"] != true {
		t.Fatalf("expected victory for starter squad, got %#v", bat)
	}
	bid, _ := bat["battle_id"].(string)
	rr = authH(http.MethodPost, "/api/v1/battle/"+bid+"/claim", []byte(`{"idempotency_key":"bc1"}`))
	if rr.Code != 200 {
		t.Fatalf("claim %d %s", rr.Code, rr.Body.String())
	}

	rr = authH(http.MethodPost, "/api/v1/summon/roll", []byte(`{"banner_id":"standard","count":1,"idempotency_key":"s1"}`))
	if rr.Code != 200 {
		t.Fatalf("summon %d %s", rr.Code, rr.Body.String())
	}

	rr = authH(http.MethodPost, "/api/v1/afk/claim", []byte(`{"idempotency_key":"a1"}`))
	if rr.Code != 200 {
		t.Fatalf("afk %d %s", rr.Code, rr.Body.String())
	}

	rr = authH(http.MethodGet, "/api/v1/mail", nil)
	if rr.Code != 200 {
		t.Fatalf("mail list %d %s", rr.Code, rr.Body.String())
	}
	var mailbox struct {
		Messages []struct {
			ID string `json:"id"`
		} `json:"messages"`
	}
	_ = json.Unmarshal(rr.Body.Bytes(), &mailbox)
	if len(mailbox.Messages) == 0 {
		t.Fatal("expected demo mail")
	}
	rr = authH(http.MethodPost, "/api/v1/mail/"+mailbox.Messages[0].ID+"/claim", []byte(`{"idempotency_key":"m1"}`))
	if rr.Code != 200 && rr.Code != 409 {
		t.Fatalf("mail claim %d %s", rr.Code, rr.Body.String())
	}

	rr = authH(http.MethodGet, "/api/v1/summon/pity", nil)
	if rr.Code != 200 {
		t.Fatalf("pity %d %s", rr.Code, rr.Body.String())
	}
	rr = authH(http.MethodGet, "/api/v1/battle/"+bid, nil)
	if rr.Code != 200 {
		t.Fatalf("battle get %d %s", rr.Code, rr.Body.String())
	}
	rr = authH(http.MethodGet, "/api/v1/store/catalog", nil)
	if rr.Code != 200 {
		t.Fatalf("store catalog %d %s", rr.Code, rr.Body.String())
	}
	rr = authH(http.MethodPost, "/api/v1/store/orders", []byte(`{"sku":"diamond_s","idempotency_key":"o1"}`))
	if rr.Code != 200 {
		t.Fatalf("store order %d %s", rr.Code, rr.Body.String())
	}
	var ord struct {
		Order struct {
			ID string `json:"id"`
		} `json:"order"`
	}
	_ = json.Unmarshal(rr.Body.Bytes(), &ord)
	rr = authH(http.MethodPost, "/api/v1/store/orders/"+ord.Order.ID+"/confirm-test", []byte(`{"idempotency_key":"oc1"}`))
	if rr.Code != 200 {
		t.Fatalf("store confirm %d %s", rr.Code, rr.Body.String())
	}
	rr = authH(http.MethodPost, "/api/v1/mail/claim-all", []byte(`{"idempotency_key":"mall1"}`))
	if rr.Code != 200 {
		t.Fatalf("mail claim-all %d %s", rr.Code, rr.Body.String())
	}
}
