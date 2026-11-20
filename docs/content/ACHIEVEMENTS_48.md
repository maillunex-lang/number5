# ACHIEVEMENT-01 · 48 достижений и 6 секретных

**Дата:** 2026-11-20 · **Формат:** самостоятельное подробное ТЗ для Cursor

## Общий контракт проекта
- Проект: Lunex AFK «Башкортостан: Разлом эпох»; репозиторий `maillunex-lang/number5`, ветка `main`; вертикальный Godot 4.7.2, Android и планируемый веб/PWA; авторитетный Go/PostgreSQL и Lunex Admin Studio.
- Канон: 6 глав, 180 этапов `CH01-01`…`CH06-30`; 45 героев `H01`…`H45`, фракции `F01`…`F06`, редкости N/R/SR/SSR/UR. Не добавлять новых героев и риги без отдельного решения.
- Единый дневной сброс: **06:00 Europe/Moscow**, недельный: понедельник 06:00 МСК. Время и награды определяет сервер, не телефон.
- Единый кошелёк/инвентарь: `gold`, `diamonds`, `hero_xp`, `essence`, `summon_scroll`, `faction_scroll`, `cosmetic_token`, `afk_hour`, `skill_book`, `ore`, `boss_core`, `set_pattern`, `guild_token` по существующим спецификациям. Не заводить второй баланс.
- ×10 призыва выдаёт **10 результатов за 8 предметов**; событие не должно обойти гача pity или удваивать награды. Дубликат героя = 30 персональных фрагментов.
- Магазин остаётся `VIRTUAL_FREE`: никакого реального платежа, все тестовые начисления серверные, атомарные и с явной маркировкой.
- Ни один экран не меняет утверждённую нижнюю навигацию без аудита `docs/STRUCTURE.md`; адаптация 9:16, safe areas, устройства Android с 6 ГБ RAM.
- **Статус:** проектная спецификация, а не свидетельство внедрения. Баланс ниже предложен для тестирования и хранится в конфигурации. Перед реализацией Cursor сверяет реальные модели, API, контентный manifest и смежные документы, составляет conflict report.

## 1. Модель достижений
Достижения выдаются за **серверно подтверждённые** действия и прогресс. Не вводить отдельный боевой бонус за достижения. Награды: `diamonds`, `gold`, `summon_scroll`, `cosmetic_token`, титулы, рамки. Один прогресс учитывается через единый event bus; повтор события с тем же `event_id` не повышает счётчик дважды. Достижение может быть `single`, `tiered` (ступени) или `hidden` (секретное).

