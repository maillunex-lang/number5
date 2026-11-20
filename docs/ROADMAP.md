# Дорожная карта Lunex AFK

Обновлено 20 ноября 2026. Публичная платформа — Android 0.5.5, пакет данных — 0.9.0. [Проверенный срез](STATUS.md)

## Ближайшие задачи

| Приоритет | Задача | Критерий завершения |
|---|---|---|
| P1 | H6 — device verify | Чеклист `docs/H6_DEVICE_VERIFY.md` на свежем APK; API-контракт уже зелёный. Закрыть после «H6 device OK» от владельца |
| P1 | AUTH-04 и UI-SYNC-HEROES | Код: Memory+PG register/login/link/logout, link_guest sync, settings bind; API tests + `docs/AUTH_04_DEVICE_VERIFY.md`. Закрыть после «AUTH-04 device OK» |
| P1 | ART-05 | Проверить реальные портреты, атласы и анимации героев в боевой сцене на целевом устройстве |

## Закрыто в этом срезе

| ID | Результат |
|---|---|
| P0 APK device | Приёмка на физическом Android подтверждена владельцем |
| H6 code | Серверная timeline + клиентский playback + GET reconnect + claim replay (тесты Go) |
| UI-VISUAL foundation | Аудит, Theme styles, component library, preview, docs; частичная миграция chrome |
| UI-VISUAL wave2 | HubBuilding, BattleUnit, HeroCard grid, MailItem, ShopOfferCard, DemoScreenBuilder→GamePanel |
| FIX-GODOT-DEPLOY-002 | Godot 4.7.2 build unblocked; VPS auto-deploy OK (owner confirmed) |
| ATOMIC-ECONOMY / TD-PG-RACE | `store.RunAtomic`: ledger+side-effects в одной TX; PG FOR UPDATE + advisory lock; concurrent debit tests |
| mail ClaimAll atomic | ClaimAll: ledger → SaveMail в одной TX (без «claimed без награды») |

## Реализовано и проверено

- Миграции встроены в API. На пустой PostgreSQL 16 проверены создание гостя, регистрация, вход, профиль, heartbeat и восстановление сессии после перезапуска.

- CORE-PG-DEPLOY и OTA-2 работают на VPS. API использует PostgreSQL и отдаёт состояние через HTTPS. CDN публикует пакет 0.9.0.
- H4 реализован в запуске API: при ошибке PostgreSQL в prod процесс завершается. H5 ограничивает тестовые операции окружением test.
- Клиент загружает профиль, кошелёк, коллекцию и отряд. Бой start/claim и воспроизведение timeline — в коде; device verify остаётся P1.
- Общая тема, навигация четырёх вкладок и обновление OTA проверены в Godot. Подписанный debug APK опубликован.

### P2 — контент / Studio / онлайн-системы

| ID | Задача | Статус | Size |
|---|---|---|---|
| PUBLISH-HIST | publish_history 0.7–0.9 | NOT_STARTED | S |
| PVE-SERVER | tower/hunt/gates attempts | DATA_ONLY+DEMO UI | XL |
| GUILD-G3 | membership / raid HP | DATA_ONLY+DEMO | XL |
| META-L3+ | calendars/profile/achievements/stories/events | DATA_ONLY | XL |
| STUDIO-VIS | visual editors beyond JSON | PARTIAL | L |

## Платформы и закрытая альфа

Публичная Web/PWA-версия отключена по решению владельца. Возврат Web требует отдельного решения. Для закрытой Android-альфы остаются проверка H6 на устройстве, экономические гонки и auth/sync. Критерии описаны выше.
