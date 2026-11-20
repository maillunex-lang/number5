# Lunex AFK — текущий статус репозитория

Дата: 2026-11-20 · ветка истины: **`main`** @ `34c99cf`

## Сейчас есть

- Godot **4.7.2** UI-прототип (локальные демо-данные).
- Пакеты schema 2: hub / campaign / heroes / battle / features / **theme / shell / strings / motion / assets**.
- Admin Studio-комбайн: Theme, Shell, Strings, Motion, Assets, Hub Editor 2.0 (9:16), кампания/герои/битва, publish / diff / rollback.
- **OTA:** Save → Publish → CDN `/cdn` → `ContentUpdateService` → `user://content_cache` без новой APK (`docs/CONTENT_OTA.md`).
- CI валидации пакета + сборки Studio.

## Сейчас нет (ожидаемо)

- Утверждённый CONTENT-02+ (фракции, ростер, 30 этапов, экономика).
- HTTPS CDN / VPS для OTA на телефонах (`127.0.0.1` только для ПК).
- Go API / PostgreSQL / серверный бой / прогресс / платежи.
- Боевой арт-пайплайн и release-подпись APK.

## Запуск

```bash
godot --path .
cd admin-studio && npm install && npm run dev   # UI :5173 · API/CDN :8787
tools/validate_content_package.sh
```

Дорожная карта: `docs/ROADMAP.md`. Что утвердить дальше: `docs/CONTENT_HANDOFF.md`.
