# Lunex AFK — текущий статус репозитория

Дата: 2026-11-20 · активный пакет: **`0.4.0`** (Разлом эпох + экономика + PvE)

## Сейчас есть

- Пакет **0.4.0**: всё из 0.3.0 + `pve_modes.json` (Башня 120, Охота, Врата F01–F06, 4 подземелья).
- Порядок: C spine → E0–E4 экономика → **P0–P2 PvE** (не ждать C4).
- UI: порталы битвы + экран «Испытания» читают пакет (DEMO).
- Канон: `docs/content/PVE_MODES.md`.

## Сейчас нет

- Серверные попытки/урон/claim (P3 / CORE-01).
- Полные stages CH02–06 (C4) — режимы с unlock CH02 пока закрыты по условию.
- HTTPS OTA-2.

## Запуск

```bash
godot --path .
tools/validate_content_package.sh 0.4.0
python3 tools/generate_pve_package.py
```
