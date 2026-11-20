# Передача · UX loading + faster sync/claim

Срез 20 ноября 2026. Ветка: `cursor/ux-loading-claim-feedback-d5fe`.

**Проблема:** вход ~5с (6 serial HTTP); после боя ~3с claim+wallet+campaign с пустым экраном.

**Сделано:**
- `sync_player` — параллельные GET (`_parallel_authed_gets`); heartbeat после входа.
- Auth: LoadingOverlay + progress; health не гоняет restore.
- Battle result: награды сразу после claim; wallet/campaign в фоне; progress bar на ожидании claim.

## Next

1. Merge → APK → проверить вход и экран победы.
2. Wave5 UI / optional bootstrap API bundle.
