#!/usr/bin/env python3
"""Build content package 0.3.0: economy spine + progression/loot + gacha + liveops.
Order: currencies → progression/loot → gacha → AFK/quests/expeditions → shop/VIP.
"""
from __future__ import annotations

import hashlib
import json
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "content/packages/0.2.0"
OUT = ROOT / "content/packages/0.3.0"
DOCS = ROOT / "docs/content"

CURRENCIES = [
    {"id": "gold", "name": "Золото", "premium": False},
    {"id": "diamonds", "name": "Алмазы", "premium": True},
    {"id": "hero_xp", "name": "Опыт героя", "premium": False},
    {"id": "essence", "name": "Эссенция", "premium": False},
    {"id": "summon_scroll", "name": "Свиток призыва", "premium": False},
    {"id": "faction_scroll", "name": "Фракционный свиток", "premium": False},
    {"id": "time_shard", "name": "Осколок времени", "premium": False},
    {"id": "arena_token", "name": "Знак арены", "premium": False},
    {"id": "cosmetic_token", "name": "Печать облика", "premium": False},
    {"id": "afk_hour", "name": "Купон AFK", "premium": False},
    {"id": "vip_xp", "name": "Очки VIP", "premium": False, "spendable": False},
    {"id": "ore", "name": "Руда", "premium": False},
    {"id": "class_seal", "name": "Знак класса", "premium": False},
    {"id": "skill_book", "name": "Книга умений", "premium": False},
    {"id": "boss_core", "name": "Ядро босса", "premium": False},
    {"id": "set_pattern", "name": "Чертёж сета", "premium": False},
    {"id": "reforge_stone", "name": "Камень перековки", "premium": False},
    {"id": "artifact_fragment", "name": "Фрагмент артефакта", "premium": False},
]

SETS = [
    {"id": "SET01", "name": "Печати Первого Часа", "chapter": 1, "theme_faction": "F01",
     "bonuses": [{"pieces": 2, "effect_id": "hp_percent", "value_bp": 400},
                 {"pieces": 4, "effect_id": "first_low_hp_shield", "threshold_bp": 4000, "shield_bp": 800, "duration_ms": 5000, "max_uses": 1}]},
    {"id": "SET02", "name": "Следопыты Трёх Дорог", "chapter": 1, "theme_faction": "F02",
     "bonuses": [{"pieces": 2, "effect_id": "spd_flat", "value": 3},
                 {"pieces": 4, "effect_id": "after_3_aa_atk", "value_bp": 500, "duration_ms": 6000}]},
    {"id": "SET03", "name": "Каменные Свидетели", "chapter": 2, "theme_faction": "F04",
     "bonuses": [{"pieces": 2, "effect_id": "def_percent", "value_bp": 600}, {"pieces": 4, "effect_id": "block_counter", "atk_bp": 5000, "cd_ms": 8000}]},
    {"id": "SET04", "name": "Эхо Древнего Леса", "chapter": 2, "theme_faction": "F02",
     "bonuses": [{"pieces": 2, "effect_id": "hp_percent", "value_bp": 500}, {"pieces": 4, "effect_id": "heal_taken", "value_bp": 600}]},
    {"id": "SET05", "name": "Кузнечный Завет", "chapter": 3, "theme_faction": "F04",
     "bonuses": [{"pieces": 2, "effect_id": "atk_percent", "value_bp": 500}, {"pieces": 4, "effect_id": "vs_shield", "value_bp": 700}]},
    {"id": "SET06", "name": "Шестерни Предела", "chapter": 3, "theme_faction": "F03",
     "bonuses": [{"pieces": 2, "effect_id": "accuracy", "value_bp": 500}, {"pieces": 4, "effect_id": "every_5_hit_energy", "value": 80}]},
    {"id": "SET07", "name": "Протокол 2050", "chapter": 4, "theme_faction": "F03",
     "bonuses": [{"pieces": 2, "effect_id": "atk_percent", "value_bp": 600}, {"pieces": 4, "effect_id": "first_ult_damage", "value_bp": 800}]},
    {"id": "SET08", "name": "Контур Безмолвия", "chapter": 4, "theme_faction": "F05",
     "bonuses": [{"pieces": 2, "effect_id": "dodge", "value_bp": 400}, {"pieces": 4, "effect_id": "after_dodge_atk", "value_bp": 800, "cd_ms": 10000}]},
    {"id": "SET09", "name": "Тени Иремеля", "chapter": 5, "theme_faction": "F05",
     "bonuses": [{"pieces": 2, "effect_id": "crit_chance", "value_bp": 400}, {"pieces": 4, "effect_id": "crit_energy", "value": 20, "cd_ms": 3000}]},
    {"id": "SET10", "name": "Клятва Хранителя", "chapter": 5, "theme_faction": "F06",
     "bonuses": [{"pieces": 2, "effect_id": "heal_power", "value_bp": 600}, {"pieces": 4, "effect_id": "low_hp_heal_boost", "value_bp": 1200}]},
    {"id": "SET11", "name": "Сердце Разлома", "chapter": 6, "theme_faction": "F06",
     "bonuses": [{"pieces": 2, "effect_id": "hp_percent", "value_bp": 600}, {"pieces": 4, "effect_id": "battle_start_shield", "shield_bp": 500, "duration_ms": 8000}]},
    {"id": "SET12", "name": "Парадокс Нулевого Часа", "chapter": 6, "theme_faction": "F01",
     "bonuses": [{"pieces": 2, "effect_id": "atk_percent", "value_bp": 600}, {"pieces": 4, "effect_id": "after_ult_resist", "value_bp": 500, "duration_ms": 6000}]},
]

