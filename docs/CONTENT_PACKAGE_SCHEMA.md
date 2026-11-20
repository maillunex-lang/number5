# Схема контент-пакета (schema 2 → 6)

Корень: `content/packages/{semver}/` · указатель: `content/packages/active.json`.

| Файл | Роль |
|---|---|
| `manifest.json` | Версия, schema, sha256 |
| `theme.json` | UI Kit / палитра |
| `shell.json` | GameShell chrome |
| `strings.json` | Локализация UI |
| `motion.json` | Motion / FX budget |
| `assets.json` | Реестр + bindings (+ `media/`) |
| `hub.json` | Хаб 2.5D + look |
| `campaign.json` | Кампания (CH*, regions) |
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
| `battle_modes.json` | Порталы битвы |
| `features.json` | Демо-фичи |

`DemoData` / `ThemeManager` / Shell / `ContentUpdateService` читают пакет. Прогресс игрока сюда не пишется.  
OTA список файлов берётся из `manifest.files` / `integrity.hashes` (+ `enemies.json`).

Studio: publish обновляет `active.json` и `publish_history.json`; rollback возвращает указатель.
