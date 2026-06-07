-- Migration 082: Doctor Categorization & Game Stat Access
-- Full online hospital: specialty hierarchy
-- Doctors can view patient game stats (with consent, Pro only)

-- ============================================================================
-- MEDICAL SPECIALTIES
-- ============================================================================

CREATE TABLE IF NOT EXISTS medical_specialties (
    id INTEGER PRIMARY KEY,
    specialty_name VARCHAR(80) NOT NULL UNIQUE,
    category VARCHAR(40) NOT NULL,
        -- primary_care, surgical, medical, diagnostic, support
    description TEXT,
    avg_consultation_fee_ugx DOUBLE PRECISION,
    common_conditions TEXT,
        -- JSON array of condition IDs this specialty treats
    icon VARCHAR(60),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- MEDICAL SUB-SPECIALTIES
-- ============================================================================

CREATE TABLE IF NOT EXISTS medical_sub_specialties (
    id INTEGER PRIMARY KEY,
    specialty_id INTEGER NOT NULL REFERENCES medical_specialties(id),
    sub_specialty_name VARCHAR(100) NOT NULL,
    description TEXT,
    additional_training_years INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(specialty_id, sub_specialty_name)
);

-- ============================================================================
-- DOCTOR PROFILES (extended info beyond facility_staff_mapping)
-- ============================================================================

CREATE TABLE IF NOT EXISTS doctor_profiles (
    id INTEGER PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
        -- If doctor is also a Vurafya user
    staff_id INTEGER,
        -- Links to existing staff system
    contract_id INTEGER REFERENCES partner_contracts(id),
    specialty_id INTEGER NOT NULL REFERENCES medical_specialties(id),
    sub_specialty_id INTEGER REFERENCES medical_sub_specialties(id),
    full_name VARCHAR(200) NOT NULL,
    title VARCHAR(20) DEFAULT 'Dr.',
        -- Dr., Prof., Consultant
    license_number VARCHAR(100) NOT NULL,
    license_country VARCHAR(5) NOT NULL,
    license_verified BOOLEAN DEFAULT FALSE,
    license_verified_at TIMESTAMP,
    years_experience INTEGER,
    education TEXT,
        -- JSON: [{"degree":"MBChB","institution":"Makerere","year":2015}]
    languages TEXT,
        -- JSON: ["English","Swahili","Luganda"]
    bio TEXT,
    profile_photo_url VARCHAR(500),
    consultation_fee_ugx DOUBLE PRECISION,
    consultation_fee_usd DOUBLE PRECISION,
    accepts_insurance BOOLEAN DEFAULT FALSE,
    insurance_providers TEXT,
        -- JSON array
    average_rating DOUBLE PRECISION DEFAULT 0.0,
    total_reviews INTEGER DEFAULT 0,
    total_consultations INTEGER DEFAULT 0,
    response_time_avg_minutes INTEGER,
    is_available_for_telehealth BOOLEAN DEFAULT TRUE,
    is_available_for_in_person BOOLEAN DEFAULT FALSE,
    max_patients_per_day INTEGER DEFAULT 20,
    country_code VARCHAR(5),
    city VARCHAR(80),
    hospital_affiliation VARCHAR(200),
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- DOCTOR GAME STAT ACCESS (consent-based, Pro subscribers only)
-- ============================================================================

CREATE TABLE IF NOT EXISTS doctor_game_stat_access (
    id INTEGER PRIMARY KEY,
    patient_user_id INTEGER NOT NULL REFERENCES users(id),
    doctor_profile_id INTEGER NOT NULL REFERENCES doctor_profiles(id),
    access_level VARCHAR(20) NOT NULL DEFAULT 'basic',
        -- basic: level, class, streak
        -- detailed: + achievements, boss progress, nutrition trends
        -- full: + daily logs, medication adherence detail
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
        -- NULL = indefinite until revoked
    revoked_at TIMESTAMP,
    revoked_reason TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    last_accessed_at TIMESTAMP,
    access_count INTEGER DEFAULT 0,
    requires_subscription_tier INTEGER DEFAULT 3,
        -- Pro only
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(patient_user_id, doctor_profile_id)
);

-- ============================================================================
-- DOCTOR AVAILABILITY SLOTS (more granular than existing doctor_availability)
-- ============================================================================

CREATE TABLE IF NOT EXISTS doctor_availability_slots (
    id INTEGER PRIMARY KEY,
    doctor_profile_id INTEGER NOT NULL REFERENCES doctor_profiles(id),
    day_of_week INTEGER NOT NULL,
        -- 0=Sunday, 1=Monday, ..., 6=Saturday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_duration_minutes INTEGER DEFAULT 30,
    consultation_type VARCHAR(40) DEFAULT 'telehealth',
        -- telehealth, in_person, both
    max_bookings INTEGER DEFAULT 1,
    current_bookings INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    effective_from DATE,
    effective_until DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- DOCTOR PATIENT ACCESS LOG (audit trail)
-- ============================================================================

CREATE TABLE IF NOT EXISTS doctor_patient_access_log (
    id INTEGER PRIMARY KEY,
    doctor_profile_id INTEGER NOT NULL REFERENCES doctor_profiles(id),
    patient_user_id INTEGER NOT NULL REFERENCES users(id),
    access_type VARCHAR(40) NOT NULL,
        -- view_avatar, view_achievements, view_streaks, view_boss_progress,
        -- view_nutrition_trends, view_medication_adherence
    data_accessed TEXT,
    accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    consultation_id INTEGER
        -- Links to active consultation if during a session
);

-- ============================================================================
-- SEED: 20 MEDICAL SPECIALTIES
-- ============================================================================

INSERT INTO medical_specialties (id, specialty_name, category, description, avg_consultation_fee_ugx, common_conditions, icon) VALUES
(1, 'General Practice', 'primary_care', 'Primary healthcare provider for all ages and conditions', 30000, '[30,14,11]', 'stethoscope'),
(2, 'Internal Medicine', 'medical', 'Adult medicine specialist for complex internal conditions', 50000, '[14,15,11,17]', 'internal_med'),
(3, 'Nephrology', 'medical', 'Kidney specialist - CKD, dialysis, transplant', 80000, '[1,2,3,4,5,6,7,8,9]', 'kidney'),
(4, 'Endocrinology', 'medical', 'Hormone and metabolic specialist - diabetes, thyroid', 70000, '[10,11,12,13,27]', 'hormone'),
(5, 'Cardiology', 'medical', 'Heart and cardiovascular specialist', 80000, '[14,15,16,17,20]', 'heart'),
(6, 'Pediatrics', 'primary_care', 'Child and adolescent healthcare', 40000, '[30]', 'child'),
(7, 'Obstetrics & Gynecology', 'surgical', 'Women''s reproductive health, pregnancy, childbirth', 60000, '[26,12,27]', 'mother'),
(8, 'Dermatology', 'medical', 'Skin, hair, and nail conditions', 50000, '[]', 'skin'),
(9, 'Psychiatry', 'medical', 'Mental health diagnosis and treatment', 60000, '[]', 'brain'),
(10, 'Oncology', 'medical', 'Cancer diagnosis and treatment', 100000, '[]', 'ribbon'),
(11, 'Orthopedics', 'surgical', 'Bone, joint, and musculoskeletal conditions', 60000, '[]', 'bone'),
(12, 'Ophthalmology', 'surgical', 'Eye diseases and vision care', 50000, '[]', 'eye'),
(13, 'ENT (Otolaryngology)', 'surgical', 'Ear, nose, and throat conditions', 50000, '[]', 'ear'),
(14, 'Urology', 'surgical', 'Urinary tract and male reproductive system', 70000, '[]', 'urology'),
(15, 'Neurology', 'medical', 'Brain and nervous system conditions', 80000, '[24]', 'neuron'),
(16, 'Pulmonology', 'medical', 'Lung and respiratory conditions', 60000, '[23]', 'lungs'),
(17, 'Gastroenterology', 'medical', 'Digestive system conditions', 70000, '[25]', 'stomach'),
(18, 'Rheumatology', 'medical', 'Autoimmune and joint conditions', 70000, '[18]', 'joint'),
(19, 'Infectious Disease', 'medical', 'HIV/AIDS, TB, malaria, and other infections', 60000, '[21,28]', 'virus'),
(20, 'Emergency Medicine', 'primary_care', 'Acute and emergency medical care', 40000, '[]', 'emergency');

-- ============================================================================
-- SEED: ~40 SUB-SPECIALTIES
-- ============================================================================

INSERT INTO medical_sub_specialties (specialty_id, sub_specialty_name, description, additional_training_years) VALUES
-- Nephrology sub-specialties
(3, 'Dialysis', 'Hemodialysis and peritoneal dialysis management', 1),
(3, 'Transplant Nephrology', 'Pre and post kidney transplant care', 2),
(3, 'Pediatric Nephrology', 'Kidney diseases in children', 2),
(3, 'Interventional Nephrology', 'Vascular access and kidney procedures', 1),
(3, 'CKD Management', 'Conservative management of chronic kidney disease', 1),

-- Endocrinology sub-specialties
(4, 'Diabetology', 'Specialized diabetes management (Type 1, 2, gestational)', 1),
(4, 'Thyroid Disorders', 'Thyroid disease diagnosis and management', 1),
(4, 'Reproductive Endocrinology', 'Hormonal fertility issues, PCOS', 2),
(4, 'Pediatric Endocrinology', 'Hormone disorders in children', 2),
(4, 'Metabolic Bone Disease', 'Osteoporosis, metabolic bone disorders', 1),

-- Cardiology sub-specialties
(5, 'Interventional Cardiology', 'Catheterization, stenting, angioplasty', 2),
(5, 'Heart Failure', 'Advanced heart failure management', 1),
(5, 'Electrophysiology', 'Heart rhythm disorders (arrhythmias)', 2),
(5, 'Preventive Cardiology', 'Heart disease prevention and risk management', 1),
(5, 'Pediatric Cardiology', 'Heart conditions in children', 2),

-- Internal Medicine sub-specialties
(2, 'Geriatric Medicine', 'Healthcare for elderly patients', 1),
(2, 'Hospitalist Medicine', 'Inpatient hospital care', 0),
(2, 'Palliative Medicine', 'Pain management and end-of-life care', 1),

-- OB/GYN sub-specialties
(7, 'Maternal-Fetal Medicine', 'High-risk pregnancy management', 2),
(7, 'Reproductive Medicine', 'Fertility treatment and IVF', 2),
(7, 'Gynecologic Oncology', 'Female reproductive cancers', 2),

-- Oncology sub-specialties
(10, 'Medical Oncology', 'Chemotherapy and systemic cancer treatment', 0),
(10, 'Radiation Oncology', 'Radiation therapy for cancer', 0),
(10, 'Surgical Oncology', 'Surgical removal of tumors', 2),
(10, 'Pediatric Oncology', 'Cancer in children', 2),

-- Psychiatry sub-specialties
(9, 'Child Psychiatry', 'Mental health in children and adolescents', 2),
(9, 'Addiction Psychiatry', 'Substance abuse and addiction', 1),
(9, 'Geriatric Psychiatry', 'Mental health in elderly', 1),

-- Neurology sub-specialties
(15, 'Epileptology', 'Seizure disorders management', 1),
(15, 'Stroke Medicine', 'Stroke prevention and treatment', 1),
(15, 'Neuroimmunology', 'Autoimmune neurological conditions (MS)', 1),

-- Infectious Disease sub-specialties
(19, 'HIV Medicine', 'HIV/AIDS management and ARV therapy', 1),
(19, 'Tropical Medicine', 'Malaria, dengue, and tropical infections', 1),
(19, 'TB Management', 'Tuberculosis diagnosis and treatment', 1),

-- Pulmonology sub-specialties
(16, 'Asthma & Allergy', 'Asthma management and allergic conditions', 1),
(16, 'Sleep Medicine', 'Sleep disorders diagnosis and treatment', 1),

-- Gastroenterology sub-specialties
(17, 'Hepatology', 'Liver disease management', 1),
(17, 'Inflammatory Bowel Disease', 'Crohn''s disease and ulcerative colitis', 1),

-- Rheumatology sub-specialties
(18, 'Gout Management', 'Uric acid disorders and gout', 0),
(18, 'Lupus/Autoimmune', 'Systemic autoimmune conditions', 1),

-- General Practice sub-specialties
(1, 'Family Medicine', 'Comprehensive family healthcare', 0),
(1, 'Occupational Health', 'Workplace health and safety', 1);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'medical_specialties' AS tbl, COUNT(*) AS rows FROM medical_specialties
UNION ALL
SELECT 'medical_sub_specialties', COUNT(*) FROM medical_sub_specialties
UNION ALL
SELECT 'doctor_profiles', COUNT(*) FROM doctor_profiles
UNION ALL
SELECT 'doctor_game_stat_access', COUNT(*) FROM doctor_game_stat_access
UNION ALL
SELECT 'doctor_availability_slots', COUNT(*) FROM doctor_availability_slots
UNION ALL
SELECT 'doctor_patient_access_log', COUNT(*) FROM doctor_patient_access_log;