SLOTS = ["weapon", "armor", "helmet", "boots", "acc"]
CLASSES = ["tank", "warrior", "assassin", "ranger", "mage", "support", "healer"]

OFFERS = [
    ("diamond_s", "Малый запас алмазов", [{"resource_id": "diamonds", "amount": 300}], 59, "repeatable", {"per_day": 3}, 0),
    ("diamond_m", "Шкатулка алмазов", [{"resource_id": "diamonds", "amount": 850}], 149, "repeatable", {"per_day": 2}, 0),
    ("diamond_l", "Сундук алмазов", [{"resource_id": "diamonds", "amount": 1900}], 299, "repeatable", {"per_day": 1}, 0),
    ("diamond_xl", "Хранилище алмазов", [{"resource_id": "diamonds", "amount": 4300}], 599, "repeatable", {"per_week": 1}, 0),
    ("starter_ufa", "Набор первопроходца Уфы",
     [{"resource_id": "diamonds", "amount": 600}, {"resource_id": "summon_scroll", "amount": 10},
      {"resource_id": "gold", "amount": 100000}, {"resource_id": "hero_xp", "amount": 20000}], 199, "once", {"lifetime": 1}, 100),
    ("chapter_1", "Комплект Разлома: Уфа",
     [{"resource_id": "diamonds", "amount": 400}, {"resource_id": "essence", "amount": 1200},
      {"resource_id": "summon_scroll", "amount": 5}], 149, "once", {"after_stage": "CH01-10"}, 80),
    ("daily_supplies", "Ежедневные припасы",
     [{"resource_id": "gold", "amount": 50000}, {"resource_id": "hero_xp", "amount": 12000},
      {"resource_id": "essence", "amount": 400}], 49, "daily", {"per_day": 1}, 10),
    ("weekly_expedition", "Недельная экспедиция",
     [{"resource_id": "diamonds", "amount": 500}, {"resource_id": "summon_scroll", "amount": 6},
      {"resource_id": "afk_hour", "amount": 4}], 199, "weekly", {"per_week": 1}, 60),
    ("monthly_archive", "Архив Хранителя",
     [{"resource_id": "diamonds", "amount": 1200}, {"resource_id": "summon_scroll", "amount": 10},
      {"resource_id": "essence", "amount": 2500}], 499, "monthly", {"per_30d": 1}, 150),
    ("summon_10", "Десять свитков", [{"resource_id": "summon_scroll", "amount": 10}], 199, "repeatable", {"per_week": 2}, 30),
    ("faction_5", "Пять фракционных свитков", [{"resource_id": "faction_scroll", "amount": 5}], 249, "repeatable", {"per_week": 1}, 40),
    ("cosmetic_frame_ufa", "Рамка «Ночная Уфа»", [{"resource_id": "cosmetic_frame", "amount": 1, "item_id": "ufa_night"}], 99, "once", {"lifetime": 1}, 0),
    ("battlepass_premium_s01", "Премиум «Хроники Разлома»", [{"resource_id": "battlepass_premium", "amount": 1, "season": "s01"}], 499, "once", {"per_season": 1}, 100),
]

SUBS = [
    {"id": "sub_moon", "name": "Лунный пропуск", "days": 30, "nominal_rub": 299,
     "grant_now": [{"resource_id": "diamonds", "amount": 300}],
     "daily": [{"resource_id": "diamonds", "amount": 100}],
     "perks": ["afk_expedition_slot_+1", "cosmetic_badge_moon"]},
    {"id": "sub_guardian", "name": "Клятва Хранителя", "days": 30, "nominal_rub": 599,
     "grant_now": [{"resource_id": "diamonds", "amount": 650}, {"resource_id": "summon_scroll", "amount": 5}],
     "daily": [{"resource_id": "diamonds", "amount": 150}, {"resource_id": "afk_hour", "amount": 1}],
     "perks": ["squad_preset_+2", "frame_guardian"]},
    {"id": "sub_archivist", "name": "Архивариус эпох", "days": 30, "nominal_rub": 899,
     "grant_now": [{"resource_id": "diamonds", "amount": 1000}, {"resource_id": "summon_scroll", "amount": 8}],
     "daily": [{"resource_id": "diamonds", "amount": 200}, {"resource_id": "cosmetic_token", "amount": 100}],
     "perks": ["history_extended", "title_archivist"]},
]

VIP = [
    (0, 0, "Базовый доступ", []),
    (1, 100, "Рамка профиля I", [{"resource_id": "diamonds", "amount": 100}]),
    (2, 300, "+1 пресет отряда", [{"resource_id": "summon_scroll", "amount": 2}]),
    (3, 650, "Уникальная иконка профиля", [{"resource_id": "diamonds", "amount": 150}]),
    (4, 1100, "+1 пресет отряда", [{"resource_id": "summon_scroll", "amount": 3}]),
    (5, 1700, "Рамка профиля II", [{"resource_id": "diamonds", "amount": 200}]),
    (6, 2500, "+1 сохранённый фильтр коллекции", [{"resource_id": "summon_scroll", "amount": 5}]),
    (7, 3500, "Косметический титул", [{"resource_id": "diamonds", "amount": 250}]),
    (8, 4800, "Рамка профиля III", [{"resource_id": "faction_scroll", "amount": 5}]),
    (9, 6500, "+1 слот пресета отряда", [{"resource_id": "diamonds", "amount": 300}]),
    (10, 8500, "Анимированный аватар", [{"resource_id": "summon_scroll", "amount": 8}]),
    (11, 11000, "Рамка Хранителя эпох",
     [{"resource_id": "diamonds", "amount": 500}, {"resource_id": "cosmetic_token", "amount": 100}]),
]

