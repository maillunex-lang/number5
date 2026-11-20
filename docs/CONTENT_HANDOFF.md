# CONTENT-C — статус передачи

Канон **«Башкортостан: Разлом эпох»** принят в репозиторий. Рабочее имя «Элиориан» из CONTENT-01 больше **не** используется в активном пакете `0.2.0`.

## Источники (канон)

| Файл | Содержание |
|---|---|
| `docs/content/STORY_6_CHAPTERS.md` | 6 глав, зоны, 30 этапов/глава, сюжет |
| `docs/content/FACTIONS_45_HEROES.md` | F01–F06, H01–H45, статы L1, навыки |
| `docs/content/BESTIARY_6_CHAPTERS.md` | 6 ригов, E**/B**, encounters |
| `docs/content/MONETIZATION_VIP.md` | Магазин VIRTUAL_FREE, VIP, BP |
| `docs/content/PROGRESSION_EQUIPMENT_LOOT.md` | Уровни, сеты, дроп |
| `docs/content/GACHA_45_HEROES.md` | 4 баннера, pity |
| `docs/content/AFK_DAILY_QUESTS_EXPEDITIONS.md` | AFK, квесты, 18 миссий |
| `docs/content/PVE_MODES.md` | Башня, охота, врата, подземелья |
| `docs/CONTENT_IMPLEMENTATION.md` | Фазы C0–C7 и инварианты ID |

## Что уже в игре (C0–C3 + E0–E4)

- Пакет `content/packages/0.2.0/` + `active.json` → `0.2.0`
- Герои/фракции/враги/CH01 связаны по ID
- Клиент: `enemies_pack` + `economy`/`gacha`/`liveops`; бой из encounters; магазин 0 ₽; алтарь; AFK ставки
- Активный пакет **0.4.0** (+ PvE)

## Что ещё нужно решить / доделать

| Блок | Статус | Комментарий |
|---|---|---|
| Фракции (6) | **В данных** | Бонусы 2/3/5 — проект, не в бою |
| 45 героев | **Реестр + L1 статы** | Полные skill cards → C5 |
| Кампания гл.1 | **30 этапов** | CH02–06 → C4 |
| Бестиарий | **36+18 ID** | Арт ригов → C6 |
| Экономика / призыв | Черновик в `features.json` | Утвердить веса/капы |
| Доступы CORE-01 | Открыто | Docker/VPS/email/keystore |

Пересборка пакета из канона: `python3 tools/generate_razlom_package.py` → валидатор → новая версия `0.2.x`.
