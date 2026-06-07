-- Migration 025: Create Barter Matching Algorithm
-- Date: 2026-04-11
-- Purpose: AI-powered matching to find compatible barter trades

-- Barter Match Scores (Pre-computed matches between users)
CREATE TABLE IF NOT EXISTS barter_match_scores (
  id SERIAL PRIMARY KEY,

  -- User A (has something to offer)
  user_a_id INTEGER NOT NULL,
  user_a_offer_type VARCHAR(40), -- barter_good / barter_service
  user_a_offer_id INTEGER,
  user_a_offer_value_ap INTEGER, -- Value in Afya Points

  -- User B (has what User A wants)
  user_b_id INTEGER NOT NULL,
  user_b_offer_type VARCHAR(40),
  user_b_offer_id INTEGER,
  user_b_offer_value_ap INTEGER,

  -- Match Score (0.0 to 1.0)
  match_score DOUBLE PRECISION NOT NULL, -- 0.0 = terrible match, 1.0 = perfect match
  category_alignment_score DOUBLE PRECISION, -- 0.0-1.0: Does User A want what User B has?
  value_alignment_score DOUBLE PRECISION, -- 0.0-1.0: Are values similar?
  location_proximity_score DOUBLE PRECISION, -- 0.0-1.0: How close geographically?
  trust_score_avg DOUBLE PRECISION, -- 0.0-1.0: Average of both users' trust scores

  -- Match Details
  value_difference_ap INTEGER, -- Absolute difference in value
  distance_km DOUBLE PRECISION, -- Calculated distance between users
  is_mutual_match BOOLEAN DEFAULT FALSE, -- TRUE if both want what the other has

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  match_suggested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  match_viewed BOOLEAN DEFAULT FALSE,
  match_viewed_at TIMESTAMP,
  trade_initiated BOOLEAN DEFAULT FALSE,
  trade_initiated_at TIMESTAMP,

  calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  recalculate_after TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '1 day'), -- Recalculate daily

  FOREIGN KEY (user_a_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (user_b_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (user_a_id, user_a_offer_id, user_b_id, user_b_offer_id)
);

-- Match Score Weights Configuration (Platform can adjust matching algorithm)
CREATE TABLE IF NOT EXISTS match_score_weights (
  id SERIAL PRIMARY KEY,
  weight_name VARCHAR(60) NOT NULL UNIQUE,
  weight_value DOUBLE PRECISION NOT NULL CHECK (weight_value >= 0 AND weight_value <= 1), -- 0.0 to 1.0
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed default matching weights
INSERT INTO match_score_weights (weight_name, weight_value, description) VALUES
('category_alignment', 0.40, 'Weight for category match (does User A want what User B has?)'),
('value_alignment', 0.30, 'Weight for value similarity (are items of similar worth?)'),
('location_proximity', 0.20, 'Weight for geographic closeness (can they meet easily?)'),
('trust_score', 0.10, 'Weight for user trust/reputation (are both reliable traders?)');

-- User Barter Preferences (What they're seeking)
CREATE TABLE IF NOT EXISTS user_barter_preferences (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  seeking_category VARCHAR(60), -- Food, Medication, Lab Tests, Consultations, etc.
  seeking_specific_item TEXT, -- Specific item name (e.g., "Metformin 500mg", "CBC Blood Test")
  max_value_willing_to_trade_ap INTEGER, -- Maximum value they'll trade
  max_distance_km INTEGER, -- How far they'll travel
  preferred_districts TEXT, -- JSON array: ["Kampala", "Wakiso"]
  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Barter Match Notifications (Notify users of good matches)
CREATE TABLE IF NOT EXISTS barter_match_notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  match_score_id INTEGER NOT NULL,
  notification_type VARCHAR(40), -- perfect_match / good_match / new_match / price_drop
  notification_text TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (match_score_id) REFERENCES barter_match_scores(id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_match_scores_user_a ON barter_match_scores(user_a_id);
CREATE INDEX IF NOT EXISTS idx_match_scores_user_b ON barter_match_scores(user_b_id);
CREATE INDEX IF NOT EXISTS idx_match_scores_score ON barter_match_scores(match_score DESC);
CREATE INDEX IF NOT EXISTS idx_match_scores_active ON barter_match_scores(is_active);
CREATE INDEX IF NOT EXISTS idx_match_scores_recalculate ON barter_match_scores(recalculate_after);
CREATE INDEX IF NOT EXISTS idx_match_scores_mutual ON barter_match_scores(is_mutual_match);

CREATE INDEX IF NOT EXISTS idx_user_preferences_user ON user_barter_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_category ON user_barter_preferences(seeking_category);
CREATE INDEX IF NOT EXISTS idx_user_preferences_active ON user_barter_preferences(is_active);

CREATE INDEX IF NOT EXISTS idx_match_notifications_user ON barter_match_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_match_notifications_read ON barter_match_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_match_notifications_created ON barter_match_notifications(created_at);

-- View: Top Matches Per User (for UI display)
CREATE VIEW IF NOT EXISTS v_top_barter_matches AS
WITH RankedMatches AS (
  SELECT
    bms.*,
    u_a.username AS user_a_name,
    u_b.username AS user_b_name,
    ROW_NUMBER() OVER (PARTITION BY bms.user_a_id ORDER BY bms.match_score DESC) AS rank
  FROM barter_match_scores bms
  JOIN users u_a ON bms.user_a_id = u_a.id
  JOIN users u_b ON bms.user_b_id = u_b.id
  WHERE bms.is_active = TRUE
)
SELECT *
FROM RankedMatches
WHERE rank <= 10; -- Top 10 matches per user

-- Function to calculate category alignment (returns 0.0-1.0)
-- This will be implemented in backend, but document the logic here:
/*
CATEGORY ALIGNMENT CALCULATION:
- Check if User A's seeking_categories matches User B's offer category
- Exact match: 1.0
- Parent category match: 0.7
- Related category: 0.5
- No match: 0.0

Example:
User A wants "Medication" (category)
User B offers "Metformin 500mg" (pharmacy_inventory)
→ Exact match on category "Medication" → 1.0
*/

-- Function to calculate value alignment (returns 0.0-1.0)
-- This will be implemented in backend, but document the logic here:
/*
VALUE ALIGNMENT CALCULATION:
value_difference_pct = ABS(value_a - value_b) / MAX(value_a, value_b)
value_alignment_score = 1.0 - value_difference_pct

Example:
User A offers: 50,000 UGX = 500 AP
User B offers: 45,000 UGX = 450 AP
→ Difference: 5,000 UGX / 50,000 UGX = 10% difference
→ Value alignment score: 1.0 - 0.10 = 0.90 (very close values)
*/

-- Function to calculate location proximity (returns 0.0-1.0)
-- This will be implemented in backend using Haversine formula:
/*
LOCATION PROXIMITY CALCULATION (Haversine Distance):
distance_km = Haversine(lat_a, lng_a, lat_b, lng_b)

Scoring:
- 0-5 km: 1.0 (same neighborhood)
- 5-10 km: 0.9 (same city)
- 10-20 km: 0.7 (nearby)
- 20-50 km: 0.5 (reachable)
- 50-100 km: 0.3 (far)
- 100+ km: 0.1 (very far)
*/

-- Function to calculate overall match score
/*
OVERALL MATCH SCORE CALCULATION:
match_score = (category_alignment × 0.40) +
              (value_alignment × 0.30) +
              (location_proximity × 0.20) +
              (trust_score_avg × 0.10)

Where weights come from match_score_weights table.

Example:
Category alignment: 1.0 (perfect match)
Value alignment: 0.90 (10% price difference)
Location proximity: 0.7 (15 km apart)
Trust score avg: 0.8 (both users have good reputation)

match_score = (1.0 × 0.40) + (0.90 × 0.30) + (0.7 × 0.20) + (0.8 × 0.10)
           = 0.40 + 0.27 + 0.14 + 0.08
           = 0.89 (excellent match!)
*/

-- Trigger: Notify user when high-score match is found
CREATE TRIGGER IF NOT EXISTS trg_notify_high_score_match
AFTER INSERT ON barter_match_scores
FOR EACH ROW
WHEN NEW.match_score >= 0.8 -- Excellent match threshold
BEGIN
  INSERT INTO barter_match_notifications (user_id, match_score_id, notification_type, notification_text)
  VALUES (
    NEW.user_a_id,
    NEW.id,
    CASE
      WHEN NEW.match_score >= 0.95 THEN 'perfect_match'
      ELSE 'good_match'
    END,
    'We found a great barter match for you! Match score: ' || CAST(ROUND(NEW.match_score * 100) AS INTEGER) || '%'
  );
END;

-- Trigger: Mark match as inactive when either item becomes unavailable
CREATE TRIGGER IF NOT EXISTS trg_deactivate_match_on_unavailable_good_a
AFTER UPDATE OF is_available ON barter_goods_catalog
FOR EACH ROW
WHEN NEW.is_available = FALSE
BEGIN
  UPDATE barter_match_scores
  SET is_active = FALSE
  WHERE (user_a_offer_id = NEW.id AND user_a_offer_type = 'barter_good')
     OR (user_b_offer_id = NEW.id AND user_b_offer_type = 'barter_good');
END;

CREATE TRIGGER IF NOT EXISTS trg_deactivate_match_on_unavailable_service_a
AFTER UPDATE OF is_available ON barter_services_catalog
FOR EACH ROW
WHEN NEW.is_available = FALSE
BEGIN
  UPDATE barter_match_scores
  SET is_active = FALSE
  WHERE (user_a_offer_id = NEW.id AND user_a_offer_type = 'barter_service')
     OR (user_b_offer_id = NEW.id AND user_b_offer_type = 'barter_service');
END;

-- Trigger: Mark match as traded when transaction is initiated
CREATE TRIGGER IF NOT EXISTS trg_mark_match_traded
AFTER INSERT ON barter_exchange_transactions
FOR EACH ROW
BEGIN
  UPDATE barter_match_scores
  SET
    trade_initiated = TRUE,
    trade_initiated_at = CURRENT_TIMESTAMP,
    is_active = FALSE
  WHERE (user_a_id = NEW.party_a_user_id AND user_a_offer_id = NEW.party_a_offer_id)
     OR (user_b_id = NEW.party_b_user_id AND user_b_offer_id = NEW.party_b_offer_id);
END;
