package campaign

import (
	"github.com/maillunex-lang/number5/server/internal/domain"
	"github.com/maillunex-lang/number5/server/internal/store"
)

type Service struct {
	Store store.Store
}

type ProgressResponse struct {
	CurrentStage    string              `json:"current_stage"`
	UnlockedChapter int                 `json:"unlocked_chapter"`
	Cleared         []domain.StageClear `json:"cleared"`
}

func (s *Service) Progress(accountID domain.AccountID) (ProgressResponse, error) {
	p, err := s.Store.GetCampaign(accountID)
	if err != nil {
		return ProgressResponse{}, err
	}
	cleared := make([]domain.StageClear, 0, len(p.Stages))
	for _, st := range p.Stages {
		cleared = append(cleared, st)
	}
	return ProgressResponse{
		CurrentStage:    p.CurrentStage,
		UnlockedChapter: p.UnlockedChapter,
		Cleared:         cleared,
	}, nil
}
