package heroes

import (
	"fmt"

	"github.com/maillunex-lang/number5/server/internal/domain"
	"github.com/maillunex-lang/number5/server/internal/store"
)

type Service struct {
	Store store.Store
}

type CollectionResponse struct {
	Heroes []domain.HeroOwned `json:"heroes"`
	Count  int                `json:"count"`
}

func (s *Service) Collection(accountID domain.AccountID) (CollectionResponse, error) {
	hs, err := s.Store.ListHeroes(accountID)
	if err != nil {
		return CollectionResponse{}, err
	}
	return CollectionResponse{Heroes: hs, Count: len(hs)}, nil
}

func (s *Service) GetFormation(accountID domain.AccountID, mode string) (domain.Formation, error) {
	if mode == "" {
		mode = "campaign"
	}
	return s.Store.GetFormation(accountID, mode)
}

func (s *Service) SetFormation(accountID domain.AccountID, form domain.Formation) error {
	if form.Mode == "" {
		form.Mode = "campaign"
	}
	if len(form.Slots) != 5 {
		return fmt.Errorf("formation must have 5 slots")
	}
	seen := map[string]bool{}
	owned, err := s.Store.ListHeroes(accountID)
	if err != nil {
		return err
	}
	own := map[string]bool{}
	for _, h := range owned {
		own[h.HeroID] = true
	}
	filled := 0
	for _, id := range form.Slots {
		if id == "" {
			continue
		}
		if seen[id] {
			return fmt.Errorf("duplicate hero %s", id)
		}
		if !own[id] {
			return fmt.Errorf("hero not owned %s", id)
		}
		seen[id] = true
		filled++
	}
	if filled == 0 {
		return fmt.Errorf("at least one hero required")
	}
	return s.Store.SetFormation(accountID, form)
}
