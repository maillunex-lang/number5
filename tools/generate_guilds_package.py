#!/usr/bin/env python3
"""Build content package 0.5.0: guilds / async coop raids.

Order: after E0–E4 (currencies/materials) and P0–P2 (tower/dungeons referenced by
guild quests). Uses existing B* bosses. Real multiplayer waits for CORE-01 (G3+).
"""
from __future__ import annotations

import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "content/packages/0.4.0"
OUT = ROOT / "content/packages/0.5.0"

LEVEL_XP = [0, 1000, 2500, 4500, 7000, 10000, 14000, 19000, 25000, 32000]
CAPACITY = {1: 20, 2: 20, 3: 22, 4: 22, 5: 25, 6: 25, 7: 28, 8: 28, 9: 30, 10: 30}

RAID_TIERS = [
    ("I", "Часовой архив Уфы", 1, 1_000_000, 5, 60, 1, "B01-01"),
    ("II", "Каменная клятва Шиханов", 3, 3_000_000, 8, 80, 2, "B02-01"),
    ("III", "Стальное сердце Белорецка", 5, 8_000_000, 12, 110, 3, "B03-01"),
    ("IV", "Реактор 2050", 7, 18_000_000, 16, 140, 4, "B04-01"),
    ("V", "Парадокс Иремеля", 9, 40_000_000, 20, 180, 5, "B05-01"),
]

SHOP = [
    ("guild_gold", 60, [{"resource_id": "gold", "amount": 15000}], 5),
    ("guild_xp", 80, [{"resource_id": "hero_xp", "amount": 10000}], 5),
    ("guild_essence", 100, [{"resource_id": "essence", "amount": 400}], 5),
    ("guild_ore", 90, [{"resource_id": "ore", "amount": 15}], 3),
    ("guild_skill", 120, [{"resource_id": "skill_book", "amount": 2}], 3),
    ("guild_boss_core", 150, [{"resource_id": "boss_core", "amount": 2}], 2),
    ("guild_summon", 250, [{"resource_id": "summon_scroll", "amount": 1}], 2),
    ("guild_faction", 500, [{"resource_id": "faction_scroll", "amount": 1}], 1),
    ("guild_avatar_frame", 400, [{"resource_id": "cosmetic_frame", "amount": 1, "item_id": "guild_frame"}], 0),
    ("guild_emblem_color", 300, [{"resource_id": "cosmetic_token", "amount": 1, "item_id": "guild_emblem_color"}], 0),
]

DAILY_QUESTS = [
    ("GQ_D01", "Победить 3 раза в кампании", "campaign_wins_3", 30, [{"resource_id": "gold", "amount": 3000}], 40),
    ("GQ_D02", "Собрать AFK-награду", "afk_claim_1", 20, [{"resource_id": "hero_xp", "amount": 1500}], 30),
    ("GQ_D03", "Улучшить героя или навык 1 раз", "upgrade_1", 25, [{"resource_id": "essence", "amount": 100}], 35),
    ("GQ_D04", "Победить в 1 подземелье", "dungeon_win_1", 25, [{"resource_id": "ore", "amount": 4}], 35),
    ("GQ_D05", "Провести 1 бой с рейдовым боссом", "raid_attempt_1", 40, [{"resource_id": "boss_core", "amount": 1}], 60),
    ("GQ_D06", "Завершить 1 экспедицию", "expedition_1", 25, [{"resource_id": "essence", "amount": 100}], 35),
    ("GQ_D07", "Победить 1 босса кампании или PvE", "boss_win_1", 30, [{"resource_id": "skill_book", "amount": 1}], 45),
    ("GQ_D08", "Пройти 1 новый этаж Башни", "tower_new_floor_1", 30, [{"resource_id": "hero_xp", "amount": 1500}], 45),
]


