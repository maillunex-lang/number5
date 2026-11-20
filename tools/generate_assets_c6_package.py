#!/usr/bin/env python3
"""Build content package 0.9.0: C6 art registry (placeholder → planned paths).

Maps heroes / 6 enemy rigs / chapter art packs into assets.json + media/*.json
descriptors. No binary art — ART-05 fills real webp/atlases later.
Active package writer for this layer.
"""
from __future__ import annotations

import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "content/packages/0.8.0"
OUT = ROOT / "content/packages/0.9.0"

HERO_ANIMS = [
    "idle",
    "attack",
    "skill_1",
    "skill_2",
    "ultimate",
    "hit",
    "death",
    "victory",
]
RIG_ANIMS_CAST = ["idle", "attack", "cast", "hit", "death"]
RIG_ANIMS_NO_CAST = ["idle", "attack", "hit", "death"]  # RIG-BEAST
VFX_COMMON = [
    "shield",
    "strike",
    "beam",
    "slow",
    "mark",
    "heal",
    "explosion",
    "teleport",
    "runes",
    "fire",
    "ice",
    "rift",
]
SFX_COMMON = [
    "hit_light",
    "hit_heavy",
    "cast",
    "shield",
    "heal",
    "explosion",
    "whoosh",
    "crit",
    "death",
    "ui_confirm",
    "ui_back",
    "rift_pulse",
]
CHAPTER_NAMES = {
    1: "Уфа",
    2: "Шиханы",
    3: "Белорецк",
    4: "Стерлитамак 2050",
    5: "Иремель",
    6: "Сердце Разлома",
}


def _item(
    asset_id: str,
    *,
    path: str,
    role: str,
    tags: list[str],
    status: str = "planned",
    note: str = "",
    meta: dict | None = None,
) -> dict:
    out = {
        "id": asset_id,
        "path": path,
        "role": role,
        "tags": tags,
        "status": status,
    }
    if note:
        out["note"] = note
    if meta:
        out["meta"] = meta
    return out


