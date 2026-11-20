# Lunex AFK — текущий статус репозитория

Дата: 2026-11-20 · ветка истины: **`main`**

## Сейчас есть

- Godot **4.7.2** клиентский UI-прототип (локальные демо-данные).
- Версионные пакеты `content/packages/0.1.0/` + `ContentPackageLoader` (клиент только читает).
- Lunex Admin Studio (`admin-studio/`) — React/TS + Express; **Visual Editor 2.0** хаба (телефон 9:16 ≈ Godot).
- Документы: GDD, MVP, STRUCTURE, ARCHITECTURE, CONTENT-01, ROADMAP, ADMIN_STUDIO.

## Сейчас нет (и это ожидаемо)

- Go API / PostgreSQL / Docker Compose игрового сервера.
- Серверный бой, прогресс, призыв, AFK-выдача, платежи.
- Утверждённый CONTENT-02+ (фракции, полный ростер, 30 этапов, экономика).
- Боевой арт-пайплайн (GLB → атласы) и релизная подпись APK.
- Публикация на домен / изменения VPS.

## Как запускать

```bash
godot --path .                                 # клиент
cd admin-studio && npm install && npm run dev  # Studio :5173 + API :8787
tools/validate_content_package.sh              # проверка пакета
```

Подробности: `README.md`, `docs/ROADMAP.md`, `docs/ADMIN_STUDIO.md`.
