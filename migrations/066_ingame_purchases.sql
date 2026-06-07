-- Migration 066: In-Game Purchases
-- Fair monetization via avatar cosmetics (can be earned OR purchased)
-- Final migration of Avatar-Health Integration (Phase 3)

-- ============================================================================
-- AVATAR COSMETIC SHOP TABLE
-- ============================================================================
-- Defines pricing and availability for all cosmetic items

CREATE TABLE avatar_cosmetic_shop (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cosmetic_id INTEGER NOT NULL UNIQUE,

    -- Pricing (dual currency: Afya Points OR USD)
    price_afya_points INTEGER,  -- Earnable currency
    price_usd_cents INTEGER,  -- Optional premium purchase (e.g., 99 cents = 99)

    -- Availability
    is_premium BOOLEAN DEFAULT FALSE,  -- Premium-only (no AP purchase option)
    is_season_exclusive BOOLEAN DEFAULT FALSE,
    season_id INTEGER,
    available_from DATE,
    available_until DATE,

    -- Stock (for limited edition cosmetics)
    stock_quantity INTEGER,  -- NULL = unlimited
    stock_remaining INTEGER,
    is_sold_out BOOLEAN DEFAULT FALSE,

    -- Requirements
    min_level_required INTEGER DEFAULT 1,
    min_evolution_stage INTEGER DEFAULT 1,
    requires_achievement_id INTEGER,  -- Must unlock achievement first
    requires_condition VARCHAR(50),  -- diabetes / ckd / hypertension (exclusive to condition)

    -- Discounts
    discount_pct REAL DEFAULT 0,  -- Current discount percentage
    discount_reason VARCHAR(100),  -- holiday_sale / level_up_bonus / birthday
    discount_expires_at TIMESTAMP,

    -- Metadata
    featured BOOLEAN DEFAULT FALSE,
    popularity_rank INTEGER,
    purchase_count INTEGER DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (cosmetic_id) REFERENCES avatar_cosmetics(id),
    FOREIGN KEY (season_id) REFERENCES season_pass_metadata(id),
    FOREIGN KEY (requires_achievement_id) REFERENCES achievements(id)
);

CREATE INDEX idx_cosmetic_shop_featured ON avatar_cosmetic_shop(featured, popularity_rank);
CREATE INDEX idx_cosmetic_shop_premium ON avatar_cosmetic_shop(is_premium, is_sold_out);
CREATE INDEX idx_cosmetic_shop_season ON avatar_cosmetic_shop(season_id, is_season_exclusive);


-- ============================================================================
-- USER PURCHASE HISTORY TABLE
-- ============================================================================
-- Track all cosmetic purchases (both AP and USD)

CREATE TABLE user_purchase_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    cosmetic_id INTEGER NOT NULL,

    -- Transaction details
    purchase_method VARCHAR(20) NOT NULL,  -- afya_points / usd / season_pass_unlock / achievement_unlock / earned
    amount_paid_ap INTEGER DEFAULT 0,
    amount_paid_usd_cents INTEGER DEFAULT 0,

    -- Payment processing (for USD purchases)
    payment_processor VARCHAR(50),  -- stripe / paypal / mpesa / flutterwave
    payment_transaction_id VARCHAR(200),
    payment_status VARCHAR(20),  -- pending / completed / failed / refunded

    -- Context
    was_discounted BOOLEAN DEFAULT FALSE,
    discount_pct REAL DEFAULT 0,
    original_price_ap INTEGER,
    original_price_usd_cents INTEGER,

    -- Gifting
    is_gift BOOLEAN DEFAULT FALSE,
    gifted_to_user_id INTEGER,
    gift_message TEXT,

    -- Metadata
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    applied_to_avatar_at TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (cosmetic_id) REFERENCES avatar_cosmetics(id),
    FOREIGN KEY (gifted_to_user_id) REFERENCES users(id),

    CHECK (purchase_method IN ('afya_points', 'usd', 'season_pass_unlock', 'achievement_unlock', 'earned'))
);

