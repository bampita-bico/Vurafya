-- Migration 047: Medication Submissions
-- Community-powered medication database with PHARMACIST REVIEW (safety-critical)
-- Part of User Submission System (Phase 5)

-- ============================================================================
-- MEDICATION_SUBMISSIONS TABLE
-- ============================================================================
-- NEW table - medications require professional verification

CREATE TABLE medication_submissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Submitter information
    submitted_by_user_id INTEGER NOT NULL,
    submitter_name VARCHAR(100),
    submitter_email VARCHAR(200),
    submitter_is_healthcare_professional BOOLEAN DEFAULT FALSE,
    submitter_credentials VARCHAR(200),  -- "PharmD", "MD", "Registered Nurse"

    -- Medication identification
    generic_name VARCHAR(200) NOT NULL,
    brand_names TEXT,  -- JSON array: ["Glucophage", "Metformin HCl"]
    active_ingredient VARCHAR(200) NOT NULL,
    drug_class VARCHAR(100),  -- Biguanide / ACE Inhibitor / Beta-blocker / etc.

    -- Classification
    drug_category_id INTEGER,
    therapeutic_category VARCHAR(100),  -- Antidiabetic / Antihypertensive / Antibiotic / etc.

    -- Formulations
    dosage_forms TEXT,  -- JSON array: ["tablet", "capsule", "injection", "syrup"]
    standard_doses TEXT,  -- JSON: {"tablet": "500mg", "injection": "100mg/ml"}
    available_strengths TEXT,  -- JSON array: ["500mg", "850mg", "1000mg"]

    -- Prescribing information
    requires_prescription BOOLEAN DEFAULT TRUE,
    is_controlled_substance BOOLEAN DEFAULT FALSE,
    controlled_schedule VARCHAR(10),  -- Schedule II, III, IV, V (DEA classification)

    -- Availability
    is_essential_medicine BOOLEAN DEFAULT FALSE,  -- WHO Essential Medicines List
    is_available_locally BOOLEAN DEFAULT FALSE,
    available_regions TEXT,  -- JSON array: ["UG", "KE", "TZ"]
    typical_cost_ugx INTEGER,  -- Approximate cost per unit

    -- Indications & Usage
    primary_indication TEXT NOT NULL,  -- What is this drug used for?
    secondary_indications TEXT,  -- Other uses
    contraindications TEXT,  -- When NOT to use
    pregnancy_category VARCHAR(10),  -- A / B / C / D / X (FDA classification)

    -- Safety information
    common_side_effects TEXT,  -- JSON array
    serious_side_effects TEXT,  -- JSON array
    black_box_warnings TEXT,  -- Most serious FDA warnings
    drug_interactions_known TEXT,  -- JSON array of known drug interactions

    -- Administration
    typical_dosing_frequency VARCHAR(100),  -- Once daily / Twice daily / Three times daily
    administration_instructions TEXT,  -- "Take with food", "Take on empty stomach"
    maximum_daily_dose VARCHAR(50),

    -- Data source
    data_source VARCHAR(200) NOT NULL,  -- "Product monograph", "WHO Essential Medicines", "NDA Uganda", "Personal experience"
    source_url VARCHAR(500),
    reference_documents TEXT,  -- JSON array of document URLs
    data_quality_self_rating INTEGER,

    -- Supporting evidence
    has_product_monograph BOOLEAN DEFAULT FALSE,
    product_monograph_url VARCHAR(500),
    has_package_insert BOOLEAN DEFAULT FALSE,
    package_insert_url VARCHAR(500),

    -- Submission context
    submission_reason TEXT NOT NULL,  -- Why is this medication important to add?
    patient_experience TEXT,  -- User's personal experience (if submitter is patient)

    -- Review workflow (REQUIRES PHARMACIST)
    status VARCHAR(20) DEFAULT 'pending',
    requires_pharmacist_review BOOLEAN DEFAULT TRUE,  -- Always TRUE for medications
    reviewed_by_pharmacist_id INTEGER,
    pharmacist_name VARCHAR(100),
    pharmacist_license_number VARCHAR(100),
    reviewed_at TIMESTAMP,
    approval_notes TEXT,
    rejection_reason TEXT,
    revision_requested_notes TEXT,

    -- Safety flags (set by pharmacist reviewer)
    safety_verified BOOLEAN DEFAULT FALSE,
    interactions_verified BOOLEAN DEFAULT FALSE,
    dosing_verified BOOLEAN DEFAULT FALSE,
    regulatory_status_verified BOOLEAN DEFAULT FALSE,

    -- Metadata
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    urgent_submission BOOLEAN DEFAULT FALSE,  -- Flag for medications urgently needed in database

    FOREIGN KEY (submitted_by_user_id) REFERENCES users(id),
    FOREIGN KEY (drug_category_id) REFERENCES drug_categories(id),
    FOREIGN KEY (reviewed_by_pharmacist_id) REFERENCES medical_staff(id),

    CHECK (status IN ('pending', 'under_review', 'approved', 'rejected', 'needs_revision')),
    CHECK (data_quality_self_rating BETWEEN 1 AND 5)
);

