# Схема контент-пакета (schema 2)

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
| `campaign.json` | Кампания |
| `heroes.json` | Герои / отряд |
| `battle_modes.json` | Порталы битвы |
| `features.json` | Демо-фичи |

`DemoData` / `ThemeManager` / Shell читают пакет. Прогресс игрока сюда не пишется.

Studio: publish обновляет `active.json` и `publish_history.json`; rollback возвращает указатель.
