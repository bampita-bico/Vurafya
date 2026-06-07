-- Migration 033: Create Dynamic Fee Structure
-- Date: 2026-04-11
-- Purpose: Configurable transaction fees for barter, labor, and hybrid payments
-- Philosophy: 70% revenue (fees) + 30% social good (waivers)

-- Fee Structure Config (Master fee rates per transaction type)
CREATE TABLE IF NOT EXISTS fee_structure_config (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fee_type VARCHAR(60) NOT NULL UNIQUE, -- barter_exchange / labor_transaction / verification_fee / escrow_fee / premium_listing

  -- Base Fee Rates
  base_fee_pct REAL NOT NULL, -- Base percentage (3.5% for barter, 5% for labor, 2% for verification, 1% for escrow)
  base_fee_ap INTEGER, -- Flat fee in Afya Points (alternative to percentage)
  base_fee_ugx REAL, -- Flat fee in UGX (alternative to percentage)

  -- Fee Split (for percentage fees)
  platform_share_pct REAL DEFAULT 100.0, -- % of fee that goes to platform
  partner_share_pct REAL DEFAULT 0.0, -- % of fee that goes to facility/pharmacy partner
  worker_share_pct REAL DEFAULT 0.0, -- % of fee charged to worker (for labor)

  -- Minimum & Maximum Fees
  min_fee_ugx REAL, -- Minimum fee (protects revenue on micro-transactions)
  max_fee_ugx REAL, -- Maximum fee cap (protects users on large transactions)

  -- Fee Application
  applies_to VARCHAR(60), -- both_parties / payer_only / receiver_only / split_equally
  charge_method VARCHAR(40) DEFAULT 'percentage', -- percentage / flat_ap / flat_ugx / hybrid

  -- Fee Waivers (Social Good 30%)
  waive_for_essential_medicines BOOLEAN DEFAULT FALSE,
  waive_for_vulnerable_populations BOOLEAN DEFAULT FALSE,
  waive_for_micro_transactions BOOLEAN DEFAULT FALSE, -- < 10K UGX
  waive_for_social_good BOOLEAN DEFAULT FALSE,

  -- Dynamic Adjustments
  is_active BOOLEAN DEFAULT TRUE,
  is_promotional BOOLEAN DEFAULT FALSE, -- Promotional 0% fee periods
  promotional_start_date DATE,
  promotional_end_date DATE,

  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed base fee structure (matches plan: 3.5% barter, 5% labor, 2% verification, 1% escrow)
INSERT OR IGNORE INTO fee_structure_config (fee_type, base_fee_pct, applies_to, description, waive_for_essential_medicines, waive_for_vulnerable_populations, waive_for_micro_transactions) VALUES
('barter_exchange', 3.5, 'split_equally', 'Barter trade transaction fee (1.75% per party)', TRUE, TRUE, TRUE),
('labor_transaction', 5.0, 'receiver_only', 'Labor hour transaction fee (charged to worker)', TRUE, TRUE, TRUE),
('verification_fee', 2.0, 'payer_only', 'Facility staff verification fee', FALSE, TRUE, TRUE),
('escrow_fee', 1.0, 'payer_only', 'Escrow protection fee for high-value transactions (>200K UGX)', FALSE, FALSE, FALSE),
('premium_listing', 0.0, 'payer_only', 'Premium listing fee (500 AP/month flat)', FALSE, FALSE, FALSE);

-- Update premium listing to flat fee
UPDATE fee_structure_config
SET base_fee_ap = 500, charge_method = 'flat_ap'
WHERE fee_type = 'premium_listing';

-- Country-Specific Fee Adjustments (Different fee rates per country)
CREATE TABLE IF NOT EXISTS country_fee_adjustments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  country_code VARCHAR(5) NOT NULL,
  fee_type VARCHAR(60) NOT NULL, -- barter_exchange / labor_transaction / etc.

  -- Adjusted Fee Rates (overrides base fee)
  adjusted_fee_pct REAL,
  adjusted_fee_ap INTEGER,
  adjusted_fee_ugx REAL,

  -- Reason for Adjustment
  adjustment_reason TEXT, -- market_conditions / regulatory_requirement / competitive_pressure / promotional

  effective_date DATE DEFAULT CURRENT_DATE,
  expires_at DATE,
  is_active BOOLEAN DEFAULT TRUE,

  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code),
  UNIQUE (country_code, fee_type)
);

