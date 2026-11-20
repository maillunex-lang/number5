# ART-05 — портреты / атласы / анимации в бою

Критерий ROADMAP: на устройстве видны реальные (или ART-05 placeholder) портреты и смены кадров атласа в COMBAT-02, не только цветные прямоугольники.

Код: `AssetLoader` грузит `content/packages/*/media/heroes|rigs/**/*.webp`; `BattleUnit` показывает atlas frames (`idle/attack/hit/death`); HUD-портреты и HeroCard/FormationSlot — portrait.webp. Генератор: `tools/generate_art05_placeholders.py`.

## Перед тестом

1. Свежий APK с `main` после merge ART-05 (бинари media должны быть в сборке; gitignore — `git add -f` или generate перед export).
2. Online-бой CH01-01 (или DEMO playback).

## Чеклист

| # | Шаг | Ожидание | ✓ |
|---|---|---|---|
| 1 | Отряд на подготовке | Слоты с портретами героев (не пустой tint-блок) | |
| 2 | Старт боя | На поле спрайты/атлас, не только ColorRect | |
| 3 | Удары timeline | У атакующего кадр attack, у цели hit; смерть → death | |
| 4 | HUD снизу | Портреты союзников с картинкой | |
| 5 | Враги | Rig atlas/skin (placeholder допустим) | |
| 6 | Коллекция героев | HeroCard с portrait | |

## Не баг

- Placeholder-силуэты (процедурный webp) до финального арта Studio — ожидаемо.
- Low-пресет режет FX, не атлас.

## После прогона

Владелец: **ART-05 device OK** (или FAIL #).