## 2. Категории и полная стартовая матрица (48 достижений)
| ID | Название | Условие | Награда |
|---|---|---|---|
| `ACH_STORY_01` | Первый шаг | `campaign_unique_clears` ≥ 1 | `diamonds:50` |
| `ACH_STORY_02` | Десять решений | `campaign_unique_clears` ≥ 10 | `diamonds:75` |
| `ACH_STORY_03` | Тридцать дорог | `campaign_unique_clears` ≥ 30 | `diamonds:100` |
| `ACH_STORY_04` | Шестьдесят испытаний | `campaign_unique_clears` ≥ 60 | `diamonds:125` |
| `ACH_STORY_05` | Девяносто битв | `campaign_unique_clears` ≥ 90 | `diamonds:150` |
| `ACH_STORY_06` | Сто двадцать этапов | `campaign_unique_clears` ≥ 120 | `diamonds:175` |
| `ACH_STORY_07` | Сто пятьдесят этапов | `campaign_unique_clears` ≥ 150 | `summon_scroll:1` |
| `ACH_STORY_08` | Разлом закрыт | `campaign_unique_clears` ≥ 180 | `summon_scroll:2` |
| `ACH_HERO_01` | Первый герой | `unique_owned_heroes` ≥ 1 | `diamonds:50` |
| `ACH_HERO_02` | Пятеро в строю | `unique_owned_heroes` ≥ 5 | `diamonds:75` |
| `ACH_HERO_03` | Десять имён | `unique_owned_heroes` ≥ 10 | `diamonds:100` |
| `ACH_HERO_04` | Пятнадцать героев | `unique_owned_heroes` ≥ 15 | `diamonds:125` |
| `ACH_HERO_05` | Двадцать героев | `unique_owned_heroes` ≥ 20 | `diamonds:150` |
| `ACH_HERO_06` | Тридцать героев | `unique_owned_heroes` ≥ 30 | `diamonds:175` |
| `ACH_HERO_07` | Сорок героев | `unique_owned_heroes` ≥ 40 | `summon_scroll:1` |
| `ACH_HERO_08` | Все сорок пять | `unique_owned_heroes` ≥ 45 | `summon_scroll:2` |
| `ACH_SUMMON_01` | Первый призыв | `summon_results` ≥ 1 | `diamonds:50` |
| `ACH_SUMMON_02` | Десять зовов | `summon_results` ≥ 10 | `diamonds:75` |
| `ACH_SUMMON_03` | Пятьдесят зовов | `summon_results` ≥ 50 | `diamonds:100` |
| `ACH_SUMMON_04` | Сто зовов | `summon_results` ≥ 100 | `diamonds:125` |
| `ACH_SUMMON_05` | Двести зовов | `summon_results` ≥ 200 | `diamonds:150` |
| `ACH_SUMMON_06` | Пятьсот зовов | `summon_results` ≥ 500 | `diamonds:175` |
| `ACH_SUMMON_07` | Тысяча зовов | `summon_results` ≥ 1000 | `summon_scroll:1` |
| `ACH_SUMMON_08` | Мастер призыва | `summon_results` ≥ 2000 | `summon_scroll:2` |
| `ACH_PVE_01` | Башня: 10 | `tower_highest_floor` ≥ 10 | `diamonds:50` |
| `ACH_PVE_02` | Башня: 20 | `tower_highest_floor` ≥ 20 | `diamonds:75` |
| `ACH_PVE_03` | Башня: 40 | `tower_highest_floor` ≥ 40 | `diamonds:100` |
| `ACH_PVE_04` | Башня: 60 | `tower_highest_floor` ≥ 60 | `diamonds:125` |
| `ACH_PVE_05` | Башня: 80 | `tower_highest_floor` ≥ 80 | `diamonds:150` |
| `ACH_PVE_06` | Башня: 100 | `tower_highest_floor` ≥ 100 | `diamonds:175` |
| `ACH_PVE_07` | Башня: 110 | `tower_highest_floor` ≥ 110 | `summon_scroll:1` |
| `ACH_PVE_08` | Башня: 120 | `tower_highest_floor` ≥ 120 | `summon_scroll:2` |
| `ACH_AFK_01` | Первый сбор | `afk_claim_count` ≥ 1 | `diamonds:50` |
| `ACH_AFK_02` | Пять сборов | `afk_claim_count` ≥ 5 | `diamonds:75` |
| `ACH_AFK_03` | Десять сборов | `afk_claim_count` ≥ 10 | `diamonds:100` |
| `ACH_AFK_04` | Двадцать сборов | `afk_claim_count` ≥ 20 | `diamonds:125` |
| `ACH_AFK_05` | Пятьдесят сборов | `afk_claim_count` ≥ 50 | `diamonds:150` |
| `ACH_AFK_06` | Сто сборов | `afk_claim_count` ≥ 100 | `diamonds:175` |
| `ACH_AFK_07` | Двести сборов | `afk_claim_count` ≥ 200 | `summon_scroll:1` |
| `ACH_AFK_08` | Пятьсот сборов | `afk_claim_count` ≥ 500 | `summon_scroll:2` |
| `ACH_GUILD_01` | Первое вступление | `guild_joins` ≥ 1 | `diamonds:50` |
| `ACH_GUILD_02` | Три поручения | `guild_quests_claimed` ≥ 3 | `diamonds:75` |
| `ACH_GUILD_03` | Десять поручений | `guild_quests_claimed` ≥ 10 | `diamonds:100` |
| `ACH_GUILD_04` | Первый рейд | `guild_raid_participations` ≥ 1 | `diamonds:125` |
| `ACH_GUILD_05` | Пять рейдов | `guild_raid_participations` ≥ 5 | `diamonds:150` |
| `ACH_GUILD_06` | Десять рейдов | `guild_raid_participations` ≥ 10 | `diamonds:175` |
| `ACH_GUILD_07` | Пятьдесят поручений | `guild_quests_claimed` ≥ 50 | `summon_scroll:1` |
| `ACH_GUILD_08` | Сто поручений | `guild_quests_claimed` ≥ 100 | `summon_scroll:2` |

**Уточнение:** счётчик `summon_results` считает реально выданные результаты, то есть ×10 добавляет **10**, хотя стоит 8 предметов. Для `unique_owned_heroes` не учитывать дубликаты. Для `campaign_unique_clears` только уникальные впервые пройденные этапы. В таблице `guild_joins` засчитывать **первое вступление в жизни**, не каждый переход между гильдиями. Для рейдов учитывать валидное участие, а не бесконечные клики. Названия/пороги являются стартовым предложением.

