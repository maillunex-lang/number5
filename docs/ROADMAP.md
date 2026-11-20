# Lunex AFK — Roadmap

Обновлено: **2026-11-20** (post-audit, PR #5 в `main`) · истина: **`main` @ `5f6f754`** · пакет **`0.9.0`**.

Шкала статусов: **DONE** · **PARTIAL** · **DEMO** · **DATA_ONLY** · **DOC_ONLY** · **BLOCKED** · **NOT_STARTED**.

UI-канон навигации: **4 вкладки** (Карта / Герои / Главная / Битва). Призыв — из Алтаря хаба.

---

## Срез репозитория

| Артефакт | Статус | Где | Проверка |
|---|---|---|---|
| Master audit docs / AGENTS / registries | **DONE** (PR #5) | `AGENTS.md`, `docs/*` | CI green |
| UI Prototype v0.1 | DONE (shell) | `scenes/`, `project.godot` | headless |
| Пакеты `0.1.0`…`0.9.0` | DONE data | `content/packages/` | `validate_content_package.sh` |
| Admin Studio | DONE editors | `admin-studio/` | `npm run build` |
| OTA-1 (dev) | PARTIAL | Studio CDN | Publish→клиент localhost |
| CORE-01 memory | DONE slice | `server/` | `go test` + CI |
| UI-02 ApiClient | PARTIAL | `api_client.gd` + 5 экранов | guest online |
| Postgres adapter | PARTIAL (код) | `store/postgres` | compile; runtime BLOCKED |
| Lunex PG / CDN / ART | BLOCKED | инфра / ассеты | — |

---

## Утверждённые требования (код ещё не внедрён)

| ID | Требование | Статус кода | Задача |
|---|---|---|---|
| **H4** | `APP_ENV=prod` → только Postgres, без memory fallback | NOT_STARTED | `CORE-PG-FAILCLOSED` |
| **H5** | `grant-test` / `confirm-test` только при `APP_ENV=test` | NOT_STARTED | `CORE-SEC-TESTONLY` |
| **H6** | Server seed/timeline → Godot playback → однократный claim | NOT_STARTED (desync) | `BATTLE-SERVER-PIPELINE` |

До H6 локальная симуляция **не** источник настоящих наград в проде.

---

## Бэклог по приоритету

### P0 — без инфра / фундамент

| ID | Задача | Статус | Зависимости | Критерий приёмки | Проверка | Size |
|---|---|---|---|---|---|---|
| DOC-AUDIT | Master audit docs | **DONE** | — | в `main` | CI | — |
| **CORE-SEC-TESTONLY** | H5: test-only grant/confirm | NOT_STARTED | — | 403 вне `APP_ENV=test` | `go test` | S |
| **UI-LOGOUT-CLEAR** | logout → `ApiClient.clear_session` | NOT_STARTED | — | online=false | smoke | S |
| UI-HEALTH-PROBE | клиент дергает `/health` | NOT_STARTED | — | offline при мёртвом API | smoke | S |
| CORE-PG-DEPLOY | Изолированный Postgres Lunex + migrate | BLOCKED | отдельная БД (не Nexus AI) | health `store=postgres` | интеграция | L |
| CORE-PG-FAILCLOSED | H4 в коде | NOT_STARTED | желательно после DEPLOY | prod без URL → exit≠0 | unit | S |
| OTA-2 | HTTPS CDN пакетов | BLOCKED | хост/CDN | телефоны тянут `cdn_base` | OTA smoke | M |
| ART-05 | Бинарный арт в слоты 0.9.0 | BLOCKED | ассеты | idle/attack на экране | visual QA | XL |

### P1 — сервер / клиент

| ID | Задача | Статус | Зависимости | Критерий | Проверка | Size |
|---|---|---|---|---|---|---|
| **BATTLE-SERVER-PIPELINE** | H6 playback | NOT_STARTED | — | клиент не авторитет исхода | API+UI | L |
| ATOMIC-ECONOMY | TX ledger+heroes/pity/mail/campaign | NOT_STARTED | PG | нет partial grants | concurrent test | L |
| UI-SYNC-HEROES | `get_heroes` / `get_campaign` / formations | NOT_STARTED | — | online UI = server | manual+API | M |
| AUTH-04 | email register/login/refresh | NOT_STARTED | PG | guest upgrade | `go test` | L |
| TD-NILMOD / TD-ID / TD-FORM-PG | выравнивание memory↔PG | NOT_STARTED | — | см. TECH_DEBT | unit | M |

### P2 — контент / Studio / онлайн-системы

| ID | Задача | Статус | Size |
|---|---|---|---|
| PUBLISH-HIST | publish_history 0.7–0.9 | NOT_STARTED | S |
| PVE-SERVER | tower/hunt/gates attempts | DATA_ONLY+DEMO UI | XL |
| GUILD-G3 | membership / raid HP | DATA_ONLY+DEMO | XL |
| META-L3+ | calendars/profile/achievements/stories/events | DATA_ONLY | XL |
| STUDIO-VIS | visual editors beyond JSON | PARTIAL | L |

### P3 — платформы / альфа

| ID | Задача | Статус |
|---|---|---|
| APK-03 | signed APK | PARTIAL debug |
| PWA-iOS | Web export | NOT_STARTED |
| ALPHA-12 | closed alpha | BLOCKED на PG+OTA+ART+H4/H5/H6 |

---

## Фазы контента (сводка)

| Линия | Статус | Дальше |
|---|---|---|
| C0–C6 | DONE data | C7 = OTA-2 |
| E0–E4 | DONE data+UI | E5 memory → PG + atomic |
| P0–P2 | DONE data+UI DEMO | P3 server |
| G0–G2 | DONE data+UI DEMO | G3 server |
| M→V | DONE data+UI; mail memory PARTIAL | L3+/… |

---

## Ближайший рабочий порядок (следующая команда)

Готово к старту **без** VPS/CDN/арта:

1. **CORE-SEC-TESTONLY (H5)** — закрыть test grants вне `APP_ENV=test`
2. **UI-LOGOUT-CLEAR** (+ опционально health probe)
3. **BATTLE-SERVER-PIPELINE (H6)** — можно проектировать/кодить до PG; prod-награды только через server claim

Когда появится изолированная БД Lunex:

4. CORE-PG-DEPLOY → CORE-PG-FAILCLOSED (H4) → ATOMIC-ECONOMY  
5. Параллельно ART-05 / OTA-2 (внешние блокеры)

Не начинать GUILD-G3 / PVE-SERVER / META-L3+ server, пока нет PG + H4 + H6.

Тестовые ворота: `docs/QUALITY_GATES.md` · `tools/verify_project.sh`.
