# Lunex AFK — UI Prototype v0.1 (фактическая реализация)

Статус (аудит 2026-11-20): Godot 4.7.2 клиент на `main`.  
**Онлайн:** guest → CORE-01 (`ApiClient`) для summon / AFK / shop / mail / battle claim; иначе DEMO.  
**Не прод:** нет живой Lunex PG БД, HTTPS CDN, бинарного арта. Полный email-auth не реализован.

## Что работает

- Bootstrap: Splash → Version → AssetBootstrap → Auth (гость → API / локальный email DEMO) → WorldSelect → GameShell
- GameShell: TopBar, BottomNavigation (**4 вкладки:** Карта / Герои / Главная / Битва), ScreenRouter, ModalManager, NotificationManager, UIStateManager, AssetLoader, ThemeManager, **ApiClient**
- Главный хаб: вертикальный 2.5D-скролл, параллакс, здания, быстрые кнопки
- Карта мира → глава → карточка этапа → подготовка
- Герои: коллекция, фильтры, карточка, автоэкипировка, отряд (локальный DemoData; server collection ещё не sync)
- Битва: карта входов → подготовка → **локальный** автобой 5v5 → результат; при online победе — серверный start/claim (целевой H6: server timeline → playback — ещё не внедрён)
- Контент: пакеты `0.1.0`…`0.9.0`, OTA hot-reload (dev CDN Studio)
- Графика: пресеты Низкая / Средняя / Высокая / Ультра
- Back: модалка → оверлей → вкладка → выход

## DEMO / PARTIAL

| Область | Режим |
|---|---|
| Summon / AFK / shop / mail | ONLINE при guest API, иначе DEMO |
| Battle rewards online | PARTIAL (desync с локальной симуляцией; H6 в TECH_DEBT) |
| Heroes / campaign sync | DEMO локально |
| Guild / PvE modes / quests / events / VIP / BP / social / PvP | DEMO или stub |

## Не считать готовым

- Production PostgreSQL / изолированный деплой Lunex
- OTA-2 HTTPS CDN
- ART-05 бинарные ассеты
- Email register/login/refresh
- Атомарные TX economy end-to-end на PG

См. `docs/STATUS.md`, `docs/AUDIT_REPORT.md`.
