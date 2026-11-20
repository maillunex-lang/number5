# Number5

Клиентский каркас idle/MMO в духе AFK Arena на **Godot 4** (портрет 1080×1920).  
UI-шелл: авторизация, хаб, герои, гильдия, чат, магазин, бой 5×5. Механики и сервер — позже.

## Быстрый старт

1. Установите [Godot 4.3+](https://godotengine.org/download/).
2. **Import** → выберите папку этого репозитория (`project.godot`).
3. F5 — Boot → Auth → Main Hub.

Гостевой вход или любой username (пароль не проверяется).

## Навигация

| Экран | Как открыть |
|-------|-------------|
| Home / Heroes / Guild / Shop / More | Нижний таб-бар |
| Chat | TopBar → Chat или More |
| Battle | Home → Enter Battle или More |

## Структура

```
docs/GDD.md          — дизайн-каркас
scenes/              — экраны Godot
scripts/autoload/    — AppState, ScreenRouter
scripts/ui/          — палитра и стили
theme/               — Theme
fonts/               — Cinzel + Open Sans
```

## Документация

См. [docs/GDD.md](docs/GDD.md).

## Статус

Каркас UI без VPS, боевой симуляции и оплаты. Следующий шаг — механики поверх этих экранов.
