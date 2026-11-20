# STORY_IDS — реестр ID (spine)

Источник истины для данных: активный пакет `content/packages/{active}/` и канон в `docs/content/`.

| Префикс | Смысл | Канон / файл пакета |
|---|---|---|
| `F01`…`F06` | Фракции | `FACTIONS_45_HEROES.md` → `heroes.json` |
| `H01`…`H45` | Герои | то же |
| `CH01-01`…`CH06-30` | Этапы кампании (180) | `STORY_6_CHAPTERS.md` → `campaign.json` (CH01 в данных) |
| `E**` / `B**` | Враги / боссы | `BESTIARY_6_CHAPTERS.md` → `enemies.json` |
| `RIG-*` | Риги врагов | `enemies.json` |
| `SET*` | Сеты экипировки | `PROGRESSION_EQUIPMENT_LOOT.md` → `equipment.json` |
| `GQ_*` | Задания гильдии | `GUILDS_COOP_RAIDS.md` → `guilds.json` |
| `LOGIN_7` / `LOGIN_30` / `NEWCOMER_14` | Календари | `LOGIN_CALENDAR.md` → `login_calendars.json` |
| `ACH_*` | Достижения | `ACHIEVEMENTS_48.md` → `achievements.json` |
| `DSE-*` | Сюжет дня | `DAILY_STORY_EVENTS_30.md` → `daily_stories.json` |
| `EVT_*` | Live-события | `LIVE_EVENTS_6.md` → `live_events.json` |
| `MAIL_*` | Шаблоны почты | `GAME_MAIL.md` → `mail.json` |

Инварианты кросс-ссылок проверяет `tools/validate_content_package.sh`.
