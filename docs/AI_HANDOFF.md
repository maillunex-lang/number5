# Передача · ART-05 battle portraits/atlases

Срез 20 ноября 2026. Ветка: `cursor/art-05-battle-portraits-d5fe`.

**Сделано:** `tools/generate_art05_placeholders.py` → media heroes/rigs webp (force-add в git); `AssetLoader` package textures; `BattleUnit` atlas clips; playback attack/hit/death; HUD + FormationSlot + HeroCard portraits; checklist `docs/ART_05_DEVICE_VERIFY.md`. Headless: H01 portrait+atlas + E01-01 enemy atlas/skin OK; Android export APK ~35MB с `.ctex` в assets. `ops/deploy-vps.sh` regenerate перед export.

## Next

1. Merge → VPS APK → **ART-05 device OK** (`docs/ART_05_DEVICE_VERIFY.md`).
2. Владелец: H6 / AUTH-04 device.
3. Финальный арт Studio вместо placeholder; wave4 UI (hero_details / squad / auth).
