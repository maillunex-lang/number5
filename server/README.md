# Lunex CORE-01 — Go API (скелет)

Спека: [`docs/TZ_A_FOUNDATION.md`](../docs/TZ_A_FOUNDATION.md).

**Сейчас (dev):** in-memory store — `POST /auth/guest`, `GET /wallet`, `POST /wallet/grant-test` (idempotent).  
**Позже:** Postgres adapter по тому же `store.Store` (нужен Docker/VPS).

```bash
cd server
go test ./...
CONTENT_PACKAGES_ROOT=../content/packages APP_ENV=dev go run ./cmd/api
```

```bash
curl -X POST http://127.0.0.1:8080/api/v1/auth/guest
curl -H "Authorization: Bearer $TOK" http://127.0.0.1:8080/api/v1/wallet
```

Docker Compose (когда Docker доступен):

```bash
docker compose up -d postgres
DATABASE_URL=postgres://lunex:lunex@127.0.0.1:5432/lunex?sslmode=disable go run ./cmd/api
```

## Структура

```
cmd/api/            — HTTP entry
internal/store/     — Store interface + memory
internal/modules/   — auth, wallet, content…
migrations/         — SQL stub for PG
```

Admin Studio Express **не** заменяется этим сервисом.
