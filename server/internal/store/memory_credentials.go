package store

import (
	"errors"
	"strings"
	"time"

	"github.com/maillunex-lang/number5/server/internal/domain"
	"golang.org/x/crypto/bcrypt"
)

// RegisterAccount creates a non-guest account with email/password (dev/test Memory parity with Postgres).
func (m *Memory) RegisterAccount(email, password string) (domain.Account, domain.Session, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	if email == "" || len(password) < 10 {
		return domain.Account{}, domain.Session{}, ErrUnauthorized
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return domain.Account{}, domain.Session{}, err
	}
	m.mu.Lock()
	if m.emailTakenLocked(email, "") {
		m.mu.Unlock()
		return domain.Account{}, domain.Session{}, ErrConflict
	}
	m.mu.Unlock()

	acc, sess, err := m.CreateGuest([]string{"H01", "H02", "H03", "H04", "H05"})
	if err != nil {
		return domain.Account{}, domain.Session{}, err
	}

	m.mu.Lock()
	defer m.mu.Unlock()
	if m.emailTakenLocked(email, acc.ID) {
		delete(m.sessions, sess.Token)
		dead := m.accounts[acc.ID]
		dead.Status = "revoked"
		m.accounts[acc.ID] = dead
		return domain.Account{}, domain.Session{}, ErrConflict
	}
	acc.Email = email
	acc.IsGuest = false
	m.accounts[acc.ID] = acc
	m.passwords[acc.ID] = string(hash)
	return acc, sess, nil
}

func (m *Memory) LoginAccount(email, password string) (domain.Account, domain.Session, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	m.mu.Lock()
	defer m.mu.Unlock()
	var acc domain.Account
	var found bool
	for _, a := range m.accounts {
		if !a.IsGuest && a.Status == "active" && strings.EqualFold(a.Email, email) {
			acc = a
			found = true
			break
		}
	}
	if !found {
		return domain.Account{}, domain.Session{}, ErrUnauthorized
	}
	hash := m.passwords[acc.ID]
	if hash == "" || bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) != nil {
		return domain.Account{}, domain.Session{}, ErrUnauthorized
	}
	now := m.clock.Now()
	tok := newID("tok")
	sess := domain.Session{Token: tok, AccountID: acc.ID, ExpiresAt: now.Add(30 * 24 * time.Hour)}
	m.sessions[tok] = sess
	return acc, sess, nil
}

func (m *Memory) LinkGuest(accountID domain.AccountID, email, password string) error {
	email = strings.ToLower(strings.TrimSpace(email))
	if email == "" || len(password) < 10 {
		return ErrUnauthorized
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	acc, ok := m.accounts[accountID]
	if !ok || !acc.IsGuest || acc.Status != "active" {
		return errors.New("not_guest")
	}
	if m.emailTakenLocked(email, accountID) {
		return ErrConflict
	}
	acc.Email = email
	acc.IsGuest = false
	m.accounts[accountID] = acc
	m.passwords[accountID] = string(hash)
	return nil
}

func (m *Memory) RevokeSession(token string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	delete(m.sessions, token)
	return nil
}

func (m *Memory) emailTakenLocked(email string, except domain.AccountID) bool {
	for id, a := range m.accounts {
		if except != "" && id == except {
			continue
		}
		if a.Email != "" && strings.EqualFold(a.Email, email) && a.Status == "active" {
			return true
		}
	}
	return false
}
