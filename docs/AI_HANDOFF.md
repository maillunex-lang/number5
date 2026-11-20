# Передача · после merge #18+#19

Срез 20 ноября 2026. `main` = `fdd4f82` (AUTH-04 + battle no-farm).

**Сделано сегодня:** AUTH-04 code; баг «повтор боя = снова награда» закрыт (claim только first clear).

## Блокер на владельце (телефон)

1. **Деплой API** с `main` (если VPS auto — уже), перепроверить: повтор cleared-этапа → без наград.
2. **H6 device OK** — `docs/H6_DEVICE_VERIFY.md` (+ шаг 5b).
3. **AUTH-04 device OK** — `docs/AUTH_04_DEVICE_VERIFY.md` (нужен свежий APK с link UI).

## Next для агента (пока ждут device)

1. **ART-05** — аудит портретов/атласов/анимаций в боевой сцене (код/контент), чеклист на устройство.
2. Или UI-VISUAL wave3 (formation/settings/map nodes).
3. Replay loot + daily cap — только после явного приоритета (канон PROGRESSION).
