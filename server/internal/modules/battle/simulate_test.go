package battle

import (
	"path/filepath"
	"runtime"
	"testing"

	"github.com/maillunex-lang/number5/server/internal/modules/content"
)

func TestSimulateTimelinePlaybackShape(t *testing.T) {
	_, file, _, _ := runtime.Caller(0)
	root := filepath.Clean(filepath.Join(filepath.Dir(file), "..", "..", "..", "..", "content", "packages"))
	cat, err := content.LoadCatalog(root)
	if err != nil {
		t.Fatalf("catalog: %v", err)
	}
	enc, ok := cat.Encounter("CH01-01")
	if !ok {
		t.Fatal("missing CH01-01 encounter")
	}
	squad := []string{"H01", "H02", "H03", "H04", "H05"}
	victory, tl := simulate(42, squad, enc, cat)
	if len(tl) < 3 {
		t.Fatalf("timeline too short: %d", len(tl))
	}
	if tl[0]["type"] != "start" {
		t.Fatalf("first event want start, got %#v", tl[0])
	}
	allies, _ := tl[0]["allies"].([]map[string]any)
	enemies, _ := tl[0]["enemies"].([]map[string]any)
	if len(allies) != 5 || len(enemies) == 0 {
		t.Fatalf("start snapshot allies=%d enemies=%d", len(allies), len(enemies))
	}
	end := tl[len(tl)-1]
	if end["type"] != "end" {
		t.Fatalf("last event want end, got %#v", end)
	}
	if end["victory"] != victory {
		t.Fatalf("end.victory=%v simulate=%v", end["victory"], victory)
	}
	hasHit := false
	for _, ev := range tl {
		if ev["type"] == "hit" {
			hasHit = true
			break
		}
	}
	if !hasHit {
		t.Fatal("expected at least one hit event")
	}
	// Same seed → identical timeline (reconnect-safe).
	_, tl2 := simulate(42, squad, enc, cat)
	if len(tl2) != len(tl) {
		t.Fatalf("deterministic length mismatch %d vs %d", len(tl), len(tl2))
	}
	for i := range tl {
		if tl[i]["type"] != tl2[i]["type"] || tl[i]["t"] != tl2[i]["t"] {
			t.Fatalf("event %d mismatch %#v vs %#v", i, tl[i], tl2[i])
		}
	}
}
