# Сборка Android APK — Lunex AFK 0.5.5

## Требования

- Godot 4.7.2
- Export Templates 4.7.2.stable
- Android SDK (platform 36, build-tools 36, NDK 27+)
- JDK 17+ (проверено на 21)
- Debug keystore (стандартный `~/.android/debug.keystore` или путь из editor settings)

## Настройка Godot Editor Settings

- `export/android/android_sdk_path` → каталог Android SDK
- `export/android/java_sdk_path` → JAVA_HOME
- `export/android/debug_keystore` + user/pass

В `project.godot` включено: `textures/vram_compression/import_etc2_astc=true`.

## Команда

```bash
mkdir -p builds
godot --headless --path . --export-debug "Android" builds/lunex-afk-online-v0.5.5-debug.apk
```

Пресет: `export_presets.cfg` (Android, arm64-v8a, package `com.lunex.afk`).

## Результат проверки (2026-11-20)

- APK успешно собран: `builds/lunex-afk-online-v0.5.5-debug.apk` (33 198 218 байт, debug-подпись).
- Каталог `builds/` в `.gitignore` — бинарники в git не коммитятся.
- Keystore и пароли release не хранятся в репозитории.
- Запуск на физическом устройстве: `adb install -r builds/lunex-afk-online-v0.5.5-debug.apk`.

Ориентация: портрет 9:16. Для входа и сохранения прогресса требуется доступ к API. Установка на физическом устройстве ожидает проверки.

SHA-256 опубликованного APK: `39c47e3d20aca16584b2648dd9589bffb358b8942ee4ca21584ea389cd8568bb`.
