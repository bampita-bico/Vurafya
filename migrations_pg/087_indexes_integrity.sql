-- Migration 087: Indexes + Integrity Checks
-- Performance indexes on all new tables
-- Referential integrity verification

-- ============================================================================
-- INDEXES: SUBSCRIPTION SYSTEM
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON user_subscriptions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_plan ON user_subscriptions(plan_id);
CREATE INDEX IF NOT EXISTS idx_subscription_features_tier ON subscription_features(required_tier);
CREATE INDEX IF NOT EXISTS idx_subscription_features_key ON subscription_features(feature_key);
CREATE INDEX IF NOT EXISTS idx_subscription_transactions_user ON subscription_transactions(user_id);

-- ============================================================================
-- INDEXES: HEALTH CONDITION SYSTEM
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_user_conditions_user ON user_conditions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_conditions_condition ON user_conditions(condition_id);
CREATE INDEX IF NOT EXISTS idx_user_conditions_primary ON user_conditions(user_id, is_primary);
CREATE INDEX IF NOT EXISTS idx_condition_game_modifiers_condition ON condition_game_modifiers(condition_id);
CREATE INDEX IF NOT EXISTS idx_condition_game_modifiers_type ON condition_game_modifiers(modifier_type);
CREATE INDEX IF NOT EXISTS idx_condition_nutrition_rules_condition ON condition_nutrition_rules(condition_id);
CREATE INDEX IF NOT EXISTS idx_condition_nutrition_rules_type ON condition_nutrition_rules(rule_type);

-- ============================================================================
-- INDEXES: QUEST & ACHIEVEMENT SYSTEM
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_quest_objectives_quest ON quest_objectives(quest_id);
CREATE INDEX IF NOT EXISTS idx_achievement_tiers_achievement ON achievement_tiers(achievement_id);
CREATE INDEX IF NOT EXISTS idx_achievement_tiers_tier ON achievement_tiers(tier_level);
CREATE INDEX IF NOT EXISTS idx_user_achievement_tier_progress_user ON user_achievement_tier_progress(user_id);

-- ============================================================================
-- INDEXES: DAILY LOGIN
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_user_daily_logins_user ON user_daily_logins(user_id);
CREATE INDEX IF NOT EXISTS idx_user_daily_logins_date ON user_daily_logins(user_id, login_date);

-- ============================================================================
-- INDEXES: BOSS SYSTEM
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_boss_encounters_condition ON boss_encounters(condition_focus);
CREATE INDEX IF NOT EXISTS idx_boss_mechanics_boss ON boss_mechanics(boss_id);
CREATE INDEX IF NOT EXISTS idx_boss_loot_table_boss ON boss_loot_table(boss_id);
CREATE INDEX IF NOT EXISTS idx_user_boss_progress_user ON user_boss_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_boss_progress_status ON user_boss_progress(user_id, status);
CREATE INDEX IF NOT EXISTS idx_boss_condition_links_boss ON boss_condition_links(boss_id);
CREATE INDEX IF NOT EXISTS idx_boss_condition_links_condition ON boss_condition_links(condition_id);

-- ============================================================================
-- INDEXES: GUILD SYSTEM
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_guilds_leader ON guilds(leader_id);
CREATE INDEX IF NOT EXISTS idx_guilds_condition ON guilds(condition_focus);
CREATE INDEX IF NOT EXISTS idx_guild_members_user ON guild_members(user_id);
CREATE INDEX IF NOT EXISTS idx_guild_members_guild ON guild_members(guild_id);
CREATE INDEX IF NOT EXISTS idx_guild_challenges_guild ON guild_challenges(guild_id);
CREATE INDEX IF NOT EXISTS idx_guild_challenges_status ON guild_challenges(status);
CREATE INDEX IF NOT EXISTS idx_guild_challenge_progress_challenge ON guild_challenge_progress(challenge_id);
CREATE INDEX IF NOT EXISTS idx_guild_chat_messages_guild ON guild_chat_messages(guild_id);
CREATE INDEX IF NOT EXISTS idx_guild_chat_messages_time ON guild_chat_messages(guild_id, created_at);

