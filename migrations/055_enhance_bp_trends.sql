-- Migration 055: Enhance Blood Pressure Trends
-- Adds medication adherence and dietary context to blood pressure tracking
-- Part of Medical Core Infrastructure (Phase 1)

-- ============================================================================
-- ENHANCE BLOOD_PRESSURE_TRENDS TABLE
-- ============================================================================
-- Existing table tracks BP readings over time
-- Adding columns to enable correlation analysis:
-- - Did medication adherence affect BP control?
-- - Did sodium intake affect BP readings?
-- - Did potassium intake improve BP control? (K+ helps lower BP)

ALTER TABLE blood_pressure_trends ADD COLUMN medication_adherence_pct REAL;
ALTER TABLE blood_pressure_trends ADD COLUMN avg_sodium_intake_mg REAL;
ALTER TABLE blood_pressure_trends ADD COLUMN avg_potassium_intake_mg REAL;

-- Additional context columns for hypertension management
ALTER TABLE blood_pressure_trends ADD COLUMN stress_level INTEGER;  -- 1-10 scale
ALTER TABLE blood_pressure_trends ADD COLUMN sleep_quality INTEGER;  -- 1-10 scale
ALTER TABLE blood_pressure_trends ADD COLUMN physical_activity_min INTEGER;  -- Minutes of activity
ALTER TABLE blood_pressure_trends ADD COLUMN alcohol_consumed BOOLEAN DEFAULT FALSE;
ALTER TABLE blood_pressure_trends ADD COLUMN caffeine_consumed BOOLEAN DEFAULT FALSE;

-- Clinical interpretation
ALTER TABLE blood_pressure_trends ADD COLUMN bp_category VARCHAR(50);  -- normal / elevated / hypertension_stage1 / hypertension_stage2 / hypertensive_crisis
ALTER TABLE blood_pressure_trends ADD COLUMN requires_action BOOLEAN DEFAULT FALSE;

-- ============================================================================
-- BLOOD PRESSURE CATEGORIZATION (ACC/AHA 2017 Guidelines)
-- ============================================================================
-- Normal: <120/80
-- Elevated: 120-129/<80
-- Hypertension Stage 1: 130-139/80-89
-- Hypertension Stage 2: ≥140/≥90
-- Hypertensive Crisis: >180/>120 (emergency)

-- ============================================================================
-- CLINICAL NOTES
-- ============================================================================
-- Hypertension management through Vurafya:
--
-- 1. **Daily Monitoring**:
--    - User logs BP readings (morning and evening recommended)
--    - App tracks medication_adherence_pct from adherence_logs table
--    - App calculates avg_sodium_intake_mg from daily_nutrition_summary
--    - App calculates avg_potassium_intake_mg (K+ helps lower BP)
--
-- 2. **Correlation Analysis**:
--    - High sodium days → Higher BP readings?
--    - Missed medications → BP spike?
--    - Poor sleep → Elevated BP?
--    - Exercise days → Better BP control?
--
-- 3. **Dietary Recommendations**:
--    - IF BP >140/90 AND avg_sodium >2000mg THEN recommend low-sodium meals
--    - IF BP controlled AND sodium <1500mg THEN praise user
--    - IF BP elevated THEN suggest high-K foods (bananas, sweet potatoes)
--
-- 4. **Health Scoring**:
--    - bp_score component based on:
--      * BP readings in target range (40% weight)
--      * Medication adherence (30% weight)
--      * Sodium intake control (20% weight)
--      * Physical activity (10% weight)
--
-- 5. **Gamification Integration**:
--    - XP for logging BP daily (adherence streak)
--    - Milestone: 7 days in target range → 100 XP + badge
--    - Milestone: Sodium <1500mg for 30 days → 150 XP + avatar evolution
--    - Competition: Best BP control wins (motivates lifestyle changes)
--
-- Integration points:
-- - adherence_logs: Pull medication_adherence_pct
-- - daily_nutrition_summary: Pull avg_sodium_intake_mg, avg_potassium_intake_mg
-- - health_rules: IF BP >180/120 THEN emergency alert
-- - nutrient_targets: Hypertensive users get sodium <1500mg/day target
-- - avatar_health_milestones: Track BP improvement
