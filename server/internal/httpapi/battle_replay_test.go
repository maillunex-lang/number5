package httpapi_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestBattleClearedStageClaimGivesNoRewards(t *testing.T) {
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

	walletGold := func() int64 {
		rr := authH(http.MethodGet, "/api/v1/wallet", nil)
		if rr.Code != 200 {
			t.Fatalf("wallet %d %s", rr.Code, rr.Body.String())
		}
		var w struct {
			Balances []struct {
				ResourceID string `json:"resource_id"`
				Amount     int64  `json:"amount"`
			} `json:"balances"`
		}
		_ = json.Unmarshal(rr.Body.Bytes(), &w)
		for _, b := range w.Balances {
			if b.ResourceID == "gold" {
				return b.Amount
			}
		}
		t.Fatal("gold missing")
		return 0
	}

	startClaim := func(stage, startKey string) (map[string]any, int64) {
		rr := authH(http.MethodPost, "/api/v1/battle/start",
			[]byte(`{"stage_id":"`+stage+`","idempotency_key":"`+startKey+`"}`))
		if rr.Code != 200 {
			t.Fatalf("start %s %d %s", stage, rr.Code, rr.Body.String())
		}
		var bat map[string]any
		_ = json.Unmarshal(rr.Body.Bytes(), &bat)
		if bat["victory"] != true {
			t.Fatalf("need victory %#v", bat)
		}
		bid, _ := bat["battle_id"].(string)
		before := walletGold()
		rr = authH(http.MethodPost, "/api/v1/battle/"+bid+"/claim",
			[]byte(`{"idempotency_key":"claim:`+bid+`"}`))
		if rr.Code != 200 {
			t.Fatalf("claim %s %d %s", stage, rr.Code, rr.Body.String())
		}
		var claim map[string]any
		_ = json.Unmarshal(rr.Body.Bytes(), &claim)
		return claim, before
	}

	first, goldBeforeFirst := startClaim("CH01-01", "replay-farm-b1")
	rewards, _ := first["rewards"].(map[string]any)
	if len(rewards) == 0 || first["first_clear"] != true {
		t.Fatalf("first clear should pay %#v", first)
	}
	goldAfterFirst := walletGold()
	if goldAfterFirst <= goldBeforeFirst {
		t.Fatalf("first clear gold %d → %d", goldBeforeFirst, goldAfterFirst)
	}

	// Replay already-cleared CH01-01: training, no currency.
	second, goldBeforeReplay := startClaim("CH01-01", "replay-farm-b2")
	rew2, _ := second["rewards"].(map[string]any)
	if len(rew2) != 0 {
		t.Fatalf("cleared replay must not grant rewards, got %#v", second)
	}
	if second["first_clear"] != false {
		t.Fatalf("first_clear flag %#v", second)
	}
	goldAfterReplay := walletGold()
	if goldAfterReplay != goldBeforeReplay {
		t.Fatalf("replay farm: gold %d → %d", goldBeforeReplay, goldAfterReplay)
	}
}
