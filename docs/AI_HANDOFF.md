# Передача · fix sync hang on login overlay

Срез 20 ноября 2026. Ветка: `cursor/fix-sync-hang-parallel-d5fe`.

**Баг:** `_parallel_authed_gets` — лямбда захватывала общий `http` из цикла → `queue_free` чужого запроса → `pending` не доходил до 0 → оверлей «С возвращением» навечно.

**Сделано:** nodes[] по индексу; CONNECT_ONE_SHOT; deadline timeout; auth watchdog 18с.

## Next

1. Merge → срочный APK → проверить restore/login.
2. Wave5 UI.
