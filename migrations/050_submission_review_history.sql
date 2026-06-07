-- Migration 050: Submission Review History
-- Complete audit trail of all review actions and decisions
-- Part of User Submission System (Phase 5)

-- ============================================================================
-- SUBMISSION_REVIEW_HISTORY TABLE
-- ============================================================================
-- Records every action taken during review process

CREATE TABLE submission_review_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Submission reference
    submission_type VARCHAR(50) NOT NULL,
    submission_id INTEGER NOT NULL,
    review_queue_id INTEGER NOT NULL,

    -- Action details
    action_type VARCHAR(50) NOT NULL,  -- assigned / started_review / requested_revision / approved / rejected / reassigned / escalated
    action_by_user_id INTEGER NOT NULL,
    action_by_role VARCHAR(50),

    -- Previous and new values
    previous_status VARCHAR(20),
    new_status VARCHAR(20),
    previous_reviewer_id INTEGER,
    new_reviewer_id INTEGER,

    -- Decision details
    decision VARCHAR(20),  -- approve / reject / needs_revision
    decision_notes TEXT,
    approval_conditions TEXT,  -- "Approved with condition: Update sodium content"

    -- Revision requests
    revision_requested BOOLEAN DEFAULT FALSE,
    revision_requirements TEXT,  -- What needs to be changed?
    revision_deadline TIMESTAMP,

    -- Quality assessment
    data_quality_rating INTEGER,  -- 1-5
    completeness_rating INTEGER,  -- 1-5
    accuracy_rating INTEGER,  -- 1-5

    -- Time tracking
    time_spent_minutes INTEGER,

    -- Metadata
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(50),

    FOREIGN KEY (review_queue_id) REFERENCES submission_review_queue(id),
    FOREIGN KEY (action_by_user_id) REFERENCES users(id),
    FOREIGN KEY (previous_reviewer_id) REFERENCES users(id),
    FOREIGN KEY (new_reviewer_id) REFERENCES users(id),

    CHECK (action_type IN ('assigned', 'started_review', 'paused_review', 'resumed_review', 'requested_revision', 'approved', 'rejected', 'reassigned', 'escalated', 'comment_added'))
);

CREATE INDEX idx_review_history_submission ON submission_review_history(submission_type, submission_id, action_timestamp DESC);
CREATE INDEX idx_review_history_reviewer ON submission_review_history(action_by_user_id, action_timestamp DESC);
CREATE INDEX idx_review_history_queue ON submission_review_history(review_queue_id, action_timestamp DESC);


-- ============================================================================
-- REVIEW_COMMENTS TABLE
-- ============================================================================
-- Detailed comments during review process

CREATE TABLE review_comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    submission_type VARCHAR(50) NOT NULL,
    submission_id INTEGER NOT NULL,
    review_queue_id INTEGER NOT NULL,

    -- Comment details
    comment_by_user_id INTEGER NOT NULL,
    comment_by_role VARCHAR(50),
    comment_text TEXT NOT NULL,
    comment_type VARCHAR(50),  -- question / concern / suggestion / note / approval_comment

    -- Addressed to
    addressed_to_user_id INTEGER,  -- If asking submitter for clarification
    requires_response BOOLEAN DEFAULT FALSE,
    response_received BOOLEAN DEFAULT FALSE,
    response_text TEXT,
    responded_at TIMESTAMP,

    -- Visibility
    is_internal BOOLEAN DEFAULT FALSE,  -- Internal comment (not shown to submitter)
    is_public BOOLEAN DEFAULT TRUE,  -- Show in final approval/rejection message

    -- Metadata
    commented_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (review_queue_id) REFERENCES submission_review_queue(id),
    FOREIGN KEY (comment_by_user_id) REFERENCES users(id),
    FOREIGN KEY (addressed_to_user_id) REFERENCES users(id)
);

CREATE INDEX idx_review_comments_submission ON review_comments(submission_type, submission_id, commented_at DESC);
CREATE INDEX idx_review_comments_requires_response ON review_comments(requires_response, response_received);


-- ============================================================================
-- REVIEW_DECISION_FACTORS TABLE
-- ============================================================================
-- Structured reasons for approval/rejection decisions

