# Lunex AFK — текущий статус репозитория

Дата: 2026-11-20 · активный пакет: **`0.5.0`**

## Сейчас есть

- `0.5.0`: гильдии (уровни 1–10, 8 заданий, 5 tier асинхронных рейдов на `B*`, магазин `guild_token`) + всё из 0.4.0.
- Порядок: C spine → E экономика → P PvE → **G гильдии DEMO**.
- UI HUB-05 читает `guilds.json` (без онлайна).

## Сейчас нет

- Серверное членство / общий HP рейда (G3 / CORE-01).
- Чат, сезонный рейтинг, Admin Studio гильдий.

```bash
tools/validate_content_package.sh 0.5.0
python3 tools/generate_guilds_package.py
```
