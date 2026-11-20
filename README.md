# Lunex AFK

Мобильная онлайн AFK/Idle RPG. Репозиторий: клиентский **UI Prototype v0.1** на Godot 4.7.2.

## Статус

Локальный игровой прототип интерфейса. **Онлайн-режим не реализован.** Данные демо хранятся локально и не выдаются за серверные.

Документы: `docs/STATUS.md` (срез), `docs/ROADMAP.md`, `docs/STRUCTURE.md`, `docs/PROTOTYPE_v0.1.md`, `docs/ADMIN_STUDIO.md`, `docs/CONTENT_HANDOFF.md` (что утвердить дальше).

## Запуск клиента

```bash
godot --path .
```

Требуется Godot **4.7.2**. Портрет 1080×1920 (9:16).

Контент читается только из `content/packages/{version}/` (указатель `active.json`). Клиент рисует UI; прогресс сессии локальный и не является сервером.

## Lunex Admin Studio

Визуальный редактор пакетов (React/TS + локальный Express API):

```bash
cd admin-studio
npm install
npm run dev
```

UI http://127.0.0.1:5173 · API http://127.0.0.1:8787 — см. `docs/ADMIN_STUDIO.md`.

## Что включено в v0.1

- GameShell: TopBar, 4 вкладки (Карта / Герои / Главная / Битва), Router, модалки, тосты
- 2.5D-хаб с 8 зданиями и параллаксом (данные из пакета)
- Карта → глава → этап → подготовка → автобой 5v5 → результат
- Коллекция героев, отряды, пресеты
- Демо-экраны реестра UI-14 (магазин/квесты/AFK/почта/события из `features.json`)
- Версионные контент-пакеты + Admin Studio
- Пресеты графики Low/Med/High/Ultra
- Android debug APK (см. `docs/ANDROID_BUILD.md`)

## Лицензии сторонних материалов

См. `THIRD_PARTY_LICENSES.md` и `docs/ASSETS_REGISTRY.md`.
