-- Migration 052: Submission Approvals
-- Post-approval workflow: copy to live tables, notify submitter, award rewards
-- Part of User Submission System (Phase 5)

-- ============================================================================
-- SUBMISSION_APPROVALS TABLE
-- ============================================================================
-- Records when submissions are approved and copied to production tables

CREATE TABLE submission_approvals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Submission reference
    submission_type VARCHAR(50) NOT NULL,
    submission_id INTEGER NOT NULL,
    review_queue_id INTEGER NOT NULL,
    review_history_id INTEGER NOT NULL,

    -- Approval details
    approved_by_user_id INTEGER NOT NULL,
    approved_by_role VARCHAR(50),
    approved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Production record created
    production_table VARCHAR(100) NOT NULL,  -- foods / beverages / medications / recipes
    production_record_id INTEGER NOT NULL,  -- ID in production table
    production_status VARCHAR(20) DEFAULT 'active',  -- active / archived / deleted

    -- Approval conditions
    conditional_approval BOOLEAN DEFAULT FALSE,
    approval_conditions TEXT,  -- "Approved pending final nutrient verification"
    conditions_met BOOLEAN,
    conditions_met_at TIMESTAMP,

    -- Quality metrics (from review)
    data_quality_rating INTEGER,
    completeness_rating INTEGER,
    accuracy_rating INTEGER,
    overall_quality_score REAL,  -- Weighted average

    -- Attribution
    submitter_user_id INTEGER NOT NULL,
    submitter_credited BOOLEAN DEFAULT TRUE,
    attribution_text VARCHAR(200),  -- "Submitted by Sarah Nakato, verified by Dr. Jane Okello"

    -- Rewards
    xp_awarded INTEGER,
    afya_points_awarded INTEGER,
    achievement_unlocked_id INTEGER,

    -- Notifications
    submitter_notified BOOLEAN DEFAULT FALSE,
    notified_at TIMESTAMP,
    notification_message TEXT,

    -- Metadata
    approval_notes TEXT,
    public_acknowledgment BOOLEAN DEFAULT TRUE,  -- Show in community feed?

    FOREIGN KEY (review_queue_id) REFERENCES submission_review_queue(id),
    FOREIGN KEY (review_history_id) REFERENCES submission_review_history(id),
    FOREIGN KEY (approved_by_user_id) REFERENCES users(id),
    FOREIGN KEY (submitter_user_id) REFERENCES users(id),
    FOREIGN KEY (achievement_unlocked_id) REFERENCES achievements(id),

    UNIQUE(submission_type, submission_id)
);

CREATE INDEX idx_approvals_submission ON submission_approvals(submission_type, submission_id);
CREATE INDEX idx_approvals_user ON submission_approvals(submitter_user_id, approved_at DESC);
CREATE INDEX idx_approvals_production ON submission_approvals(production_table, production_record_id);


-- ============================================================================
-- APPROVED_CONTENT_AUDIT TABLE
-- ============================================================================
-- Track quality of approved content over time (for feedback loop)

CREATE TABLE approved_content_audit (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    submission_approval_id INTEGER NOT NULL UNIQUE,
    production_table VARCHAR(100) NOT NULL,
    production_record_id INTEGER NOT NULL,

    -- Usage tracking
    times_used INTEGER DEFAULT 0,  -- How many times has this been used? (meal logs, recipe views, etc.)
    times_favorited INTEGER DEFAULT 0,
    times_shared INTEGER DEFAULT 0,

    -- User feedback
    user_rating_avg REAL,  -- Average user rating (1-5 stars)
    user_rating_count INTEGER DEFAULT 0,
    positive_feedback_count INTEGER DEFAULT 0,
    negative_feedback_count INTEGER DEFAULT 0,

    -- Issues reported
    issues_reported_count INTEGER DEFAULT 0,
    issue_types TEXT,  -- JSON array: ["incorrect_nutrition", "safety_concern", "cultural_inaccuracy"]

    -- Quality status
    quality_status VARCHAR(20) DEFAULT 'good',  -- excellent / good / acceptable / needs_review / flagged
    needs_re_review BOOLEAN DEFAULT FALSE,
    re_review_reason TEXT,

    -- Last audit
    last_audited_at TIMESTAMP,
    audited_by_user_id INTEGER,
    audit_notes TEXT,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (submission_approval_id) REFERENCES submission_approvals(id),
    FOREIGN KEY (audited_by_user_id) REFERENCES users(id)
);

CREATE INDEX idx_content_audit_quality ON approved_content_audit(quality_status, needs_re_review);
CREATE INDEX idx_content_audit_production ON approved_content_audit(production_table, production_record_id);


-- ============================================================================
-- SUBMISSION_REWARDS TABLE
-- ============================================================================
-- Define rewards for successful submissions

