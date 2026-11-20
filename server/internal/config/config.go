package config

import (
	"os"
)

type Config struct {
	HTTPAddr            string
	DatabaseURL         string
	ContentPackagesRoot string
	AppEnv              string
}

func Load() Config {
	return Config{
		HTTPAddr:            getenv("HTTP_ADDR", "127.0.0.1:8080"),
		DatabaseURL:         os.Getenv("DATABASE_URL"),
		ContentPackagesRoot: getenv("CONTENT_PACKAGES_ROOT", "../content/packages"),
		AppEnv:              getenv("APP_ENV", "dev"),
	}
}

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
