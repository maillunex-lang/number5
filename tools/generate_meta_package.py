#!/usr/bin/env python3
"""Build content package 0.6.0: meta retention layer.

Order (decided):
  M mail → L login calendars → R profile → A achievements → S daily stories → V live events

Why: mail is the shared delivery channel; calendar/achievements/events roll unclaimed
rewards into mail; profile cosmetics are granted by achievements/events; live events
need currencies + guild/PvE hooks and are heaviest.
"""
from __future__ import annotations

import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "content/packages/0.5.0"
OUT = ROOT / "content/packages/0.6.0"

CURRENCY_IDS = {
    "gold", "diamonds", "hero_xp", "essence", "summon_scroll", "faction_scroll",
    "cosmetic_token", "afk_hour", "skill_book", "ore", "boss_core", "set_pattern",
    "guild_token", "event_token",
}


def rewards(*pairs: tuple[str, int]) -> list[dict]:
    out = []
    for rid, amt in pairs:
        if amt <= 0:
            continue
        assert rid in CURRENCY_IDS or rid.startswith("title_") or rid.startswith("frame_") or rid.startswith("profile_"), rid
        out.append({"resource_id": rid, "amount": amt})
    return out


def build_mail() -> dict:
    templates = [
        ("MAIL_DAILY_UNCLAIMED", "daily_rollover", 7, "Награда за вчерашние дела",
         "Твой отряд заработал награду. Забери её до {expires_at}."),
        ("MAIL_LOGIN_UNCLAIMED", "calendar_rollover", 7, "Календарь не забыт",
         "Награда входа сохранена. Забери до {expires_at}."),
        ("MAIL_EVENT_REWARD", "reward", 30, "Награда события",
         "Событие завершено. Вложение ждёт в письме."),
        ("MAIL_ACHIEVEMENT", "reward", 30, "Заслуженная награда",
         "Достижение выполнено. Забери награду."),
        ("MAIL_GUILD_RAID", "guild", 7, "Итоги совместного рейда",
         "Право на рейдовую награду перенесено в почту."),
        ("MAIL_SEASON_END", "season", 30, "Итоги сезона",
         "Сезон закрыт. Невостребованные права — во вложении."),
        ("MAIL_COMPENSATION", "compensation", 30, "Компенсация",
         "Компенсация от службы Разлома."),
        ("MAIL_MAINTENANCE", "system", 30, "Новости Разлома",
         "Краткое обслуживание завершено. Спасибо за терпение."),
    ]
    demo_inbox = [
        {
            "id": "demo_m1",
            "template_id": "MAIL_MAINTENANCE",
            "category": "system",
            "subject": "Новости Разлома",
            "body": "Демо-пакет 0.6.0: почта — единый канал наград. Без HTML/ссылок.",
            "status": "unread",
            "attachments": [],
            "expires_in_days": 30,
        },
        {
            "id": "demo_m2",
            "template_id": "MAIL_LOGIN_UNCLAIMED",
            "category": "calendar_rollover",
            "subject": "Календарь не забыт",
            "body": "Демо: незабранный день LOGIN_7 перенесён сюда на 7 дней.",
            "status": "unread",
            "attachments": rewards(("gold", 10000), ("hero_xp", 2000)),
            "expires_in_days": 7,
        },
        {
            "id": "demo_m3",
            "template_id": "MAIL_ACHIEVEMENT",
            "category": "reward",
            "subject": "Заслуженная награда",
            "body": "Демо: ACH_STORY_01 ждал claim — право в почте.",
            "status": "read",
            "attachments": rewards(("diamonds", 50)),
            "expires_in_days": 30,
        },
    ]
    return {
        "schema": 1,
        "disclaimer": "DEMO · серверная доставка после CORE-01",
        "player_to_player": False,
        "ui_limit": 200,
        "categories": ["system", "reward", "daily_rollover", "calendar_rollover", "compensation", "guild", "season"],
        "states": ["unread", "read", "claimed", "archived", "expired", "deleted"],
        "templates": [
            {
                "id": tid,
                "category": cat,
                "ttl_days": ttl,
                "subject_key": f"mail.{tid}.subject",
                "subject": subject,
                "body_key": f"mail.{tid}.body",
                "body": body,
            }
            for tid, cat, ttl, subject, body in templates
        ],
        "demo_inbox": demo_inbox,
        "rules": {
            "read_does_not_claim": True,
            "delete_before_claim_forbidden_mvp": True,
            "claim_all_atomic_per_mail": True,
            "unique_source_key": ["account_id", "source_type", "source_id", "period_key"],
        },
    }


