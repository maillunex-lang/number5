# QUALITY_GATES — проверки качества

## Быстрые (перед коммитом)

```bash
python3 tools/check_repo_refs.py
tools/validate_content_package.sh 0.9.0   # или active
cd server && go test ./...
```

Если трогали Studio:

```bash
cd admin-studio && npm test 2>/dev/null; npm run build
```

Если трогали Godot сцены — желательно:

```bash
godot --headless --path . --quit-after 2
# опционально smoke: см. tools/smoke_flow.gd / SmokeRunner
```

## Перед merge в main

1. Все быстрые проверки PASS.  
2. CI workflow `content-and-studio` зелёный.  
3. STATUS/ROADMAP/AI_HANDOFF согласованы с диффом.  
4. Нет секретов в диффе.  
5. Старые пакеты `0.1.0`…`0.8.0` не rewrite.  

## Перед publish контента

1. `validate_content_package.sh <new_ver>` PASS.  
2. Манифест/hashes.  
3. Не затирать active чужим пакетом без записи в publish_history.  
4. OTA-1: Publish → клиент hot-reload (dev).  

## Перед APK

1. Export presets / Android docs.  
2. Smoke навигации.  
3. Нет зависимости от `127.0.0.1` в prod build (CDN/API URL).  

## Перед server release

1. `APP_ENV=prod` + `DATABASE_URL` (после H4 — обязателен).  
2. Migrate applied.  
3. grant/confirm-test недоступны (после H5).  
4. `/health` → store=postgres.  
5. Идемпотентность claim/summon проверена.  

## Stop-the-line

- Валидатор пакета FAIL.  
- `go test` FAIL.  
- Обнаружены секреты в git.  
- Rewrite опубликованного пакета.  
- Prod с memory store (после внедрения H4).  
- Выдача «настоящих» наград от локального боя без H6.

## Обёртка (опционально)

Можно добавить `tools/verify_project.sh` как вызов быстрых команд выше — без новых зависимостей.
