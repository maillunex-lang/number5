# Lunex AFK — статус

Дата: **2026-11-20** · истина: **`main`** · пакет: **`0.9.0`** · аудит: `docs/AUDIT_REPORT.md`

## Есть (проверено)

- Контент **C0–C6**: 180 этапов, 45 героев, E/P/G/meta, арт-реестр (без бинарей).
- Godot UI Prototype v0.1 + **4 вкладки** + Admin Studio.
- OTA hot-reload (**dev** HTTP через Studio CDN).
- **CORE-01 memory**: auth guest, wallet, heroes, campaign, battle, summon, afk, mail, store VIRTUAL_FREE.
- **Postgres adapter** в коде (`server/internal/store/postgres`); runtime Lunex DB — нет.
- **UI-02**: `ApiClient` — guest + summon/AFK/shop/mail/battle claim (fallback DEMO).

## Блокеры (уточнено аудитом)

| Что | Почему |
|---|---|
| **Lunex production PG** | VPS существует, но нет **изолированной** БД/стека Lunex. Нельзя использовать БД Nexus AI. |
| **OTA-2 CDN HTTPS** | Нет публичного `cdn_base` для пакетов. |
| **ART-05** | Нет бинарных webp/атласов (слоты в `0.9.0`). |

Утверждённые требования (ещё не в коде): **H4** prod без memory fallback; **H5** grant/confirm-test только `APP_ENV=test`; **H6** server timeline → client playback. См. `docs/TECH_DEBT.md`.

## Быстрая проверка

```bash
tools/validate_content_package.sh 0.9.0
python3 tools/check_repo_refs.py
cd server && go test ./...
```

Дальше: `docs/ROADMAP.md` · `docs/AI_HANDOFF.md` · `AGENTS.md`.