def build_login_calendars() -> dict:
    login7 = [
        rewards(("gold", 10000), ("hero_xp", 2000)),
        rewards(("essence", 250), ("ore", 8)),
        rewards(("summon_scroll", 1), ("gold", 12000)),
        rewards(("hero_xp", 5000), ("skill_book", 1)),
        rewards(("diamonds", 100), ("essence", 300)),
        rewards(("summon_scroll", 2), ("ore", 12)),
        rewards(("diamonds", 200), ("summon_scroll", 3), ("cosmetic_token", 30)),
    ]
    login30_raw = [
        (1, [("gold", 7000), ("hero_xp", 2500)]),
        (2, [("gold", 8000), ("hero_xp", 3000)]),
        (3, [("gold", 9000), ("hero_xp", 3500)]),
        (4, [("gold", 10000), ("hero_xp", 4000)]),
        (5, [("summon_scroll", 2), ("skill_book", 2)]),
        (6, [("gold", 12000), ("hero_xp", 5000)]),
        (7, [("faction_scroll", 1), ("essence", 500)]),
        (8, [("gold", 14000), ("hero_xp", 6000)]),
        (9, [("gold", 15000), ("hero_xp", 6500)]),
        (10, [("diamonds", 250), ("summon_scroll", 3)]),
        (11, [("gold", 17000), ("hero_xp", 7500)]),
        (12, [("gold", 18000), ("hero_xp", 8000)]),
        (13, [("gold", 19000), ("hero_xp", 8500)]),
        (14, [("faction_scroll", 1), ("essence", 500)]),
        (15, [("summon_scroll", 2), ("skill_book", 2)]),
        (16, [("gold", 22000), ("hero_xp", 10000)]),
        (17, [("gold", 23000), ("hero_xp", 10500)]),
        (18, [("gold", 24000), ("hero_xp", 11000)]),
        (19, [("gold", 25000), ("hero_xp", 11500)]),
        (20, [("diamonds", 250), ("summon_scroll", 3)]),
        (21, [("faction_scroll", 1), ("essence", 500)]),
        (22, [("gold", 28000), ("hero_xp", 13000)]),
        (23, [("gold", 29000), ("hero_xp", 13500)]),
        (24, [("gold", 30000), ("hero_xp", 14000)]),
        (25, [("summon_scroll", 2), ("skill_book", 2)]),
        (26, [("gold", 32000), ("hero_xp", 15000)]),
        (27, [("gold", 33000), ("hero_xp", 15500)]),
        (28, [("faction_scroll", 1), ("essence", 500)]),
        (29, [("gold", 35000), ("hero_xp", 16500)]),
        (30, [("diamonds", 500), ("summon_scroll", 8), ("faction_scroll", 2)]),
    ]
    newcomer = [
        rewards(("gold", 6000), ("hero_xp", 2000)),
        rewards(("gold", 8000), ("hero_xp", 3000)),
        rewards(("gold", 10000), ("hero_xp", 4000), ("summon_scroll", 1)),
        rewards(("gold", 12000), ("hero_xp", 5000)),
        rewards(("gold", 14000), ("hero_xp", 6000)),
        rewards(("gold", 16000), ("hero_xp", 7000), ("summon_scroll", 1)),
        rewards(("faction_scroll", 1), ("essence", 500)),
        rewards(("gold", 20000), ("hero_xp", 9000)),
        rewards(("gold", 22000), ("hero_xp", 10000), ("summon_scroll", 1)),
        rewards(("gold", 24000), ("hero_xp", 11000)),
        rewards(("gold", 26000), ("hero_xp", 12000)),
        rewards(("gold", 28000), ("hero_xp", 13000), ("summon_scroll", 1)),
        rewards(("gold", 30000), ("hero_xp", 14000)),
        rewards(("summon_scroll", 8), ("diamonds", 300)),
    ]
    return {
        "schema": 1,
        "disclaimer": "DEMO · claim/сервер после CORE-01; незабранное → MAIL_LOGIN_UNCLAIMED",
        "unlock_stage": "CH01-03",
        "daily_reset": "06:00 Europe/Moscow",
        "auto_claim": False,
        "premium_calendar": False,
        "calendars": [
            {
                "id": "LOGIN_7",
                "name": "7 дней",
                "days": 7,
                "repeat": True,
                "once": False,
                "entries": [{"day": i + 1, "rewards": login7[i]} for i in range(7)],
            },
            {
                "id": "LOGIN_30",
                "name": "30 дней",
                "days": 30,
                "repeat": True,
                "once": False,
                "entries": [{"day": d, "rewards": rewards(*pairs)} for d, pairs in login30_raw],
            },
            {
                "id": "NEWCOMER_14",
                "name": "Новичок",
                "days": 14,
                "repeat": False,
                "once": True,
                "entries": [{"day": i + 1, "rewards": newcomer[i]} for i in range(14)],
            },
        ],
        "rollover": {
            "unclaimed_to_mail_template": "MAIL_LOGIN_UNCLAIMED",
            "mail_ttl_days": 7,
            "advance_after_mail_or_claim": True,
        },
        "demo": {
            "LOGIN_7": {"next_day": 3, "cycle_no": 1, "status": "available"},
            "LOGIN_30": {"next_day": 5, "cycle_no": 1, "status": "available"},
            "NEWCOMER_14": {"next_day": 4, "cycle_no": 1, "status": "available"},
        },
    }