CREATE TABLE review_decision_factors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    review_history_id INTEGER NOT NULL,
    submission_type VARCHAR(50) NOT NULL,
    submission_id INTEGER NOT NULL,

    -- Decision factor
    factor_category VARCHAR(50) NOT NULL,  -- data_quality / safety / completeness / accuracy / cultural_appropriateness / regulatory_compliance
    factor_name VARCHAR(100) NOT NULL,
    factor_status VARCHAR(20) NOT NULL,  -- passed / failed / needs_improvement
    factor_weight REAL DEFAULT 1.0,  -- Importance of this factor

    -- Details
    factor_notes TEXT,
    evidence TEXT,  -- Supporting evidence for this assessment

    -- Metadata
    assessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assessed_by_user_id INTEGER,

    FOREIGN KEY (review_history_id) REFERENCES submission_review_history(id),
    FOREIGN KEY (assessed_by_user_id) REFERENCES users(id)
);

CREATE INDEX idx_decision_factors_history ON review_decision_factors(review_history_id);
CREATE INDEX idx_decision_factors_submission ON review_decision_factors(submission_type, submission_id);


-- ============================================================================
-- USAGE FLOW: Recording Review Actions
-- ============================================================================

-- EXAMPLE: Reviewer approves food submission

-- STEP 1: Record approval action
-- INSERT OR IGNORE INTO submission_review_history (
--     submission_type, submission_id, review_queue_id,
--     action_type, action_by_user_id, action_by_role,
--     previous_status, new_status,
--     decision, decision_notes,
--     data_quality_rating, completeness_rating, accuracy_rating,
--     time_spent_minutes
-- ) VALUES (
--     'food', 123, 456,
--     'approved', 789, 'nutritionist',
--     'in_review', 'approved',
--     'approve', 'Excellent submission. All nutritional data verified against FAO INFOODS database. Local names confirmed with community sources.',
--     5, 5, 5,
--     45
-- );

-- STEP 2: Record decision factors
-- INSERT OR IGNORE INTO review_decision_factors (review_history_id, submission_type, submission_id, factor_category, factor_name, factor_status, factor_notes) VALUES
-- (review_history_id, 'food', 123, 'data_quality', 'Nutritional data accuracy', 'passed', 'Cross-checked with FAO INFOODS. All macros within expected range.'),
-- (review_history_id, 'food', 123, 'completeness', 'Required fields', 'passed', 'All required nutritional fields provided. Local name verified.'),
-- (review_history_id, 'food', 123, 'cultural_appropriateness', 'Local significance', 'passed', 'Matembele is widely consumed in Uganda. Cultural context accurately described.'),
-- (review_history_id, 'food', 123, 'safety', 'Food safety concerns', 'passed', 'No known safety hazards. Common preparation methods are safe.');

-- STEP 3: Update food_submissions table
-- UPDATE food_submissions
-- SET status = 'approved',
--     reviewed_by = 789,
--     reviewed_at = NOW()
-- WHERE id = 123;

-- STEP 4: Copy to foods table (approved data goes live)
-- INSERT OR IGNORE INTO foods (name, local_name, category, energy_kcal, protein_g, ...)
-- SELECT food_name, local_name, food_category, energy_kcal, protein_g, ...
-- FROM food_submissions
-- WHERE id = 123;

-- STEP 5: Update review queue
-- UPDATE submission_review_queue
-- SET status = 'completed',
--     review_completed_at = NOW(),
--     review_duration_minutes = TIMESTAMPDIFF(MINUTE, review_started_at, NOW())
-- WHERE id = 456;

-- STEP 6: Update reviewer workload
-- UPDATE reviewer_workload
-- SET in_review_count = in_review_count - 1,
--     total_active = total_active - 1,
--     total_reviews_completed = total_reviews_completed + 1,
--     total_reviews_this_week = total_reviews_this_week + 1,
--     total_reviews_this_month = total_reviews_this_month + 1
-- WHERE reviewer_id = 789;

-- STEP 7: Notify submitter
-- - Send notification: "Your food submission 'Matembele' has been approved!"
-- - Award XP: 75 XP for approved food submission
-- - UPDATE users SET afya_points = afya_points + 200 WHERE id = submitter_id


