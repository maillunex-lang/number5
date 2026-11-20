# OTA контента без переустановки APK

Да: **фон, иконки UI-пакета, позиции зданий, тексты, тема, shell** обновляются после Save → Publish, если клиент достучится до CDN.

Нет: новый GDScript, новые сцены/логика боя, смена движка Godot — для этого нужна новая сборка APK.

## Поток

```
Admin Studio: сохранить JSON → Опубликовать
        ↓
content/packages/active.json + /cdn/*
        ↓
Клиент ContentUpdateService (фон / интервал / кнопка в Настройки→Контент)
        ↓
user://content_cache/packages/{version}/
        ↓
ContentPackageLoader hot-reload → DemoData / Theme / Shell перечитывают
```

## Локально

1. `cd admin-studio && npm run dev` (API+CDN на `:8787`)
2. В `content/update_config.json` уже `cdn_base: http://127.0.0.1:8787/cdn`
3. Запустить Godot → пакет подтянется при старте / из Настройки → Контент

## APK на телефоне

`127.0.0.1` с телефона не увидит ваш ПК. Нужно:

1. Выложить `content/packages` на HTTPS (Caddy/S3/Cloudflare…) с тем же layout: `/cdn/active.json`, `/cdn/packages/{ver}/*.json`
2. На устройстве задать URL через `user://update_config.json` или сменить `cdn_base` перед сборкой
3. Для HTTP (не HTTPS) на Android — cleartext в export (только для отладки)

## Файлы

- Клиент: `scripts/autoload/content_update_service.gd`
- Конфиг: `content/update_config.json`
- CDN: Admin Studio `GET /cdn/...`