CREATE TABLE submission_rewards (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    submission_type VARCHAR(50) NOT NULL,

    -- Reward tiers based on quality and impact
    tier VARCHAR(20) NOT NULL,  -- basic / good / excellent / exceptional
    tier_criteria TEXT,  -- What qualifies for this tier?

    -- Rewards
    base_xp INTEGER NOT NULL,
    base_afya_points INTEGER NOT NULL,
    bonus_xp_multiplier REAL DEFAULT 1.0,

    -- Special rewards
    unlock_achievement_id INTEGER,
    unlock_cosmetic_id INTEGER,
    unlock_badge BOOLEAN DEFAULT FALSE,

    -- Requirements
    min_quality_rating INTEGER,  -- Minimum overall quality score
    min_usage_count INTEGER,  -- Minimum times used by community
    requires_verification BOOLEAN DEFAULT TRUE,

    is_active BOOLEAN DEFAULT TRUE,

    FOREIGN KEY (unlock_achievement_id) REFERENCES achievements(id),
    FOREIGN KEY (unlock_cosmetic_id) REFERENCES avatar_cosmetics(id),

    UNIQUE(submission_type, tier)
);

INSERT OR IGNORE INTO submission_rewards (submission_type, tier, tier_criteria, base_xp, base_afya_points, min_quality_rating) VALUES
('food', 'basic', 'Complete submission with valid nutrition data', 50, 200, 3),
('food', 'good', 'High-quality submission with verified data sources', 75, 300, 4),
('food', 'excellent', 'Exceptional submission with lab measurements and cultural context', 150, 500, 5),
('beverage', 'basic', 'Complete submission with basic info', 40, 150, 3),
('beverage', 'good', 'Detailed submission with health info', 60, 250, 4),
('medication', 'basic', 'Complete medication info with safety data', 100, 400, 4),
('medication', 'excellent', 'Comprehensive medication profile with full interaction data', 250, 800, 5),
('recipe', 'basic', 'Complete recipe with clear instructions', 75, 300, 3),
('recipe', 'good', 'Well-documented recipe with health benefits', 100, 400, 4),
('recipe', 'excellent', 'Exceptional recipe with nutrition calculations and cultural significance', 200, 700, 5);


-- ============================================================================
-- USAGE FLOW: Approving Submission
-- ============================================================================

-- EXAMPLE: Approving food submission

-- STEP 1: Reviewer approves (already recorded in submission_review_history)

-- STEP 2: Determine reward tier
-- - Quality ratings: data=5, completeness=5, accuracy=5
-- - Overall quality: (5+5+5)/3 = 5.0
-- - Tier: "excellent" (quality>=5)
-- - Query submission_rewards: tier='excellent', submission_type='food'
-- - base_xp=150, base_afya_points=500

-- STEP 3: Copy to production table (foods)
-- INSERT OR IGNORE INTO foods (name, local_name, category, region_code, is_local, is_verified, energy_kcal, protein_g, carbs_g, ...)
-- SELECT food_name, local_name, food_category, region_code, is_local, TRUE AS is_verified, energy_kcal, protein_g, carbs_g, ...
-- FROM food_submissions
-- WHERE id = 123;
-- → new_food_id = 1001

-- STEP 4: Record approval
-- INSERT OR IGNORE INTO submission_approvals (
--     submission_type, submission_id, review_queue_id, review_history_id,
--     approved_by_user_id, approved_by_role,
--     production_table, production_record_id,
--     data_quality_rating, completeness_rating, accuracy_rating, overall_quality_score,
--     submitter_user_id, submitter_credited, attribution_text,
--     xp_awarded, afya_points_awarded,
--     notification_message, public_acknowledgment
-- ) VALUES (
--     'food', 123, 456, 789,
--     reviewer_id, 'nutritionist',
--     'foods', 1001,
--     5, 5, 5, 5.0,
--     submitter_id, TRUE, 'Submitted by Sarah Nakato, verified by Dr. Jane Okello (Nutritionist)',
--     150, 500,
--     '🎉 Your food submission "Matembele (Sweet Potato Leaves)" has been approved and is now live in the Vurafya database! You earned 150 XP and 500 Afya Points.',
--     TRUE
-- );

-- STEP 5: Award rewards
-- - XP transaction
-- INSERT OR IGNORE INTO user_xp_transactions (user_id, xp_earning_rule_id, base_xp, total_xp, related_entity_type, related_entity_id, description)
-- VALUES (submitter_id, 16, 150, 150, 'food_submission', 123, 'Food submission approved: Matembele');

-- UPDATE avatar_stats
-- SET social_based_xp = social_based_xp + 150, total_xp_earned = total_xp_earned + 150
-- WHERE user_id = submitter_id;

-- - Afya Points
-- UPDATE users
-- SET afya_points = afya_points + 500
-- WHERE id = submitter_id;

