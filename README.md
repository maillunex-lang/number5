# Lunex AFK

Мобильная онлайн AFK/Idle RPG. Godot **4.7.2** UI Prototype v0.1, контент-пакеты, Admin Studio, CORE-01 API.

## Статус

Активный пакет **`0.9.0`**. Memory API + UI online-wiring; живой Postgres / HTTPS / бинарный арт — блокеры.

Документы: [`docs/STATUS.md`](docs/STATUS.md) · [`docs/ROADMAP.md`](docs/ROADMAP.md) · [`docs/TZ_A_FOUNDATION.md`](docs/TZ_A_FOUNDATION.md).

## Клиент

```bash
godot --path .
tools/validate_content_package.sh
python3 tools/check_repo_refs.py
```

Портрет 1080×1920. `ApiClient`: guest / summon / AFK / shop / mail / battle claim → `127.0.0.1:8080` (иначе DEMO).

## Admin Studio

```bash
cd admin-studio && npm install && npm run dev
```

UI http://127.0.0.1:5173 · API http://127.0.0.1:8787 — `docs/ADMIN_STUDIO.md`.

## CORE-01

```bash
cd server && go test ./... && go run ./cmd/api
# optional: DATABASE_URL=postgres://… go run ./cmd/api
```

Memory по умолчанию; Postgres adapter в `internal/store/postgres` при `DATABASE_URL`.

## Включено

- GameShell, хаб / кампания / герои / DEMO-бой
- Пакеты `0.1.0`…`0.9.0` + Studio economy/meta/catalog
- TZ-A + CORE-01 + `ApiClient` (UI-02)

## Лицензии

`THIRD_PARTY_LICENSES.md` · `docs/ASSETS_REGISTRY.md`.
