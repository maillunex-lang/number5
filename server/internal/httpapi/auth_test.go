package httpapi_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/maillunex-lang/number5/server/internal/store"
)

func TestAuthRegisterLoginLinkLogout(t *testing.T) {
	h := setup(t)
	email := "auth04@example.com"
	pass := "password-ok-12"

	// Register
	rr := httptest.NewRecorder()
	body, _ := json.Marshal(map[string]string{"email": email, "password": pass})
	h.ServeHTTP(rr, httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewReader(body)))
	if rr.Code != 200 {
		t.Fatalf("register %d %s", rr.Code, rr.Body.String())
	}
	var reg struct {
		AccountID   string `json:"account_id"`
		AccessToken string `json:"access_token"`
		Email       string `json:"email"`
		IsGuest     bool   `json:"is_guest"`
	}
	_ = json.Unmarshal(rr.Body.Bytes(), &reg)
	if reg.AccessToken == "" || reg.IsGuest || reg.Email != email {
		t.Fatalf("bad register payload %#v", reg)
	}

	// Duplicate email → 409
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewReader(body)))
	if rr.Code != 409 {
		t.Fatalf("dup register want 409 got %d", rr.Code)
	}

	// /me
	rr = httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+reg.AccessToken)
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("me %d %s", rr.Code, rr.Body.String())
	}
	var me map[string]any
	_ = json.Unmarshal(rr.Body.Bytes(), &me)
	if me["is_guest"] != false || me["email"] != email {
		t.Fatalf("me %#v", me)
	}

	// Login new session
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, httptest.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewReader(body)))
	if rr.Code != 200 {
		t.Fatalf("login %d %s", rr.Code, rr.Body.String())
	}
	var login struct {
		AccessToken string `json:"access_token"`
	}
	_ = json.Unmarshal(rr.Body.Bytes(), &login)
	if login.AccessToken == "" || login.AccessToken == reg.AccessToken {
		t.Fatalf("expected fresh login token")
	}

	// Logout revokes
	rr = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodPost, "/api/v1/auth/logout", nil)
	req.Header.Set("Authorization", "Bearer "+login.AccessToken)
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("logout %d %s", rr.Code, rr.Body.String())
	}
	rr = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodGet, "/api/v1/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+login.AccessToken)
	h.ServeHTTP(rr, req)
	if rr.Code != 401 {
		t.Fatalf("revoked me want 401 got %d %s", rr.Code, rr.Body.String())
	}

	// Guest → link keeps account, enables login
	guestTok := guestToken(t, h)
	linkEmail := "guest-link@example.com"
	linkPass := "guest-pass-99"
	linkBody, _ := json.Marshal(map[string]string{"email": linkEmail, "password": linkPass})
	rr = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodPost, "/api/v1/auth/link", bytes.NewReader(linkBody))
	req.Header.Set("Authorization", "Bearer "+guestTok)
	req.Header.Set("Content-Type", "application/json")
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("link %d %s", rr.Code, rr.Body.String())
	}
	rr = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodGet, "/api/v1/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+guestTok)
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("me after link %d", rr.Code)
	}
	_ = json.Unmarshal(rr.Body.Bytes(), &me)
	if me["is_guest"] != false || me["email"] != linkEmail {
		t.Fatalf("linked me %#v", me)
	}
	// Second link → already_linked
	rr = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodPost, "/api/v1/auth/link", bytes.NewReader(linkBody))
	req.Header.Set("Authorization", "Bearer "+guestTok)
	req.Header.Set("Content-Type", "application/json")
	h.ServeHTTP(rr, req)
	if rr.Code != 409 {
		t.Fatalf("relink want 409 got %d", rr.Code)
	}
	// Login with linked credentials
	rr = httptest.NewRecorder()
	h.ServeHTTP(rr, httptest.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewReader(linkBody)))
	if rr.Code != 200 {
		t.Fatalf("login linked %d %s", rr.Code, rr.Body.String())
	}
}

func TestAuthSessionExpiry(t *testing.T) {
	root := packagesRoot(t)
	mem := store.NewMemory(nil)
	clk := &fixedClock{t: time.Date(2026, 11, 20, 12, 0, 0, 0, time.UTC)}
	mem.SetClock(clk)
	h := setupWithStore(t, root, mem)

	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, httptest.NewRequest(http.MethodPost, "/api/v1/auth/guest", nil))
	if rr.Code != 200 {
		t.Fatalf("guest %d", rr.Code)
	}
	var guest struct {
		AccessToken string `json:"access_token"`
	}
	_ = json.Unmarshal(rr.Body.Bytes(), &guest)

	rr = httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+guest.AccessToken)
	h.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatalf("me before expiry %d", rr.Code)
	}

	clk.t = clk.t.Add(31 * 24 * time.Hour)
	rr = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodGet, "/api/v1/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+guest.AccessToken)
	h.ServeHTTP(rr, req)
	if rr.Code != 401 {
		t.Fatalf("me after expiry want 401 got %d %s", rr.Code, rr.Body.String())
	}
}

type fixedClock struct{ t time.Time }

func (f *fixedClock) Now() time.Time { return f.t }
