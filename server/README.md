# Lunex CORE-01 — Go API (скелет)

Спека: [`docs/TZ_A_FOUNDATION.md`](../docs/TZ_A_FOUNDATION.md).

**Сейчас:** компилируемый каркас + health + migrate stub.  
**Не является** игровым сервером прогресса, пока нет PostgreSQL-доступов и реализации модулей §4 TZ-A.

## Запуск (когда есть PG)

```bash
cd server
cp .env.example .env   # DATABASE_URL=…
go run ./cmd/api
```

Docker Compose (локально):

```bash
docker compose up -d postgres
DATABASE_URL=postgres://lunex:lunex@127.0.0.1:5432/lunex?sslmode=disable go run ./cmd/api
```

## Структура

```
cmd/api/          — HTTP entry
internal/config/  — env
internal/httpapi/ — routes, middleware
internal/modules/ — auth, wallet, battle… (stubs)
migrations/       — SQL
```

Admin Studio Express **не** заменяется этим сервисом.
