package httpapi_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/maillunex-lang/number5/server/internal/config"
	"github.com/maillunex-lang/number5/server/internal/httpapi"
	"github.com/maillunex-lang/number5/server/internal/modules/auth"
	"github.com/maillunex-lang/number5/server/internal/modules/wallet"
	"github.com/maillunex-lang/number5/server/internal/store"
)

func setup() http.Handler {
	mem := store.NewMemory(nil)
	return httpapi.NewMux(httpapi.Deps{
		Config: config.Config{AppEnv: "test", ContentPackagesRoot: "../../../content/packages"},
		Store:  mem,
		Auth:   &auth.Service{Store: mem},
		Wallet: &wallet.Service{Store: mem, ConfigVersion: "0.9.0", AllowTestGrant: true},
	})
}

func TestGuestWalletIdempotentGrant(t *testing.T) {
	h := setup()

	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, httptest.NewRequest(http.MethodPost, "/api/v1/auth/guest", nil))
	if rr.Code != 200 {
		t.Fatalf("guest status %d body %s", rr.Code, rr.Body.String())
	}
	var guest auth.GuestResponse
	if err := json.Unmarshal(rr.Body.Bytes(), &guest); err != nil {
		t.Fatal(err)
	}
	if guest.AccessToken == "" {
		t.Fatal("empty token")
	}

	req, _ := http.NewRequest(http.MethodGet, "/api/v1/wallet", nil)
	req.Header.Set("Authorization", "Bearer "+guest.AccessToken)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("wallet %d %s", rr.Code, rr.Body.String())
	}
	var wres wallet.WalletResponse
	_ = json.Unmarshal(rr.Body.Bytes(), &wres)
	if len(wres.Balances) < 3 {
		t.Fatalf("expected starter balances, got %#v", wres.Balances)
	}

	body := []byte(`{"resource_id":"diamonds","amount":50,"idempotency_key":"g1"}`)
	doGrant := func() *httptest.ResponseRecorder {
		r, _ := http.NewRequest(http.MethodPost, "/api/v1/wallet/grant-test", bytes.NewReader(body))
		r.Header.Set("Authorization", "Bearer "+guest.AccessToken)
		r.Header.Set("Content-Type", "application/json")
		out := httptest.NewRecorder()
		h.ServeHTTP(out, r)
		return out
	}
	g1 := doGrant()
	g2 := doGrant()
	if g1.Code != 200 || g2.Code != 200 {
		t.Fatalf("grant codes %d %d bodies %s | %s", g1.Code, g2.Code, g1.Body.String(), g2.Body.String())
	}
	var a, b wallet.GrantResponse
	_ = json.Unmarshal(g1.Body.Bytes(), &a)
	_ = json.Unmarshal(g2.Body.Bytes(), &b)
	diamonds := func(gr wallet.GrantResponse) int64 {
		for _, bal := range gr.Balances {
			if bal.ResourceID == "diamonds" {
				return bal.Amount
			}
		}
		return -1
	}
	if diamonds(a) != diamonds(b) {
		t.Fatalf("idempotent replay changed balance %d vs %d", diamonds(a), diamonds(b))
	}
	if b.Replayed != true {
		t.Fatalf("expected replayed=true on second grant")
	}

	bad := []byte(`{"resource_id":"diamonds","amount":99,"idempotency_key":"g1"}`)
	r, _ := http.NewRequest(http.MethodPost, "/api/v1/wallet/grant-test", bytes.NewReader(bad))
	r.Header.Set("Authorization", "Bearer "+guest.AccessToken)
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, r)
	if rr.Code != 409 {
		t.Fatalf("expected 409 got %d %s", rr.Code, rr.Body.String())
	}
}
