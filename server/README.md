# Lunex CORE-01 — Go API

Спека: [`docs/TZ_A_FOUNDATION.md`](../docs/TZ_A_FOUNDATION.md).

**Сейчас:** in-memory store с рабочим срезом модулей (без Docker/Postgres).

| Метод | Путь |
|---|---|
| POST | `/api/v1/auth/guest` |
| GET | `/api/v1/wallet` |
| POST | `/api/v1/wallet/grant-test` (dev) |
| GET | `/api/v1/heroes/collection` |
| GET/PUT | `/api/v1/formations/{mode}` |
| GET | `/api/v1/campaign/progress` |
| POST | `/api/v1/battle/start` · `/api/v1/battle/{id}/claim` |
| GET | `/api/v1/summon/banners` |
| POST | `/api/v1/summon/roll` |
| GET/POST | `/api/v1/afk` · `/api/v1/afk/claim` |
| GET/POST | `/api/v1/mail` · `/api/v1/mail/{id}/claim` |
| GET | `/api/v1/content/active` · `/api/v1/health` |

```bash
cd server
go test ./...
CONTENT_PACKAGES_ROOT=../content/packages APP_ENV=dev go run ./cmd/api
```

Postgres adapter — после Docker/VPS; интерфейс `store.Store` уже готов.
