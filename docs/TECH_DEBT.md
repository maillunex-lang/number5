# TECH_DEBT — реестр проблем

Дата: 2026-11-20 · источник: master audit.  
Типы: **BUG** (подтверждено) · **RISK** · **IMPROVE**.  
Не путать с wishlist ROADMAP.

| ID | Тип | Описание | Риск | Файлы | Доказательство | Исправление | Prio | Критерий закрытия |
|---|---|---|---|---|---|---|---|---|
| TD-ATOMIC | BUG | ~~Ledger и side-effects не в одной TX~~ | — | battle/afk/mail(+claim-all)/shop/summon + `store.RunAtomic` | закрыто | Memory rollback + PG TX | P1 | ✅ crash mid-op откатывает |
| TD-PG-RACE | RISK | ~~PG ApplyLedger без FOR UPDATE~~ | — | `store/postgres` advisory+row lock | закрыто | concurrent debit test | P1 | ✅ |
| TD-ID | RISK | Memory IDs `acc_*` ≠ UUID PG | Средний | memory vs postgres | CreateGuest | единый UUID ID gen | P1 | один формат ID |
| TD-PUBHIST | IMPROVE | publish_history до 0.6.0 | Низкий | admin-studio publish | файл | дописать 0.7–0.9 | P2 | history полный |
| TD-NILMOD | RISK | Catalog fail → nil Battle/Summon panic | Средний | `cmd/api/main.go` | код | fail boot / 503 | P1 | — |
| TD-FORM-PG | RISK | GetFormation missing → ErrNotFound на PG vs empty memory | Средний | postgres vs memory | код | выровнять семантику | P1 | — |

## Приоритеты версии 0.5.5

Миграция 0002 добавляет player_profiles и журнал изменений профиля. H6 code: детерминированная timeline на сервере и COMBAT-02 playback в клиенте. Device verify после новой APK — в [дорожной карте](ROADMAP.md).
