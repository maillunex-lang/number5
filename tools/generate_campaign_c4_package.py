#!/usr/bin/env python3
"""Build content package 0.7.0: C4 campaign CH01–CH06 (180 stages).

Copies 0.6.0, expands campaign/enemies encounters/loot bindings from canon docs.
Does not invent new heroes/enemies — uses existing F/H/E/B spine.
"""
from __future__ import annotations

import hashlib
import json
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs/content"
SRC = ROOT / "content/packages/0.6.0"
OUT = ROOT / "content/packages/0.7.0"

CHAPTERS_META = [
    {"id": "CH01", "name": "Уфа: Справка о конце света", "region": "Уфа", "unlocked": True},
    {"id": "CH02", "name": "Каменные свидетели", "region": "Шиханы", "unlocked": False},
    {"id": "CH03", "name": "Железное сердце Белорецка", "region": "Белорецк", "unlocked": False},
    {"id": "CH04", "name": "Стерлитамак 2050", "region": "Стерлитамак", "unlocked": False},
    {"id": "CH05", "name": "Тени Иремеля", "region": "Иремель", "unlocked": False},
    {"id": "CH06", "name": "Хозяева времени", "region": "Сердце Разлома", "unlocked": False},
]

CHAPTER_SETS = {
    1: ["SET01", "SET02"],
    2: ["SET03", "SET04"],
    3: ["SET05", "SET06"],
    4: ["SET07", "SET08"],
    5: ["SET09", "SET10"],
    6: ["SET11", "SET12"],
}

SIDE_NAMES = {
    1: ("Спасение экспедиции", "Архивное свидетельство", "Потерянный трамвай №0"),
    2: ("Спасение экспедиции", "Архивное свидетельство", "Камень, помнящий завтра"),
    3: ("Спасение экспедиции", "Архивное свидетельство", "Кузница последней искры"),
    4: ("Спасение экспедиции", "Архивное свидетельство", "Билет в вчера"),
    5: ("Спасение экспедиции", "Архивное свидетельство", "Тропа двойной тени"),
    6: ("Спасение экспедиции", "Архивное свидетельство", "Секунда до нуля"),
}


def parse_all_stages(story: str) -> list[dict]:
    stages: list[dict] = []
    for ch in range(1, 7):
        ch_id = f"CH{ch:02d}"
        # slice between ### Глава N. and next chapter or end
        pat = rf"### Глава {ch}\.(.*?)(?=### Глава {ch + 1}\.|\Z)"
        m = re.search(pat, story, re.S)
        if not m:
            raise SystemExit(f"missing chapter block {ch}")
        block = m.group(1)
        for line in block.splitlines():
            rm = re.match(
                rf"\|\s*`?({ch_id}-\d+)`?\s*\|\s*([^/]+)/\s*(\d+)\s*\|\s*`?(\w+)`?\s*\|\s*([^|]+)\|\s*([^|]+)\|",
                line,
            )
            if not rm:
                continue
            sid, zone, num, typ, enemies, plot = [x.strip().strip("`") for x in rm.groups()]
            n = int(num)
            col = (n - 1) % 5
            row = (n - 1) // 5
            power = 8000 + (ch - 1) * 12000 + (n - 1) * (450 + ch * 40)
            state = "locked"
            if ch == 1:
                if n < 3:
                    state = "cleared"
                elif n == 3:
                    state = "available"
            stages.append({
                "id": sid,
                "name": f"{zone.strip()} · {num}",
                "zone": zone.strip(),
                "power": power,
                "type": "main" if typ == "normal" else typ,
                "stage_type": typ,
                "state": state,
                "rewards": ["Золото", "Опыт"] if typ in ("normal", "story") else ["Золото", "Осколок"],
                "x": 160 + col * 180,
                "y": 140 + row * 220,
                "enemy_composition": enemies,
                "plot": plot,
                "chapter_id": ch_id,
                "chapter": ch,
            })
    assert len(stages) == 180, len(stages)
    return stages


def parse_all_encounters(bestiary: str) -> dict[str, str]:
    enc: dict[str, str] = {}
    for ch in range(1, 7):
        ch_id = f"CH{ch:02d}"
        pat = rf"### Глава {ch}: этапы и составы(.*?)(?=### Глава {ch + 1}:|\Z)"
        m = re.search(pat, bestiary, re.S)
        if not m:
            raise SystemExit(f"missing encounter section {ch}")
        for line in m.group(1).splitlines():
            rm = re.match(rf"\|\s*`?({ch_id}-\d+)`?\s*\|\s*([^|]+)\|", line)
            if not rm:
                continue
            enc[rm.group(1)] = rm.group(2).strip()
    assert len(enc) == 180, len(enc)
    return enc


