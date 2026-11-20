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
| Feature sections | `scripts/ui/feature_section_host.gd` | демо-секции в DynamicHost |
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
| Auth | `bootstrap/auth.tscn` | ~30 | средняя | API | MED* | Card/Tabs/Email/Password/Login/Guest Theme | parallax + API + _adapt_layout | средний |
| Game shell | `shell/game_shell.tscn` | 19 | средняя | — | CODE_HEAVY | слои, fade | вкладки, overlays | safe-area |
| Top bar | `shell/top_bar.tscn` | ~14 | низкая | wallet | HIGH* | Profile/Shop/Settings + 3×ResourceCounter | wallet sync + shell.json chrome | hit area |
| Bottom nav | `shell/bottom_nav.tscn` | ~10 | низкая | shell.json | HIGH* | 4×GameButton, exports | иконки/лейблы из пакета | hit area ≥ |
| Hub | `hub/hub_root.tscn` | 10 | высокая | hub.json | LOW* | SideRail, Scroll/World | здания через `HubBuilding` + JSON позиции | WORLD 1080×2400 |
| Map root | `map/map_root.tscn` | ~12 | средняя | campaign | MED* | Header, Landscape, Scroll | регионы через `MapRegionButton` | средний |
| Chapter map | `map/chapter_map.tscn` | ~12 | средняя | campaign | MED* | Header/Continue/Back | список через `StageListItem` | средний |
| Stage card | `map/stage_card.tscn` | ~14 | низкая | stage | HIGH* | Card/Pad/кнопки Theme | DialogHost опционально | низкий |
| Heroes root | `heroes/heroes_root.tscn` | 12 | высокая | heroes | MED* | фильтры/хост | сетка через `HeroCard` | списки |
| Hero details | `heroes/hero_details.tscn` | ~20 | средняя | hero | MED* | Title/Portrait/Tabs/Back | TabContentHost | средний |
| Squad | `heroes/squad_manager.tscn` | ~20 | средняя | formation | MED* | 5×FormationSlot, Back | PresetsHost + HeroesHost (HeroCard) | средний |
| Battle modes | `battle/battle_modes_root.tscn` | 7 | средняя | — | LOW | список режимов-хост | кнопки режимов | низкий |
| Formation | `battle/formation.tscn` | ~20 | средняя | battle API | MED* | labels, 5×FormationSlot, Start/Edit/Back | PresetsHost + battle_start | средний |
| Playback | `battle/battle_playback.tscn` | 12 | высокая | timeline | MED* | Field/HUD/Controls | юниты через `BattleUnit` + timeline | полный экран |
| Result | `battle/battle_result.tscn` | ~12 | низкая | claim | MED* | Title/ClaimProgress/Status/Meta/Nav Theme | claim API + тексты | низкий |
| Settings | `features/settings.tscn` | ~18 | средняя | local | MED* | Title/Close/5 Tabs/ContentPanel | DynamicHost вкладок | средний |
| Mail | `features/mail.tscn` | ~14 | средняя | API | MED* | Title/Tabs/ListHost/ClaimAll | MailItem + claim | средний |
| Shop | `features/shop.tscn` | ~18 | средняя | API | MED* | Title/Banner/Tabs/ListHost | ShopOfferCard + buy | средний |
| AFK | `features/afk_rewards.tscn` | ~14 | низкая | API | MED* | Title/Accum/Chest/Collect | status/claim | низкий |
| Summon | `features/summon.tscn` | ~16 | средняя | API | MED* | Title/BannersHost/Art/Actions | roll/pity API | средний |
| VIP | `features/vip.tscn` | ~12 | низкая | пакет | MED* | Title/Status/Back/DynamicHost | секции в host | низкий |
| Social hub | `features/social_hub.tscn` | ~10 | низкая | демо | MED* | Title/Back/DynamicHost | route-кнопки | низкий |
| Chat | `features/chat.tscn` | ~12 | низкая | демо | MED* | Title/Back/DynamicHost | FeatureSectionHost | низкий |
| Friends | `features/friends.tscn` | ~12 | низкая | демо | MED* | Title/Back/DynamicHost | FeatureSectionHost | низкий |
| Rankings | `features/rankings.tscn` | ~12 | низкая | демо | MED* | Title/Back/DynamicHost | FeatureSectionHost | низкий |
| Battle pass / PvP / Profile / Rewards / Sys | `features/*.tscn` | ~12 | низкая | пакет/демо | MED* | Title/Back/DynamicHost | FeatureSectionHost | низкий |
| Quests | `features/quests.tscn` | ~14 | средняя | пакет | MED* | Title/Tabs/ListHost | quest cards | средний |
| Expeditions | `features/expeditions.tscn` | ~12 | низкая | пакет | MED* | Title/ListHost | mission cards | низкий |
| Guild / Events | `features/*` | 5 | высокая | пакет | CODE_HEAVY | скелет | карточки/рейды | средний |

\*MED: chrome в `.tscn`, секции через `FeatureSectionHost` (не полный visual-edit содержимого панели).

## 4. Повторно используемые куски (сейчас в коде)

| Паттерн | Где | Целевой компонент |
|---|---|---|
| `UIFactory.fantasy_button` / `gold_button` | почти везде | `GameButton`, `GoldButton` |
| `UIFactory.panel` / `panel_style` | хаб, модалки | `GamePanel` + StyleBox `.tres` |
| `currency_chip` | top bar conceptually | `ResourceCounter` |
| `hero_portrait` | бой, герои | `HeroCard` / portrait template |
| Safe + Scroll + VBox | features | `FeatureScreen` scaffold |
| Modal rewards | ModalManager | `PopupWindow` / `RewardCard` |
| TopBar / BottomNav | shell | HIGH*: ResourceCounter + GameButton + Inspector exports |

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
| Wave2 | HubBuilding, BattleUnit, HeroCard, MailItem, ShopOfferCard |
| Wave3 | Formation chrome+slots; Settings tabs; Map landscape+MapRegionButton; StageListItem; stage_card Theme |
| Wave4 | Hero details chrome+tabs; Squad FormationSlot+HeroCard; Auth form Theme; settings account Theme buttons |
| Wave5 | BattleResult ClaimProgress/Status; VIP + SocialHub off DemoScreenBuilder |
| Wave5+ | Chat / Friends / Rankings Theme hosts; FeatureSectionHost helper |
| Wave6 | BattlePass/PvP/Profile/Rewards/Sys off DemoScreenBuilder (builder unused) |
| Wave7 shell | TopBar ResourceCounter + BottomNav exports; DemoScreenBuilder removed |
| Wave8 lists | Mail/Shop/AFK Theme chrome + ListHost (claim/buy API intact) |
| Wave9 summon | Summon altar Theme chrome; roll/pity API intact |
| Wave10 quests | Quests + Expeditions Theme chrome + ListHost |

## 7. Критерии «экран модернизирован»

1. Открывается в редакторе без ошибок.
2. Кнопки/панели/отступы chrome — в `.tscn` или Theme.
3. Динамика только в marked host-узлах (`DynamicHost`, `ListHost`).
4. `@export` для ключевых визуальных параметров.
5. Логика API/роутинга не в визуальных узлах.
