# Lunex AFK — Roadmap

Обновлено: **2026-11-20** · истина: ветка **`main`** · пакет **`0.9.0`**.

Порядок: **D** (доки) → **C** (контент) → **A** (ТЗ) → **CORE-01** (онлайн).  
UI + Studio + OTA (dev) **не** заменяют сервер.

---

## Срез репозитория

| Артефакт | Статус | Где |
|---|---|---|
| Документы D | **Готово** | `docs/` |
| UI Prototype v0.1 (Godot 4.7.2) | **Готово** | `project.godot`, `scenes/` |
| Пакеты `0.1.0`…`0.9.0` (active=`0.9.0`) | **Готово** | `content/packages/` |
| Admin Studio | **Готово** | `admin-studio/` |
| OTA hot-reload (dev) | **Готово** | `docs/CONTENT_OTA.md` |
| CONTENT-C канон + данные C0–C6, E/P/G, M→V | **Готово** | `docs/content/`, пакет `0.9.0` |
| TZ-A | **Готово** | `docs/TZ_A_FOUNDATION.md` |
| CORE-01 memory (auth…store) | **Готово** | `server/` |
| Клиент → API (`ApiClient`) | **Готово** (fallback офлайн) | `scripts/autoload/api_client.gd` |
| CORE-01 Postgres | **Блокер** Docker/VPS | `migrations/0001_init.sql` готов |
| OTA-2 HTTPS CDN | **Блокер** хост | — |
| ART-05 бинарный арт | **Блокер** ассеты | слоты в `0.9.0` |

---

## Фазы контента (сводка)

Детали: `docs/CONTENT_IMPLEMENTATION.md`.

| Линия | Готово | Дальше |
|---|---|---|
| **C** сюжет/пакеты | C0–C6 | C7 = OTA-2 publish |
| **E** экономика | E0–E4 данные+UI; **E5 memory** (wallet/summon/store) | E5 PG · E6 Studio publish |
| **P** PvE | P0–P2 каталог+UI; **P3 memory** (campaign battle) | P3 PG · P4 Studio |
| **G** гильдии | G0–G2 каталог+UI | G3+ сервер (после PG) |
| **Meta** M→V | M0–V2 каталог+UI; mail claim memory | M3+/… сервер TTL (после PG) |

---

## Этапы продукта

| ID | Этап | Статус | Критерий |
|---|---|---|---|
| DOC-D | Документы | **Готово** | GDD/MVP/STRUCTURE |
| UI-PROTO | UI v0.1 | **Готово** | Smoke PASS |
| PKG-PROTO | Пакеты + Studio | **Готово** | Publish → клиент |
| STUDIO-2 | Visual Editor + комбайн | **Готово** | Theme/Shell/Hub 9:16 |
| OTA-1 | Hot-reload (dev) | **Готово** | Save→Publish→клиент |
| CONTENT-C | Данные C0–C6 | **Готово** | active `0.9.0` |
| TZ-A | ТЗ фундамента | **Готово** | `TZ_A_FOUNDATION.md` |
| CORE-01 | Go API MVP | **Memory ✓** | auth…store + CI; **PG next** |
| UI-02 | UI на реальных API | Частично | `ApiClient` guest/wallet; полный UI kit позже |
| OTA-2 | Прод CDN HTTPS | Блокер хост | Публичный `cdn_base` |
| ART-05 | GLB/спрайты/атласы | Блокер ассеты | Idle/Attack/Skill/Hit/Death |
| AUTH-04 | Email + upgrade guest | После PG | Сохранение прогресса |
| BATTLE-06 | Автобой 5v5 (прод) | Memory ✓ · PG next | Авторитетный claim |
| RPG-07 | Развитие / призыв (прод) | Memory ✓ · PG next | Звёзды/pity на PG |
| WORLD-08 | Кампания + AFK (прод) | Memory ✓ · PG next | Полный цикл на PG |
| PVE-09 | Башня/боссы/данжи | Каталог ✓ · сервер later | После PG battle |
| ADMIN-10 | Прод-админка | Studio ✓ | HTTPS publish |
| OPT-11 | CI/CD / качество | Частично | Android + iPhone/PWA |
| ALPHA-12 | Закрытая альфа | Ожидает | Нет блокер-дефектов |

---

## Контрольные пакеты

| Версия | Содержание | Факт |
|---|---|---|
| `0.1.0` | Демо Eliorian | Rollback |
| `0.2.0` | Разлом · гл.1 spine | Rollback |
| `0.3.0` | E0–E4 | Rollback |
| `0.4.0` | PvE P0–P2 | Rollback |
| `0.5.0` | Гильдии G0–G2 | Rollback |
| `0.6.0` | Meta M→V | Rollback |
| `0.7.0` | C4: 180 этапов | Rollback |
| `0.8.0` | C5: skills + dialogs | Rollback |
| **`0.9.0`** | C6: art registry | **Активный** |

---

## Ближайший порядок

1. **Postgres adapter** для CORE-01 (**блокер:** Docker/VPS).
2. **ART-05** — бинарные webp/атласы в слоты `0.9.0`.
3. **OTA-2** — HTTPS CDN (**блокер:** хост).

---

## Тестовые ворота

1. Smoke навигации — после смены пакета  
2. `tools/validate_content_package.sh 0.9.0`  
3. `python3 tools/check_repo_refs.py`  
4. `cd server && go test ./...`  
5. OTA Publish → `/cdn` → hot-reload (локально)

Канон — в `docs/content/`. Активный пакет пишет `tools/generate_assets_c6_package.py`. Старые версии пакетов не rewrite на месте.
