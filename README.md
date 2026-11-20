# Lunex AFK

Мобильная онлайн AFK/Idle RPG. Репозиторий: Godot **4.7.2** UI Prototype v0.1, контент-пакеты, Admin Studio, CORE-01 API (memory).

## Статус

Активный пакет **`0.9.0`**. Локальный UI + memory API; прод-онлайн ждёт Postgres/VPS и HTTPS.

Документы: [`docs/STATUS.md`](docs/STATUS.md) · [`docs/ROADMAP.md`](docs/ROADMAP.md) · [`docs/TZ_A_FOUNDATION.md`](docs/TZ_A_FOUNDATION.md).

## Клиент

```bash
godot --path .
tools/validate_content_package.sh
python3 tools/check_repo_refs.py
```

Портрет 1080×1920. Гостевой вход пробует CORE-01 (`ApiClient` / `LUNEX_API_BASE`), иначе офлайн-демо.

## Admin Studio

```bash
cd admin-studio && npm install && npm run dev
```

UI http://127.0.0.1:5173 · API http://127.0.0.1:8787 — `docs/ADMIN_STUDIO.md`.

## CORE-01

```bash
cd server && go test ./... && go run ./cmd/api
```

Memory: guest → wallet → battle → summon → afk → mail → store. Postgres — после Docker/VPS (`migrations/0001_init.sql`).

## Включено

- GameShell, хаб / кампания / герои / DEMO-бой
- Пакеты `0.1.0`…`0.9.0` + Studio economy/meta/catalog
- TZ-A + CORE-01 memory + `ApiClient`

## Лицензии

`THIRD_PARTY_LICENSES.md` · `docs/ASSETS_REGISTRY.md`.