-- ============================================================================
-- INDEXES: CRAFTING SYSTEM
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_crafting_recipes_condition ON crafting_recipes(condition_focus);
CREATE INDEX IF NOT EXISTS idx_crafting_recipes_type ON crafting_recipes(recipe_type);
CREATE INDEX IF NOT EXISTS idx_crafting_materials_food ON crafting_materials(food_id);
CREATE INDEX IF NOT EXISTS idx_user_crafting_inventory_user ON user_crafting_inventory(user_id);
CREATE INDEX IF NOT EXISTS idx_user_crafting_mastery_user ON user_crafting_mastery(user_id);
CREATE INDEX IF NOT EXISTS idx_crafting_condition_bonuses_recipe ON crafting_condition_bonuses(recipe_id);

-- ============================================================================
-- INDEXES: PET SYSTEM
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_user_pets_user ON user_pets(user_id);
CREATE INDEX IF NOT EXISTS idx_user_pets_species ON user_pets(species_id);
CREATE INDEX IF NOT EXISTS idx_user_pets_active ON user_pets(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_pet_evolution_stages_species ON pet_evolution_stages(species_id);
CREATE INDEX IF NOT EXISTS idx_pet_abilities_species ON pet_abilities(species_id);

-- ============================================================================
-- INDEXES: PARTNER & CONTRACT SYSTEM
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_partner_applications_status ON partner_applications(application_status);
CREATE INDEX IF NOT EXISTS idx_partner_applications_type ON partner_applications(applicant_type);
CREATE INDEX IF NOT EXISTS idx_partner_contracts_status ON partner_contracts(contract_status);
CREATE INDEX IF NOT EXISTS idx_partner_contracts_type ON partner_contracts(partner_type);
CREATE INDEX IF NOT EXISTS idx_partner_performance_contract ON partner_performance_metrics(contract_id);
CREATE INDEX IF NOT EXISTS idx_partner_performance_month ON partner_performance_metrics(metric_month);

-- ============================================================================
-- INDEXES: DOCTOR SYSTEM
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_doctor_profiles_specialty ON doctor_profiles(specialty_id);
CREATE INDEX IF NOT EXISTS idx_doctor_profiles_sub_specialty ON doctor_profiles(sub_specialty_id);
CREATE INDEX IF NOT EXISTS idx_doctor_profiles_contract ON doctor_profiles(contract_id);
CREATE INDEX IF NOT EXISTS idx_doctor_profiles_country ON doctor_profiles(country_code);
CREATE INDEX IF NOT EXISTS idx_doctor_game_stat_access_patient ON doctor_game_stat_access(patient_user_id);
CREATE INDEX IF NOT EXISTS idx_doctor_game_stat_access_doctor ON doctor_game_stat_access(doctor_profile_id);
CREATE INDEX IF NOT EXISTS idx_doctor_availability_slots_doctor ON doctor_availability_slots(doctor_profile_id);
CREATE INDEX IF NOT EXISTS idx_doctor_patient_access_log_doctor ON doctor_patient_access_log(doctor_profile_id);
CREATE INDEX IF NOT EXISTS idx_doctor_patient_access_log_patient ON doctor_patient_access_log(patient_user_id);

-- ============================================================================
-- INDEXES: CONSULTATION & REVENUE SYSTEM
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_consultation_bookings_patient ON consultation_bookings(patient_user_id);
CREATE INDEX IF NOT EXISTS idx_consultation_bookings_doctor ON consultation_bookings(doctor_profile_id);
CREATE INDEX IF NOT EXISTS idx_consultation_bookings_status ON consultation_bookings(status);
CREATE INDEX IF NOT EXISTS idx_consultation_bookings_scheduled ON consultation_bookings(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_consultation_receipts_type ON consultation_receipts(receipt_type);
CREATE INDEX IF NOT EXISTS idx_consultation_receipts_payer ON consultation_receipts(payer_user_id);
CREATE INDEX IF NOT EXISTS idx_consultation_receipts_date ON consultation_receipts(transaction_date);
CREATE INDEX IF NOT EXISTS idx_referral_transactions_referring ON referral_transactions(referring_doctor_id);
CREATE INDEX IF NOT EXISTS idx_referral_transactions_patient ON referral_transactions(patient_user_id);
CREATE INDEX IF NOT EXISTS idx_platform_revenue_ledger_date ON platform_revenue_ledger(revenue_date);
CREATE INDEX IF NOT EXISTS idx_platform_revenue_ledger_source ON platform_revenue_ledger(revenue_source);
CREATE INDEX IF NOT EXISTS idx_payout_requests_requestor ON payout_requests(requestor_type, requestor_id);
CREATE INDEX IF NOT EXISTS idx_payout_requests_status ON payout_requests(status);

-- ============================================================================
-- INDEXES: WORLD MAP
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_world_map_regions_tier ON world_map_regions(requires_subscription_tier);
CREATE INDEX IF NOT EXISTS idx_region_unlock_requirements_region ON region_unlock_requirements(region_id);
CREATE INDEX IF NOT EXISTS idx_region_content_region ON region_content(region_id);
CREATE INDEX IF NOT EXISTS idx_region_content_type ON region_content(content_type);
CREATE INDEX IF NOT EXISTS idx_user_region_progress_user ON user_region_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_region_progress_status ON user_region_progress(user_id, status);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Count all new tables
SELECT 'NEW TABLES' AS check_type, COUNT(*) AS count
FROM sqlite_master
WHERE type = 'table'
  AND name IN (
    'user_subscriptions', 'subscription_features', 'subscription_transactions',
    'condition_game_modifiers', 'condition_nutrition_rules', 'condition_onboarding_flow',
    'achievement_tiers', 'user_achievement_tier_progress',
    'daily_login_calendar', 'user_daily_logins', 'login_streak_milestones',
    'boss_encounters', 'boss_mechanics', 'boss_loot_table', 'user_boss_progress', 'boss_condition_links',
    'guilds', 'guild_members', 'guild_ranks', 'guild_challenges', 'guild_challenge_progress',
    'guild_chat_messages', 'guild_level_requirements', 'guild_perks',
    'crafting_quality_tiers', 'crafting_recipes', 'crafting_materials',
    'user_crafting_inventory', 'user_crafting_mastery', 'crafting_condition_bonuses',
    'pet_species', 'pet_evolution_stages', 'user_pets', 'pet_care_actions', 'pet_abilities', 'pet_decay_rules',
    'partner_applications', 'partner_contracts', 'partner_contract_terms', 'partner_performance_metrics',
    'medical_specialties', 'medical_sub_specialties', 'doctor_profiles',
    'doctor_game_stat_access', 'doctor_availability_slots', 'doctor_patient_access_log',
    'consultation_bookings', 'consultation_receipts', 'referral_transactions',
    'referral_commission_rules', 'platform_revenue_ledger', 'payout_requests',
    'world_map_regions', 'region_unlock_requirements', 'region_content', 'user_region_progress'
  );

-- Count all new views
SELECT 'NEW VIEWS' AS check_type, COUNT(*) AS count
FROM sqlite_master
WHERE type = 'view'
  AND name IN (
    'v_daily_platform_revenue', 'v_partner_performance_dashboard',
    'v_subscription_analytics', 'v_consultation_revenue_breakdown',
    'v_user_complete_profile', 'v_platform_health_summary'
  );

-- Count all new indexes
SELECT 'NEW INDEXES' AS check_type, COUNT(*) AS count
FROM sqlite_master
WHERE type = 'index'
  AND name LIKE 'idx_%'
  AND name IN (
    SELECT name FROM sqlite_master WHERE type = 'index' AND sql IS NOT NULL
  );

-- Overall database summary
SELECT 'TOTAL TABLES' AS metric, COUNT(*) AS value FROM sqlite_master WHERE type = 'table'
UNION ALL
SELECT 'TOTAL VIEWS', COUNT(*) FROM sqlite_master WHERE type = 'view'
UNION ALL
SELECT 'TOTAL INDEXES', COUNT(*) FROM sqlite_master WHERE type = 'index' AND sql IS NOT NULL;
