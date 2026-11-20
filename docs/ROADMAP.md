# Lunex AFK - Roadmap

Статус: **живая карта**. Обновлено 2026-11-20 · истина: ветка `cursor/content-c-razlom-epoh-9d0b` → merge в **`main`**. Пакет **`0.9.0`** (C6 арт-реестр + C5/C4).

Последовательность: **D** (документы) → **C** (контент) → **A** (ТЗ фундамента) → онлайн.  
Локальный UI + Admin Studio + OTA **не заменяют** CORE-01.

## Фактический прогресс (репозиторий)

| Артефакт | Состояние | Где |
|---|---|---|
| Документы D (GDD / MVP / STRUCTURE / ARCHITECTURE / CONTENT-01) | Зафиксированы | `docs/` |
| UI Prototype v0.1 (Godot 4.7.2) | **Готово** | `project.godot`, `scenes/`, smoke |
| Пакеты schema 2→10 (клиент только читает) | **Готово** `0.1.0`…`0.9.0`, active=`0.9.0` | `content/packages/` |
| Admin Studio комбайн | **Готово** | `admin-studio/` |
| OTA контента без переустановки APK | **Готово** (dev CDN) | `docs/CONTENT_OTA.md` |
| **CONTENT-C канон** (6 глав / 45 героев / бестиарий + meta) | **В репо** | `docs/content/*.md` |
| **CONTENT-C вертикальный срез** | **В коде** (C0–C6, E/P/G, M→V) | active `0.9.0`, `docs/CONTENT_IMPLEMENTATION.md` |
| HTTPS CDN / VPS (OTA-2) | Не развёрнуто | хост + `cdn_base` |
| CORE-01 (Go + PostgreSQL + CI) | ТЗ готово (TZ-A); код — скелет `server/` | ждёт доступы PG/VPS |
| Серверный бой / прогресс / платежи | Не начато | после AUTH/BATTLE |

## CONTENT-C — фазы (взаимосвязанные ID)

Порядок: **каркас ID → глава 1 → расширение**. Не «только кампания» и не полный параллель 6×45 сразу.  
Детали: `docs/CONTENT_IMPLEMENTATION.md`.

| ID | Этап | Статус | Критерий |
|---|---|---|---|
| C0 | Канон в `docs/content/` + фазы | **Готово** | Три спецификации в репо |
| C1 | Spine: F01–F06, H01–H45, E**/B**, 6 ригов | **Готово** | `heroes.json` + `enemies.json`, кросс-валидация |
| C2 | Кампания CH01 (30 этапов + encounters) | **Готово** | `campaign.json` ссылается на E/B |
| C3 | Клиент на spine+CH01 | **Готово** | Loader/DemoData; active эволюционировал до `0.6.0` |
| C4 | Данные CH02–CH06 | **Готово** (`0.7.0`) | 180 этапов + encounters + loot |
| C5 | Навыки / диалоги / улики в runtime | **Готово** (`0.8.0`) | skills.json + dialogs.json + UI |
| C6 | Арт ригов/героев + экономика | **Готово** (`0.9.0`) | registry + media descriptors; бинарь → ART-05 |
| C7 | OTA publish 0.2.x | После C3; прод = OTA-2 | CDN без новой APK |

Инварианты: `H*.faction_id→F*`, `encounter.enemy_id→E*|B*`, `stage_id=CH*`, `rig_id→RIG-*`.


## CONTENT-C экономика — фазы E0–E4 (порядок зафиксирован)

Зависимости: **валюты → прогресс/лут → гача → AFK/квесты → VIRTUAL_FREE магазин/VIP**.  
Детали: `docs/CONTENT_IMPLEMENTATION.md`.

| ID | Этап | Статус |
|---|---|---|
| E0 | Currencies spine | **Готово** (`economy.json`) |
| E1 | Progression + equipment + loot CH01 | **Готово** |
| E2 | Gacha 4 баннера | **Готово** |
| E3 | AFK / daily / weekly / 18 expeditions | **Готово** |
| E4 | Shop / subs / VIP / battle pass (0 ₽) | **Готово (данные+демо UI)** |
| E5 | Server wallet / RNG | После CORE-01 |




## CONTENT-C PvE — фазы P0–P4 (после E0–E4)

Башня / охота / фракционные врата / подземелья. Зависят от валют+бестиария; **не** ждут C4.  
Детали: `docs/CONTENT_IMPLEMENTATION.md`.

| ID | Этап | Статус |
|---|---|---|
| P0 | Канон PVE-01 | **Готово** |
| P1 | `pve_modes.json` 120 этажей + 4 режима | **Готово** (`0.4.0`) |
| P2 | UI Испытания (DEMO) | **Готово** |
| P3 | Сервер лимитов/боя | После CORE-01 |
| P4 | Admin Studio | После P3 |



## CONTENT-C гильдии — фазы G0–G4 (после E + P)

Асинхронные рейды, жетоны, задания. Зависят от экономики и PvE-ссылок в квестах.  
Онлайн-членство — после CORE-01.

| ID | Этап | Статус |
|---|---|---|
| G0 | Канон GUILD-01 | **Готово** |
| G1 | `guilds.json` | **Готово** (`0.5.0`) |
| G2 | UI DEMO штаб | **Готово** |
| G3 | Сервер | После CORE-01 |
| G4 | Чат / сезон / Studio | После G3 |



## CONTENT-C meta — фазы M→L→R→A→S→V (после E/P/G)

