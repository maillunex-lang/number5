#!/usr/bin/env python3
"""Build content package 0.8.0: C5 skills + story dialogs.

Parses FACTIONS_45_HEROES skill cards (45×5) and STORY dialog beats (Dxx-*).
Active package writer for this layer.
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
SRC = ROOT / "content/packages/0.7.0"
OUT = ROOT / "content/packages/0.8.0"


def parse_hero_skills(text: str) -> tuple[dict[str, list[dict]], dict[str, dict]]:
    """Return skills_by_hero and flat skill cards keyed by skill_id."""
    by_hero: dict[str, list[dict]] = {}
    flat: dict[str, dict] = {}
    blocks = re.split(r"\n### (H\d+)\s+·", text)
    # blocks[0]=preamble, then pairs id, body
    for i in range(1, len(blocks), 2):
        hid = blocks[i].strip()
        body = blocks[i + 1] if i + 1 < len(blocks) else ""
        # cut at next hero already split
        skills: list[dict] = []

        def add(slot: str, name: str, desc: str, **extra) -> None:
            sid = f"{hid}_{slot}"
            card = {
                "id": sid,
                "hero_id": hid,
                "slot": slot,
                "name": name.strip(),
                "description": desc.strip(),
                **extra,
            }
            skills.append(card)
            flat[sid] = card

        m = re.search(r"\*\*Автоатака «([^»]+)»:\*\*\s*(.+)", body)
        if m:
            add("basic", m.group(1), m.group(2), cast="auto")
        m = re.search(r"\*\*Активное умение 1:\*\*\s*\*\*([^*]+)\*\*\s*:\s*(.+)", body)
        if m:
            cd = None
            cdm = re.search(r"КД\s+([\d.]+)\s*с", m.group(2))
            if cdm:
                cd = float(cdm.group(1))
            add("active_1", m.group(1), m.group(2), cast="auto", cooldown_sec=cd)
        m = re.search(r"\*\*Активное умение 2:\*\*\s*\*\*([^*]+)\*\*\s*:\s*(.+)", body)
        if m:
            cd = None
            cdm = re.search(r"КД\s+([\d.]+)\s*с", m.group(2))
            if cdm:
                cd = float(cdm.group(1))
            add("active_2", m.group(1), m.group(2), cast="auto", cooldown_sec=cd)
        m = re.search(r"\*\*Пассивное умение «([^»]+)»:\*\*\s*(.+)", body)
        if m:
            add("passive", m.group(1), m.group(2), cast="passive")
        m = re.search(r"\*\*Ультимативное умение:\*\*\s*\*\*([^*]+)\*\*\s*:\s*(.+)", body)
        if m:
            add("ultimate", m.group(1), m.group(2), cast="auto", energy_cost=1000)

        # bio / quote
        quote = ""
        qm = re.search(r"реплики для коллекции:\s*«([^»]+)»", body)
        if qm:
            quote = qm.group(1)
        personality = ""
        pm = re.search(r"\*\*Личность:\*\*\s*([^.]+)", body)
        if pm:
            personality = pm.group(1).strip()

        if len(skills) < 5:
            # fill missing with placeholders so every hero has 5 slots
            have = {s["slot"] for s in skills}
            for slot, fallback in [
                ("basic", "Удар"),
                ("active_1", "Навык I"),
                ("active_2", "Навык II"),
                ("passive", "Пассив"),
                ("ultimate", "Ульта"),
            ]:
                if slot not in have:
                    add(slot, f"{fallback} {hid}", "Описание уточняется в каноне.", cast="auto" if slot != "passive" else "passive")

        by_hero[hid] = {
            "skills": [s["id"] for s in skills],
            "cards": skills,
            "quote": quote,
            "personality": personality,
        }
    return by_hero, flat


def _parse_speaker_lines(block: str) -> list[dict]:
    lines: list[dict] = []
    for lm in re.finditer(r"- \*\*([^*]+):\*\*\s*«([^»]+)»", block):
        lines.append({"speaker": lm.group(1).strip(), "text": lm.group(2).strip()})
    if lines:
        return lines
    for lm in re.finditer(r"- \*\*([^*]+):\*\*\s*(.+)", block):
        text = lm.group(2).strip().strip("«»").rstrip(".")
        lines.append({"speaker": lm.group(1).strip(), "text": text})
    return lines


def parse_dialogs(story: str) -> list[dict]:
    """Parse Dxx-OPEN and Dxx-NN / Dxx-NNA/B dialog blocks."""
    dialogs: list[dict] = []

    # Split by dialog headers that start a beat
    # Two markdown styles in canon:
    #   **Сценарий открытия главы (D01-OPEN):**
    #   **D01-05 (после...):**
    #   **D01-01 (до...):**   ← colon outside bold
    header_re = re.compile(
        r"\*\*(?:Сценарий открытия главы \((D\d+-OPEN)\):\*\*|"
        r"(D\d+-\d+[AB]?)\s*\(([^)]+)\):\*\*|"
        r"(D\d+-\d+[AB]?)\s*\(([^)]+)\)\*\*:)"
    )
    matches = list(header_re.finditer(story))
    for i, m in enumerate(matches):
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else min(len(story), start + 800)
        block = story[start:end]
        # stop at next major section markers inside slice
        cut = re.search(r"\n\*\*(?:Визуальная|Арт-пакет|Условия завершения|#### )", block)
        if cut:
            block = block[: cut.start()]

        if m.group(1):  # OPEN
            did = m.group(1)
            note = "открытие главы"
            ch = int(did[1:3])
            stage_n = 1
            timing = "before"
            trigger = "chapter_open"
        else:
            did = m.group(2) or m.group(4)
            note = (m.group(3) or m.group(5) or "").strip()
            ch = int(did[1:3])
            num_m = re.match(r"D\d+-(\d+)", did)
            stage_n = int(num_m.group(1)) if num_m else 1
            timing = "after"
            if "до " in note.lower() or did.endswith("A"):
                timing = "before"
            if "после" in note.lower() or did.endswith("B"):
                timing = "after"
            trigger = "stage"
            if "босс" in note.lower():
                trigger = "boss"
            if "секрет" in note.lower():
                trigger = "secret"
            if "развязк" in note.lower() or "финал" in note.lower():
                trigger = "chapter_end"

        lines = _parse_speaker_lines(block)
        entry = {
            "id": did,
            "chapter": ch,
            "trigger": trigger,
            "timing": timing,
            "stage_id": f"CH{ch:02d}-{stage_n:02d}",
            "note": note,
            "lines": lines,
            "choices": [],
        }
        # Dxx-01 often has no bullets — alias OPEN
        if did.endswith("-01") and not lines:
            entry["alias_of"] = f"D{ch:02d}-OPEN"
        dialogs.append(entry)

    by_id = {d["id"]: d for d in dialogs}
    for d in dialogs:
        if d.get("alias_of") and d["alias_of"] in by_id and not d["lines"]:
            d["lines"] = list(by_id[d["alias_of"]]["lines"])

    dialogs.sort(key=lambda d: (d["chapter"], d["id"]))
    return dialogs


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    shutil.copytree(SRC, OUT)

    factions = (DOCS / "FACTIONS_45_HEROES.md").read_text(encoding="utf-8")
    story = (DOCS / "STORY_6_CHAPTERS.md").read_text(encoding="utf-8")

    by_hero, flat = parse_hero_skills(factions)
    assert len(by_hero) >= 45, f"heroes with skills={len(by_hero)}"
    dialogs = parse_dialogs(story)
    assert len(dialogs) >= 40, f"dialogs={len(dialogs)}"

    skills_doc = {
        "schema": 1,
        "disclaimer": "C5 DEMO · коэффициенты из канона; бой пока не считает серверные эффекты",
        "ai_priority": [
            "save_ally_hp_lt_35",
            "ultimate_ready",
            "control_threat",
            "active_skill",
            "basic_attack",
        ],
        "heroes": {
            hid: {
                "skill_ids": data["skills"],
                "quote": data.get("quote", ""),
                "personality": data.get("personality", ""),
            }
            for hid, data in by_hero.items()
        },
        "cards": list(flat.values()),
    }
    (OUT / "skills.json").write_text(json.dumps(skills_doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    dialogs_doc = {
        "schema": 1,
        "disclaimer": "C5 DEMO · катсцены без блокирующего выбора; оба варианта = один этап",
        "choice_policy": "cosmetic_journal_only",
        "dialogs": dialogs,
        "index_by_stage": {},
    }
    idx: dict[str, list[str]] = {}
    for d in dialogs:
        sid = d.get("stage_id")
        if not sid:
            continue
        idx.setdefault(sid, []).append(d["id"])
    dialogs_doc["index_by_stage"] = idx
    (OUT / "dialogs.json").write_text(json.dumps(dialogs_doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # wire skill ids into heroes.json
    heroes = json.loads((OUT / "heroes.json").read_text(encoding="utf-8"))
    for h in heroes["heroes"]:
        hid = h["id"]
        if hid in by_hero:
            h["skills"] = by_hero[hid]["skills"]
            h["quote"] = by_hero[hid].get("quote", "")
            h["personality"] = by_hero[hid].get("personality", "")
    (OUT / "heroes.json").write_text(json.dumps(heroes, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    strings = json.loads((OUT / "strings.json").read_text(encoding="utf-8"))
    strings["entries"].update({
        "skills.title": "Навыки",
        "dialogs.title": "Диалог",
        "c5.demo": "C5 DEMO · навыки и сюжетные сцены",
    })
    (OUT / "strings.json").write_text(json.dumps(strings, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    file_list = [f.name for f in sorted(OUT.glob("*.json")) if f.name != "manifest.json"]
    hashes = {f: hashlib.sha256((OUT / f).read_bytes()).hexdigest() for f in file_list}
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    manifest = {
        "id": "lunex-core",
        "version": "0.8.0",
        "schema": 9,
        "client_min": "0.1.0",
        "title": "Razlom Epoh · C5 skills + dialogs",
        "locale": "ru",
        "created_at": now,
        "updated_at": now,
        "notes": "C5: 45×5 skill cards + story dialog beats. Battle still DEMO.",
        "files": {f: {"role": f.replace(".json", "")} for f in file_list},
        "integrity": {"algo": "sha256", "hashes": hashes},
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    active = {
        "version": "0.8.0",
        "source": "content-c-c5",
        "note": "Клиент читает только опубликованный пакет. Прогресс игрока сюда не пишется.",
        "published_at": now,
    }
    (ROOT / "content/packages/active.json").write_text(json.dumps(active, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # previous C4 generator should not clobber — patch note separately
    print(f"Wrote {OUT}")
    print(f" heroes_skills={len(by_hero)} cards={len(flat)} dialogs={len(dialogs)}")


if __name__ == "__main__":
    main()
