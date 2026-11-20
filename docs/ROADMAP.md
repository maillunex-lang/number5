# Lunex AFK — Roadmap

Обновлено: **2026-11-20** (master audit) · истина: **`main`** · пакет **`0.9.0`**.

Шкала статусов: **DONE** · **PARTIAL** · **DEMO** · **DATA_ONLY** · **DOC_ONLY** · **BLOCKED** · **NOT_STARTED**.

UI-канон навигации: **4 вкладки** (Карта / Герои / Главная / Битва). Призыв — из Алтаря хаба.

---

## Срез репозитория

| Артефакт | Статус | Где | Проверка |
|---|---|---|---|
| Документы D / канон | DONE (шапки обновлены) | `docs/`, `docs/content/` | чтение |
| UI Prototype v0.1 | DONE (shell) | `scenes/`, `project.godot` | smoke / headless |
| Пакеты `0.1.0`…`0.9.0` | DONE data | `content/packages/` | `validate_content_package.sh` |
| Admin Studio | DONE editors | `admin-studio/` | `npm run build` |
| OTA-1 (dev) | PARTIAL | Studio CDN | Publish→клиент localhost |
| CORE-01 memory | DONE slice | `server/` | `go test` + CI smoke |
| UI-02 ApiClient | PARTIAL | `api_client.gd` + 5 экранов | guest online |
| Postgres adapter | PARTIAL (код) | `store/postgres` | compile; runtime BLOCKED |
| Lunex PG / CDN / ART | BLOCKED | инфра / ассеты | — |

---

## Утверждённые требования (планирование)

| ID | Требование | Статус кода | Задача |
|---|---|---|---|
| **H4** | `APP_ENV=prod` → только Postgres, без memory fallback | NOT_STARTED | `CORE-PG-FAILCLOSED` |
| **H5** | `grant-test` / `confirm-test` только при `APP_ENV=test` | NOT_STARTED | `CORE-SEC-TESTONLY` |
| **H6** | Server seed/timeline → Godot playback → однократный claim | NOT_STARTED (сейчас desync) | `BATTLE-SERVER-PIPELINE` |

До внедрения H6 **нельзя** считать локальную симуляцию источником настоящих наград в проде.

---

## Бэклог по приоритету

### P0 — блокеры / фундамент

| ID | Задача | Статус | Зависимости | Критерий приёмки | Проверка | Исполнитель | Size |
|---|---|---|---|---|---|---|---|
| DOC-AUDIT | Этот аудит docs/AGENTS/registries | DONE (ветка) | — | PR зелёный | validators | Cursor | M |
| CORE-PG-DEPLOY | Изолированный Postgres Lunex + migrate | BLOCKED | отдельная БД на VPS | API `store=postgres` в health | интеграционный тест | DevOps+Go | L |
| CORE-PG-FAILCLOSED | H4 в коде | NOT_STARTED | CORE-PG-DEPLOY | prod без DATABASE_URL → exit≠0 | unit | Go | S |
| CORE-SEC-TESTONLY | H5 в коде | NOT_STARTED | — | test-only endpoints | go test | Go | S |
| OTA-2 | HTTPS CDN пакетов | BLOCKED | хост/CDN | телефоны тянут `cdn_base` | OTA smoke | DevOps | M |
| ART-05 | Бинарный арт в слоты 0.9.0 | BLOCKED | ассеты | idle/attack/… на экране | visual QA | Art+Godot | XL |

### P1 — сервер / клиент

| ID | Задача | Статус | Зависимости | Критерий | Проверка | Size |
|---|---|---|---|---|---|---|
| BATTLE-SERVER-PIPELINE | H6 playback | NOT_STARTED | — | client не симулирует авторитетный исход | API+UI test | L |
| ATOMIC-ECONOMY | TX: ledger+heroes/pity/mail/campaign | NOT_STARTED | PG | нет partial grants | go test concurrent | L |
| UI-SYNC-HEROES | `get_heroes`/`get_campaign`/formations | NOT_STARTED | — | online UI = server | manual+API | M |
| UI-LOGOUT-CLEAR | logout → `ApiClient.clear_session` | NOT_STARTED | — | online=false | smoke | S |
| AUTH-04 | email register/login/refresh | NOT_STARTED | PG | guest upgrade | go test | L |

### P2 — контент / Studio / онлайн-системы

| ID | Задача | Статус | Size |
|---|---|---|---|
| PUBLISH-HIST | publish_history 0.7–0.9 | NOT_STARTED | S |
| PVE-SERVER | tower/hunt/gates attempts | DATA_ONLY+DEMO UI | XL |
| GUILD-G3 | membership / raid HP | DATA_ONLY+DEMO | XL |
| META-L3+ | calendars/profile/achievements/stories/events server | DATA_ONLY | XL |
| STUDIO-VIS | visual editors beyond JSON for PvE/guilds | PARTIAL | L |

### P3 — платформы / альфа

| ID | Задача | Статус |
|---|---|---|
| APK-03 | signed APK | PARTIAL debug |
| PWA-iOS | Web export | NOT_STARTED |
| ALPHA-12 | closed alpha | BLOCKED на PG+OTA+ART+H6 |

---

## Фазы контента (сводка)

| Линия | Статус | Дальше |
|---|---|---|
| C0–C6 | DONE data | C7 = OTA-2 |
| E0–E4 | DONE data+UI | E5 memory PARTIAL → PG |
| P0–P2 | DONE data+UI DEMO | P3 server |
| G0–G2 | DONE data+UI DEMO | G3 server |
| M→V | DONE data+UI; mail memory PARTIAL | L3+/… |

---

## Ближайший рабочий порядок

1. Merge аудита docs → `main`.
2. **H5** (test-only endpoints) — можно без инфра.
3. **H4 + Lunex PG** на изолированной БД VPS (не Nexus).
4. **H6** battle pipeline.
5. ART-05 / OTA-2 параллельно.

Тестовые ворота: `docs/QUALITY_GATES.md`.
