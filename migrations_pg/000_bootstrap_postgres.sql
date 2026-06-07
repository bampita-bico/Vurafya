-- PostgreSQL Bootstrap
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', 'public', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Create stubs for all tables to satisfy FK references
CREATE TABLE IF NOT EXISTS achievements (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS achievement_tiers (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS active_buffs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS adherence_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS adverse_event_monitoring (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS afya_points_ledger (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS points_expiry_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS ai_inference_results (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS ai_model_registry (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS ai_recommendation_types (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS allergy_flags (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS aml_screening_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS anomaly_detection_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS api_usage_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS approved_content_audit (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS audit_trail_sensitive (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS auto_assignment_rules (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS automated_nudge_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS avatar_appearance_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS avatar_cosmetic_shop (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS avatar_cosmetics (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS avatar_evolution_progress (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS avatar_evolution_stages (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS avatar_health_milestones (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS avatar_stats (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS backup_restore_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS badges (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS barter_escrow_locks (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS barter_exchange_transactions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS barter_goods_catalog (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS barter_item_categories (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS barter_match_notifications (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS barter_match_scores (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS barter_services_catalog (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS barter_transaction_timeline (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS batch_expiry_tracking (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS behavioral_segmentation (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS beverages (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS beverage_submissions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS biomarker_reference_ranges (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS biomarker_trends (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS blacklisted_entities (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS blood_pressure_trends (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS body_composition_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS boss_condition_links (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS boss_encounters (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS boss_loot_table (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS boss_mechanics (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS calculation_warnings (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS category_nutrients (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS challenge_participants (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS challenges (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS character_classes (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS character_progression (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS cocktail_ingredients (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS cocktails (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS condition_game_modifiers (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS condition_nutrient_templates (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS condition_nutrition_rules (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS condition_onboarding_flow (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS condition_thresholds (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS consultation_attachments (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS consultation_bookings (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS consultation_payments (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS consultation_queue (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS consultation_ratings (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS consultation_receipts (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS consultation_transcripts (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS cooking_methods (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS cosmetic_bundles (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS cosmetic_earning_methods (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS cosmetic_wishlist (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS countries_supported (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS country_cost_of_living (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS country_fee_adjustments (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS country_regulatory_requirements (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS country_revenue_summary (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS crafting_condition_bonuses (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS crafting_materials (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS crafting_quality_tiers (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS crafting_recipes (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS creatinine_egfr_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS cross_platform_currency_bridge (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS currency_exchange_rates (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS daily_login_calendar (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS daily_xp_summary (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS data_export_requests (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS data_privacy_consent (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS db_migration_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS device_fingerprints (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS device_sync_state (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS device_tokens (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS diagnostic_alerts (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS direct_messages (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS direct_message_threads (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS discount_campaigns (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS doctor_availability (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS doctor_profiles (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS doctor_game_stat_access (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS doctor_availability_slots (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS doctor_patient_access_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS drink_components (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS drinks (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS drug_active_ingredients (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS drug_categories (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS drug_regulatory_status (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS emergency_contacts (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS error_exception_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS essential_medicine_registry (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS exchange_rate_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS exchange_rate_locks (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS facility_certifications (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS facility_commission_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS facility_locations (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS facility_operating_hours (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS facility_partners (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS facility_payment_acceptance (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS facility_ratings (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS facility_services (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS facility_staff_mapping (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS fasting_blood_sugar_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS fee_structure_config (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS fee_waiver_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS follow_up_reminders (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS food_cooking_method_retention (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS food_nutrients (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS food_safety_hazards (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS foods (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS food_submissions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS fraud_detection_alerts (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS fraud_detection_rules (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS game_character_classes (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS game_quests (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS game_sprites (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS glucose_monitoring (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS glycemic_load_index (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS group_memberships (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS group_moderation_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS guilds (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS guild_members (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS guild_ranks (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS guild_challenges (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS guild_challenge_progress (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS guild_chat_messages (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS guild_level_requirements (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS guild_perks (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS hba1c_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS health_assessments (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS health_endorsements (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS health_rules (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS health_scores (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS heart_rate_variability (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS hybrid_payment_approval_queue (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS hybrid_payment_details (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS imaging_results (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS informed_consent_records (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS ingredient_substitutions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS kitchen_physics (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS labor_booking_requests (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS labor_currency_conversion (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS labor_demand_surge (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS lab_orders (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS labor_earnings_summary (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS labor_hour_ledger (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS labor_no_show_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS labor_services_registry (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS labor_skill_categories (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS labor_verification_queue (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS lab_reference_ranges (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS lab_test_catalog (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS leaderboard_rewards (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS leaderboards (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS legal_terms_versions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS login_streak_milestones (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS longitudinal_outcomes (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS match_score_weights (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_components (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_logging_compliance (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_logging_requirements (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_logging_warnings (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_nutrition_calculations (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_photos (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_planner_calendar (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_portion_adjustments (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_prep_steps (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_sharing (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meals (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_tags (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_templates (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS medical_conditions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS medical_specialties (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS medical_staff (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS medical_sub_specialties (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS medication_schedules (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS medication_side_effects (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS medications (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS medication_storage_reqs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS medication_submission_review_checklist (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS medication_submissions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS menstrual_cycle_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS mentor_profiles (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS metabolic_pathways (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS monthly_revenue_summary (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS monthly_social_good_summary (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS mood_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS nutrient_antagonisms (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS nutrient_contribution_breakdown (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS nutrients (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS nutrient_synergies (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS nutrient_targets (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS nutrition_calculation_comparisons (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS offline_capability_status (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS offline_conflict_resolution (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS offline_sync_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS offline_transaction_queue (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS order_line_items (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS order_management (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS pain_tracking (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS pantry_inventory (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS partner_applications (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS partner_contracts (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS partner_contract_terms (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS partner_facilities (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS partner_payout_schedule (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS partner_performance_metrics (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS partnership_agreements (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS payment_gateways_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS payout_requests (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS personalization_params (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS pet_abilities (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS pet_care_actions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS pet_decay_rules (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS pet_evolution_stages (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS pet_species (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS pharmacy_inventory (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS pharmacy_locations (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS pharmacy_order_items (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS pharmacy_orders (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS pharmacy_payment_acceptance (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS pharmacy_purchase_orders (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS pharmacy_stock_movements (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS phosphorus_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS platform_revenue_ledger (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS point_minting_audit (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS points_earning_rules (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS points_expiry_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS points_vrc_conversions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS post_comments (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS post_likes (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS potassium_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS privacy_settings (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS product_catalog (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS product_categories (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS product_multi_currency_pricing (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS proficiency_level_definitions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS progression_curve (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS promotional_campaigns (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS quest_objectives (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS random_blood_sugar_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_cooking_steps (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_favorites (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_ingredients (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_reviews (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipes (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_submissions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_tag_assignments (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_tags (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_variations (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recommendation_feedback (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS referral_commission_rules (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS referral_tickets (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS referral_transactions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS region_content (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS region_unlock_requirements (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS regulatory_compliance_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS renal_acid_load_data (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS research_studies (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS revenue_forecast (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS revenue_targets (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS review_comments (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS review_decision_factors (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS reviewer_workload (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS review_sla_targets (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS revision_requirements_tracking (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS reward_catalog (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS reward_redemption_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS risk_prediction_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS saved_drinks (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS saved_meals (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS schema_migrations (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS screening_reminders (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS seasonal_availability (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS season_pass_metadata (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS second_opinion_requests (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS shipping_logistics (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS shopping_lists (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS skill_tree (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS sleep_stages_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS sms_delivery_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS sms_provider_config (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS sms_templates (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS sms_verification_codes (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS social_good_goals (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS social_good_impact_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS social_good_success_stories (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS social_groups (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS social_posts (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS sodium_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS specialist_registry (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS specimen_tracking (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS step_count_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS streak_multipliers (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS study_participants (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS submission_approvals (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS submission_resubmissions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS submission_review_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS submission_review_queue (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS submission_rewards (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS submission_version_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS subregions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS subscription_features (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS subscription_plans (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS subscription_transactions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS support_group_meetings (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS symptom_diary (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS tax_reporting_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS telemedicine_sessions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS test_interpretation_rules (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS transaction_reviews (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS treatment_plans (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS trust_actions_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS trust_score_weights (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS unified_payment_ledger (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS universal_currency_matrix (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_access_controls (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_achievements (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_achievement_tier_progress (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_app_settings (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_auth_tokens (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_barter_preferences (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_boss_progress (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_conditions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_connections (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_cosmetics (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_crafting_inventory (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_crafting_mastery (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_daily_logins (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_devices (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_fraud_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_health_goals (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_kyc_status (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_login_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_payment_preferences (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_pets (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_Profiles (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_promotional_redemptions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_purchase_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_quest_progress (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_referrals (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_region_progress (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_skills (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_stats (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_streaks (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_subscriptions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_terms_agreements (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_trust_ratings (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_volume_tier_assignments (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_vrc_wallets (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_wellness_score (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_xp_transactions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS vendor_profiles (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS virtual_currency_basket (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS virtual_currency_config (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS virtual_currency_rate_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS vital_signs_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS volume_discount_tiers (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS vrc_transactions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS vulnerable_population_registry (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS vuralis_consent_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS vuralis_consent_policy (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS vuralis_sync_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS wallet_transactions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS world_map_regions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS xp_earning_rules (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS xp_multiplier_context (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS xp_rules (id SERIAL PRIMARY KEY);

-- Disable FK checks for bootstrap
SET session_replication_role = 'replica';
-- Migration 000: Bootstrap Base Schema (Full)
-- Purpose: Pre-create all tables referenced in subsequent migrations to ensure idempotency

CREATE TABLE IF NOT EXISTS achievements (id SERIAL PRIMARY KEY, name VARCHAR(120), description TEXT, icon TEXT, requirement_type VARCHAR(40), reward_item_id INTEGER, points INTEGER DEFAULT 0, category VARCHAR(40), xp_reward INTEGER DEFAULT 0, points_reward INTEGER DEFAULT 0, trigger_type VARCHAR(40), trigger_value DOUBLE PRECISION, badge_id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS achievement_tiers (
    id INTEGER PRIMARY KEY,
    achievement_id INTEGER NOT NULL REFERENCES achievements(id),
    tier_name VARCHAR(20) NOT NULL,
    tier_level INTEGER NOT NULL,
    requirement_value DOUBLE PRECISION NOT NULL,
    requirement_description TEXT NOT NULL,
    xp_reward INTEGER NOT NULL,
    ap_reward INTEGER DEFAULT 0,
    cosmetic_reward_id INTEGER,
    title_reward VARCHAR(80),
    requires_subscription_tier INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(achievement_id, tier_level)
);
CREATE TABLE IF NOT EXISTS active_buffs (id SERIAL PRIMARY KEY, user_id INTEGER, buff_name TEXT, buff_type TEXT, multiplier DOUBLE PRECISION, expires_at TIMESTAMP, created_at TIMESTAMP);
CREATE TABLE IF NOT EXISTS adherence_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    medication_id INTEGER NOT NULL,
    schedule_id INTEGER,
    scheduled_at TIMESTAMP NOT NULL,
    taken_at TIMESTAMP,
    status VARCHAR(20) NOT NULL,
    dose_taken VARCHAR(60),
    skip_reason VARCHAR(100),
    side_effects TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE,
    FOREIGN KEY (schedule_id) REFERENCES medication_schedules(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS adverse_event_monitoring (
    id SERIAL PRIMARY KEY,
    study_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    event_type VARCHAR(80),
    severity VARCHAR(20),
    description TEXT,
    action_taken TEXT,
    reported_to_ethics BOOLEAN DEFAULT FALSE,
    reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (study_id) REFERENCES research_studies(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS afya_points_ledger (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  points_change INTEGER NOT NULL,
  transaction_type VARCHAR(40),
  action_type VARCHAR(60),
  reference_id INTEGER,
  reference_table VARCHAR(60),
  balance_after INTEGER NOT NULL,
  expires_at DATE,
  is_expired BOOLEAN DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS points_expiry_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  points_to_expire INTEGER NOT NULL,
  earned_on DATE NOT NULL,
  expires_on DATE NOT NULL,
  expired_at TIMESTAMP,
  status VARCHAR(20) DEFAULT 'pending',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS ai_inference_results (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    model_id INTEGER NOT NULL,
    input_data TEXT,
    output_data TEXT,
    confidence_score DOUBLE PRECISION,
    inference_time_ms INTEGER,
    inference_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (model_id) REFERENCES ai_model_registry(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS ai_model_registry (
    id SERIAL PRIMARY KEY,
    model_name VARCHAR(120) NOT NULL UNIQUE,
    model_type VARCHAR(60),
    model_version VARCHAR(40) NOT NULL,
    description TEXT,
    input_features TEXT,
    output_format TEXT,
    accuracy_score DOUBLE PRECISION,
    f1_score DOUBLE PRECISION,
    training_date DATE,
    deployed_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    endpoint_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS ai_recommendation_types (
    id SERIAL PRIMARY KEY,
    type_name VARCHAR(60) NOT NULL UNIQUE,
    category VARCHAR(40),
    description TEXT,
    model_id INTEGER,
    priority_weight DOUBLE PRECISION DEFAULT 1.0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (model_id) REFERENCES ai_model_registry(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS allergy_flags (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS aml_screening_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  transaction_id INTEGER,
  transaction_type VARCHAR(40),
  screening_type VARCHAR(60) NOT NULL,
  risk_score DOUBLE PRECISION NOT NULL,
  risk_level VARCHAR(40),
  red_flags TEXT,
  red_flag_count INTEGER DEFAULT 0,
  transaction_volume_last_30_days_ugx DOUBLE PRECISION,
  transaction_count_last_30_days INTEGER,
  avg_transaction_size_ugx DOUBLE PRECISION,
  unusual_pattern_detected BOOLEAN DEFAULT FALSE,
  unusual_pattern_description TEXT,
  on_sanctions_list BOOLEAN DEFAULT FALSE,
  sanctions_list_name VARCHAR(200),
  is_pep BOOLEAN DEFAULT FALSE,
  pep_relationship VARCHAR(200),
  requires_reporting BOOLEAN DEFAULT FALSE,
  reported_to_authority BOOLEAN DEFAULT FALSE,
  reported_to VARCHAR(200),
  reported_at TIMESTAMP,
  report_reference VARCHAR(200),
  screening_result VARCHAR(40),
  reviewed_by INTEGER,
  reviewed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (reviewed_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS anomaly_detection_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    anomaly_type VARCHAR(60),
    metric_name VARCHAR(60),
    expected_value DOUBLE PRECISION,
    actual_value DOUBLE PRECISION,
    deviation_score DOUBLE PRECISION,
    severity VARCHAR(20),
    explanation TEXT,
    recommended_action TEXT,
    reviewed_by_staff BOOLEAN DEFAULT FALSE,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS api_usage_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    endpoint VARCHAR(200) NOT NULL,
    method VARCHAR(10),
    status_code INTEGER,
    response_ms INTEGER,
    error_ref INTEGER,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS approved_content_audit (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS audit_trail_sensitive (
    id SERIAL PRIMARY KEY,
    accessor_user_id INTEGER NOT NULL,
    subject_user_id INTEGER NOT NULL,
    data_category VARCHAR(40),
    action VARCHAR(30),
    table_name VARCHAR(60),
    record_id INTEGER,
    justification TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (accessor_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS auto_assignment_rules (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS automated_nudge_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    nudge_type VARCHAR(60),
    trigger_condition TEXT,
    message_sent TEXT,
    delivery_method VARCHAR(20),
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    opened BOOLEAN DEFAULT FALSE,
    opened_at TIMESTAMP,
    action_taken BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS avatar_appearance_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS avatar_cosmetic_shop (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS avatar_cosmetics (id SERIAL PRIMARY KEY, cosmetic_name VARCHAR(100) NOT NULL, cosmetic_type VARCHAR(40), rarity VARCHAR(20), unlock_method VARCHAR(40), cost_afya_points INTEGER DEFAULT 0, image_ref TEXT, description TEXT);
CREATE TABLE IF NOT EXISTS avatar_evolution_progress (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS avatar_evolution_stages (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS avatar_health_milestones (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS avatar_stats (id SERIAL PRIMARY KEY, user_id INTEGER NOT NULL UNIQUE, HP INTEGER DEFAULT 100, Strength INTEGER DEFAULT 10, Agility INTEGER DEFAULT 10, Intelligence INTEGER DEFAULT 10, Immunity INTEGER DEFAULT 10, Resilience INTEGER DEFAULT 10, Gut_Health INTEGER DEFAULT 10, Vitality INTEGER DEFAULT 10, XP_points INTEGER DEFAULT 0, Level INTEGER DEFAULT 1, Current_Streak INTEGER DEFAULT 0, Aura_Tier VARCHAR(20) DEFAULT 'none', class_id INTEGER, xp_to_next_level INTEGER DEFAULT 100, afya_points_balance INTEGER DEFAULT 0, FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS backup_restore_logs (
    id SERIAL PRIMARY KEY,
    operation_type VARCHAR(20),
    database_name VARCHAR(60),
    file_reference TEXT,
    size_mb DOUBLE PRECISION,
    status VARCHAR(20),
    initiated_by VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS badges (id SERIAL PRIMARY KEY, name VARCHAR(80) NOT NULL, description TEXT, icon TEXT, requirement_description TEXT, badge_type VARCHAR(40), rarity VARCHAR(20), image_ref TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS barter_escrow_locks (
  id SERIAL PRIMARY KEY,
  transaction_id INTEGER NOT NULL,
  item_type VARCHAR(40),
  item_id INTEGER NOT NULL,
  locked_by_user_id INTEGER NOT NULL,
  locked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  is_released BOOLEAN DEFAULT FALSE,
  released_at TIMESTAMP,
  FOREIGN KEY (transaction_id) REFERENCES barter_exchange_transactions(id) ON DELETE CASCADE,
  FOREIGN KEY (locked_by_user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS barter_exchange_transactions (
  id SERIAL PRIMARY KEY,
  transaction_type VARCHAR(40),
  party_a_user_id INTEGER NOT NULL,
  party_a_offer_type VARCHAR(40),
  party_a_offer_id INTEGER,
  party_a_offer_description TEXT,
  party_a_afya_points_value INTEGER,
  party_b_user_id INTEGER NOT NULL,
  party_b_offer_type VARCHAR(40),
  party_b_offer_id INTEGER,
  party_b_offer_description TEXT,
  party_b_afya_points_value INTEGER,
  value_difference_points INTEGER,
  balance_payment_method VARCHAR(40),
  balance_payment_amount DOUBLE PRECISION,
  balance_payment_currency VARCHAR(10),
  status VARCHAR(40) DEFAULT 'pending',
  initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  accepted_at TIMESTAMP,
  escrow_locked_at TIMESTAMP,
  escrow_release_at TIMESTAMP,
  completed_at TIMESTAMP,
  cancelled_at TIMESTAMP,
  cancellation_reason TEXT,
  party_a_confirmed BOOLEAN DEFAULT FALSE,
  party_a_confirmed_at TIMESTAMP,
  party_b_confirmed BOOLEAN DEFAULT FALSE,
  party_b_confirmed_at TIMESTAMP,
  facility_verified BOOLEAN DEFAULT FALSE,
  verified_by INTEGER,
  verified_at TIMESTAMP,
  verification_notes TEXT,
  transaction_fee_pct DOUBLE PRECISION DEFAULT 3.5,
  transaction_fee_ap INTEGER,
  transaction_fee_ugx DOUBLE PRECISION,
  fee_paid BOOLEAN DEFAULT FALSE,
  fee_paid_at TIMESTAMP,
  dispute_raised BOOLEAN DEFAULT FALSE,
  dispute_raised_by INTEGER,
  dispute_raised_at TIMESTAMP,
  dispute_reason TEXT,
  dispute_status VARCHAR(40),
  dispute_resolved_at TIMESTAMP,
  dispute_resolution_notes TEXT,
  dispute_resolved_by INTEGER,
  party_a_rating INTEGER,
  party_a_review TEXT,
  party_a_reviewed_at TIMESTAMP,
  party_b_rating INTEGER,
  party_b_review TEXT,
  party_b_reviewed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (party_a_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (party_b_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verified_by) REFERENCES medical_staff(id) ON DELETE SET NULL,
  FOREIGN KEY (dispute_raised_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (dispute_resolved_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS barter_goods_catalog (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  item_name VARCHAR(200) NOT NULL,
  item_category VARCHAR(60),
  item_description TEXT,
  condition VARCHAR(40),
  estimated_value_ugx DOUBLE PRECISION,
  afya_points_equivalent INTEGER,
  quantity INTEGER DEFAULT 1,
  unit VARCHAR(40),
  location_district VARCHAR(100),
  location_gps_lat DOUBLE PRECISION,
  location_gps_lng DOUBLE PRECISION,
  delivery_available BOOLEAN DEFAULT FALSE,
  delivery_radius_km INTEGER,
  photos TEXT,
  is_available BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT FALSE,
  verified_by INTEGER,
  verified_at TIMESTAMP,
  verification_method VARCHAR(40),
  expires_at DATE,
  perishable BOOLEAN DEFAULT FALSE,
  seeking_items TEXT,
  seeking_categories TEXT,
  open_to_offers BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verified_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS barter_item_categories (id SERIAL PRIMARY KEY, category_name VARCHAR(60) NOT NULL UNIQUE, category_type VARCHAR(40), parent_category_id INTEGER, is_active BOOLEAN DEFAULT TRUE, FOREIGN KEY (parent_category_id) REFERENCES barter_item_categories(id) ON DELETE SET NULL);
CREATE TABLE IF NOT EXISTS barter_match_notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  match_score_id INTEGER NOT NULL,
  notification_type VARCHAR(40),
  notification_text TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (match_score_id) REFERENCES barter_match_scores(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS barter_match_scores (
  id SERIAL PRIMARY KEY,
  user_a_id INTEGER NOT NULL,
  user_a_offer_type VARCHAR(40),
  user_a_offer_id INTEGER,
  user_a_offer_value_ap INTEGER,
  user_b_id INTEGER NOT NULL,
  user_b_offer_type VARCHAR(40),
  user_b_offer_id INTEGER,
  user_b_offer_value_ap INTEGER,
  match_score DOUBLE PRECISION NOT NULL,
  category_alignment_score DOUBLE PRECISION,
  value_alignment_score DOUBLE PRECISION,
  location_proximity_score DOUBLE PRECISION,
  trust_score_avg DOUBLE PRECISION,
  value_difference_ap INTEGER,
  distance_km DOUBLE PRECISION,
  is_mutual_match BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  match_suggested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  match_viewed BOOLEAN DEFAULT FALSE,
  match_viewed_at TIMESTAMP,
  trade_initiated BOOLEAN DEFAULT FALSE,
  trade_initiated_at TIMESTAMP,
  calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  recalculate_after TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '1 day'),
  FOREIGN KEY (user_a_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (user_b_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (user_a_id, user_a_offer_id, user_b_id, user_b_offer_id)
);
CREATE TABLE IF NOT EXISTS barter_services_catalog (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  service_name VARCHAR(200) NOT NULL,
  service_category VARCHAR(60),
  service_description TEXT,
  estimated_value_ugx DOUBLE PRECISION,
  afya_points_equivalent INTEGER,
  duration_hours DOUBLE PRECISION,
  location_district VARCHAR(100),
  location_gps_lat DOUBLE PRECISION,
  location_gps_lng DOUBLE PRECISION,
  can_travel BOOLEAN DEFAULT FALSE,
  travel_radius_km INTEGER,
  portfolio_images TEXT,
  certifications TEXT,
  rating_avg DOUBLE PRECISION DEFAULT 0,
  rating_count INTEGER DEFAULT 0,
  completed_services INTEGER DEFAULT 0,
  is_available BOOLEAN DEFAULT TRUE,
  availability_schedule TEXT,
  seeking_items TEXT,
  seeking_categories TEXT,
  open_to_offers BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS barter_transaction_timeline (
  id SERIAL PRIMARY KEY,
  transaction_id INTEGER NOT NULL,
  status_from VARCHAR(40),
  status_to VARCHAR(40) NOT NULL,
  changed_by INTEGER,
  change_reason TEXT,
  automated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (transaction_id) REFERENCES barter_exchange_transactions(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS batch_expiry_tracking (
    id SERIAL PRIMARY KEY,
    pharmacy_id INTEGER NOT NULL,
    medication_id INTEGER NOT NULL,
    batch_number VARCHAR(60) NOT NULL,
    quantity_received INTEGER NOT NULL,
    quantity_remaining INTEGER NOT NULL,
    manufacture_date DATE,
    expiry_date DATE NOT NULL,
    days_until_expiry INTEGER,
    alert_threshold_days INTEGER DEFAULT 90,
    status VARCHAR(20),
    supplier VARCHAR(200),
    unit_cost_ugx DOUBLE PRECISION,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pharmacy_id) REFERENCES pharmacy_locations(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE,
    UNIQUE(pharmacy_id, medication_id, batch_number)
);
CREATE TABLE IF NOT EXISTS behavioral_segmentation (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    segment_name VARCHAR(60),
    segment_score DOUBLE PRECISION,
    engagement_level VARCHAR(20),
    health_literacy VARCHAR(20),
    digital_savviness VARCHAR(20),
    risk_tolerance VARCHAR(20),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS beverages (id SERIAL PRIMARY KEY, name TEXT);
CREATE TABLE IF NOT EXISTS beverage_submissions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS biomarker_reference_ranges (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS biomarker_trends (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    biomarker_name VARCHAR(60) NOT NULL,
    analysis_date DATE NOT NULL,
    period_days INTEGER DEFAULT 90,
    baseline_value DOUBLE PRECISION,
    latest_value DOUBLE PRECISION,
    change_amount DOUBLE PRECISION,
    change_pct DOUBLE PRECISION,
    trend VARCHAR(20),
    interpretation TEXT,
    clinical_action TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS blacklisted_entities (
  id SERIAL PRIMARY KEY,
  entity_type VARCHAR(60) NOT NULL,
  entity_value VARCHAR(500) NOT NULL,
  entity_hash VARCHAR(100),
  blacklist_reason VARCHAR(60),
  blacklist_notes TEXT,
  blacklist_level VARCHAR(40) DEFAULT 'permanent',
  blacklist_expires_at TIMESTAMP,
  block_new_accounts BOOLEAN DEFAULT TRUE,
  block_transactions BOOLEAN DEFAULT TRUE,
  require_manual_review BOOLEAN DEFAULT TRUE,
  blacklisted_by INTEGER,
  blacklisted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (blacklisted_by) REFERENCES medical_staff(id) ON DELETE SET NULL,
  UNIQUE (entity_type, entity_value)
);
CREATE TABLE IF NOT EXISTS blood_pressure_trends (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    analysis_date DATE NOT NULL,
    period_days INTEGER DEFAULT 30,
    avg_systolic DOUBLE PRECISION,
    avg_diastolic DOUBLE PRECISION,
    max_systolic INTEGER,
    max_diastolic INTEGER,
    min_systolic INTEGER,
    min_diastolic INTEGER,
    measurement_count INTEGER,
    trend VARCHAR(20),
    risk_category VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, analysis_date)
);
CREATE TABLE IF NOT EXISTS body_composition_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    weight_kg DOUBLE PRECISION,
    height_cm DOUBLE PRECISION,
    bmi DOUBLE PRECISION,
    body_fat_pct DOUBLE PRECISION,
    muscle_mass_kg DOUBLE PRECISION,
    bone_mass_kg DOUBLE PRECISION,
    body_water_pct DOUBLE PRECISION,
    visceral_fat_level INTEGER,
    metabolic_age INTEGER,
    measurement_method VARCHAR(40),
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS boss_condition_links (
    id INTEGER PRIMARY KEY,
    boss_id INTEGER NOT NULL REFERENCES boss_encounters(id),
    condition_id INTEGER NOT NULL REFERENCES medical_conditions(id),
    unlock_at_stage VARCHAR(20),
    hp_modifier DOUBLE PRECISION DEFAULT 1.0,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(boss_id, condition_id)
);
CREATE TABLE IF NOT EXISTS boss_encounters (
    id INTEGER PRIMARY KEY,
    boss_name VARCHAR(80) NOT NULL UNIQUE,
    boss_title VARCHAR(120),
    description TEXT NOT NULL,
    condition_focus VARCHAR(60),
    base_hp INTEGER NOT NULL,
    difficulty_level INTEGER NOT NULL DEFAULT 1,
    respawn_days INTEGER DEFAULT 30,
    difficulty_scaling DOUBLE PRECISION DEFAULT 1.5,
    min_level_required INTEGER DEFAULT 5,
    requires_subscription_tier INTEGER DEFAULT 3,
    xp_reward_base INTEGER NOT NULL,
    ap_reward_base INTEGER DEFAULT 0,
    icon VARCHAR(60),
    lore_text TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS boss_loot_table (
    id INTEGER PRIMARY KEY,
    boss_id INTEGER NOT NULL REFERENCES boss_encounters(id),
    loot_type VARCHAR(40) NOT NULL,
    loot_value INTEGER,
    loot_item_id INTEGER,
    loot_name VARCHAR(80),
    drop_chance_pct DOUBLE PRECISION DEFAULT 100.0,
    is_first_kill_only BOOLEAN DEFAULT FALSE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS boss_mechanics (
    id INTEGER PRIMARY KEY,
    boss_id INTEGER NOT NULL REFERENCES boss_encounters(id),
    mechanic_type VARCHAR(40) NOT NULL,
    target_metric VARCHAR(60) NOT NULL,
    target_operator VARCHAR(10) NOT NULL DEFAULT '<=',
    target_value DOUBLE PRECISION NOT NULL,
    target_value_upper DOUBLE PRECISION,
    required_days INTEGER DEFAULT 7,
    damage_per_success INTEGER NOT NULL,
    description TEXT NOT NULL,
    sequence_order INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS calculation_warnings (
    id SERIAL PRIMARY KEY,
    meal_nutrition_calculation_id INTEGER NOT NULL,
    warning_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    warning_message TEXT NOT NULL,
    affected_nutrient VARCHAR(50),
    affected_food_id INTEGER,
    fallback_method VARCHAR(100),
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (meal_nutrition_calculation_id) REFERENCES meal_nutrition_calculations(id),
    FOREIGN KEY (affected_food_id) REFERENCES foods(id),
    CHECK (severity IN ('info', 'warning', 'error'))
);
CREATE TABLE IF NOT EXISTS category_nutrients (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS challenge_participants (
  id SERIAL PRIMARY KEY,
  challenge_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  current_value DOUBLE PRECISION DEFAULT 0,
  rank INTEGER,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (challenge_id, user_id)
);
CREATE TABLE IF NOT EXISTS challenges (id SERIAL PRIMARY KEY, name VARCHAR(100), description TEXT, start_date DATE, end_date DATE, is_active BOOLEAN DEFAULT TRUE);
CREATE TABLE IF NOT EXISTS character_classes (id SERIAL PRIMARY KEY, class_name VARCHAR(50), description TEXT);
CREATE TABLE IF NOT EXISTS character_progression (id SERIAL PRIMARY KEY, class_id INTEGER, level INTEGER NOT NULL, xp_required INTEGER NOT NULL, title_unlocked TEXT);
CREATE TABLE IF NOT EXISTS cocktail_ingredients (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS cocktails (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS condition_game_modifiers (
    id INTEGER PRIMARY KEY,
    condition_id INTEGER NOT NULL,
    modifier_type VARCHAR(40) NOT NULL,
    modifier_key VARCHAR(80) NOT NULL,
    modifier_value DOUBLE PRECISION,
    modifier_text TEXT,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (condition_id) REFERENCES medical_conditions(id)
);
CREATE TABLE IF NOT EXISTS condition_nutrient_templates (
    id SERIAL PRIMARY KEY,
    condition VARCHAR(50) NOT NULL,
    condition_stage VARCHAR(20),
    nutrient_name VARCHAR(50) NOT NULL,
    target_min DOUBLE PRECISION,
    target_max DOUBLE PRECISION,
    target_value DOUBLE PRECISION,
    unit VARCHAR(20) NOT NULL,
    calculation_formula TEXT,
    formula_variables TEXT,
    clinical_rationale TEXT NOT NULL,
    reference_source VARCHAR(200) NOT NULL,
    publication_year INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(condition, condition_stage, nutrient_name)
);
CREATE TABLE IF NOT EXISTS condition_nutrition_rules (
    id INTEGER PRIMARY KEY,
    condition_id INTEGER NOT NULL,
    rule_type VARCHAR(40) NOT NULL,
    nutrient_or_food VARCHAR(60),
    min_value DOUBLE PRECISION,
    max_value DOUBLE PRECISION,
    unit VARCHAR(20),
    priority VARCHAR(20) DEFAULT 'recommended',
    clinical_rationale TEXT,
    reference_source VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (condition_id) REFERENCES medical_conditions(id)
);
CREATE TABLE IF NOT EXISTS condition_onboarding_flow (
    id INTEGER PRIMARY KEY,
    condition_id INTEGER,
    question_text TEXT NOT NULL,
    question_type VARCHAR(20) NOT NULL,
    options TEXT,
    is_required BOOLEAN DEFAULT TRUE,
    sequence_order INTEGER NOT NULL,
    maps_to_field VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (condition_id) REFERENCES medical_conditions(id)
);
CREATE TABLE IF NOT EXISTS condition_thresholds (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS consultation_attachments (
    id SERIAL PRIMARY KEY,
    consultation_id INTEGER NOT NULL,
    uploaded_by VARCHAR(20),
    file_type VARCHAR(40),
    file_url VARCHAR(500) NOT NULL,
    file_name VARCHAR(200),
    file_size_kb INTEGER,
    description TEXT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS consultation_bookings (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS consultation_payments (
    id SERIAL PRIMARY KEY,
    consultation_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    amount_ugx DOUBLE PRECISION NOT NULL,
    payment_method VARCHAR(40),
    payment_status VARCHAR(20),
    transaction_ref VARCHAR(120),
    paid_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS consultation_queue (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    staff_id INTEGER,
    priority VARCHAR(20),
    check_in_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estimated_wait_minutes INTEGER,
    queue_position INTEGER,
    status VARCHAR(20),
    called_at TIMESTAMP,
    completed_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES medical_services(id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS consultation_ratings (
    id SERIAL PRIMARY KEY,
    consultation_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    staff_id INTEGER NOT NULL,
    overall_rating INTEGER NOT NULL,
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
CREATE TABLE IF NOT EXISTS consultation_receipts (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS consultation_transcripts (
    id SERIAL PRIMARY KEY,
    consultation_id INTEGER NOT NULL,
    transcript_text TEXT,
    audio_url VARCHAR(500),
    transcription_method VARCHAR(40),
    transcribed_at TIMESTAMP,
    reviewed_by_staff BOOLEAN DEFAULT FALSE,
    is_confidential BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE,
    UNIQUE(consultation_id)
);
CREATE TABLE IF NOT EXISTS cooking_methods (
    id SERIAL PRIMARY KEY,
    method_name VARCHAR(60) NOT NULL UNIQUE,
    method_type VARCHAR(40),
    description TEXT,
    typical_temp_range VARCHAR(40),
    nutrient_impact TEXT,
    health_rating VARCHAR(20),
    equipment_needed TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS cosmetic_bundles (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS cosmetic_earning_methods (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS cosmetic_wishlist (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS countries_supported (id SERIAL PRIMARY KEY, country_code TEXT UNIQUE, country_name TEXT, currency_code TEXT UNIQUE, currency_symbol TEXT, language_primary TEXT, language_secondary TEXT, is_active BOOLEAN DEFAULT TRUE, added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS country_cost_of_living (
  id SERIAL PRIMARY KEY,
  country_code VARCHAR(5) NOT NULL UNIQUE,
  cost_of_living_index DOUBLE PRECISION NOT NULL,
  minimum_wage_hourly_local_currency DOUBLE PRECISION,
  minimum_wage_hourly_ugx DOUBLE PRECISION,
  currency_strength_index DOUBLE PRECISION,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code)
);
CREATE TABLE IF NOT EXISTS country_fee_adjustments (
  id SERIAL PRIMARY KEY,
  country_code VARCHAR(5) NOT NULL,
  fee_type VARCHAR(60) NOT NULL,
  adjusted_fee_pct DOUBLE PRECISION,
  adjusted_fee_ap INTEGER,
  adjusted_fee_ugx DOUBLE PRECISION,
  adjustment_reason TEXT,
  effective_date DATE DEFAULT CURRENT_DATE,
  expires_at DATE,
  is_active BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code),
  UNIQUE (country_code, fee_type)
);
CREATE TABLE IF NOT EXISTS country_regulatory_requirements (
  id SERIAL PRIMARY KEY,
  country_code VARCHAR(5) NOT NULL UNIQUE,
  kyc_required BOOLEAN DEFAULT TRUE,
  kyc_threshold_ugx DOUBLE PRECISION,
  kyc_renewal_months INTEGER DEFAULT 24,
  aml_screening_required BOOLEAN DEFAULT TRUE,
  aml_threshold_ugx DOUBLE PRECISION,
  suspicious_transaction_threshold_ugx DOUBLE PRECISION,
  tax_reporting_required BOOLEAN DEFAULT TRUE,
  tax_reporting_threshold_ugx DOUBLE PRECISION,
  tax_authority VARCHAR(200),
  max_transaction_without_kyc_ugx DOUBLE PRECISION,
  max_daily_volume_ugx DOUBLE PRECISION,
  max_monthly_volume_ugx DOUBLE PRECISION,
  central_bank VARCHAR(200),
  financial_intelligence_unit VARCHAR(200),
  data_protection_authority VARCHAR(200),
  mobile_money_license_required BOOLEAN DEFAULT FALSE,
  mobile_money_regulatory_body VARCHAR(200),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code)
);
CREATE TABLE IF NOT EXISTS country_revenue_summary (
  id SERIAL PRIMARY KEY,
  country_code VARCHAR(5) NOT NULL,
  month DATE NOT NULL,
  total_revenue_ugx DOUBLE PRECISION DEFAULT 0,
  total_revenue_local_currency DOUBLE PRECISION DEFAULT 0,
  local_currency_code VARCHAR(5),
  barter_fees_ugx DOUBLE PRECISION DEFAULT 0,
  labor_fees_ugx DOUBLE PRECISION DEFAULT 0,
  total_transactions INTEGER DEFAULT 0,
  active_users INTEGER DEFAULT 0,
  new_users INTEGER DEFAULT 0,
  calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code),
  UNIQUE (country_code, month)
);
CREATE TABLE IF NOT EXISTS crafting_condition_bonuses (
    id INTEGER PRIMARY KEY,
    recipe_id INTEGER NOT NULL REFERENCES crafting_recipes(id),
    condition_id INTEGER NOT NULL REFERENCES medical_conditions(id),
    quality_bonus DOUBLE PRECISION DEFAULT 0.2,
    xp_bonus_pct DOUBLE PRECISION DEFAULT 25.0,
    bonus_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(recipe_id, condition_id)
);
CREATE TABLE IF NOT EXISTS crafting_materials (
    id INTEGER PRIMARY KEY,
    food_id INTEGER NOT NULL REFERENCES foods(id),
    material_name VARCHAR(80),
    material_category VARCHAR(40) NOT NULL,
    quality_contribution DOUBLE PRECISION DEFAULT 1.0,
    rarity VARCHAR(20) DEFAULT 'common',
    condition_bonus_for VARCHAR(60),
    condition_bonus_multiplier DOUBLE PRECISION DEFAULT 1.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(food_id)
);
CREATE TABLE IF NOT EXISTS crafting_quality_tiers (
    id INTEGER PRIMARY KEY,
    tier_name VARCHAR(20) NOT NULL UNIQUE,
    tier_level INTEGER NOT NULL UNIQUE,
    min_quality_score DOUBLE PRECISION NOT NULL,
    xp_multiplier DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    ap_bonus INTEGER DEFAULT 0,
    color_hex VARCHAR(10),
    requires_subscription_tier INTEGER DEFAULT 1,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS crafting_recipes (
    id INTEGER PRIMARY KEY,
    recipe_name VARCHAR(120) NOT NULL,
    recipe_type VARCHAR(40) NOT NULL,
    description TEXT,
    condition_focus VARCHAR(60),
    required_food_categories TEXT NOT NULL,
    required_food_count INTEGER DEFAULT 3,
    quality_formula TEXT,
    base_xp_reward INTEGER DEFAULT 10,
    base_ap_reward INTEGER DEFAULT 2,
    effect_description TEXT,
    effect_duration_hours INTEGER DEFAULT 24,
    requires_subscription_tier INTEGER DEFAULT 1,
    min_crafting_level INTEGER DEFAULT 1,
    cooldown_hours INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS creatinine_egfr_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    creatinine_mg_dl DOUBLE PRECISION NOT NULL,
    egfr_ml_min DOUBLE PRECISION,
    egfr_formula VARCHAR(50),
    measured_at TIMESTAMP NOT NULL,
    ckd_stage VARCHAR(20),
    measurement_context VARCHAR(50),
    lab_facility_id INTEGER,
    notes TEXT,
    bun_mg_dl DOUBLE PRECISION,
    urine_albumin_mg DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entered_by INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (lab_facility_id) REFERENCES partner_facilities(id),
    FOREIGN KEY (entered_by) REFERENCES users(id)
);
CREATE TABLE IF NOT EXISTS cross_platform_currency_bridge (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS currency_exchange_rates (
  id SERIAL PRIMARY KEY,
  from_currency_code VARCHAR(5) NOT NULL,
  to_currency_code VARCHAR(5) NOT NULL,
  exchange_rate DOUBLE PRECISION NOT NULL,
  rate_source VARCHAR(100),
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  update_frequency VARCHAR(20) DEFAULT 'daily',
  UNIQUE (from_currency_code, to_currency_code)
);
CREATE TABLE IF NOT EXISTS daily_login_calendar (
    id INTEGER PRIMARY KEY,
    day_number INTEGER NOT NULL UNIQUE,
    reward_type VARCHAR(40) NOT NULL,
    reward_value INTEGER NOT NULL,
    reward_description TEXT NOT NULL,
    subscriber_multiplier DOUBLE PRECISION DEFAULT 2.0,
    subscriber_bonus_type VARCHAR(40),
    subscriber_bonus_value INTEGER,
    subscriber_bonus_description TEXT,
    is_milestone_day BOOLEAN DEFAULT FALSE,
    icon VARCHAR(40),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS daily_xp_summary (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS data_export_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    request_type VARCHAR(20),
    status VARCHAR(20),
    export_file_ref TEXT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    handled_by VARCHAR(60),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS data_privacy_consent (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE,
  marketing_consent BOOLEAN DEFAULT FALSE,
  data_sharing_consent BOOLEAN DEFAULT FALSE,
  vuralis_data_sharing_consent BOOLEAN DEFAULT FALSE,
  third_party_analytics_consent BOOLEAN DEFAULT FALSE,
  geolocation_tracking_consent BOOLEAN DEFAULT FALSE,
  consent_granted_at TIMESTAMP,
  consent_revoked_at TIMESTAMP,
  consent_version VARCHAR(20),
  right_to_be_forgotten_requested BOOLEAN DEFAULT FALSE,
  right_to_be_forgotten_requested_at TIMESTAMP,
  data_export_requested BOOLEAN DEFAULT FALSE,
  data_export_completed_at TIMESTAMP,
  gdpr_compliant BOOLEAN DEFAULT TRUE,
  popia_compliant BOOLEAN DEFAULT TRUE,
  ndpr_compliant BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS db_migration_history (
    id SERIAL PRIMARY KEY,
    migration_name VARCHAR(120) UNIQUE NOT NULL,
    direction VARCHAR(10),
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    applied_by VARCHAR(60),
    checksum VARCHAR(64)
);
CREATE TABLE IF NOT EXISTS device_fingerprints (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  device_id VARCHAR(200),
  device_type VARCHAR(60),
  os_name VARCHAR(60),
  os_version VARCHAR(60),
  browser_name VARCHAR(60),
  browser_version VARCHAR(60),
  ip_address VARCHAR(60),
  ip_country VARCHAR(5),
  is_vpn BOOLEAN DEFAULT FALSE,
  is_proxy BOOLEAN DEFAULT FALSE,
  is_tor BOOLEAN DEFAULT FALSE,
  last_location_lat DOUBLE PRECISION,
  last_location_lng DOUBLE PRECISION,
  last_location_country VARCHAR(5),
  last_location_city VARCHAR(100),
  first_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  login_count INTEGER DEFAULT 1,
  is_suspicious BOOLEAN DEFAULT FALSE,
  suspicious_reason TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS device_sync_state (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  device_id VARCHAR(200) NOT NULL,
  last_sync_at TIMESTAMP,
  last_successful_sync_at TIMESTAMP,
  pending_transactions INTEGER DEFAULT 0,
  failed_transactions INTEGER DEFAULT 0,
  avg_sync_duration_seconds DOUBLE PRECISION,
  total_sync_count INTEGER DEFAULT 0,
  success_sync_count INTEGER DEFAULT 0,
  failed_sync_count INTEGER DEFAULT 0,
  last_network_type VARCHAR(40),
  last_network_strength VARCHAR(40),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (user_id, device_id)
);
CREATE TABLE IF NOT EXISTS device_tokens (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS diagnostic_alerts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    diagnostic_result_id INTEGER,
    alert_type VARCHAR(40),
    severity VARCHAR(20),
    alert_message TEXT NOT NULL,
    recommended_action TEXT,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by INTEGER,
    acknowledged_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (diagnostic_result_id) REFERENCES diagnostic_results(id) ON DELETE SET NULL,
    FOREIGN KEY (acknowledged_by) REFERENCES users(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS direct_messages (
    id SERIAL PRIMARY KEY,
    thread_id INTEGER NOT NULL,
    sender_id INTEGER NOT NULL,
    message_text TEXT,
    media_urls TEXT,
    read_by TEXT,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (thread_id) REFERENCES direct_message_threads(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS direct_message_threads (
    id SERIAL PRIMARY KEY,
    thread_name VARCHAR(120),
    thread_type VARCHAR(20),
    created_by_user_id INTEGER NOT NULL,
    last_message_at TIMESTAMP,
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS discount_campaigns (
    id SERIAL PRIMARY KEY,
    campaign_name VARCHAR(120) NOT NULL,
    discount_type VARCHAR(20),
    discount_value DOUBLE PRECISION NOT NULL,
    min_purchase_ugx DOUBLE PRECISION,
    max_discount_ugx DOUBLE PRECISION,
    applicable_to TEXT,
    promo_code VARCHAR(40) UNIQUE,
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS doctor_availability (
    id SERIAL PRIMARY KEY,
    staff_id INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    consultation_type VARCHAR(40),
    max_patients_per_hour INTEGER DEFAULT 2,
    is_active BOOLEAN DEFAULT TRUE,
    effective_from DATE,
    effective_until DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES medical_staff(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS doctor_profiles (
    id INTEGER PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    staff_id INTEGER,
    contract_id INTEGER REFERENCES partner_contracts(id),
    specialty_id INTEGER NOT NULL REFERENCES medical_specialties(id),
    sub_specialty_id INTEGER REFERENCES medical_sub_specialties(id),
    full_name VARCHAR(200) NOT NULL,
    title VARCHAR(20) DEFAULT 'Dr.',
    license_number VARCHAR(100) NOT NULL,
    license_country VARCHAR(5) NOT NULL,
    license_verified BOOLEAN DEFAULT FALSE,
    license_verified_at TIMESTAMP,
    years_experience INTEGER,
    education TEXT,
    languages TEXT,
    bio TEXT,
    profile_photo_url VARCHAR(500),
    consultation_fee_ugx DOUBLE PRECISION,
    consultation_fee_usd DOUBLE PRECISION,
    accepts_insurance BOOLEAN DEFAULT FALSE,
    insurance_providers TEXT,
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
CREATE TABLE IF NOT EXISTS doctor_game_stat_access (
    id INTEGER PRIMARY KEY,
    patient_user_id INTEGER NOT NULL REFERENCES users(id),
    doctor_profile_id INTEGER NOT NULL REFERENCES doctor_profiles(id),
    access_level VARCHAR(20) NOT NULL DEFAULT 'basic',
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    revoked_at TIMESTAMP,
    revoked_reason TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    last_accessed_at TIMESTAMP,
    access_count INTEGER DEFAULT 0,
    requires_subscription_tier INTEGER DEFAULT 3,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(patient_user_id, doctor_profile_id)
);
CREATE TABLE IF NOT EXISTS doctor_availability_slots (
    id INTEGER PRIMARY KEY,
    doctor_profile_id INTEGER NOT NULL REFERENCES doctor_profiles(id),
    day_of_week INTEGER NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_duration_minutes INTEGER DEFAULT 30,
    consultation_type VARCHAR(40) DEFAULT 'telehealth',
    max_bookings INTEGER DEFAULT 1,
    current_bookings INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    effective_from DATE,
    effective_until DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS doctor_patient_access_log (
    id INTEGER PRIMARY KEY,
    doctor_profile_id INTEGER NOT NULL REFERENCES doctor_profiles(id),
    patient_user_id INTEGER NOT NULL REFERENCES users(id),
    access_type VARCHAR(40) NOT NULL,
    data_accessed TEXT,
    accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    consultation_id INTEGER
);
CREATE TABLE IF NOT EXISTS drink_components (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS drinks (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS drug_active_ingredients (
    id SERIAL PRIMARY KEY,
    medication_id INTEGER NOT NULL,
    active_ingredient VARCHAR(200) NOT NULL,
    strength VARCHAR(60),
    is_primary BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS drug_categories (
    id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    parent_id INTEGER,
    category_level INTEGER,
    description TEXT,
    common_uses TEXT,
    typical_side_effects TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES drug_categories(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS drug_regulatory_status (
    id SERIAL PRIMARY KEY,
    medication_id INTEGER NOT NULL,
    country_code VARCHAR(10) NOT NULL,
    regulatory_body VARCHAR(100),
    status VARCHAR(30) NOT NULL,
    registration_number VARCHAR(60),
    approval_date DATE,
    valid_until DATE,
    restrictions TEXT,
    scheduling VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE,
    UNIQUE(medication_id, country_code)
);
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    contact_name VARCHAR(120) NOT NULL,
    relationship VARCHAR(60),
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
CREATE TABLE IF NOT EXISTS error_exception_logs (
    id SERIAL PRIMARY KEY,
    error_type VARCHAR(60),
    message TEXT,
    stack_trace TEXT,
    user_id INTEGER,
    endpoint VARCHAR(200),
    severity VARCHAR(20),
    resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS essential_medicine_registry (
  id SERIAL PRIMARY KEY,
  medication_id INTEGER NOT NULL UNIQUE,
  is_essential_medicine BOOLEAN DEFAULT TRUE,
  who_essential_list BOOLEAN DEFAULT FALSE,
  national_essential_list BOOLEAN DEFAULT FALSE,
  priority_level VARCHAR(40) DEFAULT 'high',
  zero_fee_eligible BOOLEAN DEFAULT TRUE,
  for_ckd BOOLEAN DEFAULT FALSE,
  for_diabetes BOOLEAN DEFAULT FALSE,
  for_hypertension BOOLEAN DEFAULT FALSE,
  for_malaria BOOLEAN DEFAULT FALSE,
  for_hiv BOOLEAN DEFAULT FALSE,
  for_tb BOOLEAN DEFAULT FALSE,
  for_maternal_health BOOLEAN DEFAULT FALSE,
  social_good_reason TEXT,
  added_by INTEGER,
  added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE,
  FOREIGN KEY (added_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS exchange_rate_history (
  id SERIAL PRIMARY KEY,
  from_currency_code VARCHAR(5) NOT NULL,
  to_currency_code VARCHAR(5) NOT NULL,
  exchange_rate DOUBLE PRECISION NOT NULL,
  rate_source VARCHAR(100),
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS exchange_rate_locks (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  transaction_id INTEGER,
  transaction_type VARCHAR(40),
  from_currency_code VARCHAR(10) NOT NULL,
  to_currency_code VARCHAR(10) NOT NULL,
  locked_rate DOUBLE PRECISION NOT NULL,
  locked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  is_used BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS facility_certifications (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    certification_name VARCHAR(120),
    issuing_body VARCHAR(120),
    certification_number VARCHAR(60),
    issue_date DATE,
    expiry_date DATE,
    status VARCHAR(20),
    document_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS facility_commission_log (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    transaction_type VARCHAR(40),
    transaction_id INTEGER,
    transaction_amount_ugx DOUBLE PRECISION NOT NULL,
    commission_pct DOUBLE PRECISION NOT NULL,
    commission_amount_ugx DOUBLE PRECISION NOT NULL,
    payment_status VARCHAR(20),
    payment_date DATE,
    payment_ref VARCHAR(120),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS facility_locations (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    location_name VARCHAR(120),
    is_main_branch BOOLEAN DEFAULT FALSE,
    address TEXT,
    district VARCHAR(60),
    region VARCHAR(60),
    gps_lat DOUBLE PRECISION,
    gps_lng DOUBLE PRECISION,
    phone VARCHAR(20),
    email VARCHAR(120),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS facility_operating_hours (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    opens_at TIME,
    closes_at TIME,
    is_24_hours BOOLEAN DEFAULT FALSE,
    is_closed BOOLEAN DEFAULT FALSE,
    notes TEXT,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE,
    UNIQUE(facility_id, day_of_week)
);
CREATE TABLE IF NOT EXISTS facility_partners (
    id SERIAL PRIMARY KEY,
    name TEXT,
    type NUMERIC,
    location_gps DOUBLE PRECISION,
    commision_rate DOUBLE PRECISION,
    contract_id INTEGER REFERENCES partner_contracts(id),
    is_contracted BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP
);
CREATE TABLE IF NOT EXISTS facility_payment_acceptance (
  id SERIAL PRIMARY KEY,
  facility_id INTEGER NOT NULL UNIQUE,
  accepts_afya_points BOOLEAN DEFAULT TRUE,
  accepts_labor_hours BOOLEAN DEFAULT TRUE,
  accepts_barter_goods BOOLEAN DEFAULT FALSE,
  accepts_barter_services BOOLEAN DEFAULT TRUE,
  preferred_labor_skills TEXT,
  max_labor_hours_per_month DOUBLE PRECISION,
  seeking_goods_categories TEXT,
  seeking_services_categories TEXT,
  max_afya_points_per_service INTEGER,
  min_fiat_percentage DOUBLE PRECISION DEFAULT 20.0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS facility_ratings (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    overall_rating INTEGER NOT NULL,
    cleanliness_rating INTEGER,
    staff_friendliness_rating INTEGER,
    wait_time_rating INTEGER,
    value_for_money_rating INTEGER,
    review_text TEXT,
    would_recommend BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS facility_services (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    service_name VARCHAR(120) NOT NULL,
    service_type VARCHAR(40),
    description TEXT,
    price_ugx DOUBLE PRECISION,
    currency_code VARCHAR(5) DEFAULT 'UGX',
    base_price_ugx DOUBLE PRECISION,
    auto_convert_pricing BOOLEAN DEFAULT TRUE,
    duration_minutes INTEGER,
    afya_points_earned INTEGER,
    requires_appointment BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS facility_staff_mapping (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    staff_id INTEGER NOT NULL,
    role_at_facility VARCHAR(60),
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES medical_staff(id) ON DELETE CASCADE,
    UNIQUE(facility_id, staff_id)
);
CREATE TABLE IF NOT EXISTS fasting_blood_sugar_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS fee_structure_config (
  id SERIAL PRIMARY KEY,
  fee_type VARCHAR(60) NOT NULL UNIQUE,
  base_fee_pct DOUBLE PRECISION NOT NULL,
  base_fee_ap INTEGER,
  base_fee_ugx DOUBLE PRECISION,
  platform_share_pct DOUBLE PRECISION DEFAULT 100.0,
  partner_share_pct DOUBLE PRECISION DEFAULT 0.0,
  worker_share_pct DOUBLE PRECISION DEFAULT 0.0,
  min_fee_ugx DOUBLE PRECISION,
  max_fee_ugx DOUBLE PRECISION,
  applies_to VARCHAR(60),
  charge_method VARCHAR(40) DEFAULT 'percentage',
  waive_for_essential_medicines BOOLEAN DEFAULT FALSE,
  waive_for_vulnerable_populations BOOLEAN DEFAULT FALSE,
  waive_for_micro_transactions BOOLEAN DEFAULT FALSE,
  waive_for_social_good BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  is_promotional BOOLEAN DEFAULT FALSE,
  promotional_start_date DATE,
  promotional_end_date DATE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS fee_waiver_log (
  id SERIAL PRIMARY KEY,
  transaction_id INTEGER NOT NULL,
  transaction_type VARCHAR(40) NOT NULL,
  user_id INTEGER NOT NULL,
  original_fee_ugx DOUBLE PRECISION NOT NULL,
  waived_fee_ugx DOUBLE PRECISION NOT NULL,
  waiver_reason VARCHAR(60) NOT NULL,
  is_social_good BOOLEAN DEFAULT TRUE,
  social_good_category VARCHAR(60),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS follow_up_reminders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    consultation_id INTEGER,
    treatment_plan_id INTEGER,
    reminder_type VARCHAR(40),
    reminder_date DATE NOT NULL,
    reminder_time TIME,
    message TEXT,
    priority VARCHAR(20),
    status VARCHAR(20),
    sent_at TIMESTAMP,
    acknowledged_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE SET NULL,
    FOREIGN KEY (treatment_plan_id) REFERENCES treatment_plans(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS food_cooking_method_retention (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS food_nutrients (food_id INTEGER, nutrient_id INTEGER, amount_per_100g DOUBLE PRECISION, PRIMARY KEY (food_id, nutrient_id));
CREATE TABLE IF NOT EXISTS food_safety_hazards (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS foods (id SERIAL PRIMARY KEY, name VARCHAR(200) NOT NULL, local_name VARCHAR(200), category VARCHAR(100), glycemic_index DOUBLE PRECISION, is_local BOOLEAN DEFAULT TRUE, is_verified BOOLEAN DEFAULT FALSE, region_code VARCHAR(10));
CREATE TABLE IF NOT EXISTS food_submissions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS fraud_detection_alerts (
  id SERIAL PRIMARY KEY,
  alert_type VARCHAR(60) NOT NULL,
  user_id INTEGER,
  transaction_id INTEGER,
  transaction_type VARCHAR(40),
  risk_score DOUBLE PRECISION NOT NULL,
  risk_level VARCHAR(40),
  fraud_indicators TEXT,
  fraud_indicator_count INTEGER DEFAULT 0,
  alert_description TEXT NOT NULL,
  alert_details TEXT,
  auto_action_taken VARCHAR(60),
  auto_action_at TIMESTAMP,
  requires_manual_review BOOLEAN DEFAULT FALSE,
  reviewed_by INTEGER,
  review_status VARCHAR(40),
  review_notes TEXT,
  reviewed_at TIMESTAMP,
  is_resolved BOOLEAN DEFAULT FALSE,
  resolution_action VARCHAR(60),
  resolved_by INTEGER,
  resolved_at TIMESTAMP,
  detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (reviewed_by) REFERENCES medical_staff(id) ON DELETE SET NULL,
  FOREIGN KEY (resolved_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS fraud_detection_rules (
  id SERIAL PRIMARY KEY,
  rule_name VARCHAR(200) NOT NULL UNIQUE,
  rule_code VARCHAR(60) NOT NULL UNIQUE,
  rule_category VARCHAR(60) NOT NULL,
  rule_condition TEXT NOT NULL,
  risk_score_weight DOUBLE PRECISION DEFAULT 0.1,
  alert_threshold DOUBLE PRECISION DEFAULT 0.7,
  auto_action VARCHAR(60),
  is_active BOOLEAN DEFAULT TRUE,
  is_ml_based BOOLEAN DEFAULT FALSE,
  description TEXT,
  created_by INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS game_character_classes (id SERIAL PRIMARY KEY, class_name VARCHAR(50) NOT NULL, focus_area VARCHAR(50), xp_multiplier DOUBLE PRECISION, base_hp INTEGER, starting_skills TEXT, description TEXT, icon_ref TEXT);
CREATE TABLE IF NOT EXISTS game_quests (id SERIAL PRIMARY KEY, name VARCHAR(100), quest_type VARCHAR(20), description TEXT, xp_reward INTEGER, points_reward INTEGER, duration_days INTEGER, condition_focus TEXT, min_level_required INTEGER);
CREATE TABLE IF NOT EXISTS game_sprites (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS glucose_monitoring (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    glucose_mg_dl DOUBLE PRECISION NOT NULL,
    measurement_context VARCHAR(30),
    meal_id INTEGER,
    hours_since_meal DOUBLE PRECISION,
    insulin_dose_units DOUBLE PRECISION,
    medication_taken BOOLEAN,
    physical_activity TEXT,
    symptoms TEXT,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS glycemic_load_index (
    id SERIAL PRIMARY KEY,
    food_id INTEGER NOT NULL,
    serving_grams INTEGER NOT NULL,
    glycemic_index INTEGER,
    available_carb_g DOUBLE PRECISION,
    glycemic_load DOUBLE PRECISION,
    gl_category VARCHAR(10),
    reference_food VARCHAR(60),
    data_source VARCHAR(100),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS group_memberships (
    id SERIAL PRIMARY KEY,
    group_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    role VARCHAR(20),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    muted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (group_id) REFERENCES social_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(group_id, user_id)
);
CREATE TABLE IF NOT EXISTS group_moderation_logs (
    id SERIAL PRIMARY KEY,
    group_id INTEGER NOT NULL,
    moderator_user_id INTEGER NOT NULL,
    action_type VARCHAR(40),
    target_user_id INTEGER,
    target_post_id INTEGER,
    target_comment_id INTEGER,
    reason TEXT,
    duration_days INTEGER,
    action_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES social_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (moderator_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (target_post_id) REFERENCES social_posts(id) ON DELETE SET NULL,
    FOREIGN KEY (target_comment_id) REFERENCES post_comments(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS guilds (
    id INTEGER PRIMARY KEY,
    guild_name VARCHAR(80) NOT NULL UNIQUE,
    description TEXT,
    guild_tag VARCHAR(10),
    leader_id INTEGER NOT NULL REFERENCES users(id),
    co_leader_id INTEGER REFERENCES users(id),
    guild_level INTEGER DEFAULT 1,
    guild_xp INTEGER DEFAULT 0,
    max_members INTEGER DEFAULT 30,
    current_member_count INTEGER DEFAULT 1,
    condition_focus VARCHAR(60),
    min_subscription_tier_join INTEGER DEFAULT 2,
    min_subscription_tier_create INTEGER DEFAULT 3,
    icon VARCHAR(60),
    banner_color VARCHAR(10),
    is_public BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS guild_members (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    guild_id INTEGER NOT NULL REFERENCES guilds(id),
    rank_id INTEGER NOT NULL DEFAULT 1,
    contribution_xp INTEGER DEFAULT 0,
    challenges_completed INTEGER DEFAULT 0,
    weekly_activity_score DOUBLE PRECISION DEFAULT 0,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(user_id, guild_id)
);
CREATE TABLE IF NOT EXISTS guild_ranks (
    id INTEGER PRIMARY KEY,
    rank_name VARCHAR(40) NOT NULL UNIQUE,
    rank_level INTEGER NOT NULL UNIQUE,
    permissions TEXT,
    min_contribution_xp INTEGER DEFAULT 0,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS guild_challenges (
    id INTEGER PRIMARY KEY,
    guild_id INTEGER NOT NULL REFERENCES guilds(id),
    challenge_name VARCHAR(120) NOT NULL,
    description TEXT,
    challenge_type VARCHAR(40) NOT NULL,
    target_value DOUBLE PRECISION NOT NULL,
    current_value DOUBLE PRECISION DEFAULT 0,
    condition_focus VARCHAR(60),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    xp_reward_per_member INTEGER DEFAULT 100,
    ap_reward_per_member INTEGER DEFAULT 25,
    guild_xp_reward INTEGER DEFAULT 500,
    min_participants INTEGER DEFAULT 5,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);
CREATE TABLE IF NOT EXISTS guild_challenge_progress (
    id INTEGER PRIMARY KEY,
    challenge_id INTEGER NOT NULL REFERENCES guild_challenges(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    contribution_value DOUBLE PRECISION DEFAULT 0,
    contribution_rank INTEGER,
    last_contribution_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(challenge_id, user_id)
);
CREATE TABLE IF NOT EXISTS guild_chat_messages (
    id INTEGER PRIMARY KEY,
    guild_id INTEGER NOT NULL REFERENCES guilds(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    message_text TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text',
    is_pinned BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS guild_level_requirements (
    id INTEGER PRIMARY KEY,
    guild_level INTEGER NOT NULL UNIQUE,
    xp_required INTEGER NOT NULL,
    max_members_unlock INTEGER NOT NULL,
    perk_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS guild_perks (
    id INTEGER PRIMARY KEY,
    perk_name VARCHAR(80) NOT NULL,
    perk_type VARCHAR(40) NOT NULL,
    perk_value DOUBLE PRECISION,
    required_guild_level INTEGER NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS hba1c_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS health_assessments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    assessment_date DATE NOT NULL,
    assessment_type VARCHAR(40),
    overall_health_score DOUBLE PRECISION,
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
CREATE TABLE IF NOT EXISTS health_endorsements (
    id SERIAL PRIMARY KEY,
    from_user_id INTEGER NOT NULL,
    to_user_id INTEGER NOT NULL,
    endorsement_type VARCHAR(40),
    message TEXT,
    related_post_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (related_post_id) REFERENCES social_posts(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS health_rules (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS health_scores (id SERIAL PRIMARY KEY, user_id INTEGER NOT NULL, kidney_score DOUBLE PRECISION, diabetes_score DOUBLE PRECISION, bp_score DOUBLE PRECISION, metabolic_score DOUBLE PRECISION, longevity_score DOUBLE PRECISION, date DATE DEFAULT CURRENT_DATE, FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS heart_rate_variability (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    hrv_ms DOUBLE PRECISION NOT NULL,
    measurement_type VARCHAR(20),
    resting_hr INTEGER,
    recovery_score DOUBLE PRECISION,
    stress_level VARCHAR(20),
    source VARCHAR(40),
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS hybrid_payment_approval_queue (
  id SERIAL PRIMARY KEY,
  unified_payment_id INTEGER NOT NULL,
  transaction_type VARCHAR(40),
  transaction_id INTEGER,
  approver_type VARCHAR(40),
  approver_id INTEGER,
  total_amount_ugx DOUBLE PRECISION,
  fiat_amount_ugx DOUBLE PRECISION,
  fiat_percentage DOUBLE PRECISION,
  non_fiat_components TEXT,
  approval_status VARCHAR(40) DEFAULT 'pending',
  approved_by INTEGER,
  approved_at TIMESTAMP,
  rejected_at TIMESTAMP,
  rejection_reason TEXT,
  expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '24 hours'),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (unified_payment_id) REFERENCES unified_payment_ledger(id) ON DELETE CASCADE,
  FOREIGN KEY (approved_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS hybrid_payment_details (
  id SERIAL PRIMARY KEY,
  unified_payment_id INTEGER NOT NULL,
  component_type VARCHAR(40) NOT NULL,
  component_amount DOUBLE PRECISION NOT NULL,
  component_value_ugx DOUBLE PRECISION NOT NULL,
  component_percentage DOUBLE PRECISION,
  labor_service_id INTEGER,
  labor_booking_id INTEGER,
  hours_committed DOUBLE PRECISION,
  hourly_rate_ap INTEGER,
  barter_item_type VARCHAR(40),
  barter_item_id INTEGER,
  barter_exchange_id INTEGER,
  component_status VARCHAR(40) DEFAULT 'pending',
  completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (unified_payment_id) REFERENCES unified_payment_ledger(id) ON DELETE CASCADE,
  FOREIGN KEY (labor_service_id) REFERENCES labor_services_registry(id) ON DELETE SET NULL,
  FOREIGN KEY (labor_booking_id) REFERENCES labor_booking_requests(id) ON DELETE SET NULL,
  FOREIGN KEY (barter_exchange_id) REFERENCES barter_exchange_transactions(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS imaging_results (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    consultation_id INTEGER,
    imaging_type VARCHAR(40),
    body_part VARCHAR(60),
    indication TEXT,
    findings TEXT,
    impression TEXT,
    recommendations TEXT,
    image_urls TEXT,
    performed_at TIMESTAMP,
    facility_id INTEGER,
    radiologist_name VARCHAR(120),
    is_normal BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE SET NULL,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS informed_consent_records (
    id SERIAL PRIMARY KEY,
    study_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    consent_version VARCHAR(20),
    consented_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    signature_ref TEXT,
    UNIQUE(study_id, user_id),
    FOREIGN KEY (study_id) REFERENCES research_studies(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS ingredient_substitutions (
    id SERIAL PRIMARY KEY,
    original_food_id INTEGER NOT NULL,
    substitute_food_id INTEGER NOT NULL,
    substitution_ratio DOUBLE PRECISION DEFAULT 1.0,
    reason VARCHAR(40),
    nutrition_impact TEXT,
    taste_impact TEXT,
    recommended BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (original_food_id) REFERENCES foods(id) ON DELETE CASCADE,
    FOREIGN KEY (substitute_food_id) REFERENCES foods(id) ON DELETE CASCADE,
    UNIQUE(original_food_id, substitute_food_id)
);
CREATE TABLE IF NOT EXISTS kitchen_physics (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS labor_booking_requests (
  id SERIAL PRIMARY KEY,
  requester_user_id INTEGER NOT NULL,
  labor_service_id INTEGER NOT NULL,
  provider_user_id INTEGER NOT NULL,
  hours_requested DOUBLE PRECISION NOT NULL,
  hourly_rate_ap INTEGER NOT NULL,
  total_cost_ap INTEGER NOT NULL,
  booking_date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  work_location_address TEXT,
  work_location_gps_lat DOUBLE PRECISION,
  work_location_gps_lng DOUBLE PRECISION,
  work_description TEXT,
  payment_method VARCHAR(40),
  payment_breakdown TEXT,
  status VARCHAR(40) DEFAULT 'pending',
  requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  accepted_at TIMESTAMP,
  confirmed_at TIMESTAMP,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  cancelled_at TIMESTAMP,
  cancellation_reason TEXT,
  verification_required BOOLEAN DEFAULT TRUE,
  verified_by INTEGER,
  verification_method VARCHAR(40),
  verification_photos TEXT,
  verified_at TIMESTAMP,
  requester_rating INTEGER,
  requester_review TEXT,
  provider_rating INTEGER,
  provider_review TEXT,
  transaction_fee_pct DOUBLE PRECISION DEFAULT 5.0,
  transaction_fee_ap INTEGER,
  platform_revenue_ugx DOUBLE PRECISION,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (requester_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (labor_service_id) REFERENCES labor_services_registry(id) ON DELETE CASCADE,
  FOREIGN KEY (provider_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS labor_currency_conversion (
  id SERIAL PRIMARY KEY,
  skill_category_id INTEGER NOT NULL,
  country_code VARCHAR(5) NOT NULL,
  proficiency_level VARCHAR(40) NOT NULL,
  base_hourly_rate_ap INTEGER NOT NULL,
  base_hourly_rate_ugx DOUBLE PRECISION NOT NULL,
  base_hourly_rate_local_currency DOUBLE PRECISION,
  proficiency_multiplier DOUBLE PRECISION NOT NULL,
  country_cost_of_living_multiplier DOUBLE PRECISION NOT NULL,
  demand_surge_multiplier DOUBLE PRECISION DEFAULT 1.0,
  final_hourly_rate_ap INTEGER,
  final_hourly_rate_ugx DOUBLE PRECISION,
  final_hourly_rate_local_currency DOUBLE PRECISION,
  meets_minimum_wage BOOLEAN DEFAULT TRUE,
  minimum_wage_local_currency DOUBLE PRECISION,
  effective_date DATE DEFAULT CURRENT_DATE,
  expires_at DATE,
  is_active BOOLEAN DEFAULT TRUE,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (skill_category_id) REFERENCES labor_skill_categories(id) ON DELETE CASCADE,
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code),
  UNIQUE (skill_category_id, country_code, proficiency_level)
);
CREATE TABLE IF NOT EXISTS labor_demand_surge (
  id SERIAL PRIMARY KEY,
  skill_category_id INTEGER NOT NULL,
  country_code VARCHAR(5),
  district VARCHAR(100),
  demand_level VARCHAR(40),
  surge_multiplier DOUBLE PRECISION NOT NULL,
  active_requests INTEGER,
  active_providers INTEGER,
  supply_demand_ratio DOUBLE PRECISION,
  calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days'),
  FOREIGN KEY (skill_category_id) REFERENCES labor_skill_categories(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS lab_orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    consultation_id INTEGER,
    facility_id INTEGER,
    test_ids TEXT,
    order_date DATE NOT NULL,
    collection_date DATE,
    result_date DATE,
    status VARCHAR(20),
    priority VARCHAR(20),
    fasting_status BOOLEAN,
    total_cost_ugx DOUBLE PRECISION,
    payment_status VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE SET NULL,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS labor_earnings_summary (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  service_type VARCHAR(60),
  month DATE NOT NULL,
  total_hours_worked DOUBLE PRECISION DEFAULT 0,
  total_earned_ap INTEGER DEFAULT 0,
  total_earned_ugx DOUBLE PRECISION DEFAULT 0,
  jobs_completed INTEGER DEFAULT 0,
  avg_hourly_rate_ap INTEGER,
  verified_hours DOUBLE PRECISION DEFAULT 0,
  unverified_hours DOUBLE PRECISION DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (user_id, service_type, month)
);
CREATE TABLE IF NOT EXISTS labor_hour_ledger (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  labor_service_id INTEGER NOT NULL,
  labor_booking_id INTEGER,
  service_type VARCHAR(60) NOT NULL,
  hours_worked DOUBLE PRECISION NOT NULL,
  hourly_rate_ap INTEGER NOT NULL,
  total_earned_ap INTEGER NOT NULL,
  total_earned_ugx DOUBLE PRECISION,
  work_date DATE NOT NULL,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  actual_duration_hours DOUBLE PRECISION,
  client_user_id INTEGER,
  client_facility_id INTEGER,
  work_location_address TEXT,
  work_location_gps_lat DOUBLE PRECISION,
  work_location_gps_lng DOUBLE PRECISION,
  work_description TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  verified_by INTEGER,
  verification_method VARCHAR(40),
  verification_notes TEXT,
  verification_photos TEXT,
  verified_at TIMESTAMP,
  checkin_gps_lat DOUBLE PRECISION,
  checkin_gps_lng DOUBLE PRECISION,
  checkin_timestamp TIMESTAMP,
  checkout_gps_lat DOUBLE PRECISION,
  checkout_gps_lng DOUBLE PRECISION,
  checkout_timestamp TIMESTAMP,
  gps_verification_passed BOOLEAN,
  payment_status VARCHAR(40) DEFAULT 'pending',
  payment_method VARCHAR(40),
  payment_breakdown TEXT,
  paid_at TIMESTAMP,
  transaction_fee_pct DOUBLE PRECISION DEFAULT 5.0,
  transaction_fee_ap INTEGER,
  net_earned_ap INTEGER,
  platform_revenue_ugx DOUBLE PRECISION,
  dispute_raised BOOLEAN DEFAULT FALSE,
  dispute_reason TEXT,
  dispute_raised_by INTEGER,
  dispute_resolved_at TIMESTAMP,
  is_social_good BOOLEAN DEFAULT FALSE,
  social_good_reason TEXT,
  fee_waived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (labor_service_id) REFERENCES labor_services_registry(id) ON DELETE CASCADE,
  FOREIGN KEY (labor_booking_id) REFERENCES labor_booking_requests(id) ON DELETE SET NULL,
  FOREIGN KEY (client_user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (client_facility_id) REFERENCES facility_partners(id) ON DELETE SET NULL,
  FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (dispute_raised_by) REFERENCES users(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS labor_no_show_log (
  id SERIAL PRIMARY KEY,
  labor_booking_id INTEGER NOT NULL,
  provider_user_id INTEGER NOT NULL,
  requester_user_id INTEGER NOT NULL,
  scheduled_date DATE NOT NULL,
  no_show_type VARCHAR(40),
  reported_by INTEGER NOT NULL,
  report_notes TEXT,
  penalty_applied BOOLEAN DEFAULT FALSE,
  penalty_amount_ap INTEGER,
  is_legitimate_excuse BOOLEAN,
  excuse_notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (labor_booking_id) REFERENCES labor_booking_requests(id) ON DELETE CASCADE,
  FOREIGN KEY (provider_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (requester_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (reported_by) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS labor_services_registry (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  service_type VARCHAR(60) NOT NULL,
  service_name VARCHAR(200) NOT NULL,
  service_description TEXT,
  proficiency_level VARCHAR(40) DEFAULT 'intermediate',
  years_experience INTEGER,
  certifications TEXT,
  portfolio_images TEXT,
  hourly_rate_afya_points INTEGER NOT NULL,
  hourly_rate_ugx DOUBLE PRECISION,
  min_hours INTEGER DEFAULT 1,
  max_hours_per_week INTEGER DEFAULT 40,
  rate_negotiable BOOLEAN DEFAULT TRUE,
  is_available BOOLEAN DEFAULT TRUE,
  availability_schedule TEXT,
  advance_notice_days INTEGER DEFAULT 1,
  location_district VARCHAR(100),
  location_gps_lat DOUBLE PRECISION,
  location_gps_lng DOUBLE PRECISION,
  can_travel BOOLEAN DEFAULT TRUE,
  travel_radius_km INTEGER DEFAULT 20,
  rating_avg DOUBLE PRECISION DEFAULT 0,
  rating_count INTEGER DEFAULT 0,
  hours_completed INTEGER DEFAULT 0,
  jobs_completed INTEGER DEFAULT 0,
  reliability_score DOUBLE PRECISION DEFAULT 0.5,
  no_show_count INTEGER DEFAULT 0,
  is_verified_provider BOOLEAN DEFAULT FALSE,
  verified_by INTEGER,
  verified_at TIMESTAMP,
  background_check_status VARCHAR(40),
  background_check_date DATE,
  preferred_payment_method VARCHAR(40) DEFAULT 'afya_points',
  accepts_barter BOOLEAN DEFAULT TRUE,
  seeking_categories TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verified_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS labor_skill_categories (
  id SERIAL PRIMARY KEY,
  category_name VARCHAR(60) NOT NULL UNIQUE,
  base_hourly_rate_ap INTEGER NOT NULL,
  base_hourly_rate_ugx DOUBLE PRECISION NOT NULL,
  demand_level VARCHAR(40) DEFAULT 'medium',
  demand_multiplier DOUBLE PRECISION DEFAULT 1.0,
  description TEXT,
  required_certification BOOLEAN DEFAULT FALSE,
  physical_intensity VARCHAR(40),
  skill_tier INTEGER DEFAULT 2,
  is_active BOOLEAN DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS labor_verification_queue (
  id SERIAL PRIMARY KEY,
  labor_hour_ledger_id INTEGER NOT NULL,
  verification_type VARCHAR(40),
  assigned_to INTEGER,
  priority VARCHAR(40) DEFAULT 'normal',
  status VARCHAR(40) DEFAULT 'pending',
  rejection_reason TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  FOREIGN KEY (labor_hour_ledger_id) REFERENCES labor_hour_ledger(id) ON DELETE CASCADE,
  FOREIGN KEY (assigned_to) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS lab_reference_ranges (
    id SERIAL PRIMARY KEY,
    test_name VARCHAR(120) NOT NULL,
    age_min INTEGER,
    age_max INTEGER,
    gender VARCHAR(20),
    range_min DOUBLE PRECISION,
    range_max DOUBLE PRECISION,
    unit VARCHAR(40),
    interpretation_low TEXT,
    interpretation_normal TEXT,
    interpretation_high TEXT,
    source VARCHAR(120),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS lab_test_catalog (
    id SERIAL PRIMARY KEY,
    test_name VARCHAR(120) NOT NULL,
    test_code VARCHAR(40) UNIQUE,
    test_category VARCHAR(60),
    description TEXT,
    specimen_type VARCHAR(60),
    specimen_volume VARCHAR(40),
    fasting_required BOOLEAN DEFAULT FALSE,
    turnaround_time_hours INTEGER,
    typical_price_ugx DOUBLE PRECISION,
    reference_ranges TEXT,
    clinical_significance TEXT,
    preparation_instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS leaderboard_rewards (
  id SERIAL PRIMARY KEY,
  leaderboard_name VARCHAR(60) NOT NULL,
  period VARCHAR(20) DEFAULT 'monthly',
  rank_min INTEGER NOT NULL,
  rank_max INTEGER NOT NULL,
  afya_points_reward INTEGER DEFAULT 0,
  premium_days INTEGER DEFAULT 0,
  description TEXT
);
CREATE TABLE IF NOT EXISTS leaderboards (id SERIAL PRIMARY KEY, competition_id INTEGER, rank INTEGER);
CREATE TABLE IF NOT EXISTS legal_terms_versions (
    id SERIAL PRIMARY KEY,
    version VARCHAR(20) UNIQUE NOT NULL,
    terms_text_ref TEXT,
    summary TEXT,
    effective_from DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS login_streak_milestones (
    id INTEGER PRIMARY KEY,
    streak_days INTEGER NOT NULL UNIQUE,
    milestone_name VARCHAR(80) NOT NULL,
    reward_type VARCHAR(40) NOT NULL,
    reward_value INTEGER NOT NULL,
    subscriber_reward_type VARCHAR(40),
    subscriber_reward_value INTEGER,
    title_reward VARCHAR(80),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS longitudinal_outcomes (
    id SERIAL PRIMARY KEY,
    study_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    outcome_metric VARCHAR(60),
    baseline_value DOUBLE PRECISION,
    current_value DOUBLE PRECISION,
    pct_change DOUBLE PRECISION,
    measured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (study_id) REFERENCES research_studies(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS match_score_weights (
  id SERIAL PRIMARY KEY,
  weight_name VARCHAR(60) NOT NULL UNIQUE,
  weight_value DOUBLE PRECISION NOT NULL CHECK (weight_value >= 0 AND weight_value <= 1),
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS meal_components (
    id SERIAL PRIMARY KEY,
    meal_id INTEGER NOT NULL,
    food_id INTEGER NOT NULL,
    quantity_grams DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
    FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS meal_logging_compliance (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_logging_requirements (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_logging_warnings (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS meal_nutrition_calculations (
    id SERIAL PRIMARY KEY,
    meal_id INTEGER NOT NULL UNIQUE,
    calculation_method VARCHAR(50) NOT NULL,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    calculation_version VARCHAR(20) DEFAULT '1.0',
    raw_energy_kcal DOUBLE PRECISION,
    raw_protein_g DOUBLE PRECISION,
    raw_carbs_g DOUBLE PRECISION,
    raw_fat_g DOUBLE PRECISION,
    raw_fiber_g DOUBLE PRECISION,
    raw_sugar_g DOUBLE PRECISION,
    raw_potassium_mg DOUBLE PRECISION,
    raw_sodium_mg DOUBLE PRECISION,
    raw_calcium_mg DOUBLE PRECISION,
    raw_iron_mg DOUBLE PRECISION,
    raw_magnesium_mg DOUBLE PRECISION,
    raw_phosphorus_mg DOUBLE PRECISION,
    raw_zinc_mg DOUBLE PRECISION,
    raw_vitamin_a_mcg DOUBLE PRECISION,
    raw_vitamin_c_mg DOUBLE PRECISION,
    raw_vitamin_d_mcg DOUBLE PRECISION,
    raw_vitamin_e_mg DOUBLE PRECISION,
    raw_folate_mcg DOUBLE PRECISION,
    raw_vitamin_b12_mcg DOUBLE PRECISION,
    adjusted_energy_kcal DOUBLE PRECISION,
    adjusted_protein_g DOUBLE PRECISION,
    adjusted_carbs_g DOUBLE PRECISION,
    adjusted_fat_g DOUBLE PRECISION,
    adjusted_fiber_g DOUBLE PRECISION,
    adjusted_sugar_g DOUBLE PRECISION,
    adjusted_potassium_mg DOUBLE PRECISION,
    adjusted_sodium_mg DOUBLE PRECISION,
    adjusted_calcium_mg DOUBLE PRECISION,
    adjusted_iron_mg DOUBLE PRECISION,
    adjusted_magnesium_mg DOUBLE PRECISION,
    adjusted_phosphorus_mg DOUBLE PRECISION,
    adjusted_zinc_mg DOUBLE PRECISION,
    adjusted_vitamin_a_mcg DOUBLE PRECISION,
    adjusted_vitamin_c_mg DOUBLE PRECISION,
    adjusted_vitamin_d_mcg DOUBLE PRECISION,
    adjusted_vitamin_e_mg DOUBLE PRECISION,
    adjusted_folate_mcg DOUBLE PRECISION,
    adjusted_vitamin_b12_mcg DOUBLE PRECISION,
    cooking_method_id INTEGER,
    total_weight_raw_g DOUBLE PRECISION,
    total_weight_cooked_g DOUBLE PRECISION,
    weight_yield_factor DOUBLE PRECISION,
    average_retention_factor DOUBLE PRECISION,
    glycemic_load DOUBLE PRECISION,
    glycemic_load_category VARCHAR(20),
    pral_value DOUBLE PRECISION,
    pral_category VARCHAR(20),
    sodium_potassium_ratio DOUBLE PRECISION,
    calculation_warnings TEXT,
    data_quality_score DOUBLE PRECISION,
    missing_nutrients TEXT,
    estimated_nutrients TEXT,
    number_of_components INTEGER,
    has_custom_portions BOOLEAN DEFAULT FALSE,
    portion_adjustment_applied BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (meal_id) REFERENCES meals(id),
    FOREIGN KEY (cooking_method_id) REFERENCES cooking_methods(id),
    CHECK (data_quality_score BETWEEN 0.0 AND 1.0)
);
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
CREATE TABLE IF NOT EXISTS meal_planner_calendar (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    plan_date DATE NOT NULL,
    meal_type VARCHAR(30) NOT NULL,
    recipe_id INTEGER,
    meal_template_id INTEGER,
    planned_calories INTEGER,
    preparation_status VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE SET NULL,
    FOREIGN KEY (meal_template_id) REFERENCES meal_templates(id) ON DELETE SET NULL,
    UNIQUE(user_id, plan_date, meal_type)
);
CREATE TABLE IF NOT EXISTS meal_portion_adjustments (id SERIAL PRIMARY KEY);
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
CREATE TABLE IF NOT EXISTS meal_sharing (
    id SERIAL PRIMARY KEY,
    meal_id INTEGER NOT NULL,
    shared_by_user_id INTEGER NOT NULL,
    shared_with_user_id INTEGER,
    share_type VARCHAR(20),
    message TEXT,
    view_count INTEGER DEFAULT 0,
    shared_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
    FOREIGN KEY (shared_by_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (shared_with_user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS meals (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    meal_type VARCHAR(30),
    meal_name VARCHAR(200),
    meal_time TIMESTAMP,
    meal_source VARCHAR(50) DEFAULT 'component_assembly',
    recipe_id INTEGER,
    portion_size_pct DOUBLE PRECISION DEFAULT 100.0,
    cooking_method_id INTEGER,
    preparation_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS meal_tags (
    id SERIAL PRIMARY KEY,
    tag_name VARCHAR(60) NOT NULL UNIQUE,
    tag_category VARCHAR(40),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS meal_templates (
    id SERIAL PRIMARY KEY,
    template_name VARCHAR(120) NOT NULL,
    meal_type VARCHAR(30),
    description TEXT,
    target_calories INTEGER,
    target_protein_g INTEGER,
    target_carbs_g INTEGER,
    target_fat_g INTEGER,
    diet_type VARCHAR(40),
    health_focus TEXT,
    created_by_user_id INTEGER,
    is_public BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS medical_conditions (
    id SERIAL PRIMARY KEY,
    condition_name VARCHAR(120) NOT NULL UNIQUE,
    icd_10_code VARCHAR(20),
    category VARCHAR(60),
    description TEXT,
    symptoms TEXT,
    risk_factors TEXT,
    typical_treatments TEXT,
    prognosis TEXT,
    is_chronic BOOLEAN DEFAULT FALSE,
    requires_specialist BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS medical_specialties (
    id INTEGER PRIMARY KEY,
    specialty_name VARCHAR(80) NOT NULL UNIQUE,
    category VARCHAR(40) NOT NULL,
    description TEXT,
    avg_consultation_fee_ugx DOUBLE PRECISION,
    common_conditions TEXT,
    icon VARCHAR(60),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS medical_staff (id SERIAL PRIMARY KEY, user_id INTEGER, staff_role VARCHAR(50), is_active BOOLEAN DEFAULT TRUE, FOREIGN KEY (user_id) REFERENCES users(id));
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
CREATE TABLE IF NOT EXISTS medication_schedules (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    medication_id INTEGER NOT NULL,
    prescription_id INTEGER,
    schedule_type VARCHAR(30) NOT NULL,
    times_per_day INTEGER,
    scheduled_times TEXT,
    dose_amount VARCHAR(60),
    meal_relation VARCHAR(20),
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    reminder_enabled BOOLEAN DEFAULT TRUE,
    reminder_minutes_before INTEGER DEFAULT 15,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE,
    FOREIGN KEY (prescription_id) REFERENCES digital_prescriptions(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS medication_side_effects (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    medication_id INTEGER NOT NULL,
    reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    side_effect VARCHAR(100) NOT NULL,
    severity VARCHAR(20),
    onset_date DATE,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_date DATE,
    action_taken VARCHAR(40),
    reported_to_doctor BOOLEAN DEFAULT FALSE,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS medications (
    id SERIAL PRIMARY KEY,
    generic_name VARCHAR(200) NOT NULL,
    brand_names TEXT,
    active_ingredient VARCHAR(200) NOT NULL,
    drug_class VARCHAR(100),
    drug_category_id INTEGER,
    therapeutic_category VARCHAR(100),
    dosage_forms TEXT,
    standard_doses TEXT,
    available_strengths TEXT,
    requires_prescription BOOLEAN DEFAULT TRUE,
    is_controlled_substance BOOLEAN DEFAULT FALSE,
    controlled_schedule VARCHAR(10),
    is_essential_medicine BOOLEAN DEFAULT FALSE,
    primary_indication TEXT,
    secondary_indications TEXT,
    contraindications TEXT,
    pregnancy_category VARCHAR(10),
    common_side_effects TEXT,
    serious_side_effects TEXT,
    black_box_warnings TEXT,
    drug_interactions_known TEXT,
    typical_dosing_frequency VARCHAR(100),
    administration_instructions TEXT,
    maximum_daily_dose VARCHAR(50),
    data_source VARCHAR(200),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (drug_category_id) REFERENCES drug_categories(id)
);
CREATE TABLE IF NOT EXISTS medication_storage_reqs (
    id SERIAL PRIMARY KEY,
    medication_id INTEGER NOT NULL,
    storage_temp_min_c DOUBLE PRECISION,
    storage_temp_max_c DOUBLE PRECISION,
    humidity_controlled BOOLEAN DEFAULT FALSE,
    light_sensitive BOOLEAN DEFAULT FALSE,
    refrigeration_required BOOLEAN DEFAULT FALSE,
    freezing_allowed BOOLEAN DEFAULT FALSE,
    special_container TEXT,
    special_instructions TEXT,
    stability_after_opening_days INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS medication_submission_review_checklist (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS medication_submissions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS menstrual_cycle_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    cycle_start_date DATE NOT NULL,
    cycle_end_date DATE,
    cycle_length_days INTEGER,
    period_length_days INTEGER,
    flow_intensity VARCHAR(20),
    symptoms TEXT,
    basal_temp_avg DOUBLE PRECISION,
    ovulation_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS mentor_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    mentor_type VARCHAR(40),
    specialization TEXT,
    bio TEXT,
    years_experience INTEGER,
    certification VARCHAR(200),
    max_mentees INTEGER,
    current_mentees_count INTEGER DEFAULT 0,
    accepts_new_mentees BOOLEAN DEFAULT TRUE,
    hourly_rate_ugx DOUBLE PRECISION,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS metabolic_pathways (
    id SERIAL PRIMARY KEY,
    pathway_name VARCHAR(100) NOT NULL UNIQUE,
    pathway_type VARCHAR(40),
    description TEXT,
    primary_function TEXT,
    location VARCHAR(60),
    key_enzymes TEXT,
    cofactors TEXT,
    substrates TEXT,
    products TEXT,
    energy_yield VARCHAR(40),
    clinical_relevance TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS monthly_revenue_summary (
  id SERIAL PRIMARY KEY,
  month DATE NOT NULL,
  barter_fees_ugx DOUBLE PRECISION DEFAULT 0,
  labor_fees_ugx DOUBLE PRECISION DEFAULT 0,
  verification_fees_ugx DOUBLE PRECISION DEFAULT 0,
  escrow_fees_ugx DOUBLE PRECISION DEFAULT 0,
  premium_listing_fees_ugx DOUBLE PRECISION DEFAULT 0,
  facility_commissions_ugx DOUBLE PRECISION DEFAULT 0,
  pharmacy_commissions_ugx DOUBLE PRECISION DEFAULT 0,
  currency_conversion_fees_ugx DOUBLE PRECISION DEFAULT 0,
  total_revenue_ugx DOUBLE PRECISION DEFAULT 0,
  total_revenue_usd DOUBLE PRECISION,
  total_transactions INTEGER DEFAULT 0,
  barter_transactions INTEGER DEFAULT 0,
  labor_transactions INTEGER DEFAULT 0,
  pharmacy_orders INTEGER DEFAULT 0,
  facility_services INTEGER DEFAULT 0,
  avg_revenue_per_transaction_ugx DOUBLE PRECISION,
  top_country_1_code VARCHAR(5),
  top_country_1_revenue_ugx DOUBLE PRECISION,
  top_country_2_code VARCHAR(5),
  top_country_2_revenue_ugx DOUBLE PRECISION,
  top_country_3_code VARCHAR(5),
  top_country_3_revenue_ugx DOUBLE PRECISION,
  calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (month)
);
CREATE TABLE IF NOT EXISTS monthly_social_good_summary (
  id SERIAL PRIMARY KEY,
  month DATE NOT NULL UNIQUE,
  total_users_served INTEGER DEFAULT 0,
  elderly_users_served INTEGER DEFAULT 0,
  disabled_users_served INTEGER DEFAULT 0,
  child_users_served INTEGER DEFAULT 0,
  pregnant_women_served INTEGER DEFAULT 0,
  low_income_users_served INTEGER DEFAULT 0,
  total_social_good_transactions INTEGER DEFAULT 0,
  barter_only_transactions INTEGER DEFAULT 0,
  labor_only_transactions INTEGER DEFAULT 0,
  zero_cash_transactions INTEGER DEFAULT 0,
  total_value_delivered_ugx DOUBLE PRECISION DEFAULT 0,
  total_fees_waived_ugx DOUBLE PRECISION DEFAULT 0,
  total_fees_waived_usd DOUBLE PRECISION,
  essential_medicine_transactions INTEGER DEFAULT 0,
  ckd_medications_provided INTEGER DEFAULT 0,
  insulin_doses_provided INTEGER DEFAULT 0,
  hypertension_meds_provided INTEGER DEFAULT 0,
  free_lab_tests INTEGER DEFAULT 0,
  free_consultations INTEGER DEFAULT 0,
  free_dialysis_sessions INTEGER DEFAULT 0,
  countries_reached INTEGER DEFAULT 0,
  rural_communities_reached INTEGER DEFAULT 0,
  districts_reached INTEGER DEFAULT 0,
  success_stories_count INTEGER DEFAULT 0,
  calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS mood_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    mood_score INTEGER NOT NULL,
    mood_label VARCHAR(40),
    energy_level INTEGER,
    stress_level INTEGER,
    anxiety_level INTEGER,
    triggers TEXT,
    activities TEXT,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS nutrient_antagonisms (
    id SERIAL PRIMARY KEY,
    nutrient_a_id INTEGER NOT NULL,
    nutrient_b_id INTEGER NOT NULL,
    antagonism_type VARCHAR(40),
    effect_magnitude VARCHAR(20),
    mechanism TEXT,
    foods_to_separate TEXT,
    time_separation_hours INTEGER,
    clinical_evidence VARCHAR(20),
    recommendation TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (nutrient_a_id) REFERENCES nutrients(id) ON DELETE CASCADE,
    FOREIGN KEY (nutrient_b_id) REFERENCES nutrients(id) ON DELETE CASCADE,
    UNIQUE(nutrient_a_id, nutrient_b_id)
);
CREATE TABLE IF NOT EXISTS nutrient_contribution_breakdown (
    id SERIAL PRIMARY KEY,
    meal_id INTEGER NOT NULL,
    food_id INTEGER NOT NULL,
    food_weight_g DOUBLE PRECISION,
    total_meal_weight_g DOUBLE PRECISION,
    weight_contribution_pct DOUBLE PRECISION,
    energy_contribution_pct DOUBLE PRECISION,
    protein_contribution_pct DOUBLE PRECISION,
    carbs_contribution_pct DOUBLE PRECISION,
    fat_contribution_pct DOUBLE PRECISION,
    fiber_contribution_pct DOUBLE PRECISION,
    potassium_contribution_pct DOUBLE PRECISION,
    sodium_contribution_pct DOUBLE PRECISION,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (meal_id) REFERENCES meals(id),
    FOREIGN KEY (food_id) REFERENCES foods(id),
    UNIQUE(meal_id, food_id)
);
CREATE TABLE IF NOT EXISTS nutrients (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL);
CREATE TABLE IF NOT EXISTS nutrient_synergies (
    id SERIAL PRIMARY KEY,
    nutrient_a_id INTEGER NOT NULL,
    nutrient_b_id INTEGER NOT NULL,
    synergy_type VARCHAR(40),
    effect_magnitude VARCHAR(20),
    mechanism TEXT,
    example_foods TEXT,
    clinical_evidence VARCHAR(20),
    recommendation TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (nutrient_a_id) REFERENCES nutrients(id) ON DELETE CASCADE,
    FOREIGN KEY (nutrient_b_id) REFERENCES nutrients(id) ON DELETE CASCADE,
    UNIQUE(nutrient_a_id, nutrient_b_id)
);
CREATE TABLE IF NOT EXISTS nutrient_targets (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    nutrient_id INTEGER NOT NULL,
    target_min DOUBLE PRECISION,
    target_max DOUBLE PRECISION,
    target_value DOUBLE PRECISION,
    unit VARCHAR(20) NOT NULL,
    reason TEXT,
    condition VARCHAR(50),
    condition_stage VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    set_by INTEGER,
    set_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    review_frequency_days INTEGER DEFAULT 90,
    last_reviewed_at TIMESTAMP,
    reviewed_by INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (nutrient_id) REFERENCES nutrients(id),
    FOREIGN KEY (set_by) REFERENCES medical_staff(id),
    FOREIGN KEY (reviewed_by) REFERENCES medical_staff(id),
    UNIQUE(user_id, nutrient_id, is_active)
);
CREATE TABLE IF NOT EXISTS nutrition_calculation_comparisons (
    id SERIAL PRIMARY KEY,
    meal_id INTEGER NOT NULL,
    user_provided_calories DOUBLE PRECISION,
    user_provided_protein_g DOUBLE PRECISION,
    user_provided_carbs_g DOUBLE PRECISION,
    user_provided_fat_g DOUBLE PRECISION,
    user_provided_source VARCHAR(100),
    calculated_calories DOUBLE PRECISION,
    calculated_protein_g DOUBLE PRECISION,
    calculated_carbs_g DOUBLE PRECISION,
    calculated_fat_g DOUBLE PRECISION,
    calories_difference_pct DOUBLE PRECISION,
    protein_difference_pct DOUBLE PRECISION,
    carbs_difference_pct DOUBLE PRECISION,
    fat_difference_pct DOUBLE PRECISION,
    large_discrepancy BOOLEAN DEFAULT FALSE,
    investigation_needed BOOLEAN DEFAULT FALSE,
    resolution TEXT,
    compared_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (meal_id) REFERENCES meals(id)
);
CREATE TABLE IF NOT EXISTS offline_capability_status (
  id SERIAL PRIMARY KEY,
  feature_name VARCHAR(200) NOT NULL UNIQUE,
  supports_offline BOOLEAN DEFAULT FALSE,
  offline_mode VARCHAR(40),
  requires_immediate_sync BOOLEAN DEFAULT FALSE,
  can_batch_sync BOOLEAN DEFAULT TRUE,
  conflict_resolution_strategy VARCHAR(60),
  description TEXT,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS offline_conflict_resolution (
  id SERIAL PRIMARY KEY,
  offline_transaction_id INTEGER NOT NULL,
  conflict_type VARCHAR(60) NOT NULL,
  local_data TEXT,
  server_data TEXT,
  conflict_field VARCHAR(100),
  resolution_strategy VARCHAR(60),
  resolution_applied BOOLEAN DEFAULT FALSE,
  resolved_data TEXT,
  requires_manual_review BOOLEAN DEFAULT FALSE,
  reviewed_by INTEGER,
  reviewed_at TIMESTAMP,
  review_notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (offline_transaction_id) REFERENCES offline_transaction_queue(id) ON DELETE CASCADE,
  FOREIGN KEY (reviewed_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS offline_sync_log (
  id SERIAL PRIMARY KEY,
  offline_transaction_id INTEGER NOT NULL,
  sync_attempt_number INTEGER NOT NULL,
  sync_started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  sync_completed_at TIMESTAMP,
  sync_result VARCHAR(40),
  sync_error TEXT,
  network_type VARCHAR(40),
  network_strength VARCHAR(40),
  data_hash_match BOOLEAN,
  data_corrupted BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (offline_transaction_id) REFERENCES offline_transaction_queue(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS offline_transaction_queue (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  device_id VARCHAR(200),
  transaction_type VARCHAR(40) NOT NULL,
  transaction_data TEXT NOT NULL,
  transaction_data_hash VARCHAR(100),
  created_offline_at TIMESTAMP NOT NULL,
  queued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  sync_status VARCHAR(40) DEFAULT 'pending',
  sync_attempt_count INTEGER DEFAULT 0,
  last_sync_attempt_at TIMESTAMP,
  next_sync_attempt_at TIMESTAMP,
  synced_at TIMESTAMP,
  sync_error TEXT,
  conflict_detected BOOLEAN DEFAULT FALSE,
  conflict_description TEXT,
  server_transaction_id INTEGER,
  server_transaction_type VARCHAR(40),
  priority INTEGER DEFAULT 5,
  is_critical BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS order_line_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    vendor_id INTEGER,
    quantity INTEGER NOT NULL,
    unit_price_ugx DOUBLE PRECISION NOT NULL,
    discount_pct DOUBLE PRECISION DEFAULT 0,
    line_total_ugx DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES order_management(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product_catalog(id) ON DELETE RESTRICT,
    FOREIGN KEY (vendor_id) REFERENCES vendor_profiles(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS order_management (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    order_number VARCHAR(60) UNIQUE NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount_ugx DOUBLE PRECISION NOT NULL,
    discount_amount_ugx DOUBLE PRECISION DEFAULT 0,
    delivery_fee_ugx DOUBLE PRECISION DEFAULT 0,
    afya_points_used INTEGER DEFAULT 0,
    payment_method VARCHAR(40),
    payment_status VARCHAR(20),
    order_status VARCHAR(20),
    delivery_address TEXT,
    delivery_instructions TEXT,
    estimated_delivery_date DATE,
    actual_delivery_date DATE,
    tracking_number VARCHAR(100),
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS pain_tracking (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pain_location VARCHAR(60),
    pain_intensity INTEGER NOT NULL,
    pain_type VARCHAR(40),
    duration_minutes INTEGER,
    triggers TEXT,
    relief_methods TEXT,
    medication_taken VARCHAR(100),
    impact_on_activity VARCHAR(20),
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS pantry_inventory (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    food_id INTEGER NOT NULL,
    quantity_grams DOUBLE PRECISION,
    quantity_units VARCHAR(40),
    location VARCHAR(60),
    purchase_date DATE,
    expiry_date DATE,
    status VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS partner_applications (
    id INTEGER PRIMARY KEY,
    applicant_name VARCHAR(200) NOT NULL,
    applicant_type VARCHAR(40) NOT NULL,
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
    services_offered TEXT,
    proposed_commission_rate DOUBLE PRECISION,
    website_url VARCHAR(300),
    documents_submitted TEXT,
    application_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    reviewed_by INTEGER,
    review_notes TEXT,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS partner_contracts (
    id INTEGER PRIMARY KEY,
    application_id INTEGER REFERENCES partner_applications(id),
    partner_type VARCHAR(40) NOT NULL,
    partner_name VARCHAR(200) NOT NULL,
    contract_number VARCHAR(40) NOT NULL UNIQUE,
    commission_rate_pct DOUBLE PRECISION NOT NULL,
    commission_type VARCHAR(40) NOT NULL DEFAULT 'percentage',
    contract_start_date DATE NOT NULL,
    contract_end_date DATE NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    renewal_period_months INTEGER DEFAULT 12,
    minimum_transactions_month INTEGER DEFAULT 0,
    performance_bonus_threshold DOUBLE PRECISION,
    performance_bonus_rate DOUBLE PRECISION,
    terms_version VARCHAR(20) DEFAULT '1.0',
    terms_accepted BOOLEAN DEFAULT FALSE,
    terms_accepted_at TIMESTAMP,
    signed_by_partner VARCHAR(120),
    signed_by_platform VARCHAR(120),
    contract_status VARCHAR(20) NOT NULL DEFAULT 'draft',
    suspension_reason TEXT,
    termination_reason TEXT,
    terminated_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
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
CREATE TABLE IF NOT EXISTS partner_facilities (id SERIAL PRIMARY KEY, facility_name VARCHAR(200), facility_type VARCHAR(50), address TEXT, is_active BOOLEAN DEFAULT TRUE);
CREATE TABLE IF NOT EXISTS partner_payout_schedule (
  id SERIAL PRIMARY KEY,
  partner_type VARCHAR(40) NOT NULL,
  partner_id INTEGER NOT NULL,
  payout_month DATE NOT NULL,
  total_revenue_generated_ugx DOUBLE PRECISION NOT NULL,
  partner_commission_pct DOUBLE PRECISION NOT NULL,
  partner_payout_amount_ugx DOUBLE PRECISION NOT NULL,
  payout_status VARCHAR(40) DEFAULT 'pending',
  payment_method VARCHAR(40),
  payment_reference VARCHAR(200),
  approved_by INTEGER,
  approved_at TIMESTAMP,
  paid_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (partner_id) REFERENCES facility_partners(id) ON DELETE CASCADE,
  FOREIGN KEY (approved_by) REFERENCES medical_staff(id) ON DELETE SET NULL,
  UNIQUE (partner_type, partner_id, payout_month)
);
CREATE TABLE IF NOT EXISTS partner_performance_metrics (
    id INTEGER PRIMARY KEY,
    contract_id INTEGER NOT NULL REFERENCES partner_contracts(id),
    metric_month DATE NOT NULL,
    total_transactions INTEGER DEFAULT 0,
    total_revenue_ugx DOUBLE PRECISION DEFAULT 0,
    platform_commission_ugx DOUBLE PRECISION DEFAULT 0,
    partner_payout_ugx DOUBLE PRECISION DEFAULT 0,
    average_rating DOUBLE PRECISION,
    total_reviews INTEGER DEFAULT 0,
    complaint_count INTEGER DEFAULT 0,
    average_response_time_minutes INTEGER,
    cancellation_rate_pct DOUBLE PRECISION DEFAULT 0,
    patient_satisfaction_score DOUBLE PRECISION,
    performance_grade VARCHAR(5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(contract_id, metric_month)
);
CREATE TABLE IF NOT EXISTS partnership_agreements (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    agreement_type VARCHAR(40),
    start_date DATE NOT NULL,
    end_date DATE,
    commission_pct DOUBLE PRECISION,
    payment_terms VARCHAR(60),
    minimum_guarantee_ugx DOUBLE PRECISION,
    performance_bonuses TEXT,
    agreement_status VARCHAR(20),
    signed_by VARCHAR(120),
    document_url VARCHAR(500),
    notes TEXT,
    contract_id INTEGER REFERENCES partner_contracts(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS payment_gateways_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    order_id INTEGER,
    gateway_name VARCHAR(40),
    transaction_ref VARCHAR(120) UNIQUE,
    amount_ugx DOUBLE PRECISION NOT NULL,
    currency VARCHAR(10),
    status VARCHAR(20),
    error_message TEXT,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (order_id) REFERENCES order_management(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS payout_requests (
    id INTEGER PRIMARY KEY,
    requestor_type VARCHAR(40) NOT NULL,
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
    approved_by INTEGER,
    approved_at TIMESTAMP,
    paid_at TIMESTAMP,
    rejection_reason TEXT,
    receipt_id INTEGER REFERENCES consultation_receipts(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS personalization_params (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    food_preference_vector TEXT,
    health_priority_weights TEXT,
    engagement_score DOUBLE PRECISION,
    response_rate_pct DOUBLE PRECISION,
    optimal_notification_time TIME,
    preferred_recommendation_types TEXT,
    learning_rate DOUBLE PRECISION,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS pet_abilities (
    id INTEGER PRIMARY KEY,
    species_id INTEGER NOT NULL REFERENCES pet_species(id),
    stage_level INTEGER NOT NULL,
    ability_name VARCHAR(80) NOT NULL,
    ability_type VARCHAR(40) NOT NULL,
    ability_value DOUBLE PRECISION,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(species_id, stage_level, ability_type)
);
CREATE TABLE IF NOT EXISTS pet_care_actions (
    id INTEGER PRIMARY KEY,
    action_name VARCHAR(60) NOT NULL UNIQUE,
    action_type VARCHAR(40) NOT NULL,
    trigger_event VARCHAR(60) NOT NULL,
    happiness_change INTEGER DEFAULT 0,
    health_change INTEGER DEFAULT 0,
    hunger_change INTEGER DEFAULT 0,
    xp_reward INTEGER DEFAULT 5,
    description TEXT,
    cooldown_hours INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS pet_decay_rules (
    id INTEGER PRIMARY KEY,
    decay_trigger VARCHAR(60) NOT NULL UNIQUE,
    happiness_decay INTEGER DEFAULT -5,
    health_decay INTEGER DEFAULT -3,
    hunger_decay INTEGER DEFAULT -10,
    decay_interval_hours INTEGER DEFAULT 24,
    recovery_action VARCHAR(60),
    warning_message TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS pet_evolution_stages (
    id INTEGER PRIMARY KEY,
    species_id INTEGER NOT NULL REFERENCES pet_species(id),
    stage_name VARCHAR(40) NOT NULL,
    stage_level INTEGER NOT NULL,
    required_owner_streak INTEGER DEFAULT 0,
    required_owner_level INTEGER DEFAULT 1,
    required_pet_happiness INTEGER DEFAULT 0,
    appearance_description TEXT,
    stat_bonus_type VARCHAR(40),
    stat_bonus_value DOUBLE PRECISION DEFAULT 0,
    unlock_message TEXT,
    icon VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(species_id, stage_level)
);
CREATE TABLE IF NOT EXISTS pet_species (
    id INTEGER PRIMARY KEY,
    species_name VARCHAR(60) NOT NULL UNIQUE,
    display_name VARCHAR(80) NOT NULL,
    description TEXT NOT NULL,
    native_region VARCHAR(60),
    base_happiness INTEGER DEFAULT 50,
    base_health INTEGER DEFAULT 100,
    condition_affinity VARCHAR(60),
    special_ability_description TEXT,
    requires_subscription_tier INTEGER DEFAULT 2,
    icon VARCHAR(60),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS pharmacy_inventory (id SERIAL PRIMARY KEY, pharmacy_id INTEGER, medication_id INTEGER, price DOUBLE PRECISION, currency_code VARCHAR(5), base_price_ugx DOUBLE PRECISION, auto_convert_pricing BOOLEAN DEFAULT TRUE);
CREATE TABLE IF NOT EXISTS pharmacy_locations (id SERIAL PRIMARY KEY, pharmacy_name VARCHAR(200), address TEXT);
CREATE TABLE IF NOT EXISTS pharmacy_order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    medication_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price_ugx DOUBLE PRECISION NOT NULL,
    total_price_ugx DOUBLE PRECISION NOT NULL,
    dosage_form VARCHAR(40),
    strength VARCHAR(60),
    instructions TEXT,
    substitution_allowed BOOLEAN DEFAULT TRUE,
    actual_medication_dispensed INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES pharmacy_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE RESTRICT,
    FOREIGN KEY (actual_medication_dispensed) REFERENCES medications(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS pharmacy_orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER,
  pharmacy_id INTEGER,
  total_amount_ugx DOUBLE PRECISION,
  status VARCHAR(40) DEFAULT 'pending',
  payment_method VARCHAR(40) DEFAULT 'fiat_only',
  is_hybrid_payment BOOLEAN DEFAULT FALSE,
  payment_breakdown TEXT,
  labor_hours_committed DOUBLE PRECISION DEFAULT 0,
  barter_credits_used INTEGER DEFAULT 0,
  unified_payment_id INTEGER,
  hybrid_payment_approved BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (pharmacy_id) REFERENCES pharmacy_locations(id)
);
CREATE TABLE IF NOT EXISTS pharmacy_payment_acceptance (
  id SERIAL PRIMARY KEY,
  pharmacy_id INTEGER NOT NULL UNIQUE,
  accepts_afya_points BOOLEAN DEFAULT TRUE,
  accepts_labor_hours BOOLEAN DEFAULT FALSE,
  accepts_barter_goods BOOLEAN DEFAULT FALSE,
  accepts_barter_services BOOLEAN DEFAULT FALSE,
  preferred_labor_skills TEXT,
  max_labor_hours_per_month DOUBLE PRECISION,
  seeking_goods_categories TEXT,
  seeking_services_categories TEXT,
  max_afya_points_per_order INTEGER,
  min_fiat_percentage DOUBLE PRECISION DEFAULT 30.0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (pharmacy_id) REFERENCES pharmacy_locations(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS pharmacy_purchase_orders (
    id SERIAL PRIMARY KEY,
    pharmacy_id INTEGER NOT NULL,
    supplier_name VARCHAR(200),
    order_number VARCHAR(60) UNIQUE,
    order_date DATE NOT NULL,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    total_amount_ugx DOUBLE PRECISION,
    payment_status VARCHAR(20),
    payment_method VARCHAR(40),
    status VARCHAR(20),
    received_by VARCHAR(60),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pharmacy_id) REFERENCES pharmacy_locations(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS pharmacy_stock_movements (
    id SERIAL PRIMARY KEY,
    pharmacy_id INTEGER NOT NULL,
    medication_id INTEGER NOT NULL,
    movement_type VARCHAR(20) NOT NULL,
    quantity INTEGER NOT NULL,
    unit_cost_ugx DOUBLE PRECISION,
    reference_id INTEGER,
    batch_number VARCHAR(60),
    expiry_date DATE,
    moved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    moved_by VARCHAR(60),
    notes TEXT,
    FOREIGN KEY (pharmacy_id) REFERENCES pharmacy_locations(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE RESTRICT
);
CREATE TABLE IF NOT EXISTS phosphorus_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    phosphorus_mg_dl DOUBLE PRECISION NOT NULL,
    measured_at TIMESTAMP NOT NULL,
    measurement_context VARCHAR(50),
    lab_facility_id INTEGER,
    notes TEXT,
    is_elevated BOOLEAN DEFAULT FALSE,
    risk_level VARCHAR(20),
    calcium_mg_dl DOUBLE PRECISION,
    pth_pg_ml DOUBLE PRECISION,
    vitamin_d_ng_ml DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entered_by INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (lab_facility_id) REFERENCES partner_facilities(id),
    FOREIGN KEY (entered_by) REFERENCES users(id)
);
CREATE TABLE IF NOT EXISTS platform_revenue_ledger (
  id SERIAL PRIMARY KEY,
  revenue_source VARCHAR(60) NOT NULL,
  amount_ugx DOUBLE PRECISION NOT NULL,
  amount_ap INTEGER,
  amount_local_currency DOUBLE PRECISION,
  local_currency_code VARCHAR(5),
  user_id INTEGER,
  transaction_id INTEGER,
  transaction_type VARCHAR(40),
  country_code VARCHAR(5),
  facility_id INTEGER,
  partner_revenue_share_ugx DOUBLE PRECISION,
  revenue_date DATE NOT NULL,
  month DATE NOT NULL,
  quarter VARCHAR(10),
  year INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code),
  FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS point_minting_audit (
    id SERIAL PRIMARY KEY,
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
CREATE TABLE IF NOT EXISTS points_earning_rules (
    id SERIAL PRIMARY KEY,
    action_type VARCHAR(60) NOT NULL UNIQUE,
    base_points INTEGER NOT NULL,
    requires_verification BOOLEAN DEFAULT FALSE,
    multiplier_conditions TEXT,
    max_per_day INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS points_expiry_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS points_vrc_conversions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS post_comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    parent_comment_id INTEGER,
    comment_text TEXT NOT NULL,
    like_count INTEGER DEFAULT 0,
    is_flagged BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES social_posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_comment_id) REFERENCES post_comments(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS post_likes (
    id SERIAL PRIMARY KEY,
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
CREATE TABLE IF NOT EXISTS potassium_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    potassium_value DOUBLE PRECISION NOT NULL,
    unit VARCHAR(10) DEFAULT 'mEq/L',
    measured_at TIMESTAMP NOT NULL,
    measurement_context VARCHAR(50),
    lab_facility_id INTEGER,
    notes TEXT,
    is_critical BOOLEAN DEFAULT FALSE,
    risk_level VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entered_by INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (lab_facility_id) REFERENCES partner_facilities(id),
    FOREIGN KEY (entered_by) REFERENCES users(id)
);
CREATE TABLE IF NOT EXISTS privacy_settings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    profile_visibility VARCHAR(20),
    meal_logs_visibility VARCHAR(20),
    biometrics_visibility VARCHAR(20),
    achievements_visibility VARCHAR(20),
    allow_friend_requests BOOLEAN DEFAULT TRUE,
    allow_group_invites BOOLEAN DEFAULT TRUE,
    allow_direct_messages VARCHAR(20),
    show_online_status BOOLEAN DEFAULT TRUE,
    show_in_leaderboards BOOLEAN DEFAULT TRUE,
    data_sharing_consent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS product_catalog (
    id SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    product_category_id INTEGER,
    description TEXT,
    brand VARCHAR(100),
    sku VARCHAR(60) UNIQUE,
    base_price_ugx DOUBLE PRECISION NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    low_stock_threshold INTEGER DEFAULT 10,
    images TEXT,
    specifications TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_category_id) REFERENCES product_categories(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS product_categories (
    id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    parent_id INTEGER,
    description TEXT,
    icon_url VARCHAR(500),
    display_order INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES product_categories(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS product_multi_currency_pricing (
  id SERIAL PRIMARY KEY,
  product_type VARCHAR(40) NOT NULL,
  product_id INTEGER NOT NULL,
  currency_code VARCHAR(5) NOT NULL,
  price DOUBLE PRECISION NOT NULL,
  is_manual BOOLEAN DEFAULT FALSE,
  base_price_ugx DOUBLE PRECISION,
  auto_convert BOOLEAN DEFAULT TRUE,
  effective_date DATE DEFAULT CURRENT_DATE,
  expires_at DATE,
  is_active BOOLEAN DEFAULT TRUE,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (currency_code) REFERENCES countries_supported(currency_code),
  UNIQUE (product_type, product_id, currency_code)
);
CREATE TABLE IF NOT EXISTS proficiency_level_definitions (
  id SERIAL PRIMARY KEY,
  proficiency_level VARCHAR(40) NOT NULL UNIQUE,
  multiplier DOUBLE PRECISION NOT NULL,
  years_experience_min INTEGER,
  years_experience_max INTEGER,
  description TEXT
);
CREATE TABLE IF NOT EXISTS progression_curve (id SERIAL PRIMARY KEY, level INTEGER, xp_required INTEGER);
CREATE TABLE IF NOT EXISTS promotional_campaigns (
  id SERIAL PRIMARY KEY,
  campaign_name VARCHAR(200) NOT NULL,
  campaign_code VARCHAR(60) UNIQUE,
  applies_to_fee_types TEXT,
  discount_pct DOUBLE PRECISION NOT NULL,
  target_countries TEXT,
  target_user_ids TEXT,
  target_new_users_only BOOLEAN DEFAULT FALSE,
  target_first_transaction_only BOOLEAN DEFAULT FALSE,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  max_redemptions INTEGER,
  redemptions_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_by INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS quest_objectives (
    id SERIAL PRIMARY KEY,
    quest_id INTEGER NOT NULL,
    description TEXT,
    objective_type VARCHAR(40),
    target_value DOUBLE PRECISION,
    sequence_order INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (quest_id) REFERENCES game_quests(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS random_blood_sugar_logs (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_cooking_steps (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_favorites (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_ingredients (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_reviews (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    rating INTEGER NOT NULL,
    review_text TEXT,
    difficulty_rating INTEGER,
    taste_rating INTEGER,
    would_make_again BOOLEAN,
    modifications_made TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(recipe_id, user_id)
);
CREATE TABLE IF NOT EXISTS recipes (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_submissions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_tag_assignments (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recipe_tags (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES meal_tags(id) ON DELETE CASCADE,
    UNIQUE(recipe_id, tag_id)
);
CREATE TABLE IF NOT EXISTS recipe_variations (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS recommendation_feedback (
    id SERIAL PRIMARY KEY,
    recommendation_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    feedback_type VARCHAR(20),
    feedback_rating INTEGER,
    feedback_text TEXT,
    was_helpful BOOLEAN,
    reason_dismissed TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recommendation_id) REFERENCES ai_recommendations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS referral_commission_rules (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS referral_tickets (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS referral_transactions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS region_content (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS region_unlock_requirements (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS regulatory_compliance_log (
  id SERIAL PRIMARY KEY,
  compliance_type VARCHAR(60) NOT NULL,
  user_id INTEGER,
  transaction_id INTEGER,
  transaction_type VARCHAR(40),
  country_code VARCHAR(5) NOT NULL,
  regulatory_body VARCHAR(100),
  regulation_reference VARCHAR(200),
  compliance_status VARCHAR(40) NOT NULL,
  risk_level VARCHAR(40),
  check_description TEXT,
  failure_reason TEXT,
  remediation_required TEXT,
  remediation_deadline DATE,
  action_taken VARCHAR(60),
  action_taken_by INTEGER,
  action_taken_at TIMESTAMP,
  is_resolved BOOLEAN DEFAULT FALSE,
  resolved_by INTEGER,
  resolved_at TIMESTAMP,
  resolution_notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code),
  FOREIGN KEY (action_taken_by) REFERENCES medical_staff(id) ON DELETE SET NULL,
  FOREIGN KEY (resolved_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS renal_acid_load_data (
    id SERIAL PRIMARY KEY,
    food_id INTEGER NOT NULL,
    pral_value DOUBLE PRECISION NOT NULL,
    neap_value DOUBLE PRECISION,
    acid_category VARCHAR(20),
    phosphorus_mg DOUBLE PRECISION,
    potassium_mg DOUBLE PRECISION,
    sodium_mg DOUBLE PRECISION,
    protein_g DOUBLE PRECISION,
    ckd_recommendation VARCHAR(20),
    serving_size_g INTEGER DEFAULT 100,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS research_studies (
    id SERIAL PRIMARY KEY,
    study_title TEXT NOT NULL,
    study_type VARCHAR(40),
    condition_focus VARCHAR(60),
    principal_investigator INTEGER,
    institution TEXT,
    ethics_approval_ref VARCHAR(80),
    status VARCHAR(20),
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (principal_investigator) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS revenue_forecast (
  id SERIAL PRIMARY KEY,
  forecast_month DATE NOT NULL,
  forecast_type VARCHAR(40) DEFAULT 'growth_projection',
  forecasted_revenue_ugx DOUBLE PRECISION NOT NULL,
  forecasted_revenue_usd DOUBLE PRECISION,
  assumed_barter_transactions INTEGER,
  assumed_labor_transactions INTEGER,
  assumed_avg_fee_ugx DOUBLE PRECISION,
  assumed_countries_active INTEGER,
  confidence_level VARCHAR(40),
  confidence_pct DOUBLE PRECISION,
  forecast_basis TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (forecast_month, forecast_type)
);
CREATE TABLE IF NOT EXISTS revenue_targets (
  id SERIAL PRIMARY KEY,
  target_period VARCHAR(20) NOT NULL,
  target_type VARCHAR(40),
  target_revenue_ugx DOUBLE PRECISION NOT NULL,
  target_revenue_usd DOUBLE PRECISION,
  target_barter_fees_ugx DOUBLE PRECISION,
  target_labor_fees_ugx DOUBLE PRECISION,
  target_facility_commissions_ugx DOUBLE PRECISION,
  target_transactions INTEGER,
  target_active_users INTEGER,
  target_countries INTEGER,
  actual_revenue_ugx DOUBLE PRECISION DEFAULT 0,
  actual_transactions INTEGER DEFAULT 0,
  actual_active_users INTEGER DEFAULT 0,
  achievement_pct DOUBLE PRECISION,
  is_achieved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (target_period)
);
CREATE TABLE IF NOT EXISTS review_comments (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS review_decision_factors (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS reviewer_workload (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS review_sla_targets (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS revision_requirements_tracking (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS reward_catalog (id SERIAL PRIMARY KEY, reward_name VARCHAR(100), reward_value_ugx DOUBLE PRECISION);
CREATE TABLE IF NOT EXISTS reward_redemption_log (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS risk_prediction_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    condition_name VARCHAR(120),
    risk_score DOUBLE PRECISION NOT NULL,
    risk_category VARCHAR(20),
    risk_factors TEXT,
    protective_factors TEXT,
    recommendations TEXT,
    model_version VARCHAR(40),
    confidence_score DOUBLE PRECISION,
    predicted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS saved_drinks (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS saved_meals (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS schema_migrations (id SERIAL PRIMARY KEY, filename TEXT UNIQUE, applied_at TIMESTAMP);
CREATE TABLE IF NOT EXISTS screening_reminders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    screening_type VARCHAR(60),
    due_date DATE NOT NULL,
    last_completed_date DATE,
    frequency_months INTEGER,
    priority VARCHAR(20),
    age_appropriate BOOLEAN DEFAULT TRUE,
    gender_specific BOOLEAN DEFAULT FALSE,
    condition_specific TEXT,
    reminder_sent BOOLEAN DEFAULT FALSE,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS seasonal_availability (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS season_pass_metadata (id SERIAL PRIMARY KEY, season_name VARCHAR(100) NOT NULL, theme TEXT, starts_at DATE, ends_at DATE, exclusive_quests TEXT, exclusive_rewards TEXT);
CREATE TABLE IF NOT EXISTS second_opinion_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    original_consultation_id INTEGER,
    original_diagnosis TEXT,
    reason_for_request TEXT,
    requested_specialty VARCHAR(100),
    assigned_staff_id INTEGER,
    status VARCHAR(20),
    priority VARCHAR(20),
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    second_opinion_notes TEXT,
    agreement_with_original VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (original_consultation_id) REFERENCES consultations(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_staff_id) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS shipping_logistics (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    carrier_name VARCHAR(100),
    tracking_number VARCHAR(100),
    shipped_from TEXT,
    shipped_to TEXT,
    shipped_at TIMESTAMP,
    estimated_delivery TIMESTAMP,
    delivered_at TIMESTAMP,
    delivery_status VARCHAR(20),
    delivery_attempts INTEGER DEFAULT 0,
    signature_required BOOLEAN DEFAULT FALSE,
    delivery_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES order_management(id) ON DELETE CASCADE,
    UNIQUE(order_id)
);
CREATE TABLE IF NOT EXISTS shopping_lists (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    list_name VARCHAR(120),
    start_date DATE,
    end_date DATE,
    status VARCHAR(20),
    total_estimated_cost_ugx DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS skill_tree (id SERIAL PRIMARY KEY, skill_name VARCHAR(100), category VARCHAR(50), prerequisite_id INTEGER, xp_cost INTEGER, description TEXT, required_level INTEGER, is_premium BOOLEAN DEFAULT FALSE);
CREATE TABLE IF NOT EXISTS sleep_stages_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    sleep_date DATE NOT NULL,
    sleep_start TIMESTAMP,
    sleep_end TIMESTAMP,
    total_sleep_minutes INTEGER,
    deep_sleep_minutes INTEGER,
    light_sleep_minutes INTEGER,
    rem_sleep_minutes INTEGER,
    awake_minutes INTEGER,
    sleep_efficiency_pct DOUBLE PRECISION,
    sleep_quality_score DOUBLE PRECISION,
    resting_heart_rate INTEGER,
    hrv_avg DOUBLE PRECISION,
    respiration_rate DOUBLE PRECISION,
    movement_count INTEGER,
    interruptions INTEGER,
    source VARCHAR(40),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, sleep_date)
);
CREATE TABLE IF NOT EXISTS sms_delivery_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER,
  phone_number VARCHAR(20) NOT NULL,
  message_text TEXT NOT NULL,
  message_length INTEGER,
  template_code VARCHAR(60),
  provider_name VARCHAR(60),
  provider_message_id VARCHAR(200),
  delivery_status VARCHAR(40),
  delivery_error TEXT,
  cost_ugx DOUBLE PRECISION,
  sent_at TIMESTAMP,
  delivered_at TIMESTAMP,
  failed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS sms_provider_config (
  id SERIAL PRIMARY KEY,
  provider_name VARCHAR(60) NOT NULL UNIQUE,
  api_key VARCHAR(500),
  api_secret VARCHAR(500),
  sender_id VARCHAR(20),
  supported_countries TEXT,
  priority INTEGER DEFAULT 1,
  cost_per_sms_ugx DOUBLE PRECISION,
  monthly_quota INTEGER,
  monthly_usage INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS sms_templates (
  id SERIAL PRIMARY KEY,
  template_code VARCHAR(60) NOT NULL UNIQUE,
  template_name VARCHAR(200) NOT NULL,
  message_template TEXT NOT NULL,
  message_length INTEGER,
  language_code VARCHAR(5) DEFAULT 'en',
  purpose VARCHAR(60),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS sms_verification_codes (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  otp_code VARCHAR(10) NOT NULL,
  otp_hash VARCHAR(100),
  verification_purpose VARCHAR(60) NOT NULL,
  transaction_id INTEGER,
  transaction_type VARCHAR(40),
  transaction_amount_ugx DOUBLE PRECISION,
  status VARCHAR(40) DEFAULT 'pending',
  sent_at TIMESTAMP,
  verified_at TIMESTAMP,
  expires_at TIMESTAMP,
  sms_provider VARCHAR(60),
  sms_message_id VARCHAR(200),
  sms_delivery_status VARCHAR(40),
  sms_cost_ugx DOUBLE PRECISION,
  verification_attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 3,
  is_locked BOOLEAN DEFAULT FALSE,
  ip_address VARCHAR(60),
  user_agent TEXT,
  geolocation_lat DOUBLE PRECISION,
  geolocation_lng DOUBLE PRECISION,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS social_good_goals (
  id SERIAL PRIMARY KEY,
  goal_period VARCHAR(20) NOT NULL UNIQUE,
  target_users_served INTEGER NOT NULL,
  target_value_delivered_ugx DOUBLE PRECISION NOT NULL,
  target_essential_medicines INTEGER,
  target_rural_communities INTEGER,
  target_zero_cash_transactions INTEGER,
  actual_users_served INTEGER DEFAULT 0,
  actual_value_delivered_ugx DOUBLE PRECISION DEFAULT 0,
  actual_essential_medicines INTEGER DEFAULT 0,
  achievement_pct DOUBLE PRECISION,
  is_achieved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS social_good_impact_log (
  id SERIAL PRIMARY KEY,
  transaction_id INTEGER NOT NULL,
  transaction_type VARCHAR(40) NOT NULL,
  user_id INTEGER NOT NULL,
  user_category VARCHAR(60),
  transaction_value_ugx DOUBLE PRECISION NOT NULL,
  fee_waived_ugx DOUBLE PRECISION NOT NULL,
  fee_waived_pct DOUBLE PRECISION,
  payment_method VARCHAR(40),
  used_barter BOOLEAN DEFAULT FALSE,
  used_labor BOOLEAN DEFAULT FALSE,
  used_afya_points BOOLEAN DEFAULT FALSE,
  had_zero_fiat BOOLEAN DEFAULT FALSE,
  impact_type VARCHAR(60) NOT NULL,
  health_service_type VARCHAR(60),
  ckd_related BOOLEAN DEFAULT FALSE,
  diabetes_related BOOLEAN DEFAULT FALSE,
  hypertension_related BOOLEAN DEFAULT FALSE,
  country_code VARCHAR(5),
  district VARCHAR(100),
  is_rural BOOLEAN DEFAULT FALSE,
  is_success_story BOOLEAN DEFAULT FALSE,
  success_story_notes TEXT,
  impact_date DATE NOT NULL,
  month DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code)
);
CREATE TABLE IF NOT EXISTS social_good_success_stories (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  story_title VARCHAR(200) NOT NULL,
  story_text TEXT NOT NULL,
  story_category VARCHAR(60),
  transaction_ids TEXT,
  health_outcome VARCHAR(200),
  lives_impacted INTEGER DEFAULT 1,
  story_photos TEXT,
  story_video_url TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  featured_on_website BOOLEAN DEFAULT FALSE,
  featured_in_newsletter BOOLEAN DEFAULT FALSE,
  featured_in_report BOOLEAN DEFAULT FALSE,
  is_verified_story BOOLEAN DEFAULT FALSE,
  verified_by INTEGER,
  story_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verified_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS social_groups (
    id SERIAL PRIMARY KEY,
    group_name VARCHAR(120) NOT NULL,
    group_type VARCHAR(40),
    description TEXT,
    health_focus TEXT,
    privacy_level VARCHAR(20),
    created_by_user_id INTEGER NOT NULL,
    member_count INTEGER DEFAULT 0,
    max_members INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS social_posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    group_id INTEGER,
    post_type VARCHAR(20),
    content TEXT,
    media_urls TEXT,
    visibility VARCHAR(20),
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    is_flagged BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES social_groups(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS sodium_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    sodium_value DOUBLE PRECISION NOT NULL,
    unit VARCHAR(10) DEFAULT 'mEq/L',
    measured_at TIMESTAMP NOT NULL,
    measurement_context VARCHAR(50),
    lab_facility_id INTEGER,
    notes TEXT,
    is_critical BOOLEAN DEFAULT FALSE,
    risk_level VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entered_by INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (lab_facility_id) REFERENCES partner_facilities(id),
    FOREIGN KEY (entered_by) REFERENCES users(id)
);
CREATE TABLE IF NOT EXISTS specialist_registry (
    id SERIAL PRIMARY KEY,
    staff_id INTEGER NOT NULL,
    specialty VARCHAR(100) NOT NULL,
    sub_specialty VARCHAR(100),
    years_of_experience INTEGER,
    medical_school VARCHAR(200),
    residency VARCHAR(200),
    board_certified BOOLEAN DEFAULT FALSE,
    certifications TEXT,
    languages_spoken TEXT,
    areas_of_interest TEXT,
    publications_count INTEGER DEFAULT 0,
    accepts_new_patients BOOLEAN DEFAULT TRUE,
    consultation_fee_ugx DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES medical_staff(id) ON DELETE CASCADE,
    UNIQUE(staff_id)
);
CREATE TABLE IF NOT EXISTS specimen_tracking (
    id SERIAL PRIMARY KEY,
    lab_order_id INTEGER NOT NULL,
    specimen_id VARCHAR(60) UNIQUE NOT NULL,
    specimen_type VARCHAR(60),
    collected_at TIMESTAMP,
    collected_by VARCHAR(120),
    received_at_lab TIMESTAMP,
    processing_started_at TIMESTAMP,
    processing_completed_at TIMESTAMP,
    status VARCHAR(20),
    rejection_reason TEXT,
    quality_check_passed BOOLEAN,
    notes TEXT,
    FOREIGN KEY (lab_order_id) REFERENCES lab_orders(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS step_count_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    recorded_date DATE NOT NULL,
    step_count INTEGER NOT NULL,
    distance_km DOUBLE PRECISION,
    floors_climbed INTEGER,
    active_minutes INTEGER,
    calories_burned INTEGER,
    source VARCHAR(40),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, recorded_date, source)
);
CREATE TABLE IF NOT EXISTS streak_multipliers (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS study_participants (
    id SERIAL PRIMARY KEY,
    study_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    cohort_label VARCHAR(40),
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    withdrawn_at TIMESTAMP,
    UNIQUE(study_id, user_id),
    FOREIGN KEY (study_id) REFERENCES research_studies(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS submission_approvals (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS submission_resubmissions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS submission_review_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS submission_review_queue (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS submission_rewards (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS submission_version_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS subregions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS subscription_features (
    id INTEGER PRIMARY KEY,
    feature_key VARCHAR(80) NOT NULL UNIQUE,
    feature_name VARCHAR(120) NOT NULL,
    category VARCHAR(40) NOT NULL,
    required_tier INTEGER NOT NULL DEFAULT 1,
    free_limit INTEGER,
    plus_limit INTEGER,
    pro_limit INTEGER,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS subscription_plans (
    id SERIAL PRIMARY KEY,
    plan_name VARCHAR(80) NOT NULL UNIQUE,
    description TEXT,
    price_monthly_ugx DOUBLE PRECISION,
    price_annual_ugx DOUBLE PRECISION,
    features TEXT,
    max_consultations INTEGER,
    ai_features_enabled BOOLEAN DEFAULT FALSE,
    lab_discounts_pct DOUBLE PRECISION DEFAULT 0,
    pharmacy_discounts_pct DOUBLE PRECISION DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    tier INTEGER DEFAULT 1,
    price_monthly_usd DOUBLE PRECISION DEFAULT 0.0,
    price_annual_usd DOUBLE PRECISION DEFAULT 0.0,
    trial_days INTEGER DEFAULT 0,
    badge_label VARCHAR(40),
    color_hex VARCHAR(10),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS subscription_transactions (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    subscription_id INTEGER REFERENCES user_subscriptions(id),
    plan_id INTEGER NOT NULL REFERENCES subscription_plans(id),
    transaction_type VARCHAR(20) NOT NULL,
    amount_ugx DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    amount_usd DOUBLE PRECISION,
    currency_code VARCHAR(10) DEFAULT 'UGX',
    payment_method VARCHAR(40),
    payment_reference VARCHAR(200),
    receipt_number VARCHAR(60) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'completed',
    billing_period_start DATE,
    billing_period_end DATE,
    platform_revenue_ugx DOUBLE PRECISION DEFAULT 0.0,
    tax_amount_ugx DOUBLE PRECISION DEFAULT 0.0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS support_group_meetings (
    id SERIAL PRIMARY KEY,
    group_id INTEGER NOT NULL,
    meeting_title VARCHAR(200),
    meeting_type VARCHAR(20),
    meeting_date DATE NOT NULL,
    meeting_time TIME NOT NULL,
    duration_minutes INTEGER,
    location TEXT,
    meeting_url VARCHAR(500),
    agenda TEXT,
    max_attendees INTEGER,
    rsvp_count INTEGER DEFAULT 0,
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES social_groups(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS symptom_diary (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    symptom_type VARCHAR(60),
    severity INTEGER,
    onset_time TIMESTAMP,
    duration_minutes INTEGER,
    associated_activities TEXT,
    potential_triggers TEXT,
    relief_methods TEXT,
    seeking_medical_attention BOOLEAN DEFAULT FALSE,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS tax_reporting_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  tax_year INTEGER NOT NULL,
  country_code VARCHAR(5) NOT NULL,
  total_earnings_ugx DOUBLE PRECISION DEFAULT 0,
  total_earnings_local_currency DOUBLE PRECISION DEFAULT 0,
  local_currency_code VARCHAR(5),
  labor_earnings_ugx DOUBLE PRECISION DEFAULT 0,
  barter_earnings_ugx DOUBLE PRECISION DEFAULT 0,
  platform_commission_earnings_ugx DOUBLE PRECISION DEFAULT 0,
  tax_threshold_ugx DOUBLE PRECISION,
  exceeds_threshold BOOLEAN DEFAULT FALSE,
  requires_reporting BOOLEAN DEFAULT FALSE,
  user_tax_id VARCHAR(100),
  has_valid_tax_id BOOLEAN DEFAULT FALSE,
  reporting_status VARCHAR(40) DEFAULT 'pending',
  reported_to_authority BOOLEAN DEFAULT FALSE,
  tax_authority VARCHAR(200),
  report_reference VARCHAR(200),
  reported_at TIMESTAMP,
  tax_report_document_path VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code),
  UNIQUE (user_id, tax_year, country_code)
);
CREATE TABLE IF NOT EXISTS telemedicine_sessions (
    id SERIAL PRIMARY KEY,
    consultation_id INTEGER NOT NULL,
    session_type VARCHAR(20),
    session_url VARCHAR(500),
    session_token VARCHAR(200),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    duration_minutes INTEGER,
    connection_quality VARCHAR(20),
    technical_issues TEXT,
    recording_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS test_interpretation_rules (
    id SERIAL PRIMARY KEY,
    test_name VARCHAR(120) NOT NULL,
    rule_condition TEXT NOT NULL,
    interpretation TEXT,
    severity VARCHAR(20),
    recommended_action TEXT,
    follow_up_test VARCHAR(120),
    consult_specialist VARCHAR(60),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS transaction_reviews (
  id SERIAL PRIMARY KEY,
  transaction_id INTEGER NOT NULL,
  transaction_type VARCHAR(40) NOT NULL,
  reviewer_user_id INTEGER NOT NULL,
  reviewed_user_id INTEGER NOT NULL,
  rating INTEGER NOT NULL CHECK(rating >= 1 AND rating <= 5),
  review_title VARCHAR(200),
  review_text TEXT,
  communication_rating INTEGER CHECK(communication_rating >= 1 AND communication_rating <= 5),
  reliability_rating INTEGER CHECK(reliability_rating >= 1 AND reliability_rating <= 5),
  quality_rating INTEGER CHECK(quality_rating >= 1 AND quality_rating <= 5),
  fairness_rating INTEGER CHECK(fairness_rating >= 1 AND fairness_rating <= 5),
  would_trade_again BOOLEAN,
  showed_up_on_time BOOLEAN,
  goods_as_described BOOLEAN,
  work_completed_fully BOOLEAN,
  is_verified_review BOOLEAN DEFAULT FALSE,
  verified_by INTEGER,
  verified_at TIMESTAMP,
  review_disputed BOOLEAN DEFAULT FALSE,
  dispute_reason TEXT,
  helpful_count INTEGER DEFAULT 0,
  not_helpful_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (reviewer_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (reviewed_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verified_by) REFERENCES medical_staff(id) ON DELETE SET NULL,
  UNIQUE (transaction_id, transaction_type, reviewer_user_id)
);
CREATE TABLE IF NOT EXISTS treatment_plans (
    id SERIAL PRIMARY KEY,
    consultation_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    condition_id INTEGER,
    plan_title VARCHAR(200),
    objectives TEXT,
    medications TEXT,
    lifestyle_changes TEXT,
    dietary_recommendations TEXT,
    exercise_recommendations TEXT,
    follow_up_frequency VARCHAR(60),
    success_metrics TEXT,
    plan_start_date DATE,
    plan_end_date DATE,
    status VARCHAR(20),
    created_by_staff_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (condition_id) REFERENCES medical_conditions(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by_staff_id) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS trust_actions_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  action_type VARCHAR(60) NOT NULL,
  trust_score_before DOUBLE PRECISION,
  trust_score_after DOUBLE PRECISION,
  trust_score_change DOUBLE PRECISION,
  reference_id INTEGER,
  reference_table VARCHAR(60),
  action_description TEXT,
  penalty_points INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS trust_score_weights (
  id SERIAL PRIMARY KEY,
  weight_name VARCHAR(60) NOT NULL UNIQUE,
  weight_value DOUBLE PRECISION NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS unified_payment_ledger (
  id SERIAL PRIMARY KEY,
  transaction_type VARCHAR(40) NOT NULL,
  transaction_id INTEGER NOT NULL,
  transaction_reference VARCHAR(100),
  payer_user_id INTEGER NOT NULL,
  payee_type VARCHAR(40),
  payee_id INTEGER,
  total_amount_ugx DOUBLE PRECISION NOT NULL,
  total_amount_local_currency DOUBLE PRECISION,
  local_currency_code VARCHAR(5),
  payment_method VARCHAR(40) NOT NULL,
  is_hybrid_payment BOOLEAN DEFAULT FALSE,
  payment_breakdown TEXT,
  fiat_amount_ugx DOUBLE PRECISION DEFAULT 0,
  fiat_currency_code VARCHAR(5),
  afya_points_amount INTEGER DEFAULT 0,
  labor_hours_amount DOUBLE PRECISION DEFAULT 0,
  labor_hours_value_ugx DOUBLE PRECISION DEFAULT 0,
  barter_credit_amount INTEGER DEFAULT 0,
  barter_credit_value_ugx DOUBLE PRECISION DEFAULT 0,
  payment_status VARCHAR(40) DEFAULT 'pending',
  initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  failed_at TIMESTAMP,
  failure_reason TEXT,
  transaction_fee_pct DOUBLE PRECISION,
  transaction_fee_ugx DOUBLE PRECISION,
  transaction_fee_ap INTEGER,
  fee_waived BOOLEAN DEFAULT FALSE,
  fee_waiver_reason TEXT,
  platform_revenue_ugx DOUBLE PRECISION,
  partner_revenue_ugx DOUBLE PRECISION,
  partner_commission_pct DOUBLE PRECISION,
  exchange_rate_lock_id INTEGER,
  exchange_rates_json TEXT,
  requires_approval BOOLEAN DEFAULT FALSE,
  approved_by INTEGER,
  approved_at TIMESTAMP,
  dispute_raised BOOLEAN DEFAULT FALSE,
  dispute_id INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (payer_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (exchange_rate_lock_id) REFERENCES exchange_rate_locks(id) ON DELETE SET NULL,
  FOREIGN KEY (approved_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS universal_currency_matrix (
  id SERIAL PRIMARY KEY,
  currency_type VARCHAR(40) NOT NULL,
  currency_code VARCHAR(10),
  ugx_exchange_rate DOUBLE PRECISION NOT NULL,
  is_base_currency BOOLEAN DEFAULT FALSE,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  UNIQUE (currency_type, currency_code)
);
CREATE TABLE IF NOT EXISTS user_access_controls (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    role_name VARCHAR(40),
    permissions TEXT,
    granted_by INTEGER,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (granted_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE(user_id, role_name)
);
CREATE TABLE IF NOT EXISTS user_achievements (id SERIAL PRIMARY KEY, user_id INTEGER, achievement_id INTEGER, unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS user_achievement_tier_progress (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    achievement_id INTEGER NOT NULL REFERENCES achievements(id),
    current_tier_level INTEGER DEFAULT 0,
    current_value DOUBLE PRECISION DEFAULT 0,
    bronze_completed_at TIMESTAMP,
    silver_completed_at TIMESTAMP,
    gold_completed_at TIMESTAMP,
    platinum_completed_at TIMESTAMP,
    diamond_completed_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, achievement_id)
);
CREATE TABLE IF NOT EXISTS user_app_settings (id SERIAL PRIMARY KEY, user_id INTEGER NOT NULL UNIQUE, vuralis_data_bridge_consent BOOLEAN DEFAULT FALSE, gamification_enabled BOOLEAN DEFAULT FALSE);
CREATE TABLE IF NOT EXISTS user_auth_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    token_type VARCHAR(20),
    device_id VARCHAR(120),
    device_name VARCHAR(120),
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    revoked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS user_barter_preferences (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  seeking_category VARCHAR(60),
  seeking_specific_item TEXT,
  max_value_willing_to_trade_ap INTEGER,
  max_distance_km INTEGER,
  preferred_districts TEXT,
  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS user_boss_progress (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    boss_id INTEGER NOT NULL REFERENCES boss_encounters(id),
    status VARCHAR(20) NOT NULL DEFAULT 'locked',
    current_boss_hp INTEGER,
    damage_dealt INTEGER DEFAULT 0,
    attempt_number INTEGER DEFAULT 1,
    highest_difficulty_defeated INTEGER DEFAULT 0,
    started_at TIMESTAMP,
    defeated_at TIMESTAMP,
    respawn_at TIMESTAMP,
    total_defeats INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, boss_id)
);
CREATE TABLE IF NOT EXISTS user_conditions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    condition_id INTEGER NOT NULL,
    diagnosed_date DATE,
    diagnosed_by_staff_id INTEGER,
    severity VARCHAR(20),
    status VARCHAR(20),
    notes TEXT,
    stage VARCHAR(20),
    is_primary BOOLEAN DEFAULT FALSE,
    verified_by_doctor BOOLEAN DEFAULT FALSE,
    declaration_source VARCHAR(20) DEFAULT 'self_report',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (condition_id) REFERENCES medical_conditions(id) ON DELETE CASCADE,
    FOREIGN KEY (diagnosed_by_staff_id) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS user_connections (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    connected_user_id INTEGER NOT NULL,
    connection_type VARCHAR(20),
    connection_strength DOUBLE PRECISION,
    last_interaction_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (connected_user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, connected_user_id)
);
CREATE TABLE IF NOT EXISTS user_cosmetics (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    cosmetic_id INTEGER NOT NULL,
    is_equipped BOOLEAN DEFAULT FALSE,
    acquired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (cosmetic_id) REFERENCES avatar_cosmetics(id) ON DELETE CASCADE,
    UNIQUE (user_id, cosmetic_id)
);
CREATE TABLE IF NOT EXISTS user_crafting_inventory (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    recipe_id INTEGER NOT NULL REFERENCES crafting_recipes(id),
    crafted_name VARCHAR(120),
    quality_tier_id INTEGER REFERENCES crafting_quality_tiers(id),
    quality_score DOUBLE PRECISION,
    food_ids_used TEXT,
    meal_id INTEGER,
    xp_earned INTEGER DEFAULT 0,
    ap_earned INTEGER DEFAULT 0,
    effect_active BOOLEAN DEFAULT FALSE,
    effect_expires_at TIMESTAMP,
    crafted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS user_crafting_mastery (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    recipe_type VARCHAR(40) NOT NULL,
    mastery_level INTEGER DEFAULT 1,
    mastery_xp INTEGER DEFAULT 0,
    total_crafted INTEGER DEFAULT 0,
    highest_quality_achieved INTEGER DEFAULT 1,
    last_crafted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, recipe_type)
);
CREATE TABLE IF NOT EXISTS user_daily_logins (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    login_date DATE NOT NULL,
    day_in_cycle INTEGER NOT NULL,
    cycle_number INTEGER DEFAULT 1,
    reward_claimed BOOLEAN DEFAULT FALSE,
    reward_type VARCHAR(40),
    reward_value INTEGER,
    bonus_claimed BOOLEAN DEFAULT FALSE,
    bonus_type VARCHAR(40),
    bonus_value INTEGER,
    streak_count INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, login_date)
);
CREATE TABLE IF NOT EXISTS user_devices (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    device_id VARCHAR(120) NOT NULL,
    device_name VARCHAR(120),
    device_type VARCHAR(40),
    os_version VARCHAR(60),
    app_version VARCHAR(40),
    push_token VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    last_seen_at TIMESTAMP,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, device_id)
);
CREATE TABLE IF NOT EXISTS user_fraud_history (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  total_fraud_alerts INTEGER DEFAULT 0,
  confirmed_fraud_incidents INTEGER DEFAULT 0,
  false_positive_alerts INTEGER DEFAULT 0,
  overall_fraud_risk_score DOUBLE PRECISION DEFAULT 0.0,
  fraud_risk_level VARCHAR(40) DEFAULT 'low',
  has_fake_goods_history BOOLEAN DEFAULT FALSE,
  has_no_show_history BOOLEAN DEFAULT FALSE,
  has_payment_dispute_history BOOLEAN DEFAULT FALSE,
  has_identity_theft_attempt BOOLEAN DEFAULT FALSE,
  is_permanently_banned BOOLEAN DEFAULT FALSE,
  is_temporarily_suspended BOOLEAN DEFAULT FALSE,
  suspension_expires_at TIMESTAMP,
  requires_enhanced_verification BOOLEAN DEFAULT FALSE,
  last_fraud_alert_at TIMESTAMP,
  last_confirmed_fraud_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (user_id)
);
CREATE TABLE IF NOT EXISTS user_health_goals (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    goal_type VARCHAR(40),
    goal_description TEXT NOT NULL,
    target_value DOUBLE PRECISION,
    target_unit VARCHAR(20),
    current_value DOUBLE PRECISION,
    start_date DATE NOT NULL,
    target_date DATE,
    status VARCHAR(20),
    progress_pct DOUBLE PRECISION,
    motivation_level INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS user_kyc_status (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE,
  kyc_level VARCHAR(40) DEFAULT 'none',
  kyc_tier INTEGER DEFAULT 0,
  has_verified_phone BOOLEAN DEFAULT FALSE,
  has_verified_email BOOLEAN DEFAULT FALSE,
  has_provided_full_name BOOLEAN DEFAULT FALSE,
  has_provided_dob BOOLEAN DEFAULT FALSE,
  basic_kyc_approved BOOLEAN DEFAULT FALSE,
  basic_kyc_approved_at TIMESTAMP,
  has_national_id BOOLEAN DEFAULT FALSE,
  national_id_number VARCHAR(100),
  national_id_verified BOOLEAN DEFAULT FALSE,
  has_proof_of_address BOOLEAN DEFAULT FALSE,
  address_document_type VARCHAR(60),
  intermediate_kyc_approved BOOLEAN DEFAULT FALSE,
  intermediate_kyc_approved_at TIMESTAMP,
  has_tax_id BOOLEAN DEFAULT FALSE,
  tax_id_number VARCHAR(100),
  has_bank_verification BOOLEAN DEFAULT FALSE,
  bank_account_verified BOOLEAN DEFAULT FALSE,
  has_biometric_verification BOOLEAN DEFAULT FALSE,
  biometric_verified_at TIMESTAMP,
  full_kyc_approved BOOLEAN DEFAULT FALSE,
  full_kyc_approved_at TIMESTAMP,
  kyc_documents TEXT,
  approved_by INTEGER,
  approval_notes TEXT,
  max_transaction_ugx DOUBLE PRECISION,
  max_monthly_volume_ugx DOUBLE PRECISION,
  kyc_expires_at DATE,
  requires_renewal BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (approved_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS user_login_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    email VARCHAR(120),
    login_status VARCHAR(20),
    failure_reason VARCHAR(60),
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_type VARCHAR(40),
    location_country VARCHAR(60),
    location_city VARCHAR(60),
    login_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS user_payment_preferences (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE,
  preferred_method_1 VARCHAR(40) DEFAULT 'afya_points',
  preferred_method_2 VARCHAR(40) DEFAULT 'fiat_currency',
  preferred_method_3 VARCHAR(40) DEFAULT 'labor_hours',
  preferred_method_4 VARCHAR(40) DEFAULT 'barter_credit',
  enable_auto_hybrid BOOLEAN DEFAULT FALSE,
  max_afya_points_per_transaction INTEGER,
  max_labor_hours_per_month DOUBLE PRECISION,
  default_fiat_currency VARCHAR(5),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS user_pets (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    species_id INTEGER NOT NULL REFERENCES pet_species(id),
    pet_name VARCHAR(60) NOT NULL,
    current_stage INTEGER DEFAULT 1,
    happiness INTEGER DEFAULT 50,
    health INTEGER DEFAULT 100,
    hunger INTEGER DEFAULT 50,
    is_active BOOLEAN DEFAULT TRUE,
    is_favorite BOOLEAN DEFAULT FALSE,
    total_care_actions INTEGER DEFAULT 0,
    total_days_owned INTEGER DEFAULT 0,
    last_fed_at TIMESTAMP,
    last_played_at TIMESTAMP,
    last_healed_at TIMESTAMP,
    adopted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS user_Profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    full_name VARCHAR(200),
    age INTEGER,
    date_of_birth DATE,
    gender VARCHAR(20),
    phone VARCHAR(20),
    address TEXT,
    district VARCHAR(100),
    region VARCHAR(100),
    country_code VARCHAR(3),
    gamification_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS user_promotional_redemptions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  promotional_campaign_id INTEGER NOT NULL,
  transaction_id INTEGER NOT NULL,
  transaction_type VARCHAR(40) NOT NULL,
  original_fee_ugx DOUBLE PRECISION,
  discounted_fee_ugx DOUBLE PRECISION,
  discount_amount_ugx DOUBLE PRECISION,
  redeemed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (promotional_campaign_id) REFERENCES promotional_campaigns(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS user_purchase_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS user_quest_progress (id SERIAL PRIMARY KEY, user_id INTEGER, quest_id INTEGER);
CREATE TABLE IF NOT EXISTS user_referrals (
    id SERIAL PRIMARY KEY,
    referrer_user_id INTEGER NOT NULL,
    referred_user_id INTEGER,
    referral_code VARCHAR(40) UNIQUE NOT NULL,
    referral_status VARCHAR(20),
    referred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    signed_up_at TIMESTAMP,
    reward_points_earned INTEGER DEFAULT 0,
    notes TEXT,
    FOREIGN KEY (referrer_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (referred_user_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS user_region_progress (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    username VARCHAR(80) UNIQUE,
    password_hash VARCHAR(255),
    phone_number VARCHAR(20),
    country_code VARCHAR(5),
    is_active BOOLEAN DEFAULT TRUE,
    has_completed_health_declaration BOOLEAN DEFAULT FALSE,
    health_declaration_date TIMESTAMP,
    primary_condition_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS user_skills (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    skill_id INTEGER NOT NULL,
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skill_tree(id) ON DELETE CASCADE,
    UNIQUE (user_id, skill_id)
);
CREATE TABLE IF NOT EXISTS user_stats (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    total_meals_logged INTEGER DEFAULT 0,
    total_foods_tried INTEGER DEFAULT 0,
    total_recipes_created INTEGER DEFAULT 0,
    streak_days INTEGER DEFAULT 0,
    longest_streak_days INTEGER DEFAULT 0,
    points_earned INTEGER DEFAULT 0,
    achievements_unlocked INTEGER DEFAULT 0,
    consultations_completed INTEGER DEFAULT 0,
    medications_tracked INTEGER DEFAULT 0,
    avg_adherence_rate DOUBLE PRECISION,
    last_activity_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS user_streaks (id SERIAL PRIMARY KEY, user_id INTEGER, current_streak INTEGER DEFAULT 0, longest_streak INTEGER DEFAULT 0, last_logged_date DATE, last_action_date TIMESTAMP, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    plan_id INTEGER NOT NULL REFERENCES subscription_plans(id),
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    billing_cycle VARCHAR(10) NOT NULL DEFAULT 'monthly',
    current_period_start DATE NOT NULL,
    current_period_end DATE NOT NULL,
    trial_end_date DATE,
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT,
    auto_renew BOOLEAN DEFAULT TRUE,
    payment_method VARCHAR(40),
    currency_code VARCHAR(10) DEFAULT 'UGX',
    amount_paid DOUBLE PRECISION DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS user_terms_agreements (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    terms_id INTEGER NOT NULL,
    agreed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    UNIQUE(user_id, terms_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (terms_id) REFERENCES legal_terms_versions(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS user_trust_ratings (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE,
  trust_score DOUBLE PRECISION DEFAULT 0.5,
  trust_level VARCHAR(40) DEFAULT 'building',
  barter_reliability DOUBLE PRECISION DEFAULT 0.5,
  labor_reliability DOUBLE PRECISION DEFAULT 0.5,
  payment_reliability DOUBLE PRECISION DEFAULT 0.5,
  verification_rate DOUBLE PRECISION DEFAULT 0.0,
  avg_rating DOUBLE PRECISION DEFAULT 0.0,
  total_transactions INTEGER DEFAULT 0,
  completed_transactions INTEGER DEFAULT 0,
  disputed_transactions INTEGER DEFAULT 0,
  cancelled_transactions INTEGER DEFAULT 0,
  barter_trades_initiated INTEGER DEFAULT 0,
  barter_trades_completed INTEGER DEFAULT 0,
  barter_trades_disputed INTEGER DEFAULT 0,
  barter_avg_rating DOUBLE PRECISION DEFAULT 0.0,
  labor_hours_committed DOUBLE PRECISION DEFAULT 0.0,
  labor_hours_completed DOUBLE PRECISION DEFAULT 0.0,
  labor_hours_verified DOUBLE PRECISION DEFAULT 0.0,
  labor_no_shows INTEGER DEFAULT 0,
  labor_avg_rating DOUBLE PRECISION DEFAULT 0.0,
  total_payments_made INTEGER DEFAULT 0,
  on_time_payments INTEGER DEFAULT 0,
  late_payments INTEGER DEFAULT 0,
  failed_payments INTEGER DEFAULT 0,
  has_verified_trader_badge BOOLEAN DEFAULT FALSE,
  has_reliable_worker_badge BOOLEAN DEFAULT FALSE,
  has_honest_trader_badge BOOLEAN DEFAULT FALSE,
  has_prompt_payer_badge BOOLEAN DEFAULT FALSE,
  max_transaction_ugx DOUBLE PRECISION,
  requires_escrow BOOLEAN DEFAULT TRUE,
  requires_facility_verification BOOLEAN DEFAULT TRUE,
  warning_count INTEGER DEFAULT 0,
  penalty_points INTEGER DEFAULT 0,
  is_suspended BOOLEAN DEFAULT FALSE,
  suspended_until TIMESTAMP,
  suspension_reason TEXT,
  last_calculated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS user_volume_tier_assignments (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  month DATE NOT NULL,
  volume_tier_id INTEGER NOT NULL,
  total_transactions INTEGER DEFAULT 0,
  barter_transactions INTEGER DEFAULT 0,
  labor_transactions INTEGER DEFAULT 0,
  total_fees_paid_ugx DOUBLE PRECISION DEFAULT 0,
  total_discount_received_ugx DOUBLE PRECISION DEFAULT 0,
  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (volume_tier_id) REFERENCES volume_discount_tiers(id),
  UNIQUE (user_id, month)
);
CREATE TABLE IF NOT EXISTS user_vrc_wallets (id SERIAL PRIMARY KEY, user_id INTEGER, balance DOUBLE PRECISION DEFAULT 0);
CREATE TABLE IF NOT EXISTS user_wellness_score (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    score_date DATE NOT NULL,
    overall_score DOUBLE PRECISION NOT NULL,
    nutrition_score DOUBLE PRECISION,
    physical_activity_score DOUBLE PRECISION,
    sleep_score DOUBLE PRECISION,
    mental_health_score DOUBLE PRECISION,
    social_connection_score DOUBLE PRECISION,
    medical_adherence_score DOUBLE PRECISION,
    preventive_care_score DOUBLE PRECISION,
    trend VARCHAR(20),
    percentile INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, score_date)
);
CREATE TABLE IF NOT EXISTS user_xp_transactions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS vendor_profiles (
    id SERIAL PRIMARY KEY,
    vendor_name VARCHAR(200) NOT NULL,
    business_registration VARCHAR(100),
    contact_person VARCHAR(120),
    email VARCHAR(120),
    phone VARCHAR(20),
    address TEXT,
    logo_url VARCHAR(500),
    rating DOUBLE PRECISION,
    total_sales INTEGER DEFAULT 0,
    commission_pct DOUBLE PRECISION DEFAULT 15.0,
    payment_terms VARCHAR(60),
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS virtual_currency_basket (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS virtual_currency_config (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS virtual_currency_rate_history (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS vital_signs_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    temperature_c DOUBLE PRECISION,
    pulse_bpm INTEGER,
    respiratory_rate INTEGER,
    oxygen_saturation_pct INTEGER,
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,
    measurement_location VARCHAR(40),
    measured_by VARCHAR(60),
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS volume_discount_tiers (
  id SERIAL PRIMARY KEY,
  tier_name VARCHAR(60) NOT NULL UNIQUE,
  min_transactions_per_month INTEGER NOT NULL,
  max_transactions_per_month INTEGER,
  fee_discount_pct DOUBLE PRECISION NOT NULL,
  tier_description TEXT,
  tier_badge_icon VARCHAR(100),
  is_active BOOLEAN DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS vrc_transactions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS vulnerable_population_registry (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE,
  is_elderly BOOLEAN DEFAULT FALSE,
  is_disabled BOOLEAN DEFAULT FALSE,
  is_child BOOLEAN DEFAULT FALSE,
  is_pregnant BOOLEAN DEFAULT FALSE,
  is_low_income BOOLEAN DEFAULT FALSE,
  is_orphan BOOLEAN DEFAULT FALSE,
  is_refugee BOOLEAN DEFAULT FALSE,
  is_ckd_patient BOOLEAN DEFAULT FALSE,
  is_verified BOOLEAN DEFAULT FALSE,
  verified_by INTEGER,
  verification_method VARCHAR(60),
  verification_documents TEXT,
  verified_at TIMESTAMP,
  eligible_for_0pct_fees BOOLEAN DEFAULT TRUE,
  eligible_for_priority_matching BOOLEAN DEFAULT TRUE,
  eligible_for_subsidized_transport BOOLEAN DEFAULT FALSE,
  max_monthly_transactions INTEGER DEFAULT 50,
  monthly_transactions_used INTEGER DEFAULT 0,
  lifetime_social_good_value_ugx DOUBLE PRECISION DEFAULT 0,
  registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verified_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS vuralis_consent_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  consent_given BOOLEAN NOT NULL,
  consent_version VARCHAR(20) DEFAULT '1.0',
  ip_address VARCHAR(45),
  user_agent TEXT,
  consented_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  revoked_at TIMESTAMP,
  notes TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS vuralis_consent_policy (
  id SERIAL PRIMARY KEY,
  version VARCHAR(20) NOT NULL UNIQUE,
  policy_text TEXT NOT NULL,
  effective_date DATE NOT NULL,
  is_current BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS vuralis_sync_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  sync_type VARCHAR(40),
  sync_status VARCHAR(20),
  records_synced INTEGER DEFAULT 0,
  error_message TEXT,
  synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    transaction_type VARCHAR(30),
    points_amount INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    source_type VARCHAR(40),
    source_id INTEGER,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS world_map_regions (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS xp_earning_rules (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS xp_multiplier_context (id SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS xp_rules (id SERIAL PRIMARY KEY);

-- Re-enable FK checks
SET session_replication_role = 'origin';
