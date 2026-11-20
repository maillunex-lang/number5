# Передача · AUTH-04 prep (+ H6 device parallel)

Срез 20 ноября 2026. Ветка: `cursor/auth-04-prep-d5fe`.

**Параллельно:** владелец тестирует H6 на устройстве (`docs/H6_DEVICE_VERIFY.md`).

**Сделано:** AUTH-04 prep — credentials на Memory (CI) + Postgres; `POST /auth/logout`; client `link_guest` → me/sync/save; settings «Привязать»; auth API tests; `docs/AUTH_04_DEVICE_VERIFY.md`; `tools/auth_04_verify_api.sh`.

## Next

1. Ждать **H6 device OK** → закрыть H6 в STATUS.
2. После merge AUTH-04 + новый APK → **AUTH-04 device OK** по чеклисту.
3. ART-05; visual wave3.