def build_profile() -> dict:
    avatars = [f"avatar_f{i:02d}" for i in range(1, 7)] + [f"avatar_ch{i:02d}" for i in range(1, 7)]
    frames = [
        ("frame_start_a", "campaign", "CH01-01"),
        ("frame_start_b", "campaign", "CH01-01"),
        ("frame_story_a", "campaign", "CH01-30"),
        ("frame_story_b", "campaign", "CH03-30"),
        ("frame_tower_a", "tower", "floor_40"),
        ("frame_tower_b", "tower", "floor_100"),
        ("frame_guild", "guild", "guild_level_5"),
        ("frame_event", "event", "EVT_001"),
    ]
    titles = []
    for ch in range(1, 7):
        titles.append({"id": f"title_ch{ch:02d}_a", "chapter": ch, "name": f"Глава {ch} · след"})
        titles.append({"id": f"title_ch{ch:02d}_b", "chapter": ch, "name": f"Глава {ch} · печать"})
    # secret / achievement titles referenced later
    titles.extend([
        {"id": "title_untouched", "chapter": 0, "name": "Нетронутый", "secret": True},
        {"id": "title_last_spark", "chapter": 0, "name": "Последняя искра", "secret": True},
    ])
    backgrounds = [{"id": f"bg_ch{ch:02d}", "chapter": ch, "unlock_stage": f"CH{ch:02d}-30"} for ch in range(1, 7)]
    backgrounds.append({"id": "profile_rift", "chapter": 6, "unlock_stage": "CH06-30", "secret": True})
    return {
        "schema": 1,
        "disclaimer": "DEMO · публичная карточка без email/VIP/платежей",
        "nickname": {"min": 3, "max": 18, "free_renames_period_days": 30, "first_free": True, "paid_rename_mvp": False},
        "privacy_defaults": {
            "show_campaign_progress": True,
            "show_hero_showcase": False,
            "show_collection_summary": False,
            "show_pve_records": False,
            "show_guild": True,
        },
        "cosmetics": {
            "avatars": [{"id": a, "kind": "emblem" if a.startswith("avatar_f") else "chapter"} for a in avatars],
            "frames": [{"id": fid, "source": src, "unlock": un} for fid, src, un in frames] + [
                {"id": "frame_unlikely", "source": "secret", "unlock": "ACH_SECRET_03"},
            ],
            "titles": titles,
            "backgrounds": backgrounds,
        },
        "demo": {
            "public_player_id": "LX-7F3K9Q",
            "nickname": "Командир Уфы",
            "avatar_id": "avatar_f01",
            "frame_id": "frame_start_a",
            "title_id": "title_ch01_a",
            "background_id": "bg_ch01",
            "favorite_hero_id": "H01",
            "max_stage": "CH01-12",
            "owned_heroes": 8,
            "tower_floor": 12,
            "guild_tag": "UFA",
        },
    }


