# Lunex AFK — текущий статус репозитория

Дата: 2026-11-20 · активный пакет: **`0.7.0`**

## Сейчас есть

- `0.7.0`: **C4** — 180 этапов CH01–CH06 + encounters + loot; главы 2–6 locked до `*-30`.
- Meta/гильдии/PvE/экономика из `0.6.0`.
- UI: инвентарь (`WORKSHOP`), доска экспедиций (`EXPEDITIONS`), карта фильтрует главу по региону.

## Сейчас нет / блокер

- **CORE-01** (Go/Postgres, claim/TTL) — нужны доступы + TZ-A.
- **OTA-2** HTTPS CDN — нужен хост.
- C5 навыки/диалоги runtime, C6 арт ригов.

```bash
tools/validate_content_package.sh 0.7.0
python3 tools/check_repo_refs.py
python3 tools/generate_campaign_c4_package.py
```