CREATE INDEX idx_medication_submissions_status ON medication_submissions(status, submitted_at DESC);
CREATE INDEX idx_medication_submissions_user ON medication_submissions(submitted_by_user_id);
CREATE INDEX idx_medication_submissions_pharmacist_review ON medication_submissions(requires_pharmacist_review, status);
CREATE INDEX idx_medication_submissions_urgent ON medication_submissions(urgent_submission, status);


-- ============================================================================
-- MEDICATION SUBMISSION REVIEW CHECKLIST
-- ============================================================================
-- Pharmacist must verify all items before approval

CREATE TABLE medication_submission_review_checklist (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    medication_submission_id INTEGER NOT NULL UNIQUE,
    reviewed_by_pharmacist_id INTEGER NOT NULL,

    -- Verification checklist
    generic_name_verified BOOLEAN DEFAULT FALSE,
    active_ingredient_verified BOOLEAN DEFAULT FALSE,
    drug_class_verified BOOLEAN DEFAULT FALSE,
    dosing_verified BOOLEAN DEFAULT FALSE,
    contraindications_verified BOOLEAN DEFAULT FALSE,
    side_effects_verified BOOLEAN DEFAULT FALSE,
    drug_interactions_checked BOOLEAN DEFAULT FALSE,
    pregnancy_safety_verified BOOLEAN DEFAULT FALSE,
    regulatory_status_checked BOOLEAN DEFAULT FALSE,
    local_availability_confirmed BOOLEAN DEFAULT FALSE,

    -- Overall assessment
    all_items_verified BOOLEAN DEFAULT FALSE,
    ready_for_approval BOOLEAN DEFAULT FALSE,

    -- Notes
    pharmacist_notes TEXT,
    additional_interactions_found TEXT,  -- Interactions not mentioned by submitter
    additional_warnings_found TEXT,

    -- Metadata
    review_started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    review_completed_at TIMESTAMP,

    FOREIGN KEY (medication_submission_id) REFERENCES medication_submissions(id),
    FOREIGN KEY (reviewed_by_pharmacist_id) REFERENCES medical_staff(id)
);


-- ============================================================================
-- EXAMPLE SEED DATA
-- ============================================================================