CREATE INDEX idx_purchase_history_user ON user_purchase_history(user_id, purchased_at DESC);
CREATE INDEX idx_purchase_history_cosmetic ON user_purchase_history(cosmetic_id, purchased_at DESC);
CREATE INDEX idx_purchase_history_method ON user_purchase_history(purchase_method, purchased_at DESC);


-- ============================================================================
-- COSMETIC EARNING METHODS TABLE
-- ============================================================================
-- Defines non-purchase ways to earn cosmetics (fair play mechanics)

CREATE TABLE cosmetic_earning_methods (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cosmetic_id INTEGER NOT NULL,

    -- Earning method
    earn_method VARCHAR(50) NOT NULL,  -- achievement / milestone / competition_win / seasonal_event / daily_login_reward
    earn_requirement TEXT NOT NULL,  -- "HbA1c <6.5 for 90 days" / "Win 3 competitions" / "Reach Level 20"

    -- Requirements
    required_achievement_id INTEGER,
    required_milestone_type VARCHAR(50),
    required_milestone_count INTEGER,
    required_level INTEGER,
    required_evolution_stage INTEGER,
    required_competition_wins INTEGER,

    -- Difficulty
    difficulty_rating VARCHAR(20),  -- easy / medium / hard / legendary

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    FOREIGN KEY (cosmetic_id) REFERENCES avatar_cosmetics(id),
    FOREIGN KEY (required_achievement_id) REFERENCES achievements(id)
);

CREATE INDEX idx_earning_methods_cosmetic ON cosmetic_earning_methods(cosmetic_id, is_active);
CREATE INDEX idx_earning_methods_difficulty ON cosmetic_earning_methods(difficulty_rating);


-- ============================================================================
-- COSMETIC WISHLIST TABLE
-- ============================================================================
-- Users can add cosmetics to wishlist for future purchase

CREATE TABLE cosmetic_wishlist (
    user_id INTEGER NOT NULL,
    cosmetic_id INTEGER NOT NULL,

    -- Priority
    priority_rank INTEGER,  -- User's personal ranking

    -- Saving progress
    saved_ap_for_this INTEGER DEFAULT 0,  -- How much AP user has saved toward this item

    -- Notifications
    notify_when_available BOOLEAN DEFAULT TRUE,
    notify_when_discounted BOOLEAN DEFAULT TRUE,

    -- Metadata
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (cosmetic_id) REFERENCES avatar_cosmetics(id),

    PRIMARY KEY (user_id, cosmetic_id)
);

CREATE INDEX idx_wishlist_user ON cosmetic_wishlist(user_id, priority_rank);


-- ============================================================================
-- COSMETIC BUNDLES TABLE
-- ============================================================================
-- Discounted sets of cosmetics

CREATE TABLE cosmetic_bundles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bundle_name VARCHAR(100) NOT NULL,
    description TEXT,

    -- Pricing
    bundle_price_ap INTEGER,
    bundle_price_usd_cents INTEGER,
    individual_total_price_ap INTEGER,  -- If bought separately
    savings_pct REAL,  -- Discount percentage

    -- Availability
    is_limited_time BOOLEAN DEFAULT FALSE,
    available_from DATE,
    available_until DATE,

    -- Bundle contents (JSON array of cosmetic IDs)
    cosmetic_ids_json TEXT NOT NULL,

    -- Requirements
    min_level_required INTEGER DEFAULT 1,

    -- Metadata
    is_active BOOLEAN DEFAULT TRUE,
    purchase_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bundles_active ON cosmetic_bundles(is_active, available_until);


-- ============================================================================
-- SEED DATA: Example Cosmetics in Shop
-- ============================================================================

-- BASIC TIER (Earnable - Stage 2 Unlocks) - Low AP cost
INSERT OR IGNORE INTO avatar_cosmetic_shop (cosmetic_id, price_afya_points, price_usd_cents, is_premium, min_level_required, min_evolution_stage)
VALUES
(10, 500, NULL, FALSE, 5, 2),  -- Basic Hat
(11, 600, NULL, FALSE, 5, 2),  -- Basic Shirt
(12, 550, NULL, FALSE, 5, 2);  -- Basic Shoes