BP_LEVELS_RAW = """
01 gold:12500 diamonds:90
02 hero_xp:2800 summon_scroll:2
03 essence:145 cosmetic_token:35
04 summon_scroll:1 faction_scroll:1
05 diamonds:55 diamonds:150
06 gold:25000 diamonds:140
07 hero_xp:4800 summon_scroll:2
08 essence:220 cosmetic_token:60
09 summon_scroll:1 faction_scroll:1
10 diamonds:80 diamonds:200
11 gold:37500 diamonds:190
12 hero_xp:6800 summon_scroll:3
13 essence:295 cosmetic_token:85
14 summon_scroll:2 faction_scroll:1
15 diamonds:105 diamonds:250
16 gold:50000 diamonds:240
17 hero_xp:8800 summon_scroll:3
18 essence:370 cosmetic_token:110
19 summon_scroll:2 faction_scroll:2
20 diamonds:130 diamonds:300
21 gold:62500 diamonds:290
22 hero_xp:10800 summon_scroll:4
23 essence:445 cosmetic_token:135
24 summon_scroll:3 faction_scroll:2
25 diamonds:155 diamonds:350
26 gold:75000 diamonds:340
27 hero_xp:12800 summon_scroll:4
28 essence:520 cosmetic_token:160
29 summon_scroll:3 faction_scroll:2
30 diamonds:180 diamonds:500
"""

DAILY_QUESTS = [
    {"id": "dq_login", "name": "Первый свет Уфы", "condition": "login_1", "rewards": [{"resource_id": "gold", "amount": 1500}, {"resource_id": "hero_xp", "amount": 500}], "unlock": "always"},
    {"id": "dq_campaign_3", "name": "Три шага через Разлом", "condition": "campaign_wins_3", "rewards": [{"resource_id": "gold", "amount": 3000}, {"resource_id": "essence", "amount": 60}], "unlock": "CH01-05"},
    {"id": "dq_campaign_5", "name": "Дорога не кончается", "condition": "campaign_wins_5", "rewards": [{"resource_id": "hero_xp", "amount": 1500}, {"resource_id": "gold", "amount": 2000}], "unlock": "CH01-05"},
    {"id": "dq_afk", "name": "Сбор без суеты", "condition": "afk_claim_1", "rewards": [{"resource_id": "gold", "amount": 2000}, {"resource_id": "essence", "amount": 40}], "unlock": "CH01-05"},
    {"id": "dq_upgrade_hero", "name": "Герой растёт", "condition": "hero_level_up_1", "rewards": [{"resource_id": "hero_xp", "amount": 1200}, {"resource_id": "gold", "amount": 1000}], "unlock": "CH01-05"},
    {"id": "dq_upgrade_gear", "name": "Пыль кузницы", "condition": "equipment_upgrade_1", "rewards": [{"resource_id": "ore", "amount": 5}, {"resource_id": "gold", "amount": 1500}], "unlock": "CH01-10"},
    {"id": "dq_summon", "name": "Зов Плетения", "condition": "summon_1", "rewards": [{"resource_id": "diamonds", "amount": 25}, {"resource_id": "gold", "amount": 1500}], "unlock": "altar"},
    {"id": "dq_expedition", "name": "Послать разведку", "condition": "expedition_1", "rewards": [{"resource_id": "essence", "amount": 80}, {"resource_id": "gold", "amount": 1000}], "unlock": "CH01-10"},
    {"id": "dq_boss", "name": "Разговор с начальством", "condition": "boss_win_1", "rewards": [{"resource_id": "essence", "amount": 100}, {"resource_id": "hero_xp", "amount": 1000}], "unlock": "CH01-10"},
    {"id": "dq_equipment", "name": "Найти применение", "condition": "equip_1", "rewards": [{"resource_id": "gold", "amount": 1000}, {"resource_id": "ore", "amount": 3}], "unlock": "first_item"},
    {"id": "dq_collect", "name": "Учёт ценностей", "condition": "claim_3_sources", "rewards": [{"resource_id": "gold", "amount": 2500}, {"resource_id": "hero_xp", "amount": 1000}], "unlock": "CH01-05"},
    {"id": "dq_team", "name": "Перестановка кадров", "condition": "squad_preset_1", "rewards": [{"resource_id": "gold", "amount": 1500}, {"resource_id": "essence", "amount": 40}], "unlock": "presets"},
]

WEEKLY_QUESTS = [
    {"id": "wq_battles_20", "condition": "campaign_wins_20", "rewards": [{"resource_id": "gold", "amount": 12000}, {"resource_id": "essence", "amount": 300}]},
    {"id": "wq_boss_3", "condition": "boss_wins_3", "rewards": [{"resource_id": "hero_xp", "amount": 8000}, {"resource_id": "ore", "amount": 20}]},
    {"id": "wq_summon_5", "condition": "summon_results_5", "rewards": [{"resource_id": "summon_scroll", "amount": 2}, {"resource_id": "gold", "amount": 5000}]},
    {"id": "wq_afk_24h", "condition": "afk_hours_24", "rewards": [{"resource_id": "diamonds", "amount": 80}, {"resource_id": "essence", "amount": 250}]},
    {"id": "wq_expeditions_8", "condition": "expeditions_8", "rewards": [{"resource_id": "faction_scroll", "amount": 1}, {"resource_id": "gold", "amount": 10000}]},
    {"id": "wq_upgrades_10", "condition": "upgrades_10", "rewards": [{"resource_id": "ore", "amount": 25}, {"resource_id": "hero_xp", "amount": 5000}]},
    {"id": "wq_campaign_new_5", "condition": "first_clear_5", "rewards": [{"resource_id": "diamonds", "amount": 100}, {"resource_id": "summon_scroll", "amount": 1}]},
    {"id": "wq_faction_3", "condition": "faction_expeditions_3", "rewards": [{"resource_id": "essence", "amount": 400}, {"resource_id": "gold", "amount": 8000}]},
]

