# Схема контент-пакета (клиент только читает)

Корень: `content/packages/{semver}/` · указатель: `content/packages/active.json`.

| Файл | Назначение | Читает клиент |
|---|---|---|
| `manifest.json` | Версия, schema, список файлов, sha256 | `ContentPackageLoader` |
| `hub.json` | Мир хаба, здания, side_rail | Хаб |
| `campaign.json` | Регионы, этапы, рёбра, current_stage | Карта / глава / бой |
| `heroes.json` | Герои, экип, пресеты, default_squad | Герои / отряд / бой |
| `battle_modes.json` | Порталы вкладки «Битва» | Battle modes |
| `features.json` | Магазин, квесты, почта, VIP, BP, AFK, summon, events | Feature-экраны |

`DemoData` копирует героев/кампанию/AFK-дефолты из пакета в сессию. **Прогресс игрока в пакет не пишется.**

Публикация: Admin Studio → `POST /api/packages/:version/publish` обновляет хеши и `active.json`.  
Проверка: `tools/validate_content_package.sh [version]`.
