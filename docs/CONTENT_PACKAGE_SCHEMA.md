# Схема контент-пакета (schema 2 → 3)

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
| `battle_modes.json` | Порталы битвы |
| `features.json` | Демо-фичи |

`DemoData` / `ThemeManager` / Shell / `ContentUpdateService` читают пакет. Прогресс игрока сюда не пишется.  
OTA список файлов берётся из `manifest.files` / `integrity.hashes` (+ `enemies.json`).

Studio: publish обновляет `active.json` и `publish_history.json`; rollback возвращает указатель.
