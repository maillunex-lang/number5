# Передача проекта · UI visual-editor + H6

Срез от 20 ноября 2026. Ветка работы UI: `cursor/godot-visual-editor-ready-d5fe` (мержится в `main` после CI).

**Сделано ранее:** P0 device OK · H6 code · фикс rewind «В хаб».

**Сделано в visual-editor PR:**

- Аудит `docs/UI_VISUAL_AUDIT.md`
- Theme StyleBox в `theme/styles/` + обновлённый `theme/lunex_theme.tres` (GameButton/GoldButton/GamePanel)
- Библиотека `scenes/ui/components/*`
- `UIFactory` → инстанс визуальных кнопок
- COMBAT-03 chrome в `.tscn`; TopBar/BottomNav `@export`
- Preview `scenes/ui/preview/ui_preview_root.tscn`
- `docs/HOW_TO_EDIT_UI_IN_GODOT.md`, `docs/UI_DEVELOPMENT_RULES.md`, правила в `AGENTS.md`

**Процесс:** после зелёного CI **merge в `main` по умолчанию**.

## Next

1. APK с H6 + visual chrome → device verify playback и «В хаб».
2. Продолжить миграцию CODE_HEAVY экранов (hub buildings остаются из JSON; списки → HeroCard/RewardCard).
3. ATOMIC-ECONOMY / TD-PG-RACE.
4. AUTH-04, ART-05.

Godot headless в cloud-агенте может отсутствовать — проверять локально F6 preview + export по `docs/ANDROID_BUILD.md`.
