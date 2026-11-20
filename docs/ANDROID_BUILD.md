# Сборка Android APK — Lunex AFK v0.1

## Требования

- Godot 4.7.2
- Export Templates 4.7.2.stable
- Android SDK (platform 34, build-tools 34, NDK 27+)
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
godot --headless --path . --export-debug "Android" builds/lunex_afk_v0.1_debug.apk
```

Пресет: `export_presets.cfg` (Android, arm64-v8a, package `com.lunex.afk`).

## Результат проверки (2026-11-20)

- APK успешно собран: `builds/lunex_afk_v0.1_debug.apk` (~28 МБ, debug-подпись).
- Каталог `builds/` в `.gitignore` — бинарники в git не коммитятся.
- Keystore и пароли release не хранятся в репозитории.
- Запуск на физическом устройстве: `adb install -r builds/lunex_afk_v0.1_debug.apk`.

Ориентация: портрет 9:16. Онлайн-сервер не требуется для прототипа.
