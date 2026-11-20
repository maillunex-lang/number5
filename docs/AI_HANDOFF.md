# AI_HANDOFF — сводка для следующего ИИ

**Обновлять вручную** после каждого значимого PR (см. `AI_WORKFLOW.md`).  
Последнее обновление: **2026-11-20** · `main` @ `5f6f754` (merge PR #5 master audit).

## Текущий этап

Master audit **закрыт и в main**. Игровой контент C0–C6 в пакете **`0.9.0`**. Онлайн-прототип на memory API. Ждём следующую команду пользователя на код (рекомендация: H5 → logout → H6).

## Последний проверенный коммит main

`5f6f754` — Merge pull request #5 (docs master audit H1–H6 locked).  
До аудита: `572c27d` — PR #4 (UI-02 + postgres adapter stub).

## Что действительно готово

- Пакеты / валидатор / Studio / Godot shell / 4 вкладки  
- CORE-01 memory API (guest…store) + CI smoke  
- ApiClient wiring: summon, AFK, shop, mail, battle claim  
- Postgres **код** adapter  
- AGENTS / AI_WORKFLOW / TECH_DEBT / QUALITY_GATES / AUDIT_REPORT  

## В работе / PARTIAL

- Heroes/campaign sync на клиенте  
- Battle: local sim ≠ server authority (**H6** запланирован)  
- Economy atomicity (ledger vs side effects)  
- OTA только dev HTTP  

## Заблокировано

| Блокер | Пояснение |
|---|---|
| Lunex PG prod | VPS есть; нужна **изолированная** БД Lunex (не Nexus AI) |
| OTA-2 | HTTPS CDN |
| ART-05 | бинарный арт |

## Решения пользователя (зафиксированы)

| ID | Решение |
|---|---|
| H1 | 4 вкладки — канон UI |
| H2 | Шапки `docs/content/*` = статус внедрения |
| H3 | ARCHITECTURE/STRUCTURE/PROTOTYPE актуализированы |
| H4 | prod → только Postgres (**код отдельной задачей**) |
| H5 | grant/confirm-test только `APP_ENV=test` (**код отдельной задачей**) |
| H6 | server timeline → playback → single claim (**код отдельной задачей**) |

## Читать первым (5–10 мин)

1. `AGENTS.md`  
2. `docs/STATUS.md`  
3. `docs/ROADMAP.md`  
4. этот `AI_HANDOFF.md`  
5. `docs/TECH_DEBT.md` (TD-*)  
6. Сервер: `docs/TZ_A_FOUNDATION.md` + `server/internal/httpapi/mux.go`  
7. Контент: `docs/CONTENT_IMPLEMENTATION.md` + `content/packages/0.9.0/`  

## Тесты перед работой

```bash
tools/verify_project.sh
```

## Рекомендуемые следующие задачи

1. `CORE-SEC-TESTONLY` (H5) — без инфра  
2. `UI-LOGOUT-CLEAR` (+ health probe)  
3. `BATTLE-SERVER-PIPELINE` (H6)  
4. `CORE-PG-DEPLOY` / `CORE-PG-FAILCLOSED` (H4) — когда есть изолированная БД  
5. `ATOMIC-ECONOMY`  

Не начинать гильдии/ивенты server, пока нет PG + H4/H6.  
Не повторять полный аудит без причины.