-- INTERMEDIATE TIER (Stage 3 Unlocks) - Medium AP cost or small USD
INSERT OR IGNORE INTO avatar_cosmetic_shop (cosmetic_id, price_afya_points, price_usd_cents, is_premium, min_level_required, min_evolution_stage)
VALUES
(20, 1500, 99, FALSE, 10, 3),  -- Cool Sunglasses (can earn OR buy)
(21, 1800, 99, FALSE, 10, 3),  -- Stylish Jacket
(22, 2000, 149, FALSE, 10, 3),  -- Athletic Shoes
(23, 1600, 99, FALSE, 10, 3),  -- Modern Haircut
(24, 1400, NULL, FALSE, 10, 3);  -- Fitness Band (earn only)

-- PREMIUM TIER (Stage 4 Unlocks) - Higher cost
INSERT OR IGNORE INTO avatar_cosmetic_shop (cosmetic_id, price_afya_points, price_usd_cents, is_premium, min_level_required, min_evolution_stage)
VALUES
(30, 5000, 299, FALSE, 20, 4),  -- Designer Outfit
(31, 4500, 249, FALSE, 20, 4),  -- Luxury Watch
(32, 6000, 349, FALSE, 20, 4),  -- Premium Backpack
(33, NULL, 499, TRUE, 20, 4),  -- Exclusive Glow Effect (premium-only)
(34, 5500, 299, FALSE, 20, 4),  -- Victory Dance Animation
(35, 4800, NULL, FALSE, 20, 4),  -- Champion Badge (earn only)
(36, 5200, 299, FALSE, 20, 4);  -- Energy Aura

-- LEGENDARY TIER (Stage 5 Unlocks) - Very high cost or achievement-locked
INSERT OR IGNORE INTO avatar_cosmetic_shop (cosmetic_id, price_afya_points, price_usd_cents, is_premium, min_level_required, min_evolution_stage, requires_achievement_id)
VALUES
(40, 15000, 999, FALSE, 35, 5, NULL),  -- Golden Crown
(41, 12000, NULL, FALSE, 35, 5, 123),  -- HbA1c Master Badge (requires achievement)
(42, NULL, 1499, TRUE, 35, 5, NULL),  -- Diamond Aura (premium-only)
(43, 18000, NULL, FALSE, 35, 5, 124),  -- CKD Warrior Armor (requires CKD achievement)
(44, 16000, 1299, FALSE, 35, 5, NULL),  -- Legend Wings
(45, 20000, NULL, FALSE, 35, 5, 125),  -- 1000-Day Streak Crown (requires milestone)
(46, NULL, NULL, FALSE, 35, 5, 126),  -- Vuralis Pioneer Badge (cannot be bought, only earned)
(47, 14000, 999, FALSE, 35, 5, NULL),  -- Transformation Glow
(48, 17000, 1199, FALSE, 35, 5, NULL);  -- Victory Pose


-- ============================================================================
-- SEED DATA: Earning Methods
-- ============================================================================

-- Basic cosmetics (Stage 2) - Easy to earn
INSERT OR IGNORE INTO cosmetic_earning_methods (cosmetic_id, earn_method, earn_requirement, required_level, difficulty_rating)
VALUES
(10, 'level_up', 'Reach Level 5', 5, 'easy'),
(11, 'achievement', '7-day meal logging streak', NULL, 'easy'),
(12, 'milestone', 'Log 50 total meals', NULL, 'easy');

