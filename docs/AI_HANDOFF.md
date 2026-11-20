# Передача · battle replay no-farm (+ H6 device)

Срез 20 ноября 2026. Ветка: `cursor/battle-no-replay-farm-d5fe`. AUTH-04 смержен в `main` (#18).

**Баг владельца:** повтор уже пройденного этапа кампании снова давал награду (hardcoded 500 gold / 200 xp).

**Фикс:** claim без first-clear → пустые rewards; UI «тренировка»; тест `TestBattleClearedStageClaimGivesNoRewards`.

## Next

1. Merge + деплой API → владелец перепроверит повтор боя без награды.
2. Ждать **H6 device OK** / **AUTH-04 device OK**.
3. Позже: replay loot + daily cap по `PROGRESSION_EQUIPMENT_LOOT.md`.
4. ART-05; visual wave3.
