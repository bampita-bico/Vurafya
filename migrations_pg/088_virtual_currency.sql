-- Migration 088: Vura Coin (VRC) - Universal Virtual Currency
-- Baseline currency for all Vura platforms (Vurafya, Vubora, Vuralis)
-- Pegged to UGX initially (1 VRC = 1 UGX), infrastructure for future re-peg
-- Separate from loyalty points (AP, Bora Points) - this is transactional

-- ============================================================================
-- VIRTUAL CURRENCY CONFIG
-- ============================================================================

CREATE TABLE IF NOT EXISTS virtual_currency_config (
    id INTEGER PRIMARY KEY,
    currency_name VARCHAR(60) NOT NULL,
    currency_code VARCHAR(10) NOT NULL UNIQUE,
    currency_symbol VARCHAR(10) NOT NULL,
    description TEXT,
    peg_type VARCHAR(20) NOT NULL DEFAULT 'single',
        -- single (pegged to one currency), basket (weighted average), floating
    peg_currency_code VARCHAR(10),
        -- For single peg: which currency it's pegged to
    peg_rate DOUBLE PRECISION NOT NULL DEFAULT 1.0,
        -- 1 VRC = X of peg currency
    min_transaction DOUBLE PRECISION DEFAULT 1.0,
    max_transaction DOUBLE PRECISION DEFAULT 999999999.0,
    decimal_places INTEGER DEFAULT 2,
    is_active BOOLEAN DEFAULT TRUE,
    applies_to_platforms TEXT DEFAULT '["vurafya","vubora","vuralis"]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- VIRTUAL CURRENCY BASKET (for future basket peg)
-- ============================================================================

CREATE TABLE IF NOT EXISTS virtual_currency_basket (
    id INTEGER PRIMARY KEY,
    virtual_currency_id INTEGER NOT NULL REFERENCES virtual_currency_config(id),
    component_currency_code VARCHAR(10) NOT NULL,
    weight_pct DOUBLE PRECISION NOT NULL,
        -- Percentage weight in basket (all must sum to 100)
    rationale TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(virtual_currency_id, component_currency_code)
);

-- ============================================================================
-- VIRTUAL CURRENCY RATE HISTORY
-- ============================================================================

CREATE TABLE IF NOT EXISTS virtual_currency_rate_history (
    id INTEGER PRIMARY KEY,
    currency_code VARCHAR(10) NOT NULL,
    rate_to_ugx DOUBLE PRECISION NOT NULL,
    peg_type VARCHAR(20),
    basket_snapshot TEXT,
        -- JSON snapshot of basket weights + component rates at this time
    effective_from TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    effective_until TIMESTAMP,
    changed_by VARCHAR(60),
    change_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- USER VIRTUAL CURRENCY WALLETS
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_vrc_wallets (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    currency_code VARCHAR(10) NOT NULL DEFAULT 'VRC',
    balance DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    total_deposited DOUBLE PRECISION DEFAULT 0.0,
    total_withdrawn DOUBLE PRECISION DEFAULT 0.0,
    total_earned DOUBLE PRECISION DEFAULT 0.0,
    total_spent DOUBLE PRECISION DEFAULT 0.0,
    is_active BOOLEAN DEFAULT TRUE,
    last_transaction_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, currency_code)
);

-- ============================================================================
-- VRC TRANSACTIONS LEDGER
-- ============================================================================

CREATE TABLE IF NOT EXISTS vrc_transactions (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    transaction_type VARCHAR(40) NOT NULL,
        -- deposit, withdrawal, transfer, payment, refund,
        -- points_conversion, earning, subscription_payment
    amount DOUBLE PRECISION NOT NULL,
    balance_before DOUBLE PRECISION NOT NULL,
    balance_after DOUBLE PRECISION NOT NULL,
    currency_code VARCHAR(10) NOT NULL DEFAULT 'VRC',

    -- Conversion details (when converting to/from other currencies)
    source_currency VARCHAR(10),
    source_amount DOUBLE PRECISION,
    conversion_rate DOUBLE PRECISION,
    conversion_fee_vrc DOUBLE PRECISION DEFAULT 0,

    -- Reference
    reference_type VARCHAR(40),
        -- consultation, pharmacy_order, lab_order, subscription,
        -- points_exchange, peer_transfer, fiat_deposit, fiat_withdrawal
    reference_id INTEGER,
    counterparty_user_id INTEGER,

    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'completed',
        -- pending, completed, failed, reversed
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CROSS-PLATFORM CURRENCY BRIDGE (Vurafya ↔ Vubora ↔ Vuralis)
-- ============================================================================

CREATE TABLE IF NOT EXISTS cross_platform_currency_bridge (
    id INTEGER PRIMARY KEY,
    platform_name VARCHAR(40) NOT NULL,
        -- vurafya, vubora, vuralis
    points_currency_code VARCHAR(10) NOT NULL,
        -- AP (Afya Points), BP (Bora Points), VP (Vuralis Points)
    points_currency_name VARCHAR(60) NOT NULL,
    points_to_vrc_rate DOUBLE PRECISION NOT NULL,
        -- How many points = 1 VRC
    vrc_to_points_rate DOUBLE PRECISION NOT NULL,
        -- 1 VRC = how many points
    conversion_fee_pct DOUBLE PRECISION DEFAULT 2.0,
        -- Fee for converting between points and VRC
    min_conversion_amount DOUBLE PRECISION DEFAULT 10.0,
    max_daily_conversion DOUBLE PRECISION DEFAULT 100000.0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(platform_name, points_currency_code)
);

-- ============================================================================
-- POINTS-VRC CONVERSION LOG
-- ============================================================================

CREATE TABLE IF NOT EXISTS points_vrc_conversions (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    direction VARCHAR(20) NOT NULL,
        -- points_to_vrc, vrc_to_points
    platform VARCHAR(40) NOT NULL,
    points_currency_code VARCHAR(10) NOT NULL,
    points_amount DOUBLE PRECISION NOT NULL,
    vrc_amount DOUBLE PRECISION NOT NULL,
    conversion_rate DOUBLE PRECISION NOT NULL,
    fee_vrc DOUBLE PRECISION DEFAULT 0,
    fee_pct DOUBLE PRECISION DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'completed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SEED: VRC DEFINITION (pegged to UGX at 1:1)
-- ============================================================================

INSERT INTO virtual_currency_config (id, currency_name, currency_code, currency_symbol, description, peg_type, peg_currency_code, peg_rate, decimal_places, applies_to_platforms)
VALUES (1, 'Vura Coin', 'VRC', 'V',
    'Universal virtual currency for all Vura platforms. Currently pegged 1:1 to UGX. Future: basket peg to African currencies.',
    'single', 'UGX', 1.0, 2, '["vurafya","vubora","vuralis"]');

-- ============================================================================
-- SEED: FUTURE BASKET COMPOSITION (inactive for now)
-- When ready, flip peg_type to 'basket' and activate these
-- ============================================================================

INSERT INTO virtual_currency_basket (virtual_currency_id, component_currency_code, weight_pct, rationale, is_active) VALUES
(1, 'UGX', 25.0, 'Uganda - home market, largest user base', FALSE),
(1, 'KES', 25.0, 'Kenya - largest East African economy, stable shilling', FALSE),
(1, 'TZS', 15.0, 'Tanzania - major East African economy', FALSE),
(1, 'NGN', 15.0, 'Nigeria - largest African economy by GDP', FALSE),
(1, 'ZAR', 10.0, 'South Africa - most traded African currency', FALSE),
(1, 'GHS', 5.0, 'Ghana - growing West African economy', FALSE),
(1, 'ETB', 5.0, 'Ethiopia - fast-growing East African economy', FALSE);

-- ============================================================================
-- SEED: INITIAL RATE HISTORY
-- ============================================================================

INSERT INTO virtual_currency_rate_history (currency_code, rate_to_ugx, peg_type, change_reason)
VALUES ('VRC', 1.0, 'single', 'Initial peg: 1 VRC = 1 UGX');

-- ============================================================================
-- SEED: CROSS-PLATFORM BRIDGE
-- ============================================================================

INSERT INTO cross_platform_currency_bridge (platform_name, points_currency_code, points_currency_name, points_to_vrc_rate, vrc_to_points_rate, conversion_fee_pct) VALUES
('vurafya', 'AP', 'Afya Points', 100.0, 0.01, 2.0),
    -- 100 AP = 1 VRC (since 1 AP = 100 UGX, and 1 VRC = 1 UGX, so 1 AP = 1 VRC... wait)
    -- Actually: 1 AP = 100 UGX. 1 VRC = 1 UGX. So 1 AP = 100 VRC.
    -- points_to_vrc_rate = how many points for 1 VRC → 0.01 (1 AP = 100 VRC)
    -- Let me fix this:
('vubora', 'BP', 'Bora Points', 0.01, 100.0, 2.0),
    -- Placeholder: same rate as AP until Vubora launches
('vuralis', 'VP', 'Vuralis Points', 0.01, 100.0, 2.0);
    -- Placeholder: same rate until Vuralis launches

-- Fix Vurafya rates: 1 AP = 100 UGX = 100 VRC
UPDATE cross_platform_currency_bridge
SET points_to_vrc_rate = 0.01, vrc_to_points_rate = 100.0
WHERE platform_name = 'vurafya';

-- So: to get 1 VRC you need 0.01 AP (i.e., 1 AP gives you 100 VRC)
-- Or: 1 VRC buys you 0.01 AP...
-- Simpler: store "1 AP = X VRC"
-- 1 AP = 100 UGX = 100 VRC → points_to_vrc_rate should mean "1 point = X VRC"
-- Let me use a clearer column interpretation:

-- Actually let me just update to make it clear:
-- 1 AP = 100 VRC (since 1 AP = 100 UGX and 1 VRC = 1 UGX)
UPDATE cross_platform_currency_bridge
SET points_to_vrc_rate = 100.0, vrc_to_points_rate = 0.01
WHERE platform_name = 'vurafya';

UPDATE cross_platform_currency_bridge
SET points_to_vrc_rate = 100.0, vrc_to_points_rate = 0.01
WHERE platform_name = 'vubora';

UPDATE cross_platform_currency_bridge
SET points_to_vrc_rate = 100.0, vrc_to_points_rate = 0.01
WHERE platform_name = 'vuralis';

-- ============================================================================
-- ADD VRC TO UNIVERSAL CURRENCY MATRIX
-- ============================================================================

INSERT INTO universal_currency_matrix (currency_type, currency_code, ugx_exchange_rate, is_base_currency, last_updated, is_active)
VALUES ('virtual', 'VRC', 1.0, FALSE, CURRENT_TIMESTAMP, TRUE);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_user_vrc_wallets_user ON user_vrc_wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_vrc_transactions_user ON vrc_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_vrc_transactions_type ON vrc_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_vrc_transactions_date ON vrc_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_vrc_transactions_ref ON vrc_transactions(reference_type, reference_id);
CREATE INDEX IF NOT EXISTS idx_points_vrc_conversions_user ON points_vrc_conversions(user_id);
CREATE INDEX IF NOT EXISTS idx_virtual_currency_rate_history_code ON virtual_currency_rate_history(currency_code);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'virtual_currency_config' AS tbl, COUNT(*) AS rows FROM virtual_currency_config
UNION ALL
SELECT 'virtual_currency_basket', COUNT(*) FROM virtual_currency_basket
UNION ALL
SELECT 'virtual_currency_rate_history', COUNT(*) FROM virtual_currency_rate_history
UNION ALL
SELECT 'user_vrc_wallets', COUNT(*) FROM user_vrc_wallets
UNION ALL
SELECT 'vrc_transactions', COUNT(*) FROM vrc_transactions
UNION ALL
SELECT 'cross_platform_currency_bridge', COUNT(*) FROM cross_platform_currency_bridge
UNION ALL
SELECT 'points_vrc_conversions', COUNT(*) FROM points_vrc_conversions;
