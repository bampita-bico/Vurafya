-- Migration 043: Missing Tables - FINAL MODULES
-- Social networks, commerce, Afya Points, research, and infrastructure
-- Created: 2026-04-12
-- Tables: 33+ (Modules 13, 14, 15, 16, 17)

-- ============================================================================
-- MODULE 13: SOCIAL HEALTH NETWORKS - Enhancement Tables (13 tables)
-- ============================================================================

-- Social Groups - Health-focused communities
CREATE TABLE IF NOT EXISTS social_groups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    group_name VARCHAR(120) NOT NULL,
    group_type VARCHAR(40),        -- support / challenge / condition_specific / regional
    description TEXT,
    health_focus TEXT,             -- JSON: ["diabetes", "weight_loss", "ckd"]
    privacy_level VARCHAR(20),     -- public / private / invite_only
    created_by_user_id INTEGER NOT NULL,
    member_count INTEGER DEFAULT 0,
    max_members INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_social_group_type ON social_groups(group_type);
CREATE INDEX idx_social_group_privacy ON social_groups(privacy_level);
CREATE INDEX idx_social_group_active ON social_groups(is_active);

-- Group Memberships - User membership in groups
CREATE TABLE IF NOT EXISTS group_memberships (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    group_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    role VARCHAR(20),              -- admin / moderator / member
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    muted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (group_id) REFERENCES social_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(group_id, user_id)
);

CREATE INDEX idx_group_member_group ON group_memberships(group_id);
CREATE INDEX idx_group_member_user ON group_memberships(user_id);
CREATE INDEX idx_group_member_role ON group_memberships(role);

-- Social Posts - User posts in groups or public feed
CREATE TABLE IF NOT EXISTS social_posts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    group_id INTEGER,              -- NULL for public posts
    post_type VARCHAR(20),         -- text / photo / achievement / milestone
    content TEXT,
    media_urls TEXT,               -- JSON array
    visibility VARCHAR(20),        -- public / friends / private / group
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    is_flagged BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES social_groups(id) ON DELETE CASCADE
);

CREATE INDEX idx_social_post_user ON social_posts(user_id);
CREATE INDEX idx_social_post_group ON social_posts(group_id);
CREATE INDEX idx_social_post_visibility ON social_posts(visibility);
CREATE INDEX idx_social_post_created ON social_posts(created_at);

-- Post Comments - Comments on social posts
CREATE TABLE IF NOT EXISTS post_comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    post_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    parent_comment_id INTEGER,     -- For nested replies
    comment_text TEXT NOT NULL,
    like_count INTEGER DEFAULT 0,
    is_flagged BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES social_posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_comment_id) REFERENCES post_comments(id) ON DELETE CASCADE
);

CREATE INDEX idx_post_comment_post ON post_comments(post_id);
CREATE INDEX idx_post_comment_user ON post_comments(user_id);
CREATE INDEX idx_post_comment_parent ON post_comments(parent_comment_id);

-- Post Likes - Track who liked what
CREATE TABLE IF NOT EXISTS post_likes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    post_id INTEGER,
    comment_id INTEGER,
    user_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES social_posts(id) ON DELETE CASCADE,
    FOREIGN KEY (comment_id) REFERENCES post_comments(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(post_id, user_id),
    UNIQUE(comment_id, user_id)
);

CREATE INDEX idx_post_like_post ON post_likes(post_id);
CREATE INDEX idx_post_like_comment ON post_likes(comment_id);
CREATE INDEX idx_post_like_user ON post_likes(user_id);

-- User Connections - Friend connections beyond basic friends table
CREATE TABLE IF NOT EXISTS user_connections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    connected_user_id INTEGER NOT NULL,
    connection_type VARCHAR(20),   -- friend / mentor / buddy / family
    connection_strength REAL,      -- 0.0-1.0 based on interactions
    last_interaction_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (connected_user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, connected_user_id)
);

CREATE INDEX idx_user_conn_user ON user_connections(user_id);
CREATE INDEX idx_user_conn_connected ON user_connections(connected_user_id);
CREATE INDEX idx_user_conn_type ON user_connections(connection_type);

