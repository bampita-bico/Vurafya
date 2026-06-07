-- Migration 051: Submission Resubmissions
-- Track revision iterations when users fix and resubmit
-- Part of User Submission System (Phase 5)

-- ============================================================================
-- SUBMISSION_RESUBMISSIONS TABLE
-- ============================================================================
-- Tracks each resubmission after revision request

CREATE TABLE submission_resubmissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Original submission reference
    submission_type VARCHAR(50) NOT NULL,
    original_submission_id INTEGER NOT NULL,
    review_queue_id INTEGER NOT NULL,

    -- Resubmission details
    resubmission_number INTEGER NOT NULL,  -- 1st revision, 2nd revision, etc.
    resubmitted_by_user_id INTEGER NOT NULL,
    resubmission_notes TEXT,  -- What did user change?

    -- Changes made (JSON documenting what changed)
    changes_summary TEXT,  -- "Updated sodium content, added black box warning, clarified dosing"
    changes_detail_json TEXT,  -- JSON: {"sodium_mg": {"old": 200, "new": 180}, "black_box_warning": {"old": null, "new": "..."}}

    -- Addressing review comments
    addressed_comments TEXT,  -- JSON array of comment IDs that were addressed
    unaddressed_comments TEXT,  -- JSON array of comment IDs still not addressed
    all_requirements_met BOOLEAN DEFAULT FALSE,

    -- Review cycle
    previous_status VARCHAR(20),  -- needs_revision
    new_status VARCHAR(20) DEFAULT 'pending',  -- Back to pending for re-review
    resubmitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Re-assignment
    assigned_to_same_reviewer BOOLEAN DEFAULT TRUE,
    new_reviewer_id INTEGER,

    FOREIGN KEY (resubmitted_by_user_id) REFERENCES users(id),
    FOREIGN KEY (review_queue_id) REFERENCES submission_review_queue(id),
    FOREIGN KEY (new_reviewer_id) REFERENCES users(id)
);

CREATE INDEX idx_resubmissions_submission ON submission_resubmissions(submission_type, original_submission_id);
CREATE INDEX idx_resubmissions_user ON submission_resubmissions(resubmitted_by_user_id, resubmitted_at DESC);
CREATE INDEX idx_resubmissions_queue ON submission_resubmissions(review_queue_id, resubmission_number);


-- ============================================================================
-- REVISION_REQUIREMENTS_TRACKING TABLE
-- ============================================================================
-- Track individual requirements from revision request and their completion

CREATE TABLE revision_requirements_tracking (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    submission_type VARCHAR(50) NOT NULL,
    submission_id INTEGER NOT NULL,
    review_history_id INTEGER NOT NULL,  -- The revision request record

    -- Requirement details
    requirement_number INTEGER NOT NULL,
    requirement_description TEXT NOT NULL,
    requirement_category VARCHAR(50),  -- data_quality / safety / completeness / accuracy / clarity

    -- Completion status
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP,
    completion_notes TEXT,
    verified_by_user_id INTEGER,

    -- Priority
    is_mandatory BOOLEAN DEFAULT TRUE,  -- Must be completed or submission will be rejected
    priority INTEGER DEFAULT 3,  -- 1-5

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (review_history_id) REFERENCES submission_review_history(id),
    FOREIGN KEY (verified_by_user_id) REFERENCES users(id)
);

CREATE INDEX idx_revision_requirements_submission ON revision_requirements_tracking(submission_type, submission_id);
CREATE INDEX idx_revision_requirements_completed ON revision_requirements_tracking(is_completed, is_mandatory);


-- ============================================================================
-- SUBMISSION_VERSION_HISTORY TABLE
-- ============================================================================
-- Store snapshots of submission data at each version (for comparison)

CREATE TABLE submission_version_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    submission_type VARCHAR(50) NOT NULL,
    submission_id INTEGER NOT NULL,

    -- Version tracking
    version_number INTEGER NOT NULL,
    previous_version_id INTEGER,  -- Link to previous version

    -- Snapshot of submission data (JSON)
    submission_data_json TEXT NOT NULL,  -- Full snapshot of all fields

    -- Version metadata
    version_type VARCHAR(50),  -- initial_submission / revision_1 / revision_2 / approved_version / rejected_version
    version_notes TEXT,

    -- Who made changes
    changed_by_user_id INTEGER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (previous_version_id) REFERENCES submission_version_history(id),
    FOREIGN KEY (changed_by_user_id) REFERENCES users(id),

    UNIQUE(submission_type, submission_id, version_number)
);

CREATE INDEX idx_version_history_submission ON submission_version_history(submission_type, submission_id, version_number DESC);


-- ============================================================================
-- USAGE FLOW: Handling Revision Request
-- ============================================================================

-- SCENARIO: Pharmacist requests revision for medication submission

-- STEP 1: Reviewer requests revision (already handled in Migration 050)
-- - Record in submission_review_history with action_type='requested_revision'
-- - Add comments explaining what needs to be fixed

-- STEP 2: Parse revision requirements into trackable items
-- INSERT OR IGNORE INTO revision_requirements_tracking (submission_type, submission_id, review_history_id, requirement_number, requirement_description, requirement_category, is_mandatory, priority) VALUES
-- ('medication', 456, review_history_id, 1, 'Add black box warnings if any exist', 'safety', TRUE, 5),
-- ('medication', 456, review_history_id, 2, 'Specify pregnancy category (A/B/C/D/X)', 'safety', TRUE, 5),
-- ('medication', 456, review_history_id, 3, 'List known drug interactions with common medications', 'safety', TRUE, 4),
-- ('medication', 456, review_history_id, 4, 'Add typical cost range in UGX', 'completeness', FALSE, 2);

