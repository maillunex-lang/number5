# Как менять интерфейс Lunex AFK в Godot (Windows)

Инструкция для владельца игры **без программирования**. Цель: двигать кнопки, менять цвета и картинки мышкой в редакторе сцен.

Версия движка: **Godot 4.7.2** (как в `project.godot`).

---

## 1. Установить Godot 4.7.2

1. Откройте [https://godotengine.org/download](https://godotengine.org/download).
2. Скачайте **Godot 4.7.2** Standard (Windows).
3. Распакуйте, например, в `C:\Godot\Godot_v4.7.2\`.
4. Не используйте Godot 3.x и не смешивайте с 4.2/4.3 без проверки — проект рассчитан на **4.7**.

---

## 2. Скачать проект с GitHub

1. Установите [GitHub Desktop](https://desktop.github.com/) или Git.
2. Клонируйте репозиторий `maillunex-lang/number5`, ветка **`main`**.
3. Путь может быть, например: `C:\Games\number5\`.

---

## 3. Открыть проект

1. Запустите Godot 4.7.2.
2. **Import** → укажите файл `project.godot` в корне репозитория.
3. Дождитесь импорта ресурсов.

---

## 4. Главные места интерфейса

| Что менять | Файл сцены |
|---|---|
| Верхняя панель (профиль, валюты) | `scenes/shell/top_bar.tscn` |
| Нижние 4 вкладки | `scenes/shell/bottom_nav.tscn` |
| Оболочка игры | `scenes/shell/game_shell.tscn` |
| Хаб (мир) | `scenes/hub/hub_root.tscn` |
| Итог боя (кнопки «В хаб») | `scenes/battle/battle_result.tscn` |
| Настройки (шапка + вкладки) | `scenes/features/settings.tscn` |
| Подготовка к бою | `scenes/battle/formation.tscn` |
| Карта мира / глава / этап | `map_root.tscn` / `chapter_map.tscn` / `stage_card.tscn` |
| Общие кнопки/панели | `scenes/ui/components/` |
| Карточка героя (сетка) | `scenes/ui/components/hero_card.tscn` |
| Здание хаба | `scenes/ui/components/hub_building.tscn` (позиции из `hub.json`) |
| Юнит боя | `scenes/ui/components/battle_unit.tscn` |
| Слот отряда / этап / регион | `formation_slot.tscn` / `stage_list_item.tscn` / `map_region_button.tscn` |
| Карточка героя / менеджер отряда | `heroes/hero_details.tscn` / `heroes/squad_manager.tscn` |
| Экран входа | `bootstrap/auth.tscn` (поля и кнопки в сцене) |
| Письмо / оффер магазина | `mail_item.tscn` / `shop_offer_card.tscn` |
| Цвета кнопок (на всех экранах) | `theme/styles/*.tres` и `theme/lunex_theme.tres` |
| Предпросмотр без сервера | `scenes/ui/preview/ui_preview_root.tscn` |

---

## 5. Переместить кнопку

1. Откройте нужную `.tscn` двойным щелчком.
2. В дереве слева выберите кнопку (например `HubBtn` в `battle_result.tscn`).
3. В 2D-виде перетащите мышью **или** меняйте отступы у родителя-контейнера (`MarginContainer` / `VBoxContainer`).
4. Если кнопка внутри `VBox`/`HBox`, порядок в дереве = порядок на экране (перетащите узел вверх/вниз).

---

## 6. Изменить размер кнопки

1. Выберите кнопку.
2. В Inspector найдите **Custom Minimum Size** (или у `GameButton` — `Min Height`).
3. Задайте высоту не меньше **64** (для пальца на Android лучше 64–72).

---

## 7. Заменить иконку

1. Положите PNG/SVG в `assets/ui/` (например `assets/ui/navigation/`).
2. Выберите кнопку с иконкой (нижняя навигация уже грузит файлы вроде `assets/ui/navigation/hub.svg`, `map.svg`, `heroes.svg`, `battle.svg`).
3. В Inspector у кнопки: **Icon** → Load → ваш файл.  
   Либо замените файл с тем же именем, чтобы подхватилось автоматически.

---

## 8. Поменять фон экрана

1. Откройте сцену (например `battle_result.tscn`).
2. Выберите узел `BG` (`ColorRect`).
3. В Inspector измените **Color**.  
   У `FeatureScreen` / `BattleResult` также есть экспорт `Bg Color` на корневом скрипте.

---

## 9. Изменить цвет панели / всех кнопок

**Одна кнопка:** StyleBox в Inspector у этой кнопки (перекроет тему).

**Все обычные кнопки сразу:**

1. Откройте `theme/styles/button_normal.tres` (также `button_hover`, `button_pressed`).
2. Меняйте `Bg Color`, `Border Color`, скругление.
3. То же для золотых: `theme/styles/gold_button_*.tres`.
4. Панели: `theme/styles/panel.tres`, модалки: `panel_modal.tres`.

Тема проекта подключена в `project.godot` → `gui/theme/custom = res://theme/lunex_theme.tres`.

---

## 10. Проверить результат без сервера

1. Откройте `scenes/ui/preview/ui_preview_root.tscn`.
2. Нажмите **F6** (Play Scene) — не F5 (F5 запускает splash/авторизацию).
3. Переключайте вкладки предпросмотра: компоненты, TopBar, итог боя, HeroCard и т.д.

Для полной игры: F5 и гостевой вход (нужен интернет/API).

Проверьте ориентиры экрана: в Project Settings viewport **1080×1920**. В редакторе удобно смотреть окно ~405×720 (уже задано override).

---

## 11. Сохранить

`Ctrl+S` для сцены. Если Godot спросит про `.uid`/импорт — согласитесь.

---

## 12. Отправить в GitHub безопасно

1. Создайте ветку, например `cursor/ui-tweaks-...` (не коммитьте напрямую в чужие ветки).
2. Коммитьте **только** изменённые `.tscn`, `.tres`, картинки и при необходимости `.gd`.
3. **Не коммитьте:** `.env`, ключи, APK, пароли.
4. Откройте Pull Request в `main`. После зелёного CI изменения обычно вливаются в `main`.

Через GitHub Desktop: Commit → Push → Create Pull Request.

---

## 13. Новый APK

Сборка описана в `docs/ANDROID_BUILD.md`:

```bash
mkdir -p builds
godot --headless --path . --export-debug "Android" builds/lunex-afk-online-debug.apk
```

Нужны Godot 4.7.2, Export Templates 4.7.2, Android SDK. Публикация на VPS — по вашему существующему пайплайну деплоя (агенты сами на VPS не выкладывают).

---

## Частые вопросы

**Почему список героев нельзя целиком разложить мышкой?**  
Карточки создаются из шаблона `scenes/ui/components/hero_card.tscn` по данным сервера. Правите **шаблон** — меняется вид всех карточек.

**Сломаю ли игру, двигая кнопку?**  
Не удаляйте узлы с именами, на которые ссылается скрипт (`AgainBtn`, `HubBtn`, `Pad/Row/Map` и т.п.). Можно двигать и менять стили; переименование узла без правки `.gd` сломает экран.

**Где правила для разработчиков?**  
`docs/UI_DEVELOPMENT_RULES.md` и раздел UI в `AGENTS.md`.