-- Seed country-specific adjustments (example: Nigeria higher fees due to higher costs, Ethiopia lower for market penetration)
INSERT OR IGNORE INTO country_fee_adjustments (country_code, fee_type, adjusted_fee_pct, adjustment_reason) VALUES
('NG', 'barter_exchange', 5.0, 'Higher operational costs in Nigeria'),
('NG', 'labor_transaction', 7.0, 'Higher verification costs'),
('ET', 'barter_exchange', 2.0, 'Market penetration strategy in Ethiopia'),
('ET', 'labor_transaction', 3.0, 'Subsidized fees to build initial user base'),
('ZA', 'barter_exchange', 4.5, 'Premium market in South Africa'),
('ZA', 'labor_transaction', 6.0, 'Higher wage verification requirements');

-- Volume Discount Tiers (Reward high-volume traders with lower fees)
CREATE TABLE IF NOT EXISTS volume_discount_tiers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tier_name VARCHAR(60) NOT NULL UNIQUE, -- bronze / silver / gold / platinum / diamond

  -- Transaction Volume Thresholds
  min_transactions_per_month INTEGER NOT NULL,
  max_transactions_per_month INTEGER,

  -- Discount Rates
  fee_discount_pct REAL NOT NULL, -- % discount off base fee (e.g., 10% = 0.9× multiplier)

  -- Tier Benefits
  tier_description TEXT,
  tier_badge_icon VARCHAR(100), -- Icon reference for gamification

  is_active BOOLEAN DEFAULT TRUE
);

-- Seed volume discount tiers
INSERT OR IGNORE INTO volume_discount_tiers (tier_name, min_transactions_per_month, max_transactions_per_month, fee_discount_pct, tier_description, tier_badge_icon) VALUES
('bronze', 1, 10, 0.0, 'Standard user (0% discount)', 'badge_bronze'),
('silver', 11, 25, 10.0, '11-25 transactions/month (10% fee discount)', 'badge_silver'),
('gold', 26, 50, 25.0, '26-50 transactions/month (25% fee discount)', 'badge_gold'),
('platinum', 51, 100, 40.0, '51-100 transactions/month (40% fee discount)', 'badge_platinum'),
('diamond', 101, NULL, 50.0, '100+ transactions/month (50% fee discount)', 'badge_diamond');

-- User Volume Tier Assignments (Computed monthly)
CREATE TABLE IF NOT EXISTS user_volume_tier_assignments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  month DATE NOT NULL, -- YYYY-MM-01
  volume_tier_id INTEGER NOT NULL,

  -- Transaction Stats for Month
  total_transactions INTEGER DEFAULT 0,
  barter_transactions INTEGER DEFAULT 0,
  labor_transactions INTEGER DEFAULT 0,
  total_fees_paid_ugx REAL DEFAULT 0,
  total_discount_received_ugx REAL DEFAULT 0,

  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (volume_tier_id) REFERENCES volume_discount_tiers(id),
  UNIQUE (user_id, month)
);

