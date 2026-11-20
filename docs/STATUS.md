# Lunex AFK — текущий статус репозитория

Дата: 2026-11-20 · активный пакет: **`0.9.0`**

## Сейчас есть

- `0.9.0` **C6**: `assets.json` schema 2 (реестр ригов/героев/глав) + `media/` descriptors + UI `ART-01`.
- `0.8.0` C5: skills + dialogs; `0.7.0` C4: 180 этапов.
- UI: карточка героя → Навыки / Арт; хаб → реестр арта; этап → диалог → бой.
- Admin Studio: `/economy`, `/meta` (M→V), `/catalog` + фильтр ассетов C6.

## Сейчас нет / блокер

- **CORE-01** — доступы + TZ-A.
- **OTA-2** — HTTPS-хост.
- **ART-05** — бинарные webp/атласы (слоты уже в `0.9.0`).

```bash
tools/validate_content_package.sh 0.9.0
python3 tools/generate_assets_c6_package.py
```
