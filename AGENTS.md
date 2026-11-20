# AGENTS.md — правила для ИИ-исполнителей

Проект: **Lunex AFK** «Башкортостан: Разлом эпох» · репо `maillunex-lang/number5` · ветка истины **`main`**.

Этот файл — единый контракт для Cursor, Codex, Claude Code, Kimi и других агентов.

---

## 1. Кратко о проекте

Вертикальная (9:16) Anime Fantasy AFK/Idle RPG. Клиент Godot 4.7.2 для Android, сервер Go modular monolith, хранилище PostgreSQL 16 на VPS Lunex, контент версионированными JSON-пакетами, Lunex Admin Studio (React/TS).

## 2. Стек

| Слой | Технология |
|---|---|
| Клиент | Godot **4.7.2**, GDScript, autoloads |
| API | Go 1.22, `net/http`, пакеты `server/internal/modules/*` |
| Store | `store.Memory` (dev) · `store/postgres` (код; prod обязателен) |
| Контент | `content/packages/{ver}/` + `active.json` |
| Studio | `admin-studio/` Vite + Express |
| CI | `.github/workflows/content-and-studio.yml` |

## 3. Карта репозитория

```
scenes/ scripts/     — Godot UI
content/packages/    — игровые данные (не прогресс игрока)
server/              — CORE-01 API
admin-studio/        — редакторы + CDN dev
docs/                — канон, статус, ТЗ
docs/content/        — игровой канон (сюжет/экономика/…)
tools/               — validate / generate / refs
AGENTS.md            — этот файл
```

## 4. Источник истины

| Вопрос | Где смотреть |
|---|---|
| Что реально сделано | `docs/STATUS.md`, код, тесты |
| Задачи / приоритеты | `docs/ROADMAP.md` |
| Передача ИИ | `docs/AI_HANDOFF.md` |
| Сюжет, герои, награды | `docs/content/*` (канон) + пакет `0.9.0` |
| API контракт | `docs/TZ_A_FOUNDATION.md` + `server/internal/httpapi/mux.go` |
| UI навигация | **4 вкладки** — `docs/STRUCTURE.md`, `docs/GDD.md` NAV-001 |
| Аудит / долг | `docs/AUDIT_REPORT.md`, `docs/TECH_DEBT.md` |
| Проверки | `docs/QUALITY_GATES.md` |

Приоритет при конфликте: **решение пользователя** → канон GDD/content → поведение кода → ТЗ → исторические docs.

## 5. Запрещено без согласования

- Менять сюжет, героев, статы, награды, баланс.
- Rewrite / удалять опубликованные пакеты `0.1.0`…`0.8.0`.
- Ломать публичные API без миграции.
- Удалять миграции SQL.
- Подключаться к БД **Nexus AI** или менять чужой стек на VPS.
- Деплой, смена доменов, секреты в git, реальные платежи.
- Force push / rewrite history / `reset --hard` чужой работы.
- Объявлять систему **DONE** без критериев приёмки и проверок.

## 6. Как выбрать задачу

1. Прочитать `docs/AI_HANDOFF.md` и `docs/STATUS.md`.  
2. Взять следующую **P0/P1** из `docs/ROADMAP.md` без открытого блокера.  
3. Проверить, нет ли уже реализации (grep / mux / scenes).  
4. Работать в ветке `cursor/<topic>-9d0b`.

## 7. Проверка «уже сделано?»

- API: `server/internal/httpapi/mux.go`  
- Клиент online: `scripts/autoload/api_client.gd` + feature scenes  
- Данные: `content/packages/0.9.0/` + `tools/validate_content_package.sh`  
- Статус: не верь шапке канона без STATUS/IMPLEMENTATION  

## 8. Git

- Ветка от актуального `main`: `cursor/<desc>-9d0b`.  
- Не коммитить секреты, `.env`, бинари без нужды.  
- PR в `main`; после зелёного CI **merge в `main` по умолчанию** (решение владельца 2026-11-20), если нет блокера/ревью-запрета.
- Не трогать чужие незакоммиченные изменения.

## 9. Контент-пакеты

- Клиент читает только `active.json` → версию.  
- Новые данные — новый package version (не rewrite старых).  
- Active пишет генератор C6 (`generate_assets_c6_package.py`) или явный publish Studio.  
- Валидатор обязателен перед merge.

## 10. API и БД

- Интерфейс persistence: `store.Store`.  
- **Prod (H4):** только Postgres; memory fallback запрещён.  
- **Test endpoints (H5):** `grant-test` / `confirm-test` только `APP_ENV=test`.  
- **Бой (H6):** сервер считает результат/timeline; клиент воспроизводит; claim однократный.  
- Миграции: `server/migrations/`; не edit applied history без согласования.

## 11. Документация после задачи

Обязательно обновить затронутые: `STATUS` и/или `ROADMAP`, при необходимости `AI_HANDOFF`, `TECH_DEBT`.  
Не плодить параллельные «источники статуса».

## 12. Обязательные проверки

См. `docs/QUALITY_GATES.md`. Минимум перед PR:

```bash
tools/validate_content_package.sh 0.9.0
python3 tools/check_repo_refs.py
cd server && go test ./...
```

## 13. Секреты

Никогда не коммитить пароли, токены, `DATABASE_URL` с кредами. Использовать env / секреты хоста. Не читать/менять чужие контейнеры на VPS.

## 14. Формат отчёта

1. Цель задачи  
2. Что сделано (файлы)  
3. Что не сделано / блокеры  
4. Команды тестов + результаты  
5. Изменения STATUS/ROADMAP/HANDOFF  
6. Следующий шаг для другого ИИ  

## 15. Передача следующему ИИ

Обновить `docs/AI_HANDOFF.md` (статус, коммит, next tasks).  
Не перезаписывать чужую незавершённую ветку молча — отдельная ветка / согласование.  
Процесс: `docs/AI_WORKFLOW.md`.