EXPEDITIONS = [
    ("EXP-01-01", "Фонари на набережной", 1, "short", "F01", "ranger", 1300),
    ("EXP-01-02", "Потерянная ведомость", 1, "medium", "F01", "tank", 1600),
    ("EXP-01-03", "Ночная опись", 1, "long", "F01", "warrior", 1900),
    ("EXP-02-01", "Руническая тропа", 2, "short", "F02", "tank", 2300),
    ("EXP-02-02", "Каменные дозорные", 2, "medium", "F02", "warrior", 2600),
    ("EXP-02-03", "Шёпот пластов", 2, "long", "F02", "mage", 2900),
    ("EXP-03-01", "Угольный маршрут", 3, "short", "F04", "warrior", 3300),
    ("EXP-03-02", "Сломанный пресс", 3, "medium", "F04", "mage", 3600),
    ("EXP-03-03", "Смена без конца", 3, "long", "F04", "assassin", 3900),
    ("EXP-04-01", "Сбой терминала", 4, "short", "F03", "mage", 4300),
    ("EXP-04-02", "Архивный дрон", 4, "medium", "F03", "assassin", 4600),
    ("EXP-04-03", "Тихий протокол", 4, "long", "F03", "healer", 4900),
    ("EXP-05-01", "Снежная печать", 5, "short", "F05", "assassin", 5300),
    ("EXP-05-02", "Следы на перевале", 5, "medium", "F05", "healer", 5600),
    ("EXP-05-03", "Холодный караул", 5, "long", "F05", "ranger", 5900),
    ("EXP-06-01", "Секунда до полуночи", 6, "short", "F06", "healer", 6300),
    ("EXP-06-02", "Потерянная эпоха", 6, "medium", "F06", "ranger", 6600),
    ("EXP-06-03", "Парадоксальная вахта", 6, "long", "F06", "tank", 6900),
]

TIER_DURATION = {"short": 7200, "medium": 14400, "long": 28800}
TIER_REWARDS = {
    "short": [{"resource_id": "gold", "amount": 2500}, {"resource_id": "hero_xp", "amount": 900}],
    "medium": [{"resource_id": "gold", "amount": 6000}, {"resource_id": "hero_xp", "amount": 2200}, {"resource_id": "essence", "amount": 90}],
    "long": [{"resource_id": "gold", "amount": 14000}, {"resource_id": "hero_xp", "amount": 5200}, {"resource_id": "essence", "amount": 240}],
}
CHAPTER_MULT = {1: 1.0, 2: 1.4, 3: 1.8, 4: 2.3, 5: 2.9, 6: 3.6}
SPECIAL = {1: "summon_scroll", 2: "class_seal", 3: "skill_book", 4: "reforge_stone", 5: "faction_scroll", 6: "artifact_fragment"}


def parse_grant(s: str) -> list[dict]:
    out = []
    for part in s.split(","):
        part = part.strip()
        if not part:
            continue
        if ":" not in part:
            continue
        rid, amt = part.split(":", 1)
        if rid == "skin":
            out.append({"resource_id": "skin", "amount": 1, "item_id": amt})
        else:
            out.append({"resource_id": rid, "amount": int(amt)})
    return out


def build_battlepass() -> dict:
    levels = []
    for line in BP_LEVELS_RAW.strip().splitlines():
        parts = line.split()
        n = int(parts[0])
        free = parse_grant(parts[1])
        prem = parse_grant(parts[2])
        # level 30 premium special
        if n == 30:
            prem = [{"resource_id": "skin", "amount": 1, "item_id": "season_rift_s01"},
                    {"resource_id": "diamonds", "amount": 500}]
        levels.append({"level": n, "xp_required": n * 100, "free": free, "premium": prem})
    return {
        "id": "s01",
        "name": "Хроники Разлома",
        "duration_days": 28,
        "xp_per_level": 100,
        "max_level": 30,
        "sku_premium": "battlepass_premium_s01",
        "levels": levels,
        "pass_xp_sources": {
            "daily_login": 20, "daily_campaign": 30, "daily_afk": 20, "daily_upgrade": 20,
            "weekly_campaign": 120, "weekly_boss": 100, "weekly_summon": 80, "season_story": 250,
        },
    }


