# Lunex AFK

Мобильная онлайн AFK/Idle RPG «Башкортостан: Разлом эпох».  
Стек: **Godot 4.7.2** · **Go CORE-01** · **PostgreSQL 16** (цель) · **Admin Studio** · контент-пакеты.

## С чего начать

| Файл | Зачем |
|---|---|
| [`docs/STATUS.md`](docs/STATUS.md) | Что реально есть / блокеры |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Задачи и приоритеты |
| [`docs/AI_HANDOFF.md`](docs/AI_HANDOFF.md) | Передача следующему ИИ |
| [`AGENTS.md`](AGENTS.md) | Правила для ИИ-исполнителей |
| [`docs/DOCS_INDEX.md`](docs/DOCS_INDEX.md) | Навигация по docs |
| [`docs/AUDIT_REPORT.md`](docs/AUDIT_REPORT.md) | Итог master audit |

Активный пакет: **`0.9.0`**. UI-навигация: **4 вкладки**.

## Клиент

```bash
godot --path .
tools/validate_content_package.sh
python3 tools/check_repo_refs.py
```

`ApiClient` → `LUNEX_API_BASE` или `http://127.0.0.1:8080` (иначе DEMO).

## Admin Studio

```bash
cd admin-studio && npm install && npm run dev
```

UI :5173 · API :8787 — `docs/ADMIN_STUDIO.md`.

## CORE-01

```bash
cd server && go test ./... && go run ./cmd/api
# DATABASE_URL=…  # Postgres; без URL — memory (dev)
```

Утверждено: в **prod** memory fallback запрещён (H4); test-grant только `APP_ENV=test` (H5) — см. TECH_DEBT.

## Блокеры

1. Изолированный Lunex Postgres (+ CDN HTTPS). VPS есть; БД Nexus AI **не** использовать.  
2. ART-05 бинарный арт.  
3. H6 server battle pipeline (пока local sim ≠ авторитет).

## Лицензии

`THIRD_PARTY_LICENSES.md` · `docs/ASSETS_REGISTRY.md`.
