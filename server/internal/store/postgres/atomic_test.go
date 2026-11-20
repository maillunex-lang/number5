package postgres

import (
	"context"
	"os"
	"sync"
	"testing"

	"github.com/maillunex-lang/number5/server/internal/domain"
	"github.com/maillunex-lang/number5/server/internal/store"
)

func openTestStore(t *testing.T) *Store {
	t.Helper()
	url := os.Getenv("DATABASE_URL")
	if url == "" {
		t.Skip("DATABASE_URL not set")
	}
	ctx := context.Background()
	s, err := Open(ctx, url, []domain.Balance{{ResourceID: "gold", Amount: 100, Version: 1}})
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Migrate(ctx); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { s.Close() })
	return s
}

func TestPostgresConcurrentDebitNoOverdraw(t *testing.T) {
	s := openTestStore(t)
	acc, _, err := s.CreateGuest([]string{"H01"})
	if err != nil {
		t.Fatal(err)
	}
	// Normalize gold to 100 via atomic set delta.
	bals, err := s.WalletBalances(acc.ID)
	if err != nil {
		t.Fatal(err)
	}
	cur := int64(0)
	for _, b := range bals {
		if b.ResourceID == "gold" {
			cur = b.Amount
		}
	}
	if _, err := s.ApplyLedger(acc.ID, []domain.LedgerEntry{{
		ResourceID: "gold", Delta: 100 - cur, SourceType: "test_set", SourceID: "set",
	}}, "pg-set-"+string(acc.ID), "pg-set", []byte(`{}`), 200); err != nil {
		t.Fatal(err)
	}

	var wg sync.WaitGroup
	errs := make(chan error, 20)
	for i := 0; i < 20; i++ {
		wg.Add(1)
		i := i
		go func() {
			defer wg.Done()
			_, err := s.ApplyLedger(acc.ID, []domain.LedgerEntry{{
				ResourceID: "gold", Delta: -10, SourceType: "debit", SourceID: "d",
			}}, "pg-debit-"+string(acc.ID)+"-"+itoa(i), "h-"+itoa(i), []byte(`{}`), 200)
			errs <- err
		}()
	}
	wg.Wait()
	close(errs)
	ok := 0
	for e := range errs {
		if e == nil {
			ok++
		} else if e != store.ErrInsufficient {
			t.Fatalf("unexpected %v", e)
		}
	}
	after, _ := s.WalletBalances(acc.ID)
	got := int64(0)
	for _, b := range after {
		if b.ResourceID == "gold" {
			got = b.Amount
		}
	}
	if got < 0 {
		t.Fatalf("negative balance %d", got)
	}
	if got != 100-int64(ok)*10 {
		t.Fatalf("gold=%d ok=%d", got, ok)
	}
	if ok > 10 {
		t.Fatalf("too many successful debits: %d", ok)
	}
}

func TestPostgresAtomicClaimRollback(t *testing.T) {
	s := openTestStore(t)
	acc, _, err := s.CreateGuest([]string{"H01"})
	if err != nil {
		t.Fatal(err)
	}
	before, _ := s.WalletBalances(acc.ID)
	goldBefore := int64(0)
	for _, b := range before {
		if b.ResourceID == "gold" {
			goldBefore = b.Amount
		}
	}
	bid := "pg_bat_" + string(acc.ID)[:8]
	_ = s.SaveBattle(domain.BattleInstance{
		ID: bid, AccountID: acc.ID, StageID: "CH01-01", Status: "finished", Victory: true,
	})

	err = s.RunAtomic(acc.ID, func(ops store.Ops) error {
		if _, err := ops.ApplyLedger([]domain.LedgerEntry{{
			ResourceID: "gold", Delta: 777, SourceType: "battle_claim", SourceID: bid,
		}}, "pg-fail-"+string(acc.ID), "hf", []byte(`{}`), 200); err != nil {
			return err
		}
		if err := ops.MarkBattleClaimed(bid); err != nil {
			return err
		}
		return store.ErrNotFound
	})
	if err != store.ErrNotFound {
		t.Fatalf("want rollback trigger, got %v", err)
	}
	after, _ := s.WalletBalances(acc.ID)
	got := int64(0)
	for _, b := range after {
		if b.ResourceID == "gold" {
			got = b.Amount
		}
	}
	if got != goldBefore {
		t.Fatalf("gold rolled back want %d got %d", goldBefore, got)
	}
	b, _ := s.GetBattle(bid)
	if b.Claimed {
		t.Fatal("battle claim should roll back")
	}
}

func itoa(i int) string {
	if i == 0 {
		return "0"
	}
	var b [16]byte
	n := len(b)
	for i > 0 {
		n--
		b[n] = byte('0' + i%10)
		i /= 10
	}
	return string(b[n:])
}