def build_economy() -> dict:
    offers = []
    for sku, title, grants, nominal, typ, limits, vip_xp in OFFERS:
        offers.append({
            "sku": sku, "title": title, "nominal_price_rub": nominal, "payable_price_rub": 0,
            "type": typ, "grants": grants, "vip_xp": vip_xp, "limits": limits, "enabled": True,
            "cta": "Получить бесплатно (тест)",
        })
    # chapter packs 2-6 abbreviated
    for i, (sku, title, dia, ess, vip) in enumerate([
        ("chapter_2", "Каменные свидетели", 500, 1600, 90),
        ("chapter_3", "Железное сердце", 600, 2200, 110),
        ("chapter_4", "Стерлитамак 2050", 700, 2800, 130),
        ("chapter_5", "Тени Иремеля", 800, 3500, 150),
        ("chapter_6", "Сердце Разлома", 1000, 0, 180),
    ], start=2):
        grants = [{"resource_id": "diamonds", "amount": dia}]
        if ess:
            grants.append({"resource_id": "essence", "amount": ess})
        if i == 6:
            grants.append({"resource_id": "faction_scroll", "amount": 8})
            grants.append({"resource_id": "cosmetic_token", "amount": 100})
        offers.append({
            "sku": sku, "title": title, "nominal_price_rub": 149 + (i - 1) * 50,
            "payable_price_rub": 0, "type": "once", "grants": grants, "vip_xp": vip,
            "limits": {"after_stage": f"CH0{i}-10", "lifetime": 1}, "enabled": True,
            "cta": "Получить бесплатно (тест)",
        })
    return {
        "schema_version": 1,
        "mode": "VIRTUAL_FREE",
        "timezone": "Europe/Moscow",
        "disclaimer": "Тестовый магазин · Бесплатно · Реальные деньги не списываются",
        "currencies": CURRENCIES,
        "offers": offers,
        "subscriptions": SUBS,
        "vip_levels": [
            {"level": lv, "threshold_xp": thr, "perk": perk, "milestone_rewards": rew}
            for lv, thr, perk, rew in VIP
        ],
        "battle_pass": build_battlepass(),
        "categories": ["Рекомендуем", "Алмазы", "Наборы", "Подписки", "VIP", "Пропуск", "Косметика", "История"],
    }


def build_progression() -> dict:
    return {
        "schema_version": 1,
        "level_cap_default": 100,
        "level_cap_by_rarity": {"common": 60, "rare": 80, "epic": 100, "legendary": 100, "mythic": 100},
        "level_up": {
            "hero_xp_cost": "round(70 + 12*L + 0.65*L^2)",
            "gold_cost": "round(30 + 8*L + 0.28*L^2)",
        },
        "base_stat_growth": {
            "hp": "round(HP1*(1+0.075*(L-1)))",
            "atk": "round(ATK1*(1+0.060*(L-1)))",
            "def": "round(DEF1*(1+0.055*(L-1)))",
            "spd": "flat",
        },
        "breakthroughs": [
            {"at_level": 20, "essence": 150, "gold": 3000, "class_seal": 1},
            {"at_level": 40, "essence": 450, "gold": 9000, "class_seal": 2},
            {"at_level": 60, "essence": 1100, "gold": 24000, "class_seal": 3},
            {"at_level": 80, "essence": 2600, "gold": 60000, "class_seal": 5},
        ],
        "stars": {
            "max": 5,
            "shard_per_dupe": 30,
            "costs": [
                {"from": 1, "to": 2, "shards": 30, "gold": 2000},
                {"from": 2, "to": 3, "shards": 60, "gold": 5000},
                {"from": 3, "to": 4, "shards": 100, "gold": 12000},
                {"from": 4, "to": 5, "shards": 160, "gold": 30000},
            ],
            "stat_mult": {1: 1.00, 2: 1.05, 3: 1.11, 4: 1.18, 5: 1.26},
        },
        "skills": {
            "max_level": 5,
            "coefficient_per_level_bp": 400,
            "costs": [
                {"from": 1, "to": 2, "skill_book": 2, "gold": 1000},
                {"from": 2, "to": 3, "skill_book": 4, "gold": 3000},
                {"from": 3, "to": 4, "skill_book": 8, "gold": 8000},
                {"from": 4, "to": 5, "skill_book": 15, "gold": 18000},
            ],
        },
        "unlocks": {
            "equipment": "CH01-05",
            "stars": "CH01-10",
            "skills": "CH01-15",
            "sets": "CH02-01",
            "talents": "CH03-01",
            "bonds": "CH03-10",
            "artifact": "CH04-01",
        },
        "replay_rewards_per_day": 20,
        "replay_soft_cap_after": {"gold_bp": 2500, "xp_bp": 2500, "equipment": False},
        "day_reset_timezone": "Europe/Moscow",
        "day_reset_hour": 6,
    }


def build_equipment() -> dict:
    templates = []
    for slot in ["weapon", "armor", "helmet", "boots"]:
        for role in ["tank", "warrior", "assassin", "ranger", "mage", "support", "healer"]:
            templates.append({
                "id": f"eq_{slot}_{role}",
                "slot": slot,
                "allowed_roles": [role] if slot == "weapon" else CLASSES,
                "base_stats": {"hp": 40 if slot != "weapon" else 0, "atk": 20 if slot == "weapon" else 8, "def": 15 if slot in ("armor", "helmet") else 5},
                "placeholder": True,
            })
    templates.append({
        "id": "eq_acc_universal", "slot": "acc", "allowed_roles": CLASSES,
        "base_stats": {"hp": 20, "atk": 10, "def": 5}, "placeholder": True,
    })
    return {
        "schema_version": 1,
        "slots": SLOTS,
        "sets": SETS,
        "templates": templates,
        "upgrade": {"max_level": 15, "guaranteed": True},
        "craft": {
            "rare": {"ore": 20, "boss_core": 1, "gold": 5000},
            "epic": {"ore": 55, "boss_core": 3, "gold": 16000},
            "legendary": {"ore": 150, "boss_core": 8, "set_pattern": 1, "gold": 55000},
        },
        "note": "Экземпляры предметов — только в аккаунте (сервер). Здесь каталог.",
    }