-- Example 1: Essential diabetes medication
INSERT OR IGNORE INTO medication_submissions (
    submitted_by_user_id, submitter_name, submitter_email,
    submitter_is_healthcare_professional, submitter_credentials,
    generic_name, brand_names, active_ingredient, drug_class, therapeutic_category,
    dosage_forms, standard_doses, available_strengths,
    requires_prescription, is_essential_medicine, is_available_locally,
    available_regions, typical_cost_ugx,
    primary_indication, contraindications,
    common_side_effects, serious_side_effects,
    typical_dosing_frequency, administration_instructions, maximum_daily_dose,
    data_source, source_url, data_quality_self_rating,
    submission_reason, urgent_submission,
    status
) VALUES (
    789, 'Dr. Peter Okello', 'pokello@hospital.ug',
    TRUE, 'MBChB, Internal Medicine Specialist',
    'Metformin', '["Glucophage", "Metformin HCl", "Diabex"]', 'Metformin Hydrochloride',
    'Biguanide', 'Antidiabetic',
    '["tablet", "extended-release tablet"]', '{"tablet": "500mg, 850mg, 1000mg", "extended-release": "500mg, 750mg"}',
    '["500mg", "850mg", "1000mg"]',
    TRUE, TRUE, TRUE,
    '["UG", "KE", "TZ", "RW"]', 1500,
    'Type 2 Diabetes Mellitus - First-line treatment',
    'Severe renal impairment (eGFR <30), metabolic acidosis, diabetic ketoacidosis',
    '["Nausea", "Diarrhea", "Abdominal discomfort", "Metallic taste"]',
    '["Lactic acidosis (rare but serious)", "Vitamin B12 deficiency with long-term use"]',
    'Twice daily or three times daily with meals',
    'Take with meals to reduce GI side effects. Start with low dose and gradually increase.',
    '2550mg daily (3 × 850mg)',
    'WHO Essential Medicines List + Product Monograph',
    'https://www.who.int/publications/i/item/WHO-MHP-HPS-EML-2023.02',
    5,
    'Metformin is the most commonly prescribed diabetes medication globally and in East Africa. Critical to have in database.',
    TRUE,
    'pending'
);

-- Example 2: Local antimalarial
INSERT OR IGNORE INTO medication_submissions (
    submitted_by_user_id, submitter_name,
    generic_name, brand_names, active_ingredient, drug_class, therapeutic_category,
    dosage_forms, standard_doses, available_strengths,
    requires_prescription, is_essential_medicine, is_available_locally,
    available_regions, typical_cost_ugx,
    primary_indication, contraindications,
    common_side_effects,
    typical_dosing_frequency, administration_instructions,
    data_source, data_quality_self_rating,
    submission_reason,
    status
) VALUES (
    890, 'Community Health Worker - Joyce',
    'Artemether/Lumefantrine', '["Coartem", "Riamet"]',
    'Artemether 20mg + Lumefantrine 120mg',
    'Antimalarial Combination', 'Antimalarial',
    '["tablet"]', '{"tablet": "20mg/120mg"}', '["20mg/120mg"]',
    TRUE, TRUE, TRUE,
    '["UG", "KE", "TZ", "RW", "BI"]', 8000,
    'Uncomplicated Plasmodium falciparum malaria',
    'First trimester of pregnancy, severe hepatic impairment, known hypersensitivity',
    '["Headache", "Dizziness", "Sleep disturbances", "Palpitations"]',
    'Twice daily for 3 days (6 doses total)',
    'Take with food or fatty drink to increase absorption. Complete full 3-day course.',
    'National Malaria Control Program Uganda + WHO Guidelines',
    4,
    'Coartem is the most widely used antimalarial in East Africa. Essential for malaria management.',
    'pending'
);


-- ============================================================================
-- SAFETY NOTES
-- ============================================================================

-- 1. PHARMACIST REVIEW MANDATORY
--    - No medication submission can be approved without pharmacist verification
--    - Pharmacist must have valid license
--    - Review checklist must be 100% complete

-- 2. VERIFICATION PROCESS
--    - Cross-check with WHO Essential Medicines List
--    - Cross-check with national drug authority (NDA Uganda, PPB Kenya, TFDA Tanzania)
--    - Verify drug interactions against drug_drug_interactions table
--    - Verify contraindications against drug_food_interactions, drug_beverage_interactions

-- 3. LIABILITY
--    - Vurafya displays drug information for educational purposes
--    - Users must consult healthcare provider before taking any medication
--    - Disclaimer: "This information is not a substitute for professional medical advice"

-- 4. UPDATE FREQUENCY
--    - Medication data should be reviewed annually
--    - Safety alerts (FDA, WHO) trigger immediate review
--    - User reports of adverse effects trigger review