def build_assets(heroes: list[dict], enemies: dict) -> tuple[dict, list[tuple[str, dict]]]:
    """Return assets.json doc and list of (relative_path, json_doc) media descriptors."""
    items: list[dict] = []
    bindings: dict[str, str] = {}
    media_files: list[tuple[str, dict]] = []

    # Preserve base UI items
    items.extend(
        [
            _item(
                "icon_app",
                path="res://assets/ui/icon.svg",
                role="app_icon",
                tags=["ui", "brand"],
                status="ready",
                note="Иконка приложения",
            ),
            _item(
                "font_display",
                path="res://fonts/Cinzel-Bold.ttf",
                role="font_display",
                tags=["font"],
                status="ready",
            ),
            _item(
                "font_ui",
                path="res://fonts/OpenSans-SemiBold.ttf",
                role="font_ui",
                tags=["font"],
                status="ready",
            ),
            _item(
                "placeholder_building",
                path="",
                role="building_art",
                tags=["hub", "placeholder"],
                status="placeholder",
                note="Слот арта здания — PNG/WebP через Studio / ART-05",
            ),
        ]
    )
    bindings["hub.building.summon"] = "placeholder_building"
    bindings["hub.building.guild"] = "placeholder_building"
    bindings["shell.brand"] = "icon_app"

    # --- Heroes (45 × portrait/atlas/animations/ultimate_vfx) ---
    for h in heroes:
        hid = h["id"]  # H01
        slug = hid.lower()  # h01
        base = f"media/heroes/{slug}"
        portrait_id = f"hero_{slug}_portrait"
        atlas_id = f"hero_{slug}_atlas"
        anim_id = f"hero_{slug}_animations"
        vfx_id = f"hero_{slug}_ultimate_vfx"

        items.append(
            _item(
                portrait_id,
                path=f"{base}/portrait.webp",
                role="hero_portrait",
                tags=["hero", "portrait", "placeholder"],
                status="placeholder",
                meta={"hero_id": hid, "tint": h.get("tint", "")},
            )
        )
        items.append(
            _item(
                atlas_id,
                path=f"{base}/atlas.webp",
                role="hero_atlas",
                tags=["hero", "atlas", "placeholder"],
                status="placeholder",
                meta={"hero_id": hid},
            )
        )
        items.append(
            _item(
                anim_id,
                path=f"{base}/animations.json",
                role="hero_animations",
                tags=["hero", "animations"],
                status="planned",
                meta={"hero_id": hid, "clips": HERO_ANIMS},
            )
        )
        items.append(
            _item(
                vfx_id,
                path=f"{base}/ultimate_vfx.webp",
                role="hero_ultimate_vfx",
                tags=["hero", "vfx", "placeholder"],
                status="placeholder",
                meta={"hero_id": hid},
            )
        )
        bindings[f"hero.{hid}.portrait"] = portrait_id
        bindings[f"hero.{hid}.atlas"] = atlas_id
        bindings[f"hero.{hid}.animations"] = anim_id
        bindings[f"hero.{hid}.ultimate_vfx"] = vfx_id

        media_files.append(
            (
                f"heroes/{slug}/animations.json",
                {
                    "hero_id": hid,
                    "pivot": "feet",
                    "facing": "right",
                    "clips": [
                        {"id": c, "frames": 1, "duration_hint_sec": 0.8 if c != "idle" else 1.5}
                        for c in HERO_ANIMS
                    ],
                    "status": "planned",
                    "note": "C6 descriptor · ART-05 fills atlas frames",
                },
            )
        )
        media_files.append(
            (
                f"heroes/{slug}/manifest.json",
                {
                    "hero_id": hid,
                    "name": h.get("name", hid),
                    "assets": {
                        "portrait": f"portrait.webp",
                        "atlas": f"atlas.webp",
                        "animations": f"animations.json",
                        "ultimate_vfx": f"ultimate_vfx.webp",
                    },
                    "status": "placeholder",
                },
            )
        )

    # --- 6 rigs × skins + animation descriptors ---
    for rig in enemies.get("rigs", []):
        rid = rig["id"]  # RIG-GUARD
        slug = rid.lower().replace("rig-", "")  # guard
        has_cast = rid != "RIG-BEAST"
        clips = RIG_ANIMS_CAST if has_cast else RIG_ANIMS_NO_CAST
        base = f"media/rigs/{slug}"

        atlas_id = f"rig_{slug}_atlas"
        anim_id = f"rig_{slug}_animations"
        items.append(
            _item(
                atlas_id,
                path=f"{base}/atlas.webp",
                role="rig_atlas",
                tags=["rig", "atlas", "placeholder"],
                status="placeholder",
                meta={"rig_id": rid, "clips": clips},
            )
        )
        items.append(
            _item(
                anim_id,
                path=f"{base}/animations.json",
                role="rig_animations",
                tags=["rig", "animations"],
                status="planned",
                meta={"rig_id": rid, "clips": clips, "pivot": "feet"},
            )
        )
        bindings[f"rig.{rid}.atlas"] = atlas_id
        bindings[f"rig.{rid}.animations"] = anim_id

        for skin in ("skin_a", "skin_b"):
            skin_id = f"rig_{slug}_{skin}"
            items.append(
                _item(
                    skin_id,
                    path=f"{base}/{skin}.webp",
                    role="rig_skin",
                    tags=["rig", "skin", "placeholder"],
                    status="placeholder",
                    meta={
                        "rig_id": rid,
                        "skin_id": skin,
                        "palette": "ancient_nature" if skin == "skin_a" else "tech_rift",
                    },
                )
            )
            bindings[f"rig.{rid}.{skin}"] = skin_id

        media_files.append(
            (
                f"rigs/{slug}/animations.json",
                {
                    "rig_id": rid,
                    "pivot": "feet",
                    "facing": "left",
                    "clips": [
                        {
                            "id": c,
                            "frames": 1,
                            "duration_hint_sec": {
                                "idle": 1.5,
                                "attack": 0.65,
                                "cast": 0.85,
                                "hit": 0.28,
                                "death": 0.9,
                            }.get(c, 0.7),
                        }
                        for c in clips
                    ],
                    "skins": ["skin_a", "skin_b"],
                    "status": "planned",
                    "note": "C6 · 1 atlas + shader tint; no duplicate atlases per skin",
                },
            )
        )
        media_files.append(
            (
                f"rigs/{slug}/manifest.json",
                {
                    "rig_id": rid,
                    "name": rig.get("name", rid),
                    "role": rig.get("role", ""),
                    "assets": {
                        "atlas": "atlas.webp",
                        "animations": "animations.json",
                        "skin_a": "skin_a.webp",
                        "skin_b": "skin_b.webp",
                    },
                    "status": "placeholder",
                },
            )
        )

    # Enemy / boss → binding to rig+skin (no unique mesh)
    for e in enemies.get("enemies", []) + enemies.get("bosses", []):
        eid = e["id"]
        rid = e.get("rig_id", "")
        skin = e.get("skin_id", "skin_a")
        slug = rid.lower().replace("rig-", "")
        bind_key = f"enemy.{eid}.visual"
        # point at skin item; atlas shared via rig
        bindings[bind_key] = f"rig_{slug}_{skin}"
        bindings[f"enemy.{eid}.rig"] = rid
        if e.get("kind") == "boss" or str(eid).startswith("B"):
            portrait_id = f"boss_{eid.lower().replace('-', '_')}_portrait"
            items.append(
                _item(
                    portrait_id,
                    path=f"media/bosses/{eid.lower()}/portrait.webp",
                    role="boss_portrait",
                    tags=["boss", "portrait", "placeholder"],
                    status="placeholder",
                    meta={"boss_id": eid, "rig_id": rid, "scale": 1.35},
                )
            )
            bindings[f"enemy.{eid}.portrait"] = portrait_id
            media_files.append(
                (
                    f"bosses/{eid.lower()}/manifest.json",
                    {
                        "boss_id": eid,
                        "rig_id": rid,
                        "skin_id": skin,
                        "scale": 1.35,
                        "assets": {"portrait": "portrait.webp"},
                        "status": "placeholder",
                        "note": "Boss reuses rig animations; unique portrait + overlays",
                    },
                )
            )

    # --- Chapter art packs ---
    for ch in range(1, 7):
        prefix = f"ch{ch:02d}"
        base = f"media/chapters/{prefix}"
        map_id = f"{prefix}_map"
        items.append(
            _item(
                map_id,
                path=f"{base}/{prefix}_map.webp",
                role="chapter_map",
                tags=["chapter", "map", "placeholder"],
                status="placeholder",
                meta={"chapter": ch, "name": CHAPTER_NAMES[ch]},
            )
        )
        bindings[f"chapter.CH{ch:02d}.map"] = map_id

        for z in range(1, 7):
            zid = f"{prefix}_z{z:02d}_bg"
            items.append(
                _item(
                    zid,
                    path=f"{base}/{prefix}_z{z:02d}_bg.webp",
                    role="zone_bg",
                    tags=["chapter", "zone", "placeholder"],
                    status="placeholder",
                    meta={"chapter": ch, "zone": z},
                )
            )
            bindings[f"chapter.CH{ch:02d}.zone.{z}.bg"] = zid
            mid = f"{prefix}_z{z:02d}_mid"
            items.append(
                _item(
                    mid,
                    path=f"{base}/{prefix}_z{z:02d}_mid.webp",
                    role="zone_mid",
                    tags=["chapter", "parallax", "placeholder"],
                    status="placeholder",
                    meta={"chapter": ch, "zone": z},
                )
            )
            bindings[f"chapter.CH{ch:02d}.zone.{z}.mid"] = mid
            fg = f"{prefix}_z{z:02d}_fg"
            items.append(
                _item(
                    fg,
                    path=f"{base}/{prefix}_z{z:02d}_fg.webp",
                    role="zone_fg",
                    tags=["chapter", "foreground", "placeholder"],
                    status="placeholder",
                    meta={"chapter": ch, "zone": z},
                )
            )
            bindings[f"chapter.CH{ch:02d}.zone.{z}.fg"] = fg

        for a in range(1, 4):
            aid = f"{prefix}_arena_{a:02d}"
            items.append(
                _item(
                    aid,
                    path=f"{base}/{prefix}_arena_{a:02d}.webp",
                    role="boss_arena",
                    tags=["chapter", "arena", "placeholder"],
                    status="placeholder",
                    meta={"chapter": ch, "arena": a},
                )
            )
            bindings[f"chapter.CH{ch:02d}.arena.{a}"] = aid

        media_files.append(
            (
                f"chapters/{prefix}/manifest.json",
                {
                    "chapter": ch,
                    "name": CHAPTER_NAMES[ch],
                    "map": f"{prefix}_map.webp",
                    "zones": [
                        {
                            "zone": z,
                            "bg": f"{prefix}_z{z:02d}_bg.webp",
                            "mid": f"{prefix}_z{z:02d}_mid.webp",
                            "fg": f"{prefix}_z{z:02d}_fg.webp",
                        }
                        for z in range(1, 7)
                    ],
                    "arenas": [f"{prefix}_arena_{a:02d}.webp" for a in range(1, 4)],
                    "audio": {
                        "map_theme": f"{prefix}_map_theme.ogg",
                        "battle_a": f"{prefix}_battle_a.ogg",
                        "battle_b": f"{prefix}_battle_b.ogg",
                    },
                    "status": "placeholder",
                    "note": "Art pack per STORY_6_CHAPTERS · files planned for ART-05",
                },
            )
        )

    # Common VFX / SFX
    for v in VFX_COMMON:
        vid = f"vfx_{v}"
        items.append(
            _item(
                vid,
                path=f"media/vfx/{v}.webp",
                role="common_vfx",
                tags=["vfx", "shared", "placeholder"],
                status="placeholder",
            )
        )
        bindings[f"vfx.{v}"] = vid
    for s in SFX_COMMON:
        sid = f"sfx_{s}"
        items.append(
            _item(
                sid,
                path=f"media/sfx/{s}.ogg",
                role="common_sfx",
                tags=["sfx", "shared", "placeholder"],
                status="placeholder",
            )
        )
        bindings[f"sfx.{s}"] = sid

    media_files.append(
        (
            "vfx/manifest.json",
            {"items": VFX_COMMON, "status": "placeholder", "count": len(VFX_COMMON)},
        )
    )
    media_files.append(
        (
            "sfx/manifest.json",
            {"items": SFX_COMMON, "status": "placeholder", "count": len(SFX_COMMON)},
        )
    )

    production_budget = {
        "rigs": 6,
        "enemy_skins": 12,
        "story_bosses": 18,
        "common_vfx": 12,
        "boss_arenas": 6,
        "common_sfx": 12,
        "hero_sets_planned": 45,
        "note": "Бюджет BESTIARY §1 · не 54 уникальных комплекта анимаций",
    }

    summary = {
        "heroes": 45,
        "hero_asset_slots": 45 * 4,
        "rigs": 6,
        "rig_skins": 12,
        "boss_portraits": 18,
        "chapter_packs": 6,
        "zone_layers": 6 * 6 * 3,
        "arenas": 6 * 3,
        "vfx": len(VFX_COMMON),
        "sfx": len(SFX_COMMON),
        "items_total": len(items),
        "bindings_total": len(bindings),
    }

    doc = {
        "schema": 2,
        "disclaimer": "C6 DEMO · реестр слотов без бинарного арта; ART-05 подставляет webp/атласы",
        "production_budget": production_budget,
        "summary": summary,
        "animation_slots": {
            "hero": HERO_ANIMS,
            "rig_default": RIG_ANIMS_CAST,
            "rig_beast": RIG_ANIMS_NO_CAST,
        },
        "items": items,
        "bindings": bindings,
    }
    return doc, media_files


