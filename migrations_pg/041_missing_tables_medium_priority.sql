-- Migration 041: Missing Tables - MEDIUM PRIORITY
-- Meal planning, medical consulting, and preventive medicine enhancements
-- Created: 2026-04-12
-- Tables: 31 (Module 2: 12, Module 6: 13, Module 10: 6)

-- ============================================================================
-- MODULE 2: MEAL SYSTEM & PLANNING - Enhancement Tables (12 tables)
-- ============================================================================

-- Meal Templates - Pre-made meal plans
CREATE TABLE IF NOT EXISTS meal_templates (
    id SERIAL PRIMARY KEY,
    template_name VARCHAR(120) NOT NULL,
    meal_type VARCHAR(30),         -- breakfast / lunch / dinner / snack
    description TEXT,
    target_calories INTEGER,
    target_protein_g INTEGER,
    target_carbs_g INTEGER,
    target_fat_g INTEGER,
    diet_type VARCHAR(40),         -- balanced / low_carb / high_protein / vegan / keto
    health_focus TEXT,             -- JSON: ["diabetes", "ckd", "hypertension"]
    created_by_user_id INTEGER,
    is_public BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_meal_template_type ON meal_templates(meal_type);
CREATE INDEX idx_meal_template_diet ON meal_templates(diet_type);
CREATE INDEX idx_meal_template_public ON meal_templates(is_public);

-- Meal Tags - Categorize meals (e.g., "quick", "budget-friendly")
CREATE TABLE IF NOT EXISTS meal_tags (
    id SERIAL PRIMARY KEY,
    tag_name VARCHAR(60) NOT NULL UNIQUE,
    tag_category VARCHAR(40),      -- prep_time / cost / difficulty / diet / health
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_meal_tag_category ON meal_tags(tag_category);

-- Recipe Tags - Categorize recipes
CREATE TABLE IF NOT EXISTS recipe_tags (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES meal_tags(id) ON DELETE CASCADE,
    UNIQUE(recipe_id, tag_id)
);

CREATE INDEX idx_recipe_tag_recipe ON recipe_tags(recipe_id);
CREATE INDEX idx_recipe_tag_tag ON recipe_tags(tag_id);

-- Cooking Methods - How food is prepared
CREATE TABLE IF NOT EXISTS cooking_methods (
    id SERIAL PRIMARY KEY,
    method_name VARCHAR(60) NOT NULL UNIQUE, -- boiling / frying / steaming / roasting / grilling
    method_type VARCHAR(40),       -- moist_heat / dry_heat / combination
    description TEXT,
    typical_temp_range VARCHAR(40),
    nutrient_impact TEXT,          -- How method affects nutrients
    health_rating VARCHAR(20),     -- healthiest / healthy / moderate / unhealthy
    equipment_needed TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_cooking_method_type ON cooking_methods(method_type);
CREATE INDEX idx_cooking_method_rating ON cooking_methods(health_rating);

-- Meal Prep Steps - Step-by-step cooking instructions
CREATE TABLE IF NOT EXISTS meal_prep_steps (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL,
    step_number INTEGER NOT NULL,
    instruction TEXT NOT NULL,
    duration_minutes INTEGER,
    cooking_method_id INTEGER,
    temperature VARCHAR(40),
    tips TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    FOREIGN KEY (cooking_method_id) REFERENCES cooking_methods(id) ON DELETE SET NULL,
    UNIQUE(recipe_id, step_number)
);

CREATE INDEX idx_prep_steps_recipe ON meal_prep_steps(recipe_id);

-- Meal Photos - User-uploaded meal images
CREATE TABLE IF NOT EXISTS meal_photos (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    meal_id INTEGER,
    recipe_id INTEGER,
    photo_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    caption TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    taken_at TIMESTAMP,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
);

CREATE INDEX idx_meal_photo_user ON meal_photos(user_id);
CREATE INDEX idx_meal_photo_meal ON meal_photos(meal_id);
CREATE INDEX idx_meal_photo_recipe ON meal_photos(recipe_id);

-- Recipe Reviews - User ratings and feedback
CREATE TABLE IF NOT EXISTS recipe_reviews (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    rating INTEGER NOT NULL,       -- 1-5 stars
    review_text TEXT,
    difficulty_rating INTEGER,     -- 1-5 (easy to hard)
    taste_rating INTEGER,          -- 1-5
    would_make_again BOOLEAN,
    modifications_made TEXT,       -- What user changed
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(recipe_id, user_id)
);

CREATE INDEX idx_recipe_review_recipe ON recipe_reviews(recipe_id);
CREATE INDEX idx_recipe_review_user ON recipe_reviews(user_id);
CREATE INDEX idx_recipe_review_rating ON recipe_reviews(rating);

-- Meal Sharing - Share meals with friends/community
CREATE TABLE IF NOT EXISTS meal_sharing (
    id SERIAL PRIMARY KEY,
    meal_id INTEGER NOT NULL,
    shared_by_user_id INTEGER NOT NULL,
    shared_with_user_id INTEGER,   -- NULL for public share
    share_type VARCHAR(20),        -- private / friends / public
    message TEXT,
    view_count INTEGER DEFAULT 0,
    shared_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
    FOREIGN KEY (shared_by_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (shared_with_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_meal_share_meal ON meal_sharing(meal_id);
CREATE INDEX idx_meal_share_by ON meal_sharing(shared_by_user_id);
CREATE INDEX idx_meal_share_with ON meal_sharing(shared_with_user_id);
CREATE INDEX idx_meal_share_type ON meal_sharing(share_type);

-- Ingredient Substitutions - Alternative ingredients
CREATE TABLE IF NOT EXISTS ingredient_substitutions (
    id SERIAL PRIMARY KEY,
    original_food_id INTEGER NOT NULL,
    substitute_food_id INTEGER NOT NULL,
    substitution_ratio DOUBLE PRECISION DEFAULT 1.0, -- 1.0 = 1:1 replacement
    reason VARCHAR(40),            -- allergy / availability / preference / health
    nutrition_impact TEXT,         -- How nutrients change
    taste_impact TEXT,             -- How flavor changes
    recommended BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (original_food_id) REFERENCES foods(id) ON DELETE CASCADE,
    FOREIGN KEY (substitute_food_id) REFERENCES foods(id) ON DELETE CASCADE,
    UNIQUE(original_food_id, substitute_food_id)
);

CREATE INDEX idx_substitution_original ON ingredient_substitutions(original_food_id);
CREATE INDEX idx_substitution_substitute ON ingredient_substitutions(substitute_food_id);

-- Meal Planner Calendar - Weekly meal planning
CREATE TABLE IF NOT EXISTS meal_planner_calendar (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    plan_date DATE NOT NULL,
    meal_type VARCHAR(30) NOT NULL, -- breakfast / lunch / dinner / snack
    recipe_id INTEGER,
    meal_template_id INTEGER,
    planned_calories INTEGER,
    preparation_status VARCHAR(20), -- planned / prep_done / cooked / eaten / skipped
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE SET NULL,
    FOREIGN KEY (meal_template_id) REFERENCES meal_templates(id) ON DELETE SET NULL,
    UNIQUE(user_id, plan_date, meal_type)
);

CREATE INDEX idx_meal_planner_user ON meal_planner_calendar(user_id);
CREATE INDEX idx_meal_planner_date ON meal_planner_calendar(plan_date);

-- Shopping Lists - Grocery lists from meal plans
CREATE TABLE IF NOT EXISTS shopping_lists (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    list_name VARCHAR(120),
    start_date DATE,
    end_date DATE,
    status VARCHAR(20),            -- draft / active / completed / archived
    total_estimated_cost_ugx DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_shopping_list_user ON shopping_lists(user_id);
CREATE INDEX idx_shopping_list_status ON shopping_lists(status);

-- Pantry Inventory - Track what user has at home
CREATE TABLE IF NOT EXISTS pantry_inventory (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    food_id INTEGER NOT NULL,
    quantity_grams DOUBLE PRECISION,
    quantity_units VARCHAR(40),    -- pieces / cans / boxes
    location VARCHAR(60),          -- fridge / freezer / pantry / cupboard
    purchase_date DATE,
    expiry_date DATE,
    status VARCHAR(20),            -- available / running_low / expired / used_up
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
);

CREATE INDEX idx_pantry_user ON pantry_inventory(user_id);
CREATE INDEX idx_pantry_food ON pantry_inventory(food_id);
CREATE INDEX idx_pantry_status ON pantry_inventory(status);
CREATE INDEX idx_pantry_expiry ON pantry_inventory(expiry_date);

-- ============================================================================
-- MODULE 6: MEDICAL CONSULTING - Enhancement Tables (13 tables)
-- ============================================================================

-- Consultation Attachments - Files shared during consultation
CREATE TABLE IF NOT EXISTS consultation_attachments (
    id SERIAL PRIMARY KEY,
    consultation_id INTEGER NOT NULL,
    uploaded_by VARCHAR(20),       -- patient / doctor
    file_type VARCHAR(40),         -- image / pdf / lab_result / prescription / other
    file_url VARCHAR(500) NOT NULL,
    file_name VARCHAR(200),
    file_size_kb INTEGER,
    description TEXT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE
);

CREATE INDEX idx_consult_attach_consult ON consultation_attachments(consultation_id);
CREATE INDEX idx_consult_attach_type ON consultation_attachments(file_type);

-- Consultation Ratings - Patient feedback on consultations
CREATE TABLE IF NOT EXISTS consultation_ratings (
    id SERIAL PRIMARY KEY,
    consultation_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    staff_id INTEGER NOT NULL,
    overall_rating INTEGER NOT NULL, -- 1-5 stars
    professionalism_rating INTEGER,
    communication_rating INTEGER,
    timeliness_rating INTEGER,
    helpfulness_rating INTEGER,
    feedback_text TEXT,
    would_recommend BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES medical_staff(id) ON DELETE CASCADE,
    UNIQUE(consultation_id, user_id)
);

CREATE INDEX idx_consult_rating_consult ON consultation_ratings(consultation_id);
CREATE INDEX idx_consult_rating_staff ON consultation_ratings(staff_id);
CREATE INDEX idx_consult_rating_overall ON consultation_ratings(overall_rating);

-- Doctor Availability - Schedule when doctors are available
CREATE TABLE IF NOT EXISTS doctor_availability (
    id SERIAL PRIMARY KEY,
    staff_id INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL, -- 0=Sunday, 6=Saturday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    consultation_type VARCHAR(40), -- in_person / video / phone / any
    max_patients_per_hour INTEGER DEFAULT 2,
    is_active BOOLEAN DEFAULT TRUE,
    effective_from DATE,
    effective_until DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES medical_staff(id) ON DELETE CASCADE
);

CREATE INDEX idx_doctor_avail_staff ON doctor_availability(staff_id);
CREATE INDEX idx_doctor_avail_day ON doctor_availability(day_of_week);
CREATE INDEX idx_doctor_avail_active ON doctor_availability(is_active);

-- Consultation Queue - Waiting list management
CREATE TABLE IF NOT EXISTS consultation_queue (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    staff_id INTEGER,              -- NULL for any available
    priority VARCHAR(20),          -- routine / urgent / emergency
    check_in_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estimated_wait_minutes INTEGER,
    queue_position INTEGER,
    status VARCHAR(20),            -- waiting / in_progress / completed / cancelled
    called_at TIMESTAMP,
    completed_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES medical_services(id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES medical_staff(id) ON DELETE SET NULL
);

CREATE INDEX idx_queue_user ON consultation_queue(user_id);
CREATE INDEX idx_queue_status ON consultation_queue(status);
CREATE INDEX idx_queue_priority ON consultation_queue(priority);

-- Telemedicine Sessions - Video/call session tracking
CREATE TABLE IF NOT EXISTS telemedicine_sessions (
    id SERIAL PRIMARY KEY,
    consultation_id INTEGER NOT NULL,
    session_type VARCHAR(20),      -- video / audio / chat
    session_url VARCHAR(500),      -- Video call link
    session_token VARCHAR(200),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    duration_minutes INTEGER,
    connection_quality VARCHAR(20), -- excellent / good / fair / poor
    technical_issues TEXT,
    recording_url VARCHAR(500),    -- If recorded (with consent)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE
);

CREATE INDEX idx_telemedicine_consult ON telemedicine_sessions(consultation_id);
CREATE INDEX idx_telemedicine_started ON telemedicine_sessions(started_at);

-- Consultation Payments - Payment tracking per consultation
CREATE TABLE IF NOT EXISTS consultation_payments (
    id SERIAL PRIMARY KEY,
    consultation_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    amount_ugx DOUBLE PRECISION NOT NULL,
    payment_method VARCHAR(40),    -- mobile_money / cash / insurance / afya_points / barter / labor
    payment_status VARCHAR(20),    -- pending / completed / failed / refunded
    transaction_ref VARCHAR(120),
    paid_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_consult_payment_consult ON consultation_payments(consultation_id);
CREATE INDEX idx_consult_payment_user ON consultation_payments(user_id);
CREATE INDEX idx_consult_payment_status ON consultation_payments(payment_status);

-- Specialist Registry - Extended specialist profiles
CREATE TABLE IF NOT EXISTS specialist_registry (
    id SERIAL PRIMARY KEY,
    staff_id INTEGER NOT NULL,
    specialty VARCHAR(100) NOT NULL, -- Cardiologist / Nephrologist / Endocrinologist
    sub_specialty VARCHAR(100),
    years_of_experience INTEGER,
    medical_school VARCHAR(200),
    residency VARCHAR(200),
    board_certified BOOLEAN DEFAULT FALSE,
    certifications TEXT,           -- JSON array
    languages_spoken TEXT,         -- JSON array
    areas_of_interest TEXT,
    publications_count INTEGER DEFAULT 0,
    accepts_new_patients BOOLEAN DEFAULT TRUE,
    consultation_fee_ugx DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES medical_staff(id) ON DELETE CASCADE,
    UNIQUE(staff_id)
);

CREATE INDEX idx_specialist_staff ON specialist_registry(staff_id);
CREATE INDEX idx_specialist_specialty ON specialist_registry(specialty);

-- Medical Conditions - Standardized condition definitions
CREATE TABLE IF NOT EXISTS medical_conditions (
    id SERIAL PRIMARY KEY,
    condition_name VARCHAR(120) NOT NULL UNIQUE,
    icd_10_code VARCHAR(20),       -- International Classification of Diseases
    category VARCHAR(60),          -- cardiovascular / metabolic / renal / respiratory
    description TEXT,
    symptoms TEXT,
    risk_factors TEXT,
    typical_treatments TEXT,
    prognosis TEXT,
    is_chronic BOOLEAN DEFAULT FALSE,
    requires_specialist BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_medical_condition_category ON medical_conditions(category);
CREATE INDEX idx_medical_condition_chronic ON medical_conditions(is_chronic);

-- Treatment Plans - Structured treatment protocols
CREATE TABLE IF NOT EXISTS treatment_plans (
    id SERIAL PRIMARY KEY,
    consultation_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    condition_id INTEGER,
    plan_title VARCHAR(200),
    objectives TEXT,
    medications TEXT,              -- JSON array of prescribed medications
    lifestyle_changes TEXT,
    dietary_recommendations TEXT,
    exercise_recommendations TEXT,
    follow_up_frequency VARCHAR(60),
    success_metrics TEXT,
    plan_start_date DATE,
    plan_end_date DATE,
    status VARCHAR(20),            -- active / completed / discontinued / modified
    created_by_staff_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (condition_id) REFERENCES medical_conditions(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by_staff_id) REFERENCES medical_staff(id) ON DELETE SET NULL
);

CREATE INDEX idx_treatment_plan_consult ON treatment_plans(consultation_id);
CREATE INDEX idx_treatment_plan_user ON treatment_plans(user_id);
CREATE INDEX idx_treatment_plan_status ON treatment_plans(status);

-- Follow Up Reminders - Automated patient follow-up system
CREATE TABLE IF NOT EXISTS follow_up_reminders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    consultation_id INTEGER,
    treatment_plan_id INTEGER,
    reminder_type VARCHAR(40),     -- follow_up_visit / lab_test / medication_refill / lifestyle_check
    reminder_date DATE NOT NULL,
    reminder_time TIME,
    message TEXT,
    priority VARCHAR(20),          -- routine / important / urgent
    status VARCHAR(20),            -- pending / sent / acknowledged / completed / cancelled
    sent_at TIMESTAMP,
    acknowledged_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE SET NULL,
    FOREIGN KEY (treatment_plan_id) REFERENCES treatment_plans(id) ON DELETE SET NULL
);

CREATE INDEX idx_followup_user ON follow_up_reminders(user_id);
CREATE INDEX idx_followup_date ON follow_up_reminders(reminder_date);
CREATE INDEX idx_followup_status ON follow_up_reminders(status);

-- Consultation Transcripts - Text records of consultations
CREATE TABLE IF NOT EXISTS consultation_transcripts (
    id SERIAL PRIMARY KEY,
    consultation_id INTEGER NOT NULL,
    transcript_text TEXT,
    audio_url VARCHAR(500),        -- If audio recorded
    transcription_method VARCHAR(40), -- manual / automated
    transcribed_at TIMESTAMP,
    reviewed_by_staff BOOLEAN DEFAULT FALSE,
    is_confidential BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE,
    UNIQUE(consultation_id)
);

CREATE INDEX idx_transcript_consult ON consultation_transcripts(consultation_id);

-- Second Opinion Requests - Request additional medical opinions
CREATE TABLE IF NOT EXISTS second_opinion_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    original_consultation_id INTEGER,
    original_diagnosis TEXT,
    reason_for_request TEXT,
    requested_specialty VARCHAR(100),
    assigned_staff_id INTEGER,
    status VARCHAR(20),            -- pending / assigned / in_progress / completed / declined
    priority VARCHAR(20),
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    second_opinion_notes TEXT,
    agreement_with_original VARCHAR(20), -- agree / partial / disagree
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (original_consultation_id) REFERENCES consultations(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_staff_id) REFERENCES medical_staff(id) ON DELETE SET NULL
);

CREATE INDEX idx_second_opinion_user ON second_opinion_requests(user_id);
CREATE INDEX idx_second_opinion_status ON second_opinion_requests(status);

-- Emergency Contacts - Patient emergency contact information
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    contact_name VARCHAR(120) NOT NULL,
    relationship VARCHAR(60),      -- spouse / parent / sibling / friend
    phone_primary VARCHAR(20) NOT NULL,
    phone_secondary VARCHAR(20),
    email VARCHAR(120),
    address TEXT,
    is_primary BOOLEAN DEFAULT FALSE,
    notify_in_emergency BOOLEAN DEFAULT TRUE,
    can_make_medical_decisions BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_emergency_contact_user ON emergency_contacts(user_id);
CREATE INDEX idx_emergency_contact_primary ON emergency_contacts(is_primary);

-- ============================================================================
-- MODULE 10: PREVENTIVE MEDICINE - Enhancement Tables (6 tables)
-- ============================================================================

-- User Health Goals - Personal health objectives
CREATE TABLE IF NOT EXISTS user_health_goals (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    goal_type VARCHAR(40),         -- weight_loss / bp_control / glucose_control / fitness / nutrition
    goal_description TEXT NOT NULL,
    target_value DOUBLE PRECISION,
    target_unit VARCHAR(20),
    current_value DOUBLE PRECISION,
    start_date DATE NOT NULL,
    target_date DATE,
    status VARCHAR(20),            -- active / completed / abandoned / on_hold
    progress_pct DOUBLE PRECISION,             -- 0.0-100.0
    motivation_level INTEGER,      -- 1-10
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_health_goal_user ON user_health_goals(user_id);
CREATE INDEX idx_health_goal_type ON user_health_goals(goal_type);
CREATE INDEX idx_health_goal_status ON user_health_goals(status);

-- User Conditions - Patient's diagnosed conditions
CREATE TABLE IF NOT EXISTS user_conditions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    condition_id INTEGER NOT NULL,
    diagnosed_date DATE,
    diagnosed_by_staff_id INTEGER,
    severity VARCHAR(20),          -- mild / moderate / severe
    status VARCHAR(20),            -- active / managed / resolved / recurring
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (condition_id) REFERENCES medical_conditions(id) ON DELETE CASCADE,
    FOREIGN KEY (diagnosed_by_staff_id) REFERENCES medical_staff(id) ON DELETE SET NULL
);

CREATE INDEX idx_user_condition_user ON user_conditions(user_id);
CREATE INDEX idx_user_condition_condition ON user_conditions(condition_id);
CREATE INDEX idx_user_condition_status ON user_conditions(status);

-- Risk Prediction Logs - AI-generated health risk assessments
CREATE TABLE IF NOT EXISTS risk_prediction_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    condition_name VARCHAR(120),
    risk_score DOUBLE PRECISION NOT NULL,      -- 0.0-1.0 probability
    risk_category VARCHAR(20),     -- low / medium / high / very_high
    risk_factors TEXT,             -- JSON array of contributing factors
    protective_factors TEXT,       -- JSON array of protective factors
    recommendations TEXT,
    model_version VARCHAR(40),
    confidence_score DOUBLE PRECISION,
    predicted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_risk_pred_user ON risk_prediction_logs(user_id);
CREATE INDEX idx_risk_pred_date ON risk_prediction_logs(predicted_at);
CREATE INDEX idx_risk_pred_category ON risk_prediction_logs(risk_category);

-- Health Assessments - Periodic comprehensive health evaluations
CREATE TABLE IF NOT EXISTS health_assessments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    assessment_date DATE NOT NULL,
    assessment_type VARCHAR(40),   -- annual / quarterly / condition_specific
    overall_health_score DOUBLE PRECISION,     -- 0-100
    cardiovascular_score DOUBLE PRECISION,
    metabolic_score DOUBLE PRECISION,
    mental_health_score DOUBLE PRECISION,
    nutrition_score DOUBLE PRECISION,
    physical_activity_score DOUBLE PRECISION,
    sleep_score DOUBLE PRECISION,
    key_findings TEXT,
    action_items TEXT,
    assessed_by_staff_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (assessed_by_staff_id) REFERENCES medical_staff(id) ON DELETE SET NULL
);

CREATE INDEX idx_health_assess_user ON health_assessments(user_id);
CREATE INDEX idx_health_assess_date ON health_assessments(assessment_date);

-- Screening Reminders - Preventive screening notifications
CREATE TABLE IF NOT EXISTS screening_reminders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    screening_type VARCHAR(60),    -- mammogram / colonoscopy / blood_pressure / diabetes / cholesterol
    due_date DATE NOT NULL,
    last_completed_date DATE,
    frequency_months INTEGER,      -- How often needed
    priority VARCHAR(20),          -- routine / recommended / overdue
    age_appropriate BOOLEAN DEFAULT TRUE,
    gender_specific BOOLEAN DEFAULT FALSE,
    condition_specific TEXT,       -- If triggered by existing condition
    reminder_sent BOOLEAN DEFAULT FALSE,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_screening_user ON screening_reminders(user_id);
CREATE INDEX idx_screening_due ON screening_reminders(due_date);
CREATE INDEX idx_screening_priority ON screening_reminders(priority);

-- User Wellness Score - Composite wellness metric (Vuralis data source)
CREATE TABLE IF NOT EXISTS user_wellness_score (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    score_date DATE NOT NULL,
    overall_score DOUBLE PRECISION NOT NULL,   -- 0.0-1.0 or 0-100
    nutrition_score DOUBLE PRECISION,
    physical_activity_score DOUBLE PRECISION,
    sleep_score DOUBLE PRECISION,
    mental_health_score DOUBLE PRECISION,
    social_connection_score DOUBLE PRECISION,
    medical_adherence_score DOUBLE PRECISION,
    preventive_care_score DOUBLE PRECISION,
    trend VARCHAR(20),             -- improving / stable / declining
    percentile INTEGER,            -- User's rank vs. similar demographics
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, score_date)
);

CREATE INDEX idx_wellness_score_user ON user_wellness_score(user_id);
CREATE INDEX idx_wellness_score_date ON user_wellness_score(score_date);

-- ============================================================================
-- MIGRATION COMPLETE: 31 MEDIUM PRIORITY TABLES
-- ============================================================================
