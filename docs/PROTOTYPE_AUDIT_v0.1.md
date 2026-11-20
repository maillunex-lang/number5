# Lunex AFK UI Prototype v0.1 — Аудит репозитория (Этап 1)

Дата: 2026-11-20  
Ветка: `cursor/lunex-afk-ui-prototype-9d0b`  
Godot: 4.7.2.stable.official

## Что уже есть на main

| Путь | Состояние |
|---|---|
| `docs/STRUCTURE.md` | Полный реестр экранов UI-05…UI-14 — **главный источник** |
| `docs/ARCHITECTURE.md` | Целевая клиент/сервер архитектура |
| `docs/CONTENT.md` | Мир Элиориан (частично утверждён) |
| `docs/GDD.md`, `MVP.md`, `ROADMAP.md` | Проектные документы |
| `README.md` | Заглушка |
| Godot-проект | **Отсутствует** на main |

## Соседняя ветка `cursor/afk-mmo-godot-shell-94bf`

Черновой UI-shell (Godot 4.3, несоответствие утверждённой навигации: «More» вместо 4 вкладок).  
Переиспользуем только шрифты Cinzel/OpenSans. Сцены и логика **не** переносятся — строим заново под STRUCTURE.md.

## Референс godot-ui-template

- Лицензия: **CC BY 4.0** (Mario Brandao) — допустимо с атрибуцией.
- Целевая версия шаблона: Godot **4.2** + C#/addons.
- Решение: **не импортировать** исходники напрямую (несовместимость 4.2→4.7.2, лишние GamePersistence/GameSaver для серверного прогресса).  
  Реализуем собственный Lunex UI Kit по идеям: Router, переходы, модалки, ControlBlocker, тема.

## Отсутствующие компоненты (к реализации)

1. `project.godot` + дерево сцен STRUCTURE-04  
2. GameShell: TopBar, BottomNav (Карта/Герои/Главная/Битва), ScreenRouter, ModalManager, NotificationManager, UIStateManager, AssetLoader, ThemeManager  
3. Bootstrap: Splash → Version → Assets → Auth → WorldSelect  
4. Hub 2.5D (8 зданий), Map, Heroes, Battle modes  
5. Formation / Demo battle 5v5 / Result  
6. Все экраны реестра UI-14 (демо-статус где нет полного функционала)  
7. Графические пресеты Low/Med/High/Ultra  
8. Android export + документация фактической реализации  
9. Реестр временных ассетов

## Ограничения v0.1

- Локальные демо-данные; **не** выдавать за серверные.
- Без платёжных интеграций и фиктивного сервера.
- Без публикации на домен / изменений VPS.
- Пароли не хранить в локальных файлах (гость без настоящей auth).