-- ============================================================================
-- EXAMPLE: Reviewer requests revision
-- ============================================================================

-- STEP 1: Record revision request
-- INSERT OR IGNORE INTO submission_review_history (
--     submission_type, submission_id, review_queue_id,
--     action_type, action_by_user_id, action_by_role,
--     previous_status, new_status,
--     decision, decision_notes,
--     revision_requested, revision_requirements, revision_deadline,
--     data_quality_rating, completeness_rating
-- ) VALUES (
--     'medication', 456, 789,
--     'requested_revision', 123, 'pharmacist',
--     'in_review', 'needs_revision',
--     'needs_revision', 'Submission is mostly complete but requires additional safety information.',
--     TRUE, 'Please add: 1. Black box warnings if any, 2. Pregnancy category, 3. Known drug interactions with common medications', NOW() + INTERVAL 7 DAY,
--     4, 3
-- );

-- STEP 2: Add detailed comments
-- INSERT OR IGNORE INTO review_comments (submission_type, submission_id, review_queue_id, comment_by_user_id, comment_by_role, comment_text, comment_type, addressed_to_user_id, requires_response) VALUES
-- (456, 789, 123, 'pharmacist', 'Black box warnings: Please check FDA/WHO databases for any serious warnings associated with this medication.', 'concern', submitter_id, TRUE),
-- (456, 789, 123, 'pharmacist', 'Drug interactions: At minimum, please check interactions with: 1. Common antidiabetics (Metformin), 2. Common antihypertensives (ACE inhibitors), 3. Common antibiotics', 'suggestion', submitter_id, TRUE);

-- STEP 3: Update medication_submissions table
-- UPDATE medication_submissions
-- SET status = 'needs_revision',
--     reviewed_by_pharmacist_id = 123,
--     reviewed_at = NOW(),
--     revision_requested_notes = 'Please add: 1. Black box warnings, 2. Pregnancy category, 3. Drug interactions'
-- WHERE id = 456;

-- STEP 4: Notify submitter
-- - Email notification with detailed revision requirements
-- - In-app notification: "Revision requested for your medication submission"


-- ============================================================================
-- ANALYTICS QUERIES
-- ============================================================================

-- Average review time by submission type:
-- SELECT
--     submission_type,
--     AVG(review_duration_minutes) AS avg_review_time_min,
--     MIN(review_duration_minutes) AS min_review_time_min,
--     MAX(review_duration_minutes) AS max_review_time_min
-- FROM submission_review_queue
-- WHERE status = 'completed'
-- GROUP BY submission_type;

-- Reviewer performance:
-- SELECT
--     srh.action_by_user_id,
--     u.username AS reviewer_name,
--     COUNT(*) AS reviews_completed,
--     AVG(srh.time_spent_minutes) AS avg_time_minutes,
--     SUM(CASE WHEN srh.decision = 'approve' THEN 1 ELSE 0 END) AS approvals,
--     SUM(CASE WHEN srh.decision = 'reject' THEN 1 ELSE 0 END) AS rejections,
--     SUM(CASE WHEN srh.decision = 'needs_revision' THEN 1 ELSE 0 END) AS revisions_requested
-- FROM submission_review_history srh
-- JOIN users u ON srh.action_by_user_id = u.id
-- WHERE srh.action_type IN ('approved', 'rejected', 'requested_revision')
-- GROUP BY srh.action_by_user_id;

-- Approval rates by submission type:
-- SELECT
--     submission_type,
--     COUNT(*) AS total_submissions,
--     SUM(CASE WHEN decision = 'approve' THEN 1 ELSE 0 END) AS approved,
--     SUM(CASE WHEN decision = 'reject' THEN 1 ELSE 0 END) AS rejected,
--     SUM(CASE WHEN decision = 'needs_revision' THEN 1 ELSE 0 END) AS needs_revision,
--     ROUND(SUM(CASE WHEN decision = 'approve' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS approval_rate_pct
-- FROM submission_review_history
-- WHERE action_type IN ('approved', 'rejected', 'requested_revision')
-- GROUP BY submission_type;
