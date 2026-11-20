# Lunex AFK - Roadmap

Статус: **живая карта**. Обновлено 2026-11-20 · истина: ветка `cursor/content-c-razlom-epoh-9d0b` → merge в **`main`**. Пакет **`0.3.0`** (экономика E0–E4).

Последовательность: **D** (документы) → **C** (контент) → **A** (ТЗ фундамента) → онлайн.  
Локальный UI + Admin Studio + OTA **не заменяют** CORE-01.

## Фактический прогресс (репозиторий)

| Артефакт | Состояние | Где |
|---|---|---|
| Документы D (GDD / MVP / STRUCTURE / ARCHITECTURE / CONTENT-01) | Зафиксированы | `docs/` |
| UI Prototype v0.1 (Godot 4.7.2) | **Готово** | `project.godot`, `scenes/`, smoke |
| Пакеты schema 2/3 (клиент только читает) | **Готово** `0.1.0` (демо) + **`0.2.0` (Разлом эпох)** | `content/packages/` |
| Admin Studio комбайн | **Готово** | `admin-studio/` |
| OTA контента без переустановки APK | **Готово** (dev CDN) | `docs/CONTENT_OTA.md` |
| **CONTENT-C канон** (6 глав / 45 героев / бестиарий) | **В репо** | `docs/content/*.md` |
| **CONTENT-C вертикальный срез гл.1** | **В коде** (C0–C3) | пакет `0.2.0`, `docs/CONTENT_IMPLEMENTATION.md` |
| HTTPS CDN / VPS (OTA-2) | Не развёрнуто | хост + `cdn_base` |
| CORE-01 (Go + PostgreSQL + CI) | Не начато | этап A |
| Серверный бой / прогресс / платежи | Не начато | после AUTH/BATTLE |

## CONTENT-C — фазы (взаимосвязанные ID)

Порядок: **каркас ID → глава 1 → расширение**. Не «только кампания» и не полный параллель 6×45 сразу.  
Детали: `docs/CONTENT_IMPLEMENTATION.md`.

| ID | Этап | Статус | Критерий |
|---|---|---|---|
| C0 | Канон в `docs/content/` + фазы | **Готово** | Три спецификации в репо |
| C1 | Spine: F01–F06, H01–H45, E**/B**, 6 ригов | **Готово** | `heroes.json` + `enemies.json`, кросс-валидация |
| C2 | Кампания CH01 (30 этапов + encounters) | **Готово** | `campaign.json` ссылается на E/B |
| C3 | Клиент на `0.2.0` | **Готово** | Loader/DemoData/фильтры, active → 0.2.0 |
| C4 | Данные CH02–CH06 | Дальше | По главе, тот же spine |
| C5 | Навыки / диалоги / улики в runtime | Дальше | skill ids + story keys |
| C6 | Арт ригов/героев + экономика | Параллельно ART-05 | placeholder → ассеты |
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


## Этапы реализации и зависимости

| ID | Этап | Статус | Зависимости | Критерий завершения |
|---|---|---|---|---|
| DOC-D | Документы и STRUCTURE | **Готово** | — | GDD/MVP/STRUCTURE согласованы |
| UI-PROTO | Локальный UI-клиент v0.1 | **Готово** | DOC-D | Smoke PASS |
| PKG-PROTO | Пакеты + Studio | **Готово** | UI-PROTO | Publish → клиент |
| STUDIO-2 | Visual Editor 2.0 + комбайн | **Готово** | PKG-PROTO | Theme/Shell/Hub 9:16 |
| OTA-1 | Hot-reload контента | **Готово (dev)** | PKG-PROTO | Save→Publish→клиент |
| OTA-2 | Прод CDN (HTTPS) | Ожидает | OTA-1, хост | Телефоны с публичным URL |
| CONTENT-C | Игровой контент C | **В работе** (C0–C3 ✓, E0–E4 ✓) | DOC-D | C4–C7, E5 сервер |
| TZ-A | ТЗ фундамента | Ожидает | CONTENT-C (минимум C3) | API/БД/протокол боя |
| CORE-01 | Go + Postgres + CI | Ожидает | TZ-A, доступы | Сервисы изолированно |
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
| пакет **0.3.0** | + экономика E0–E4 | **Активный** (`active.json`) |
| v0.1 Alpha | Расширенный MVP | Дальше: C4–C7 → TZ-A → CORE-01 |

## Ближайший рабочий порядок

1. **E5 / CORE-01** — серверный wallet, дроп, pity (после TZ-A).
2. **C4** — данные глав 2–6 + loot bindings.
3. UI вертикали: инвентарь экипировки, доска экспедиций.
4. **OTA-2** — HTTPS CDN.
5. Admin Studio economy editors.

## Тестовые ворота

1. Smoke навигации — обязателен после смены пакета
2. `tools/validate_content_package.sh 0.2.0` — кросс-ID PASS
3. OTA Publish → `/cdn` → hot-reload — PASS локально
4. Functional бой/награды — демо до CORE-01

## Управление изменениями

Канон правится в `docs/content/`, пакет пересобирается `tools/generate_razlom_package.py`, валидируется скриптом, публикуется новой версией (`0.2.x`), не in-place rewrite `0.1.0`.
