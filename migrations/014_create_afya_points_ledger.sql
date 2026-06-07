-- Migration 014: Create Afya Points Ledger
-- Date: 2026-04-11
-- Purpose: Create complete points transaction ledger (if not exists)

-- Check if table exists, create if not
CREATE TABLE IF NOT EXISTS afya_points_ledger (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  points_change INTEGER NOT NULL, -- Positive for earn, negative for spend
  transaction_type VARCHAR(40), -- earned / spent / expired / bonus / correction
  action_type VARCHAR(60), -- meal_logged / achievement_unlock / pharmacy_order / etc.
  reference_id INTEGER, -- Achievement ID, Quest ID, Order ID, etc.
  reference_table VARCHAR(60), -- achievements / game_quests / pharmacy_orders / etc.
  balance_after INTEGER NOT NULL,
  expires_at DATE, -- For earned points: 12 months from created_at
  is_expired BOOLEAN DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Points expiry tracking
CREATE TABLE IF NOT EXISTS points_expiry_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  points_to_expire INTEGER NOT NULL,
  earned_on DATE NOT NULL,
  expires_on DATE NOT NULL, -- earned_on + 12 months
  expired_at TIMESTAMP,
  status VARCHAR(20) DEFAULT 'pending', -- pending / expired / used_before_expiry
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_afya_ledger_user ON afya_points_ledger(user_id);
CREATE INDEX IF NOT EXISTS idx_afya_ledger_created ON afya_points_ledger(created_at);
CREATE INDEX IF NOT EXISTS idx_afya_ledger_expires ON afya_points_ledger(expires_at);
CREATE INDEX IF NOT EXISTS idx_afya_ledger_type ON afya_points_ledger(transaction_type);
CREATE INDEX IF NOT EXISTS idx_points_expiry_user ON points_expiry_log(user_id);
CREATE INDEX IF NOT EXISTS idx_points_expiry_expires ON points_expiry_log(expires_on);
