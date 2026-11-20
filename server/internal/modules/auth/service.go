package auth

import (
	"time"

	"github.com/maillunex-lang/number5/server/internal/domain"
	"github.com/maillunex-lang/number5/server/internal/store"
)

type Service struct {
	Store         store.Store
	StarterHeroes []string
}

type GuestResponse struct {
	AccountID   string `json:"account_id"`
	AccessToken string `json:"access_token"`
	TokenType   string `json:"token_type"`
	IsGuest     bool   `json:"is_guest"`
	ExpiresAt   string `json:"expires_at"`
}

func (s *Service) CreateGuest() (GuestResponse, error) {
	heroes := s.StarterHeroes
	if len(heroes) == 0 {
		heroes = []string{"H01", "H02", "H03", "H04", "H05"}
	}
	acc, sess, err := s.Store.CreateGuest(heroes)
	if err != nil {
		return GuestResponse{}, err
	}
	return GuestResponse{
		AccountID:   string(acc.ID),
		AccessToken: sess.Token,
		TokenType:   "Bearer",
		IsGuest:     true,
		ExpiresAt:   sess.ExpiresAt.UTC().Format(time.RFC3339),
	}, nil
}

func (s *Service) AccountFromBearer(token string) (domain.Account, error) {
	if token == "" {
		return domain.Account{}, store.ErrUnauthorized
	}
	return s.Store.AccountBySession(token)
}
