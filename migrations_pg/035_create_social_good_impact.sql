-- Migration 035: Create Social Good Impact Tracking
-- Date: 2026-04-11
-- Purpose: Track social good impact (30% allocation) - serving broke communities
-- Philosophy: Financial inclusion for people with ZERO money but have goods/skills/time

-- Social Good Impact Log (Track ALL social good transactions with 0% fees)
CREATE TABLE IF NOT EXISTS social_good_impact_log (
  id SERIAL PRIMARY KEY,

  -- Transaction Reference
  transaction_id INTEGER NOT NULL,
  transaction_type VARCHAR(40) NOT NULL, -- barter_exchange / labor_booking / pharmacy_order / facility_service / consultation_booking

  -- User Served
  user_id INTEGER NOT NULL,
  user_category VARCHAR(60), -- elderly / disabled / child / pregnant_woman / low_income / essential_medicine_user / broke_farmer / broke_student

  -- Impact Metrics
  transaction_value_ugx DOUBLE PRECISION NOT NULL, -- Full value of goods/services provided
  fee_waived_ugx DOUBLE PRECISION NOT NULL, -- Platform revenue sacrificed for social good
  fee_waived_pct DOUBLE PRECISION, -- % of transaction value waived

  -- Payment Method Used
  payment_method VARCHAR(40), -- barter_only / labor_only / hybrid / fiat (with waiver)
  used_barter BOOLEAN DEFAULT FALSE,
  used_labor BOOLEAN DEFAULT FALSE,
  used_afya_points BOOLEAN DEFAULT FALSE,
  had_zero_fiat BOOLEAN DEFAULT FALSE, -- User paid ZERO cash (pure barter/labor)

  -- Social Good Type
  impact_type VARCHAR(60) NOT NULL, -- essential_medicine / vulnerable_population / micro_transaction / zero_cash_payment / first_time_user

  -- Health Outcome
  health_service_type VARCHAR(60), -- medication_purchase / lab_test / consultation / dialysis / prenatal_care
  ckd_related BOOLEAN DEFAULT FALSE, -- CKD patient served
  diabetes_related BOOLEAN DEFAULT FALSE,
  hypertension_related BOOLEAN DEFAULT FALSE,

  -- Geographic Impact
  country_code VARCHAR(5),
  district VARCHAR(100),
  is_rural BOOLEAN DEFAULT FALSE, -- Rural community reached

  -- Success Story
  is_success_story BOOLEAN DEFAULT FALSE, -- Flag exceptional impact stories
  success_story_notes TEXT, -- E.g., "Grandmother traded eggs for diabetes medication"

  impact_date DATE NOT NULL,
  month DATE NOT NULL, -- YYYY-MM-01
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code)
);

