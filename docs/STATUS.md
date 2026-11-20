# Lunex AFK · состояние на 20 ноября 2026

Опубликована Android debug-сборка **0.5.5** (versionCode **29**), активный пакет **0.9.0**. Страница игры ведёт на APK. Публичный Web-клиент отключён; путь запуска и его файлы возвращают HTTP 410. [Страница игры](https://rikagro.ru/afkgame/)

| Компонент | Подтверждено | Граница проверки |
|---|---|---|
| Android | Подпись APK проверена. SHA-256 опубликованного файла совпал со сборкой на VPS. **Приёмка на физическом устройстве подтверждена владельцем (P0)** | Новые клиентские правки H6 требуют следующей APK-сборки и повторной проверки playback |
| Интерфейс | В портретном тесте Godot проверены 42 состояния. Все 269 доступных кнопок в 37 игровых меню приняли нажатие. Колесо прокрутило 8 из 8 переполненных областей | Только доступные тестовому профилю действия. Серверный эффект каждой операции этим тестом не проверялся |
| Аккаунт и прогресс | Гостевой вход, загрузка профиля, героев, отряда и кошелька. После боя CH01-01 открывался CH01-02, повтор получения награды сохранял баланс, перезапуск сохранял этап | Шесть исторических HTTP 500 профиля наблюдались 20 ноября. Точная причина не установлена |
| Бой H6 | Server timeline + playback + GET reconnect + stable `claim:{battle_id}`; API/CI контракт покрыт | **Device verify** по `docs/H6_DEVICE_VERIFY.md` на свежем APK — ждём подтверждение владельца |
| Battle replay farm | Claim на уже `FirstClearClaimed` этап: пустые rewards (без hardcoded 500 gold) | **Владелец: повторные награды не выдаются** на свежем APK |
| ART-05 | Procedural portrait/atlas webp в пакете; AssetLoader; BattleUnit clips; HUD/cards; headless load + Android export OK | Device verify: `docs/ART_05_DEVICE_VERIFY.md` — ждём «ART-05 device OK» |
| MAP-01 list | StageListItem bind + scroll + squad power estimate (fix) | Device: имена этапов, сила ≠ 0, вертикальный скролл |
| UI visual-edit | Theme + wave2–3 + **wave4**: HeroDetails, SquadManager (FormationSlot/HeroCard), Auth form Theme | battle_result / DemoScreenBuilder features — следующие |
| FIX-GODOT-DEPLOY-002 | Theme `GamePopupPanel`; typed battle/shop GDScript; headless import clean; **VPS auto-deploy подтверждён владельцем без ошибок** | Следующий APK — H6 device verify |
| ATOMIC-ECONOMY | `RunAtomic`: claim/summon/shop/afk/mail(+claim-all) + ledger в одной TX; PG row lock | device smoke после деплоя API |
| AUTH-04 | Memory+PG register/login/link; logout revoke; link_guest sync heroes; settings bind; Go tests + device checklist | Device verify: `docs/AUTH_04_DEVICE_VERIFY.md` — ждём владельца |
| Инфраструктура | Nginx, Go API в prod и отдельный PostgreSQL. Health подтверждал соединение с БД | Чистый запуск и перезапуск проверены на отдельной PostgreSQL 16 |
| Контент | 27 файлов из манифеста совпали с копией на VPS. Проверены HTTPS CDN, загрузка диалогов и активация OTA-кэша | Новый код, сцены и встроенные пиктограммы распространяются в APK |

Четыре корневые вкладки используют общую тему. В хабе и на карте используется иллюстрация мира, навигация получила компактные пиктограммы. Исправлены открытие событий, гильдии и профиля, возврат к предыдущему экрану и доступ к последнему региону карты.

[Дорожная карта](ROADMAP.md) · [Сборка Android](ANDROID_BUILD.md) · [Проверки](QUALITY_GATES.md)
