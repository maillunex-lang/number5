# AI_HANDOFF — сводка для следующего ИИ

**Обновлять вручную** после каждого значимого PR (см. `AI_WORKFLOW.md`).  
Последнее обновление: **2026-11-20** · ветка `cursor/audit-repository-master-9d0b` · PR [#5](https://github.com/maillunex-lang/number5/pull/5) (до merge в main).

## Текущий этап

Документационный **master audit** после CORE-01 memory + UI-02.  
Игровой контент C0–C6 в пакете **`0.9.0`**. Онлайн-прототип на memory API.

## Последний проверенный коммит main

`main` @ `572c27d` — merge PR #4 (UI-02 + postgres adapter stub).  
Аудит-доки — tip ветки PR #5 (этот аудит).

## Что действительно готово

- Пакеты / валидатор / Studio / Godot shell / 4 вкладки  
- CORE-01 memory API (guest…store) + CI smoke  
- ApiClient wiring: summon, AFK, shop, mail, battle claim  
- Postgres **код** adapter  

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
| H1 | 4 вкладки — канон UI; GDD исправлен |
| H2 | Шапки `docs/content/*` = статус внедрения |
| H3 | ARCHITECTURE/STRUCTURE/PROTOTYPE актуализировать |
| H4 | prod → только Postgres, без memory fallback (**код отдельной задачей**) |
| H5 | grant/confirm-test только `APP_ENV=test` (**код отдельной задачей**) |
| H6 | server timeline → playback → single claim (**код отдельной задачей**) |

## Читать первым (5–10 мин)

1. `AGENTS.md`  
2. `docs/STATUS.md`  
3. `docs/ROADMAP.md`  
4. этот `AI_HANDOFF.md`  
5. `docs/TECH_DEBT.md` (TD-*)  
6. При сервере: `docs/TZ_A_FOUNDATION.md` + `server/internal/httpapi/mux.go`  
7. При контенте: `docs/CONTENT_IMPLEMENTATION.md` + `content/packages/0.9.0/`  

## Тесты перед работой

```bash
tools/validate_content_package.sh 0.9.0
python3 tools/check_repo_refs.py
cd server && go test ./...
```

## Рекомендуемые следующие задачи

1. `CORE-SEC-TESTONLY` (H5) — без инфра  
2. `UI-LOGOUT-CLEAR` + health probe  
3. `CORE-PG-DEPLOY` / `CORE-PG-FAILCLOSED` (H4) на изолированной БД  
4. `BATTLE-SERVER-PIPELINE` (H6)  
5. `ATOMIC-ECONOMY`  

Не начинать гильдии/ивенты server, пока нет PG + H4/H6.
