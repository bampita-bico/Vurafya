-- Migration 036: Create Regulatory Compliance System
-- Date: 2026-04-11
-- Purpose: Track compliance with 54 African countries' financial regulations
-- Key Regulations: KYC, AML, Tax Reporting, Data Privacy (GDPR-style)

-- Regulatory Compliance Log (Track all compliance checks and violations)
CREATE TABLE IF NOT EXISTS regulatory_compliance_log (
  id SERIAL PRIMARY KEY,

  -- Compliance Type
  compliance_type VARCHAR(60) NOT NULL, -- kyc_check / aml_screening / tax_reporting / data_privacy_consent / transaction_limit_check / sanctions_screening

  -- Transaction/User Reference
  user_id INTEGER,
  transaction_id INTEGER,
  transaction_type VARCHAR(40), -- barter_exchange / labor_booking / pharmacy_order

  -- Country-Specific Regulation
  country_code VARCHAR(5) NOT NULL,
  regulatory_body VARCHAR(100), -- Central Bank of Kenya / NDA Uganda / CBN Nigeria
  regulation_reference VARCHAR(200), -- E.g., "Kenya Mobile Money Regulations 2020 Section 5.3"

  -- Compliance Status
  compliance_status VARCHAR(40) NOT NULL, -- passed / failed / pending_review / requires_manual_review / flagged
  risk_level VARCHAR(40), -- low / medium / high / critical

  -- Details
  check_description TEXT,
  failure_reason TEXT,
  remediation_required TEXT, -- What needs to be fixed
  remediation_deadline DATE,

  -- Actions Taken
  action_taken VARCHAR(60), -- user_suspended / transaction_blocked / kyc_requested / manual_review_queued / reported_to_authority
  action_taken_by INTEGER, -- Staff ID
  action_taken_at TIMESTAMP,

  -- Resolution
  is_resolved BOOLEAN DEFAULT FALSE,
  resolved_by INTEGER, -- Staff ID
  resolved_at TIMESTAMP,
  resolution_notes TEXT,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code),
  FOREIGN KEY (action_taken_by) REFERENCES medical_staff(id) ON DELETE SET NULL,
  FOREIGN KEY (resolved_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- KYC (Know Your Customer) Status
CREATE TABLE IF NOT EXISTS user_kyc_status (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE,

  -- KYC Level
  kyc_level VARCHAR(40) DEFAULT 'none', -- none / basic / intermediate / full
  kyc_tier INTEGER DEFAULT 0, -- 0 = none, 1 = basic, 2 = intermediate, 3 = full

  -- Basic KYC (Tier 1) - For transactions < 500K UGX (~$135)
  has_verified_phone BOOLEAN DEFAULT FALSE,
  has_verified_email BOOLEAN DEFAULT FALSE,
  has_provided_full_name BOOLEAN DEFAULT FALSE,
  has_provided_dob BOOLEAN DEFAULT FALSE,
  basic_kyc_approved BOOLEAN DEFAULT FALSE,
  basic_kyc_approved_at TIMESTAMP,

  -- Intermediate KYC (Tier 2) - For transactions 500K-5M UGX (~$135-$1,350)
  has_national_id BOOLEAN DEFAULT FALSE,
  national_id_number VARCHAR(100),
  national_id_verified BOOLEAN DEFAULT FALSE,
  has_proof_of_address BOOLEAN DEFAULT FALSE,
  address_document_type VARCHAR(60), -- utility_bill / bank_statement / rental_agreement
  intermediate_kyc_approved BOOLEAN DEFAULT FALSE,
  intermediate_kyc_approved_at TIMESTAMP,

  -- Full KYC (Tier 3) - For transactions > 5M UGX (~$1,350)
  has_tax_id BOOLEAN DEFAULT FALSE,
  tax_id_number VARCHAR(100),
  has_bank_verification BOOLEAN DEFAULT FALSE,
  bank_account_verified BOOLEAN DEFAULT FALSE,
  has_biometric_verification BOOLEAN DEFAULT FALSE,
  biometric_verified_at TIMESTAMP,
  full_kyc_approved BOOLEAN DEFAULT FALSE,
  full_kyc_approved_at TIMESTAMP,

  -- KYC Documents
  kyc_documents TEXT, -- JSON array: ["national_id_front.jpg", "national_id_back.jpg", "utility_bill.pdf"]

  -- Approval
  approved_by INTEGER, -- Staff ID who approved KYC
  approval_notes TEXT,

  -- Transaction Limits Based on KYC Level
  max_transaction_ugx DOUBLE PRECISION, -- NULL = unlimited for Tier 3
  max_monthly_volume_ugx DOUBLE PRECISION,

  -- Expiry (KYC needs renewal)
  kyc_expires_at DATE, -- Typically 12-24 months after approval
  requires_renewal BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (approved_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- AML (Anti-Money Laundering) Screening
CREATE TABLE IF NOT EXISTS aml_screening_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  transaction_id INTEGER,
  transaction_type VARCHAR(40),

  -- Screening Type
  screening_type VARCHAR(60) NOT NULL, -- transaction_monitoring / pattern_analysis / sanctions_list_check / pep_screening

  -- Risk Indicators
  risk_score DOUBLE PRECISION NOT NULL, -- 0.0 to 1.0 (0 = no risk, 1 = high risk)
  risk_level VARCHAR(40), -- low / medium / high / critical

  -- Red Flags
  red_flags TEXT, -- JSON array: ["rapid_succession_transactions", "round_number_amounts", "structuring_pattern"]
  red_flag_count INTEGER DEFAULT 0,

  -- Transaction Patterns
  transaction_volume_last_30_days_ugx DOUBLE PRECISION,
  transaction_count_last_30_days INTEGER,
  avg_transaction_size_ugx DOUBLE PRECISION,
  unusual_pattern_detected BOOLEAN DEFAULT FALSE,
  unusual_pattern_description TEXT,

  -- Sanctions & PEP Checks
  on_sanctions_list BOOLEAN DEFAULT FALSE,
  sanctions_list_name VARCHAR(200), -- UN Sanctions List / OFAC / EU Sanctions
  is_pep BOOLEAN DEFAULT FALSE, -- Politically Exposed Person
  pep_relationship VARCHAR(200), -- family_member / close_associate / direct_pep

  -- Actions
  requires_reporting BOOLEAN DEFAULT FALSE, -- Must report to Financial Intelligence Unit
  reported_to_authority BOOLEAN DEFAULT FALSE,
  reported_to VARCHAR(200), -- E.g., "Financial Intelligence Authority Uganda"
  reported_at TIMESTAMP,
  report_reference VARCHAR(200),

  screening_result VARCHAR(40), -- cleared / flagged / blocked / reported
  reviewed_by INTEGER, -- Staff ID
  reviewed_at TIMESTAMP,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (reviewed_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- Tax Reporting (Platform must report user earnings to tax authorities)
CREATE TABLE IF NOT EXISTS tax_reporting_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  tax_year INTEGER NOT NULL,
  country_code VARCHAR(5) NOT NULL,

  -- Earnings Subject to Tax
  total_earnings_ugx DOUBLE PRECISION DEFAULT 0,
  total_earnings_local_currency DOUBLE PRECISION DEFAULT 0,
  local_currency_code VARCHAR(5),

  -- Breakdown by Income Type
  labor_earnings_ugx DOUBLE PRECISION DEFAULT 0,
  barter_earnings_ugx DOUBLE PRECISION DEFAULT 0, -- Value received in barter
  platform_commission_earnings_ugx DOUBLE PRECISION DEFAULT 0, -- For facility/pharmacy partners

  -- Tax Thresholds
  tax_threshold_ugx DOUBLE PRECISION, -- Reporting threshold for this country
  exceeds_threshold BOOLEAN DEFAULT FALSE,
  requires_reporting BOOLEAN DEFAULT FALSE,

  -- Tax Identification
  user_tax_id VARCHAR(100),
  has_valid_tax_id BOOLEAN DEFAULT FALSE,

  -- Reporting Status
  reporting_status VARCHAR(40) DEFAULT 'pending', -- pending / submitted / accepted / rejected
  reported_to_authority BOOLEAN DEFAULT FALSE,
  tax_authority VARCHAR(200), -- E.g., "Uganda Revenue Authority"
  report_reference VARCHAR(200),
  reported_at TIMESTAMP,

  -- Documents
  tax_report_document_path VARCHAR(500), -- Path to generated tax report PDF

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code),
  UNIQUE (user_id, tax_year, country_code)
);

-- Data Privacy Consent (GDPR-style consent for data sharing)
CREATE TABLE IF NOT EXISTS data_privacy_consent (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE,

  -- Consent Types
  marketing_consent BOOLEAN DEFAULT FALSE,
  data_sharing_consent BOOLEAN DEFAULT FALSE,
  vuralis_data_sharing_consent BOOLEAN DEFAULT FALSE, -- Share biometric data with Vuralis avatar
  third_party_analytics_consent BOOLEAN DEFAULT FALSE,
  geolocation_tracking_consent BOOLEAN DEFAULT FALSE,

  -- Consent History
  consent_granted_at TIMESTAMP,
  consent_revoked_at TIMESTAMP,
  consent_version VARCHAR(20), -- Version of privacy policy accepted

  -- Data Rights
  right_to_be_forgotten_requested BOOLEAN DEFAULT FALSE,
  right_to_be_forgotten_requested_at TIMESTAMP,
  data_export_requested BOOLEAN DEFAULT FALSE,
  data_export_completed_at TIMESTAMP,

  -- Compliance
  gdpr_compliant BOOLEAN DEFAULT TRUE,
  popia_compliant BOOLEAN DEFAULT TRUE, -- South Africa's POPIA
  ndpr_compliant BOOLEAN DEFAULT TRUE, -- Nigeria's NDPR

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Country Regulatory Requirements (Per-country compliance rules)
CREATE TABLE IF NOT EXISTS country_regulatory_requirements (
  id SERIAL PRIMARY KEY,
  country_code VARCHAR(5) NOT NULL UNIQUE,

  -- KYC Requirements
  kyc_required BOOLEAN DEFAULT TRUE,
  kyc_threshold_ugx DOUBLE PRECISION, -- Transaction value requiring KYC
  kyc_renewal_months INTEGER DEFAULT 24, -- How often KYC needs renewal

  -- AML Requirements
  aml_screening_required BOOLEAN DEFAULT TRUE,
  aml_threshold_ugx DOUBLE PRECISION, -- Transaction value requiring AML screening
  suspicious_transaction_threshold_ugx DOUBLE PRECISION, -- Auto-flag transactions above this

  -- Tax Reporting
  tax_reporting_required BOOLEAN DEFAULT TRUE,
  tax_reporting_threshold_ugx DOUBLE PRECISION, -- Annual earnings threshold for reporting
  tax_authority VARCHAR(200),

  -- Transaction Limits
  max_transaction_without_kyc_ugx DOUBLE PRECISION,
  max_daily_volume_ugx DOUBLE PRECISION,
  max_monthly_volume_ugx DOUBLE PRECISION,

  -- Regulatory Bodies
  central_bank VARCHAR(200),
  financial_intelligence_unit VARCHAR(200),
  data_protection_authority VARCHAR(200),

  -- Mobile Money Regulations
  mobile_money_license_required BOOLEAN DEFAULT FALSE,
  mobile_money_regulatory_body VARCHAR(200),

  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code)
);

-- Seed country regulatory requirements (sample: UG, KE, NG, ZA)
INSERT INTO country_regulatory_requirements (
  country_code,
  kyc_threshold_ugx,
  aml_threshold_ugx,
  suspicious_transaction_threshold_ugx,
  tax_reporting_threshold_ugx,
  max_transaction_without_kyc_ugx,
  max_daily_volume_ugx,
  central_bank,
  financial_intelligence_unit,
  tax_authority
) VALUES
('UG', 500000, 5000000, 10000000, 20000000, 500000, 5000000, 'Bank of Uganda', 'Financial Intelligence Authority Uganda', 'Uganda Revenue Authority'),
('KE', 1750000, 17500000, 35000000, 70000000, 1750000, 17500000, 'Central Bank of Kenya', 'FRC Kenya', 'Kenya Revenue Authority'),
('NG', 675000, 6750000, 13500000, 27000000, 675000, 6750000, 'Central Bank of Nigeria', 'NFIU Nigeria', 'Federal Inland Revenue Service'),
('ZA', 2070000, 20700000, 41400000, 82800000, 2070000, 20700000, 'South African Reserve Bank', 'FIC South Africa', 'SARS');

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_compliance_user ON regulatory_compliance_log(user_id);
CREATE INDEX IF NOT EXISTS idx_compliance_type ON regulatory_compliance_log(compliance_type);
CREATE INDEX IF NOT EXISTS idx_compliance_status ON regulatory_compliance_log(compliance_status);
CREATE INDEX IF NOT EXISTS idx_compliance_country ON regulatory_compliance_log(country_code);
CREATE INDEX IF NOT EXISTS idx_compliance_created ON regulatory_compliance_log(created_at);

CREATE INDEX IF NOT EXISTS idx_kyc_user ON user_kyc_status(user_id);
CREATE INDEX IF NOT EXISTS idx_kyc_level ON user_kyc_status(kyc_level);
CREATE INDEX IF NOT EXISTS idx_kyc_tier ON user_kyc_status(kyc_tier);

CREATE INDEX IF NOT EXISTS idx_aml_user ON aml_screening_log(user_id);
CREATE INDEX IF NOT EXISTS idx_aml_risk ON aml_screening_log(risk_level);
CREATE INDEX IF NOT EXISTS idx_aml_result ON aml_screening_log(screening_result);

CREATE INDEX IF NOT EXISTS idx_tax_user ON tax_reporting_log(user_id);
CREATE INDEX IF NOT EXISTS idx_tax_year ON tax_reporting_log(tax_year);
CREATE INDEX IF NOT EXISTS idx_tax_country ON tax_reporting_log(country_code);

CREATE INDEX IF NOT EXISTS idx_privacy_user ON data_privacy_consent(user_id);

-- View: Users Requiring KYC
CREATE VIEW IF NOT EXISTS v_users_requiring_kyc AS
SELECT
  u.id AS user_id,
  u.username,
  COALESCE(uks.kyc_level, 'none') AS current_kyc_level,
  utr.max_transaction_ugx AS attempted_transaction_ugx,
  crr.kyc_threshold_ugx AS required_kyc_threshold_ugx,
  u.country_code
FROM users u
LEFT JOIN user_kyc_status uks ON u.id = uks.user_id
LEFT JOIN user_trust_ratings utr ON u.id = utr.user_id
LEFT JOIN country_regulatory_requirements crr ON u.country_code = crr.country_code
WHERE utr.max_transaction_ugx > crr.kyc_threshold_ugx
  AND (uks.kyc_level IS NULL OR uks.kyc_level = 'none');

-- Trigger: Create default KYC status for new users
CREATE TRIGGER IF NOT EXISTS trg_create_default_kyc_status
AFTER INSERT ON users
FOR EACH ROW
BEGIN
  INSERT INTO user_kyc_status (user_id, kyc_level, kyc_tier, max_transaction_ugx)
  VALUES (NEW.id, 'none', 0, 50000); -- New users limited to 50K UGX without KYC

  INSERT INTO data_privacy_consent (user_id)
  VALUES (NEW.id);
END;

-- Trigger: Log compliance check when transaction exceeds threshold
CREATE TRIGGER IF NOT EXISTS trg_check_transaction_compliance
AFTER INSERT ON unified_payment_ledger
FOR EACH ROW
WHEN NEW.total_amount_ugx > 500000 -- 500K UGX threshold
BEGIN
  INSERT INTO regulatory_compliance_log (
    compliance_type,
    user_id,
    transaction_id,
    transaction_type,
    country_code,
    compliance_status,
    risk_level,
    check_description
  )
  VALUES (
    'transaction_limit_check',
    NEW.payer_user_id,
    NEW.id,
    NEW.transaction_type,
    (SELECT country_code FROM users WHERE id = NEW.payer_user_id),
    'pending_review',
    'medium',
    'Transaction exceeds 500K UGX threshold, requires KYC verification'
  );
END;

-- Function: KYC & Compliance Flow (documented for backend)
/*
KYC & COMPLIANCE WORKFLOW:

TIER 0: No KYC (0-50K UGX)
- Phone verification only
- Max 50K UGX per transaction
- Max 200K UGX per month

TIER 1: Basic KYC (50K-500K UGX ~$13-$135)
- Verified phone + email
- Full name + date of birth
- Max 500K UGX per transaction
- Max 2M UGX per month

TIER 2: Intermediate KYC (500K-5M UGX ~$135-$1,350)
- National ID verification
- Proof of address
- Max 5M UGX per transaction
- Max 20M UGX per month

TIER 3: Full KYC (>5M UGX ~$1,350+)
- Tax ID verification
- Bank account verification
- Biometric verification (optional)
- Unlimited transactions

AML SCREENING TRIGGERS:
- Transaction > 5M UGX: Auto-screen
- 10+ transactions in 24 hours: Pattern analysis
- Round number amounts (1M, 5M, 10M): Structuring flag
- Rapid succession (< 5 min between transactions): Flag
- Cross-border transactions: Enhanced screening

TAX REPORTING THRESHOLDS (Annual):
- Uganda: 20M UGX (~$5,400)
- Kenya: 70M UGX (~$18,900)
- Nigeria: 27M UGX (~$7,300)
- South Africa: 82M UGX (~$22,200)

DATA PRIVACY RIGHTS:
- Right to access: User can download all their data (JSON export)
- Right to rectification: User can correct incorrect data
- Right to erasure ("right to be forgotten"): User can request account deletion
- Right to data portability: User can export data to another platform
- Right to object: User can revoke consent for data processing
*/