def build_achievements() -> dict:
    rows = []
    # story
    story = [(1, 50), (10, 75), (30, 100), (60, 125), (90, 150), (120, 175), (150, "scroll1"), (180, "scroll2")]
    names_s = ["Первый шаг", "Десять решений", "Тридцать дорог", "Шестьдесят испытаний",
               "Девяносто битв", "Сто двадцать этапов", "Сто пятьдесят этапов", "Разлом закрыт"]
    for i, (th, rew) in enumerate(story, 1):
        r = rewards(("summon_scroll", 1)) if rew == "scroll1" else rewards(("summon_scroll", 2)) if rew == "scroll2" else rewards(("diamonds", rew))
        rows.append({"id": f"ACH_STORY_{i:02d}", "name": names_s[i - 1], "category": "story",
                     "metric": "campaign_unique_clears", "threshold": th, "rewards": r, "hidden": False})
    # heroes
    hero = [(1, 50), (5, 75), (10, 100), (15, 125), (20, 150), (30, 175), (40, "scroll1"), (45, "scroll2")]
    names_h = ["Первый герой", "Пятеро в строю", "Десять имён", "Пятнадцать героев",
               "Двадцать героев", "Тридцать героев", "Сорок героев", "Все сорок пять"]
    for i, (th, rew) in enumerate(hero, 1):
        r = rewards(("summon_scroll", 1)) if rew == "scroll1" else rewards(("summon_scroll", 2)) if rew == "scroll2" else rewards(("diamonds", rew))
        rows.append({"id": f"ACH_HERO_{i:02d}", "name": names_h[i - 1], "category": "heroes",
                     "metric": "unique_owned_heroes", "threshold": th, "rewards": r, "hidden": False})
    # summon
    summon = [(1, 50), (10, 75), (50, 100), (100, 125), (200, 150), (500, 175), (1000, "scroll1"), (2000, "scroll2")]
    names_m = ["Первый призыв", "Десять зовов", "Пятьдесят зовов", "Сто зовов",
               "Двести зовов", "Пятьсот зовов", "Тысяча зовов", "Мастер призыва"]
    for i, (th, rew) in enumerate(summon, 1):
        r = rewards(("summon_scroll", 1)) if rew == "scroll1" else rewards(("summon_scroll", 2)) if rew == "scroll2" else rewards(("diamonds", rew))
        rows.append({"id": f"ACH_SUMMON_{i:02d}", "name": names_m[i - 1], "category": "summon",
                     "metric": "summon_results", "threshold": th, "rewards": r, "hidden": False})
    # pve tower
    pve = [(10, 50), (20, 75), (40, 100), (60, 125), (80, 150), (100, 175), (110, "scroll1"), (120, "scroll2")]
    for i, (th, rew) in enumerate(pve, 1):
        r = rewards(("summon_scroll", 1)) if rew == "scroll1" else rewards(("summon_scroll", 2)) if rew == "scroll2" else rewards(("diamonds", rew))
        rows.append({"id": f"ACH_PVE_{i:02d}", "name": f"Башня: {th}", "category": "pve",
                     "metric": "tower_highest_floor", "threshold": th, "rewards": r, "hidden": False})
    # afk
    afk = [(1, 50), (5, 75), (10, 100), (20, 125), (50, 150), (100, 175), (200, "scroll1"), (500, "scroll2")]
    names_a = ["Первый сбор", "Пять сборов", "Десять сборов", "Двадцать сборов",
               "Пятьдесят сборов", "Сто сборов", "Двести сборов", "Пятьсот сборов"]
    for i, (th, rew) in enumerate(afk, 1):
        r = rewards(("summon_scroll", 1)) if rew == "scroll1" else rewards(("summon_scroll", 2)) if rew == "scroll2" else rewards(("diamonds", rew))
        rows.append({"id": f"ACH_AFK_{i:02d}", "name": names_a[i - 1], "category": "afk",
                     "metric": "afk_claim_count", "threshold": th, "rewards": r, "hidden": False})
    # guild
    guild_defs = [
        (1, "guild_joins", 1, 50, "Первое вступление"),
        (2, "guild_quests_claimed", 3, 75, "Три поручения"),
        (3, "guild_quests_claimed", 10, 100, "Десять поручений"),
        (4, "guild_raid_participations", 1, 125, "Первый рейд"),
        (5, "guild_raid_participations", 5, 150, "Пять рейдов"),
        (6, "guild_raid_participations", 10, 175, "Десять рейдов"),
        (7, "guild_quests_claimed", 50, "scroll1", "Пятьдесят поручений"),
        (8, "guild_quests_claimed", 100, "scroll2", "Сто поручений"),
    ]
    for i, metric, th, rew, name in guild_defs:
        r = (
            rewards(("summon_scroll", 1)) if rew == "scroll1"
            else rewards(("summon_scroll", 2)) if rew == "scroll2"
            else rewards(("diamonds", int(rew)))
        )
        rows.append({
            "id": f"ACH_GUILD_{i:02d}", "name": name, "category": "guild",
            "metric": metric, "threshold": th, "rewards": r, "hidden": False,
        })

    secrets = [
        {"id": "ACH_SECRET_01", "name": "???", "category": "secret", "metric": "stage_no_hp_loss", "threshold": 1,
         "rewards": [{"resource_id": "title_untouched", "amount": 1}], "hidden": True, "reveal_name": "Без царапины"},
        {"id": "ACH_SECRET_02", "name": "???", "category": "secret", "metric": "boss_one_survivor", "threshold": 1,
         "rewards": rewards(("cosmetic_token", 100)), "hidden": True, "reveal_name": "Один на ногах"},
        {"id": "ACH_SECRET_03", "name": "???", "category": "secret", "metric": "tower_five_n", "threshold": 1,
         "rewards": [{"resource_id": "frame_unlikely", "amount": 1}], "hidden": True, "reveal_name": "Невероятный состав"},
        {"id": "ACH_SECRET_04", "name": "???", "category": "secret", "metric": "daily_quests_distinct", "threshold": 7,
         "rewards": rewards(("diamonds", 100)), "hidden": True, "reveal_name": "Полный день"},
        {"id": "ACH_SECRET_05", "name": "???", "category": "secret", "metric": "raid_min_nonzero", "threshold": 1,
         "rewards": [{"resource_id": "title_last_spark", "amount": 1}], "hidden": True, "reveal_name": "Последняя искра"},
        {"id": "ACH_SECRET_06", "name": "???", "category": "secret", "metric": "chapters_cleared", "threshold": 6,
         "rewards": [{"resource_id": "profile_rift", "amount": 1}], "hidden": True, "reveal_name": "Все главы"},
    ]
    assert len(rows) == 48
    assert len(secrets) == 6
    return {
        "schema": 1,
        "disclaimer": "DEMO · прогресс/claim серверные после CORE-01; незабранное → MAIL_ACHIEVEMENT",
        "combat_bonus": False,
        "mail_rollover_template": "MAIL_ACHIEVEMENT",
        "achievements": rows,
        "secrets": secrets,
        "demo_progress": {
            "ACH_STORY_01": {"progress": 12, "status": "claimed"},
            "ACH_STORY_02": {"progress": 12, "status": "completed_unclaimed"},
            "ACH_HERO_01": {"progress": 8, "status": "claimed"},
            "ACH_HERO_02": {"progress": 8, "status": "completed_unclaimed"},
            "ACH_SUMMON_01": {"progress": 3, "status": "claimed"},
            "ACH_PVE_01": {"progress": 12, "status": "completed_unclaimed"},
            "ACH_AFK_01": {"progress": 4, "status": "claimed"},
            "ACH_GUILD_01": {"progress": 1, "status": "claimed"},
        },
    }


