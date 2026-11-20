# TECH_DEBT — реестр проблем

Дата: 2026-11-20 · источник: master audit.  
Типы: **BUG** (подтверждено) · **RISK** · **IMPROVE**.  
Не путать с wishlist ROADMAP.

| ID | Тип | Описание | Риск | Файлы | Доказательство | Исправление | Prio | Критерий закрытия |
|---|---|---|---|---|---|---|---|---|
| TD-H4 | RISK | Memory fallback в prod при отсутствии/ошибке PG | Высокий | `server/cmd/api/main.go` | silent fallback | Fail-closed если `APP_ENV=prod` | P0 | prod без URL → non-zero exit |
| TD-H5 | RISK | `grant-test` / `confirm-test` в default `APP_ENV=dev` | Высокий | wallet/shop/mux | код | Только `APP_ENV=test` | P0 | 403 вне test + go test |
| TD-H6 | BUG | Local battle win → новый server start (desync) | Высокий | `battle_playback.gd`, `battle_result.gd`, battle service | аудит UI/API | Server timeline → playback → claim | P0 | E2E: один battle_id на бой |
| TD-ATOMIC | BUG | Ledger и heroes/pity/mail/campaign не в одной TX | Высокий | summon/mail/battle/shop services | код | Одна транзакция store | P1 | crash mid-op безопасен |
| TD-PG-RACE | RISK | PG ApplyLedger без FOR UPDATE | Высокий | `store/postgres` | код | row lock / serializable | P1 | concurrent debit test |
| TD-ID | RISK | Memory IDs `acc_*` ≠ UUID PG | Средний | memory vs postgres | CreateGuest | единый UUID ID gen | P1 | один формат ID |
| TD-LOGOUT | BUG | Logout не чистит ApiClient token | Средний | `settings.gd`, `api_client.gd` | код | clear_session | P1 | online=false после logout |
| TD-SYNC | RISK | get_heroes/get_campaign не вызываются | Средний | api_client + heroes/map | grep | UI sync | P1 | online UI = server |
| TD-EMAIL | IMPROVE | Email login всегда offline | Средний | `auth.gd` | код | API login или явный DEMO badge | P2 | — |
| TD-PUBHIST | IMPROVE | publish_history до 0.6.0 | Низкий | admin-studio publish | файл | дописать 0.7–0.9 | P2 | history полный |
| TD-NILMOD | RISK | Catalog fail → nil Battle/Summon panic | Средний | `cmd/api/main.go` | код | fail boot / 503 | P1 | — |
| TD-HEALTH | IMPROVE | health не дергается клиентом | Низкий | version_check | код | probe | P2 | — |
| TD-HTTP1 | RISK | Один HTTPRequest в ApiClient | Средний | api_client.gd | код | очередь/пул | P2 | — |
| TD-FORM-PG | RISK | GetFormation missing → ErrNotFound на PG vs empty memory | Средний | postgres vs memory | код | выровнять семантику | P1 | — |

## Утверждённые, но не внедрённые

H4, H5, H6 — решения PO 2026-11-20; реализация **отдельными** задачами ROADMAP, не смешивать с docs-only PR.
