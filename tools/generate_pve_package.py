#!/usr/bin/env python3
"""Build content package 0.4.0: PvE modes after economy E0–E4.

Order rationale: tower/hunt/gates/dungeons need currency IDs, boss IDs (B*),
enemy IDs (E*), faction IDs (F*), and campaign unlock stages — all already in 0.3.0.
Does not wait for CH02–06 stage data (C4): unlock gates simply stay locked.
"""
from __future__ import annotations

import hashlib
import json
import math
import shutil
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "content/packages/0.3.0"
OUT = ROOT / "content/packages/0.4.0"

MODS = ["hardened", "swift", "volatile", "warded"]
REF_LEVEL = {1: 20, 2: 35, 3: 50, 4: 65, 5: 80, 6: 95}


def parse_rewards(s: str) -> list[dict]:
    out = []
    for part in s.split(","):
        part = part.strip()
        if not part or ":" not in part:
            continue
        rid, amt = part.split(":", 1)
        if rid == "cosmetic_frame":
            out.append({"resource_id": "cosmetic_frame", "amount": 1, "item_id": amt})
        else:
            out.append({"resource_id": rid, "amount": int(amt)})
    return out


def first_clear_rewards(floor: int) -> list[dict]:
    rewards = [
        {"resource_id": "gold", "amount": 3000 + 250 * floor},
        {"resource_id": "hero_xp", "amount": 1200 + 100 * floor},
    ]
    if floor % 5 == 0:
        rewards.append({"resource_id": "skill_book", "amount": 1 + floor // 30})
    if floor % 10 == 0:
        rewards.append({"resource_id": "diamonds", "amount": 100 + 10 * floor})
        rewards.append({"resource_id": "summon_scroll", "amount": 2})
    if floor % 20 == 0:
        rewards.append({"resource_id": "faction_scroll", "amount": 2})
        rewards.append({"resource_id": "boss_core", "amount": math.ceil(floor / 40)})
    if floor == 120:
        rewards.append({"resource_id": "cosmetic_frame", "amount": 1, "item_id": "tower_120"})
    return rewards


def build_tower(enemies_by_ch: dict, bosses_by_ch: dict) -> dict:
    floors = []
    for floor in range(1, 121):
        chapter = math.ceil(floor / 20)
        chapter_floor = ((floor - 1) % 20) + 1
        mod = MODS[(chapter_floor - 1) // 5]
        if chapter_floor in (10, 20):
            kind = "boss"
            # boss #1 on xx10, boss #3 on xx20 per spec
            idx = 0 if chapter_floor == 10 else 2
            boss_list = bosses_by_ch.get(chapter, [])
            boss_id = boss_list[idx]["id"] if len(boss_list) > idx else boss_list[0]["id"]
            squad = [{"enemy_id": boss_id, "tier": "boss"}]
            # pad with chapter enemies
            for e in enemies_by_ch.get(chapter, [])[:4]:
                squad.append({"enemy_id": e["id"], "tier": "normal"})
        elif chapter_floor in (5, 15):
            kind = "elite"
            squad = [{"enemy_id": e["id"], "tier": "elite"} for e in enemies_by_ch.get(chapter, [])[:5]]
        else:
            kind = "normal"
            squad = [{"enemy_id": e["id"], "tier": "normal"} for e in enemies_by_ch.get(chapter, [])[:5]]
        while len(squad) < 5 and squad:
            squad.append(dict(squad[-1]))
        floors.append({
            "id": f"TWR-{floor:03d}",
            "floor": floor,
            "chapter": chapter,
            "kind": kind,
            "modifier": mod,
            "power_multiplier": round(0.90 + 0.035 * (floor - 1), 4),
            "reference_hero_level": REF_LEVEL[chapter],
            "enemy_squad": squad[:5],
            "first_clear_rewards": first_clear_rewards(floor),
            "reward_policy": "first_clear_only",
        })
    return {
        "id": "tower",
        "name": "Башня Времени",
        "unlock_stage": "CH01-15",
        "floor_count": 120,
        "battle_duration_sec": 90,
        "attempt_limit": None,
        "stars": ["win", "no_deaths", "under_60s"],
        "floors": floors,
    }


def build_hunt(bosses_by_ch: dict) -> dict:
    # Pick boss 01 from each chapter for schedule slots
    pick = {ch: bosses_by_ch[ch][0]["id"] for ch in range(1, 7) if bosses_by_ch.get(ch)}
    # Mon/Thu = 1,4; Tue/Fri = 2,5; Wed/Sat = 3,6; Sun = 2,4,6 — need exactly 3 per day
    schedule = {
        "mon": [pick[1], pick[4], pick[2]],
        "tue": [pick[2], pick[5], pick[3]],
        "wed": [pick[3], pick[6], pick[1]],
        "thu": [pick[1], pick[4], pick[5]],
        "fri": [pick[2], pick[5], pick[6]],
        "sat": [pick[3], pick[6], pick[4]],
        "sun": [pick[2], pick[4], pick[6]],
    }
    return {
        "id": "anomaly_hunt",
        "name": "Охота на Аномалии",
        "unlock_stage": "CH02-10",
        "daily_completed_attempts": 3,
        "battle_duration_sec": 90,
        "infinite_hp": True,
        "thresholds_bp": [2500, 6000, 10000],
        "threshold_rewards": [
            [{"resource_id": "boss_core", "amount": 1}, {"resource_id": "essence", "amount": 150}],
            [{"resource_id": "boss_core", "amount": 1}, {"resource_id": "essence", "amount": 200}],
            [{"resource_id": "set_pattern", "amount": 1}, {"resource_id": "essence", "amount": 250}],
        ],
        "consolation": [{"resource_id": "essence", "amount": 100}],
        "first_success_day": [{"resource_id": "skill_book", "amount": 1}],
        "schedule": schedule,
        "note": "damage_score считает только сервер; клиент DEMO показывает пороги.",
    }


def build_gates() -> dict:
    difficulties = [
        {"id": "novice", "unlock_stage": "CH02-20", "recommended_level": 35,
         "rewards_repeat": [{"resource_id": "gold", "amount": 4000}, {"resource_id": "essence", "amount": 100},
                            {"resource_id": "class_seal", "amount": 1}, {"resource_id": "faction_token", "amount": 3}]},
        {"id": "veteran", "unlock_stage": "CH04-10", "recommended_level": 60,
         "rewards_repeat": [{"resource_id": "gold", "amount": 9000}, {"resource_id": "essence", "amount": 250},
                            {"resource_id": "class_seal", "amount": 2}, {"resource_id": "faction_token", "amount": 6}]},
        {"id": "master", "unlock_stage": "CH05-20", "recommended_level": 80,
         "rewards_repeat": [{"resource_id": "gold", "amount": 18000}, {"resource_id": "essence", "amount": 450},
                            {"resource_id": "class_seal", "amount": 3}, {"resource_id": "faction_scroll", "amount": 1},
                            {"resource_id": "faction_token", "amount": 10}]},
    ]
    factions = []
    for fid in ["F01", "F02", "F03", "F04", "F05", "F06"]:
        min_count = 2 if fid in ("F05", "F06") else 3
        factions.append({
            "faction_id": fid,
            "min_faction_heroes": min_count,
            "party_size": 5,
            "steps": 5,
            "first_clear_step_rewards": [
                {"resource_id": "diamonds", "amount": 50},
                {"resource_id": "skill_book", "amount": 1},
            ],
        })
    return {
        "id": "faction_gates",
        "name": "Фракционные врата",
        "unlock_stage": "CH02-20",
        "daily_rewarded_wins": 3,
        "difficulties": difficulties,
        "factions": factions,
        "token_exchange": [
            {"cost": {"faction_token": 20}, "grant": {"hero_shard_open_same_faction": 5}},
            {"cost": {"faction_token": 60}, "grant": {"faction_scroll": 1}},
        ],
    }


def build_dungeons() -> dict:
    table = {
        "DUN_GOLD": {
            "name": "Казна Уфимского Часа",
            "unlock_stage": "CH01-20",
            "rewards": {
                "easy": [{"resource_id": "gold", "amount": 6000}, {"resource_id": "hero_xp", "amount": 500}],
                "normal": [{"resource_id": "gold", "amount": 16000}, {"resource_id": "hero_xp", "amount": 1200}],
                "hard": [{"resource_id": "gold", "amount": 38000}, {"resource_id": "hero_xp", "amount": 3000}],
            },
        },
        "DUN_XP": {
            "name": "Архив Потерянных Лет",
            "unlock_stage": "CH01-20",
            "rewards": {
                "easy": [{"resource_id": "hero_xp", "amount": 4000}, {"resource_id": "essence", "amount": 120}],
                "normal": [{"resource_id": "hero_xp", "amount": 10000}, {"resource_id": "essence", "amount": 280}],
                "hard": [{"resource_id": "hero_xp", "amount": 24000}, {"resource_id": "essence", "amount": 650}],
            },
        },
        "DUN_FORGE": {
            "name": "Шахты Белорецка",
            "unlock_stage": "CH03-01",
            "rewards": {
                "easy": [{"resource_id": "ore", "amount": 8}, {"resource_id": "gold", "amount": 1500}],
                "normal": [{"resource_id": "ore", "amount": 18}, {"resource_id": "gold", "amount": 4000}],
                "hard": [{"resource_id": "ore", "amount": 35}, {"resource_id": "gold", "amount": 9000}],
            },
        },
        "DUN_SKILL": {
            "name": "Печати Мастерства",
            "unlock_stage": "CH02-01",
            "rewards": {
                "easy": [{"resource_id": "skill_book", "amount": 1}, {"resource_id": "gold", "amount": 1000}],
                "normal": [{"resource_id": "skill_book", "amount": 2}, {"resource_id": "gold", "amount": 3000}],
                "hard": [{"resource_id": "skill_book", "amount": 4}, {"resource_id": "reforge_stone", "amount": 1}],
            },
        },
    }
    diffs = [
        {"id": "easy", "label": "I", "recommended_level": 20, "unlock_stage": "CH01-20"},
        {"id": "normal", "label": "II", "recommended_level": 45, "unlock_stage": "CH03-10"},
        {"id": "hard", "label": "III", "recommended_level": 75, "unlock_stage": "CH05-10"},
    ]
    dungeons = []
    for did, meta in table.items():
        dungeons.append({
            "id": did,
            "name": meta["name"],
            "unlock_stage": meta["unlock_stage"],
            "difficulties": diffs,
            "rewards_by_difficulty": meta["rewards"],
            "quick_clear_requires_stars": 3,
        })
    return {
        "id": "rift_dungeons",
        "name": "Подземелья Разлома",
        "unlock_stage": "CH01-20",
        "daily_rewarded_entries": 6,
        "dungeons": dungeons,
    }


def build_battle_modes() -> dict:
    return {
        "portals": [
            {"id": "campaign", "name": "Кампания", "route": "MAP-01", "x": 200, "y": 140, "color": "#E8C56A", "size": {"w": 280, "h": 140}},
            {"id": "tower", "name": "Башня Времени", "route": "PVE-01", "payload": {"mode": "tower"}, "x": 620, "y": 140, "color": "#C4454A", "size": {"w": 280, "h": 140}, "unlock_stage": "CH01-15"},
            {"id": "anomaly_hunt", "name": "Охота на Аномалии", "route": "PVE-01", "payload": {"mode": "anomaly_hunt"}, "x": 180, "y": 420, "color": "#E05A5A", "size": {"w": 280, "h": 140}, "unlock_stage": "CH02-10"},
            {"id": "faction_gates", "name": "Фракционные врата", "route": "PVE-01", "payload": {"mode": "faction_gates"}, "x": 640, "y": 420, "color": "#B06AE8", "size": {"w": 280, "h": 140}, "unlock_stage": "CH02-20"},
            {"id": "rift_dungeons", "name": "Подземелья Разлома", "route": "PVE-01", "payload": {"mode": "rift_dungeons"}, "x": 200, "y": 700, "color": "#5A7AD8", "size": {"w": 280, "h": 140}, "unlock_stage": "CH01-20"},
            {"id": "expedition", "name": "Экспедиции", "route": "HUB-02", "payload": {"mode": "expedition"}, "x": 620, "y": 700, "color": "#3DBE7A", "size": {"w": 280, "h": 140}, "unlock_stage": "CH01-10", "note": "liveops expeditions"},
            {"id": "pvp", "name": "PvP-арена", "route": "PVP-01", "x": 400, "y": 980, "color": "#E09A3E", "size": {"w": 280, "h": 140}},
        ],
        "world": {"width": 1080, "height": 1280},
    }


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    shutil.copytree(SRC, OUT)

    enemies_pack = json.loads((OUT / "enemies.json").read_text(encoding="utf-8"))
    enemies_by_ch: dict[int, list] = {}
    bosses_by_ch: dict[int, list] = {}
    for e in enemies_pack["enemies"]:
        enemies_by_ch.setdefault(int(e["chapter"]), []).append(e)
    for b in enemies_pack["bosses"]:
        bosses_by_ch.setdefault(int(b["chapter"]), []).append(b)
    for ch in bosses_by_ch:
        bosses_by_ch[ch] = sorted(bosses_by_ch[ch], key=lambda x: x["id"])

    pve = {
        "schema_version": 1,
        "mode": "DEMO_SANDBOX",
        "disclaimer": "Локальный DEMO. Попытки/награды/урон авторитетны только на сервере.",
        "reset": {"timezone": "Europe/Moscow", "hour": 6},
        "battle_rules": {"party_size": 5, "combat_engine": "shared_5v5", "duration_sec": 90},
        "modes": [
            {"id": "tower", "unlock_stage": "CH01-15", "floor_count": 120, "reward_policy": "first_clear_only", "battle_scene": "shared_5v5"},
            {"id": "anomaly_hunt", "unlock_stage": "CH02-10", "daily_completed_attempts": 3, "battle_duration_sec": 90},
            {"id": "faction_gates", "unlock_stage": "CH02-20", "daily_rewarded_wins": 3, "factions": ["F01", "F02", "F03", "F04", "F05", "F06"]},
            {"id": "rift_dungeons", "unlock_stage": "CH01-20", "daily_rewarded_entries": 6,
             "dungeons": ["DUN_GOLD", "DUN_XP", "DUN_FORGE", "DUN_SKILL"]},
        ],
        "tower": build_tower(enemies_by_ch, bosses_by_ch),
        "anomaly_hunt": build_hunt(bosses_by_ch),
        "faction_gates": build_gates(),
        "rift_dungeons": build_dungeons(),
    }
    (OUT / "pve_modes.json").write_text(json.dumps(pve, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (OUT / "battle_modes.json").write_text(json.dumps(build_battle_modes(), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    strings = json.loads((OUT / "strings.json").read_text(encoding="utf-8"))
    strings["entries"]["pve.title"] = "Испытания"
    strings["entries"]["pve.tower"] = "Башня Времени"
    strings["entries"]["pve.hunt"] = "Охота на Аномалии"
    strings["entries"]["pve.gates"] = "Фракционные врата"
    strings["entries"]["pve.dungeons"] = "Подземелья Разлома"
    (OUT / "strings.json").write_text(json.dumps(strings, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    files = sorted(f.name for f in OUT.glob("*.json") if f.name != "manifest.json")
    files = ["manifest.json"] + [f for f in files if f != "manifest.json"]
    # rebuild file list without double manifest
    file_list = [f.name for f in sorted(OUT.glob("*.json")) if f.name != "manifest.json"]
    hashes = {f: hashlib.sha256((OUT / f).read_bytes()).hexdigest() for f in file_list}
    hashes["manifest.json"] = ""  # filled after write
    manifest = {
        "id": "lunex-core",
        "version": "0.4.0",
        "schema": 5,
        "client_min": "0.1.0",
        "title": "Razlom Epoh · PvE modes (tower/hunt/gates/dungeons)",
        "locale": "ru",
        "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "updated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "notes": "P0–P2: pve_modes после E0–E4. Не серверные попытки.",
        "files": {f: {"role": f.replace(".json", "")} for f in file_list + ["manifest.json"]},
        "integrity": {"algo": "sha256", "hashes": {}},
    }
    # write manifest without hashes first then hash all including self? Keep hashes of content files only
    manifest["integrity"]["hashes"] = hashes
    del manifest["integrity"]["hashes"]["manifest.json"]
    (OUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    # include manifest hash
    manifest["integrity"]["hashes"]["manifest.json"] = hashlib.sha256((OUT / "manifest.json").read_bytes()).hexdigest()
    # Don't rewrite to avoid hash churn of self — leave without self-hash like prior packages

    active = {
        "version": "0.4.0",
        "source": "content-c-pve",
        "note": "Клиент читает только опубликованный пакет. Прогресс игрока сюда не пишется.",
        "published_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    (ROOT / "content/packages/active.json").write_text(json.dumps(active, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT}")
    print(f" tower floors={len(pve['tower']['floors'])} hunt days={len(pve['anomaly_hunt']['schedule'])} "
          f"gates={len(pve['faction_gates']['factions'])} dungeons={len(pve['rift_dungeons']['dungeons'])}")


if __name__ == "__main__":
    main()
