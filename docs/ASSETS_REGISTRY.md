# Реестр ассетов — Lunex AFK

В APK 0.5.5 входят фон мира в assets/login/background.webp и навигационные пиктограммы в assets/ui/navigation/. Они используются в хабе и навигации. ART-05 охватывает отдельные ассеты героев.

## UI / оболочка (вшито в клиент)

| ID | Путь / источник | Тип | Лицензия | Статус |
|---|---|---|---|---|
| FNT-01 | `fonts/Cinzel-Bold.ttf` | Шрифт display | OFL 1.1 (Google Fonts / fontsource) | Постоянный кандидат |
| FNT-02 | `fonts/OpenSans-Regular.ttf` | Шрифт UI | OFL 1.1 | Постоянный кандидат |
| FNT-03 | `fonts/OpenSans-SemiBold.ttf` | Шрифт UI | OFL 1.1 | Постоянный кандидат |
| ICO-01 | `assets/ui/icon.svg` | Иконка приложения | Собственная (прототип) | Временная |
| TEX-01 | `AssetLoader.make_gradient_texture` | Процедурный фон | Собственная | Временная |
| TEX-02 | `AssetLoader.make_radial_glow` | Процедурное свечение | Собственная | Временная |
| VIS-01 | Стилизованные портреты героев (`UIFactory.hero_portrait`) | Placeholder 2.5D | Собственная | Временная · слоты в C6 |
| VIS-02 | Панели/рамки `UIFactory.panel_style` | UI chrome | Собственная | База UI Kit |
| REF-01 | Идеи godot-ui-template (код не импортирован) | Референс | CC BY 4.0 | Атрибуция в THIRD_PARTY_LICENSES.md |

## Игровой контент (C6 · пакет `0.9.0`)

Источник истины: `content/packages/0.9.0/assets.json` (+ `media/**/*.json` descriptors).

| Категория | Кол-во слотов | Статус |
|---|---:|---|
| Герои H01–H45 (portrait/atlas/animations/ultimate_vfx) | 180 | placeholder / planned |
| Риги RIG-* (atlas + animations + skin_a/b) | 6×4 | placeholder |
| Портреты боссов B* | 18 | placeholder |
| Арт-пакеты глав (map + 6×bg/mid/fg + 3 arenas) | 6 пакетов | placeholder |
| Общие VFX / SFX | 12 + 12 | placeholder |

Bindings: `hero.H*.portrait`, `rig.RIG-*.atlas`, `enemy.E*|B*.visual`, `chapter.CHxx.map`, …  
UI: маршрут `ART-01` · карточка героя → вкладка «Арт».  
Бинарь (webp/ogg/атласы) подставляет **ART-05** без смены ID.

Чужие защищённые игровые изображения не используются.
