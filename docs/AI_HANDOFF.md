# Передача проекта · ATOMIC-ECONOMY

Срез от 20 ноября 2026. Ветка: `cursor/atomic-economy-td-pg-race-d5fe`.

**Сделано:**

- `store.Run` / `RunAtomic` — мутации экономики в одной TX (PG) или с rollback snapshot (Memory)
- Battle claim, AFK claim, mail claim, shop confirm, summon roll — через Atomic Ops
- PG `ApplyLedger`: advisory lock + `FOR UPDATE` на `wallet_balances` (TD-PG-RACE)
- Тесты: memory atomic/rollback/concurrent; PG tests при `DATABASE_URL` (CI postgres-startup)
- VPS deploy после FIX-GODOT-DEPLOY-002 подтверждён владельцем

## Next (P1)

1. **H6 device verify** на свежем APK.
2. AUTH-04 / UI-SYNC-HEROES; ART-05.
3. Visual wave3: formation / settings / map nodes.
4. Опционально: `mail ClaimAll` тоже через `RunAtomic` (сейчас SaveMail до ledger).
