# Схема контент-пакета (schema 2 → 10)

Корень: `content/packages/{semver}/` · указатель: `content/packages/active.json`.

| Файл | Роль |
|---|---|
| `manifest.json` | Версия, schema, sha256 |
| `theme.json` | UI Kit / палитра |
| `shell.json` | GameShell chrome |
| `strings.json` | Локализация UI |
| `motion.json` | Motion / FX budget |
| `assets.json` | **schema 10 / assets schema 2:** реестр + bindings + `media/` descriptors |
| `hub.json` | Хаб 2.5D + look |
| `campaign.json` | Кампания (CH01–CH06 ×30 с `0.7.0`) |
| `heroes.json` | Фракции + герои / отряд |
| `enemies.json` | **schema 3:** риги, E*/B*, encounters по stage_id |
| `economy.json` | **schema 4:** валюты, SKU VIRTUAL_FREE, VIP, BP, подписки |
| `progression.json` | уровни, прорывы, звёзды, навыки |
| `equipment.json` | 12 сетов, шаблоны слотов |
| `loot_tables.json` | дроп по stage_id |
| `gacha.json` | 4 баннера, rates/pity, пулы H* |
| `liveops.json` | AFK, daily/weekly, экспедиции |
| `pve_modes.json` | **schema 5:** башня/охота/врата/подземелья |
| `guilds.json` | **schema 6:** гильдии, асинхр. рейды, магазин жетонов |
| `mail.json` | **schema 7:** шаблоны почты, DEMO inbox |
| `login_calendars.json` | **schema 7:** LOGIN_7 / LOGIN_30 / NEWCOMER_14 |
| `profile.json` | **schema 7:** косметика, приватность |
| `achievements.json` | **schema 7:** 48 + 6 секретов |
| `daily_stories.json` | **schema 7:** 30 сюжетных карточек |
| `live_events.json` | **schema 7:** 6 форматов + event_token shop |
| `skills.json` | **schema 9:** 45×5 карточек навыков |
| `dialogs.json` | **schema 9:** сюжетные сцены Dxx-* |
| `battle_modes.json` | Порталы битвы |
| `features.json` | Демо-фичи |

`DemoData` / `ThemeManager` / Shell / `ContentUpdateService` / `ContentPackageLoader` читают пакет. Прогресс игрока сюда не пишется.  
OTA: обязательные файлы + optional (`enemies`…`live_events`) из `manifest.files` / `integrity.hashes`.

Studio: publish обновляет `active.json` и `publish_history.json`; rollback возвращает указатель.  
Исторические генераторы (`0.2`…`0.8`) пакеты пересобирают, но **не** меняют `active.json` — это делает `tools/generate_assets_c6_package.py` (active `0.9.0`).

