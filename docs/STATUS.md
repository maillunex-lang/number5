# Lunex AFK — статус

Дата: **2026-11-20** · истина: **`main` @ `5f6f754`** · пакет: **`0.9.0`**  
Аудит: `docs/AUDIT_REPORT.md` (PR #5 **merged**)

## Интерфейс VPS · 0.5.5

Сборки Web и Android используют общую тему и набор пиктограмм. Проверены 42 экранных состояния, включая четыре главные вкладки. В изолированной сессии Godot 269 доступных кнопок в 37 игровых меню приняли нажатие. Колесо прокрутило все восемь областей с переполнением в тестовом портретном размере. Результаты относятся к тестовому профилю и доступному ему контенту.

## Проверка VPS Lunex · 20 ноября 2026

- На VPS опубликованы обновлённая Web-сборка и Android 0.5.4. API использует отдельную PostgreSQL Lunex.
- OTA проверяет JSON, закрывает файлы до чтения и переключает указатель на скачанный пакет после записи. Старый кэш проверяется повторной загрузкой. Godot smoke проходит с пакетом 0.9.0 и валидными диалогами.
- Web-клиент сразу сохраняет сессию в хранилище браузера. Имя гостя на экране приходит из серверного профиля.
- API загружает профиль существующего аккаунта при отсутствии строки профиля. Ошибки чтения пишутся в журнал без токена сессии. Причина прежних ответов HTTP 500 исторически не подтверждена.
- Подпись APK проверена. Установка на физическом Android-устройстве ожидает проверки.

## Есть (проверено)

- Контент **C0–C6**: 180 этапов, 45 героев, E/P/G/meta, арт-реестр (без бинарей).
- Godot UI Prototype v0.1 + **4 вкладки** + Admin Studio.
- OTA hot-reload (**dev** HTTP через Studio CDN).
- **CORE-01 memory**: auth guest, wallet, heroes, campaign, battle, summon, afk, mail, store VIRTUAL_FREE.
- **Postgres adapter** в коде (`server/internal/store/postgres`); runtime Lunex DB — нет.
- **UI-02**: `ApiClient` — guest + summon/AFK/shop/mail/battle claim (fallback DEMO).
- **Docs/AGENTS/registries** после master audit — в `main`.

## Блокеры

| Что | Почему |
|---|---|
| **Lunex production PG** | VPS есть; нет **изолированной** БД/стека Lunex. Нельзя использовать БД Nexus AI. |
| **OTA-2 CDN HTTPS** | Нет публичного `cdn_base` для пакетов. |
| **ART-05** | Нет бинарных webp/атласов (слоты в `0.9.0`). |

Утверждено, код не внедрён: **H4** / **H5** / **H6** — см. `docs/TECH_DEBT.md`, `docs/ROADMAP.md`.

## Следующее без блокеров инфра

1. `CORE-SEC-TESTONLY` (H5)  
2. `UI-LOGOUT-CLEAR`  
3. `BATTLE-SERVER-PIPELINE` (H6)  

## Быстрая проверка

```bash
tools/verify_project.sh
# или:
tools/validate_content_package.sh 0.9.0
python3 tools/check_repo_refs.py
cd server && go test ./...
```

Дальше: `docs/ROADMAP.md` · `docs/AI_HANDOFF.md` · `AGENTS.md`.
