# CONTENT-C — внедрение «Башкортостан: Разлом эпох»

Канон сюжета/героев/бестиария: `docs/content/STORY_*.md`, `FACTIONS_*.md`, `BESTIARY_*.md`.  
Канон экономики: `MONETIZATION_VIP.md`, `PROGRESSION_EQUIPMENT_LOOT.md`, `GACHA_45_HEROES.md`, `AFK_DAILY_QUESTS_EXPEDITIONS.md`.  
Пакеты: `0.2.0` · `0.3.0` (E0–E4) · **`0.4.0` (PvE P0–P2)** · не rewrite старых на месте.

## Порядок мира (C): не «только кампания»

| Почему не так | Риск |
|---|---|
| Сначала только кампания | Этапы → несуществующие H/E/B |
| Полный параллель 6×45×180 | Расходятся ID |

**C0→C3 готовы** (spine + CH01). Дальше C4–C7 по главам/арту.

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
| **E5** | Сервер wallet/ledger/RNG | После CORE-01 | Go + Postgres |
| **E6** | Admin Studio economy editors | После E5 | publish/rollback |

## Этапы сюжета (C)

| ID | Статус | Критерий |
|---|---|---|
| C0–C3 | **Готово** | Пакет 0.2.0 / активный мир в 0.3.0 |
| C4 | Дальше | CH02–CH06 данные |
| C5–C7 | Дальше | навыки / арт / OTA-2 |

## Связи ID

```
currency_id  ←── grants / AFK rates / gacha costs / craft
H0x          ←── gacha pools / expedition heroes / equipment wear
SET0x        ←── loot featured_sets / equipment.sets
CH0y-nn      ←── loot_tables.stage_bindings / unlock gates
sku / sub_*  ←── economy.offers / subscriptions (payable_price_rub=0)
```

Генераторы: `tools/generate_razlom_package.py`, `tools/generate_economy_package.py`.  
Валидатор: `tools/validate_content_package.sh 0.3.0`.

## Порядок PvE (P) — после экономики, не ждать C4

| Почему здесь | Почему не раньше / не позже |
|---|---|
| Нужны валюты E0 и материалы E1 | Без `gold`/`boss_core`/`skill_book` некуда класть награды |
| Нужны `B*`/`E*`/`F*` из C1 | Башня/охота ссылаются на бестиарий |
| Unlock `CHxx` можно как gate | Не ждать полные stages CH02–06 (C4) — режимы просто «закрыты» |
| До сервера E5/CORE-01 | UI+каталог DEMO; попытки авторитетны позже |

```
E0–E4 экономика ✓ → P0–P2 PvE каталог+UI ✓ → C4 главы → E5/P3 сервер
```

| ID | Этап | Статус | Артефакты |
|---|---|---|---|
| **P0** | Канон + место в ROADMAP | **Готово** | `docs/content/PVE_MODES.md` |
| **P1** | `pve_modes.json` (120 этажей, охота, врата, 4 подземелья) | **Готово** | пакет `0.4.0` |
| **P2** | UI «Испытания» + порталы битвы | **Готово** | `pve_mode.gd`, `battle_modes.json` |
| **P3** | Сервер попыток/урона/claim | После CORE-01 | Go API |
| **P4** | Admin Studio PvE editors | После P3 | publish/sim |

## Отложено сознательно

- Авторитетный кошелёк / дроп / pity (CORE-01).
- Реальные IAP / billing SDK.
- Полный UI инвентаря экипировки и экранов экспедиций (данные есть; экраны — следующий вертикальный срез).
- Лут привязки CH02–CH06 (после C4).
