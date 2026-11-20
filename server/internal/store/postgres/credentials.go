package postgres

import (
	"context"
	"errors"
	"github.com/maillunex-lang/number5/server/internal/domain"
	"github.com/maillunex-lang/number5/server/internal/store"
	"golang.org/x/crypto/bcrypt"
	"strings"
	"time"
)

func (s *Store) RegisterAccount(email, password string) (domain.Account, domain.Session, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	if email == "" || len(password) < 10 {
		return domain.Account{}, domain.Session{}, store.ErrUnauthorized
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return domain.Account{}, domain.Session{}, err
	}
	acc, sess, err := s.CreateGuest([]string{"H01", "H02", "H03", "H04", "H05"})
	if err != nil {
		return acc, sess, err
	}
	ctx := context.Background()
	_, err = s.pool.Exec(ctx, `UPDATE accounts SET email=$1,password_hash=$2,is_guest=false WHERE id=$3::uuid`, email, string(hash), string(acc.ID))
	if err != nil {
		// Remove the orphaned guest account's login, but do not erase progression tables here.
		_, _ = s.pool.Exec(ctx, `UPDATE sessions SET revoked_at=now() WHERE account_id=$1::uuid`, string(acc.ID))
		return domain.Account{}, domain.Session{}, err
	}
	_, err = s.pool.Exec(ctx, `INSERT INTO player_profiles(account_id,nickname) VALUES ($1::uuid,$2) ON CONFLICT(account_id) DO NOTHING`, string(acc.ID), "Игрок-"+string(acc.ID)[:6])
	if err != nil {
		return domain.Account{}, domain.Session{}, err
	}
	acc.IsGuest = false
	return acc, sess, nil
}

func (s *Store) LoginAccount(email, password string) (domain.Account, domain.Session, error) {
	var id, hash, status string
	var created time.Time
	ctx := context.Background()
	err := s.pool.QueryRow(ctx, `SELECT id::text,password_hash,status,created_at FROM accounts WHERE lower(email)=lower($1) AND is_guest=false`, strings.TrimSpace(email)).Scan(&id, &hash, &status, &created)
	if err != nil || status != "active" || bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) != nil {
		return domain.Account{}, domain.Session{}, store.ErrUnauthorized
	}
	token := store.NewID("tok")
	exp := time.Now().UTC().Add(30 * 24 * time.Hour)
	_, err = s.pool.Exec(ctx, `INSERT INTO sessions(account_id,refresh_hash,expires_at) VALUES($1::uuid,$2,$3)`, id, token, exp)
	if err != nil {
		return domain.Account{}, domain.Session{}, err
	}
	return domain.Account{ID: domain.AccountID(id), Status: status, CreatedAt: created, IsGuest: false}, domain.Session{Token: token, AccountID: domain.AccountID(id), ExpiresAt: exp}, nil
}

func (s *Store) LinkGuest(accountID domain.AccountID, email, password string) error {
	email = strings.ToLower(strings.TrimSpace(email))
	if email == "" || len(password) < 10 {
		return store.ErrUnauthorized
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	tag, err := s.pool.Exec(context.Background(), `UPDATE accounts SET email=$1,password_hash=$2,is_guest=false WHERE id=$3::uuid AND is_guest=true AND status='active'`, email, string(hash), string(accountID))
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("not_guest")
	}
	return nil
}
