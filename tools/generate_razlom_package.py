#!/usr/bin/env python3
"""Generate content package 0.2.0 from Razlom Epoh canon docs."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs/content"
OUT = ROOT / "content/packages/0.2.0"
SRC_0_1 = ROOT / "content/packages/0.1.0"

FACTIONS = [
    {"id": "F01", "name": "Стражи Клятвы", "kind": "core", "focus": "defense", "tint": "#5EC8E8", "bonus_stat": "hp"},
    {"id": "F02", "name": "Вольные Тропы", "kind": "core", "focus": "mobility", "tint": "#3DBE7A", "bonus_stat": "atk"},
    {"id": "F03", "name": "Архив Предела", "kind": "core", "focus": "control", "tint": "#A889E8", "bonus_stat": "energy"},
    {"id": "F04", "name": "Каменные Кузни", "kind": "core", "focus": "armor", "tint": "#E09A3E", "bonus_stat": "def"},
    {"id": "F05", "name": "Межвременные Тени", "kind": "special", "focus": "assassin", "tint": "#2A9B8F", "bonus_stat": "spd"},
    {"id": "F06", "name": "Расколотые Хранители", "kind": "special", "focus": "heal", "tint": "#FFE29A", "bonus_stat": "heal"},
]

ROLE_CLASS = {
    "Танк": "tank",
    "Воин": "warrior",
    "Убийца": "assassin",
    "Стрелок": "ranger",
    "Маг": "mage",
    "Поддержка": "support",
    "Лекарь": "healer",
}

RARITY_MAP = {"N": "common", "R": "rare", "SR": "epic", "SSR": "legendary", "UR": "mythic"}

TINT_BY_FACTION = {f["id"]: f["tint"] for f in FACTIONS}

ROLE_DEFAULTS = {
    "tank": {"hp": 2400, "atk": 150, "def": 130, "spd": 50, "energy": 40},
    "warrior": {"hp": 1800, "atk": 190, "def": 90, "spd": 75, "energy": 60},
    "assassin": {"hp": 1500, "atk": 210, "def": 60, "spd": 110, "energy": 40},
    "ranger": {"hp": 1500, "atk": 210, "def": 60, "spd": 100, "energy": 20},
    "mage": {"hp": 1600, "atk": 200, "def": 70, "spd": 85, "energy": 80},
    "support": {"hp": 1700, "atk": 170, "def": 80, "spd": 80, "energy": 100},
    "healer": {"hp": 1750, "atk": 165, "def": 85, "spd": 70, "energy": 40},
}

RIGS = [
    {"id": "RIG-GUARD", "name": "Страж", "role": "defender", "spd": 85},
    {"id": "RIG-STRIKER", "name": "Налётчик", "role": "assassin", "spd": 120},
    {"id": "RIG-CASTER", "name": "Заклинатель", "role": "caster", "spd": 100},
    {"id": "RIG-CONSTRUCT", "name": "Конструкт", "role": "bruiser", "spd": 80},
    {"id": "RIG-BEAST", "name": "Зверь", "role": "beast", "spd": 115},
    {"id": "RIG-WISP", "name": "Фантом", "role": "controller", "spd": 110},
]

CHAPTERS_META = [
    {"id": "CH01", "name": "Уфа: Справка о конце света", "region": "Уфа", "unlocked": True},
    {"id": "CH02", "name": "Каменные свидетели", "region": "Шиханы", "unlocked": False},
    {"id": "CH03", "name": "Железное сердце Белорецка", "region": "Белорецк", "unlocked": False},
    {"id": "CH04", "name": "Стерлитамак 2050", "region": "Стерлитамак", "unlocked": False},
    {"id": "CH05", "name": "Тени Иремеля", "region": "Иремель", "unlocked": False},
    {"id": "CH06", "name": "Хозяева времени", "region": "Сердце Разлома", "unlocked": False},
]


def parse_hero_registry(text: str) -> list[dict]:
    heroes = []
    for line in text.splitlines():
        m = re.match(
            r"\|\s*(H\d+)\s*\|\s*([^|]+)\|\s*(F\d+)\s*\|\s*(\w+)\s*\|\s*([^|]+)\|\s*([^|]+)\|",
            line,
        )
        if not m:
            continue
        hid, name, fid, rarity, klass, era = [x.strip() for x in m.groups()]
        if not hid.startswith("H"):
            continue
        role = ROLE_CLASS.get(klass, "warrior")
        heroes.append(
            {
                "id": hid,
                "name": name,
                "faction_id": fid,
                "faction": next(f["name"] for f in FACTIONS if f["id"] == fid),
                "rarity_code": rarity,
                "rarity": RARITY_MAP.get(rarity, "common"),
                "class": klass,
                "role": role,
                "era": era,
                "tint": TINT_BY_FACTION.get(fid, "#E8C56A"),
            }
        )
    return heroes


def parse_hero_stats(text: str) -> dict[str, dict]:
    stats: dict[str, dict] = {}
    current = None
    for line in text.splitlines():
        hm = re.match(r"###\s+(H\d+)\s+", line)
        if hm:
            current = hm.group(1)
            continue
        if current and "Параметры L1" in line:
            nums = re.findall(
                r"HP \*\*(\d+)\*\*.*?ATK \*\*(\d+)\*\*.*?DEF \*\*(\d+)\*\*.*?SPD \*\*(\d+)\*\*.*?энергия \*\*(\d+)",
                line,
            )
            if nums:
                hp, atk, df, spd, energy = map(int, nums[0])
                stats[current] = {"hp": hp, "atk": atk, "def": df, "spd": spd, "energy": energy}
    return stats


def parse_enemies_ch(text: str) -> list[dict]:
    enemies = []
    chapter = None
    for line in text.splitlines():
        cm = re.match(r"### Глава (\d+):", line)
        if cm:
            chapter = int(cm.group(1))
            continue
        m = re.match(
            r"\|\s*`?(E\d+-\d+)`?\s*\|\s*([^|]+)\|\s*`?(RIG-[A-Z]+)`?\s*\|\s*`?(skin_[ab])`?\s*\|\s*([^|]+)\|\s*([^|]+)\|",
            line,
        )
        if not m or chapter is None:
            continue
        eid, name, rig, skin, role, mech = [x.strip().strip("`") for x in m.groups()]
        enemies.append(
            {
                "id": eid,
                "name": name,
                "chapter": chapter,
                "rig_id": rig,
                "skin_id": skin,
                "role": role,
                "modifier_note": mech,
                "kind": "enemy",
            }
        )
    return enemies


def parse_bosses(text: str) -> list[dict]:
    bosses = []
    current_ch = None
    for line in text.splitlines():
        cm = re.match(r"### Глава (\d+):", line)
        if cm:
            current_ch = int(cm.group(1))
            continue
        bm = re.match(r"####\s+`(B\d+-\d+)`\s*·\s*([^·]+)·\s*`(CH\d+-\d+)`", line)
        if bm:
            bid, name, stage = bm.group(1), bm.group(2).strip(), bm.group(3)
            bosses.append(
                {
                    "id": bid,
                    "name": name,
                    "stage_id": stage,
                    "chapter": current_ch,
                    "kind": "boss",
                    "rig_id": None,
                }
            )
    # attach rigs from following bullet if present - default map by chapter cycle
    rig_cycle = ["RIG-GUARD", "RIG-STRIKER", "RIG-CASTER", "RIG-CONSTRUCT", "RIG-BEAST", "RIG-WISP"]
    for i, b in enumerate(bosses):
        b["rig_id"] = rig_cycle[i % len(rig_cycle)]
        b["skin_id"] = "skin_b" if (b.get("chapter") or 1) % 2 == 1 else "skin_a"
    return bosses


def parse_ch01_stages(text: str) -> list[dict]:
    stages = []
    in_ch1 = False
    for line in text.splitlines():
        if line.startswith("### Глава 1."):
            in_ch1 = True
            continue
        if in_ch1 and line.startswith("### Глава 2."):
            break
        m = re.match(
            r"\|\s*`?(CH01-\d+)`?\s*\|\s*([^/]+)/\s*(\d+)\s*\|\s*`?(\w+)`?\s*\|\s*([^|]+)\|\s*([^|]+)\|",
            line,
        )
        if not m:
            continue
        sid, zone, num, typ, enemies, plot = [x.strip().strip("`") for x in m.groups()]
        n = int(num)
        # layout 6 rows x 5 cols
        col = (n - 1) % 5
        row = (n - 1) // 5
        x = 160 + col * 180
        y = 140 + row * 220
        state = "available" if n == 1 else ("cleared" if n < 1 else "locked")
        if n == 1:
            state = "available"
        elif n <= 0:
            state = "locked"
        power = 8000 + (n - 1) * 450
        stages.append(
            {
                "id": sid,
                "name": f"{zone.strip()} · {num}",
                "zone": zone.strip(),
                "power": power,
                "type": typ if typ != "normal" else "main",
                "stage_type": typ,
                "state": "available" if n == 1 else "locked",
                "rewards": ["Золото", "Опыт"] if typ == "normal" else ["Золото", "Осколок"],
                "x": x,
                "y": y,
                "enemy_composition": enemies,
                "plot": plot,
                "chapter_id": "CH01",
            }
        )
    # unlock first three for demo playability
    for s in stages:
        n = int(s["id"].split("-")[1])
        if n <= 3:
            s["state"] = "cleared" if n < 3 else "available"
        if n < 3:
            s["state"] = "cleared"
        if n == 3:
            s["state"] = "available"
    return stages


def parse_ch01_encounters(text: str) -> dict[str, list]:
    """From bestiary section 'Глава 1: этапы и составы'."""
    enc: dict[str, list] = {}
    in_sec = False
    for line in text.splitlines():
        if "### Глава 1: этапы и составы" in line:
            in_sec = True
            continue
        if in_sec and line.startswith("### Глава 2:"):
            break
        m = re.match(r"\|\s*`?(CH01-\d+)`?\s*\|\s*([^|]+)\|", line)
        if not m:
            continue
        sid, comp = m.group(1), m.group(2).strip()
        enc[sid] = comp
    return enc


def enemy_slots_from_composition(comp: str, enemies_by_name: dict[str, str], bosses_by_name: dict[str, str]) -> list[dict]:
    slots = []
    # boss + N × name pattern
    if "+" in comp:
        left, right = [x.strip() for x in comp.split("+", 1)]
        # left may be boss name
        for name, eid in bosses_by_name.items():
            if name in left:
                slots.append({"enemy_id": eid, "level": 10, "tier": "boss"})
                break
        else:
            for name, eid in enemies_by_name.items():
                if name in left:
                    slots.append({"enemy_id": eid, "level": 8, "tier": "elite"})
                    break
        rm = re.search(r"(\d+)\s*×\s*(.+)$", right)
        if rm:
            count = int(rm.group(1))
            ename = rm.group(2).strip()
            eid = enemies_by_name.get(ename)
            if eid:
                for _ in range(count):
                    slots.append({"enemy_id": eid, "level": 8, "tier": "normal"})
    else:
        # 2 × A, 3 × B
        parts = [p.strip() for p in comp.split(",")]
        for part in parts:
            rm = re.search(r"(\d+)\s*×\s*(.+)$", part)
            if not rm:
                continue
            count = int(rm.group(1))
            ename = rm.group(2).strip()
            eid = enemies_by_name.get(ename)
            if not eid:
                continue
            for _ in range(count):
                slots.append({"enemy_id": eid, "level": 5, "tier": "normal"})
    # pad/truncate to 5
    while len(slots) < 5 and slots:
        slots.append(dict(slots[-1]))
    return slots[:5]


def build_heroes(registry: list[dict], stats: dict[str, dict]) -> dict:
    heroes = []
    for h in registry:
        st = stats.get(h["id"], ROLE_DEFAULTS[h["role"]])
        level = 20 if h["id"] in {"H01", "H02", "H03", "H04", "H05"} else 1
        stars = {"common": 1, "rare": 2, "epic": 3, "legendary": 4, "mythic": 5}[h["rarity"]]
        if h["id"] in {"H01", "H02", "H03", "H04", "H05"}:
            stars = max(stars, 3)
        power = int(st["hp"] * 0.15 + st["atk"] * 4 + st["def"] * 2 + level * 80)
        heroes.append(
            {
                "id": h["id"],
                "name": h["name"],
                "class": h["class"],
                "role": h["role"],
                "faction": h["faction"],
                "faction_id": h["faction_id"],
                "rarity": h["rarity"],
                "rarity_code": h["rarity_code"],
                "era": h["era"],
                "tint": h["tint"],
                "level": level,
                "stars": stars,
                "power": power,
                "base_stats": st,
                "skills": ["basic", "active_1", "active_2", "passive", "ultimate"],
                "favorite": h["id"] in {"H01", "H03"},
                "asset_id": f"heroes/{h['id'].lower()}",
                "placeholder": True,
            }
        )
    return {
        "factions": FACTIONS,
        "heroes": heroes,
        "equipment": [
            {"id": "eq_seal_blade", "slot": "weapon", "name": "Клинок печати", "bonus": {"atk": 40}},
            {"id": "eq_rift_mail", "slot": "armor", "name": "Кольчуга разлома", "bonus": {"def": 35}},
            {"id": "eq_chrono_charm", "slot": "acc", "name": "Хроно-амулет", "bonus": {"spd": 8}},
        ],
        "squad_presets": [
            {"id": "p_starter", "name": "Обучающий союз", "slots": ["H01", "H02", "H03", "H04", "H05"]},
            {"id": "p_free", "name": "Стартовый свободный", "slots": ["H02", "H10", "H16", "H23", "H30"]},
        ],
        "default_squad": ["H01", "H02", "H03", "H04", "H05"],
        "schema_version": 2,
        "setting": "bashkortostan_razlom_epoh",
    }


def build_campaign(stages: list[dict], encounters: dict) -> dict:
    edges = []
    for i in range(len(stages) - 1):
        edges.append([stages[i]["id"], stages[i + 1]["id"]])
    regions = []
    for i, ch in enumerate(CHAPTERS_META):
        regions.append(
            {
                "id": ch["id"],
                "name": ch["region"],
                "chapter_name": ch["name"],
                "unlocked": ch["unlocked"],
                "req": "" if ch["unlocked"] else f"Пройти {CHAPTERS_META[i-1]['id']}-30" if i else "",
                "x": 180 + (i % 2) * 420,
                "y": 160 + i * 280,
            }
        )
    # attach encounter ids onto stages
    for s in stages:
        if s["id"] in encounters:
            s["encounter_text"] = encounters[s["id"]]
    return {
        "schema_version": 2,
        "setting": "bashkortostan_razlom_epoh",
        "world_name": "Башкортостан: Разлом эпох",
        "chapter_id": "CH01",
        "chapter_name": "Уфа: Справка о конце света",
        "current_stage": "CH01-03",
        "chapters": CHAPTERS_META,
        "regions": regions,
        "stages": stages,
        "edges": edges,
        "side_stages": [
            {"id": "CH01-S01", "name": "Спасение экспедиции", "after": "CH01-08", "type": "side"},
            {"id": "CH01-S02", "name": "Архивное свидетельство", "after": "CH01-21", "type": "side"},
        ],
        "secrets": [
            {"id": "CH01-X01", "name": "Потерянный трамвай №0", "after": "CH01-15", "type": "secret"}
        ],
    }


def build_enemies(enemies: list[dict], bosses: list[dict], encounters_text: dict, enemies_by_name: dict, bosses_by_name: dict) -> dict:
    enc_list = []
    for sid, comp in sorted(encounters_text.items()):
        slots = enemy_slots_from_composition(comp, enemies_by_name, bosses_by_name)
        if not slots:
            # fallback 5 of first ch1 enemy
            e0 = next((e for e in enemies if e["chapter"] == 1), None)
            if e0:
                slots = [{"enemy_id": e0["id"], "level": 5, "tier": "normal"} for _ in range(5)]
        enc_list.append({"stage_id": sid, "slots": slots})
    return {
        "schema_version": 1,
        "rigs": RIGS,
        "enemies": enemies,
        "bosses": bosses,
        "encounters": enc_list,
        "modifiers": ["normal", "enhanced", "guardian", "furious", "rift"],
    }


def main() -> None:
    story = (DOCS / "STORY_6_CHAPTERS.md").read_text(encoding="utf-8")
    heroes_doc = (DOCS / "FACTIONS_45_HEROES.md").read_text(encoding="utf-8")
    bestiary = (DOCS / "BESTIARY_6_CHAPTERS.md").read_text(encoding="utf-8")

    registry = parse_hero_registry(heroes_doc)
    stats = parse_hero_stats(heroes_doc)
    assert len(registry) >= 45, f"heroes={len(registry)}"
    enemies = parse_enemies_ch(bestiary)
    bosses = parse_bosses(bestiary)
    stages = parse_ch01_stages(story)
    encounters = parse_ch01_encounters(bestiary)
    assert len(stages) == 30, f"stages={len(stages)}"
    assert len(enemies) >= 36, f"enemies={len(enemies)}"
    assert len(bosses) >= 18, f"bosses={len(bosses)}"

    enemies_by_name = {e["name"]: e["id"] for e in enemies}
    bosses_by_name = {b["name"]: b["id"] for b in bosses}

    OUT.mkdir(parents=True, exist_ok=True)
    # copy unchanged design docs from 0.1.0 as baseline
    for name in ["hub.json", "battle_modes.json", "features.json", "theme.json", "shell.json", "motion.json", "assets.json"]:
        src = SRC_0_1 / name
        if src.exists():
            (OUT / name).write_text(src.read_text(encoding="utf-8"), encoding="utf-8")

    heroes_pack = build_heroes(registry, stats)
    campaign = build_campaign(stages, encounters)
    enemies_pack = build_enemies(enemies, bosses, encounters, enemies_by_name, bosses_by_name)

    # update hub portal names lightly via strings; keep hub layout
    strings = {
        "locale": "ru",
        "entries": {
            "app.name": "Lunex AFK",
            "world.name": "Башкортостан: Разлом эпох",
            "nav.map": "Карта",
            "nav.heroes": "Герои",
            "nav.hub": "Главная",
            "nav.battle": "Битва",
            "shell.shop": "Магазин",
            "map.title": "Карта · Башкортостан",
            "map.continue": "Продолжить",
            "heroes.title": "Коллекция героев",
            "battle.title": "Арена режимов",
            "common.back": "Назад",
            "common.demo": "Демо",
            "chapter.CH01.name": "Уфа: Справка о конце света",
            "story.d01.open.01": "По всем городским часам сейчас разное время.",
            "story.d01.open.02": "Зато маршрутка опоздала одинаково во всех эпохах.",
            "story.d01.open.03": "Это не шутка. Разлом расширяется.",
        },
    }
    for h in heroes_pack["heroes"]:
        strings["entries"][f"hero.{h['id']}.name"] = h["name"]
    for e in enemies:
        strings["entries"][f"enemy.{e['id']}.name"] = e["name"]
    for b in bosses:
        strings["entries"][f"boss.{b['id']}.name"] = b["name"]

    manifest = {
        "id": "lunex-core",
        "version": "0.2.0",
        "schema": 3,
        "client_min": "0.1.0",
        "title": "Razlom Epoh · Chapter 1 vertical slice",
        "locale": "ru",
        "created_at": "2026-11-20T00:00:00Z",
        "updated_at": "2026-11-20T08:00:00Z",
        "notes": "Канон «Башкортостан: Разлом эпох». Глава 1 полная; гл.2–6 маркеры. Не серверный прогресс.",
        "files": {
            "hub.json": {"role": "hub_layout"},
            "campaign.json": {"role": "campaign"},
            "heroes.json": {"role": "heroes"},
            "battle_modes.json": {"role": "battle_modes"},
            "features.json": {"role": "feature_demos"},
            "theme.json": {"role": "ui_theme"},
            "shell.json": {"role": "shell_chrome"},
            "strings.json": {"role": "locale_strings"},
            "motion.json": {"role": "motion_fx"},
            "assets.json": {"role": "asset_registry"},
            "enemies.json": {"role": "bestiary"},
        },
        "integrity": {"algo": "sha256", "hashes": {}},
    }

    (OUT / "heroes.json").write_text(json.dumps(heroes_pack, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (OUT / "campaign.json").write_text(json.dumps(campaign, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (OUT / "enemies.json").write_text(json.dumps(enemies_pack, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (OUT / "strings.json").write_text(json.dumps(strings, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (OUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(f"Wrote {OUT}")
    print(f" heroes={len(heroes_pack['heroes'])} stages={len(stages)} enemies={len(enemies)} bosses={len(bosses)} encounters={len(encounters)}")


if __name__ == "__main__":
    main()