-- Intermediate cosmetics (Stage 3) - Medium difficulty
INSERT OR IGNORE INTO cosmetic_earning_methods (cosmetic_id, earn_method, earn_requirement, required_evolution_stage, difficulty_rating)
VALUES
(20, 'evolution', 'Reach Stage 3 (Improving)', NULL, 'medium'),
(21, 'achievement', '30-day meal logging streak', NULL, 'medium'),
(22, 'milestone', 'HbA1c improved by 0.5%', NULL, 'medium'),
(23, 'competition_win', 'Win 1 competition', NULL, 'medium'),
(24, 'milestone', 'Blood pressure controlled for 30 days', NULL, 'medium');

-- Premium cosmetics (Stage 4) - Hard to earn
INSERT OR IGNORE INTO cosmetic_earning_methods (cosmetic_id, earn_method, earn_requirement, required_level, difficulty_rating)
VALUES
(30, 'level_up', 'Reach Level 20', 20, 'hard'),
(31, 'achievement', '90-day meal logging streak', NULL, 'hard'),
(32, 'milestone', 'HbA1c improved by 1.0%', NULL, 'hard'),
(34, 'competition_win', 'Win 3 competitions', NULL, 'hard'),
(35, 'evolution', 'Reach Stage 4 (Thriving)', NULL, 'hard'),
(36, 'achievement', '100% medication adherence for 90 days', NULL, 'hard');

-- Legendary cosmetics (Stage 5) - Legendary difficulty
INSERT OR IGNORE INTO cosmetic_earning_methods (cosmetic_id, earn_method, earn_requirement, required_achievement_id, difficulty_rating)
VALUES
(40, 'evolution', 'Reach Stage 5 (Champion)', NULL, 'legendary'),
(41, 'achievement', 'HbA1c <6.5% for 180 days', 123, 'legendary'),
(43, 'milestone', 'Manage CKD for 1 year with stable labs', NULL, 'legendary'),
(45, 'milestone', '1000-day meal logging streak', NULL, 'legendary'),
(46, 'achievement', 'Complete health transformation (ready for Vuralis)', 126, 'legendary');


-- ============================================================================
-- FAIR MONETIZATION PRINCIPLES
-- ============================================================================

-- 1. NO PAY-TO-WIN
--    - Cosmetics are VISUAL ONLY
--    - No stat boosts, no health advantages
--    - Premium items don't make you healthier

-- 2. EVERYTHING CAN BE EARNED (except a few premium-exclusive)
--    - 95% of cosmetics: Earnable OR purchasable
--    - 5% premium-only: Optional support for development
--    - Example: $0.99 sunglasses OR 1500 AP (2 weeks of active use)

-- 3. TRANSPARENT PRICING
--    - AP costs clearly displayed
--    - USD costs clearly displayed
--    - No hidden fees, no loot boxes, no gambling mechanics

-- 4. EARNING RATE IS FAIR
--    - Daily active user earns ~300-400 AP/day with streaks
--    - Basic cosmetic (500 AP) = 2 days of play
--    - Intermediate cosmetic (1500 AP) = 1 week of play
--    - Premium cosmetic (5000 AP) = 2-3 weeks of play
--    - Legendary cosmetic (15000 AP) = 1-2 months of sustained excellence

-- 5. ACHIEVEMENTS > MONEY
--    - Rarest cosmetics are achievement-locked
--    - "Vuralis Pioneer Badge" cannot be bought
--    - "1000-Day Streak Crown" cannot be bought
--    - Money can't buy respect from community

-- 6. SUPPORT OPTIONS
--    - Users can support development by buying premium cosmetics
--    - Optional "Supporter Badge" for donors
--    - "Thank you" message from Vurafya team


-- ============================================================================
-- USAGE FLOW: Purchasing Cosmetic
-- ============================================================================

