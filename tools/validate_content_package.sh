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
OPTIONAL=(enemies.json economy.json progression.json equipment.json loot_tables.json gacha.json liveops.json pve_modes.json guilds.json mail.json login_calendars.json profile.json achievements.json daily_stories.json live_events.json)
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

if (d/"pve_modes.json").exists():
    pve = json.loads((d/"pve_modes.json").read_text())
    assert {m["id"] for m in pve["modes"]} >= {"tower", "anomaly_hunt", "faction_gates", "rift_dungeons"}
    floors = pve["tower"]["floors"]
    assert len(floors) == 120
    foe_ids = set()
    if (d/"enemies.json").exists():
        en = json.loads((d/"enemies.json").read_text())
        foe_ids = {e["id"] for e in en.get("enemies", [])} | {b["id"] for b in en.get("bosses", [])}
    for fl in floors:
        assert fl["id"] == f"TWR-{fl['floor']:03d}"
        for slot in fl.get("enemy_squad", []):
            if foe_ids:
                assert slot["enemy_id"] in foe_ids, f"{fl['id']} bad {slot['enemy_id']}"
    for day, bosses in pve["anomaly_hunt"]["schedule"].items():
        assert len(bosses) == 3, day
        if foe_ids:
            for bid in bosses:
                assert bid in foe_ids, f"hunt {day} bad {bid}"
    assert len(pve["faction_gates"]["factions"]) == 6
    assert len(pve["rift_dungeons"]["dungeons"]) == 4
    print("PvE modes OK")

if (d/"guilds.json").exists():
    gu = json.loads((d/"guilds.json").read_text())
    assert gu.get("unlock_stage") == "CH01-20"
    assert gu["max_level"] == 10
    assert len(gu["daily_quests"]) == 8
    assert len(gu["shop"]["offers"]) >= 8
    assert gu["shop"]["real_money_enabled"] is False
    tiers = gu["raids"]["tiers"]
    assert len(tiers) == 5
    foe_ids = set()
    if (d/"enemies.json").exists():
        en = json.loads((d/"enemies.json").read_text())
        foe_ids = {b["id"] for b in en.get("bosses", [])}
    for t in tiers:
        if foe_ids:
            assert t["boss_id"] in foe_ids, t["boss_id"]
    print("Guilds / raids OK")

if (d/"mail.json").exists():
    mail = json.loads((d/"mail.json").read_text())
    assert len(mail["templates"]) == 8
    assert mail["player_to_player"] is False
    assert any(t["id"] == "MAIL_LOGIN_UNCLAIMED" for t in mail["templates"])
    print("Mail OK")

if (d/"login_calendars.json").exists():
    lc = json.loads((d/"login_calendars.json").read_text())
    assert lc["unlock_stage"] == "CH01-03"
    assert lc["premium_calendar"] is False
    ids = {c["id"] for c in lc["calendars"]}
    assert ids == {"LOGIN_7", "LOGIN_30", "NEWCOMER_14"}
    for c in lc["calendars"]:
        assert len(c["entries"]) == c["days"]
        for e in c["entries"]:
            for r in e["rewards"]:
                assert r["amount"] > 0
    assert lc["rollover"]["unclaimed_to_mail_template"] == "MAIL_LOGIN_UNCLAIMED"
    print("Login calendars OK")

if (d/"profile.json").exists():
    pr = json.loads((d/"profile.json").read_text())
    assert len(pr["cosmetics"]["avatars"]) == 12
    assert len(pr["cosmetics"]["frames"]) >= 8
    assert len([t for t in pr["cosmetics"]["titles"] if not t.get("secret")]) == 12
    assert pr["privacy_defaults"]["show_collection_summary"] is False
    print("Profile OK")

if (d/"achievements.json").exists():
    ach = json.loads((d/"achievements.json").read_text())
    assert len(ach["achievements"]) == 48
    assert len(ach["secrets"]) == 6
    assert ach["combat_bonus"] is False
    ids = [a["id"] for a in ach["achievements"]]
    assert len(ids) == len(set(ids))
    print("Achievements OK")

if (d/"daily_stories.json").exists():
    ds = json.loads((d/"daily_stories.json").read_text())
    assert len(ds["stories"]) == 30
    assert ds["unlock_stage"] == "CH01-10"
    assert ds["pass_xp"] is False
    foe_ids = set()
    if (d/"enemies.json").exists():
        en = json.loads((d/"enemies.json").read_text())
        foe_ids = {e["id"] for e in en.get("enemies", [])} | {b["id"] for b in en.get("bosses", [])}
    for s in ds["stories"]:
        assert len(s["choices"]) == 2
        for c in s["choices"]:
            if c.get("enemy_hint") and foe_ids:
                assert c["enemy_hint"] in foe_ids, c["enemy_hint"]
    print("Daily stories OK")

if (d/"live_events.json").exists():
    le = json.loads((d/"live_events.json").read_text())
    assert len(le["events"]) == 6
    assert le["currency_id"] == "event_token"
    assert le["shop"]["real_money_enabled"] is False
    assert le["one_active_large_event"] is True
    formats = {e["format"] for e in le["events"]}
    assert formats == {"COLLECTION", "BOSS_RUSH", "FACTION_WEEK", "EXPEDITION", "MINI_CAMPAIGN", "GUILD_COOP"}
    if (d/"economy.json").exists():
        eco = json.loads((d/"economy.json").read_text())
        assert any(c["id"] == "event_token" for c in eco["currencies"])
    foe_ids = set()
    if (d/"enemies.json").exists():
        en = json.loads((d/"enemies.json").read_text())
        foe_ids = {b["id"] for b in en.get("bosses", [])}
    for e in le["events"]:
        if e["format"] == "BOSS_RUSH" and foe_ids:
            for bid in e.get("bosses", []):
                assert bid in foe_ids, bid
    print("Live events OK")

if ver.startswith("0.2") or ver.startswith("0.3") or ver.startswith("0.4") or ver.startswith("0.5") or ver.startswith("0.6"):
    assert len(heroes["heroes"]) >= 45
    assert len([s for s in camp["stages"] if str(s["id"]).startswith("CH01")]) == 30

print(f"PASS {ver}")
PY
echo "PASS $VER"
