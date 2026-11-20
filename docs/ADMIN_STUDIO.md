# Lunex Admin Studio — комбайн дизайна и контента

Статус: локальный пайплайн. **Не игровой сервер** прогресса/валют/боя/платежей.

## Запуск

```bash
cd admin-studio
npm install
npm run dev
```

- UI http://127.0.0.1:5173  
- API http://127.0.0.1:8787  

## Модули

| Раздел | Файл пакета | Назначение |
|---|---|---|
| Theme Studio | `theme.json` | Палитра, радиусы, кнопки |
| Shell / Nav | `shell.json` | TopBar, вкладки, welcome |
| Строки | `strings.json` | UI-тексты / ключи |
| Motion | `motion.json` | Параллакс, pulse, FX |
| Ассеты | `assets.json` + `media/` | Реестр и upload |
| Хаб 2.0 | `hub.json` | Здания, фон, свет, side-rail |
| Кампания / герои / битва / фичи | соответствующие JSON | Контент экранов |
| Пакеты | `active.json` + history | publish / diff / rollback |

Клиент: `ContentPackageLoader` → `ThemeManager` / Shell / экраны **только читают**.

**OTA:** Publish → CDN `/cdn/*` → `ContentUpdateService` на клиенте качает в `user://` без новой APK. См. `docs/CONTENT_OTA.md`.

Схема: `docs/CONTENT_PACKAGE_SCHEMA.md`. Проверка: `tools/validate_content_package.sh`.