-- STEP 6: Create audit record
-- INSERT OR IGNORE INTO approved_content_audit (submission_approval_id, production_table, production_record_id, quality_status)
-- VALUES (approval_id, 'foods', 1001, 'excellent');

-- STEP 7: Notify submitter
-- - In-app notification
-- - Email notification
-- - Public acknowledgment in community feed:
--   "🎉 New food added to database: Matembele (Sweet Potato Leaves) - Submitted by @SarahNakato"
--
-- UPDATE submission_approvals
-- SET submitter_notified = TRUE, notified_at = NOW()
-- WHERE id = approval_id;

-- STEP 8: Update food_submissions status
-- UPDATE food_submissions
-- SET status = 'approved', reviewed_by = reviewer_id, reviewed_at = NOW()
-- WHERE id = 123;

-- STEP 9: Update review queue
-- UPDATE submission_review_queue
-- SET status = 'completed', review_completed_at = NOW()
-- WHERE id = 456;

-- STEP 10: Update reviewer workload
-- (Already handled in previous migrations)


-- ============================================================================
-- USAGE FLOW: Conditional Approval
-- ============================================================================

-- SCENARIO: Approve medication but pending final safety check

-- STEP 1: Record conditional approval
-- INSERT OR IGNORE INTO submission_approvals (
--     submission_type, submission_id, review_queue_id, review_history_id,
--     approved_by_user_id, approved_by_role,
--     production_table, production_record_id,
--     conditional_approval, approval_conditions, conditions_met,
--     submitter_user_id, xp_awarded, afya_points_awarded
-- ) VALUES (
--     'medication', 456, 789, review_history_id,
--     pharmacist_id, 'pharmacist',
--     'medications', new_medication_id,
--     TRUE, 'Final safety check: Verify no recent FDA/WHO safety alerts for this drug', FALSE,
--     submitter_id, 100, 400
-- );

-- STEP 2: Copy to production but flag as "pending_verification"
-- INSERT OR IGNORE INTO medications (..., verification_status)
-- SELECT ..., 'pending_verification'
-- FROM medication_submissions
-- WHERE id = 456;

-- STEP 3: Notify submitter
-- "Your medication submission has been conditionally approved pending final safety verification. It will go live once verification is complete."

-- STEP 4: When conditions are met
-- UPDATE submission_approvals
-- SET conditions_met = TRUE, conditions_met_at = NOW()
-- WHERE id = approval_id;
--
-- UPDATE medications
-- SET verification_status = 'verified'
-- WHERE id = new_medication_id;
--
-- Notify submitter: "Your medication submission is now fully approved and live!"


-- ============================================================================
-- ANALYTICS: Submission Success Rates
-- ============================================================================

-- Approval rates by submission type:
-- SELECT
--     fs.submission_type,
--     COUNT(*) AS total_submissions,
--     SUM(CASE WHEN sa.id IS NOT NULL THEN 1 ELSE 0 END) AS approved,
--     ROUND(SUM(CASE WHEN sa.id IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS approval_rate_pct
-- FROM (
--     SELECT 'food' AS submission_type, id FROM food_submissions
--     UNION ALL
--     SELECT 'beverage', id FROM beverage_submissions
--     UNION ALL
--     SELECT 'medication', id FROM medication_submissions
--     UNION ALL
--     SELECT 'recipe', id FROM recipe_submissions
-- ) fs
-- LEFT JOIN submission_approvals sa ON fs.submission_type = sa.submission_type AND fs.id = sa.submission_id
-- GROUP BY fs.submission_type;

-- Top contributors:
-- SELECT
--     u.username,
--     COUNT(*) AS submissions_approved,
--     SUM(sa.xp_awarded) AS total_xp_earned,
--     SUM(sa.afya_points_awarded) AS total_afya_points_earned,
--     ROUND(AVG(sa.overall_quality_score), 2) AS avg_quality_score
-- FROM submission_approvals sa
-- JOIN users u ON sa.submitter_user_id = u.id
-- GROUP BY u.username
-- ORDER BY submissions_approved DESC
-- LIMIT 20;

-- Quality distribution:
-- SELECT
--     CASE
--         WHEN overall_quality_score >= 4.5 THEN 'Exceptional (4.5-5.0)'
--         WHEN overall_quality_score >= 4.0 THEN 'Excellent (4.0-4.4)'
--         WHEN overall_quality_score >= 3.5 THEN 'Good (3.5-3.9)'
--         WHEN overall_quality_score >= 3.0 THEN 'Acceptable (3.0-3.4)'
--         ELSE 'Needs Improvement (<3.0)'
--     END AS quality_tier,
--     COUNT(*) AS submission_count,
--     ROUND(AVG(xp_awarded)) AS avg_xp,
--     ROUND(AVG(afya_points_awarded)) AS avg_afya_points
-- FROM submission_approvals
-- GROUP BY quality_tier
-- ORDER BY MIN(overall_quality_score) DESC;
