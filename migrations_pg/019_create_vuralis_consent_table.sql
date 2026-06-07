-- Migration 019: Create Vuralis Consent Tracking
-- Date: 2026-04-11
-- Purpose: Track user consent for Vurafya → Vuralis data bridge

-- Consent tracking table
CREATE TABLE IF NOT EXISTS vuralis_consent_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  consent_given BOOLEAN NOT NULL,
  consent_version VARCHAR(20) DEFAULT '1.0', -- Track consent policy version
  ip_address VARCHAR(45), -- IPv4 or IPv6
  user_agent TEXT, -- Browser/device info
  consented_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  revoked_at TIMESTAMP,
  notes TEXT, -- Optional: reason for revoking
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Note: vuralis_data_bridge_consent column already exists in user_app_settings
-- (created by migration 017b_create_user_app_settings.sql)
-- No need to add it again

-- Create table for Vuralis sync status (to track last successful sync)
CREATE TABLE IF NOT EXISTS vuralis_sync_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  sync_type VARCHAR(40), -- avatar_stats / health_scores / streaks / progression
  sync_status VARCHAR(20), -- success / failed / pending
  records_synced INTEGER DEFAULT 0,
  error_message TEXT,
  synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_vuralis_consent_user ON vuralis_consent_log(user_id);
CREATE INDEX IF NOT EXISTS idx_vuralis_consent_given ON vuralis_consent_log(consent_given);
CREATE INDEX IF NOT EXISTS idx_vuralis_consent_date ON vuralis_consent_log(consented_at);
CREATE INDEX IF NOT EXISTS idx_vuralis_sync_user ON vuralis_sync_log(user_id);
CREATE INDEX IF NOT EXISTS idx_vuralis_sync_type ON vuralis_sync_log(sync_type);
CREATE INDEX IF NOT EXISTS idx_vuralis_sync_status ON vuralis_sync_log(sync_status);

-- Trigger: Log consent changes in vuralis_consent_log when user_app_settings.vuralis_data_bridge_consent changes
CREATE TRIGGER IF NOT EXISTS trg_vuralis_consent_change
AFTER UPDATE OF vuralis_data_bridge_consent ON user_app_settings
FOR EACH ROW
WHEN NEW.vuralis_data_bridge_consent != OLD.vuralis_data_bridge_consent
BEGIN
  INSERT INTO vuralis_consent_log (user_id, consent_given, consented_at, revoked_at)
  VALUES (
    NEW.user_id,
    NEW.vuralis_data_bridge_consent,
    CASE WHEN NEW.vuralis_data_bridge_consent = TRUE THEN CURRENT_TIMESTAMP ELSE NULL END,
    CASE WHEN NEW.vuralis_data_bridge_consent = FALSE THEN CURRENT_TIMESTAMP ELSE NULL END
  );
END;

-- Sample consent policy text (to be displayed in UI)
CREATE TABLE IF NOT EXISTS vuralis_consent_policy (
  id SERIAL PRIMARY KEY,
  version VARCHAR(20) NOT NULL UNIQUE,
  policy_text TEXT NOT NULL,
  effective_date DATE NOT NULL,
  is_current BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO vuralis_consent_policy (version, policy_text, effective_date) VALUES
('1.0', 'By enabling the Vuralis data bridge, you consent to sharing the following read-only data with Vuralis:
- Avatar stats (7 health-mapped attributes: health level, energy level, brain power, muscle strength, immunity level, resilience level, gut health)
- Health scores summary (kidney, diabetes, BP, metabolic, longevity scores from last 30 days)
- User streaks (current streak, longest streak, aura tier)
- Avatar progression (level, XP, character class, skills unlocked, achievements, cosmetics, Afya Points balance)

This data will be used to personalize your Vuralis game experience:
- Avatar appearance and behavior
- City environment responses (NPCs, warnings based on health risks)
- Visual aura effects based on streaks
- In-game capabilities based on avatar level and class

You can revoke this consent at any time in Settings. Revoking consent will stop all future data sharing but will not delete data already synced to Vuralis.

Data is synced every 24 hours via secure API. No personal identifiable information (PII) such as real name, phone number, or medical history details are shared.', '2026-04-11');
