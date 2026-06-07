-- Migration 038: Create Fraud Detection System
-- Date: 2026-04-11
-- Purpose: Detect and prevent fraud (fake goods, no-show workers, double-trading, account takeover)

-- Fraud Detection Alerts (Suspicious activity flagging)
CREATE TABLE IF NOT EXISTS fraud_detection_alerts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  -- Alert Type
  alert_type VARCHAR(60) NOT NULL, -- suspicious_transaction / fake_goods / no_show_pattern / account_takeover / rapid_transactions / structuring / impossible_travel / duplicate_identity

  -- User/Transaction Reference
  user_id INTEGER,
  transaction_id INTEGER,
  transaction_type VARCHAR(40),

  -- Risk Score
  risk_score REAL NOT NULL, -- 0.0 to 1.0 (0 = no risk, 1 = certain fraud)
  risk_level VARCHAR(40), -- low / medium / high / critical

  -- Fraud Indicators
  fraud_indicators TEXT, -- JSON array: ["round_number_amount", "new_user_large_transaction", "mismatched_geolocation"]
  fraud_indicator_count INTEGER DEFAULT 0,

  -- Details
  alert_description TEXT NOT NULL,
  alert_details TEXT, -- JSON with detailed context

  -- Automated Actions Taken
  auto_action_taken VARCHAR(60), -- transaction_blocked / user_suspended / otp_required / manual_review_queued / none
  auto_action_at TIMESTAMP,

  -- Manual Review
  requires_manual_review BOOLEAN DEFAULT FALSE,
  reviewed_by INTEGER, -- Staff ID
  review_status VARCHAR(40), -- pending / investigating / false_positive / confirmed_fraud / resolved
  review_notes TEXT,
  reviewed_at TIMESTAMP,

  -- Resolution
  is_resolved BOOLEAN DEFAULT FALSE,
  resolution_action VARCHAR(60), -- account_banned / transaction_reversed / warning_issued / no_action / false_positive
  resolved_by INTEGER,
  resolved_at TIMESTAMP,

  -- Timestamps
  detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (reviewed_by) REFERENCES medical_staff(id) ON DELETE SET NULL,
  FOREIGN KEY (resolved_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- Fraud Detection Rules (Configurable detection patterns)
CREATE TABLE IF NOT EXISTS fraud_detection_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  rule_name VARCHAR(200) NOT NULL UNIQUE,
  rule_code VARCHAR(60) NOT NULL UNIQUE,

  -- Rule Type
  rule_category VARCHAR(60) NOT NULL, -- transaction_pattern / behavioral / identity / geolocation / velocity

  -- Rule Logic (SQL-based condition)
  rule_condition TEXT NOT NULL, -- E.g., "transaction_amount > 5000000 AND user_account_age_days < 7"

  -- Thresholds
  risk_score_weight REAL DEFAULT 0.1, -- How much this rule contributes to overall risk score (0.0-1.0)
  alert_threshold REAL DEFAULT 0.7, -- Trigger alert if risk_score >= this threshold

  -- Actions
  auto_action VARCHAR(60), -- none / require_otp / block_transaction / suspend_user / manual_review

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  is_ml_based BOOLEAN DEFAULT FALSE, -- TRUE if rule uses machine learning model

  description TEXT,
  created_by INTEGER, -- Staff ID
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (created_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- Seed fraud detection rules
INSERT OR IGNORE INTO fraud_detection_rules (rule_code, rule_name, rule_category, rule_condition, risk_score_weight, alert_threshold, auto_action, description) VALUES
('new_user_large_tx', 'New User Large Transaction', 'behavioral', 'transaction_amount > 1000000 AND account_age_days < 7', 0.4, 0.7, 'require_otp', 'New users (< 7 days) attempting transactions > 1M UGX'),
('rapid_succession', 'Rapid Succession Transactions', 'velocity', '5+ transactions within 5 minutes', 0.3, 0.6, 'require_otp', 'Multiple transactions in rapid succession'),
('round_numbers', 'Round Number Structuring', 'transaction_pattern', 'transaction_amount IN (1000000, 5000000, 10000000)', 0.2, 0.5, 'manual_review', 'Suspiciously round transaction amounts'),
('impossible_travel', 'Impossible Travel Pattern', 'geolocation', 'geolocation_distance > 500km AND time_since_last_login < 1 hour', 0.5, 0.8, 'block_transaction', 'User logged in from different location too quickly'),
('no_show_repeat', 'Repeat No-Show Pattern', 'behavioral', 'no_show_count >= 3 within 30 days', 0.6, 0.9, 'suspend_user', 'Multiple no-shows indicate unreliability or fraud'),
('duplicate_national_id', 'Duplicate National ID', 'identity', 'national_id_number matches existing user', 0.8, 0.9, 'block_transaction', 'National ID already registered to another account'),
('vpn_detected', 'VPN/Proxy Usage', 'geolocation', 'IP address is VPN/proxy', 0.3, 0.6, 'require_otp', 'User accessing from VPN or proxy'),
('account_takeover', 'Account Takeover Pattern', 'behavioral', 'password_changed AND phone_changed AND large_transaction within 24 hours', 0.9, 0.95, 'block_transaction', 'Suspicious account changes followed by large transaction');

-- User Fraud History (Track fraud incidents per user)
CREATE TABLE IF NOT EXISTS user_fraud_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,

  -- Fraud Stats
  total_fraud_alerts INTEGER DEFAULT 0,
  confirmed_fraud_incidents INTEGER DEFAULT 0,
  false_positive_alerts INTEGER DEFAULT 0,

  -- Risk Profile
  overall_fraud_risk_score REAL DEFAULT 0.0, -- 0.0 to 1.0
  fraud_risk_level VARCHAR(40) DEFAULT 'low', -- low / medium / high / critical

  -- Behavioral Flags
  has_fake_goods_history BOOLEAN DEFAULT FALSE,
  has_no_show_history BOOLEAN DEFAULT FALSE,
  has_payment_dispute_history BOOLEAN DEFAULT FALSE,
  has_identity_theft_attempt BOOLEAN DEFAULT FALSE,

  -- Restrictions
  is_permanently_banned BOOLEAN DEFAULT FALSE,
  is_temporarily_suspended BOOLEAN DEFAULT FALSE,
  suspension_expires_at TIMESTAMP,
  requires_enhanced_verification BOOLEAN DEFAULT FALSE,

  -- Last Incident
  last_fraud_alert_at TIMESTAMP,
  last_confirmed_fraud_at TIMESTAMP,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (user_id)
);

-- Blacklisted Entities (Banned users, phone numbers, IDs, IPs)
CREATE TABLE IF NOT EXISTS blacklisted_entities (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_type VARCHAR(60) NOT NULL, -- user / phone_number / national_id / ip_address / device_id / email

  entity_value VARCHAR(500) NOT NULL, -- The actual value (phone number, IP, etc.)
  entity_hash VARCHAR(100), -- Hashed value for privacy

  -- Blacklist Reason
  blacklist_reason VARCHAR(60), -- confirmed_fraud / multiple_no_shows / fake_goods / account_takeover / abuse
  blacklist_notes TEXT,

  -- Severity
  blacklist_level VARCHAR(40) DEFAULT 'permanent', -- temporary / permanent
  blacklist_expires_at TIMESTAMP, -- NULL for permanent

  -- Actions
  block_new_accounts BOOLEAN DEFAULT TRUE,
  block_transactions BOOLEAN DEFAULT TRUE,
  require_manual_review BOOLEAN DEFAULT TRUE,

  -- Attribution
  blacklisted_by INTEGER, -- Staff ID
  blacklisted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  is_active BOOLEAN DEFAULT TRUE,

  FOREIGN KEY (blacklisted_by) REFERENCES medical_staff(id) ON DELETE SET NULL,
  UNIQUE (entity_type, entity_value)
);

-- Device Fingerprinting (Track devices for fraud detection)
CREATE TABLE IF NOT EXISTS device_fingerprints (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,

  -- Device Info
  device_id VARCHAR(200), -- Unique device identifier
  device_type VARCHAR(60), -- mobile / tablet / desktop / feature_phone
  os_name VARCHAR(60),
  os_version VARCHAR(60),
  browser_name VARCHAR(60),
  browser_version VARCHAR(60),

  -- Network
  ip_address VARCHAR(60),
  ip_country VARCHAR(5),
  is_vpn BOOLEAN DEFAULT FALSE,
  is_proxy BOOLEAN DEFAULT FALSE,
  is_tor BOOLEAN DEFAULT FALSE,

  -- Location
  last_location_lat REAL,
  last_location_lng REAL,
  last_location_country VARCHAR(5),
  last_location_city VARCHAR(100),

  -- Usage
  first_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  login_count INTEGER DEFAULT 1,

  -- Fraud Flags
  is_suspicious BOOLEAN DEFAULT FALSE,
  suspicious_reason TEXT,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_fraud_alert_user ON fraud_detection_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_fraud_alert_type ON fraud_detection_alerts(alert_type);
CREATE INDEX IF NOT EXISTS idx_fraud_alert_risk ON fraud_detection_alerts(risk_level);
CREATE INDEX IF NOT EXISTS idx_fraud_alert_status ON fraud_detection_alerts(review_status);
CREATE INDEX IF NOT EXISTS idx_fraud_alert_created ON fraud_detection_alerts(created_at);

CREATE INDEX IF NOT EXISTS idx_fraud_rule_code ON fraud_detection_rules(rule_code);
CREATE INDEX IF NOT EXISTS idx_fraud_rule_category ON fraud_detection_rules(rule_category);
CREATE INDEX IF NOT EXISTS idx_fraud_rule_active ON fraud_detection_rules(is_active);

CREATE INDEX IF NOT EXISTS idx_user_fraud_user ON user_fraud_history(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fraud_risk ON user_fraud_history(fraud_risk_level);

CREATE INDEX IF NOT EXISTS idx_blacklist_entity ON blacklisted_entities(entity_type, entity_value);
CREATE INDEX IF NOT EXISTS idx_blacklist_active ON blacklisted_entities(is_active);

CREATE INDEX IF NOT EXISTS idx_device_user ON device_fingerprints(user_id);
CREATE INDEX IF NOT EXISTS idx_device_id ON device_fingerprints(device_id);
CREATE INDEX IF NOT EXISTS idx_device_ip ON device_fingerprints(ip_address);

-- View: High-Risk Users
CREATE VIEW IF NOT EXISTS v_high_risk_users AS
SELECT
  u.id AS user_id,
  u.username,
  ufh.overall_fraud_risk_score,
  ufh.fraud_risk_level,
  ufh.confirmed_fraud_incidents,
  ufh.is_temporarily_suspended,
  ufh.is_permanently_banned,
  COUNT(fda.id) AS pending_alerts
FROM users u
LEFT JOIN user_fraud_history ufh ON u.id = ufh.user_id
LEFT JOIN fraud_detection_alerts fda ON u.id = fda.user_id AND fda.is_resolved = FALSE
WHERE ufh.fraud_risk_level IN ('high', 'critical')
   OR ufh.is_temporarily_suspended = TRUE
   OR ufh.is_permanently_banned = TRUE
GROUP BY u.id, u.username, ufh.overall_fraud_risk_score, ufh.fraud_risk_level, ufh.confirmed_fraud_incidents, ufh.is_temporarily_suspended, ufh.is_permanently_banned;

-- Trigger: Create fraud history for new users
CREATE TRIGGER IF NOT EXISTS trg_create_fraud_history
AFTER INSERT ON users
FOR EACH ROW
BEGIN
  INSERT OR IGNORE INTO user_fraud_history (user_id)
  VALUES (NEW.id);
END;

-- Trigger: Update fraud history when alert confirmed
CREATE TRIGGER IF NOT EXISTS trg_update_fraud_history_on_confirmation
AFTER UPDATE OF resolution_action ON fraud_detection_alerts
FOR EACH ROW
WHEN NEW.resolution_action = 'confirmed_fraud' OR NEW.resolution_action = 'account_banned'
BEGIN
  UPDATE user_fraud_history
  SET
    confirmed_fraud_incidents = confirmed_fraud_incidents + 1,
    last_confirmed_fraud_at = CURRENT_TIMESTAMP,
    overall_fraud_risk_score = MIN(1.0, overall_fraud_risk_score + 0.2), -- Increase risk score
    fraud_risk_level = CASE
      WHEN overall_fraud_risk_score >= 0.8 THEN 'critical'
      WHEN overall_fraud_risk_score >= 0.6 THEN 'high'
      WHEN overall_fraud_risk_score >= 0.4 THEN 'medium'
      ELSE 'low'
    END,
    updated_at = CURRENT_TIMESTAMP
  WHERE user_id = NEW.user_id;

  -- Ban user if 3+ confirmed fraud incidents
  UPDATE user_fraud_history
  SET is_permanently_banned = TRUE
  WHERE user_id = NEW.user_id
    AND confirmed_fraud_incidents >= 3;
END;

-- Function: Fraud Detection Flow (documented for backend)
/*
FRAUD DETECTION WORKFLOW:

1. REAL-TIME TRANSACTION MONITORING
   - Every transaction evaluated against fraud_detection_rules
   - Calculate risk_score: SUM(rule_risk_score_weight for matching rules)
   - If risk_score >= alert_threshold: Create fraud_detection_alert
   - Auto-action based on rule (block/suspend/OTP/manual review)

2. FRAUD INDICATORS (Red Flags):
   - New user (< 7 days) + large transaction (> 1M UGX)
   - Rapid succession: 5+ transactions in 5 minutes
   - Round numbers: 1M, 5M, 10M UGX (structuring)
   - Impossible travel: Login from 500km+ distance in < 1 hour
   - Repeat no-shows: 3+ no-shows in 30 days
   - Duplicate identity: National ID matches existing user
   - VPN/Proxy usage
   - Account takeover pattern: Password + phone changed + large transaction within 24 hours

3. RISK SCORE CALCULATION:
   risk_score = SUM(rule_risk_score_weight for all matched rules)

   Example:
   - new_user_large_tx (0.4) + rapid_succession (0.3) = 0.7 risk_score
   - 0.7 >= 0.7 alert_threshold → ALERT TRIGGERED

4. AUTOMATED ACTIONS:
   - risk_score < 0.5: No action (monitor only)
   - risk_score 0.5-0.7: Require OTP
   - risk_score 0.7-0.9: Manual review
   - risk_score >= 0.9: Block transaction + suspend user

5. MANUAL REVIEW QUEUE:
   - Security team reviews flagged transactions
   - Review statuses: pending → investigating → confirmed_fraud / false_positive
   - Actions: account_banned / transaction_reversed / warning_issued / no_action

6. BLACKLISTING:
   - Confirmed fraud → Add to blacklisted_entities
   - Block: phone_number, national_id, IP_address, device_id
   - Prevent creating new accounts with blacklisted data

7. MACHINE LEARNING (Future Enhancement):
   - Train ML model on historical fraud patterns
   - Predict fraud probability for new transactions
   - Continuously improve detection accuracy

FRAUD PREVENTION STRATEGIES:
- Trust scores (from migration 031)
- Escrow protection for high-value trades
- Facility staff verification for goods existence
- GPS check-in/out for labor hours
- Photo proof requirements
- Peer review system
- Transaction velocity limits
- Device fingerprinting
*/