def build_guilds(boss_ids: set[str]) -> dict:
    levels = []
    for lv in range(1, 11):
        levels.append({
            "level": lv,
            "xp_required": LEVEL_XP[lv - 1],
            "capacity": CAPACITY[lv],
            "unlocks": {
                1: ["chat", "quests", "raid_I"],
                2: ["emblem_frame_extra"],
                3: ["raid_II", "capacity_+2"],
                4: ["announcement_slot"],
                5: ["raid_III", "capacity_+3"],
                6: ["hq_theme"],
                7: ["raid_IV", "capacity_+3"],
                8: ["guild_title"],
                9: ["raid_V", "capacity_+2"],
                10: ["season_emblem", "cosmetic_frame"],
            }.get(lv, []),
        })

    raids = []
    for tier, name, guild_lv, hp, active, tokens, cores, boss in RAID_TIERS:
        assert boss in boss_ids, boss
        raids.append({
            "tier": tier,
            "name": name,
            "guild_level_required": guild_lv,
            "shared_hp": hp,
            "recommended_active_members": active,
            "boss_id": boss,
            "minions": 2,
            "participation_reward": [
                {"resource_id": "guild_token", "amount": tokens},
                {"resource_id": "boss_core", "amount": cores},
            ],
            "modifiers_pool": ["shield_up", "energy_suppress", "rift_wave", "summon_minion", "enrage_50"],
            "max_active_modifiers": 2,
        })

    shop = []
    for sku, price, grants, weekly in SHOP:
        shop.append({
            "sku": sku,
            "price_guild_token": price,
            "grants": grants,
            "weekly_limit": weekly if weekly > 0 else None,
            "lifetime_limit": 1 if weekly == 0 else None,
        })

    quests = []
    for qid, title, cond, tokens, extra, gxp in DAILY_QUESTS:
        rewards = [{"resource_id": "guild_token", "amount": tokens}] + extra
        quests.append({
            "id": qid, "name": title, "condition": cond,
            "rewards": rewards, "guild_xp": gxp,
        })

    return {
        "schema_version": 1,
        "mode": "DEMO_SANDBOX",
        "disclaimer": "Гильдии — асинхронный DEMO. Общий HP рейда и членство авторитетны только на сервере.",
        "unlock_stage": "CH01-20",
        "account_level_min": 15,
        "reset": {"timezone": "Europe/Moscow", "hour": 6, "week_start": "monday"},
        "create_cost_gold": 10000,
        "name_len": [3, 24],
        "tag_len": [2, 5],
        "starting_capacity": 20,
        "max_capacity": 30,
        "max_level": 10,
        "levels": levels,
        "roles": ["leader", "deputy", "officer", "member", "recruit"],
        "max_deputies": 2,
        "max_officers": 4,
        "join_policies": ["open", "apply", "closed"],
        "cooldowns": {
            "rejoin_hours": 24,
            "create_days": 7,
            "applications_per_day": 5,
            "invites_per_day": 10,
        },
        "contributions": [
            {"gold": 5000, "guild_token": 30, "guild_xp": 50},
            {"gold": 15000, "guild_token": 70, "guild_xp": 100},
            {"gold": 30000, "guild_token": 120, "guild_xp": 160},
        ],
        "contribution_rules": {
            "mutually_exclusive_per_day": True,
            "max_guild_xp_from_contribute_per_day": 160,
            "forbidden_resources": ["diamonds", "vip_xp", "summon_scroll"],
        },
        "daily_quests": quests,
        "daily_quest_board_size": 5,
        "weekly_goals": [
            {"id": "wg_quests_100", "condition": "personal_quests_100", "base": 100, "guild_xp": 2000},
            {"id": "wg_raid_30", "condition": "raid_battles_30", "base": 30, "guild_xp": 1500},
            {"id": "wg_expeditions_50", "condition": "expeditions_50", "base": 50, "guild_xp": 1000},
            {"id": "wg_campaign_150", "condition": "campaign_wins_150", "base": 150, "guild_xp": 1500},
        ],
        "weekly_goal_scale": "max(30, ceil(base * active_members/15))",
        "raids": {
            "duration_hours": 72,
            "weekly_launch_limit": 2,
            "daily_attempts_per_member": 2,
            "max_attempts_per_raid": 6,
            "party_size": 5,
            "battle_duration_seconds": 90,
            "shared_hp": True,
            "milestones": [
                {"hp_bp": 2500, "guild_xp": 100, "rewards": [{"resource_id": "guild_token", "amount": 30}, {"resource_id": "essence", "amount": 100}]},
                {"hp_bp": 5000, "guild_xp": 150, "rewards": [{"resource_id": "guild_token", "amount": 40}, {"resource_id": "skill_book", "amount": 1}]},
                {"hp_bp": 7500, "guild_xp": 200, "rewards": [{"resource_id": "guild_token", "amount": 50}, {"resource_id": "boss_core", "amount": 1}]},
                {"hp_bp": 10000, "guild_xp": 400, "rewards": [{"resource_id": "guild_token", "amount": 80}, {"resource_id": "set_pattern", "amount": 1}, {"resource_id": "cosmetic_token", "amount": 100}]},
            ],
            "tiers": raids,
            "rotation_weeks": [
                {"week": 1, "themes": ["Уфа", "Шиханы"], "boss_chapters": [1, 2]},
                {"week": 2, "themes": ["Белорецк"], "boss_chapters": [3]},
                {"week": 3, "themes": ["Стерлитамак 2050"], "boss_chapters": [4]},
                {"week": 4, "themes": ["Иремель", "Разлом"], "boss_chapters": [5, 6]},
            ],
        },
        "shop": {
            "currency_id": "guild_token",
            "real_money_enabled": False,
            "offers": shop,
        },
        "emblem": {
            "symbols": 12,
            "colors": 8,
            "frames": 4,
            "no_custom_uploads": True,
        },
        "chat": {
            "tabs": ["general", "announcements", "events"],
            "max_chars": 300,
            "rate_limit_sec": 3,
            "max_per_hour": 60,
            "attachments": False,
            "mvp_text_only": True,
        },
        "season_ranking": {
            "enabled": False,
            "status": "soon",
            "duration_days": 28,
            "note": "Включить после античита/QA. Награды только косметика.",
        },
        "demo": {
            "guild": {
                "id": "demo_ufa_keepers",
                "name": "Хранители Уфы",
                "tag": "UFA",
                "level": 3,
                "xp": 2600,
                "members": 8,
                "join_policy": "open",
                "announcement": "Рейд I по понедельникам. Без доната. DEMO.",
            },
            "wallet_guild_token": 180,
        },
    }


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    shutil.copytree(SRC, OUT)

    enemies = json.loads((OUT / "enemies.json").read_text(encoding="utf-8"))
    boss_ids = {b["id"] for b in enemies["bosses"]}
    guilds = build_guilds(boss_ids)
    (OUT / "guilds.json").write_text(json.dumps(guilds, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # Add guild_token to economy currencies if missing
    eco = json.loads((OUT / "economy.json").read_text(encoding="utf-8"))
    cur_ids = {c["id"] for c in eco["currencies"]}
    if "guild_token" not in cur_ids:
        eco["currencies"].append({
            "id": "guild_token", "name": "Гильдейский жетон", "premium": False,
            "note": "Персональный; не передаётся между аккаунтами",
        })
    if "guild_xp" not in cur_ids:
        eco["currencies"].append({
            "id": "guild_xp", "name": "Опыт гильдии", "premium": False, "spendable": False,
        })
    (OUT / "economy.json").write_text(json.dumps(eco, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    strings = json.loads((OUT / "strings.json").read_text(encoding="utf-8"))
    strings["entries"].update({
        "guild.title": "Гильдия",
        "guild.hub": "Штаб",
        "guild.raids": "Врата Разлома",
        "guild.shop": "Склад знаков",
        "guild.quests": "Доска поручений",
        "guild.demo": "DEMO · без онлайна",
    })
    (OUT / "strings.json").write_text(json.dumps(strings, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    file_list = [f.name for f in sorted(OUT.glob("*.json")) if f.name != "manifest.json"]
    hashes = {f: hashlib.sha256((OUT / f).read_bytes()).hexdigest() for f in file_list}
    manifest = {
        "id": "lunex-core",
        "version": "0.5.0",
        "schema": 6,
        "client_min": "0.1.0",
        "title": "Razlom Epoh · guilds + async raids (DEMO)",
        "locale": "ru",
        "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "updated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "notes": "G0–G2 after E0–E4 and P0–P2. Server membership/raid HP = CORE-01.",
        "files": {f: {"role": f.replace(".json", "")} for f in file_list},
        "integrity": {"algo": "sha256", "hashes": hashes},
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    active = {
        "version": "0.5.0",
        "source": "content-c-guilds",
        "note": "Клиент читает только опубликованный пакет. Прогресс игрока сюда не пишется.",
        "published_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    (ROOT / "content/packages/active.json").write_text(json.dumps(active, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT}")
    print(f" raids={len(guilds['raids']['tiers'])} shop={len(guilds['shop']['offers'])} quests={len(guilds['daily_quests'])}")


if __name__ == "__main__":
    main()