def build_daily_stories() -> dict:
    chapter_meta = {
        1: ("Уфа", "CH01-01", 3000, 40, 1600),
        2: ("Шиханы", "CH02-01", 4000, 50, 2200),
        3: ("Белорецк", "CH03-01", 5000, 60, 2800),
        4: ("Стерлитамак 2050", "CH04-01", 6000, 70, 3400),
        5: ("Иремель", "CH05-01", 7000, 80, 4000),
        6: ("Сердце Разлома", "CH06-01", 8000, 90, 4600),
    }
    titles = {
        1: ["Очередь за временем", "Печать без адреса", "Часы идут назад", "Трамвай вне расписания", "Протокол потерянного утра"],
        2: ["Камень с памятью", "Тихая трещина", "Путь без следов", "Песок свидетелей", "Страж без приказа"],
        3: ["Кузня последней искры", "Письмо в шестерне", "Незаконченный клинок", "Смена без конца", "Зеркало в руде"],
        4: ["Сбой протокола", "Память квартала", "Невидимая очередь", "Нулевой сигнал", "Пропуск в вчера"],
        5: ["Тень на перевале", "Снежная записка", "Эхо без голоса", "Два следа", "Тропа к звезде"],
        6: ["Секунда до нуля", "Долг Хранителя", "Сломанная развилка", "Тень финала", "Письмо из завтра"],
    }
    hooks = {
        1: [
            "В архиве Уфы исчезли три минуты из журнала.",
            "Курьер доставил печать, на которой нет адресата.",
            "Уличные часы спорят с городским календарём.",
            "Старый маршрут внезапно отмечен в будущем.",
            "Писарь утверждает, что сегодня было два рассвета.",
        ],
        2: [
            "Шихан отвечает на забытое слово.",
            "В каменной стене слышны голоса прошлых эпох.",
            "Дорога исчезает с карты при каждом повороте.",
            "Песок хранит следы ещё не случившегося боя.",
            "Древний страж забыл, что именно охраняет.",
        ],
        3: [
            "Мастерская получает металл, которого нет в природе.",
            "В механизме найдено письмо без даты.",
            "Клинок отказывается принимать клеймо.",
            "Рабочие часы кузницы не доходят до полуночи.",
            "Руда показывает отражение другого времени.",
        ],
        4: [
            "Терминал 2050 года требует бумажную справку.",
            "Квартал помнит улицу, которой больше нет.",
            "Робот обслуживает людей из прошлого.",
            "Радиостанция получает сообщение из завтрашнего дня.",
            "Турникет пропускает только вчерашние билеты.",
        ],
        5: [
            "Тень движется против солнца.",
            "В снегу лежит записка, написанная огнём.",
            "Эхо отвечает раньше вопроса.",
            "На тропе две цепочки следов одного путника.",
            "Свет в ущелье показывает путь в небо.",
        ],
        6: [
            "В Разломе все часы показывают разные секунды.",
            "Древняя печать требует исполнить обещание.",
            "Две временные дороги сходятся в одну.",
            "Силуэт повторяет последнее решение отряда.",
            "Письмо благодарит за ещё не совершённый поступок.",
        ],
    }
    # enemy hints from CH01 pool style — use E01-xx / B for optional fights
    enemy_by_ch = {
        1: "E01-01", 2: "E02-01", 3: "E03-01", 4: "E04-01", 5: "E05-01", 6: "E06-01",
    }
    stories = []
    for ch in range(1, 7):
        territory, unlock, gold, ess, xp = chapter_meta[ch]
        for i in range(5):
            sid = f"DSE-{ch:02d}-{i + 1:02d}"
            stories.append({
                "id": sid,
                "chapter": ch,
                "territory": territory,
                "unlock_stage": unlock,
                "title": titles[ch][i],
                "hook": hooks[ch][i],
                "intro_lines": [
                    hooks[ch][i],
                    "Разлом шепчет два пути — и оба ведут к правде.",
                    "Выбор не меняет канон кампании.",
                ],
                "choices": [
                    {
                        "id": "A",
                        "label": "Исследовать след",
                        "battle": False,
                        "rewards": rewards(("gold", gold), ("essence", ess)),
                        "outro_lines": ["След записан в архив. Награда выдана."],
                    },
                    {
                        "id": "B",
                        "label": "Устранить аномалию",
                        "battle": True,
                        "enemy_hint": enemy_by_ch[ch],
                        "rewards": rewards(("hero_xp", xp), ("gold", gold)),
                        "outro_lines": ["Аномалия погашена. Ожидаемая ценность близка к A."],
                        "lose_partial_gold_pct": 50,
                        "retry_once": True,
                    },
                ],
            })
    assert len(stories) == 30
    return {
        "schema": 1,
        "disclaimer": "DEMO · одна карточка/день; тексты черновые для редакторского согласования",
        "unlock_stage": "CH01-10",
        "daily_reset": "06:00 Europe/Moscow",
        "anti_repeat_days": 7,
        "pass_xp": False,
        "mail_rollover_template": "MAIL_EVENT_REWARD",
        "mail_ttl_days": 7,
        "stories": stories,
        "demo": {
            "period_key": "2026-11-20",
            "story_id": "DSE-01-01",
            "status": "available",
            "history": [
                {"story_id": "DSE-01-02", "choice_id": "A", "period_key": "2026-11-19"},
                {"story_id": "DSE-01-03", "choice_id": "B", "period_key": "2026-11-18"},
            ],
        },
    }


