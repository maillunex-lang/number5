package content

import (
	"os"
	"path/filepath"
	"testing"
)

func TestReadActiveFromRepo(t *testing.T) {
	root := filepath.Join("..", "..", "..", "..", "content", "packages")
	if _, err := os.Stat(filepath.Join(root, "active.json")); err != nil {
		t.Skip("content packages not available:", err)
	}
	info, err := ReadActive(root)
	if err != nil {
		t.Fatal(err)
	}
	if info.Version == "" {
		t.Fatal("empty version")
	}
	t.Logf("active=%s schema=%v title=%s", info.Version, info.Schema, info.Title)
}
