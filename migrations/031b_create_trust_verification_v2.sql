-- Migration 031b: Create Trust & Verification System (v2 - clean slate)
-- Date: 2026-04-11
-- Purpose: User reputation scores and peer reviews for barter/labor transactions

-- Drop existing tables if they exist (clean slate)
DROP TABLE IF EXISTS trust_actions_log;
DROP TABLE IF EXISTS transaction_reviews;
DROP TABLE IF EXISTS trust_score_weights;
DROP TABLE IF EXISTS user_trust_ratings;

-- Drop existing view
DROP VIEW IF EXISTS v_user_trust_profile;

-- Drop existing triggers
DROP TRIGGER IF EXISTS trg_create_default_trust_rating;
DROP TRIGGER IF EXISTS trg_update_trust_after_review;
DROP TRIGGER IF EXISTS trg_update_trust_after_barter;
DROP TRIGGER IF EXISTS trg_penalize_trust_barter_dispute;
DROP TRIGGER IF EXISTS trg_update_trust_after_labor;
DROP TRIGGER IF EXISTS trg_penalize_trust_no_show;
DROP TRIGGER IF EXISTS trg_auto_assign_trust_level;
DROP TRIGGER IF EXISTS trg_auto_suspend_bad_actors;

-- User Trust Ratings (Master reputation score per user)
CREATE TABLE user_trust_ratings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL UNIQUE,

  -- Overall Trust Score (0.0 to 1.0)
  trust_score REAL DEFAULT 0.5, -- Start neutral at 0.5
  trust_level VARCHAR(40) DEFAULT 'building', -- building / low / medium / high / verified_trader

  -- Component Scores (0.0 to 1.0)
  barter_reliability REAL DEFAULT 0.5, -- % of barter trades completed successfully
  labor_reliability REAL DEFAULT 0.5, -- % of labor hours verified without disputes
  payment_reliability REAL DEFAULT 0.5, -- % of payments made on time
  verification_rate REAL DEFAULT 0.0, -- % of transactions with facility/peer verification
  avg_rating REAL DEFAULT 0.0, -- 0.0-5.0 peer review average

  -- Transaction Statistics
  total_transactions INTEGER DEFAULT 0,
  completed_transactions INTEGER DEFAULT 0,
  disputed_transactions INTEGER DEFAULT 0,
  cancelled_transactions INTEGER DEFAULT 0,

  -- Barter-Specific Stats
  barter_trades_initiated INTEGER DEFAULT 0,
  barter_trades_completed INTEGER DEFAULT 0,
  barter_trades_disputed INTEGER DEFAULT 0,
  barter_avg_rating REAL DEFAULT 0.0,

  -- Labor-Specific Stats
  labor_hours_committed REAL DEFAULT 0.0,
  labor_hours_completed REAL DEFAULT 0.0,
  labor_hours_verified REAL DEFAULT 0.0,
  labor_no_shows INTEGER DEFAULT 0,
  labor_avg_rating REAL DEFAULT 0.0,

  -- Payment-Specific Stats
  total_payments_made INTEGER DEFAULT 0,
  on_time_payments INTEGER DEFAULT 0,
  late_payments INTEGER DEFAULT 0,
  failed_payments INTEGER DEFAULT 0,

  -- Trust Badges
  has_verified_trader_badge BOOLEAN DEFAULT FALSE, -- trust_score > 0.8
  has_reliable_worker_badge BOOLEAN DEFAULT FALSE, -- labor_reliability > 0.9
  has_honest_trader_badge BOOLEAN DEFAULT FALSE, -- barter_reliability > 0.9
  has_prompt_payer_badge BOOLEAN DEFAULT FALSE, -- payment_reliability > 0.9

  -- Transaction Limits Based on Trust
  max_transaction_ugx REAL, -- NULL = unlimited (for high trust users)
  requires_escrow BOOLEAN DEFAULT TRUE, -- FALSE for trust_score > 0.8
  requires_facility_verification BOOLEAN DEFAULT TRUE, -- FALSE for trust_score > 0.7

  -- Penalties & Warnings
  warning_count INTEGER DEFAULT 0,
  penalty_points INTEGER DEFAULT 0, -- Accumulate penalties for bad behavior
  is_suspended BOOLEAN DEFAULT FALSE,
  suspended_until TIMESTAMP,
  suspension_reason TEXT,

  last_calculated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Transaction Reviews (Peer ratings after each transaction)
