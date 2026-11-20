# Передача · MAP-01 stage list / squad power / scroll

Срез 20 ноября 2026. Ветка: `cursor/fix-stage-list-bind-scroll-d5fe`.

**Причина бага:** `StageListItem.set_stage()` вызывался до `add_child` → `@onready` null → плейсхолдеры «Основной · Этап». `apply_server_player` писал `power = 0`. Полная ширина кнопки «Карточка» блокировала drag-scroll.

**Сделано:** bind после add_child + pending apply; клиентская оценка power по пакету; DragPad + mouse_filter IGNORE на chrome строки; FightBtn для `current`.

Headless: 30 уникальных CH01 строк, squad_power>0.

## Next

1. Merge → VPS APK → проверить список этапов / силу отряда / скролл.
2. Владелец: ART-05 / H6 / AUTH-04 device OK.
3. Wave4 UI (hero_details / squad / auth).
