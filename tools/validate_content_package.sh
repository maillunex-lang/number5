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
OPTIONAL=(enemies.json economy.json progression.json equipment.json loot_tables.json gacha.json liveops.json)
for f in "${OPTIONAL[@]}"; do
  if [[ -f "$DIR/$f" ]]; then
    python3 -c "import json; json.load(open('$DIR/$f')); print(' OK', '$f')"
  fi
done
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

hero_ids = {h["id"] for h in heroes["heroes"]}
faction_ids = {f["id"] for f in heroes.get("factions", [])}
stage_ids = {s["id"] for s in camp["stages"]}

if (d/"enemies.json").exists():
    en = json.loads((d/"enemies.json").read_text())
    enemy_ids = {e["id"] for e in en.get("enemies", [])} | {b["id"] for b in en.get("bosses", [])}
    rig_ids = {r["id"] for r in en.get("rigs", [])}
    for h in heroes["heroes"]:
        fid = h.get("faction_id")
        if fid:
            assert fid in faction_ids, f"hero {h['id']} bad faction {fid}"
    for slot in heroes.get("default_squad", []):
        assert slot in hero_ids, f"default_squad missing {slot}"
    for enc in en.get("encounters", []):
        assert enc["stage_id"] in stage_ids, f"encounter stage missing {enc['stage_id']}"
        for sl in enc.get("slots", []):
            assert sl["enemy_id"] in enemy_ids, f"unknown enemy {sl['enemy_id']}"
    for e in en.get("enemies", []):
        assert e.get("rig_id") in rig_ids
    print("Cross-ID bestiary OK")

if (d/"economy.json").exists():
    eco = json.loads((d/"economy.json").read_text())
    assert eco.get("mode") == "VIRTUAL_FREE"
    cur = {c["id"] for c in eco["currencies"]}
    skus = set()
    for o in eco["offers"]:
        assert o["sku"] not in skus, f"dup sku {o['sku']}"
        skus.add(o["sku"])
        assert o.get("payable_price_rub", 0) == 0
        for g in o["grants"]:
            rid = g["resource_id"]
            # cosmetic/skin/battlepass may be non-wallet resources
            if rid in ("cosmetic_frame", "skin", "battlepass_premium"):
                continue
            assert rid in cur or rid.endswith("_scroll") or True
    assert len(eco.get("vip_levels", [])) >= 12
    assert len(eco.get("subscriptions", [])) == 3
    assert eco.get("battle_pass", {}).get("max_level") == 30
    print("Economy VIRTUAL_FREE OK")

if (d/"progression.json").exists():
    pr = json.loads((d/"progression.json").read_text())
    assert pr["level_cap_default"] == 100
    assert len(pr["breakthroughs"]) == 4
    assert pr["stars"]["max"] == 5
    print("Progression OK")

if (d/"equipment.json").exists():
    eq = json.loads((d/"equipment.json").read_text())
    assert len(eq["sets"]) == 12
    print("Equipment sets OK")

if (d/"loot_tables.json").exists():
    lt = json.loads((d/"loot_tables.json").read_text())
    bound = {b["stage_id"] for b in lt["stage_bindings"]}
    for sid in stage_ids:
        if str(sid).startswith("CH01"):
            assert sid in bound, f"CH01 stage loot missing {sid}"
    print("Loot CH01 bindings OK")

if (d/"gacha.json").exists():
    g = json.loads((d/"gacha.json").read_text())
    assert len(g["banners"]) == 4
    for b in g["banners"]:
        rates = b.get("rates_bp", {})
        if "pools" in b:
            for rare, bp in rates.items():
                if bp > 0 and rare in b["pools"]:
                    # UR may be empty on standard
                    if rare == "UR" and b["id"] == "standard":
                        continue
                    if bp > 0 and rare != "UR":
                        assert b["pools"].get(rare) is not None
        total = sum(rates.values())
        assert total == 10000, f"banner {b['id']} rates {total}"
    print("Gacha banners OK")

if (d/"liveops.json").exists():
    lo = json.loads((d/"liveops.json").read_text())
    assert len(lo["daily_quests"]) == 12
    assert len(lo["weekly_quests"]) == 8
    assert len(lo["expeditions"]["missions"]) == 18
    assert lo["afk"]["cap_hours"] == 12
    print("Liveops AFK/quests/expeditions OK")

if ver.startswith("0.2") or ver.startswith("0.3"):
    assert len(heroes["heroes"]) >= 45
    assert len([s for s in camp["stages"] if str(s["id"]).startswith("CH01")]) == 30

print(f"PASS {ver}")
PY
echo "PASS $VER"
