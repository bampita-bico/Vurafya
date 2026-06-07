-- Migration 083: Consultation Revenue & Universal Receipts
-- "Everything has receipts" - platform takes a cut on all transactions
-- Commission structure: 7-20% depending on type

-- ============================================================================
-- CONSULTATION BOOKINGS (with fee breakdown)
-- ============================================================================

CREATE TABLE IF NOT EXISTS consultation_bookings (
    id INTEGER PRIMARY KEY,
    patient_user_id INTEGER NOT NULL REFERENCES users(id),
    doctor_profile_id INTEGER NOT NULL REFERENCES doctor_profiles(id),
    consultation_type VARCHAR(40) NOT NULL,
        -- standard, priority, follow_up, emergency, second_opinion
    booking_source VARCHAR(20) DEFAULT 'app',
        -- app, referral, scheduled, walk_in
    scheduled_at TIMESTAMP NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
        -- pending, confirmed, in_progress, completed, cancelled, no_show

    -- Fee breakdown
    consultation_fee_ugx DOUBLE PRECISION NOT NULL,
    consultation_fee_usd DOUBLE PRECISION,
    currency_code VARCHAR(10) DEFAULT 'UGX',
    platform_commission_pct DOUBLE PRECISION NOT NULL,
    platform_commission_ugx DOUBLE PRECISION NOT NULL,
    doctor_payout_ugx DOUBLE PRECISION NOT NULL,
    tax_ugx DOUBLE PRECISION DEFAULT 0,
    discount_ugx DOUBLE PRECISION DEFAULT 0,
    discount_reason VARCHAR(100),

    -- Subscription info
    patient_subscription_tier INTEGER DEFAULT 1,
    is_priority BOOLEAN DEFAULT FALSE,

    -- Payment
    payment_method VARCHAR(40),
    payment_status VARCHAR(20) DEFAULT 'pending',
        -- pending, paid, refunded, failed
    payment_reference VARCHAR(200),
    paid_at TIMESTAMP,

    -- Referral tracking
    referred_by_doctor_id INTEGER REFERENCES doctor_profiles(id),
    referral_transaction_id INTEGER,

    -- Notes
    chief_complaint TEXT,
    notes TEXT,

    cancelled_at TIMESTAMP,
    cancellation_reason TEXT,
    cancelled_by VARCHAR(20),
        -- patient, doctor, system
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CONSULTATION RECEIPTS (Universal receipt for EVERY transaction)
-- ============================================================================

CREATE TABLE IF NOT EXISTS consultation_receipts (
    id INTEGER PRIMARY KEY,
    receipt_number VARCHAR(60) NOT NULL UNIQUE,
        -- VUR-RCT-2026-000001
    receipt_type VARCHAR(40) NOT NULL,
        -- consultation, lab_test, pharmacy_order, subscription, referral_fee,
        -- guild_creation, premium_purchase
    transaction_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Parties
    payer_user_id INTEGER REFERENCES users(id),
    payer_name VARCHAR(200),
    provider_type VARCHAR(40),
        -- doctor, hospital, pharmacy, lab, platform
    provider_id INTEGER,
    provider_name VARCHAR(200),

    -- Amounts
    gross_amount_ugx DOUBLE PRECISION NOT NULL,
    gross_amount_usd DOUBLE PRECISION,
    currency_code VARCHAR(10) DEFAULT 'UGX',
    platform_fee_ugx DOUBLE PRECISION NOT NULL DEFAULT 0,
    platform_fee_pct DOUBLE PRECISION,
    provider_payout_ugx DOUBLE PRECISION DEFAULT 0,
    tax_ugx DOUBLE PRECISION DEFAULT 0,
    tax_rate_pct DOUBLE PRECISION DEFAULT 0,
    discount_ugx DOUBLE PRECISION DEFAULT 0,
    net_amount_ugx DOUBLE PRECISION NOT NULL,

    -- Payment details
    payment_method VARCHAR(40),
        -- mobile_money, card, afya_points, hybrid, bank_transfer
    payment_reference VARCHAR(200),
    payment_status VARCHAR(20) NOT NULL DEFAULT 'completed',

    -- Linked entities
    consultation_booking_id INTEGER REFERENCES consultation_bookings(id),
    subscription_transaction_id INTEGER REFERENCES subscription_transactions(id),
    referral_transaction_id INTEGER,
    lab_order_id INTEGER,
    pharmacy_order_id INTEGER,

    -- Description
    line_items TEXT,
        -- JSON: [{"description":"Consultation - Nephrology","qty":1,"amount":80000}]
    notes TEXT,

    -- Audit
    generated_by VARCHAR(20) DEFAULT 'system',
    voided BOOLEAN DEFAULT FALSE,
    voided_at TIMESTAMP,
    void_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- REFERRAL TRANSACTIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS referral_transactions (
    id INTEGER PRIMARY KEY,
    referring_doctor_id INTEGER NOT NULL REFERENCES doctor_profiles(id),
    referred_to_type VARCHAR(40) NOT NULL,
        -- doctor, lab, pharmacy, hospital
    referred_to_id INTEGER NOT NULL,
    patient_user_id INTEGER NOT NULL REFERENCES users(id),
    consultation_booking_id INTEGER REFERENCES consultation_bookings(id),
    referral_reason TEXT,

    -- Fee breakdown
    referral_fee_ugx DOUBLE PRECISION DEFAULT 0,
    platform_cut_ugx DOUBLE PRECISION DEFAULT 0,
    referring_doctor_cut_ugx DOUBLE PRECISION DEFAULT 0,

    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
        -- pending, accepted, completed, declined, expired
    accepted_at TIMESTAMP,
    completed_at TIMESTAMP,

    receipt_id INTEGER REFERENCES consultation_receipts(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- REFERRAL COMMISSION RULES
-- ============================================================================

CREATE TABLE IF NOT EXISTS referral_commission_rules (
    id INTEGER PRIMARY KEY,
    referral_type VARCHAR(60) NOT NULL UNIQUE,
        -- doctor_to_specialist, doctor_to_lab, doctor_to_pharmacy,
        -- doctor_to_hospital, hospital_to_lab
    total_referral_fee_pct DOUBLE PRECISION NOT NULL,
        -- Total fee as % of referred service cost
    platform_share_pct DOUBLE PRECISION NOT NULL,
        -- Platform's share of the referral fee
    referring_share_pct DOUBLE PRECISION NOT NULL,
        -- Referring provider's share of the referral fee
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PLATFORM REVENUE LEDGER (master revenue tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS platform_revenue_ledger (
    id INTEGER PRIMARY KEY,
    revenue_date DATE NOT NULL,
    revenue_source VARCHAR(40) NOT NULL,
        -- consultation_commission, referral_fee, subscription,
        -- lab_commission, pharmacy_commission, premium_purchase,
        -- guild_creation_fee, ad_revenue
    receipt_id INTEGER REFERENCES consultation_receipts(id),
    amount_ugx DOUBLE PRECISION NOT NULL,
    amount_usd DOUBLE PRECISION,
    currency_code VARCHAR(10) DEFAULT 'UGX',
    partner_contract_id INTEGER REFERENCES partner_contracts(id),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PAYOUT REQUESTS (partner/doctor payout requests)
-- ============================================================================

CREATE TABLE IF NOT EXISTS payout_requests (
    id INTEGER PRIMARY KEY,
    requestor_type VARCHAR(40) NOT NULL,
        -- doctor, hospital, pharmacy, lab
    requestor_id INTEGER NOT NULL,
    contract_id INTEGER REFERENCES partner_contracts(id),
    payout_period_start DATE NOT NULL,
    payout_period_end DATE NOT NULL,
    total_gross_ugx DOUBLE PRECISION NOT NULL,
    platform_commission_ugx DOUBLE PRECISION NOT NULL,
    net_payout_ugx DOUBLE PRECISION NOT NULL,
    transaction_count INTEGER DEFAULT 0,
    payment_method VARCHAR(40),
    payment_reference VARCHAR(200),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
        -- pending, approved, processing, paid, rejected
    approved_by INTEGER,
    approved_at TIMESTAMP,
    paid_at TIMESTAMP,
    rejection_reason TEXT,
    receipt_id INTEGER REFERENCES consultation_receipts(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SEED: REFERRAL COMMISSION RULES
-- ============================================================================

INSERT INTO referral_commission_rules (referral_type, total_referral_fee_pct, platform_share_pct, referring_share_pct, description) VALUES
('doctor_to_specialist', 10.0, 5.0, 5.0, 'GP refers patient to specialist. 10% fee split equally between platform and referring doctor.'),
('doctor_to_lab', 8.0, 5.0, 3.0, 'Doctor refers patient for lab tests. 8% fee: 5% platform, 3% referring doctor.'),
('doctor_to_pharmacy', 7.0, 4.0, 3.0, 'Doctor prescribes medication filled at partner pharmacy. 7% fee: 4% platform, 3% doctor.'),
('doctor_to_hospital', 10.0, 6.0, 4.0, 'Doctor refers patient to partner hospital. 10% fee: 6% platform, 4% referring doctor.'),
('hospital_to_lab', 8.0, 5.0, 3.0, 'Hospital refers patient to external lab. 8% fee: 5% platform, 3% hospital.'),
('specialist_to_specialist', 8.0, 4.0, 4.0, 'Specialist cross-referral. 8% fee split equally.'),
('emergency_referral', 5.0, 3.0, 2.0, 'Emergency referral - reduced fees. 5% fee: 3% platform, 2% referring.'),
('second_opinion', 10.0, 5.0, 5.0, 'Second opinion request. 10% fee split equally.');

-- ============================================================================
-- ADD COMMISSION TYPES TO FEE STRUCTURE CONFIG
-- ============================================================================

INSERT INTO fee_structure_config (fee_type, base_fee_pct, platform_share_pct, partner_share_pct, worker_share_pct, applies_to, charge_method, description, is_active, created_at, updated_at) VALUES
('consultation_standard', 15.0, 100.0, 0.0, 0.0, 'payer_only', 'percentage', 'Standard consultation: 15% platform commission', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('consultation_priority', 20.0, 100.0, 0.0, 0.0, 'payer_only', 'percentage', 'Priority consultation (Pro subscribers): 20% platform commission', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('consultation_follow_up', 10.0, 100.0, 0.0, 0.0, 'payer_only', 'percentage', 'Follow-up consultation within 7 days: 10% commission', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('lab_test_booking', 12.0, 100.0, 0.0, 0.0, 'payer_only', 'percentage', 'Lab test booking: 12% platform commission', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('pharmacy_order', 10.0, 100.0, 0.0, 0.0, 'payer_only', 'percentage', 'Pharmacy order: 10% platform commission', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('subscription_revenue', 100.0, 100.0, 0.0, 0.0, 'payer_only', 'percentage', 'Subscription fees: 100% platform revenue', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'consultation_bookings' AS tbl, COUNT(*) AS rows FROM consultation_bookings
UNION ALL
SELECT 'consultation_receipts', COUNT(*) FROM consultation_receipts
UNION ALL
SELECT 'referral_transactions', COUNT(*) FROM referral_transactions
UNION ALL
SELECT 'referral_commission_rules', COUNT(*) FROM referral_commission_rules
UNION ALL
SELECT 'platform_revenue_ledger', COUNT(*) FROM platform_revenue_ledger
UNION ALL
SELECT 'payout_requests', COUNT(*) FROM payout_requests
UNION ALL
SELECT 'fee_structure_config', COUNT(*) FROM fee_structure_config;
