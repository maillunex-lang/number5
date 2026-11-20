# Передача проекта · FIX-GODOT-DEPLOY-002

Срез от 20 ноября 2026. Ветка: `cursor/fix-godot-deploy-002-d5fe`.

**Сделано:**

- Theme: пользовательская вариация `PopupPanel` → `GamePopupPanel` (`theme/lunex_theme.tres`, `popup_window`, `game_panel`)
- `battle_playback.gd`: явная типизация `end_ev` / timeline / unit views (Godot 4.7.2: `:=` из Variant — ошибка)
- `shop.gd` + `shop_offer_card` / `mail_item` / `battle_unit` / `hub_building`: убраны Variant-`:=`
- Проверки: headless import без SCRIPT ERROR/Parse Error; `tools/verify_project.sh` OK; Admin Studio build OK
- Android APK export в cloud-агенте **недоступен** (нет SDK/templates) — на VPS после merge в `main`
- `ops/deploy-vps.sh`: ждёт зелёный CI `main`, import+export, откат при ошибке, health API — менять не потребовалось

**Процесс:** после зелёного CI **merge в `main`**.

## Next

1. Дождаться auto-deploy на VPS / проверить APK versionCode > 29.
2. H6 device verify на новом APK.
3. ATOMIC-ECONOMY / TD-PG-RACE; AUTH-04; ART-05.
4. Visual: formation slots, settings tabs, map nodes.
