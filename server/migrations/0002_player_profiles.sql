CREATE TABLE IF NOT EXISTS player_profiles (
  account_id UUID PRIMARY KEY REFERENCES accounts(id),
  nickname TEXT NOT NULL DEFAULT '',
  level INTEGER NOT NULL DEFAULT 1 CHECK (level BETWEEN 1 AND 200),
  xp BIGINT NOT NULL DEFAULT 0 CHECK (xp >= 0),
  last_seen_at TIMESTAMPTZ
);

INSERT INTO player_profiles (account_id, nickname)
SELECT id, (CASE WHEN is_guest THEN 'Гость-' ELSE 'Игрок-' END) || left(id::text, 6)
FROM accounts
ON CONFLICT (account_id) DO NOTHING;

CREATE TABLE IF NOT EXISTS admin_profile_audit (
  id BIGSERIAL PRIMARY KEY,
  account_id UUID NOT NULL REFERENCES accounts(id),
  action TEXT NOT NULL,
  before_json JSONB NOT NULL,
  after_json JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
