# Дорожная карта Lunex AFK

Обновлено 20 ноября 2026. Публичная платформа — Android 0.5.5, пакет данных — 0.9.0. [Проверенный срез](STATUS.md)

## Ближайшие задачи

| Приоритет | Задача | Критерий завершения |
|---|---|---|
| P1 | UI-VISUAL Events | Events chrome Theme/ListHost (как guild/quests) |
| P2 | game_shell | safe-area / CODE_HEAVY → MED |

## Закрыто в этом срезе

| ID | Результат |
|---|---|
| P0 APK device | Приёмка на физическом Android подтверждена владельцем |
| H6 code + device | Серверная timeline + playback; **H6 device OK** |
| AUTH-04 code + device | Memory+PG credentials/link; **AUTH-04 device OK** |
| ART-05 code + device | Placeholder portraits/atlases + BattleUnit; **ART-05 device OK** |
| MAP-01 list fix + device | Stage bind/scroll/power; **MAP-01 device OK** |
| Battle replay farm | Повтор cleared-этапа без валюты; владелец подтвердил |
| UI-VISUAL foundation | Аудит, Theme styles, component library, preview, docs |
| UI-VISUAL wave2 | HubBuilding, BattleUnit, HeroCard, MailItem, ShopOfferCard |
| UI-VISUAL wave3 | Formation/Settings/Map chrome + FormationSlot/StageListItem/MapRegionButton |
| UI-VISUAL wave4 code | HeroDetails + SquadManager + Auth form Theme (merge #25) |
| UI-VISUAL wave5 code | BattleResult ClaimProgress; VIP + SocialHub Theme hosts (off DemoScreenBuilder) |
| UI-VISUAL wave5+ code | Chat/Friends/Rankings Theme + FeatureSectionHost |
| UI-VISUAL wave6 demos | BattlePass/PvP/Profile/Rewards/Sys Theme hosts; DemoScreenBuilder unused |
| UI-VISUAL wave7 shell | TopBar ResourceCounter + BottomNav exports; DemoScreenBuilder removed |
| UI-VISUAL wave8 lists | Mail/Shop/AFK Theme chrome + ListHost |
| UI-VISUAL wave9 summon | Summon altar Theme chrome; roll/pity intact |
| UI-VISUAL wave10 quests | Quests + Expeditions Theme chrome + ListHost |
| UI-VISUAL wave11 guild | Guild Theme chrome + Tabs/ListHost |
| Shop scroll + copy | ListHost Scroll + PASS; VIRTUAL_FREE copy; **device OK** |
| UX hang-fix #28 device | **Владелец: Все ок** |
| FIX-GODOT-DEPLOY-002 | Godot 4.7.2 build unblocked; VPS auto-deploy OK |
| ATOMIC-ECONOMY / TD-PG-RACE | `store.RunAtomic` + PG locks |
| mail ClaimAll atomic | ClaimAll в одной TX |
| settings pass keyword | `pass` → email_edit/password_edit |

## Реализовано и проверено

- Миграции встроены в API. На пустой PostgreSQL 16 проверены создание гостя, регистрация, вход, профиль, heartbeat и восстановление сессии после перезапуска.
- CORE-PG-DEPLOY и OTA-2 работают на VPS. API использует PostgreSQL и отдаёт состояние через HTTPS. CDN публикует пакет 0.9.0.
- H4: при ошибке PostgreSQL в prod процесс завершается. H5 ограничивает тестовые операции окружением test.
- Клиент: профиль, кошелёк, коллекция, отряд, бой start/claim + playback — device OK.
- Общая тема, навигация четырёх вкладок и OTA проверены. Подписанный debug APK опубликован.

### P2 — контент / Studio / онлайн-системы

| ID | Задача | Статус | Size |
|---|---|---|---|
| PUBLISH-HIST | publish_history 0.7–0.9 | NOT_STARTED | S |
| PVE-SERVER | tower/hunt/gates attempts | DATA_ONLY+DEMO UI | XL |
| GUILD-G3 | membership / raid HP | DATA_ONLY+DEMO | XL |
| META-L3+ | calendars/profile/achievements/stories/events | DATA_ONLY | XL |
| STUDIO-VIS | visual editors beyond JSON | PARTIAL | L |

## Платформы и закрытая альфа

Публичная Web/PWA-версия отключена по решению владельца. Возврат Web требует отдельного решения. Для закрытой Android-альфы device-verify H6/AUTH/ART/MAP закрыты владельцем 20.11; следующий APK — wave4 chrome.
