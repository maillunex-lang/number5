# Lunex AFK — статус

Дата: **2026-11-20** · ветка истины: **`main`** · пакет: **`0.9.0`**

## Есть

- Контент **C0–C6** (пакеты `0.2.0`…`0.9.0`): кампания 180, skills/dialogs, арт-реестр, E/P/G/meta.
- Godot UI Prototype v0.1 + Admin Studio (`/economy`, `/meta`, `/catalog`).
- OTA hot-reload (dev).
- **TZ-A** + **CORE-01 memory**: auth, wallet, heroes, campaign, battle, summon, afk, mail, store VIRTUAL_FREE.
- Клиент `ApiClient` → `127.0.0.1:8080` (иначе офлайн-демо).
- SQL-каркас: `server/migrations/0001_init.sql`.

## Блокеры

| Что | Нужно |
|---|---|
| Postgres adapter | Docker / VPS |
| OTA-2 | HTTPS-хост |
| ART-05 | Бинарные webp/атласы (слоты уже в `0.9.0`) |

```bash
tools/validate_content_package.sh 0.9.0
cd server && go test ./... && go run ./cmd/api
```

Подробности: `docs/ROADMAP.md`.
