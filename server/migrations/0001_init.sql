-- CORE-01 initial schema stub (TZ-A §6). Apply with migrate tool when DATABASE_URL is available.
-- This file is documentation + future migrate source; not auto-applied by the skeleton binary.

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
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (account_id, key)
);

CREATE TABLE IF NOT EXISTS content_bindings (
  account_id UUID PRIMARY KEY REFERENCES accounts(id),
  package_version TEXT NOT NULL,
  schema INT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS campaign_progress (
  account_id UUID PRIMARY KEY REFERENCES accounts(id),
  current_stage TEXT NOT NULL DEFAULT 'CH01-01',
  unlocked_chapter INT NOT NULL DEFAULT 1,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
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
  config_version TEXT NOT NULL
);
