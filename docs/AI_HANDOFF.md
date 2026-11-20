# Передача проекта · UI visual-editor + H6

Срез от 20 ноября 2026. Ветка работы UI: `cursor/godot-visual-editor-ready-d5fe` (мержится в `main` после CI).

**Сделано ранее:** P0 device OK · H6 code · фикс rewind «В хаб».

**Сделано в visual-editor PR + wave2:**

- Аудит, Theme StyleBox, библиотека компонентов, preview, docs, AGENTS UI rules
- Wave2 шаблоны: `HubBuilding`, `BattleUnit`, `MailItem`, `ShopOfferCard`; wiring hub/playback/heroes/mail/shop
- `DemoScreenBuilder` секции → `GamePanel`

**Процесс:** после зелёного CI **merge в `main` по умолчанию**.

## Next

1. APK с H6 + visual wave1/2 → device verify.
2. ATOMIC-ECONOMY / TD-PG-RACE.
3. AUTH-04, ART-05.
4. Дальше visual: formation slots, settings tabs chrome, map nodes template.

Godot headless в cloud-агенте может отсутствовать — проверять локально F6 preview + export по `docs/ANDROID_BUILD.md`.
