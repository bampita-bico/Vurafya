-- Migration 081: Partner Contract System
-- Revenue foundation: contracts before platform access
-- No pre-seeded partners - all must sign contracts first

-- ============================================================================
-- PARTNER APPLICATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS partner_applications (
    id INTEGER PRIMARY KEY,
    applicant_name VARCHAR(200) NOT NULL,
    applicant_type VARCHAR(40) NOT NULL,
        -- hospital, pharmacy, lab, clinic, individual_doctor, individual_nurse,
        -- individual_nutritionist, individual_therapist
    contact_email VARCHAR(200),
    contact_phone VARCHAR(30),
    country_code VARCHAR(5) NOT NULL,
    region VARCHAR(60),
    city VARCHAR(80),
    physical_address TEXT,
    gps_lat DOUBLE PRECISION,
    gps_lng DOUBLE PRECISION,
    license_number VARCHAR(100),
    regulatory_body VARCHAR(100),
    years_in_operation INTEGER,
    number_of_staff INTEGER,
    specialties TEXT,
        -- JSON array of specialties offered
    services_offered TEXT,
        -- JSON array of services
    proposed_commission_rate DOUBLE PRECISION,
    website_url VARCHAR(300),
    documents_submitted TEXT,
        -- JSON: list of uploaded document references
    application_status VARCHAR(20) NOT NULL DEFAULT 'pending',
        -- pending, under_review, approved, rejected, withdrawn
    reviewed_by INTEGER,
    review_notes TEXT,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PARTNER CONTRACTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS partner_contracts (
    id INTEGER PRIMARY KEY,
    application_id INTEGER REFERENCES partner_applications(id),
    partner_type VARCHAR(40) NOT NULL,
    partner_name VARCHAR(200) NOT NULL,
    contract_number VARCHAR(40) NOT NULL UNIQUE,
        -- e.g., VUR-HOS-2026-0001
    commission_rate_pct DOUBLE PRECISION NOT NULL,
        -- Platform's cut on transactions
    commission_type VARCHAR(40) NOT NULL DEFAULT 'percentage',
        -- percentage, flat_fee, tiered
    contract_start_date DATE NOT NULL,
    contract_end_date DATE NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    renewal_period_months INTEGER DEFAULT 12,
    minimum_transactions_month INTEGER DEFAULT 0,
    performance_bonus_threshold DOUBLE PRECISION,
        -- Revenue threshold for bonus commission reduction
    performance_bonus_rate DOUBLE PRECISION,
        -- Reduced commission rate if threshold met
    terms_version VARCHAR(20) DEFAULT '1.0',
    terms_accepted BOOLEAN DEFAULT FALSE,
    terms_accepted_at TIMESTAMP,
    signed_by_partner VARCHAR(120),
    signed_by_platform VARCHAR(120),
    contract_status VARCHAR(20) NOT NULL DEFAULT 'draft',
        -- draft, pending_signature, active, suspended, terminated, expired
    suspension_reason TEXT,
    termination_reason TEXT,
    terminated_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PARTNER CONTRACT TERMS (templates per partner type)
-- ============================================================================

CREATE TABLE IF NOT EXISTS partner_contract_terms (
    id INTEGER PRIMARY KEY,
    partner_type VARCHAR(40) NOT NULL,
    terms_version VARCHAR(20) NOT NULL DEFAULT '1.0',
    section_name VARCHAR(80) NOT NULL,
    section_order INTEGER NOT NULL,
    section_content TEXT NOT NULL,
    is_negotiable BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(partner_type, terms_version, section_order)
);

-- ============================================================================
-- PARTNER PERFORMANCE METRICS
-- ============================================================================

CREATE TABLE IF NOT EXISTS partner_performance_metrics (
    id INTEGER PRIMARY KEY,
    contract_id INTEGER NOT NULL REFERENCES partner_contracts(id),
    metric_month DATE NOT NULL,
        -- First day of month
    total_transactions INTEGER DEFAULT 0,
    total_revenue_ugx DOUBLE PRECISION DEFAULT 0,
    platform_commission_ugx DOUBLE PRECISION DEFAULT 0,
    partner_payout_ugx DOUBLE PRECISION DEFAULT 0,
    average_rating DOUBLE PRECISION,
        -- 1.0-5.0 from patient reviews
    total_reviews INTEGER DEFAULT 0,
    complaint_count INTEGER DEFAULT 0,
    average_response_time_minutes INTEGER,
    cancellation_rate_pct DOUBLE PRECISION DEFAULT 0,
    patient_satisfaction_score DOUBLE PRECISION,
    performance_grade VARCHAR(5),
        -- A+, A, B, C, D, F
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(contract_id, metric_month)
);

-- ============================================================================
-- ALTER EXISTING FACILITY/PARTNER TABLES
-- Add contract references
-- ============================================================================

ALTER TABLE facility_partners ADD COLUMN contract_id INTEGER REFERENCES partner_contracts(id);
ALTER TABLE facility_partners ADD COLUMN is_contracted BOOLEAN DEFAULT FALSE;
ALTER TABLE facility_partners ADD COLUMN verified_at TIMESTAMP;

-- Enhance partnership_agreements to link with contracts
ALTER TABLE partnership_agreements ADD COLUMN contract_id INTEGER REFERENCES partner_contracts(id);

-- ============================================================================
-- SEED: CONTRACT TERMS TEMPLATES
-- ============================================================================

INSERT INTO partner_contract_terms (partner_type, terms_version, section_name, section_order, section_content, is_negotiable) VALUES
-- Hospital contract terms
('hospital', '1.0', 'Commission Structure', 1,
 'Platform retains 15% commission on all consultations booked through Vurafya. Emergency consultations: 20%. Follow-up consultations within 7 days of initial: 10%.',
 TRUE),
('hospital', '1.0', 'Payment Terms', 2,
 'Partner payouts processed monthly on the 15th. Minimum payout threshold: 50,000 UGX. Payment via mobile money or bank transfer.',
 FALSE),
('hospital', '1.0', 'Service Level Agreement', 3,
 'Hospital must maintain: (a) Average response time under 30 minutes for urgent consultations, (b) Minimum 4.0/5.0 patient rating, (c) Less than 5% cancellation rate.',
 FALSE),
('hospital', '1.0', 'Data Privacy', 4,
 'Hospital agrees to Vurafya data privacy standards. Patient game/avatar data shared with doctors requires explicit patient consent. No data resale.',
 FALSE),
('hospital', '1.0', 'Termination', 5,
 'Either party may terminate with 30 days written notice. Immediate termination for: fraud, patient harm, data breach, or regulatory violation.',
 FALSE),

-- Pharmacy contract terms
('pharmacy', '1.0', 'Commission Structure', 1,
 'Platform retains 10% commission on all orders processed through Vurafya. Prescription orders: 8%. OTC orders: 12%.',
 TRUE),
('pharmacy', '1.0', 'Payment Terms', 2,
 'Payouts processed bi-weekly. Minimum payout: 30,000 UGX.',
 FALSE),
('pharmacy', '1.0', 'Inventory Requirements', 3,
 'Pharmacy must maintain accurate inventory on platform. Stock updates within 4 hours of changes. Expired medication alerts mandatory.',
 FALSE),
('pharmacy', '1.0', 'Delivery Standards', 4,
 'Orders fulfilled within 2 hours (urban) or 24 hours (rural). Cold chain maintained for temperature-sensitive medications.',
 FALSE),
('pharmacy', '1.0', 'Termination', 5,
 'Either party may terminate with 30 days notice. Immediate termination for: dispensing errors, counterfeit medications, regulatory violations.',
 FALSE),

-- Lab contract terms
('lab', '1.0', 'Commission Structure', 1,
 'Platform retains 12% commission on all test bookings. Panel bookings (3+ tests): 10%. Urgent/STAT tests: 15%.',
 TRUE),
('lab', '1.0', 'Payment Terms', 2,
 'Payouts processed monthly on the 15th. Minimum payout: 50,000 UGX.',
 FALSE),
('lab', '1.0', 'Result Delivery', 3,
 'Results must be uploaded to Vurafya within: 24 hours (routine), 6 hours (urgent), 1 hour (STAT). Auto-integration with patient health dashboard.',
 FALSE),
('lab', '1.0', 'Quality Standards', 4,
 'Lab must maintain ISO 15189 or equivalent accreditation. Quality control results shared quarterly. Vurafya reserves right to audit.',
 FALSE),
('lab', '1.0', 'Termination', 5,
 'Either party may terminate with 30 days notice. Immediate termination for: result falsification, quality failures, patient safety concerns.',
 FALSE),

-- Individual doctor contract terms
('individual_doctor', '1.0', 'Commission Structure', 1,
 'Platform retains 15% on standard consultations. 20% on priority/Pro-subscriber consultations. Referral bonus: 5% of referred consultation fee to referring doctor.',
 TRUE),
('individual_doctor', '1.0', 'Payment Terms', 2,
 'Payouts processed weekly for active doctors. Minimum payout: 20,000 UGX.',
 FALSE),
('individual_doctor', '1.0', 'Availability', 3,
 'Doctor must maintain minimum 10 hours/week availability on platform. Schedule updates 48 hours in advance. No-show penalty: 1 warning, then account suspension.',
 TRUE),
('individual_doctor', '1.0', 'Patient Game Stats', 4,
 'Doctor may access patient avatar/game statistics ONLY with explicit patient consent (Pro subscribers only). Data used for clinical insight only, not shared externally.',
 FALSE),
('individual_doctor', '1.0', 'Termination', 5,
 'Either party may terminate with 14 days notice. Immediate termination for: malpractice, license revocation, patient complaints (3+ verified), fraud.',
 FALSE);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'partner_applications' AS tbl, COUNT(*) AS rows FROM partner_applications
UNION ALL
SELECT 'partner_contracts', COUNT(*) FROM partner_contracts
UNION ALL
SELECT 'partner_contract_terms', COUNT(*) FROM partner_contract_terms
UNION ALL
SELECT 'partner_performance_metrics', COUNT(*) FROM partner_performance_metrics;
