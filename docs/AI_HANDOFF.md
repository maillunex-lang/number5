# Передача проекта · Android 0.5.5 + H6 code

Срез от 20 ноября 2026. Исходники клиента, API и Studio синхронизированы с версией VPS, плюс ветка H6 (серверная timeline → COMBAT-02 playback). Рабочие документы — [статус](STATUS.md) и [приоритеты с критериями приёмки](ROADMAP.md).

**P0 приёмка APK на физическом телефоне подтверждена владельцем.** H6 code смержен в `main` (PR #8). Фикс «В хаб» после боя: не rewind стека оверлеев (`clear_overlays` / `switch_tab`). Следующий шаг: APK с H6+fix и device verify playback.

**Процесс:** владелец поручил после зелёного CI **всегда merge PR в `main` по умолчанию**.

Версионные SQL-файлы встроены в API. Для повторной проверки на отдельной PostgreSQL 16 используется tools/check_postgres_startup.py и задание postgres-startup в GitHub Actions.

Публичный Web отключён. При изменениях клиента сохранять раздачу Android APK, API и HTTPS CDN. Исторические отчёты прототипа относятся к своим версиям.

## Next для другого ИИ

1. Device verify H6 (после APK с новым `battle_playback.gd`).
2. ATOMIC-ECONOMY / TD-PG-RACE.
3. AUTH-04 + UI-SYNC-HEROES на Android.
4. ART-05.