-- Health Endorsements - Support and encouragement between users
CREATE TABLE IF NOT EXISTS health_endorsements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_user_id INTEGER NOT NULL,
    to_user_id INTEGER NOT NULL,
    endorsement_type VARCHAR(40),  -- achievement / progress / support / milestone
    message TEXT,
    related_post_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (related_post_id) REFERENCES social_posts(id) ON DELETE SET NULL
);

CREATE INDEX idx_endorsement_from ON health_endorsements(from_user_id);
CREATE INDEX idx_endorsement_to ON health_endorsements(to_user_id);

-- Support Group Meetings - Scheduled virtual or in-person meetings
CREATE TABLE IF NOT EXISTS support_group_meetings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    group_id INTEGER NOT NULL,
    meeting_title VARCHAR(200),
    meeting_type VARCHAR(20),      -- virtual / in_person / hybrid
    meeting_date DATE NOT NULL,
    meeting_time TIME NOT NULL,
    duration_minutes INTEGER,
    location TEXT,
    meeting_url VARCHAR(500),
    agenda TEXT,
    max_attendees INTEGER,
    rsvp_count INTEGER DEFAULT 0,
    status VARCHAR(20),            -- scheduled / in_progress / completed / cancelled
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES social_groups(id) ON DELETE CASCADE
);

CREATE INDEX idx_meeting_group ON support_group_meetings(group_id);
CREATE INDEX idx_meeting_date ON support_group_meetings(meeting_date);
CREATE INDEX idx_meeting_status ON support_group_meetings(status);

-- Group Moderation Logs - Track moderation actions
CREATE TABLE IF NOT EXISTS group_moderation_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    group_id INTEGER NOT NULL,
    moderator_user_id INTEGER NOT NULL,
    action_type VARCHAR(40),       -- warn / mute / ban / delete_post / delete_comment
    target_user_id INTEGER,
    target_post_id INTEGER,
    target_comment_id INTEGER,
    reason TEXT,
    duration_days INTEGER,         -- For temporary actions
    action_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES social_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (moderator_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (target_post_id) REFERENCES social_posts(id) ON DELETE SET NULL,
    FOREIGN KEY (target_comment_id) REFERENCES post_comments(id) ON DELETE SET NULL
);

CREATE INDEX idx_moderation_group ON group_moderation_logs(group_id);
CREATE INDEX idx_moderation_moderator ON group_moderation_logs(moderator_user_id);
CREATE INDEX idx_moderation_target ON group_moderation_logs(target_user_id);

