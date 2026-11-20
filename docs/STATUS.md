# Lunex AFK — текущий статус репозитория

Дата: 2026-11-20 · активный пакет: **`0.3.0`** (Разлом эпох + экономика E0–E4)

## Сейчас есть

- Пакет **0.3.0**: мир CH01 + 45 героев + бестиарий + `economy` / `progression` / `equipment` / `loot_tables` / `gacha` / `liveops`.
- Пакеты **0.1.0** (демо) и **0.2.0** (spine) сохранены.
- Канон: `docs/content/` (сюжет + 4 эконом-спеки).
- Порядок внедрения экономики: валюты → прогресс/лут → гача → AFK → VIRTUAL_FREE магазин.
- UI демо: магазин 0 ₽, алтарь 4 баннера, AFK по ставкам гл.1.
- Валидатор кросс-ID: `tools/validate_content_package.sh 0.3.0`.

## Сейчас нет (ожидаемо)

- Серверный кошелёк / авторитетный дроп и pity (E5 / CORE-01).
- Полный UI инвентаря экипировки и экспедиций.
- Лут CH02–CH06, реальные платежи, HTTPS OTA-2.

## Запуск

```bash
godot --path .
tools/validate_content_package.sh 0.3.0
python3 tools/generate_economy_package.py   # пересборка 0.3.0 из канона
```

Дорожная карта: `docs/ROADMAP.md`. Фазы: `docs/CONTENT_IMPLEMENTATION.md`.
