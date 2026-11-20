# CONTENT-C — внедрение «Башкортостан: Разлом эпох»

Канон сюжета/героев/бестиария: `docs/content/STORY_*.md`, `FACTIONS_*.md`, `BESTIARY_*.md`.  
Канон экономики: `MONETIZATION_VIP.md`, `PROGRESSION_EQUIPMENT_LOOT.md`, `GACHA_45_HEROES.md`, `AFK_DAILY_QUESTS_EXPEDITIONS.md`.  
Пакеты: `0.2.0`…**`0.9.0` (active, C6)** · не rewrite старых на месте.

## Порядок мира (C): не «только кампания»

| Почему не так | Риск |
|---|---|
| Сначала только кампания | Этапы → несуществующие H/E/B |
| Полный параллель 6×45×180 | Расходятся ID |

**C0→C6 готовы** (spine → 180 этапов → skills/dialogs → арт-реестр). Дальше **C7** = OTA-2.

## Порядок экономики (E): решено по зависимостям

| Почему не иначе | Риск |
|---|---|
| Сначала магазин/VIP | Награды ссылаются на валюты/свитки, которых нет |
| Сначала гача | Нет `summon_scroll`/`diamonds` и правил звёзд/фрагментов |
| Сначала AFK | Нет ставок в валютах и материалов прогрессии |

**Корректная цепочка:**

```
E0 валюты          ← общий кошелёк (MONETIZATION §2)
 → E1 прогресс/лут ← тратит gold/xp/essence, дроп с CH*
 → E2 гача         ← тратит свитки/алмазы, даёт H*/shards → звёзды
 → E3 AFK/квесты/экспедиции ← выдаёт те же ресурсы, слоты ↔ подписка
 → E4 магазин/VIP/BP VIRTUAL_FREE ← офферы поверх всего (0 ₽)
```

| ID | Этап | Статус | Артефакты |
|---|---|---|---|
| **E0** | Справочник валют/ресурсов | **Готово** | `economy.json` → `currencies` |
| **E1** | Прогресс + 12 сетов + лут CH01 | **Готово** | `progression.json`, `equipment.json`, `loot_tables.json` |
| **E2** | 4 баннера гачи + пулы H01–H45 | **Готово** | `gacha.json` + UI алтаря |
| **E3** | AFK / 12+8 квестов / 18 экспедиций | **Готово** | `liveops.json` + AFK UI |
| **E4** | Магазин SKU / 3 подписки / VIP 0–11 / BP 30 | **Готово (данные+UI демо)** | `economy.json` offers… · без реальных платежей |
| **E5** | Сервер wallet/ledger/RNG | **Memory ✓** (PG next) | `server/` CORE-01 |
| **E6** | Admin Studio economy editors | Частично (`/economy`) | publish/rollback на CDN |

## Этапы сюжета (C)

| ID | Статус | Критерий |
|---|---|---|
| C0–C3 | **Готово** | Spine+CH01 с `0.2.0` |
| C4 | **Готово** | CH01–CH06 ×30 в `0.7.0` |
| C5 | **Готово** | skills + dialogs в `0.8.0` |
| C6 | **Готово** | assets registry + `media/` в `0.9.0` (active) |
| C7 | Дальше | OTA-2 CDN |

## Связи ID

```
currency_id  ←── grants / AFK rates / gacha costs / craft
H0x          ←── gacha pools / expedition heroes / equipment wear
SET0x        ←── loot featured_sets / equipment.sets
CH0y-nn      ←── loot_tables.stage_bindings / unlock gates
sku / sub_*  ←── economy.offers / subscriptions (payable_price_rub=0)
```

Генераторы:  
`…` → `generate_skills_dialogs` → **`generate_assets_c6_package.py`** (active=`0.9.0`).  
Валидатор: `tools/validate_content_package.sh 0.9.0` · ссылки: `tools/check_repo_refs.py`.

## Порядок PvE (P) — после экономики, не ждать C4

