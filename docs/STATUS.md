# Lunex AFK — текущий статус репозитория

Дата: 2026-11-20 · активный пакет: **`0.2.0`** (Башкортостан: Разлом эпох)

## Сейчас есть

- Godot **4.7.2** UI-прототип (локальные демо-данные из пакета).
- Пакет **0.2.0**: 6 фракций, 45 героев (H01–H45), 36 врагов + 18 боссов, CH01×30 этапов с encounters, маркеры CH02–CH06.
- Пакет **0.1.0** сохранён (старое демо) для diff/rollback.
- Канон CONTENT-C: `docs/content/` + план фаз `docs/CONTENT_IMPLEMENTATION.md`.
- Admin Studio + OTA (dev CDN).
- Валидатор с кросс-ссылками ID: `tools/validate_content_package.sh 0.2.0`.

## Сейчас нет (ожидаемо)

- Данные этапов CH02–CH06 в пакете (C4).
- Полные skill cards / диалоги в runtime (C5).
- Боевой арт ригов и портретов (C6 / ART-05).
- HTTPS CDN для телефонов (OTA-2).
- Go API / прогресс / авторитетный бой.

## Запуск

```bash
godot --path .
cd admin-studio && npm install && npm run dev   # UI :5173 · API/CDN :8787
tools/validate_content_package.sh 0.2.0
# пересборка из канона:
python3 tools/generate_razlom_package.py
```

Дорожная карта: `docs/ROADMAP.md`. Внедрение контента: `docs/CONTENT_IMPLEMENTATION.md`.
