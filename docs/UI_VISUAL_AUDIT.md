# Аудит UI · готовность к визуальному редактору Godot

Дата: 2026-11-20 · ветка `cursor/godot-visual-editor-ready-d5fe` · Godot **4.7.2**  
Источник: все `scenes/**/*.tscn` + связанные `.gd`, `theme/`, `scripts/ui/`, `assets/ui/`.

## 1. Краткий вывод

Большинство игровых экранов — **скелет в `.tscn` + полное наполнение через `UIFactory` / `DemoScreenBuilder` в GDScript**. Shell (TopBar, BottomNav), bootstrap и часть DEMO-экранов уже визуально открываются. Цель миграции: статический chrome и оформление → `.tscn` / Theme / PackedScene; данные и логика → скрипт.

| Готовность | Кол-во | Смысл |
|---|---:|---|
| HIGH | 16 | Сцена почти самодостаточна или тонкий скрипт |
| MED | 3 | Есть структура, часть chrome в коде |
| LOW | 3 | Скелет + заметная динамика |
| CODE_HEAVY | 24 | Списки/карточки/кнопки создаются в коде |

## 2. Общая архитектура (как есть)

| Слой | Файлы | Роль |
|---|---|---|
| Theme | `theme/lunex_theme.tres` + `ThemeManager` + `content/packages/0.9.0/theme.json` | Глобальная тема проекта; runtime-палитра из пакета |
| Фабрика | `scripts/ui/ui_factory.gd`, `lunex_colors.gd` | Кнопки/панели/лейблы **кодом** |
| DEMO-сборщик | `scripts/ui/demo_screen_builder.gd` | VIP/чат/друзья и др. — весь UI в VBox |
| Навигация | `ScreenRouter`, `GameShell` overlays | Вкладки + стек оверлеев |
| Контент | `content/packages/0.9.0/` (в т.ч. `theme.json` внутри пакета) | Hub buildings, shell chrome, палитра |

**Зависимость от сервера:** `ApiClient` / `DemoData` на боевых, экономике, профиле. Визуальный preview не должен звать API.

**Адаптивность:** viewport 1080×1920, stretch `canvas_items` + `expand`, Android safe-area в `GameShell`. Много `custom_minimum_size` и абсолютных offset в хабе.

## 3. Таблица экранов

Легенда готовности: **HIGH** — править мышкой сейчас; **MED** — частично; **LOW** / **CODE_HEAVY** — нужна миграция.