-- Monthly Social Good Summary
CREATE TABLE IF NOT EXISTS monthly_social_good_summary (
  id SERIAL PRIMARY KEY,
  month DATE NOT NULL UNIQUE, -- YYYY-MM-01

  -- Users Served
  total_users_served INTEGER DEFAULT 0,
  elderly_users_served INTEGER DEFAULT 0,
  disabled_users_served INTEGER DEFAULT 0,
  child_users_served INTEGER DEFAULT 0, -- Under 5
  pregnant_women_served INTEGER DEFAULT 0,
  low_income_users_served INTEGER DEFAULT 0,

  -- Transactions
  total_social_good_transactions INTEGER DEFAULT 0,
  barter_only_transactions INTEGER DEFAULT 0,
  labor_only_transactions INTEGER DEFAULT 0,
  zero_cash_transactions INTEGER DEFAULT 0, -- No fiat used at all

  -- Value Delivered
  total_value_delivered_ugx DOUBLE PRECISION DEFAULT 0, -- Total goods/services provided
  total_fees_waived_ugx DOUBLE PRECISION DEFAULT 0, -- Revenue sacrificed
  total_fees_waived_usd DOUBLE PRECISION,

  -- Essential Medicines
  essential_medicine_transactions INTEGER DEFAULT 0,
  ckd_medications_provided INTEGER DEFAULT 0,
  insulin_doses_provided INTEGER DEFAULT 0,
  hypertension_meds_provided INTEGER DEFAULT 0,

  -- Health Services
  free_lab_tests INTEGER DEFAULT 0,
  free_consultations INTEGER DEFAULT 0,
  free_dialysis_sessions INTEGER DEFAULT 0,

  -- Geographic Reach
  countries_reached INTEGER DEFAULT 0,
  rural_communities_reached INTEGER DEFAULT 0,
  districts_reached INTEGER DEFAULT 0,

  -- Success Stories
  success_stories_count INTEGER DEFAULT 0,

  calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vulnerable Population Registry (Track who qualifies for social good)
CREATE TABLE IF NOT EXISTS vulnerable_population_registry (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE,

  -- Vulnerability Categories
  is_elderly BOOLEAN DEFAULT FALSE, -- Age >= 60
  is_disabled BOOLEAN DEFAULT FALSE,
  is_child BOOLEAN DEFAULT FALSE, -- Age < 5
  is_pregnant BOOLEAN DEFAULT FALSE,
  is_low_income BOOLEAN DEFAULT FALSE, -- Income < poverty line
  is_orphan BOOLEAN DEFAULT FALSE,
  is_refugee BOOLEAN DEFAULT FALSE,
  is_ckd_patient BOOLEAN DEFAULT FALSE,

  -- Verification
  is_verified BOOLEAN DEFAULT FALSE,
  verified_by INTEGER, -- Staff ID who verified
  verification_method VARCHAR(60), -- government_id / facility_confirmation / community_leader / self_reported
  verification_documents TEXT, -- JSON: ["national_id.jpg", "disability_certificate.pdf"]
  verified_at TIMESTAMP,

  -- Benefits Eligibility
  eligible_for_0pct_fees BOOLEAN DEFAULT TRUE,
  eligible_for_priority_matching BOOLEAN DEFAULT TRUE, -- Priority in barter matching
  eligible_for_subsidized_transport BOOLEAN DEFAULT FALSE,

  -- Limits (Prevent abuse)
  max_monthly_transactions INTEGER DEFAULT 50, -- Reasonable limit
  monthly_transactions_used INTEGER DEFAULT 0,
  lifetime_social_good_value_ugx DOUBLE PRECISION DEFAULT 0,

  registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verified_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- Essential Medicine Registry (Which medicines qualify for 0% fees)
CREATE TABLE IF NOT EXISTS essential_medicine_registry (
  id SERIAL PRIMARY KEY,
  medication_id INTEGER NOT NULL UNIQUE,

  -- Classification
  is_essential_medicine BOOLEAN DEFAULT TRUE,
  who_essential_list BOOLEAN DEFAULT FALSE, -- On WHO Essential Medicines List
  national_essential_list BOOLEAN DEFAULT FALSE, -- On national essential list

  -- Social Good Priority
  priority_level VARCHAR(40) DEFAULT 'high', -- low / medium / high / critical
  zero_fee_eligible BOOLEAN DEFAULT TRUE,

  -- Disease Categories
  for_ckd BOOLEAN DEFAULT FALSE,
  for_diabetes BOOLEAN DEFAULT FALSE,
  for_hypertension BOOLEAN DEFAULT FALSE,
  for_malaria BOOLEAN DEFAULT FALSE,
  for_hiv BOOLEAN DEFAULT FALSE,
  for_tb BOOLEAN DEFAULT FALSE,
  for_maternal_health BOOLEAN DEFAULT FALSE,

  -- Justification
  social_good_reason TEXT, -- Why this qualifies for 0% fees

  added_by INTEGER, -- Staff ID who added to list
  added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE,
  FOREIGN KEY (added_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- Success Stories (Highlight exceptional social impact)
CREATE TABLE IF NOT EXISTS social_good_success_stories (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,

  -- Story Details
  story_title VARCHAR(200) NOT NULL, -- E.g., "Grandmother Trades Eggs for Diabetes Medication"
  story_text TEXT NOT NULL, -- Full narrative
  story_category VARCHAR(60), -- zero_cash_trade / life_saved / disease_reversed / community_impact

  -- Impact
  transaction_ids TEXT, -- JSON array of transaction IDs
  health_outcome VARCHAR(200), -- E.g., "Reversed diabetes, A1C dropped from 12% to 6%"
  lives_impacted INTEGER DEFAULT 1, -- Number of people helped

  -- Media
  story_photos TEXT, -- JSON array: ["before.jpg", "after.jpg"]
  story_video_url TEXT,

  -- Sharing
  is_public BOOLEAN DEFAULT FALSE, -- User consented to public sharing
  featured_on_website BOOLEAN DEFAULT FALSE,
  featured_in_newsletter BOOLEAN DEFAULT FALSE,
  featured_in_report BOOLEAN DEFAULT FALSE,

  -- Verification
  is_verified_story BOOLEAN DEFAULT FALSE,
  verified_by INTEGER, -- Staff ID who verified story is true

  story_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verified_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- Social Good Goals (Monthly/quarterly targets for impact)
CREATE TABLE IF NOT EXISTS social_good_goals (
  id SERIAL PRIMARY KEY,
  goal_period VARCHAR(20) NOT NULL UNIQUE, -- YYYY-MM or Q1 2027

  -- Impact Goals
  target_users_served INTEGER NOT NULL,
  target_value_delivered_ugx DOUBLE PRECISION NOT NULL,
  target_essential_medicines INTEGER,
  target_rural_communities INTEGER,
  target_zero_cash_transactions INTEGER,

  -- Actuals
  actual_users_served INTEGER DEFAULT 0,
  actual_value_delivered_ugx DOUBLE PRECISION DEFAULT 0,
  actual_essential_medicines INTEGER DEFAULT 0,

  -- Achievement
  achievement_pct DOUBLE PRECISION,
  is_achieved BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed social good goals (30% allocation of platform activity)
INSERT INTO social_good_goals (goal_period, target_users_served, target_value_delivered_ugx, target_essential_medicines, target_rural_communities, target_zero_cash_transactions) VALUES
('2026-10', 500, 5000000, 300, 5, 100), -- Month 6: 500 users, 5M UGX value, 300 medicine transactions
('2027-04', 15000, 150000000, 5000, 50, 10000), -- Month 12: 15K users, 150M UGX value, 5K medicines
('2028-04', 150000, 1500000000, 50000, 200, 100000); -- Month 24: 150K users, 1.5B UGX value

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_social_good_user ON social_good_impact_log(user_id);
CREATE INDEX IF NOT EXISTS idx_social_good_type ON social_good_impact_log(impact_type);
CREATE INDEX IF NOT EXISTS idx_social_good_month ON social_good_impact_log(month);
CREATE INDEX IF NOT EXISTS idx_social_good_country ON social_good_impact_log(country_code);
CREATE INDEX IF NOT EXISTS idx_social_good_date ON social_good_impact_log(impact_date);
CREATE INDEX IF NOT EXISTS idx_social_good_success ON social_good_impact_log(is_success_story);

CREATE INDEX IF NOT EXISTS idx_vulnerable_user ON vulnerable_population_registry(user_id);
CREATE INDEX IF NOT EXISTS idx_vulnerable_elderly ON vulnerable_population_registry(is_elderly);
CREATE INDEX IF NOT EXISTS idx_vulnerable_disabled ON vulnerable_population_registry(is_disabled);
CREATE INDEX IF NOT EXISTS idx_vulnerable_ckd ON vulnerable_population_registry(is_ckd_patient);
CREATE INDEX IF NOT EXISTS idx_vulnerable_verified ON vulnerable_population_registry(is_verified);

CREATE INDEX IF NOT EXISTS idx_essential_med ON essential_medicine_registry(medication_id);
CREATE INDEX IF NOT EXISTS idx_essential_ckd ON essential_medicine_registry(for_ckd);
CREATE INDEX IF NOT EXISTS idx_essential_diabetes ON essential_medicine_registry(for_diabetes);

CREATE INDEX IF NOT EXISTS idx_success_user ON social_good_success_stories(user_id);
CREATE INDEX IF NOT EXISTS idx_success_public ON social_good_success_stories(is_public);
CREATE INDEX IF NOT EXISTS idx_success_featured ON social_good_success_stories(featured_on_website);

-- View: Current Month Social Good Impact
CREATE VIEW IF NOT EXISTS v_current_month_social_good AS
SELECT
  COUNT(DISTINCT user_id) AS users_served,
  COUNT(*) AS transactions,
  SUM(transaction_value_ugx) AS value_delivered_ugx,
  SUM(fee_waived_ugx) AS fees_waived_ugx,
  SUM(CASE WHEN had_zero_fiat = TRUE THEN 1 ELSE 0 END) AS zero_cash_transactions,
  SUM(CASE WHEN impact_type = 'essential_medicine' THEN 1 ELSE 0 END) AS essential_medicine_count
FROM social_good_impact_log
WHERE month = DATE(CURRENT_DATE, 'start of month');

-- View: Vulnerable Population Summary
CREATE VIEW IF NOT EXISTS v_vulnerable_population_summary AS
SELECT
  COUNT(*) AS total_registered,
  SUM(CASE WHEN is_elderly = TRUE THEN 1 ELSE 0 END) AS elderly_count,
  SUM(CASE WHEN is_disabled = TRUE THEN 1 ELSE 0 END) AS disabled_count,
  SUM(CASE WHEN is_child = TRUE THEN 1 ELSE 0 END) AS child_count,
  SUM(CASE WHEN is_ckd_patient = TRUE THEN 1 ELSE 0 END) AS ckd_patient_count,
  SUM(CASE WHEN is_verified = TRUE THEN 1 ELSE 0 END) AS verified_count
FROM vulnerable_population_registry;

-- Trigger: Log social good impact when fee waived
CREATE TRIGGER IF NOT EXISTS trg_log_social_good_fee_waiver
AFTER INSERT ON fee_waiver_log
FOR EACH ROW
WHEN NEW.is_social_good = TRUE
BEGIN
  INSERT INTO social_good_impact_log (
    transaction_id,
    transaction_type,
    user_id,
    user_category,
    transaction_value_ugx,
    fee_waived_ugx,
    impact_type,
    country_code,
    impact_date,
    month
  )
  VALUES (
    NEW.transaction_id,
    NEW.transaction_type,
    NEW.user_id,
    NEW.social_good_category,
    NEW.original_fee_ugx, -- Approximate transaction value
    NEW.waived_fee_ugx,
    NEW.waiver_reason,
    (SELECT country_code FROM users WHERE id = NEW.user_id),
    DATE('now'),
    DATE('now', 'start of month')
  );
END;

-- Trigger: Update monthly social good summary
CREATE TRIGGER IF NOT EXISTS trg_update_monthly_social_good_summary
AFTER INSERT ON social_good_impact_log
FOR EACH ROW
BEGIN
  INSERT INTO monthly_social_good_summary (
    month,
    total_users_served,
    total_social_good_transactions,
    total_value_delivered_ugx,
    total_fees_waived_ugx,
    zero_cash_transactions
  )
  VALUES (
    NEW.month,
    1,
    1,
    NEW.transaction_value_ugx,
    NEW.fee_waived_ugx,
    CASE WHEN NEW.had_zero_fiat = TRUE THEN 1 ELSE 0 END
  )
  ON CONFLICT(month) DO UPDATE SET
    total_users_served = total_users_served + 1,
    total_social_good_transactions = total_social_good_transactions + 1,
    total_value_delivered_ugx = total_value_delivered_ugx + NEW.transaction_value_ugx,
    total_fees_waived_ugx = total_fees_waived_ugx + NEW.fee_waived_ugx,
    zero_cash_transactions = zero_cash_transactions + CASE WHEN NEW.had_zero_fiat = TRUE THEN 1 ELSE 0 END;
END;

-- Trigger: Auto-register elderly users as vulnerable
CREATE TRIGGER IF NOT EXISTS trg_auto_register_elderly
AFTER INSERT ON user_profiles
FOR EACH ROW
WHEN (CAST((julianday('now') - julianday(NEW.date_of_birth)) / 365.25 AS INTEGER)) >= 60
BEGIN
  INSERT INTO vulnerable_population_registry (user_id, is_elderly, verification_method)
  VALUES (NEW.user_id, TRUE, 'age_calculated');
END;

-- Function: Calculate social good impact (documented for backend)
/*
SOCIAL GOOD IMPACT CALCULATION (30% allocation):

1. Total Platform Revenue (Month 12): 86M UGX ($23K)
2. Social Good Target (30%): 26M UGX worth of fees waived ($7K equivalent)
3. Users Served Target: 15,000 users (50% of 30,000 total active users)

IMPACT METRICS:
- Users served who used barter/labor (no money): COUNT(DISTINCT user_id WHERE had_zero_fiat = TRUE)
- Essential medicine transactions with 0% fees: COUNT WHERE impact_type = 'essential_medicine'
- Vulnerable populations served: COUNT WHERE user_category IN (elderly, disabled, child)
- Rural communities reached: COUNT(DISTINCT district WHERE is_rural = TRUE)
- Success stories: COUNT WHERE is_success_story = TRUE

QUALIFYING CRITERIA:
1. Essential Medicines:
   - CKD medications (dialysis fluids, phosphate binders, erythropoietin)
   - Insulin (Type 1 diabetes)
   - Hypertension meds (ACE inhibitors, ARBs)
   - Malaria prophylaxis
   - HIV antiretrovirals
   - TB medications
   - Prenatal vitamins

2. Vulnerable Populations:
   - Elderly (age >= 60)
   - Disabled (verified disability certificate)
   - Children under 5
   - Pregnant women
   - Low-income (household income < $2/day)
   - Orphans
   - Refugees
   - CKD patients (Stage 3+)

3. Micro-Transactions:
   - Any transaction < 10,000 UGX (~$2.70)

SUCCESS STORY EXAMPLES:
- "Grandmother in Uganda trades eggs for diabetes medication, A1C drops from 12% to 6%"
- "Young coder in Nigeria works 5 hours to pay for mother's dialysis, mother's kidney function stabilizes"
- "Seamstress in Tanzania exchanges dress for lab tests, catches hypertension early"
- "Farmer in Kenya barters tomatoes for prenatal care, delivers healthy baby"

REPORTING:
- Monthly social good report generated on 5th of each month
- Quarterly impact summary for investors/donors
- Annual social good report with success stories
- Public dashboard showing real-time impact metrics
*/