-- Direct Message Threads - Conversation threads
CREATE TABLE IF NOT EXISTS direct_message_threads (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    thread_name VARCHAR(120),
    thread_type VARCHAR(20),       -- one_on_one / group_chat
    created_by_user_id INTEGER NOT NULL,
    last_message_at TIMESTAMP,
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_dm_thread_creator ON direct_message_threads(created_by_user_id);
CREATE INDEX idx_dm_thread_last_message ON direct_message_threads(last_message_at);

-- Direct Messages - Individual messages in threads
CREATE TABLE IF NOT EXISTS direct_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    thread_id INTEGER NOT NULL,
    sender_id INTEGER NOT NULL,
    message_text TEXT,
    media_urls TEXT,               -- JSON array
    read_by TEXT,                  -- JSON array of user IDs who read it
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (thread_id) REFERENCES direct_message_threads(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_dm_thread ON direct_messages(thread_id);
CREATE INDEX idx_dm_sender ON direct_messages(sender_id);
CREATE INDEX idx_dm_sent ON direct_messages(sent_at);

-- Mentor Profiles - Health mentors and coaches
CREATE TABLE IF NOT EXISTS mentor_profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    mentor_type VARCHAR(40),       -- peer / professional / coach / recovered_patient
    specialization TEXT,           -- JSON: ["diabetes", "weight_loss", "ckd"]
    bio TEXT,
    years_experience INTEGER,
    certification VARCHAR(200),
    max_mentees INTEGER,
    current_mentees_count INTEGER DEFAULT 0,
    accepts_new_mentees BOOLEAN DEFAULT TRUE,
    hourly_rate_ugx REAL,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_mentor_user ON mentor_profiles(user_id);
CREATE INDEX idx_mentor_type ON mentor_profiles(mentor_type);
CREATE INDEX idx_mentor_accepts ON mentor_profiles(accepts_new_mentees);

-- Privacy Settings - Granular privacy controls
CREATE TABLE IF NOT EXISTS privacy_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    profile_visibility VARCHAR(20),        -- public / friends / private
    meal_logs_visibility VARCHAR(20),
    biometrics_visibility VARCHAR(20),
    achievements_visibility VARCHAR(20),
    allow_friend_requests BOOLEAN DEFAULT TRUE,
    allow_group_invites BOOLEAN DEFAULT TRUE,
    allow_direct_messages VARCHAR(20),     -- everyone / friends / no_one
    show_online_status BOOLEAN DEFAULT TRUE,
    show_in_leaderboards BOOLEAN DEFAULT TRUE,
    data_sharing_consent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_privacy_user ON privacy_settings(user_id);

-- ============================================================================
-- MODULE 14: COMMERCE & MARKETPLACE - Enhancement Tables (9 tables)
-- ============================================================================

-- Product Catalog - Marketplace products (health supplements, devices, etc.)
CREATE TABLE IF NOT EXISTS product_catalog (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_name VARCHAR(200) NOT NULL,
    product_category_id INTEGER,
    description TEXT,
    brand VARCHAR(100),
    sku VARCHAR(60) UNIQUE,
    base_price_ugx REAL NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    low_stock_threshold INTEGER DEFAULT 10,
    images TEXT,                   -- JSON array
    specifications TEXT,           -- JSON
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_category_id) REFERENCES product_categories(id) ON DELETE SET NULL
);

CREATE INDEX idx_product_category ON product_catalog(product_category_id);
CREATE INDEX idx_product_active ON product_catalog(is_active);
CREATE INDEX idx_product_sku ON product_catalog(sku);

-- Product Categories - Hierarchical product classification
CREATE TABLE IF NOT EXISTS product_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_name VARCHAR(100) NOT NULL,
    parent_id INTEGER,
    description TEXT,
    icon_url VARCHAR(500),
    display_order INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES product_categories(id) ON DELETE SET NULL
);

CREATE INDEX idx_product_cat_parent ON product_categories(parent_id);

-- Vendor Profiles - Third-party sellers on marketplace
CREATE TABLE IF NOT EXISTS vendor_profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vendor_name VARCHAR(200) NOT NULL,
    business_registration VARCHAR(100),
    contact_person VARCHAR(120),
    email VARCHAR(120),
    phone VARCHAR(20),
    address TEXT,
    logo_url VARCHAR(500),
    rating REAL,                   -- Average rating
    total_sales INTEGER DEFAULT 0,
    commission_pct REAL DEFAULT 15.0,
    payment_terms VARCHAR(60),
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_vendor_active ON vendor_profiles(is_active);
CREATE INDEX idx_vendor_verified ON vendor_profiles(is_verified);

-- Order Management - Product orders (distinct from pharmacy orders)
CREATE TABLE IF NOT EXISTS order_management (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    order_number VARCHAR(60) UNIQUE NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount_ugx REAL NOT NULL,
    discount_amount_ugx REAL DEFAULT 0,
    delivery_fee_ugx REAL DEFAULT 0,
    afya_points_used INTEGER DEFAULT 0,
    payment_method VARCHAR(40),
    payment_status VARCHAR(20),    -- pending / paid / failed / refunded
    order_status VARCHAR(20),      -- pending / processing / shipped / delivered / cancelled
    delivery_address TEXT,
    delivery_instructions TEXT,
    estimated_delivery_date DATE,
    actual_delivery_date DATE,
    tracking_number VARCHAR(100),
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_order_user ON order_management(user_id);
CREATE INDEX idx_order_status ON order_management(order_status);
CREATE INDEX idx_order_date ON order_management(order_date);

-- Order Line Items - Products in each order
CREATE TABLE IF NOT EXISTS order_line_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    vendor_id INTEGER,
    quantity INTEGER NOT NULL,
    unit_price_ugx REAL NOT NULL,
    discount_pct REAL DEFAULT 0,
    line_total_ugx REAL NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES order_management(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product_catalog(id) ON DELETE RESTRICT,
    FOREIGN KEY (vendor_id) REFERENCES vendor_profiles(id) ON DELETE SET NULL
);

CREATE INDEX idx_order_line_order ON order_line_items(order_id);
CREATE INDEX idx_order_line_product ON order_line_items(product_id);

-- Discount Campaigns - Promotional offers
CREATE TABLE IF NOT EXISTS discount_campaigns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    campaign_name VARCHAR(120) NOT NULL,
    discount_type VARCHAR(20),     -- percentage / fixed_amount / buy_x_get_y
    discount_value REAL NOT NULL,
    min_purchase_ugx REAL,
    max_discount_ugx REAL,
    applicable_to TEXT,            -- JSON: product_ids or category_ids
    promo_code VARCHAR(40) UNIQUE,
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_discount_promo_code ON discount_campaigns(promo_code);
CREATE INDEX idx_discount_active ON discount_campaigns(is_active);
CREATE INDEX idx_discount_dates ON discount_campaigns(start_date, end_date);

-- Payment Gateways Log - Already exists as payment_gateways_log in Module 14 from PDFs
CREATE TABLE IF NOT EXISTS payment_gateways_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    order_id INTEGER,
    gateway_name VARCHAR(40),      -- mobile_money / stripe / flutterwave
    transaction_ref VARCHAR(120) UNIQUE,
    amount_ugx REAL NOT NULL,
    currency VARCHAR(10),
    status VARCHAR(20),            -- pending / success / failed / refunded
    error_message TEXT,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (order_id) REFERENCES order_management(id) ON DELETE SET NULL
);