def build_loot(campaign_stages: list[dict]) -> dict:
    quality = {
        "normal": {"any_item_bp": 1800, "common": 60, "uncommon": 30, "rare": 10, "epic": 0, "legendary": 0, "relic": 0},
        "elite": {"any_item_bp": 3200, "common": 15, "uncommon": 40, "rare": 35, "epic": 10, "legendary": 0, "relic": 0},
        "boss": {"any_item_bp": 5500, "common": 0, "uncommon": 10, "rare": 40, "epic": 35, "legendary": 14, "relic": 1},
        "secret": {"any_item_bp": 3500, "common": 0, "uncommon": 25, "rare": 45, "epic": 25, "legendary": 5, "relic": 0},
    }
    chapter_sets = {1: ["SET01", "SET02"], 2: ["SET03", "SET04"], 3: ["SET05", "SET06"],
                    4: ["SET07", "SET08"], 5: ["SET09", "SET10"], 6: ["SET11", "SET12"]}
    stage_loot = []
    for s in campaign_stages:
        sid = s["id"]
        n = int(sid.split("-")[1])
        ch = 1
        stype = s.get("stage_type", "normal")
        if stype == "main":
            stype = "normal"
        if stype == "story":
            stype = "normal"
        tier = 1
        sets = chapter_sets[1]
        entry = {
            "stage_id": sid,
            "loot_table_id": f"loot_ch01_{stype}",
            "equipment_tier": tier,
            "featured_sets": sets,
            "stage_kind": stype,
        }
        if n in (5, 15, 25):
            entry["first_clear"] = {"equipment_choice_token": 1, "gold": 5000 + n * 100, "hero_xp": 2000}
        elif n in (10, 20, 30):
            q = "rare" if n == 10 else "epic"
            cores = {10: 1, 20: 2, 30: 3}[n]
            entry["first_clear"] = {
                "equipment_quality": q, "boss_core": cores, "gold": 12000 + n * 200, "hero_xp": 5000,
            }
            if n == 30:
                entry["first_clear"]["set_pattern"] = 1
                entry["first_clear"]["choice_slot"] = True
            entry["loot_table_id"] = "loot_ch01_boss"
        else:
            entry["first_clear"] = {"gold": 2000 + n * 80, "hero_xp": 800 + n * 20}
        stage_loot.append(entry)
    return {
        "schema_version": 1,
        "quality_tables": quality,
        "pity": {"no_item_streak": 8, "guarantee_item": True},
        "replay_item_cap_per_day": 20,
        "chapter_sets": chapter_sets,
        "stage_bindings": stage_loot,
        "note": "CH01 полные привязки; CH02–06 добавляются в C4/E1b.",
    }


def build_gacha(heroes: list[dict]) -> dict:
    by_rarity = {"common": [], "rare": [], "epic": [], "legendary": [], "mythic": []}
    by_faction: dict[str, list] = {}
    for h in heroes:
        rid = h["id"]
        r = h.get("rarity", "common")
        by_rarity.setdefault(r, []).append(rid)
        fid = h.get("faction_id", "")
        by_faction.setdefault(fid, []).append(rid)

    def pool_filter(rarities: list[str], faction: str | None = None, include_ur: bool = True) -> dict:
        pools = {}
        for r in rarities:
            ids = list(by_rarity.get(r, []))
            if faction:
                ids = [i for i in ids if any(h["id"] == i and h.get("faction_id") == faction for h in heroes)]
            if r in ("mythic",) and not include_ur:
                ids = []
            # map mythic as UR
            key = "UR" if r == "mythic" else {"common": "N", "rare": "R", "epic": "SR", "legendary": "SSR"}.get(r, r)
            pools[key] = ids
        return pools

    rarity_map_weights = {
        "standard": {"N": 5000, "R": 3500, "SR": 1200, "SSR": 300, "UR": 0},
        "advanced": {"N": 3000, "R": 4000, "SR": 2200, "SSR": 700, "UR": 100},
        "faction": {"N": 3000, "R": 4000, "SR": 2200, "SSR": 700, "UR": 100},
        "event": {"N": 3000, "R": 4000, "SR": 2200, "SSR": 700, "UR": 100},
    }
    banners = [
        {
            "id": "standard",
            "name": "Врата Уфы",
            "cost_x1": [{"resource_id": "summon_scroll", "amount": 1}],
            "cost_x10": [{"resource_id": "summon_scroll", "amount": 8}],
            "rates_bp": rarity_map_weights["standard"],
            "pity": {"ssr_every": 60, "ur_every": 0},
            "x10_guarantee": "SR+",
            "pools": pool_filter(["common", "rare", "epic", "legendary"], include_ur=False),
            "enabled": True,
        },
        {
            "id": "advanced",
            "name": "Небесное Плетение",
            "cost_x1": [{"resource_id": "diamonds", "amount": 300}],
            "cost_x10": [{"resource_id": "diamonds", "amount": 2400}],
            "rates_bp": rarity_map_weights["advanced"],
            "pity": {"ssr_plus_every": 40, "ur_every": 160},
            "x10_guarantee": "SR+",
            "pools": pool_filter(["common", "rare", "epic", "legendary", "mythic"]),
            "enabled": True,
        },
        {
            "id": "faction",
            "name": "Печать союза",
            "cost_x1": [{"resource_id": "faction_scroll", "amount": 1}],
            "cost_x10": [{"resource_id": "faction_scroll", "amount": 8}],
            "rates_bp": rarity_map_weights["faction"],
            "pity": {"ssr_plus_every": 50, "ur_every": 200, "per_faction": True},
            "x10_guarantee": "SR+",
            "faction_select": True,
            "pools_by_faction": {fid: pool_filter(["common", "rare", "epic", "legendary", "mythic"], faction=fid)
                                 for fid in sorted(by_faction.keys())},
            "enabled": True,
        },
        {
            "id": "event",
            "name": "Хроники Разлома",
            "cost_x1": [{"resource_id": "diamonds", "amount": 300}],
            "cost_x10": [{"resource_id": "diamonds", "amount": 2400}],
            "rates_bp": rarity_map_weights["event"],
            "pity": {"ssr_plus_every": 40, "ur_every": 160},
            "featured_hero_id": "H01",
            "featured_rate_bp": 5000,
            "x10_guarantee": "SR+",
            "pools": pool_filter(["common", "rare", "epic", "legendary", "mythic"]),
            "enabled": True,
        },
    ]
    return {
        "schema_version": 1,
        "mode": "DEMO_SANDBOX",
        "disclaimer": "Локальная демо-симуляция. Авторитетный RNG — только на сервере.",
        "dupe_to_shards": 30,
        "banners": banners,
        "hero_count": len(heroes),
    }


