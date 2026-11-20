# Передача · mail ClaimAll atomic (+ пока H6 device)

Срез 20 ноября 2026. Ветка: `cursor/mail-claim-all-atomic-d5fe`.

**Сейчас:** владелец тестирует H6 на устройстве (`docs/H6_DEVICE_VERIFY.md`).

**Сделано параллельно:** `mail.ClaimAll` — ledger затем SaveMail в одной `RunAtomic` TX (больше нет «claimed без награды»).

## Next

1. Ждать **H6 device OK** → закрыть пункт в STATUS.
2. **AUTH-04** — email register / bind guest / session expiry (код в `server/internal/modules/auth`, UI auth scene); device verify на Android.
3. ART-05; visual wave3.
