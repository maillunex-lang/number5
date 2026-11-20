# Lunex AFK — текущий статус репозитория

Дата: 2026-11-20 · активный пакет: **`0.8.0`**

## Сейчас есть

- `0.8.0` **C5**: `skills.json` (45×5 карточек) + `dialogs.json` (54 сцены) + UI навыков/диалогов.
- `0.7.0` C4: 180 этапов; meta/гильдии/PvE/экономика ниже по стеку.
- UI: карточка героя → Навыки; этап → сюжет до боя → `DIALOG-01`.

## Сейчас нет / блокер

- **CORE-01** — доступы + TZ-A.
- **OTA-2** — HTTPS-хост.
- **C6** — арт ригов/героев (placeholder).

```bash
tools/validate_content_package.sh 0.8.0
python3 tools/generate_skills_dialogs_package.py
```