## 3. Дополнительные секретные достижения (без обязательных наград силы)
| ID | Условие | Награда |
|---|---|---|
| `ACH_SECRET_01` | Пройти этап без потери HP героев | титул `title_untouched` |
| `ACH_SECRET_02` | Победить босса с 1 выжившим героем | `cosmetic_token:100` |
| `ACH_SECRET_03` | Победить в Башне составом из пяти N героев | рамка `frame_unlikely` |
| `ACH_SECRET_04` | Выполнить 7 разных ежедневных задач за день | `diamonds:100` |
| `ACH_SECRET_05` | Завершить рейд с минимальным ненулевым вкладом | титул `title_last_spark` |
| `ACH_SECRET_06` | Завершить все 6 глав | фон `profile_rift` |

Секреты раскрываются после выполнения, но сервер всё равно проверяет условие. Нельзя создавать достижение, требующее конкретного UR или доната.

## 4. Выдача и UI
Достижение может быть `locked`, `completed_unclaimed`, `claimed`. После достижения порога сервер создаёт уникальное право на награду. Игрок забирает в `Главная → Достижения`, либо по окончании срока активности/при техническом сбое награда переносится в почту. **Обычные достижения бессрочны**, не сгорают. Ступенчатые показывают следующий порог и прогресс. Награды за уже пройденную кампанию при внедрении нужно пересчитать один раз из авторитетного прогресса, не из клиентских событий. Уведомление о новом достижении не прерывает бой.

## 5. Данные/API
`achievement_definitions(id PK, category, metric, threshold, reward_json, hidden, version)`; `achievement_progress(account_id,achievement_id,progress,completed_at,claimed_at,PK(account_id,achievement_id))`; `achievement_event_dedupe(account_id,event_id,processed_at,PK(account_id,event_id))`. Использовать общую таблицу прав на награды и wallet ledger.

`GET /api/v1/achievements`, `GET /api/v1/achievements/summary`, `POST /api/v1/achievements/{id}/claim`. События `achievement_completed`, `achievement_claimed`, `cosmetic_unlocked`. Админка: редактор 48+6 записей, проверка метрик и источников, dry-run пересчёта для старых аккаунтов, симуляция экономики.

## 6. QA
Проверить все 48 ID уникальны; прогресс 179→180; ×10 добавляет 10 результатов; дубликат героя не увеличивает коллекцию; повторный бой не увеличивает уникальные этапы; старые аккаунты получают корректный backfill; одно событие не считается дважды; секрет скрыт; награда один раз; заблокированный режим не выдаёт награду; 6 глав без UR; безопасное отображение длинных названий; работа при пропаже сети.


## Технические требования, единые для реализации
1. Все выдачи проводить в одной транзакции с существующим wallet/inventory ledger; `source_type`, `source_id`, `account_id`, `period_key`, `config_version`, `idempotency_key` обязательны. Уникальные индексы исключают повторный claim.
2. События публиковать через существующий event bus или transactional outbox: `event_id`, `account_id`, `event_type`, `occurred_at`, `payload`, `schema_version`; обработчики идемпотентны.
3. Клиент не может задавать размер награды, вероятность, завершённость задания, время или чужой `account_id`. GET возвращает серверное состояние и версию конфига; POST проверяет право и состояние.
4. Невыданные награды сохраняются в `pending_claims` или игровой почте; не теряются при сетевой ошибке, переполнении инвентаря или рестарте.
5. Админка: черновик → схема/проверка ссылок → симуляция → публикация версии → откат; audit log с actor, причиной и diff. Тестовые выдачи только в sandbox либо с отдельным разрешением и логом.
6. Автотесты: повтор POST, параллельный POST, неверный account_id, устаревший конфиг, переход через 06:00 МСК, рестарт, отсутствующий ассет, Android 9:16, плохая сеть, неактивный аккаунт.
7. API проектировать как `/api/v1/...`; названия адаптировать к фактическим роутам после аудита, не плодить несовместимые endpoints.

## Порядок работы Cursor
- Фаза 0: read-only аудит репозитория и сверка всех смежных `.md`; отчёт `есть / частично / нет / конфликт`.
- Фаза 1: контентные JSON/валидация/миграции, без ломания текущего manifest.
- Фаза 2: вертикальный UI-срез на реальных игровых данных, без фиктивного онлайна; если backend отсутствует, явная маркировка DEMO.
- Фаза 3: серверные API, транзакции, журналы, таймеры, восстановление.
- Фаза 4: Admin Studio, симулятор баланса, аналитика.
- Фаза 5: QA, нагрузка, локализация, оптимизация и регрессионные тесты.

