# Lunex AFK — статус

Дата: **2026-11-20** · ветка истины: **`main`** · пакет: **`0.9.0`**

## Есть

- Контент **C0–C6** (пакеты `0.2.0`…`0.9.0`): кампания 180, skills/dialogs, арт-реестр, E/P/G/meta.
- Godot UI Prototype v0.1 + Admin Studio (`/economy`, `/meta`, `/catalog`).
- OTA hot-reload (dev).
- **TZ-A** + **CORE-01 memory**: auth…store VIRTUAL_FREE.
- **Postgres adapter** в коде (`server/internal/store/postgres`) — при `DATABASE_URL`, иначе memory.
- Клиент `ApiClient`: guest + summon / AFK / shop / mail / battle claim (fallback DEMO).
- SQL: `server/migrations/0001_init.sql`.

## Блокеры

| Что | Нужно |
|---|---|
| Живой Postgres | Docker / VPS + `DATABASE_URL` (адаптер уже в репо) |
| OTA-2 | HTTPS-хост |
| ART-05 | Бинарные webp/атласы (слоты уже в `0.9.0`) |

```bash
tools/validate_content_package.sh 0.9.0
cd server && go test ./... && go run ./cmd/api
```

Подробности: `docs/ROADMAP.md`.