| Экран | Путь | Узлы .tscn | Динамика (оценка) | Сервер/данные | Visual-ready | Что править мышкой сейчас | Что остаётся кодом | Риск Android |
|---|---|---:|---:|---|---|---|---|---|
| Splash | `bootstrap/splash.tscn` | 11 | 0 | нет | HIGH | фон, лого, подписи | таймер перехода | низкий |
| Version check | `bootstrap/version_check.tscn` | 6 | 0 | нет | HIGH | лейблы | логика версии | низкий |
| Asset bootstrap | `bootstrap/asset_bootstrap.tscn` | 8 | 0 | пакет | HIGH | прогресс-бар layout | загрузка | низкий |
| World select | `bootstrap/world_select.tscn` | 9 | 0 | сессия | HIGH | кнопки миров | вход в shell | низкий |
| Auth | `bootstrap/auth.tscn` | 20 | высокая | API | CODE_HEAVY | часть полей в сцене | вкладки login/signup кодом | средний |
| Game shell | `shell/game_shell.tscn` | 19 | средняя | — | CODE_HEAVY | слои, fade | вкладки, overlays | safe-area |
| Top bar | `shell/top_bar.tscn` | 11 | низкая | wallet | MED | кнопки, отступы, подписи | тексты валют, стили из пакета | hit area |
| Bottom nav | `shell/bottom_nav.tscn` | 7 | низкая | shell.json | MED | 4 вкладки, высота | иконки/лейблы из пакета | hit area ≥ |
| Hub | `hub/hub_root.tscn` | 10 | высокая | hub.json | CODE_HEAVY | SideRail, Scroll/World | здания, parallax, rail-кнопки | WORLD 1080×2400 |
| Map root | `map/map_root.tscn` | 10 | средняя | campaign | LOW | фон/скролл | регионы | средний |
| Chapter map | `map/chapter_map.tscn` | 10 | средняя | campaign | LOW | контейнеры | узлы этапов | средний |
| Stage card | `map/stage_card.tscn` | 12 | низкая | stage | MED | карточка layout | тексты/кнопки боя | низкий |
| Heroes root | `heroes/heroes_root.tscn` | 12 | высокая | heroes | CODE_HEAVY | фильтры/хост | сетка героев | списки |
| Hero details | `heroes/hero_details.tscn` | 5 | высокая | hero | CODE_HEAVY | Safe/Scroll | весь контент | средний |
| Squad | `heroes/squad_manager.tscn` | 5 | высокая | formation | CODE_HEAVY | скелет | слоты | средний |
| Battle modes | `battle/battle_modes_root.tscn` | 7 | средняя | — | LOW | список режимов-хост | кнопки режимов | низкий |
| Formation | `battle/formation.tscn` | 5 | высокая | battle API | CODE_HEAVY | Safe/Scroll | отряд, старт | средний |
| Playback | `battle/battle_playback.tscn` | 12 | высокая | timeline | CODE_HEAVY | Field/HUD/Controls | юниты, FX | полный экран |
| Result | `battle/battle_result.tscn` | 4 | высокая | claim | CODE_HEAVY | BG/Safe | title+nav кодом → миграция | низкий |
| Settings | `features/settings.tscn` | 8 | высокая | local | CODE_HEAVY | Header/Tabs/Scroll | содержимое вкладок | средний |
| Shop / Summon / AFK / Mail / … | `features/*.tscn` | ~5 | высокая | API/пакет | CODE_HEAVY | Safe/Scroll/VBox | списки/кнопки | списки |
| VIP / Chat / Friends / Rankings / … | `features/*` + DemoScreenBuilder | 5 | через builder | пакет/демо | HIGH* | скелет | секции builder → шаблоны | низкий |
| PvE / Guild / Events / Profile | `features/*` | 5 | высокая | пакет | CODE_HEAVY | скелет | карточки/рейды | средний |

\*HIGH по `.tscn`, но наполнение DEMO всё равно в коде через `DemoScreenBuilder`.

## 4. Повторно используемые куски (сейчас в коде)

| Паттерн | Где | Целевой компонент |
|---|---|---|
| `UIFactory.fantasy_button` / `gold_button` | почти везде | `GameButton`, `GoldButton` |
| `UIFactory.panel` / `panel_style` | хаб, модалки | `GamePanel` + StyleBox `.tres` |
| `currency_chip` | top bar conceptually | `ResourceCounter` |
| `hero_portrait` | бой, герои | `HeroCard` / portrait template |
| Safe + Scroll + VBox | features | `FeatureScreen` scaffold |
| Modal rewards | ModalManager | `PopupWindow` / `RewardCard` |
| TopBar / BottomNav | shell | уже сцены; усилить exports |

## 5. Что нельзя (или не стоит) полностью выносить в сцену

- Списки героев, почты, магазина, узлов карты — **шаблон карточки** + код наполнения.
- Боевые юниты и FX по timeline — данные сервера.
- Здания хаба — позиции из `hub.json` (контент), не дублировать 20 зданий в `.tscn`.
- Модалки очереди `ModalManager` — динамический стек.
- OTA/тема из пакета — оставить runtime, но **базовые StyleBox** править в `theme/`.

## 6. План миграции (фазы)

| Фаза | Содержание |
|---|---|
| A | Этот аудит |
| B | Theme StyleBox `.tres`, библиотека `scenes/ui/components/*` |
| C | FeatureScreen + DemoScreenBuilder на компоненты; Result/TopBar/Settings chrome |
| D | `ui_preview_root` без сервера; проверка адаптивности; тесты |
| E | HOW_TO + RULES + AGENTS.md |

## 7. Критерии «экран модернизирован»

1. Открывается в редакторе без ошибок.
2. Кнопки/панели/отступы chrome — в `.tscn` или Theme.
3. Динамика только в marked host-узлах (`DynamicHost`, `ListHost`).
4. `@export` для ключевых визуальных параметров.
5. Логика API/роутинга не в визуальных узлах.
