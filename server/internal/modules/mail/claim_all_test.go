package mail_test

import (
	"encoding/json"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/maillunex-lang/number5/server/internal/domain"
	"github.com/maillunex-lang/number5/server/internal/modules/content"
	"github.com/maillunex-lang/number5/server/internal/modules/mail"
	"github.com/maillunex-lang/number5/server/internal/store"
)

func TestClaimAllAtomicLedgerBeforeStatus(t *testing.T) {
	_, file, _, _ := runtime.Caller(0)
	root := filepath.Clean(filepath.Join(filepath.Dir(file), "..", "..", "..", "..", "content", "packages"))
	cat, err := content.LoadCatalog(root)
	if err != nil {
		t.Fatal(err)
	}
	mem := store.NewMemory(nil)
	acc, _, err := mem.CreateGuest([]string{"H01"})
	if err != nil {
		t.Fatal(err)
	}
	svc := &mail.Service{Store: mem, Catalog: cat}
	if err := svc.SeedDemo(acc.ID); err != nil {
		t.Fatal(err)
	}

	before, _ := mem.WalletBalances(acc.ID)
	goldBefore := bal(before, "gold")
	diamondsBefore := bal(before, "diamonds")

	st, body, err := svc.ClaimAll(acc.ID, "mall-atomic-1")
	if err != nil || st != 200 {
		t.Fatalf("claim-all %d %v %s", st, err, body)
	}
	var out mail.ClaimAllResponse
	_ = json.Unmarshal(body, &out)
	if out.Count < 1 {
		t.Fatalf("expected claimed mail, got %#v", out)
	}

	after, _ := mem.WalletBalances(acc.ID)
	if bal(after, "diamonds") < diamondsBefore && bal(after, "gold") <= goldBefore {
		// At least one reward resource should increase for demo inbox.
		t.Fatalf("wallet unchanged after claim-all diamonds %d→%d gold %d→%d",
			diamondsBefore, bal(after, "diamonds"), goldBefore, bal(after, "gold"))
	}

	msgs, _ := mem.ListMail(acc.ID)
	for _, m := range msgs {
		if len(m.Attachments) > 0 && m.Status != "claimed" {
			for _, a := range m.Attachments {
				if a.Amount > 0 && !a.Claimed {
					t.Fatalf("mail %s still unclaimed with attachments", m.ID)
				}
			}
		}
	}

	// Replay
	st, body, err = svc.ClaimAll(acc.ID, "mall-atomic-1")
	if err != nil || st != 200 {
		t.Fatalf("replay %d %v", st, err)
	}
	var replay mail.ClaimAllResponse
	_ = json.Unmarshal(body, &replay)
	if !replay.Replayed {
		t.Fatalf("expected replayed, got %#v", replay)
	}
}

func TestClaimAllRollbackOnSaveFailure(t *testing.T) {
	mem := store.NewMemory(nil)
	acc, _, err := mem.CreateGuest([]string{"H01"})
	if err != nil {
		t.Fatal(err)
	}
	_ = mem.SeedMail(acc.ID, []domain.MailMessage{{
		ID: "mail_roll", Status: "unread", Subject: "x",
		Attachments: []domain.MailAttach{{ResourceID: "gold", Amount: 42}},
	}})
	before, _ := mem.WalletBalances(acc.ID)
	goldBefore := bal(before, "gold")

	err = store.Run(mem, acc.ID, func(ops store.Ops) error {
		if _, err := ops.ApplyLedger([]domain.LedgerEntry{{
			ResourceID: "gold", Delta: 42, SourceType: "mail_claim_all", SourceID: "mail_roll",
		}}, "mall-fail", "hf", []byte(`{}`), 200); err != nil {
			return err
		}
		return store.ErrNotFound
	})
	if err != store.ErrNotFound {
		t.Fatalf("want rollback err, got %v", err)
	}
	after, _ := mem.WalletBalances(acc.ID)
	if bal(after, "gold") != goldBefore {
		t.Fatalf("gold should roll back: %d → %d", goldBefore, bal(after, "gold"))
	}
	msg, _ := mem.GetMail(acc.ID, "mail_roll")
	if msg.Status == "claimed" {
		t.Fatal("mail should not stay claimed after rollback")
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