CREATE INDEX idx_payment_gateway_user ON payment_gateways_log(user_id);
CREATE INDEX idx_payment_gateway_order ON payment_gateways_log(order_id);
CREATE INDEX idx_payment_gateway_status ON payment_gateways_log(status);

-- Shipping Logistics - Delivery tracking
CREATE TABLE IF NOT EXISTS shipping_logistics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    carrier_name VARCHAR(100),
    tracking_number VARCHAR(100),
    shipped_from TEXT,
    shipped_to TEXT,
    shipped_at TIMESTAMP,
    estimated_delivery TIMESTAMP,
    delivered_at TIMESTAMP,
    delivery_status VARCHAR(20),   -- pending / in_transit / out_for_delivery / delivered / failed
    delivery_attempts INTEGER DEFAULT 0,
    signature_required BOOLEAN DEFAULT FALSE,
    delivery_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES order_management(id) ON DELETE CASCADE,
    UNIQUE(order_id)
);

CREATE INDEX idx_shipping_order ON shipping_logistics(order_id);
CREATE INDEX idx_shipping_status ON shipping_logistics(delivery_status);

-- Subscription Plans - Premium features and subscriptions
CREATE TABLE IF NOT EXISTS subscription_plans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    plan_name VARCHAR(80) NOT NULL UNIQUE,
    description TEXT,
    price_monthly_ugx REAL,
    price_annual_ugx REAL,
    features TEXT,                 -- JSON array
    max_consultations INTEGER,
    ai_features_enabled BOOLEAN DEFAULT FALSE,
    lab_discounts_pct REAL DEFAULT 0,
    pharmacy_discounts_pct REAL DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_subscription_active ON subscription_plans(is_active);

-- Wallet Transactions - Afya Points wallet (might overlap with Module 15)
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    transaction_type VARCHAR(30),  -- earn / spend / expire / bonus / correction
    points_amount INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    source_type VARCHAR(40),       -- meal_log / quest / facility_action / purchase / referral
    source_id INTEGER,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_wallet_user ON wallet_transactions(user_id);
CREATE INDEX idx_wallet_type ON wallet_transactions(transaction_type);
CREATE INDEX idx_wallet_date ON wallet_transactions(created_at);

-- ============================================================================
-- MODULE 15: AFYA POINTS ECONOMY - Missing Tables (2 tables)
-- ============================================================================

-- Points Earning Rules - How users earn Afya Points
CREATE TABLE IF NOT EXISTS points_earning_rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_type VARCHAR(60) NOT NULL UNIQUE, -- meal_log / lab_test_verified / consultation / quest_complete / streak_bonus
    base_points INTEGER NOT NULL,
    requires_verification BOOLEAN DEFAULT FALSE,
    multiplier_conditions TEXT,    -- JSON: e.g., CKD patient gets 2x
    max_per_day INTEGER,           -- Daily cap, nullable
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_points_earning_active ON points_earning_rules(is_active);

