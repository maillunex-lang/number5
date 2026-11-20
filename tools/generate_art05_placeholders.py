#!/usr/bin/env python3
"""ART-05: generate placeholder portrait/atlas webp for heroes + rigs.

Writes under content/packages/<ver>/media/ (gitignored binaries; use -f to commit
starter set or regenerate before APK export).
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
CLIPS = ["idle", "attack", "hit", "death"]
FRAME = 128


def _hex(c: str) -> tuple[int, int, int]:
    s = (c or "#888888").lstrip("#")
    if len(s) == 3:
        s = "".join(ch * 2 for ch in s)
    return tuple(int(s[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def _font(size: int):
    for name in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "DejaVuSans-Bold.ttf",
    ):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def _draw_figure(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], tint: tuple[int, int, int], pose: str) -> None:
    x0, y0, x1, y1 = box
    cx = (x0 + x1) // 2
    # body
    body = (cx - 22, y0 + 38, cx + 22, y1 - 18)
    if pose == "attack":
        body = (cx - 18, y0 + 36, cx + 26, y1 - 18)
    elif pose == "hit":
        body = (cx - 26, y0 + 42, cx + 18, y1 - 16)
    elif pose == "death":
        body = (cx - 34, y1 - 40, cx + 34, y1 - 12)
    draw.rounded_rectangle(body, radius=14, fill=tint)
    # head
    if pose != "death":
        hy = y0 + 22 if pose != "hit" else y0 + 28
        hx = cx + (8 if pose == "attack" else (-6 if pose == "hit" else 0))
        draw.ellipse((hx - 18, hy - 18, hx + 18, hy + 18), fill=tuple(min(255, c + 40) for c in tint))
    # accent slash
    accent = tuple(min(255, int(c * 1.25)) for c in tint)
    if pose == "attack":
        draw.line((cx + 10, y0 + 50, cx + 48, y0 + 30), fill=accent, width=6)
    elif pose == "hit":
        draw.line((cx - 40, y0 + 40, cx - 10, y0 + 55), fill=(220, 80, 80), width=5)


def make_portrait(path: Path, name: str, tint_hex: str, label: str) -> None:
    tint = _hex(tint_hex)
    img = Image.new("RGBA", (256, 256), (12, 16, 28, 255))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((8, 8, 248, 248), radius=28, fill=(tint[0] // 5, tint[1] // 5, tint[2] // 5, 255), outline=tint, width=4)
    _draw_figure(draw, (48, 36, 208, 210), tint, "idle")
    font = _font(22)
    draw.text((20, 214), (name or label)[:14], fill=(255, 230, 180, 255), font=font)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "WEBP", quality=82)


def make_atlas(path: Path, tint_hex: str) -> None:
    tint = _hex(tint_hex)
    img = Image.new("RGBA", (FRAME * len(CLIPS), FRAME), (8, 10, 18, 255))
    draw = ImageDraw.Draw(img)
    for i, clip in enumerate(CLIPS):
        x0 = i * FRAME
        draw.rectangle((x0, 0, x0 + FRAME - 1, FRAME - 1), fill=(tint[0] // 6, tint[1] // 6, tint[2] // 6, 255))
        _draw_figure(draw, (x0 + 8, 4, x0 + FRAME - 8, FRAME - 4), tint, clip)
        draw.text((x0 + 6, FRAME - 18), clip[:6], fill=(230, 220, 200, 200), font=_font(12))
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "WEBP", quality=82)


def update_manifest(path: Path, **extra) -> None:
    data = {}
    if path.exists():
        data = json.loads(path.read_text(encoding="utf-8"))
    data.update(extra)
    data["status"] = "art05_placeholder"
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", default="0.9.0")
    ap.add_argument("--heroes-only", action="store_true")
    args = ap.parse_args()
    pkg = ROOT / "content" / "packages" / args.version
    heroes = json.loads((pkg / "heroes.json").read_text(encoding="utf-8")).get("heroes", [])
    n = 0
    for h in heroes:
        hid = str(h.get("id", ""))
        if not hid:
            continue
        folder = pkg / "media" / "heroes" / hid.lower()
        tint = str(h.get("tint", "#888888"))
        make_portrait(folder / "portrait.webp", str(h.get("name", hid)), tint, hid)
        make_atlas(folder / "atlas.webp", tint)
        anim = {
            "hero_id": hid,
            "pivot": "feet",
            "facing": "right",
            "frame_size": [FRAME, FRAME],
            "clips": [
                {"id": c, "frame_index": i, "frames": 1, "duration_hint_sec": 0.35 if c != "idle" else 1.2}
                for i, c in enumerate(CLIPS)
            ],
            "status": "art05_placeholder",
            "note": "ART-05 procedural placeholder atlas (idle/attack/hit/death)",
        }
        (folder / "animations.json").write_text(json.dumps(anim, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        update_manifest(
            folder / "manifest.json",
            hero_id=hid,
            name=h.get("name", hid),
            assets={"portrait": "portrait.webp", "atlas": "atlas.webp", "animations": "animations.json"},
        )
        n += 1
    if not args.heroes_only:
        enemies = json.loads((pkg / "enemies.json").read_text(encoding="utf-8"))
        for rig in enemies.get("rigs", []):
            rid = str(rig.get("id", ""))
            slug = rid.replace("RIG-", "").lower()
            folder = pkg / "media" / "rigs" / slug
            # deterministic tint from name hash
            hue = (sum(ord(c) for c in rid) * 37) % 360
            import colorsys

            r, g, b = colorsys.hsv_to_rgb(hue / 360.0, 0.45, 0.75)
            tint = "#{:02X}{:02X}{:02X}".format(int(r * 255), int(g * 255), int(b * 255))
            make_atlas(folder / "atlas.webp", tint)
            for skin in ("skin_a", "skin_b"):
                make_portrait(folder / f"{skin}.webp", str(rig.get("name", rid)), tint, skin)
            anim = {
                "rig_id": rid,
                "pivot": "feet",
                "facing": "left",
                "frame_size": [FRAME, FRAME],
                "clips": [
                    {"id": c, "frame_index": i, "frames": 1, "duration_hint_sec": 0.35 if c != "idle" else 1.2}
                    for i, c in enumerate(CLIPS)
                ],
                "status": "art05_placeholder",
            }
            (folder / "animations.json").write_text(json.dumps(anim, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            update_manifest(
                folder / "manifest.json",
                rig_id=rid,
                name=rig.get("name", rid),
                assets={"atlas": "atlas.webp", "animations": "animations.json", "skin_a": "skin_a.webp", "skin_b": "skin_b.webp"},
            )
            n += 1
    # patch assets.json disclaimer / summary statuses lightly
    assets_path = pkg / "assets.json"
    assets = json.loads(assets_path.read_text(encoding="utf-8"))
    assets["disclaimer"] = "ART-05 · placeholder webp portraits/atlases for heroes+rigs (procedural); replace with final art via Studio"
    assets["art05"] = {"generated": True, "clips": CLIPS, "frame": FRAME}
    assets_path.write_text(json.dumps(assets, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"ART05_OK heroes+rigs written under {pkg / 'media'} items≈{n}")


if __name__ == "__main__":
    main()