def enrich_enemies(enemies: dict) -> dict:
    for rig in enemies.get("rigs", []):
        rid = rig["id"]
        slug = rid.lower().replace("rig-", "")
        has_cast = rid != "RIG-BEAST"
        clips = RIG_ANIMS_CAST if has_cast else RIG_ANIMS_NO_CAST
        rig["animations"] = clips
        rig["pivot"] = "feet"
        rig["facing"] = "left"
        rig["asset_prefix"] = f"media/rigs/{slug}"
        rig["skins"] = ["skin_a", "skin_b"]
        rig["art_status"] = "placeholder"
    for e in enemies.get("enemies", []):
        e["art_binding"] = f"enemy.{e['id']}.visual"
        e["art_status"] = "placeholder"
    for b in enemies.get("bosses", []):
        b["art_binding"] = f"enemy.{b['id']}.visual"
        b["portrait_binding"] = f"enemy.{b['id']}.portrait"
        b["art_status"] = "placeholder"
        b["scale"] = 1.35
    enemies["art_schema"] = 1
    return enemies


def enrich_heroes(heroes_doc: dict) -> dict:
    for h in heroes_doc.get("heroes", []):
        hid = h["id"]
        slug = hid.lower()
        h["asset_id"] = f"heroes/{slug}"
        h["placeholder"] = True
        h["art"] = {
            "portrait": f"hero.{hid}.portrait",
            "atlas": f"hero.{hid}.atlas",
            "animations": f"hero.{hid}.animations",
            "ultimate_vfx": f"hero.{hid}.ultimate_vfx",
            "clips": HERO_ANIMS,
            "status": "placeholder",
        }
    return heroes_doc


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    shutil.copytree(SRC, OUT)

    heroes_doc = json.loads((OUT / "heroes.json").read_text(encoding="utf-8"))
    enemies = json.loads((OUT / "enemies.json").read_text(encoding="utf-8"))

    assets_doc, media_files = build_assets(heroes_doc["heroes"], enemies)
    (OUT / "assets.json").write_text(
        json.dumps(assets_doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    media_root = OUT / "media"
    if media_root.exists():
        shutil.rmtree(media_root)
    for rel, doc in media_files:
        path = media_root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    enemies = enrich_enemies(enemies)
    (OUT / "enemies.json").write_text(
        json.dumps(enemies, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    heroes_doc = enrich_heroes(heroes_doc)
    (OUT / "heroes.json").write_text(
        json.dumps(heroes_doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    # Hub rail entry for art registry DEMO
    hub = json.loads((OUT / "hub.json").read_text(encoding="utf-8"))
    rail = hub.get("side_rail", [])
    if not any(r.get("route") == "ART-01" for r in rail):
        rail.append(
            {
                "id": "art_registry",
                "label": "Арт",
                "icon": "◇",
                "tip": "Реестр арта",
                "route": "ART-01",
                "badge": "C6",
            }
        )
        hub["side_rail"] = rail
    (OUT / "hub.json").write_text(json.dumps(hub, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    strings = json.loads((OUT / "strings.json").read_text(encoding="utf-8"))
    strings["entries"].update(
        {
            "art.title": "Реестр арта",
            "art.rigs": "Риги",
            "art.heroes": "Герои",
            "art.chapters": "Главы",
            "art.budget": "Бюджет",
            "c6.demo": "C6 DEMO · слоты арта без бинарных файлов",
        }
    )
    (OUT / "strings.json").write_text(
        json.dumps(strings, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    file_list = [f.name for f in sorted(OUT.glob("*.json")) if f.name != "manifest.json"]
    hashes = {f: hashlib.sha256((OUT / f).read_bytes()).hexdigest() for f in file_list}
    # also hash media manifests for integrity awareness (optional nested)
    media_hashes = {}
    for p in sorted(media_root.rglob("*.json")):
        rel = str(p.relative_to(OUT)).replace("\\", "/")
        media_hashes[rel] = hashlib.sha256(p.read_bytes()).hexdigest()

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    manifest = {
        "id": "lunex-core",
        "version": "0.9.0",
        "schema": 10,
        "client_min": "0.1.0",
        "title": "Razlom Epoh · C6 art registry",
        "locale": "ru",
        "created_at": now,
        "updated_at": now,
        "notes": "C6: assets.json registry + media descriptors for heroes/rigs/chapters. Binary art = ART-05.",
        "files": {f: {"role": f.replace(".json", "")} for f in file_list},
        "media": {"root": "media/", "descriptors": len(media_hashes)},
        "integrity": {"algo": "sha256", "hashes": hashes, "media_hashes": media_hashes},
    }
    (OUT / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    active = {
        "version": "0.9.0",
        "source": "content-c-c6",
        "note": "Клиент читает только опубликованный пакет. Прогресс игрока сюда не пишется.",
        "published_at": now,
    }
    (ROOT / "content/packages/active.json").write_text(
        json.dumps(active, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    s = assets_doc["summary"]
    print(f"Wrote {OUT}")
    print(
        f" items={s['items_total']} bindings={s['bindings_total']} "
        f"media_json={len(media_files)} heroes={s['heroes']} rigs={s['rigs']}"
    )


if __name__ == "__main__":
    main()