-- USER WANTS: "Cool Sunglasses" (cosmetic_id = 20)
--
-- STEP 1: Check availability
-- SELECT * FROM avatar_cosmetic_shop WHERE cosmetic_id = 20
-- → price_afya_points = 1500
-- → price_usd_cents = 99 ($0.99)
-- → min_level_required = 10
-- → min_evolution_stage = 3
--
-- STEP 2: Check user eligibility
-- SELECT level, evolution_stage FROM avatar_stats WHERE user_id = 123
-- → level = 12, evolution_stage = 3 ✅ (meets requirements)
--
-- STEP 3: Check if already owned
-- SELECT * FROM user_cosmetics WHERE user_id = 123 AND cosmetic_id = 20
-- → NULL (not owned) ✅
--
-- STEP 4: Check earning options
-- SELECT * FROM cosmetic_earning_methods WHERE cosmetic_id = 20
-- → earn_method = 'evolution', earn_requirement = 'Reach Stage 3 (Improving)'
-- → User is Stage 3 ✅ Can earn it for free!
--
-- STEP 5: Display options to user
-- UI shows:
-- "Cool Sunglasses"
-- Option 1: ✅ Unlock Free (You've reached Stage 3!)
-- Option 2: Buy with 1500 AP (You have 2300 AP)
-- Option 3: Buy for $0.99 USD
--
-- STEP 6: User chooses "Unlock Free"
-- INSERT OR IGNORE INTO user_purchase_history (user_id, cosmetic_id, purchase_method, amount_paid_ap, amount_paid_usd_cents)
-- VALUES (123, 20, 'achievement_unlock', 0, 0);
--
-- INSERT OR IGNORE INTO user_cosmetics (user_id, cosmetic_id, unlocked_at, unlock_method)
-- VALUES (123, 20, CURRENT_TIMESTAMP, 'achievement');
--
-- Display: "🎉 Unlocked Cool Sunglasses! (Earned by reaching Stage 3)"


-- ALTERNATIVE: User chooses "Buy with AP"
-- STEP 6b: Deduct AP
-- UPDATE users SET afya_points = afya_points - 1500 WHERE id = 123;
--
-- INSERT OR IGNORE INTO user_purchase_history (user_id, cosmetic_id, purchase_method, amount_paid_ap)
-- VALUES (123, 20, 'afya_points', 1500);
--
-- INSERT OR IGNORE INTO user_cosmetics (user_id, cosmetic_id, unlocked_at, unlock_method)
-- VALUES (123, 20, CURRENT_TIMESTAMP, 'purchased_ap');
--
-- Display: "🎉 Purchased Cool Sunglasses for 1500 AP!"


-- ALTERNATIVE: User chooses "Buy with USD"
-- STEP 6c: Process payment
-- → Redirect to Stripe/PayPal/M-Pesa
-- → Payment completed: transaction_id = "stripe_tx_12345"
--
-- INSERT OR IGNORE INTO user_purchase_history (user_id, cosmetic_id, purchase_method, amount_paid_usd_cents, payment_processor, payment_transaction_id, payment_status)
-- VALUES (123, 20, 'usd', 99, 'stripe', 'stripe_tx_12345', 'completed');
--
-- INSERT OR IGNORE INTO user_cosmetics (user_id, cosmetic_id, unlocked_at, unlock_method)
-- VALUES (123, 20, CURRENT_TIMESTAMP, 'purchased_usd');
--
-- Display: "🎉 Purchased Cool Sunglasses for $0.99! Thank you for supporting Vurafya!"


-- ============================================================================
-- REVENUE PROJECTION
-- ============================================================================

-- Conservative monetization estimates:
--
-- USER BASE (Month 12): 30,000 active users
--
-- CONVERSION RATES:
-- - 5% make at least 1 USD purchase/month = 1,500 paying users
-- - Average spend: $2.50/month (2-3 cosmetics)
-- - Monthly USD revenue: 1,500 × $2.50 = $3,750/month
--
-- PREMIUM-ONLY REVENUE:
-- - 1% buy premium-only items = 300 users
-- - Average premium spend: $5/month
-- - Premium revenue: 300 × $5 = $1,500/month
--
-- TOTAL MONTHLY REVENUE (Cosmetics): $5,250/month
--
-- ANNUAL PROJECTION: $63,000/year (conservative)
--
-- NOTE: This is SUPPLEMENTAL to main revenue from facility partnerships,
-- pharmacy commissions, and subscription tiers (Pro features)
