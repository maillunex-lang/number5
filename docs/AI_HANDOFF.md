# Передача проекта · Android 0.5.5 + H6 code

Срез от 20 ноября 2026. Исходники клиента, API и Studio синхронизированы с версией VPS, плюс ветка H6 (серверная timeline → COMBAT-02 playback). Рабочие документы — [статус](STATUS.md) и [приоритеты с критериями приёмки](ROADMAP.md).

**P0 приёмка APK на физическом телефоне подтверждена владельцем.** Следующий шаг: собрать APK с H6-клиентом и на устройстве проверить playback ↔ timeline, reconnect (`GET /api/v1/battle/{id}`) и повтор claim.

Версионные SQL-файлы встроены в API. Для повторной проверки на отдельной PostgreSQL 16 используется tools/check_postgres_startup.py и задание postgres-startup в GitHub Actions.

Публичный Web отключён. При изменениях клиента сохранять раздачу Android APK, API и HTTPS CDN. Исторические отчёты прототипа относятся к своим версиям.

## Next для другого ИИ

1. Device verify H6 (после APK с новым `battle_playback.gd`).
2. ATOMIC-ECONOMY / TD-PG-RACE.
3. AUTH-04 + UI-SYNC-HEROES на Android.
4. ART-05.
