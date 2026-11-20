package store_test

import (
	"fmt"
	"sync"
	"testing"

	"github.com/maillunex-lang/number5/server/internal/domain"
	"github.com/maillunex-lang/number5/server/internal/store"
)

func TestMemoryRunAtomicBattleClaimAllOrNothing(t *testing.T) {
	mem := store.NewMemory(nil)
	acc, _, err := mem.CreateGuest([]string{"H01"})
	if err != nil {
		t.Fatal(err)
	}
	before, err := mem.WalletBalances(acc.ID)
	if err != nil {
		t.Fatal(err)
	}
	goldBefore := bal(before, "gold")

	bid := "bat_atomic_1"
	_ = mem.SaveBattle(domain.BattleInstance{
		ID: bid, AccountID: acc.ID, StageID: "CH01-01", Status: "finished", Victory: true,
	})

	err = store.Run(mem, acc.ID, func(ops store.Ops) error {
		_, err := ops.ApplyLedger([]domain.LedgerEntry{{
			ResourceID: "gold", Delta: 1000, SourceType: "battle_claim", SourceID: bid,
		}}, "idem-a1", "hash-a1", []byte(`{}`), 200)
		if err != nil {
			return err
		}
		if err := ops.MarkBattleClaimed(bid); err != nil {
			return err
		}
		prog, err := ops.GetCampaign()
		if err != nil {
			return err
		}
		st := prog.Stages["CH01-01"]
		st.StageID = "CH01-01"
		st.Clears = 1
		st.FirstClearClaimed = true
		st.Stars = 3
		prog.Stages["CH01-01"] = st
		prog.CurrentStage = "CH01-02"
		return ops.SaveCampaign(prog)
	})
	if err != nil {
		t.Fatal(err)
	}

	after, _ := mem.WalletBalances(acc.ID)
	if bal(after, "gold") != goldBefore+1000 {
		t.Fatalf("gold want %d got %d", goldBefore+1000, bal(after, "gold"))
	}
	b, _ := mem.GetBattle(bid)
	if !b.Claimed {
		t.Fatal("battle not claimed")
	}
	prog, _ := mem.GetCampaign(acc.ID)
	if !prog.Stages["CH01-01"].FirstClearClaimed {
		t.Fatal("stage not claimed")
	}
}

func TestMemoryRunAtomicRollbackOnSideEffectError(t *testing.T) {
	mem := store.NewMemory(nil)
	acc, _, err := mem.CreateGuest([]string{"H01"})
	if err != nil {
		t.Fatal(err)
	}
	before, _ := mem.WalletBalances(acc.ID)
	goldBefore := bal(before, "gold")

	err = store.Run(mem, acc.ID, func(ops store.Ops) error {
		if _, err := ops.ApplyLedger([]domain.LedgerEntry{{
			ResourceID: "gold", Delta: 500, SourceType: "test", SourceID: "x",
		}}, "idem-fail", "hash-fail", []byte(`{}`), 200); err != nil {
			return err
		}
		return store.ErrNotFound // simulate mid-op failure → full rollback
	})
	if err != store.ErrNotFound {
		t.Fatalf("want ErrNotFound, got %v", err)
	}
	after, _ := mem.WalletBalances(acc.ID)
	if bal(after, "gold") != goldBefore {
		t.Fatalf("gold rolled back want %d got %d", goldBefore, bal(after, "gold"))
	}
	if _, err := mem.GetIdempotency(acc.ID, "idem-fail"); err != store.ErrNotFound {
		t.Fatalf("idempotency key should be rolled back, err=%v", err)
	}
}

func TestMemoryConcurrentDebitsDoNotOverdraw(t *testing.T) {
	mem := store.NewMemory([]domain.Balance{{ResourceID: "gold", Amount: 100, Version: 1}})
	acc, _, err := mem.CreateGuest([]string{"H01"})
	if err != nil {
		t.Fatal(err)
	}
	// Force wallet to known amount (CreateGuest may seed more).
	_ = store.Run(mem, acc.ID, func(ops store.Ops) error {
		bals, _ := ops.WalletBalances()
		cur := bal(bals, "gold")
		if cur == 100 {
			return nil
		}
		delta := 100 - cur
		_, err := ops.ApplyLedger([]domain.LedgerEntry{{
			ResourceID: "gold", Delta: delta, SourceType: "test_set", SourceID: "set",
		}}, "set-bal", "set-bal", []byte(`{}`), 200)
		return err
	})

	var wg sync.WaitGroup
	errs := make(chan error, 20)
	for i := 0; i < 20; i++ {
		wg.Add(1)
		i := i
		go func() {
			defer wg.Done()
			_, err := mem.ApplyLedger(acc.ID, []domain.LedgerEntry{{
				ResourceID: "gold", Delta: -10, SourceType: "debit", SourceID: "d",
			}}, fmt.Sprintf("debit-%d", i), fmt.Sprintf("h-%d", i), []byte(`{}`), 200)
			errs <- err
		}()
	}
	wg.Wait()
	close(errs)
	ok, fail := 0, 0
	for e := range errs {
		if e == nil {
			ok++
		} else if e == store.ErrInsufficient {
			fail++
		} else {
			t.Fatalf("unexpected err %v", e)
		}
	}
	after, _ := mem.WalletBalances(acc.ID)
	got := bal(after, "gold")
	if got < 0 {
		t.Fatalf("negative gold %d", got)
	}
	if got != 100-int64(ok)*10 {
		t.Fatalf("gold=%d ok=%d fail=%d", got, ok, fail)
	}
	if ok > 10 {
		t.Fatalf("too many successful debits: %d", ok)
	}
}

func bal(bs []domain.Balance, id string) int64 {
	for _, b := range bs {
		if b.ResourceID == id {
			return b.Amount
		}
	}
	return 0
}
