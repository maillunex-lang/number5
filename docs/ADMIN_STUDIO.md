# Lunex Admin Studio + версионные пакеты

Статус: локальный контент-пайплайн для прототипа. **Не игровой сервер** прогресса, валют, боёв и платежей.

## Схема

```
Admin Studio (React/TS)  --publish-->  content/packages/{version}/
                                              |
                                              v
                                     active.json (указатель)
                                              |
                                              v
                              Godot ContentPackageLoader (только чтение)
                                              |
                                              v
                                         DemoData / экраны рисуют UI
```

## Пакет

Путь: `content/packages/0.1.0/`

| Файл | Назначение |
|---|---|
| `manifest.json` | Версия, schema, sha256 хеши |
| `hub.json` | Здания хаба, side-rail |
| `campaign.json` | Регионы, этапы, рёбра |
| `heroes.json` | Герои, экип, пресеты |
| `battle_modes.json` | Порталы вкладки «Битва» |
| `features.json` | Магазин/квесты/AFK/ивенты (демо-контент) |
| `../active.json` | Какую версию читает клиент |

## Запуск Studio

```bash
cd admin-studio
npm install
npm run dev
```

- UI: http://127.0.0.1:5173  
- API: http://127.0.0.1:8787 (`/api/health`)

Редакторы: хаб (drag-and-drop), кампания, герои, режимы битвы, версии/публикация.

После **«Опубликовать для клиента»** Godot подхватит файлы из `res://content/packages` при следующем запуске (или перезагрузке пакета).

## Клиент Godot

Autoload `ContentPackageLoader` → `DemoData` наполняется из JSON.  
Хаб, карта, битва, магазин читают пакет. Игрок не может сохранить «серверный» прогресс через пакет.

## Дальше (не в этом шаге)

- Go admin API + PostgreSQL вместо файлового API  
- Раздача пакетов по HTTPS + кеш на устройстве  
- Подпись/откат версий в проде  
- Полный визуальный превью-рендер Godot в браузере
