# Передача проекта · H6 device verify

Срез от 20 ноября 2026. Ветка: `cursor/h6-device-verify-prep-d5fe`.

**Сделано в коде (prep):**

- Стабильный claim idempotency: `claim:{battle_id}` в `ApiClient.battle_claim` (replay после обрыва сети)
- API-тесты: GET reconnect timeline, claim replay + stage advance
- `docs/H6_DEVICE_VERIFY.md` + `tools/h6_verify_api.sh`
- Smoke: online → `battle_start` + COMBAT-02 с server timeline

**Владельцу:** пройти чеклист в `docs/H6_DEVICE_VERIFY.md` на свежем APK и написать **H6 device OK**.

## Next после device OK

1. AUTH-04 / UI-SYNC-HEROES  
2. ART-05  
3. mail ClaimAll → RunAtomic (остаток TD-ATOMIC)  
4. Visual wave3  