-- Point Minting Audit - Security log for points issued
CREATE TABLE IF NOT EXISTS point_minting_audit (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    points_minted INTEGER NOT NULL,
    trigger_action VARCHAR(60),
    trigger_reference_id INTEGER,
    facility_verified BOOLEAN DEFAULT FALSE,
    facility_id INTEGER,
    verification_token VARCHAR(80),
    minted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE SET NULL
);

CREATE INDEX idx_point_mint_user ON point_minting_audit(user_id);
CREATE INDEX idx_point_mint_date ON point_minting_audit(minted_at);

-- ============================================================================
-- MODULE 16: RESEARCH & DATA - Missing Tables (5 tables)
-- ============================================================================

-- Research Studies - Clinical research protocols
CREATE TABLE IF NOT EXISTS research_studies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    study_title TEXT NOT NULL,
    study_type VARCHAR(40),        -- observational / rct / cohort / cross_sectional
    condition_focus VARCHAR(60),
    principal_investigator INTEGER,
    institution TEXT,
    ethics_approval_ref VARCHAR(80),
    status VARCHAR(20),            -- recruiting / active / completed / paused
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (principal_investigator) REFERENCES medical_staff(id) ON DELETE SET NULL
);

CREATE INDEX idx_research_status ON research_studies(status);
CREATE INDEX idx_research_condition ON research_studies(condition_focus);