def enemy_slots_from_composition(comp: str, enemies_by_name: dict[str, str], bosses_by_name: dict[str, str], level: int) -> list[dict]:
    slots: list[dict] = []
    if "+" in comp:
        left, right = [x.strip() for x in comp.split("+", 1)]
        for name, eid in bosses_by_name.items():
            if name in left:
                slots.append({"enemy_id": eid, "level": level + 5, "tier": "boss"})
                break
        else:
            for name, eid in enemies_by_name.items():
                if name in left:
                    slots.append({"enemy_id": eid, "level": level + 2, "tier": "elite"})
                    break
        rm = re.search(r"(\d+)\s*×\s*(.+)$", right)
        if rm:
            count = int(rm.group(1))
            eid = enemies_by_name.get(rm.group(2).strip())
            if eid:
                for _ in range(count):
                    slots.append({"enemy_id": eid, "level": level, "tier": "normal"})
    else:
        for part in [p.strip() for p in comp.split(",")]:
            rm = re.search(r"(\d+)\s*×\s*(.+)$", part)
            if not rm:
                continue
            count = int(rm.group(1))
            eid = enemies_by_name.get(rm.group(2).strip())
            if not eid:
                continue
            for _ in range(count):
                slots.append({"enemy_id": eid, "level": level, "tier": "normal"})
    while len(slots) < 5 and slots:
        slots.append(dict(slots[-1]))
    return slots[:5]


def build_loot_bindings(stages: list[dict]) -> list[dict]:
    out = []
    for s in stages:
        ch = int(s["chapter"])
        n = int(s["id"].split("-")[1])
        typ = str(s.get("stage_type", "normal"))
        if typ in ("boss", "final_boss"):
            kind = "boss"
            table = f"loot_ch{ch:02d}_boss"
        elif typ == "elite":
            kind = "elite"
            table = f"loot_ch{ch:02d}_elite"
        elif typ == "story":
            kind = "normal"
            table = f"loot_ch{ch:02d}_normal"
        else:
            kind = "normal"
            table = f"loot_ch{ch:02d}_normal"
        gold = 2000 + ch * 400 + n * 80
        xp = 800 + ch * 150 + n * 20
        if kind == "boss":
            gold = int(gold * 2.2)
            xp = int(xp * 2.0)
        elif kind == "elite":
            gold = int(gold * 1.4)
            xp = int(xp * 1.3)
        out.append({
            "stage_id": s["id"],
            "loot_table_id": table,
            "equipment_tier": min(6, ch),
            "featured_sets": CHAPTER_SETS[ch],
            "stage_kind": kind,
            "first_clear": {"gold": gold, "hero_xp": xp},
        })
    return out