Порядок: почта → календарь входа → профиль → достижения → сюжет дня → live-события.  
Claim/TTL серверные — после CORE-01.

| ID | Этап | Статус |
|---|---|---|
| M0–M2 | Почта каталог+UI | **Готово** (`0.6.0`) |
| L0–L2 | Календари 7/14/30 | **Готово** |
| R0–R2 | Профиль/косметика | **Готово** |
| A0–A2 | 48+6 достижений | **Готово** |
| S0–S2 | 30 сюжетных дней | **Готово** |
| V0–V2 | 6 live-событий | **Готово** |
| *3+ | Сервер | После CORE-01 |

## Этапы реализации и зависимости

| ID | Этап | Статус | Зависимости | Критерий завершения |
|---|---|---|---|---|
| DOC-D | Документы и STRUCTURE | **Готово** | — | GDD/MVP/STRUCTURE согласованы |
| UI-PROTO | Локальный UI-клиент v0.1 | **Готово** | DOC-D | Smoke PASS |
| PKG-PROTO | Пакеты + Studio | **Готово** | UI-PROTO | Publish → клиент |
| STUDIO-2 | Visual Editor 2.0 + комбайн | **Готово** | PKG-PROTO | Theme/Shell/Hub 9:16 |
| OTA-1 | Hot-reload контента | **Готово (dev)** | PKG-PROTO | Save→Publish→клиент |
| OTA-2 | Прод CDN (HTTPS) | Ожидает | OTA-1, хост | Телефоны с публичным URL |
| CONTENT-C | Игровой контент C | **В работе** (C0–C3 ✓, E/P/G ✓, M→V ✓) | DOC-D | C4–C7, сервер claim |
| TZ-A | ТЗ фундамента | **Готово** | CONTENT-C ✓ | `docs/TZ_A_FOUNDATION.md` |
| CORE-01 | Go + Postgres + CI | **Memory slice ✓** | PG ждёт Docker/VPS | auth…mail ✓ · PG adapter next |
| UI-02 | UI Kit на реальных API | Частично | CORE-01 | Серверные данные |
| APK-03 | Подписанный APK | Частично (debug) | CORE-01, UI-02 | Целевой Android |
| AUTH-04 | Email/гость/профиль | Ожидает | CORE-01 | Сохранение прогресса |
| ART-05 | GLB/спрайты/атласы | Ожидает | C1 spine | Idle/Attack/Skill/Hit/Death |
| BATTLE-06 | Авторитетный автобой 5v5 | Ожидает | AUTH-04 | Серверный результат |
| RPG-07 | Коллекция, развитие, призыв | Ожидает | AUTH-04, BATTLE-06 | Улучшения в бою |
| WORLD-08 | Кампания + AFK (сервер) | Ожидает | BATTLE-06, RPG-07, C4 | Полный цикл |
| PVE-09 | Башня/боссы/подземелья | Ожидает | BATTLE-06 | Правила MVP |
| ADMIN-10 | Админка (прод) | Studio+OTA готовы | CORE-01 | HTTPS publish |
| OPT-11 | Качество, CI/CD | Частично | игровой цикл | Android + iPhone/PWA |
| ALPHA-12 | Закрытая альфа | Ожидает | MVP | Нет блокер-дефектов |

## Контрольные версии

| Версия | План | Факт |
|---|---|---|
| v0.0.1–v0.0.7 | UI → Studio → OTA | Локально достигнуто; сервер/HTTPS — впереди |
| пакет **0.1.0** | Демо Eliorian UI | Сохранён для diff/rollback |
| пакет **0.2.0** | Разлом эпох · срез гл.1 | Сохранён |
| пакет **0.3.0** | + экономика E0–E4 | Сохранён |
| пакет **0.4.0** | + PvE режимы P0–P2 | Сохранён |
| пакет **0.5.0** | + гильдии / асинхр. рейды | Сохранён |
| пакет **0.6.0** | + meta (почта→ивенты) | Сохранён |
| пакет **0.7.0** | C4: CH01–CH06 ×30 + loot/encounters | Сохранён |
| пакет **0.8.0** | C5: skills + dialogs | Сохранён |
| пакет **0.9.0** | C6: art registry + media/ | **Активный** (`active.json`) |
| v0.1 Alpha | Расширенный MVP | Дальше: CORE-01 (доступы) / ART-05 / OTA-2 |

## Ближайший рабочий порядок

1. **CORE-01** — wallet / battle / claim по TZ-A (**блокер:** доступы PG/VPS).
2. **ART-05** — бинарные webp/атласы в слоты `0.9.0`.
3. **OTA-2** — HTTPS CDN (**блокер:** хост).

Готово: C4 · C5 · C6 · Studio economy/meta/catalog · **TZ-A** · скелет `server/`.

## Тестовые ворота

1. Smoke навигации — обязателен после смены пакета
2. `tools/validate_content_package.sh 0.9.0` — кросс-ID PASS
3. `python3 tools/check_repo_refs.py` — пути в доках/коде
4. OTA Publish → `/cdn` → hot-reload — PASS локально
5. Functional бой/награды — демо до CORE-01

## Управление изменениями

Канон правится в `docs/content/`. Исторические генераторы (`generate_razlom`…`generate_skills_dialogs`) **не** двигают `active.json`. Активный пакет пишет `tools/generate_assets_c6_package.py` (сейчас `0.9.0`). Не rewrite старых версий на месте.
