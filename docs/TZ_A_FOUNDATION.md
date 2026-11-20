# TZ-A — ТЗ фундамента (API / БД / бой)

**Статус:** утверждаемый черновик этапа **A** · 2026-11-20  
**Вход:** CONTENT-C готов (пакет `0.9.0`, канон в `docs/content/`)  
**Выход:** контракт для **CORE-01** (Go + PostgreSQL + CI)  
**Не путать с:** Admin Studio Express (`admin-studio/server`) — это редактор пакетов, **не** источник истины прогресса.

Канон деталей систем: `MONETIZATION_VIP.md`, `GACHA_45_HEROES.md`, `GAME_MAIL.md`, `STORY_6_CHAPTERS.md`, `AFK_…`, `PVE_MODES.md`, `GUILDS_…`, meta-доки. Этот файл **сводит** инварианты и MVP-срез; при конфликте чисел — канон в `docs/content/`, здесь правится маршрутизация/порядок реализации.

---

## 1. Цель

Зафиксировать авторитетный онлайн-контур:

```
Godot 4.7.2 → HTTPS /api/v1 → Go modular monolith → PostgreSQL 16
```

Клиент только показывает; прогресс, кошелёк, бой, дроп, pity, claim — только сервер.

---

## 2. Неизменяемые инварианты

1. **Ledger:** любое изменение ресурса/инвентаря — строка в `wallet_ledger` (или inventory ledger) в **одной** транзакции с балансом. Поля: `account_id`, `resource_id`, `delta`, `source_type`, `source_id`, `period_key`, `config_version`, `idempotency_key`.
2. **Idempotency:** каждый мутирующий POST несёт `Idempotency-Key` (или body `idempotency_key`). Повтор с тем же ключом → тот же результат; с другими параметрами → `409`.
3. **Клиент не задаёт:** размер награды, шанс, seed RNG, чужой `account_id`, `hero_id` призывов, факт победы.
4. **Pending / mail:** невыданное право на награду не теряется (сеть, рестарт, полный инвентарь) — `pending_claims` или почта.
5. **Outbox:** доменные события пишутся в transactional outbox; обработчики идемпотентны.
6. **Контент-пакеты:** JSON из `content/packages/{ver}/` — **конфиг** (версии/hash). Состояние игрока в БД, не в пакете.
7. **VIRTUAL_FREE:** до реальных платежей `payable_price_rub = 0`; store confirm — тестовый endpoint.

---

## 3. Стек CORE-01

| Слой | Выбор |
|---|---|
| Язык | Go 1.22+ |
| БД | PostgreSQL 16 |
| Миграции | `golang-migrate` / goose |
| HTTP | `net/http` или chi; JSON |
| Auth | email/password + guest; сессии / refresh (см. §5) |
| Deploy | Docker Compose: `api` + `postgres` (+ Caddy позже для OTA-2) |
| CI | `go test ./...`, migrate up на ephemeral PG |

Каталог кода (скелет): `server/` в корне репозитория.

---

## 4. Модули MVP (CORE-01 slice)

Реализовать **изолированно**, без микросервисов. Порядок внутри CORE-01:

| # | Модуль | Зачем первым |
|---|---|---|
| 1 | `auth` + `accounts` | сессия |
| 2 | `wallet` + ledger | любая выдача |
| 3 | `content` (read config ver) | привязка к пакету `0.9.0+` |
| 4 | `campaign` progress | этапы CH01… |
| 5 | `battle` start/sim/claim | авторитетный 5v5 |
| 6 | `heroes` collection / formation | отряд |
| 7 | `summon` | pity + RNG |
| 8 | `afk` claim | суточный цикл |
| 9 | `mail` + TTL claim | rollover наград |
| 10 | `store` VIRTUAL_FREE | SKU / VIP stub |

Позже (не блокер старта CORE-01): guilds async raids, live events, daily stories, PvE tower attempts, PvP defense snapshots — схемы уже намечены в каноне.

---

## 5. Auth

| Метод | Поведение |
|---|---|
| `POST /api/v1/auth/register` | email + password hash |
| `POST /api/v1/auth/login` | → access + refresh |
| `POST /api/v1/auth/guest` | одноразовый guest → upgradeable |
| `POST /api/v1/auth/refresh` | ротация refresh |
| `POST /api/v1/auth/logout` | revoke |

- Access JWT или opaque session в Redis/PG (`sessions`).  
- Guest: отдельный флаг; прогресс переносится при привязке email.  
- Все `/api/v1/*` кроме auth/health требуют `Authorization: Bearer …`.

---

## 6. База (ядро)

Минимальные таблицы CORE-01 (имена стабильны; поля уточняются миграциями):

```
accounts(id UUID PK, email NULL UNIQUE, password_hash NULL, is_guest BOOL, created_at, status)
sessions(id, account_id, refresh_hash, expires_at, revoked_at)
wallet_balances(account_id, resource_id, amount BIGINT, version INT, PK(account_id,resource_id))
wallet_ledger(id, account_id, resource_id, delta, source_type, source_id, period_key, config_version, idempotency_key, created_at,
  UNIQUE(account_id, idempotency_key, resource_id, source_type))  -- уточнить уникальность под ledger-паттерн канона
idempotency_keys(account_id, key, request_hash, response_json, created_at, PK(account_id,key))
outbox_events(id, account_id, event_type, payload_json, schema_version, created_at, published_at)

heroes_owned(account_id, hero_id, stars, level, shards, PK(account_id,hero_id))
formations(account_id, slot, hero_id, mode, UNIQUE(account_id, mode, slot))

campaign_progress(account_id PK, current_stage, unlocked_chapter, updated_at)
campaign_stages(account_id, stage_id, stars, first_clear_claimed_at, clears, PK(account_id,stage_id))
story_flags(account_id, flag_id, value, PK(account_id,flag_id))
seen_dialogs(account_id, dialog_id, seen_at, PK(account_id,dialog_id))

battle_instances(id UUID PK, account_id, mode, stage_id, squad_json, seed, status, started_at, finished_at, result_json, config_version)
battle_claims(battle_id PK, account_id, grant_ids_json, claimed_at, idempotency_key UNIQUE)

summon_orders / summon_results / pity — по GACHA_45
afk_state(account_id PK, last_claim_at, accumulated_sec, …)
mail_messages / mail_attachments — по GAME_MAIL
store_orders — по MONETIZATION
content_bindings(account_id PK, package_version, schema)
```

