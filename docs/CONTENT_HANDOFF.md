# CONTENT-C — статус передачи

> **Аудит 2026-11-20:** оперативный статус — `docs/STATUS.md` / `docs/AI_HANDOFF.md`. Этот файл — карта канона и пакетов.

Канон **«Башкортостан: Разлом эпох»** принят в репозиторий. Рабочее имя «Элиориан» из CONTENT-01 больше **не** используется в активном пакете.

**Активный пакет:** `content/packages/active.json` → **`0.9.0`**.

## Источники (канон)

| Файл | Содержание |
|---|---|
| `docs/content/STORY_6_CHAPTERS.md` | 6 глав, зоны, 30 этапов/глава, сюжет |
| `docs/STORY_CAMPAIGN.md` | Указатель на канон сюжета |
| `docs/STORY_IDS.md` | Реестр префиксов ID |
| `docs/content/FACTIONS_45_HEROES.md` | F01–F06, H01–H45, статы L1, навыки |
| `docs/content/BESTIARY_6_CHAPTERS.md` | 6 ригов, E**/B**, encounters |
| `docs/content/MONETIZATION_VIP.md` | Магазин VIRTUAL_FREE, VIP, BP |
| `docs/content/PROGRESSION_EQUIPMENT_LOOT.md` | Уровни, сеты, дроп |
| `docs/content/GACHA_45_HEROES.md` | 4 баннера, pity |
| `docs/content/AFK_DAILY_QUESTS_EXPEDITIONS.md` | AFK, квесты, 18 миссий |
| `docs/content/PVE_MODES.md` | Башня, охота, врата, подземелья |
| `docs/content/GUILDS_COOP_RAIDS.md` | Гильдии, асинхр. рейды, жетоны |
| `docs/content/GAME_MAIL.md` | Почта / вложения |
| `docs/content/LOGIN_CALENDAR.md` | Календари 7/14/30 |
| `docs/content/PLAYER_PROFILE.md` | Профиль / косметика |
| `docs/content/ACHIEVEMENTS_48.md` | 48+6 достижений |
| `docs/content/DAILY_STORY_EVENTS_30.md` | 30 сюжетных дней |
| `docs/content/LIVE_EVENTS_6.md` | 6 live-событий |
| `docs/CONTENT_IMPLEMENTATION.md` | Фазы C/E/P/G/M…V и инварианты ID |
| `docs/ASSETS_REGISTRY.md` | UI-шрифты/иконки + указатель на C6 пакет |

## Что уже в игре

| Пакет | Содержание | Статус |
|---|---|---|
| `0.2.0`…`0.6.0` | spine → E → P → G → meta | Сохранены |
| `0.7.0` | C4: 180 этапов | Сохранён |
| `0.8.0` | C5: skills + dialogs | Сохранён |
| **`0.9.0`** | **C6: арт-реестр + media/** | **Активный** |

Клиент: `ContentPackageLoader` читает пакет; при guest API — claim через CORE-01 (summon/AFK/shop/mail/battle); иначе DEMO.

## Что ещё нужно решить / доделать

| Блок | Статус | Комментарий |
|---|---|---|
| Фракции (6) | **В данных** | Бонусы 2/3/5 — проект, не в бою |
| 45 героев | **Реестр + skills + art slots** | Бинарный арт → ART-05 |
| Кампания | **180 этапов** | C6 ✓ · дальше ART-05 / C7 OTA |
| Бестиарий | **36+18 ID + 6 ригов** | Слоты анимаций в `0.9.0` |
| ТЗ фундамента (TZ-A) | **Готово** | `docs/TZ_A_FOUNDATION.md` |
| Сервер claim/wallet | **Memory ✓** (auth…store) | Изолированный Lunex PG (не Nexus AI) |
| Доступы CORE-01 PG | Открыто | Отдельная БД на VPS + H4 |

## Пересборка

Исторические пакеты (не двигают `active.json`):

```bash
python3 tools/generate_razlom_package.py           # 0.2.0
python3 tools/generate_economy_package.py          # 0.3.0
python3 tools/generate_pve_package.py              # 0.4.0
python3 tools/generate_guilds_package.py           # 0.5.0
python3 tools/generate_meta_package.py             # 0.6.0
python3 tools/generate_campaign_c4_package.py      # 0.7.0
python3 tools/generate_skills_dialogs_package.py   # 0.8.0
```

Активный пакет:

```bash
python3 tools/generate_assets_c6_package.py        # 0.9.0 + active.json
tools/validate_content_package.sh 0.9.0
python3 tools/check_repo_refs.py
```
