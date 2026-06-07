-- Migration 049: Submission Review Queue
-- Unified queue for admin/pharmacist to review all submission types
-- Part of User Submission System (Phase 5)

-- ============================================================================
-- SUBMISSION_REVIEW_QUEUE TABLE
-- ============================================================================
-- Single queue for all submission types with priority management

CREATE TABLE submission_review_queue (
    id SERIAL PRIMARY KEY,

    -- Submission identification
    submission_type VARCHAR(50) NOT NULL,  -- food / beverage / medication / recipe
    submission_id INTEGER NOT NULL,  -- ID in respective table
    submission_name VARCHAR(200),  -- For display in queue

    -- Submitter
    submitted_by_user_id INTEGER NOT NULL,
    submitter_name VARCHAR(100),

    -- Priority (medications highest priority due to safety)
    priority INTEGER NOT NULL,  -- 1-5 (1=lowest, 5=critical)
    auto_priority_reason VARCHAR(100),  -- Why this priority was assigned

    -- Assignment
    assigned_to_reviewer_id INTEGER,
    reviewer_role VARCHAR(50),  -- admin / nutritionist / pharmacist / community_moderator
    assigned_at TIMESTAMP,
    assignment_method VARCHAR(50),  -- auto_assign / manual_assign / self_claimed

    -- Status
    status VARCHAR(20) DEFAULT 'pending',
    status_changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Review tracking
    review_started_at TIMESTAMP,
    review_completed_at TIMESTAMP,
    review_duration_minutes INTEGER,  -- How long did review take?

    -- Urgency
    is_urgent BOOLEAN DEFAULT FALSE,
    urgent_reason TEXT,
    escalation_level INTEGER DEFAULT 0,  -- 0=normal, 1=escalated once, 2=escalated twice

    -- SLA (Service Level Agreement) tracking
    sla_target_hours INTEGER,  -- Expected review time
    sla_deadline TIMESTAMP,
    is_overdue BOOLEAN DEFAULT FALSE,
    hours_overdue DOUBLE PRECISION,

    -- Metadata
    entered_queue_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (submitted_by_user_id) REFERENCES users(id),
    FOREIGN KEY (assigned_to_reviewer_id) REFERENCES users(id),

    CHECK (submission_type IN ('food', 'beverage', 'medication', 'recipe')),
    CHECK (status IN ('pending', 'assigned', 'in_review', 'completed', 'blocked')),
    CHECK (priority BETWEEN 1 AND 5),
    UNIQUE(submission_type, submission_id)
);

CREATE INDEX idx_review_queue_status ON submission_review_queue(status, priority DESC, entered_queue_at);
CREATE INDEX idx_review_queue_assigned ON submission_review_queue(assigned_to_reviewer_id, status);
CREATE INDEX idx_review_queue_overdue ON submission_review_queue(is_overdue, sla_deadline);
CREATE INDEX idx_review_queue_type ON submission_review_queue(submission_type, status);


-- ============================================================================
-- REVIEWER_WORKLOAD TABLE
-- ============================================================================
-- Track current workload of each reviewer to enable load balancing

CREATE TABLE reviewer_workload (
    reviewer_id INTEGER PRIMARY KEY,
    reviewer_role VARCHAR(50) NOT NULL,

    -- Current assignments
    pending_count INTEGER DEFAULT 0,
    assigned_count INTEGER DEFAULT 0,
    in_review_count INTEGER DEFAULT 0,
    total_active INTEGER DEFAULT 0,  -- Sum of above

    -- Capacity
    max_concurrent_reviews INTEGER DEFAULT 10,
    current_utilization_pct DOUBLE PRECISION DEFAULT 0,  -- (total_active / max_concurrent) × 100

    -- Performance metrics
    avg_review_time_minutes DOUBLE PRECISION,
    total_reviews_completed INTEGER DEFAULT 0,
    total_reviews_this_week INTEGER DEFAULT 0,
    total_reviews_this_month INTEGER DEFAULT 0,

    -- Availability
    is_available BOOLEAN DEFAULT TRUE,
    away_reason VARCHAR(100),  -- "vacation", "sick leave", "overloaded"
    available_from TIMESTAMP,

    -- Metadata
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (reviewer_id) REFERENCES users(id)
);

CREATE INDEX idx_workload_available ON reviewer_workload(is_available, current_utilization_pct);


-- ============================================================================
-- REVIEW_SLA_TARGETS TABLE
-- ============================================================================
-- Defines expected review times for different submission types

