package shop

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"time"

	"github.com/maillunex-lang/number5/server/internal/domain"
	"github.com/maillunex-lang/number5/server/internal/modules/content"
	"github.com/maillunex-lang/number5/server/internal/store"
)

// Service implements VIRTUAL_FREE store (TZ-A module 10).
type Service struct {
	Store   store.Store
	Catalog *content.Catalog
	Clock   store.Clock
}

func (s *Service) now() time.Time {
	if s.Clock != nil {
		return s.Clock.Now()
	}
	return time.Now().UTC()
}

type CatalogResponse struct {
	Mode    string               `json:"mode"`
	Offers  []content.StoreOffer `json:"offers"`
	Version string               `json:"config_version"`
}

func (s *Service) CatalogView() CatalogResponse {
	offers := make([]content.StoreOffer, 0, len(s.Catalog.Economy.Offers))
	for _, o := range s.Catalog.Economy.Offers {
		if o.Enabled {
			offers = append(offers, o)
		}
	}
	mode := s.Catalog.Economy.Mode
	if mode == "" {
		mode = "VIRTUAL_FREE"
	}
	return CatalogResponse{Mode: mode, Offers: offers, Version: s.Catalog.Version}
}

type CreateOrderRequest struct {
	SKU            string `json:"sku"`
	IdempotencyKey string `json:"idempotency_key"`
}

type OrderResponse struct {
	Order    domain.StoreOrder `json:"order"`
	Replayed bool              `json:"replayed,omitempty"`
}

func (s *Service) CreateOrder(accountID domain.AccountID, req CreateOrderRequest) (status int, body []byte, err error) {
	if req.SKU == "" || req.IdempotencyKey == "" {
		return 422, errJSON("invalid", "sku and idempotency_key required"), nil
	}
	offer, ok := s.Catalog.Offer(req.SKU)
	if !ok || !offer.Enabled {
		return 404, errJSON("not_found", "sku"), nil
	}
	hash := hashKey("order|" + req.SKU + "|" + req.IdempotencyKey)
	if rec, e := s.Store.GetIdempotency(accountID, req.IdempotencyKey); e == nil {
		if rec.RequestHash != hash {
			return 409, errJSON("conflict", "idempotency key reused"), nil
		}
		var cached OrderResponse
		_ = json.Unmarshal(rec.ResponseJSON, &cached)
		cached.Replayed = true
		return rec.StatusCode, mustJSON(cached), nil
	}
	grants := make([]domain.MailAttach, 0, len(offer.Grants))
	for _, g := range offer.Grants {
		grants = append(grants, domain.MailAttach{ResourceID: g.ResourceID, Amount: g.Amount})
	}
	order := domain.StoreOrder{
		ID:             store.NewID("ord"),
		AccountID:      accountID,
		SKU:            req.SKU,
		Status:         "pending",
		Grants:         grants,
		VipXP:          offer.VipXP,
		IdempotencyKey: req.IdempotencyKey,
		CreatedAt:      s.now(),
	}
	out := OrderResponse{Order: order}
	body = mustJSON(out)
	_, err = s.Store.ApplyLedger(accountID, nil, req.IdempotencyKey, hash, body, 200)
	if err != nil {
		if err == store.ErrConflict {
			return 409, errJSON("conflict", err.Error()), nil
		}
		return 500, errJSON("internal", err.Error()), nil
	}
	if err := s.Store.SaveStoreOrder(order); err != nil {
		return 500, errJSON("internal", err.Error()), nil
	}
	if patcher, ok := s.Store.(interface {
		PatchIdempotencyResponse(domain.AccountID, string, []byte, int) error
	}); ok {
		_ = patcher.PatchIdempotencyResponse(accountID, req.IdempotencyKey, body, 200)
	}
	return 200, body, nil
}

func (s *Service) GetOrder(accountID domain.AccountID, orderID string) (domain.StoreOrder, error) {
	o, err := s.Store.GetStoreOrder(orderID)
	if err != nil {
		return domain.StoreOrder{}, err
	}
	if o.AccountID != accountID {
		return domain.StoreOrder{}, store.ErrForbidden
	}
	return o, nil
}

func (s *Service) ConfirmTest(accountID domain.AccountID, orderID, idempotencyKey string) (status int, body []byte, err error) {
	if orderID == "" || idempotencyKey == "" {
		return 422, errJSON("invalid", "order id and idempotency_key required"), nil
	}
	hash := hashKey("confirm|" + orderID + "|" + idempotencyKey)
	var outStatus int
	err = store.Run(s.Store, accountID, func(ops store.Ops) error {
		if rec, e := ops.GetIdempotency(idempotencyKey); e == nil {
			if rec.RequestHash != hash {
				outStatus = 409
				body = errJSON("conflict", "idempotency key reused")
				return nil
			}
			var cached OrderResponse
			_ = json.Unmarshal(rec.ResponseJSON, &cached)
			cached.Replayed = true
			outStatus = rec.StatusCode
			body = mustJSON(cached)
			return nil
		}
		order, e := ops.GetStoreOrder(orderID)
		if e != nil {
			outStatus = 404
			body = errJSON("not_found", "order")
			return nil
		}
		if order.AccountID != accountID {
			outStatus = 403
			body = errJSON("forbidden", "order")
			return nil
		}
		if order.Status == "confirmed" {
			outStatus = 200
			body = mustJSON(OrderResponse{Order: order})
			return nil
		}
		entries := make([]domain.LedgerEntry, 0, len(order.Grants)+1)
		for _, g := range order.Grants {
			if g.Amount <= 0 {
				continue
			}
			entries = append(entries, domain.LedgerEntry{
				ResourceID: g.ResourceID, Delta: g.Amount,
				SourceType: "store_confirm", SourceID: order.ID,
				ConfigVersion: s.Catalog.Version,
			})
		}
		if order.VipXP > 0 {
			entries = append(entries, domain.LedgerEntry{
				ResourceID: "vip_xp", Delta: int64(order.VipXP),
				SourceType: "store_confirm", SourceID: order.ID,
				ConfigVersion: s.Catalog.Version,
			})
		}
		if _, e := ops.ApplyLedger(entries, idempotencyKey, hash, []byte(`{}`), 200); e != nil {
			return e
		}
		now := s.now()
		order.Status = "confirmed"
		order.ConfirmedAt = &now
		if e := ops.SaveStoreOrder(order); e != nil {
			return e
		}
		body = mustJSON(OrderResponse{Order: order})
		outStatus = 200
		return ops.PatchIdempotencyResponse(idempotencyKey, body, 200)
	})
	if err != nil {
		if err == store.ErrConflict {
			return 409, errJSON("conflict", err.Error()), nil
		}
		return 500, errJSON("internal", err.Error()), nil
	}
	if outStatus == 0 {
		outStatus = 200
	}
	return outStatus, body, nil
}

func hashKey(key string) string {
	sum := sha256.Sum256([]byte(key))
	return hex.EncodeToString(sum[:])
}

func mustJSON(v any) []byte {
	b, _ := json.Marshal(v)
	return b
}

func errJSON(code, message string) []byte {
	return mustJSON(map[string]any{"error": map[string]string{"code": code, "message": message}})
}