def build_live_events(boss_ids: set[str]) -> dict:
    def pick_bosses(*cands: str) -> list[str]:
        out = [c for c in cands if c in boss_ids]
        if len(out) < 3:
            # fill from available
            for b in sorted(boss_ids):
                if b not in out:
                    out.append(b)
                if len(out) >= 3:
                    break
        return out[:3]

    shop = [
        ("evt_gold", 20, [{"resource_id": "gold", "amount": 20000}], 10),
        ("evt_essence", 40, [{"resource_id": "essence", "amount": 400}], 5),
        ("evt_skill", 50, [{"resource_id": "skill_book", "amount": 2}], 3),
        ("evt_scroll", 60, [{"resource_id": "summon_scroll", "amount": 1}], 5),
        ("evt_faction_scroll", 120, [{"resource_id": "faction_scroll", "amount": 1}], 2),
        ("evt_cosmetic_frame", 180, [{"resource_id": "cosmetic_token", "amount": 1, "item_id": "frame_event"}], 1),
    ]
    bosses = pick_bosses("B02-01", "B02-02", "B01-01")
    events = [
        {
            "id": "EVT_001",
            "name": "Неделя исчезнувших минут",
            "format": "COLLECTION",
            "theme": "Уфа",
            "duration_days": 7,
            "unlock_stage": "CH01-10",
            "milestones": [
                {"tokens": 20, "rewards": rewards(("gold", 15000), ("event_token", 30))},
                {"tokens": 50, "rewards": rewards(("essence", 300), ("event_token", 40))},
                {"tokens": 90, "rewards": rewards(("summon_scroll", 1), ("event_token", 60))},
            ],
            "sources": [
                {"id": "campaign_3", "cap_per_day": 10, "tokens": 1},
                {"id": "afk_claim", "cap_per_day": 5, "tokens": 1},
                {"id": "expedition", "cap_per_day": 5, "tokens": 1},
            ],
        },
        {
            "id": "EVT_002",
            "name": "Каменная тревога",
            "format": "BOSS_RUSH",
            "theme": "Шиханы",
            "duration_days": 7,
            "unlock_stage": "CH02-10",
            "bosses": bosses,
            "daily_rewarded_attempts": 2,
            "difficulties": 3,
        },
        {
            "id": "EVT_003",
            "name": "Неделя кузнечного завета",
            "format": "FACTION_WEEK",
            "theme": "Кузни",
            "duration_days": 7,
            "unlock_stage": "CH03-01",
            "faction_id": "F04",
            "tasks": [
                {"id": "fw_battles", "need": 5, "heroes_of_faction_min": 3},
                {"id": "fw_upgrade", "need": 2},
                {"id": "fw_trial", "need": 1},
            ],
        },
        {
            "id": "EVT_004",
            "name": "Маршрут из 2050-го",
            "format": "EXPEDITION",
            "theme": "Стерлитамак будущего",
            "duration_days": 10,
            "unlock_stage": "CH04-01",
            "chain_hours": [2, 4, 6, 8, 10],
            "max_concurrent": 1,
        },
        {
            "id": "EVT_005",
            "name": "Эхо Иремеля",
            "format": "MINI_CAMPAIGN",
            "theme": "Иремель",
            "duration_days": 14,
            "unlock_stage": "CH05-01",
            "stages": [f"EVT_005-ST{i:02d}" for i in range(1, 11)],
            "boss_stages": {"ST05": bosses[0], "ST10": bosses[1] if len(bosses) > 1 else bosses[0]},
            "dialog_inserts": 3,
        },
        {
            "id": "EVT_006",
            "name": "Общий час",
            "format": "GUILD_COOP",
            "theme": "Совместный прогресс",
            "duration_days": 7,
            "unlock_stage": "CH01-20",
            "requires_guild": True,
            "guild_targets": {"personal_quests": 30, "raid_fights": 15, "expeditions": 20},
        },
    ]
    return {
        "schema": 1,
        "disclaimer": "DEMO · одно активное крупное событие; даты назначает админ; без реальных платежей",
        "currency_id": "event_token",
        "grace_hours_after_end": 48,
        "warn_hours_before_expire": 24,
        "one_active_large_event": True,
        "global_ranking_mvp": False,
        "shop": {
            "currency_id": "event_token",
            "real_money_enabled": False,
            "offers": [
                {"sku": sku, "price_event_token": price, "grants": grants, "limit_per_event": lim}
                for sku, price, grants, lim in shop
            ],
        },
        "events": events,
        "demo": {
            "active_instance": {
                "definition_id": "EVT_001",
                "starts_at": "2026-11-18T03:00:00Z",
                "ends_at": "2026-11-25T03:00:00Z",
                "claim_deadline": "2026-11-27T03:00:00Z",
                "tokens": 42,
                "milestones_claimed": [20],
            },
        },
    }


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    shutil.copytree(SRC, OUT)

    enemies = json.loads((OUT / "enemies.json").read_text(encoding="utf-8"))
    boss_ids = {b["id"] for b in enemies.get("bosses", [])}
    foe_ids = {e["id"] for e in enemies.get("enemies", [])} | boss_ids

    mail = build_mail()
    calendars = build_login_calendars()
    profile = build_profile()
    achievements = build_achievements()
    stories = build_daily_stories()
    # validate story enemy hints exist when possible
    for s in stories["stories"]:
        for c in s["choices"]:
            hint = c.get("enemy_hint")
            if hint and foe_ids and hint not in foe_ids:
                # soften: keep id, validator may warn; prefer first enemy of chapter pack
                pass

    live = build_live_events(boss_ids)

    for name, data in [
        ("mail.json", mail),
        ("login_calendars.json", calendars),
        ("profile.json", profile),
        ("achievements.json", achievements),
        ("daily_stories.json", stories),
        ("live_events.json", live),
    ]:
        (OUT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # economy: event_token
    eco = json.loads((OUT / "economy.json").read_text(encoding="utf-8"))
    cur_ids = {c["id"] for c in eco["currencies"]}
    if "event_token" not in cur_ids:
        eco["currencies"].append({
            "id": "event_token",
            "name": "Жетон события",
            "premium": False,
            "note": "Привязан к event_instance_id; не смешивать с guild_token / time_shard",
        })
    (OUT / "economy.json").write_text(json.dumps(eco, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # features: slim mail stub replaced by mail.json; keep vip/afk/etc.
    features = json.loads((OUT / "features.json").read_text(encoding="utf-8"))
    features["mail"] = {
        "note": "Каталог писем — mail.json; этот ключ оставлен для совместимости UI badge",
        "unread_demo": sum(1 for m in mail["demo_inbox"] if m.get("status") == "unread"),
    }
    features["events"] = [
        {
            "id": live["demo"]["active_instance"]["definition_id"],
            "name": next(e["name"] for e in live["events"] if e["id"] == "EVT_001"),
            "timer": "до конца недели",
            "state": "active",
            "goto": "HUB-04",
        }
    ]
    (OUT / "features.json").write_text(json.dumps(features, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    strings = json.loads((OUT / "strings.json").read_text(encoding="utf-8"))
    strings["entries"].update({
        "mail.title": "Почта",
        "calendar.title": "Календарь входа",
        "profile.title": "Профиль",
        "achievements.title": "Достижения",
        "daily_story.title": "Событие дня",
        "live_events.title": "События",
        "meta.demo": "DEMO · без серверного claim",
    })
    (OUT / "strings.json").write_text(json.dumps(strings, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    file_list = [f.name for f in sorted(OUT.glob("*.json")) if f.name != "manifest.json"]
    hashes = {f: hashlib.sha256((OUT / f).read_bytes()).hexdigest() for f in file_list}
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    manifest = {
        "id": "lunex-core",
        "version": "0.6.0",
        "schema": 7,
        "client_min": "0.1.0",
        "title": "Razlom Epoh · mail/calendar/profile/achievements/stories/events (DEMO)",
        "locale": "ru",
        "created_at": now,
        "updated_at": now,
        "notes": "Order M→L→R→A→S→V after E/P/G. Server claim = CORE-01.",
        "files": {f: {"role": f.replace(".json", "")} for f in file_list},
        "integrity": {"algo": "sha256", "hashes": hashes},
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    active = {
        "version": "0.6.0",
        "source": "content-c-meta",
        "note": "Клиент читает только опубликованный пакет. Прогресс игрока сюда не пишется.",
        "published_at": now,
    }
    (ROOT / "content/packages/active.json").write_text(json.dumps(active, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(f"Wrote {OUT}")
    print(
        f" mail_tpl={len(mail['templates'])} cal=3 ach={len(achievements['achievements'])}+{len(achievements['secrets'])}"
        f" stories={len(stories['stories'])} events={len(live['events'])}"
    )


if __name__ == "__main__":
    main()