Индексы на `(account_id, …)` и уникальности claim — обязательны до альфы.

---

## 7. API `/api/v1` (сводка)

Префикс единый. Полные списки модулей — в каноне; здесь MVP-срез.

### Health / meta
- `GET /api/v1/health`
- `GET /api/v1/content/active` → `{version, schema, hashes_digest}` (зеркало `active.json`, не замена CDN)

### Wallet / store
- `GET /api/v1/wallet`
- `GET /api/v1/store/catalog`
- `POST /api/v1/store/orders` + `POST …/confirm-test` (VIRTUAL_FREE)

### Heroes / formation
- `GET /api/v1/heroes/collection`
- `PUT /api/v1/formations/{mode}` — 5 слотов, уникальные H*

### Campaign
- `GET /api/v1/campaign/progress`
- `GET /api/v1/campaign/stages/{stage_id}`

### Battle (см. §8)
- `POST /api/v1/battle/start`
- `GET /api/v1/battle/{id}`
- `POST /api/v1/battle/{id}/claim`

### Summon
- `GET /api/v1/summon/banners`
- `POST /api/v1/summon/roll`
- `GET /api/v1/summon/orders/{id}`
- `GET /api/v1/summon/pity`

### AFK / mail
- `GET /api/v1/afk` · `POST /api/v1/afk/claim`
- `GET /api/v1/mail` · `POST /api/v1/mail/{id}/claim` · `POST /api/v1/mail/claim-all`

Ошибки: JSON `{ "error": { "code", "message", "details?" } }` · `401/403/404/409/422/429`.

---

## 8. Протокол боя 5v5

1. **Start** — клиент шлёт `stage_id` / `mode` / `formation_id` (или слоты) + `idempotency_key`.  
   Сервер: доступ к этапу, валидность отряда (5 уникальных H*, владение), создаёт `battle_instances` со **серверным seed**, статус `running`→`finished` в той же или следующей транзакции симуляции.
2. **Simulation** — только на сервере. Правила из канона героев/ригов (SPD clamp, energy, 90s cap, auto skills). Клиент **не** считает урон.  
   Результат: `result_json` = победа/поражение, timeline событий для playback (компактный), loot preview **не** начисленный.
3. **Claim** — идемпотентная выдача first-clear / repeat loot по `loot_tables` конфига; пишет ledger + `campaign_stages`. Повтор claim → тот же grant.
4. Клиент `COMBAT-02` только воспроизводит timeline; чит победы невозможен.

Демо-бой Godot до CORE-01 остаётся локальным и помечен DEMO.

---

## 9. Конфиг vs состояние

| Источник | Что |
|---|---|
| Пакет `content/packages/{ver}` | heroes, enemies, campaign stages, economy SKU, gacha rates, loot… |
| БД | balances, owned heroes, pity, stage clears, mail, orders, battles |
| Studio Express | правка пакета / publish указателя — **не** wallet |

При старте боя/призыва сервер фиксирует `config_version` (= package version). Устаревший клиент → `426` / soft update через OTA content.

---

## 10. Тестовые ворота CORE-01

1. Migrate up/down на чистой PG.  
2. Register → guest upgrade → wallet seed.  
3. Двойной POST claim / roll с одним idempotency key.  
4. Параллельные два roll (race) — один успех списания.  
5. Battle start → claim → повтор claim.  
6. AFK claim через границу 06:00 Europe/Moscow.  
7. Mail expire + claim-all.  
8. Нагрузка smoke: 100 RPS health + 20 RPS authenticated GET wallet.

---

## 11. Блокеры до кода CORE-01

| Блокер | Нужно |
|---|---|
| Доступы | VPS/Docker host или CI secrets для PG |
| Email | SMTP / magic-link провайдер (или stub в dev) |
| Keystore | позже для APK-03, не блокер API |
| OTA-2 | HTTPS CDN — параллельно, не блокер wallet |

Пока Docker/VPS нет: `server/` работает на **in-memory** `store.Memory` — полный MVP-срез §4 (auth…store VIRTUAL_FREE) + CI smoke. Это dev/CI путь, не прод. Postgres adapter подключится к тому же `store.Store` без смены HTTP-контракта (`migrations/0001_init.sql` готов). SQLite как прод-путь **не** используем.

---

## 12. Документы-соседи

- Архитектура: `docs/ARCHITECTURE.md`  
- MVP приёмка: `docs/MVP.md`  
- Пакеты: `docs/CONTENT_PACKAGE_SCHEMA.md`  
- OTA: `docs/CONTENT_OTA.md`  
- Канон API деталей: `docs/content/*.md`

**Следующий шаг после утверждения TZ-A:** реализация CORE-01 по §4 при появлении доступов.
