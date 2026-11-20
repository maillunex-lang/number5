# Правила разработки UI · Lunex AFK (visual-first)

Обязательный стандарт для всех новых и изменяемых экранов. Дополняет `AGENTS.md`.

## 1. Visual-first

1. Сначала сцена `.tscn` (layout, chrome, отступы, тема).
2. Затем GDScript: данные, API, обработчики.
3. **Запрещено** собирать статический экран целиком через `Control.new()` / `UIFactory` без записи в аудит «почему нельзя в сцене».

## 2. Разделение UI и логики

| В сцене / Theme | В скрипте |
|---|---|
| Кнопки, панели, фон, иконки, margins | Вызовы `ApiClient`, claim, роутинг |
| `@export` внешнего вида | Заполнение `DynamicHost` / списков |
| StyleBox / Theme type variations | Условия победы, сессия, кошелёк |

Имена узлов, на которые ссылается код (`@onready`, `$Path`), **не переименовывать** без одновременного обновления скрипта.

## 3. Тема и компоненты

- Глобальная тема: `theme/lunex_theme.tres`.
- Редактируемые стили: `theme/styles/*.tres`.
- Библиотека: `scenes/ui/components/` (`GameButton`, `GoldButton`, `GamePanel`, `HeroCard`, `RewardCard`, `ResourceCounter`, `ProgressMeter`, `FeatureScreen`, `PopupWindow`, `SettingsSection`, `TabNavigation`).
- Shell: `scenes/shell/top_bar.tscn`, `bottom_nav.tscn` — не дублировать.
- Новые кнопки в коде — через `UIFactory.fantasy_button` / `gold_button` (они инстанцируют визуальные сцены).

## 4. Динамические списки

- Один **шаблон** PackedScene (карточка).
- Код только инстанцирует и вызывает `set_*` / заполняет поля.
- Не копировать 20 уникальных карточек в сцену списка.

## 5. Inspector

Использовать `@export`, `@export_group`, `@export_category` для:

- отступов и минимальных размеров;
- цветов фона;
- preview-текстов (только editor / preview).

`@tool` — осторожно: не вызывать API и `ScreenRouter` в editor-пути без `Engine.is_editor_hint()` guard.

## 6. Адаптивность (Android 9:16)

- Базовый viewport 1080×1920; stretch `canvas_items` + `expand`.
- Контейнеры и anchors вместо абсолютных координат для chrome.
- Мин. высота кнопки ≥ 64 px (логические).
- Учитывать safe-area (`GameShell`).
- Проверять мысленно/в редакторе: 720×1600, 1080×1920, 1080×2400, 1440×3200.

## 7. Preview

- Сцена `scenes/ui/preview/ui_preview_root.tscn` — без авторизации.
- Preview-данные не подменяют прод-сессию и не пишут прогресс на сервер.

## 8. Документация

При новом основном экране обновить:

- `docs/UI_VISUAL_AUDIT.md` (строка в таблице);
- при необходимости `docs/HOW_TO_EDIT_UI_IN_GODOT.md` (путь к сцене).

## 9. Запреты

- Не ломать публичные API ради UI.
- Не удалять рабочие экраны «под заглушку».
- Не зашивать уникальные цвета кнопок только в GDScript, если есть Theme type.
- Не делать массовый авто-rewrite всех `.tscn` без проверки запуска.