def build_liveops() -> dict:
    afk_rates = [
        {"chapter": 1, "gold_per_hour": 1800, "hero_xp_per_hour": 700, "essence_per_hour": 30, "ore_per_hour": 3, "equip_tier": 1, "equip_after": "CH01-20"},
        {"chapter": 2, "gold_per_hour": 3200, "hero_xp_per_hour": 1300, "essence_per_hour": 50, "ore_per_hour": 5, "equip_tier": 1},
        {"chapter": 3, "gold_per_hour": 5200, "hero_xp_per_hour": 2100, "essence_per_hour": 80, "ore_per_hour": 8, "equip_tier": 2},
        {"chapter": 4, "gold_per_hour": 8000, "hero_xp_per_hour": 3400, "essence_per_hour": 125, "ore_per_hour": 12, "equip_tier": 3},
        {"chapter": 5, "gold_per_hour": 12000, "hero_xp_per_hour": 5200, "essence_per_hour": 190, "ore_per_hour": 17, "equip_tier": 4},
        {"chapter": 6, "gold_per_hour": 17500, "hero_xp_per_hour": 7800, "essence_per_hour": 280, "ore_per_hour": 24, "equip_tier": 5},
    ]
    missions = []
    for eid, name, ch, tier, fac, klass, power in EXPEDITIONS:
        mult = CHAPTER_MULT[ch]
        base = TIER_REWARDS[tier]
        rewards = [{"resource_id": g["resource_id"], "amount": int(g["amount"] * mult)} for g in base]
        missions.append({
            "id": eid, "name": name, "chapter": ch, "tier": tier,
            "duration_sec": TIER_DURATION[tier],
            "faction_id": fac, "class_hint": klass, "min_power": power,
            "rewards_success": rewards,
            "special_resource": SPECIAL[ch],
            "special_chance_bp": {"short": 800, "medium": 1600, "long": 2800}[tier],
            "unlock_stage": f"CH0{ch}-10",
        })
    return {
        "schema_version": 1,
        "timezone": "Europe/Moscow",
        "day_reset_hour": 6,
        "afk": {
            "unlock_stage": "CH01-03",
            "cap_hours": 12,
            "min_claim_seconds": 60,
            "rates_by_chapter": afk_rates,
            "equipment_roll_every_hours": 4,
            "equipment_roll_chance_bp": 2500,
            "afk_hour_coupon_daily_cap": 4,
            "no_diamonds": True,
            "no_ssr_ur_heroes": True,
        },
        "daily_quests": DAILY_QUESTS,
        "daily_activity": {
            "points_per_quest": 10, "max_points": 120,
            "chests": [
                {"at": 20, "rewards": [{"resource_id": "gold", "amount": 3000}, {"resource_id": "hero_xp", "amount": 1000}]},
                {"at": 50, "rewards": [{"resource_id": "essence", "amount": 150}, {"resource_id": "diamonds", "amount": 30}]},
                {"at": 80, "rewards": [{"resource_id": "summon_scroll", "amount": 1}, {"resource_id": "ore", "amount": 8}]},
                {"at": 100, "rewards": [{"resource_id": "diamonds", "amount": 70}, {"resource_id": "summon_scroll", "amount": 1}]},
            ],
        },
        "weekly_quests": WEEKLY_QUESTS,
        "weekly_chests": [
            {"at_completed": 3, "rewards": [{"resource_id": "summon_scroll", "amount": 2}]},
            {"at_completed": 5, "rewards": [{"resource_id": "diamonds", "amount": 150}]},
            {"at_completed": 7, "rewards": [{"resource_id": "faction_scroll", "amount": 1}]},
        ],
        "expeditions": {
            "unlock_stage": "CH01-10",
            "base_slots": 2,
            "sub_moon_extra_slot": 1,
            "max_slots": 3,
            "heroes_per_mission": [1, 3],
            "board_size": 6,
            "free_refresh_per_day": 1,
            "paid_refresh_per_day": 2,
            "paid_refresh_gold": 2000,
            "missions": missions,
        },
    }


