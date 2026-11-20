-- CORE-01 schema (TZ-A §6). Apply when DATABASE_URL / Postgres available.
-- Memory store implements the same domain; this file is the PG target.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  password_hash TEXT,
  is_guest BOOLEAN NOT NULL DEFAULT TRUE,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id),
  refresh_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS sessions_account_idx ON sessions(account_id);

CREATE TABLE IF NOT EXISTS wallet_balances (
  account_id UUID NOT NULL REFERENCES accounts(id),
  resource_id TEXT NOT NULL,
  amount BIGINT NOT NULL DEFAULT 0,
  version INT NOT NULL DEFAULT 0,
  PRIMARY KEY (account_id, resource_id)
);

CREATE TABLE IF NOT EXISTS wallet_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id),
  resource_id TEXT NOT NULL,
  delta BIGINT NOT NULL,
  source_type TEXT NOT NULL,
  source_id TEXT NOT NULL,
  period_key TEXT NOT NULL DEFAULT '',
  config_version TEXT NOT NULL DEFAULT '',
  idempotency_key TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (account_id, idempotency_key, resource_id, source_type)
);

CREATE TABLE IF NOT EXISTS idempotency_keys (
  account_id UUID NOT NULL REFERENCES accounts(id),
  key TEXT NOT NULL,
  request_hash TEXT NOT NULL,
  response_json JSONB NOT NULL,
  status_code INT NOT NULL DEFAULT 200,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (account_id, key)
);

CREATE TABLE IF NOT EXISTS content_bindings (
  account_id UUID PRIMARY KEY REFERENCES accounts(id),
  package_version TEXT NOT NULL,
  schema INT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS heroes_owned (
  account_id UUID NOT NULL REFERENCES accounts(id),
  hero_id TEXT NOT NULL,
  stars INT NOT NULL DEFAULT 1,
  level INT NOT NULL DEFAULT 1,
  shards INT NOT NULL DEFAULT 0,
  PRIMARY KEY (account_id, hero_id)
);

CREATE TABLE IF NOT EXISTS formations (
  account_id UUID NOT NULL REFERENCES accounts(id),
  mode TEXT NOT NULL,
  slot INT NOT NULL CHECK (slot BETWEEN 0 AND 4),
  hero_id TEXT,
  UNIQUE (account_id, mode, slot)
);

CREATE TABLE IF NOT EXISTS campaign_progress (
  account_id UUID PRIMARY KEY REFERENCES accounts(id),
  current_stage TEXT NOT NULL DEFAULT 'CH01-01',
  unlocked_chapter INT NOT NULL DEFAULT 1,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS campaign_stages (
  account_id UUID NOT NULL REFERENCES accounts(id),
  stage_id TEXT NOT NULL,
  stars INT NOT NULL DEFAULT 0,
  clears INT NOT NULL DEFAULT 0,
  first_clear_claimed_at TIMESTAMPTZ,
  PRIMARY KEY (account_id, stage_id)
);

CREATE TABLE IF NOT EXISTS battle_instances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id),
  mode TEXT NOT NULL,
  stage_id TEXT NOT NULL,
  squad_json JSONB NOT NULL,
  seed BIGINT NOT NULL,
  status TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ,
  result_json JSONB,
  config_version TEXT NOT NULL,
  claimed BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS battle_account_idx ON battle_instances(account_id);

CREATE TABLE IF NOT EXISTS battle_claims (
  battle_id UUID PRIMARY KEY REFERENCES battle_instances(id),
  account_id UUID NOT NULL REFERENCES accounts(id),
  grant_ids_json JSONB NOT NULL DEFAULT '[]',
  claimed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  idempotency_key TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS summon_pity (
  account_id UUID NOT NULL REFERENCES accounts(id),
  banner_id TEXT NOT NULL,
  ssr_count INT NOT NULL DEFAULT 0,
  ur_count INT NOT NULL DEFAULT 0,
  PRIMARY KEY (account_id, banner_id)
);

CREATE TABLE IF NOT EXISTS afk_state (
  account_id UUID PRIMARY KEY REFERENCES accounts(id),
  last_claim_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  chapter INT NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS mail_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id),
  template_id TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT 'system',
  subject TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'unread',
  attachments_json JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS mail_account_idx ON mail_messages(account_id);

CREATE TABLE IF NOT EXISTS store_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id),
  sku TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  grants_json JSONB NOT NULL DEFAULT '[]',
  vip_xp INT NOT NULL DEFAULT 0,
  idempotency_key TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  confirmed_at TIMESTAMPTZ,
  UNIQUE (account_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS outbox_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID REFERENCES accounts(id),
  event_type TEXT NOT NULL,
  payload_json JSONB NOT NULL,
  schema_version INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  published_at TIMESTAMPTZ
);
