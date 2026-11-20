package content

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

type ActiveInfo struct {
	Version     string `json:"version"`
	Source      string `json:"source,omitempty"`
	Note        string `json:"note,omitempty"`
	PublishedAt string `json:"published_at,omitempty"`
	Schema      any    `json:"schema,omitempty"`
	Title       string `json:"title,omitempty"`
}

// ReadActive mirrors content/packages/active.json + manifest schema for the client bootstrap.
func ReadActive(root string) (ActiveInfo, error) {
	var info ActiveInfo
	raw, err := os.ReadFile(filepath.Join(root, "active.json"))
	if err != nil {
		return info, err
	}
	if err := json.Unmarshal(raw, &info); err != nil {
		return info, err
	}
	if info.Version == "" {
		return info, fmt.Errorf("active.json missing version")
	}
	manPath := filepath.Join(root, info.Version, "manifest.json")
	manRaw, err := os.ReadFile(manPath)
	if err != nil {
		return info, err
	}
	var man struct {
		Schema any    `json:"schema"`
		Title  string `json:"title"`
	}
	if err := json.Unmarshal(manRaw, &man); err != nil {
		return info, err
	}
	info.Schema = man.Schema
	info.Title = man.Title
	return info, nil
}