-- Study Participants - Users enrolled in studies
CREATE TABLE IF NOT EXISTS study_participants (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    study_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    cohort_label VARCHAR(40),      -- control / intervention_a / intervention_b
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    withdrawn_at TIMESTAMP,
    UNIQUE(study_id, user_id),
    FOREIGN KEY (study_id) REFERENCES research_studies(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_study_participant_study ON study_participants(study_id);
CREATE INDEX idx_study_participant_user ON study_participants(user_id);

-- Informed Consent Records - Digital consent tracking
CREATE TABLE IF NOT EXISTS informed_consent_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    study_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    consent_version VARCHAR(20),
    consented_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    signature_ref TEXT,            -- Cloud URL or signature data
    UNIQUE(study_id, user_id),
    FOREIGN KEY (study_id) REFERENCES research_studies(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_consent_study ON informed_consent_records(study_id);
CREATE INDEX idx_consent_user ON informed_consent_records(user_id);

-- Longitudinal Outcomes - Health outcomes over time
CREATE TABLE IF NOT EXISTS longitudinal_outcomes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    study_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    outcome_metric VARCHAR(60),    -- HbA1c_change / weight_loss_kg / eGFR_delta / bp_reduction
    baseline_value REAL,
    current_value REAL,
    pct_change REAL,
    measured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (study_id) REFERENCES research_studies(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_longitudinal_study ON longitudinal_outcomes(study_id);
CREATE INDEX idx_longitudinal_user ON longitudinal_outcomes(user_id);

-- Adverse Event Monitoring - Safety tracking
CREATE TABLE IF NOT EXISTS adverse_event_monitoring (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    study_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    event_type VARCHAR(80),
    severity VARCHAR(20),          -- mild / moderate / severe / life_threatening
    description TEXT,
    action_taken TEXT,
    reported_to_ethics BOOLEAN DEFAULT FALSE,
    reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (study_id) REFERENCES research_studies(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_adverse_event_study ON adverse_event_monitoring(study_id);
CREATE INDEX idx_adverse_event_severity ON adverse_event_monitoring(severity);

-- ============================================================================
-- MODULE 17: INFRASTRUCTURE & SECURITY - Missing Tables (7 tables)
-- ============================================================================

-- Audit Trail Sensitive - High-security audit for PII and medical data
CREATE TABLE IF NOT EXISTS audit_trail_sensitive (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    accessor_user_id INTEGER NOT NULL,
    subject_user_id INTEGER NOT NULL,
    data_category VARCHAR(40),     -- lab_results / prescriptions / diagnoses / genetic_data
    action VARCHAR(30),            -- view / export / modify / delete
    table_name VARCHAR(60),
    record_id INTEGER,
    justification TEXT,            -- Why this access occurred
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (accessor_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_audit_sensitive_accessor ON audit_trail_sensitive(accessor_user_id);
CREATE INDEX idx_audit_sensitive_subject ON audit_trail_sensitive(subject_user_id);
CREATE INDEX idx_audit_sensitive_date ON audit_trail_sensitive(created_at);

-- User Access Controls - RBAC permissions
CREATE TABLE IF NOT EXISTS user_access_controls (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    role_name VARCHAR(40),         -- patient / doctor / pharmacist / admin / researcher
    permissions TEXT,              -- JSON: allowed actions
    granted_by INTEGER,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (granted_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE(user_id, role_name)
);

CREATE INDEX idx_access_control_user ON user_access_controls(user_id);
CREATE INDEX idx_access_control_role ON user_access_controls(role_name);

-- Data Export Requests - GDPR right to data portability
CREATE TABLE IF NOT EXISTS data_export_requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    request_type VARCHAR(20),      -- export / deletion
    status VARCHAR(20),            -- pending / processing / completed / failed
    export_file_ref TEXT,          -- Cloud URL
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    handled_by VARCHAR(60),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_data_export_user ON data_export_requests(user_id);
CREATE INDEX idx_data_export_status ON data_export_requests(status);

-- Legal Terms Versions - Track ToS and Privacy Policy versions
CREATE TABLE IF NOT EXISTS legal_terms_versions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    version VARCHAR(20) UNIQUE NOT NULL,
    terms_text_ref TEXT,           -- URL or full text
    summary TEXT,
    effective_from DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_legal_terms_version ON legal_terms_versions(version);
CREATE INDEX idx_legal_terms_effective ON legal_terms_versions(effective_from);

-- User Terms Agreements - Record of user agreement
CREATE TABLE IF NOT EXISTS user_terms_agreements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    terms_id INTEGER NOT NULL,
    agreed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    UNIQUE(user_id, terms_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (terms_id) REFERENCES legal_terms_versions(id) ON DELETE CASCADE
);

CREATE INDEX idx_terms_agreement_user ON user_terms_agreements(user_id);

-- API Usage Logs - Track API endpoint usage
CREATE TABLE IF NOT EXISTS api_usage_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,               -- Nullable for public endpoints
    endpoint VARCHAR(200) NOT NULL,
    method VARCHAR(10),            -- GET / POST / PUT / DELETE
    status_code INTEGER,
    response_ms INTEGER,
    error_ref INTEGER,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_api_usage_user ON api_usage_logs(user_id);
CREATE INDEX idx_api_usage_endpoint ON api_usage_logs(endpoint);
CREATE INDEX idx_api_usage_time ON api_usage_logs(logged_at);

-- Error Exception Logs - Application error tracking
CREATE TABLE IF NOT EXISTS error_exception_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    error_type VARCHAR(60),        -- NullPointerError / DBTimeout / ValidationError
    message TEXT,
    stack_trace TEXT,
    user_id INTEGER,
    endpoint VARCHAR(200),
    severity VARCHAR(20),          -- info / warning / error / critical
    resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_error_severity ON error_exception_logs(severity);
CREATE INDEX idx_error_resolved ON error_exception_logs(resolved);
CREATE INDEX idx_error_time ON error_exception_logs(created_at);

-- DB Migration History - Already exists as db_migration_history
CREATE TABLE IF NOT EXISTS db_migration_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    migration_name VARCHAR(120) UNIQUE NOT NULL,
    direction VARCHAR(10),         -- up / down
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    applied_by VARCHAR(60),
    checksum VARCHAR(64)           -- SHA-256 of migration file
);

CREATE INDEX idx_migration_applied ON db_migration_history(applied_at);

-- Backup Restore Logs - Already exists as backup_restore_logs
CREATE TABLE IF NOT EXISTS backup_restore_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    operation_type VARCHAR(20),    -- backup / restore / verify
    database_name VARCHAR(60),
    file_reference TEXT,
    size_mb REAL,
    status VARCHAR(20),            -- success / failed / in_progress
    initiated_by VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_backup_operation ON backup_restore_logs(operation_type);
CREATE INDEX idx_backup_status ON backup_restore_logs(status);

-- ============================================================================
-- MIGRATION COMPLETE: ALL MISSING TABLES IMPLEMENTED
-- Total: 99 tables across 4 migration files (040-043)
-- ============================================================================
