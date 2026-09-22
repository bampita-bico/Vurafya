-- Revocable JWTs: a version increment invalidates all existing tokens for a user.
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS auth_token_version INTEGER NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_users_auth_token_version
    ON users(id, auth_token_version);