def sync_features(liveops: dict, economy: dict, gacha: dict) -> dict:
    # Keep features.json shape for existing UI; feed from new configs.
    shop_offers = []
    for o in economy["offers"][:12]:
        desc = ", ".join(f"{g['resource_id']}×{g['amount']}" for g in o["grants"] if "amount" in g)
        shop_offers.append({
            "id": o["sku"],
            "name": o["title"],
            "desc": f"{desc} · 0 ₽ тест",
            "limit": str(o.get("limits", {})),
            "cta": o.get("cta", "Получить бесплатно (тест)"),
        })
    daily = [{"id": q["id"], "title": q["name"], "progress": "0/1", "goto": "HUB-03"} for q in liveops["daily_quests"][:6]]
    weekly = [{"id": q["id"], "title": q["id"], "progress": "0/1", "goto": "HUB-03"} for q in liveops["weekly_quests"][:4]]
    std = next(b for b in gacha["banners"] if b["id"] == "standard")
    rates = std["rates_bp"]
    afk = liveops["afk"]
    ch1 = afk["rates_by_chapter"][0]
    return {
        "shop_offers": shop_offers,
        "events": [
            {"id": "ev_chronicles", "name": "Хроники Разлома", "timer": "сезон 28д", "state": "active"},
            {"id": "ev_ufa", "name": "Архивы Уфы", "timer": "активно", "state": "active"},
        ],
        "quests": {
            "daily": daily,
            "weekly": weekly,
            "story": [{"id": "qs_ch01", "title": "Уфа: пройти CH01-10", "progress": "в процессе", "goto": "MAP-01"}],
            "special": [{"id": "qsp_exp", "title": "Экспедиция Уфимские архивы", "progress": "после CH01-10", "goto": "HUB-02"}],
        },
        "mail": [
            {"id": "m1", "category": "system", "title": "Тестовый магазин", "unread": True,
             "body": "Все покупки бесплатны. Реальные деньги не списываются."},
            {"id": "m2", "category": "event", "title": "AFK после CH01-03", "unread": True},
        ],
        "vip": {"level": 0, "progress": 0, "next": 100},
        "battle_pass": {"season": "Хроники Разлома", "level": 1, "free_ready": 0, "premium_ready": 0},
        "afk": {
            "seconds_default": 3600 * 3 + 420,
            "gold_per_hour": ch1["gold_per_hour"],
            "hero_xp_per_hour": ch1["hero_xp_per_hour"],
            "essence_per_hour": ch1["essence_per_hour"],
            "cap_hours": afk["cap_hours"],
            "unlock_stage": afk["unlock_stage"],
            # legacy keys for old UI
            "gold_per_10s": max(1, ch1["gold_per_hour"] // 360),
            "cap_gold": ch1["gold_per_hour"] * afk["cap_hours"],
        },
        "summon": {
            "banner": std["name"],
            "banner_id": "standard",
            "cost_resource": "summon_scroll",
            "cost_x1": 1,
            "cost_x10": 8,
            "weights": {
                "common": rates["N"] // 100,
                "rare": rates["R"] // 100,
                "epic": rates["SR"] // 100,
                "legendary": rates["SSR"] // 100,
            },
            "disclaimer": gacha["disclaimer"],
        },
    }


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    for name in ["hub.json", "campaign.json", "heroes.json", "battle_modes.json", "enemies.json",
                 "theme.json", "shell.json", "motion.json", "assets.json", "strings.json"]:
        shutil.copy2(SRC / name, OUT / name)

    heroes = json.loads((SRC / "heroes.json").read_text(encoding="utf-8"))["heroes"]
    stages = json.loads((SRC / "campaign.json").read_text(encoding="utf-8"))["stages"]

    economy = build_economy()
    progression = build_progression()
    equipment = build_equipment()
    loot = build_loot(stages)
    gacha = build_gacha(heroes)
    liveops = build_liveops()
    features = sync_features(liveops, economy, gacha)

    # strings extras
    strings = json.loads((OUT / "strings.json").read_text(encoding="utf-8"))
    strings["entries"]["store.disclaimer"] = economy["disclaimer"]
    strings["entries"]["summon.altar"] = "Алтарь призыва"
    strings["entries"]["afk.title"] = "AFK-сокровищница"
    strings["entries"]["map.title"] = "Карта · Башкортостан"
    write_json(OUT / "strings.json", strings)

    write_json(OUT / "economy.json", economy)
    write_json(OUT / "progression.json", progression)
    write_json(OUT / "equipment.json", equipment)
    write_json(OUT / "loot_tables.json", loot)
    write_json(OUT / "gacha.json", gacha)
    write_json(OUT / "liveops.json", liveops)
    write_json(OUT / "features.json", features)

    files = [
        "hub.json", "campaign.json", "heroes.json", "battle_modes.json", "features.json",
        "theme.json", "shell.json", "strings.json", "motion.json", "assets.json", "enemies.json",
        "economy.json", "progression.json", "equipment.json", "loot_tables.json", "gacha.json", "liveops.json",
    ]
    hashes = {f: hashlib.sha256((OUT / f).read_bytes()).hexdigest() for f in files}
    manifest = {
        "id": "lunex-core",
        "version": "0.3.0",
        "schema": 4,
        "client_min": "0.1.0",
        "title": "Razlom Epoh · economy spine + CH01 liveops",
        "locale": "ru",
        "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "updated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "notes": "E0–E4: currencies→progression/loot→gacha→AFK/quests→VIRTUAL_FREE shop. Не серверный прогресс.",
        "files": {f: {"role": f.replace(".json", "")} for f in files},
        "integrity": {"algo": "sha256", "hashes": hashes},
    }
    write_json(OUT / "manifest.json", manifest)

    active = {
        "version": "0.3.0",
        "source": "content-c-economy",
        "note": "Клиент читает только опубликованный пакет. Прогресс игрока сюда не пишется.",
        "published_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    write_json(ROOT / "content/packages/active.json", active)
    print(f"Wrote {OUT}")
    print(f" offers={len(economy['offers'])} sets={len(equipment['sets'])} loot={len(loot['stage_bindings'])} "
          f"banners={len(gacha['banners'])} missions={len(liveops['expeditions']['missions'])}")


if __name__ == "__main__":
    main()
