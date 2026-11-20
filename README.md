# Lunex AFK

Мобильная онлайн AFK/Idle RPG. Репозиторий: клиентский **UI Prototype v0.1** на Godot 4.7.2 + контент-пакеты + Admin Studio + ТЗ/скелет CORE-01.

## Статус

Локальный игровой прототип интерфейса. **Онлайн-режим не реализован** (скелет API в `server/`). Данные демо хранятся локально и не выдаются за серверные.

Документы: `docs/STATUS.md`, `docs/ROADMAP.md`, `docs/TZ_A_FOUNDATION.md`, `docs/CONTENT_HANDOFF.md`, `docs/ADMIN_STUDIO.md`.

Активный контент-пакет: **`0.9.0`** (`content/packages/active.json`) — C6 арт-реестр + C5/C4 и стек ниже.

## Запуск клиента

```bash
godot --path .
```

Требуется Godot **4.7.2**. Портрет 1080×1920 (9:16).

```bash
tools/validate_content_package.sh          # active package
python3 tools/check_repo_refs.py
```

## Lunex Admin Studio

```bash
cd admin-studio && npm install && npm run dev
```

UI http://127.0.0.1:5173 · API http://127.0.0.1:8787 — `docs/ADMIN_STUDIO.md`.

## CORE-01 (memory slice)

ТЗ: `docs/TZ_A_FOUNDATION.md`. Auth…store на memory; Postgres — после Docker/VPS.

```bash
cd server && go test ./... && go run ./cmd/api
# guest → wallet → battle → summon → afk → mail → store
```

Godot: `ApiClient` (guest → `127.0.0.1:8080`, иначе офлайн-демо).

## Что включено в v0.1

- GameShell: TopBar, 4 вкладки, Router, модалки
- Хаб / кампания / герои / DEMO-бой 5v5
- Пакеты `0.1.0`…`0.9.0` + Studio economy/meta/catalog
- TZ-A + CORE-01 memory API + `ApiClient`

## Лицензии

См. `THIRD_PARTY_LICENSES.md` и `docs/ASSETS_REGISTRY.md`.