CREATE TABLE transaction_reviews (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER NOT NULL,
  transaction_type VARCHAR(40) NOT NULL, -- barter_exchange / labor_booking / pharmacy_order / facility_service

  -- Reviewer & Reviewee
  reviewer_user_id INTEGER NOT NULL, -- Who's leaving the review
  reviewed_user_id INTEGER NOT NULL, -- Who's being reviewed

  -- Rating (1-5 stars)
  rating INTEGER NOT NULL CHECK(rating >= 1 AND rating <= 5),

  -- Review Text
  review_title VARCHAR(200),
  review_text TEXT,

  -- Specific Rating Dimensions (1-5 stars each)
  communication_rating INTEGER CHECK(communication_rating >= 1 AND communication_rating <= 5),
  reliability_rating INTEGER CHECK(reliability_rating >= 1 AND reliability_rating <= 5),
  quality_rating INTEGER CHECK(quality_rating >= 1 AND quality_rating <= 5), -- Quality of goods/service/work
  fairness_rating INTEGER CHECK(fairness_rating >= 1 AND fairness_rating <= 5), -- Was the trade fair?

  -- Review Prompts (Boolean responses)
  would_trade_again BOOLEAN, -- "Would you trade with this person again?"
  showed_up_on_time BOOLEAN, -- "Did they show up on time?" (for labor)
  goods_as_described BOOLEAN, -- "Were goods as described?" (for barter)
  work_completed_fully BOOLEAN, -- "Was work completed fully?" (for labor)

  -- Review Verification
  is_verified_review BOOLEAN DEFAULT FALSE, -- Facility staff verified this review
  verified_by INTEGER, -- Staff ID who verified
  verified_at TIMESTAMP,

  -- Dispute Indicator
  review_disputed BOOLEAN DEFAULT FALSE,
  dispute_reason TEXT,

  -- Helpfulness (Other users vote if review was helpful)
  helpful_count INTEGER DEFAULT 0,
  not_helpful_count INTEGER DEFAULT 0,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (reviewer_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (reviewed_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verified_by) REFERENCES medical_staff(id) ON DELETE SET NULL,

  -- Prevent duplicate reviews (one review per transaction per user)
  UNIQUE (transaction_id, transaction_type, reviewer_user_id)
);

-- Trust Score Calculation Weights (Configurable algorithm)
CREATE TABLE trust_score_weights (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  weight_name VARCHAR(60) NOT NULL UNIQUE,
  weight_value REAL NOT NULL, -- 0.0 to 1.0
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed trust score weights (matches formula in plan: 0.3 barter + 0.3 labor + 0.2 payment + 0.1 verification + 0.1 rating)
INSERT OR IGNORE INTO trust_score_weights (weight_name, weight_value, description) VALUES
('barter_reliability_weight', 0.3, 'Weight for barter trade completion rate'),
('labor_reliability_weight', 0.3, 'Weight for labor hour completion rate'),
('payment_reliability_weight', 0.2, 'Weight for on-time payment rate'),
('verification_rate_weight', 0.1, 'Weight for transaction verification rate'),
('avg_rating_weight', 0.1, 'Weight for peer review average (normalized to 0-1)');

-- Trust Actions Log (Record all trust-affecting events)
CREATE TABLE trust_actions_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  action_type VARCHAR(60) NOT NULL, -- completed_barter / completed_labor / dispute_raised / payment_late / no_show / positive_review / negative_review / warning_issued / penalty_applied

  -- Trust Impact
  trust_score_before REAL,
  trust_score_after REAL,
  trust_score_change REAL, -- Positive or negative

  -- Reference
  reference_id INTEGER, -- Transaction ID, review ID, etc.
  reference_table VARCHAR(60), -- Which table the reference points to

  -- Details
  action_description TEXT,
  penalty_points INTEGER DEFAULT 0,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX idx_trust_ratings_user ON user_trust_ratings(user_id);
CREATE INDEX idx_trust_ratings_score ON user_trust_ratings(trust_score);
CREATE INDEX idx_trust_ratings_level ON user_trust_ratings(trust_level);
CREATE INDEX idx_trust_ratings_suspended ON user_trust_ratings(is_suspended);

CREATE INDEX idx_transaction_reviews_transaction ON transaction_reviews(transaction_id, transaction_type);
CREATE INDEX idx_transaction_reviews_reviewer ON transaction_reviews(reviewer_user_id);
CREATE INDEX idx_transaction_reviews_reviewee ON transaction_reviews(reviewed_user_id);
CREATE INDEX idx_transaction_reviews_rating ON transaction_reviews(rating);

CREATE INDEX idx_trust_actions_user ON trust_actions_log(user_id);
CREATE INDEX idx_trust_actions_type ON trust_actions_log(action_type);
CREATE INDEX idx_trust_actions_created ON trust_actions_log(created_at);

-- View: User Trust Profile (for easy lookup)
CREATE VIEW v_user_trust_profile AS
SELECT
  u.id AS user_id,
  u.username,
  utr.trust_score,
  utr.trust_level,
  utr.barter_reliability,
  utr.labor_reliability,
  utr.payment_reliability,
  utr.avg_rating,
  utr.total_transactions,
  utr.completed_transactions,
  utr.disputed_transactions,
  utr.has_verified_trader_badge,
  utr.has_reliable_worker_badge,
  utr.has_honest_trader_badge,
  utr.has_prompt_payer_badge,
  utr.max_transaction_ugx,
  utr.requires_escrow,
  utr.is_suspended,
  utr.warning_count,
  utr.penalty_points
FROM users u
LEFT JOIN user_trust_ratings utr ON u.id = utr.user_id;

-- Trigger: Create default trust rating when user registers
CREATE TRIGGER trg_create_default_trust_rating
AFTER INSERT ON users
FOR EACH ROW
BEGIN
  INSERT OR IGNORE INTO user_trust_ratings (user_id, trust_score, trust_level, max_transaction_ugx)
  VALUES (NEW.id, 0.5, 'building', 50000); -- New users limited to 50K UGX transactions
END;

-- Trigger: Calculate trust score after review submission
CREATE TRIGGER trg_update_trust_after_review
AFTER INSERT ON transaction_reviews
FOR EACH ROW
BEGIN
  -- Update reviewee's average rating
  UPDATE user_trust_ratings
  SET
    avg_rating = (
      SELECT AVG(tr.rating) FROM transaction_reviews tr WHERE tr.reviewed_user_id = NEW.reviewed_user_id
    ),
    updated_at = CURRENT_TIMESTAMP
  WHERE user_id = NEW.reviewed_user_id;

  -- Recalculate trust score (will be done by backend cron job, but we log the event)
  INSERT OR IGNORE INTO trust_actions_log (user_id, action_type, reference_id, reference_table, action_description)
  VALUES (
    NEW.reviewed_user_id,
    CASE WHEN NEW.rating >= 4 THEN 'positive_review' ELSE 'negative_review' END,
    NEW.id,
    'transaction_reviews',
    'Received ' || NEW.rating || '-star review'
  );
END;

-- Trigger: Update trust score after barter completion
CREATE TRIGGER trg_update_trust_after_barter
AFTER UPDATE OF status ON barter_exchange_transactions
FOR EACH ROW
WHEN NEW.status = 'completed' AND OLD.status = 'in_escrow'
BEGIN
  -- Update both parties' trust ratings
  UPDATE user_trust_ratings
  SET
    barter_trades_completed = barter_trades_completed + 1,
    completed_transactions = completed_transactions + 1,
    barter_reliability = CAST(barter_trades_completed AS REAL) / NULLIF(barter_trades_initiated, 0),
    updated_at = CURRENT_TIMESTAMP
  WHERE user_id IN (NEW.party_a_user_id, NEW.party_b_user_id);

  -- Log trust action
  INSERT OR IGNORE INTO trust_actions_log (user_id, action_type, reference_id, reference_table, action_description)
  SELECT NEW.party_a_user_id, 'completed_barter', NEW.id, 'barter_exchange_transactions', 'Completed barter trade'
  UNION ALL
  SELECT NEW.party_b_user_id, 'completed_barter', NEW.id, 'barter_exchange_transactions', 'Completed barter trade';
END;

-- Trigger: Penalize trust score for barter disputes
CREATE TRIGGER trg_penalize_trust_barter_dispute
AFTER UPDATE OF status ON barter_exchange_transactions
FOR EACH ROW
WHEN NEW.status = 'disputed' AND OLD.status != 'disputed'
BEGIN
  UPDATE user_trust_ratings
  SET
    disputed_transactions = disputed_transactions + 1,
    penalty_points = penalty_points + 10,
    warning_count = warning_count + 1,
    updated_at = CURRENT_TIMESTAMP
  WHERE user_id IN (NEW.party_a_user_id, NEW.party_b_user_id);

  INSERT OR IGNORE INTO trust_actions_log (user_id, action_type, reference_id, reference_table, action_description, penalty_points)
  SELECT NEW.party_a_user_id, 'dispute_raised', NEW.id, 'barter_exchange_transactions', 'Barter trade disputed', 10
  UNION ALL
  SELECT NEW.party_b_user_id, 'dispute_raised', NEW.id, 'barter_exchange_transactions', 'Barter trade disputed', 10;
END;

-- Trigger: Update trust score after labor completion
CREATE TRIGGER trg_update_trust_after_labor
AFTER UPDATE OF is_verified ON labor_hour_ledger
FOR EACH ROW
WHEN NEW.is_verified = TRUE AND OLD.is_verified = FALSE
BEGIN
  UPDATE user_trust_ratings
  SET
    labor_hours_completed = labor_hours_completed + NEW.hours_worked,
    labor_hours_verified = labor_hours_verified + NEW.hours_worked,
    completed_transactions = completed_transactions + 1,
    labor_reliability = CAST(labor_hours_verified AS REAL) / NULLIF(labor_hours_committed, 0),
    updated_at = CURRENT_TIMESTAMP
  WHERE user_id = NEW.user_id;

  INSERT OR IGNORE INTO trust_actions_log (user_id, action_type, reference_id, reference_table, action_description)
  VALUES (NEW.user_id, 'completed_labor', NEW.id, 'labor_hour_ledger', 'Completed ' || NEW.hours_worked || ' hours of ' || NEW.service_type);
END;

-- Trigger: Penalize trust score for labor no-shows
CREATE TRIGGER trg_penalize_trust_no_show
AFTER INSERT ON labor_no_show_log
FOR EACH ROW
BEGIN
  UPDATE user_trust_ratings
  SET
    labor_no_shows = labor_no_shows + 1,
    penalty_points = penalty_points + 20, -- No-shows are worse than disputes
    warning_count = warning_count + 1,
    updated_at = CURRENT_TIMESTAMP
  WHERE user_id = NEW.provider_user_id;

  INSERT OR IGNORE INTO trust_actions_log (user_id, action_type, reference_id, reference_table, action_description, penalty_points)
  VALUES (NEW.provider_user_id, 'no_show', NEW.id, 'labor_no_show_log', 'Did not show up for labor booking', 20);
END;

-- Trigger: Auto-calculate trust level from trust score
CREATE TRIGGER trg_auto_assign_trust_level
AFTER UPDATE OF trust_score ON user_trust_ratings
FOR EACH ROW
BEGIN
  UPDATE user_trust_ratings
  SET
    trust_level = CASE
      WHEN NEW.trust_score >= 0.8 THEN 'verified_trader'
      WHEN NEW.trust_score >= 0.6 THEN 'high'
      WHEN NEW.trust_score >= 0.4 THEN 'medium'
      WHEN NEW.trust_score >= 0.3 THEN 'low'
      ELSE 'building'
    END,
    max_transaction_ugx = CASE
      WHEN NEW.trust_score >= 0.8 THEN NULL -- Unlimited
      WHEN NEW.trust_score >= 0.6 THEN 200000
      WHEN NEW.trust_score >= 0.3 THEN 50000
      ELSE 10000 -- Very limited for low trust
    END,
    requires_escrow = CASE WHEN NEW.trust_score >= 0.8 THEN FALSE ELSE TRUE END,
    requires_facility_verification = CASE WHEN NEW.trust_score >= 0.7 THEN FALSE ELSE TRUE END,
    has_verified_trader_badge = CASE WHEN NEW.trust_score >= 0.8 THEN TRUE ELSE FALSE END,
    has_reliable_worker_badge = CASE WHEN NEW.labor_reliability >= 0.9 THEN TRUE ELSE FALSE END,
    has_honest_trader_badge = CASE WHEN NEW.barter_reliability >= 0.9 THEN TRUE ELSE FALSE END,
    has_prompt_payer_badge = CASE WHEN NEW.payment_reliability >= 0.9 THEN TRUE ELSE FALSE END
  WHERE id = NEW.id;
END;

-- Trigger: Auto-suspend users with too many penalties
CREATE TRIGGER trg_auto_suspend_bad_actors
AFTER UPDATE OF penalty_points ON user_trust_ratings
FOR EACH ROW
WHEN NEW.penalty_points >= 100 AND OLD.penalty_points < 100
BEGIN
  UPDATE user_trust_ratings
  SET
    is_suspended = TRUE,
    suspended_until = datetime('now', '+30 days'),
    suspension_reason = 'Accumulated 100+ penalty points for repeated violations'
  WHERE id = NEW.id;

  INSERT OR IGNORE INTO trust_actions_log (user_id, action_type, action_description, penalty_points)
  VALUES (NEW.user_id, 'penalty_applied', 'User auto-suspended for 30 days due to accumulated penalties', NEW.penalty_points);
END;

-- Function: Calculate overall trust score (documented for backend cron job)
/*
TRUST SCORE CALCULATION (Backend should run daily):

trust_score =
  (0.3 × barter_reliability) +
  (0.3 × labor_reliability) +
  (0.2 × payment_reliability) +
  (0.1 × verification_rate) +
  (0.1 × avg_rating / 5.0)

Where:
- barter_reliability = barter_trades_completed / barter_trades_initiated
- labor_reliability = labor_hours_verified / labor_hours_committed
- payment_reliability = on_time_payments / total_payments_made
- verification_rate = (barter_trades_verified + labor_hours_verified) / total_transactions
- avg_rating = average of all peer reviews (1-5 stars, normalized to 0-1)

PENALTY ADJUSTMENTS:
- Each dispute: -0.05 trust score
- Each no-show: -0.10 trust score
- Each late payment: -0.02 trust score
- Each warning: -0.03 trust score

TRUST LEVELS:
- building: 0.0-0.3 (new users, max 10K UGX transactions)
- low: 0.3-0.4 (limited to 50K UGX transactions)
- medium: 0.4-0.6 (limited to 50K UGX transactions)
- high: 0.6-0.8 (limited to 200K UGX transactions)
- verified_trader: 0.8-1.0 (unlimited transactions, escrow optional)

AUTO-SUSPENSION:
- penalty_points >= 100: 30-day suspension
- penalty_points >= 200: Permanent ban
- warning_count >= 5: Manual review required
*/
