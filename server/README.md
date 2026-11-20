# Lunex CORE-01 — Go API

Спека: [`docs/TZ_A_FOUNDATION.md`](../docs/TZ_A_FOUNDATION.md).

**Store:** memory по умолчанию; Postgres при `DATABASE_URL` (`internal/store/postgres` + `migrations/0001_init.sql`).

| Метод | Путь |
|---|---|
| POST | `/api/v1/auth/guest` |
| GET | `/api/v1/wallet` |
| POST | `/api/v1/wallet/grant-test` (dev) |
| GET | `/api/v1/heroes/collection` |
| GET/PUT | `/api/v1/formations/{mode}` |
| GET | `/api/v1/campaign/progress` |
| POST/GET | `/api/v1/battle/start` · `/battle/{id}` · `…/claim` |
| GET/POST | `/api/v1/summon/banners` · `/pity` · `/roll` |
| GET/POST | `/api/v1/afk` · `/afk/claim` |
| GET/POST | `/api/v1/mail` · `/mail/{id}/claim` · `/mail/claim-all` |
| GET/POST | `/api/v1/store/catalog` · `/orders` · `…/confirm-test` |
| GET | `/api/v1/content/active` · `/health` |

```bash
cd server
go test ./...
CONTENT_PACKAGES_ROOT=../content/packages APP_ENV=dev go run ./cmd/api
# optional:
# DATABASE_URL=postgres://user:pass@localhost:5432/lunex?sslmode=disable go run ./cmd/api
```

Клиент Godot: `ApiClient` → `LUNEX_API_BASE` или `http://127.0.0.1:8080` (fallback DEMO).
