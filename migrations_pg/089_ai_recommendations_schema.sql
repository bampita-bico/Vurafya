-- Migration 089: Expand ai_recommendations table + social good enhancements
-- ai_recommendations was created as a stub (id only). Add full columns.

-- ============================================================================
-- AI RECOMMENDATIONS - full schema
-- ============================================================================

-- Add columns to existing stub table
ALTER TABLE ai_recommendations ADD COLUMN user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE ai_recommendations ADD COLUMN recommendation_type_id INTEGER REFERENCES ai_recommendation_types(id);
ALTER TABLE ai_recommendations ADD COLUMN title VARCHAR(200);
ALTER TABLE ai_recommendations ADD COLUMN message TEXT;
ALTER TABLE ai_recommendations ADD COLUMN severity VARCHAR(20) DEFAULT 'info';
    -- info | warning | critical
ALTER TABLE ai_recommendations ADD COLUMN action_type VARCHAR(60);
    -- food_suggestion | food_restriction | medication_reminder | biometric_reminder | subscription_upsell | doctor_consult
ALTER TABLE ai_recommendations ADD COLUMN action_data TEXT;
    -- JSON: food_ids, nutrient_targets, etc.
ALTER TABLE ai_recommendations ADD COLUMN priority_score INTEGER DEFAULT 5;
ALTER TABLE ai_recommendations ADD COLUMN is_active BOOLEAN DEFAULT 1;
ALTER TABLE ai_recommendations ADD COLUMN is_dismissed BOOLEAN DEFAULT 0;
ALTER TABLE ai_recommendations ADD COLUMN dismissed_at TIMESTAMP;
ALTER TABLE ai_recommendations ADD COLUMN generated_at TIMESTAMP;
ALTER TABLE ai_recommendations ADD COLUMN expires_at TIMESTAMP;
ALTER TABLE ai_recommendations ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ai_rec_user_active ON ai_recommendations(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_ai_rec_severity ON ai_recommendations(severity);
CREATE INDEX IF NOT EXISTS idx_ai_rec_type ON ai_recommendations(recommendation_type_id);