CREATE TABLE review_sla_targets (
    submission_type VARCHAR(50) PRIMARY KEY,
    priority_1_hours INTEGER,  -- Low priority
    priority_2_hours INTEGER,
    priority_3_hours INTEGER,
    priority_4_hours INTEGER,
    priority_5_hours INTEGER,  -- Critical priority

    escalation_threshold_hours INTEGER,  -- When to escalate if not reviewed
    max_escalations INTEGER DEFAULT 2,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO review_sla_targets (submission_type, priority_1_hours, priority_2_hours, priority_3_hours, priority_4_hours, priority_5_hours, escalation_threshold_hours, max_escalations) VALUES
('food', 168, 72, 48, 24, 12, 48, 2),  -- Food: 1 week (low) to 12 hours (critical)
('beverage', 168, 72, 48, 24, 12, 48, 2),
('medication', 48, 24, 12, 6, 2, 6, 3),  -- Medications: Urgent (2-48 hours)
('recipe', 336, 168, 72, 48, 24, 72, 2);  -- Recipes: 2 weeks (low) to 24 hours (critical)


-- ============================================================================
-- AUTO-ASSIGNMENT RULES TABLE
-- ============================================================================
-- Rules for automatically assigning submissions to reviewers

CREATE TABLE auto_assignment_rules (
    id SERIAL PRIMARY KEY,
    submission_type VARCHAR(50) NOT NULL,

    -- Assignment criteria
    requires_role VARCHAR(50) NOT NULL,  -- pharmacist / nutritionist / admin
    priority_threshold INTEGER,  -- Only auto-assign if priority >= threshold
    max_workload_pct DOUBLE PRECISION DEFAULT 80,  -- Don't assign if reviewer >80% capacity

    -- Assignment method
    assignment_method VARCHAR(50) DEFAULT 'round_robin',  -- round_robin / lowest_workload / specialty_match

    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO auto_assignment_rules VALUES
(1, 'medication', 'pharmacist', 1, 70, 'lowest_workload', TRUE, CURRENT_TIMESTAMP),
(2, 'food', 'nutritionist', 2, 80, 'round_robin', TRUE, CURRENT_TIMESTAMP),
(3, 'beverage', 'admin', 2, 80, 'round_robin', TRUE, CURRENT_TIMESTAMP),
(4, 'recipe', 'community_moderator', 1, 90, 'lowest_workload', TRUE, CURRENT_TIMESTAMP);


-- ============================================================================
-- USAGE FLOW: Adding Submission to Queue
-- ============================================================================

-- EXAMPLE: User submits food
-- INSERT INTO food_submissions (...) → food_submission_id = 123
--
-- STEP 1: Determine priority
-- - Is essential food? → Priority 4
-- - Is traditional/cultural? → Priority 3
-- - Is rare/unique? → Priority 2
-- - Is common variant? → Priority 1
--
-- STEP 2: Add to queue
-- INSERT INTO submission_review_queue (
--     submission_type, submission_id, submission_name,
--     submitted_by_user_id, submitter_name,
--     priority, auto_priority_reason,
--     reviewer_role, sla_target_hours, sla_deadline, entered_queue_at
-- ) VALUES (
--     'food', 123, 'Matembele (Sweet Potato Leaves)',
--     456, 'Sarah Nakato',
--     4, 'Essential local vegetable',
--     'nutritionist', 24, NOW() + INTERVAL 24 HOUR, NOW()
-- );

-- STEP 3: Auto-assign (if rules allow)
-- - Query auto_assignment_rules WHERE submission_type = 'food'
-- - requires_role = 'nutritionist', priority_threshold = 2
-- - Priority 4 >= 2 ✅ (eligible for auto-assignment)
--
-- - Query reviewer_workload WHERE reviewer_role = 'nutritionist' AND is_available = TRUE AND current_utilization_pct < 80
-- - ORDER BY total_active ASC (lowest_workload method)
-- - SELECT reviewer_id = 789
--
-- - UPDATE submission_review_queue SET assigned_to_reviewer_id = 789, status = 'assigned', assigned_at = NOW()
-- - UPDATE reviewer_workload SET assigned_count = assigned_count + 1, total_active = total_active + 1 WHERE reviewer_id = 789

-- STEP 4: Notify reviewer
-- - Send notification: "New food submission assigned: Matembele"
-- - Email/push notification


-- ============================================================================
-- USAGE FLOW: Reviewer Claims Submission
-- ============================================================================

-- STEP 1: Reviewer views queue
-- SELECT * FROM submission_review_queue
-- WHERE status = 'pending' OR (assigned_to_reviewer_id = :reviewer_id AND status = 'assigned')
-- ORDER BY priority DESC, entered_queue_at ASC
-- LIMIT 20;

-- STEP 2: Reviewer claims submission
-- UPDATE submission_review_queue
-- SET assigned_to_reviewer_id = :reviewer_id,
--     status = 'assigned',
--     assigned_at = NOW(),
--     assignment_method = 'self_claimed'
-- WHERE id = :queue_id AND (assigned_to_reviewer_id IS NULL OR status = 'pending');

-- STEP 3: Reviewer starts review
-- UPDATE submission_review_queue
-- SET status = 'in_review',
--     review_started_at = NOW()
-- WHERE id = :queue_id;


-- ============================================================================
-- SLA MONITORING (Run Periodically)
-- ============================================================================

-- Check for overdue submissions:
-- UPDATE submission_review_queue
-- SET is_overdue = TRUE,
--     hours_overdue = (TIMESTAMPDIFF(HOUR, sla_deadline, NOW()))
-- WHERE sla_deadline < NOW() AND status NOT IN ('completed', 'blocked');

-- Escalate overdue submissions:
-- UPDATE submission_review_queue
-- SET escalation_level = escalation_level + 1,
--     priority = LEAST(priority + 1, 5)
-- WHERE is_overdue = TRUE
--   AND escalation_level < (SELECT max_escalations FROM review_sla_targets WHERE submission_type = submission_review_queue.submission_type);


-- ============================================================================
-- REVIEWER DASHBOARD QUERIES
-- ============================================================================

-- My assigned submissions:
-- SELECT * FROM submission_review_queue
-- WHERE assigned_to_reviewer_id = :reviewer_id AND status IN ('assigned', 'in_review')
-- ORDER BY priority DESC, sla_deadline ASC;

-- Available submissions (not assigned):
-- SELECT * FROM submission_review_queue
-- WHERE status = 'pending' AND reviewer_role = :my_role
-- ORDER BY priority DESC, entered_queue_at ASC;

-- Overdue submissions (urgent):
-- SELECT * FROM submission_review_queue
-- WHERE is_overdue = TRUE AND assigned_to_reviewer_id = :reviewer_id
-- ORDER BY hours_overdue DESC;