| Почему здесь | Почему не раньше / не позже |
|---|---|
| Нужны валюты E0 и материалы E1 | Без `gold`/`boss_core`/`skill_book` некуда класть награды |
| Нужны `B*`/`E*`/`F*` из C1 | Башня/охота ссылаются на бестиарий |
| Unlock `CHxx` можно как gate | Не ждать полные stages CH02–06 (C4) — режимы просто «закрыты» |
| Сервер E5/P3 | Memory ✓; PG — после Docker/VPS |

```
E0–E4 ✓ → P0–P2 ✓ → C4–C6 ✓ → E5/P3 memory ✓ → PG adapter
```

| ID | Этап | Статус | Артефакты |
|---|---|---|---|
| **P0** | Канон + место в ROADMAP | **Готово** | `docs/content/PVE_MODES.md` |
| **P1** | `pve_modes.json` (120 этажей, охота, врата, 4 подземелья) | **Готово** | пакет `0.4.0` |
| **P2** | UI «Испытания» + порталы битвы | **Готово** | `pve_mode.gd`, `battle_modes.json` |
| **P3** | Сервер попыток/урона/claim | **Memory ✓** (campaign battle) | PG next |
| **P4** | Admin Studio PvE editors | После P3 | publish/sim |

## Порядок гильдий (G) — после экономики и PvE-каталога

| Почему здесь | Почему не раньше |
|---|---|
| Нужны валюты/материалы E0–E1 и `guild_token` | Магазин жетонов и вклады |
| Задания ссылаются на Башню/подземелья/экспедиции | После P0–P2 и liveops |
| Рейды используют `B*` из бестиария | После C1 |
| Настоящий общий HP / членство | Только после CORE-01 (G3+) |

```
E0–E4 → P0–P2 → G0–G2 каталог+UI DEMO → CORE-01 → G3+ сервер рейдов
```

Не ждать C4: unlock `CH01-20`, боссы рейдов уже в `enemies.json`.

| ID | Этап | Статус |
|---|---|---|
| **G0** | Канон GUILD-01 | **Готово** |
| **G1** | `guilds.json` (уровни, задания, 5 tier рейдов, магазин) | **Готово** (`0.5.0`) |
| **G2** | UI штаб/задания/рейды/магазин DEMO | **Готово** |
| **G3** | Сервер членства / общий HP / claim | После CORE-01 |
| **G4** | Чат / сезон / Admin Studio | После G3 |

## Порядок meta (почта / календарь / профиль / достижения / сюжет / ивенты)

Решено так — зависимости, не «всё параллельно»:

```
M mail → L login calendars → R profile → A achievements → S daily stories → V live events
```

| Почему | Почему не раньше |
|---|---|
| **M** почта — канал rollover для календаря/достижений/ивентов/гильдии | Без неё незабранные награды некуда класть |
| **L** календари 7/14/30 | Нужны валюты E + шаблон MAIL_LOGIN_UNCLAIMED |
| **R** профиль + косметика | Базовый каталог до выдач A/V; приватность |
| **A** 48+6 достижений | Метрики C/E/P/G уже есть; титулы/рамки → профиль; claim → почта |
| **S** 30 сюжетных дней | Главы + E* бой; не путать с EVENT-01 |
| **V** 6 live-событий | Самый тяжёлый: event_token, гильдия, PvE, магазин |

Mail claim (memory) уже в CORE-01; остальные M3+/L3+/… — после Postgres.

| ID | Этап | Статус |
|---|---|---|
| **M0–M2** | Канон + `mail.json` + UI DEMO | **Готово** (`0.6.0`) |
| **L0–L2** | Канон + `login_calendars.json` + UI | **Готово** |
| **R0–R2** | Канон + `profile.json` + UI | **Готово** |
| **A0–A2** | Канон + `achievements.json` + UI | **Готово** |
| **S0–S2** | Канон + `daily_stories.json` + UI | **Готово** |
| **V0–V2** | Канон + `live_events.json` + UI | **Готово** |
| **M3** | Mail claim (сервер) | **Memory ✓** · PG next |
| **L3+/…** | Календарь / профиль / … | После PG |

## Отложено сознательно

- Postgres persistence (Docker/VPS).
- Реальные IAP / billing SDK.
- Полный UI инвентаря экипировки и экранов экспедиций (данные есть).
- Гильдии / live-events / daily-story сервер (G3+, V3+, S3+).
