-- Migration 017b: Create User App Settings Table
-- Date: 2026-04-11
-- Purpose: Create user-specific app settings (needed for Vuralis consent tracking)

CREATE TABLE IF NOT EXISTS user_app_settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL UNIQUE,

  -- Gamification settings
  gamification_enabled BOOLEAN DEFAULT FALSE,

  -- Vuralis integration settings
  vuralis_data_bridge_consent BOOLEAN DEFAULT FALSE,
  vuralis_sync_frequency VARCHAR(20) DEFAULT 'daily', -- daily / weekly / manual

  -- Notification preferences
  push_notifications_enabled BOOLEAN DEFAULT TRUE,
  email_notifications_enabled BOOLEAN DEFAULT TRUE,
  sms_notifications_enabled BOOLEAN DEFAULT FALSE,

  -- Privacy settings
  profile_visibility VARCHAR(20) DEFAULT 'friends', -- public / friends / private
  leaderboard_participation BOOLEAN DEFAULT TRUE,
  allow_friend_requests BOOLEAN DEFAULT TRUE,

  -- Language and locale
  language_code VARCHAR(10) DEFAULT 'en', -- en / sw / rw / etc.
  country_code VARCHAR(3), -- UG / KE / TZ / RW / BI / SS / SO
  timezone VARCHAR(40) DEFAULT 'Africa/Nairobi',

  -- Accessibility
  dark_mode_enabled BOOLEAN DEFAULT FALSE,
  font_size VARCHAR(20) DEFAULT 'medium', -- small / medium / large
  high_contrast_mode BOOLEAN DEFAULT FALSE,

  -- Feature flags
  beta_features_enabled BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Trigger to auto-create settings row when user is created
CREATE TRIGGER IF NOT EXISTS trg_create_user_app_settings
AFTER INSERT ON users
FOR EACH ROW
BEGIN
  INSERT OR IGNORE INTO user_app_settings (user_id, country_code)
  VALUES (NEW.id, NULL);
END;

-- Trigger to update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS trg_update_user_app_settings_timestamp
AFTER UPDATE ON user_app_settings
FOR EACH ROW
BEGIN
  UPDATE user_app_settings SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE INDEX IF NOT EXISTS idx_user_app_settings_user ON user_app_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_app_settings_gamification ON user_app_settings(gamification_enabled);
CREATE INDEX IF NOT EXISTS idx_user_app_settings_vuralis_consent ON user_app_settings(vuralis_data_bridge_consent);