def ensure_loot_tables(loot: dict, chapters: range) -> None:
    """Add per-chapter loot table ids if missing (clone from ch01 templates)."""
    # quality already global; stage bindings reference loot_chXX_* — keep as ids only
    # optional named tables map
    tables = loot.setdefault("tables", {})
    for ch in chapters:
        for kind in ("normal", "elite", "boss"):
            tid = f"loot_ch{ch:02d}_{kind}"
            if tid not in tables:
                tables[tid] = {
                    "id": tid,
                    "quality_key": kind if kind != "final_boss" else "boss",
                    "chapter": ch,
                }


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    shutil.copytree(SRC, OUT)

    story = (DOCS / "STORY_6_CHAPTERS.md").read_text(encoding="utf-8")
    bestiary = (DOCS / "BESTIARY_6_CHAPTERS.md").read_text(encoding="utf-8")

    stages = parse_all_stages(story)
    encounters_text = parse_all_encounters(bestiary)

    enemies_pack = json.loads((OUT / "enemies.json").read_text(encoding="utf-8"))
    enemies_by_name = {e["name"]: e["id"] for e in enemies_pack["enemies"]}
    bosses_by_name = {b["name"]: b["id"] for b in enemies_pack["bosses"]}

    enc_list = []
    for sid, comp in sorted(encounters_text.items()):
        ch = int(sid[2:4])
        level = 4 + ch * 3
        slots = enemy_slots_from_composition(comp, enemies_by_name, bosses_by_name, level)
        if not slots:
            e0 = next((e for e in enemies_pack["enemies"] if e.get("chapter") == ch), None)
            if e0 is None:
                e0 = enemies_pack["enemies"][0]
            slots = [{"enemy_id": e0["id"], "level": level, "tier": "normal"} for _ in range(5)]
        enc_list.append({"stage_id": sid, "slots": slots})
        # attach text onto stage
    for s in stages:
        if s["id"] in encounters_text:
            s["encounter_text"] = encounters_text[s["id"]]

    enemies_pack["encounters"] = enc_list
    (OUT / "enemies.json").write_text(json.dumps(enemies_pack, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # campaign
    edges = []
    for ch in range(1, 7):
        ch_stages = [s for s in stages if s["chapter"] == ch]
        for i in range(len(ch_stages) - 1):
            edges.append([ch_stages[i]["id"], ch_stages[i + 1]["id"]])
        if ch < 6:
            edges.append([f"CH{ch:02d}-30", f"CH{ch + 1:02d}-01"])

    regions = []
    for i, ch in enumerate(CHAPTERS_META):
        regions.append({
            "id": ch["id"],
            "name": ch["region"],
            "chapter_name": ch["name"],
            "unlocked": ch["unlocked"],
            "req": "" if ch["unlocked"] else f"Пройти {CHAPTERS_META[i - 1]['id']}-30",
            "x": 180 + (i % 2) * 420,
            "y": 160 + i * 280,
        })

    side_stages = []
    secrets = []
    for ch in range(1, 7):
        s1, s2, x1 = SIDE_NAMES[ch]
        side_stages.append({"id": f"CH{ch:02d}-S01", "name": s1, "after": f"CH{ch:02d}-08", "type": "side", "chapter_id": f"CH{ch:02d}"})
        side_stages.append({"id": f"CH{ch:02d}-S02", "name": s2, "after": f"CH{ch:02d}-21", "type": "side", "chapter_id": f"CH{ch:02d}"})
        secrets.append({"id": f"CH{ch:02d}-X01", "name": x1, "after": f"CH{ch:02d}-15", "type": "secret", "chapter_id": f"CH{ch:02d}"})

    campaign = {
        "schema_version": 3,
        "setting": "bashkortostan_razlom_epoh",
        "world_name": "Башкортостан: Разлом эпох",
        "chapter_id": "CH01",
        "chapter_name": CHAPTERS_META[0]["name"],
        "current_stage": "CH01-03",
        "chapters": CHAPTERS_META,
        "regions": regions,
        "stages": stages,
        "edges": edges,
        "side_stages": side_stages,
        "secrets": secrets,
        "notes": "C4: 180 этапов CH01–CH06. Главы 2–6 locked до прохождения предыдущей *-30.",
    }
    (OUT / "campaign.json").write_text(json.dumps(campaign, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    loot = json.loads((OUT / "loot_tables.json").read_text(encoding="utf-8"))
    ensure_loot_tables(loot, range(1, 7))
    loot["stage_bindings"] = build_loot_bindings(stages)
    loot["chapter_sets"] = {str(k): v for k, v in CHAPTER_SETS.items()}
    (OUT / "loot_tables.json").write_text(json.dumps(loot, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    strings = json.loads((OUT / "strings.json").read_text(encoding="utf-8"))
    strings["entries"].update({
        "map.title": "Карта мира · Разлом эпох",
        "campaign.c4": "Главы 1–6 · 180 этапов",
        "inventory.title": "Инвентарь экипировки",
        "expeditions.title": "Экспедиции",
    })
    for ch in CHAPTERS_META:
        strings["entries"][f"chapter.{ch['id']}.name"] = ch["name"]
    (OUT / "strings.json").write_text(json.dumps(strings, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # hub: expeditions quick entry on side rail
    hub = json.loads((OUT / "hub.json").read_text(encoding="utf-8"))
    rail = hub.get("side_rail", [])
    if not any(str(x.get("id", "")) == "expeditions" for x in rail):
        rail.append({
            "id": "expeditions",
            "label": "Экспедиции",
            "icon": "compass",
            "route": "EXPEDITIONS",
            "badge": "",
        })
        hub["side_rail"] = rail
    (OUT / "hub.json").write_text(json.dumps(hub, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    file_list = [f.name for f in sorted(OUT.glob("*.json")) if f.name != "manifest.json"]
    hashes = {f: hashlib.sha256((OUT / f).read_bytes()).hexdigest() for f in file_list}
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    manifest = {
        "id": "lunex-core",
        "version": "0.7.0",
        "schema": 8,
        "client_min": "0.1.0",
        "title": "Razlom Epoh · C4 campaign CH01–CH06 (180 stages)",
        "locale": "ru",
        "created_at": now,
        "updated_at": now,
        "notes": "C4 after meta 0.6.0. Full campaign data; chapters 2–6 locked until prior clear.",
        "files": {f: {"role": f.replace(".json", "")} for f in file_list},
        "integrity": {"algo": "sha256", "hashes": hashes},
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print("Note: active.json не изменён (пересборка исторического 0.7.0; active пишет generate_skills_dialogs_package.py).")
    print(f"Wrote {OUT}")
    print(f" stages={len(stages)} encounters={len(enc_list)} loot={len(loot['stage_bindings'])}")


if __name__ == "__main__":
    main()
