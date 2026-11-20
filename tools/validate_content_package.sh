#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER="${1:-}"
if [[ -z "$VER" ]]; then
  VER="$(python3 -c "import json; print(json.load(open('$ROOT/content/packages/active.json'))['version'])")"
fi
DIR="$ROOT/content/packages/$VER"
echo "Validating package $VER at $DIR"
test -d "$DIR"
REQUIRED=(manifest.json hub.json campaign.json heroes.json battle_modes.json features.json theme.json shell.json strings.json motion.json assets.json)
for f in "${REQUIRED[@]}"; do
  test -f "$DIR/$f"
  python3 -c "import json; json.load(open('$DIR/$f')); print(' OK', '$f')"
done
# enemies.json обязателен с schema 3 / 0.2.0+
if [[ -f "$DIR/enemies.json" ]]; then
  python3 -c "import json; json.load(open('$DIR/enemies.json')); print(' OK', 'enemies.json')"
fi
python3 - <<PY
import json
from pathlib import Path
d = Path("$DIR")
ver = "$VER"
hub = json.loads((d/"hub.json").read_text())
camp = json.loads((d/"campaign.json").read_text())
heroes = json.loads((d/"heroes.json").read_text())
modes = json.loads((d/"battle_modes.json").read_text())
feat = json.loads((d/"features.json").read_text())
theme = json.loads((d/"theme.json").read_text())
shell = json.loads((d/"shell.json").read_text())
strings = json.loads((d/"strings.json").read_text())
motion = json.loads((d/"motion.json").read_text())
assets = json.loads((d/"assets.json").read_text())
assert hub.get("buildings"), "hub.buildings required"
assert camp.get("stages"), "campaign.stages required"
assert heroes.get("heroes"), "heroes.heroes required"
assert modes.get("portals"), "battle_modes.portals required"
assert "shop_offers" in feat
assert theme.get("palette"), "theme.palette required"
assert shell.get("bottom_nav", {}).get("tabs"), "shell tabs required"
assert strings.get("entries"), "strings.entries required"
assert "transition_ms" in motion
assert isinstance(assets.get("items"), list)
print("Semantic checks OK")

# Cross-ID invariants for 0.2.0+
if (d/"enemies.json").exists():
    en = json.loads((d/"enemies.json").read_text())
    hero_ids = {h["id"] for h in heroes["heroes"]}
    faction_ids = {f["id"] for f in heroes.get("factions", [])}
    enemy_ids = {e["id"] for e in en.get("enemies", [])}
    boss_ids = {b["id"] for b in en.get("bosses", [])}
    all_foes = enemy_ids | boss_ids
    rig_ids = {r["id"] for r in en.get("rigs", [])}
    stage_ids = {s["id"] for s in camp["stages"]}
    for h in heroes["heroes"]:
        fid = h.get("faction_id")
        if fid:
            assert fid in faction_ids, f"hero {h['id']} bad faction {fid}"
    for slot in heroes.get("default_squad", []):
        assert slot in hero_ids, f"default_squad missing {slot}"
    for enc in en.get("encounters", []):
        sid = enc["stage_id"]
        assert sid in stage_ids, f"encounter stage missing {sid}"
        for sl in enc.get("slots", []):
            eid = sl["enemy_id"]
            assert eid in all_foes, f"encounter {sid} unknown enemy {eid}"
    for e in en.get("enemies", []):
        assert e.get("rig_id") in rig_ids, f"enemy {e['id']} bad rig"
    for b in en.get("bosses", []):
        if b.get("rig_id"):
            assert b["rig_id"] in rig_ids, f"boss {b['id']} bad rig"
    assert len(heroes["heroes"]) >= 45, "need 45 heroes"
    assert len([s for s in camp["stages"] if str(s["id"]).startswith("CH01")]) == 30, "need 30 CH01 stages"
    print("Cross-ID checks OK (Razlom spine)")
print(f"PASS {ver}")
PY
echo "PASS $VER"