-- Fee Waiver Log (Track all fee waivers for social good reporting)
CREATE TABLE IF NOT EXISTS fee_waiver_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER NOT NULL,
  transaction_type VARCHAR(40) NOT NULL, -- barter_exchange / labor_booking / pharmacy_order

  user_id INTEGER NOT NULL,
  original_fee_ugx REAL NOT NULL,
  waived_fee_ugx REAL NOT NULL,

  -- Waiver Reason
  waiver_reason VARCHAR(60) NOT NULL, -- essential_medicine / vulnerable_population / micro_transaction / social_good / promotional

  -- Social Good Classification
  is_social_good BOOLEAN DEFAULT TRUE,
  social_good_category VARCHAR(60), -- elderly / disabled / child / pregnant_woman / low_income / essential_medicine

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Promotional Campaigns (Time-limited fee discounts)
CREATE TABLE IF NOT EXISTS promotional_campaigns (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  campaign_name VARCHAR(200) NOT NULL,
  campaign_code VARCHAR(60) UNIQUE, -- e.g., "FREE_BARTER_FEB"

  -- Campaign Scope
  applies_to_fee_types TEXT, -- JSON array: ["barter_exchange", "labor_transaction"]
  discount_pct REAL NOT NULL, -- 0-100 (100 = free)

  -- Target Audience
  target_countries TEXT, -- JSON array: ["UG", "KE", "TZ"]
  target_user_ids TEXT, -- JSON array of specific user IDs (nullable)
  target_new_users_only BOOLEAN DEFAULT FALSE,
  target_first_transaction_only BOOLEAN DEFAULT FALSE,

  -- Campaign Duration
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  max_redemptions INTEGER, -- Max number of times this promo can be used
  redemptions_count INTEGER DEFAULT 0,

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  created_by INTEGER, -- Staff ID who created campaign

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (created_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- User Promotional Redemptions (Track which users used which promos)
CREATE TABLE IF NOT EXISTS user_promotional_redemptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  promotional_campaign_id INTEGER NOT NULL,
  transaction_id INTEGER NOT NULL,
  transaction_type VARCHAR(40) NOT NULL,

  original_fee_ugx REAL,
  discounted_fee_ugx REAL,
  discount_amount_ugx REAL,

  redeemed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (promotional_campaign_id) REFERENCES promotional_campaigns(id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_fee_config_type ON fee_structure_config(fee_type);
CREATE INDEX IF NOT EXISTS idx_fee_config_active ON fee_structure_config(is_active);

CREATE INDEX IF NOT EXISTS idx_country_fee_country ON country_fee_adjustments(country_code);
CREATE INDEX IF NOT EXISTS idx_country_fee_type ON country_fee_adjustments(fee_type);
CREATE INDEX IF NOT EXISTS idx_country_fee_active ON country_fee_adjustments(is_active);

CREATE INDEX IF NOT EXISTS idx_volume_tier_name ON volume_discount_tiers(tier_name);
CREATE INDEX IF NOT EXISTS idx_volume_tier_min ON volume_discount_tiers(min_transactions_per_month);

CREATE INDEX IF NOT EXISTS idx_user_volume_user ON user_volume_tier_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_user_volume_month ON user_volume_tier_assignments(month);

CREATE INDEX IF NOT EXISTS idx_fee_waiver_user ON fee_waiver_log(user_id);
CREATE INDEX IF NOT EXISTS idx_fee_waiver_reason ON fee_waiver_log(waiver_reason);
CREATE INDEX IF NOT EXISTS idx_fee_waiver_created ON fee_waiver_log(created_at);

CREATE INDEX IF NOT EXISTS idx_promo_code ON promotional_campaigns(campaign_code);
CREATE INDEX IF NOT EXISTS idx_promo_dates ON promotional_campaigns(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_promo_active ON promotional_campaigns(is_active);

CREATE INDEX IF NOT EXISTS idx_user_promo_user ON user_promotional_redemptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_promo_campaign ON user_promotional_redemptions(promotional_campaign_id);

-- View: Current Fee Rates by Country
CREATE VIEW IF NOT EXISTS v_current_fee_rates AS
SELECT
  cs.country_code,
  cs.country_name,
  fsc.fee_type,
  COALESCE(cfa.adjusted_fee_pct, fsc.base_fee_pct) AS current_fee_pct,
  fsc.min_fee_ugx,
  fsc.max_fee_ugx,
  fsc.applies_to,
  fsc.waive_for_essential_medicines,
  fsc.waive_for_vulnerable_populations,
  fsc.waive_for_micro_transactions
FROM countries_supported cs
CROSS JOIN fee_structure_config fsc
LEFT JOIN country_fee_adjustments cfa ON cs.country_code = cfa.country_code AND fsc.fee_type = cfa.fee_type AND cfa.is_active = TRUE
WHERE fsc.is_active = TRUE;

-- View: User Volume Tier Status
CREATE VIEW IF NOT EXISTS v_user_volume_tier_status AS
SELECT
  u.id AS user_id,
  u.username,
  vdt.tier_name,
  vdt.fee_discount_pct,
  uvta.total_transactions,
  uvta.total_fees_paid_ugx,
  uvta.total_discount_received_ugx,
  uvta.month
FROM users u
LEFT JOIN user_volume_tier_assignments uvta ON u.id = uvta.user_id
  AND uvta.month = DATE(CURRENT_DATE, 'start of month')
LEFT JOIN volume_discount_tiers vdt ON uvta.volume_tier_id = vdt.id;

-- Trigger: Calculate fee for barter exchange
CREATE TRIGGER IF NOT EXISTS trg_calc_barter_fee
AFTER INSERT ON barter_exchange_transactions
FOR EACH ROW
WHEN NEW.status = 'accepted'
BEGIN
  -- Get base fee rate for barter
  UPDATE barter_exchange_transactions
  SET transaction_fee_pct = (
    SELECT base_fee_pct FROM fee_structure_config WHERE fee_type = 'barter_exchange' AND is_active = TRUE LIMIT 1
  )
  WHERE id = NEW.id;
END;

-- Trigger: Apply volume discount when user completes transaction
-- (Full calculation done by backend cron job monthly)

-- Trigger: Log fee waiver when social good criteria met
-- (Actual aggregation logic will be in migration 035 - social_good_impact_log)

-- Function: Calculate transaction fee (documented for backend)
/*
FEE CALCULATION LOGIC:

1. Get base fee rate:
   - Check country_fee_adjustments first (country-specific rate)
   - Fallback to fee_structure_config.base_fee_pct

2. Apply volume discount:
   - Get user's volume_tier for current month
   - Apply fee_discount_pct: final_fee = base_fee × (1 - discount_pct/100)

3. Check fee waivers (social good 30%):
   - Essential medicines: 0% fee
   - Vulnerable populations (elderly/disabled/children under 5): 0% fee
   - Micro-transactions (< 10,000 UGX): 0% fee
   - Log all waivers in fee_waiver_log

4. Apply promotional discounts:
   - Check active promotional_campaigns
   - Validate campaign_code if provided
   - Apply discount_pct
   - Increment redemptions_count
   - Log in user_promotional_redemptions

5. Apply min/max caps:
   - If calculated fee < min_fee_ugx: charge min_fee_ugx
   - If calculated fee > max_fee_ugx: charge max_fee_ugx

6. Split fee if needed:
   - Barter: split_equally → 1.75% per party (50/50 split of 3.5%)
   - Labor: receiver_only → 5% charged to worker
   - Verification: payer_only → 2% charged to requester

EXAMPLE 1: Standard barter trade (50,000 UGX equivalent)
- Base fee: 3.5% = 1,750 UGX
- User is Silver tier (10% discount): 1,750 × 0.9 = 1,575 UGX
- Split equally: 787.5 UGX per party
- Convert to AP: 787.5 / 100 = 7.875 AP ≈ 8 AP per party

EXAMPLE 2: Essential medicine purchase (20,000 UGX)
- Base fee: 3.5% = 700 UGX
- Waiver: essential_medicine → 0 UGX (100% waived)
- Platform records 700 UGX in social good impact log

EXAMPLE 3: High-volume trader (120 transactions/month, Diamond tier)
- Base fee: 3.5%
- Diamond discount: 50%
- Effective fee: 1.75%
- Revenue trade-off: Platform earns less per transaction but gains volume
*/
