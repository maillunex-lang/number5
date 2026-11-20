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
user://content_cache/packages/{version}-{slot}/
        ↓
ContentPackageLoader hot-reload → DemoData / Theme / Shell перечитывают
```

## Локально

1. `cd admin-studio && npm run dev` (API+CDN на `:8787`)
2. Для локального клиента указать адрес тестового CDN через настройки контента.
3. Запустить проверку обновления и проверить версию пакета.

## Android 0.5.5

Встроенный CDN — https://rikagro.ru/afkgame/cdn. Клиент проверяет JSON, закрывает файлы и переключает активный слот после записи. Публичный API и CDN работают при отключённом Web-клиенте. Навигационные SVG и GDScript обновляются вместе с APK.

## Файлы

- Клиент: `scripts/autoload/content_update_service.gd`
- Конфиг: `content/update_config.json`
- CDN: Admin Studio `GET /cdn/...`