-- STEP 3: Update medication_submissions status
-- UPDATE medication_submissions
-- SET status = 'needs_revision',
--     revision_requested_notes = 'Please address 4 requirements (3 mandatory, 1 optional)'
-- WHERE id = 456;

-- STEP 4: Notify submitter
-- - Email with detailed list of requirements
-- - In-app notification
-- - Link to revision interface

-- STEP 5: User makes changes
-- - User edits medication submission
-- - User adds black box warning: "May cause lactic acidosis (rare)"
-- - User adds pregnancy category: "B"
-- - User adds drug interactions: ["Alcohol (avoid)", "Contrast dye (stop 48h before)"]
-- - User leaves cost field empty (optional)

-- STEP 6: User resubmits
-- INSERT OR IGNORE INTO submission_resubmissions (
--     submission_type, original_submission_id, review_queue_id,
--     resubmission_number, resubmitted_by_user_id,
--     resubmission_notes, changes_summary,
--     changes_detail_json,
--     addressed_comments, unaddressed_comments, all_requirements_met,
--     previous_status, new_status
-- ) VALUES (
--     'medication', 456, 789,
--     1, submitter_id,
--     'I have added the black box warning, pregnancy category, and drug interactions as requested.',
--     'Added: black box warning (lactic acidosis), pregnancy category B, drug interactions with alcohol and contrast dye',
--     '{"black_box_warnings": {"old": null, "new": "May cause lactic acidosis (rare)"}, "pregnancy_category": {"old": null, "new": "B"}, "drug_interactions_known": {"old": "[]", "new": "[\"Alcohol\", \"Contrast dye\"]"}}',
--     '[1, 2, 3]',  -- Addressed requirement IDs 1, 2, 3
--     '[4]',  -- Did not address requirement 4 (optional)
--     FALSE,  -- Not all requirements met (but that's OK, requirement 4 was optional)
--     'needs_revision', 'pending'
-- );

-- STEP 7: Mark requirements as completed
-- UPDATE revision_requirements_tracking
-- SET is_completed = TRUE, completed_at = NOW()
-- WHERE id IN (1, 2, 3);  -- Requirements 1, 2, 3 completed

-- STEP 8: Create version snapshot
-- INSERT OR IGNORE INTO submission_version_history (submission_type, submission_id, version_number, previous_version_id, submission_data_json, version_type, changed_by_user_id)
-- SELECT
--     'medication', 456, 2, previous_version.id,
--     JSON_OBJECT('generic_name', generic_name, 'black_box_warnings', black_box_warnings, ...),
--     'revision_1', submitter_id
-- FROM medication_submissions ms
-- LEFT JOIN submission_version_history previous_version ON previous_version.submission_type = 'medication' AND previous_version.submission_id = 456 AND previous_version.version_number = 1
-- WHERE ms.id = 456;

-- STEP 9: Re-enter review queue
-- UPDATE submission_review_queue
-- SET status = 'pending',
--     assigned_to_reviewer_id = original_reviewer_id,  -- Assign back to same reviewer
--     entered_queue_at = NOW()
-- WHERE id = 789;

-- STEP 10: Notify reviewer
-- - Notification: "Resubmission ready for review: Medication submission 456 (Revision #1)"

-- STEP 11: Reviewer reviews resubmission
-- - Checks revision_requirements_tracking: 3/3 mandatory requirements completed ✓
-- - Reviews changes_detail_json to see what changed
-- - Verifies black box warning is accurate
-- - Approves: INSERT OR IGNORE INTO submission_review_history (...) with action_type='approved', decision='approve'


-- ============================================================================
-- ANALYTICS: Revision Patterns
-- ============================================================================

-- Average revisions needed by submission type:
-- SELECT
--     submission_type,
--     AVG(resubmission_number) AS avg_revisions,
--     MAX(resubmission_number) AS max_revisions,
--     COUNT(DISTINCT original_submission_id) AS total_submissions_needing_revision
-- FROM submission_resubmissions
-- GROUP BY submission_type;

-- Most common revision requirements:
-- SELECT
--     requirement_category,
--     requirement_description,
--     COUNT(*) AS times_requested,
--     SUM(CASE WHEN is_completed THEN 1 ELSE 0 END) AS times_completed,
--     ROUND(SUM(CASE WHEN is_completed THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS completion_rate_pct
-- FROM revision_requirements_tracking
-- GROUP BY requirement_category, requirement_description
-- ORDER BY times_requested DESC
-- LIMIT 20;

-- Submissions by revision count:
-- SELECT
--     resubmission_number AS revision_count,
--     COUNT(*) AS submission_count
-- FROM (
--     SELECT original_submission_id, MAX(resubmission_number) AS resubmission_number
--     FROM submission_resubmissions
--     GROUP BY original_submission_id
-- ) AS max_revisions
-- GROUP BY resubmission_number
-- ORDER BY resubmission_number;

-- Compare versions (what changed?):
-- SELECT
--     v1.version_number AS from_version,
--     v2.version_number AS to_version,
--     v1.submission_data_json AS old_data,
--     v2.submission_data_json AS new_data,
--     v2.version_notes AS change_notes
-- FROM submission_version_history v1
-- JOIN submission_version_history v2 ON v2.previous_version_id = v1.id
-- WHERE v1.submission_type = 'medication' AND v1.submission_id = 456;
