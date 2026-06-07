-- Runtime artifact spine for CDFD-backed clinical model outputs.

CREATE TABLE IF NOT EXISTS runtime_runs (
    id SERIAL PRIMARY KEY,
    run_uid VARCHAR(80) NOT NULL UNIQUE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    run_kind VARCHAR(80),
    command TEXT,
    domain VARCHAR(80) DEFAULT 'medicine',
    source VARCHAR(80) DEFAULT 'api',
    status VARCHAR(30) DEFAULT 'ok',
    clinical_regime VARCHAR(40),
    clinical_stability_score DOUBLE PRECISION,
    finite_audit JSONB DEFAULT '{}'::jsonb,
    result_payload JSONB DEFAULT '{}'::jsonb,
    explanation_payload JSONB DEFAULT '{}'::jsonb,
    manifest JSONB DEFAULT '{}'::jsonb,
    artifact_root TEXT,
    result_path TEXT,
    report_markdown_path TEXT,
    report_html_path TEXT,
    claim_boundary TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_runtime_runs_user_created
    ON runtime_runs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_runtime_runs_status
    ON runtime_runs(status);
CREATE INDEX IF NOT EXISTS idx_runtime_runs_domain
    ON runtime_runs(domain);
CREATE INDEX IF NOT EXISTS idx_runtime_runs_regime
    ON runtime_runs(clinical_regime);

CREATE TABLE IF NOT EXISTS runtime_reviews (
    id SERIAL PRIMARY KEY,
    run_id INTEGER NOT NULL REFERENCES runtime_runs(id) ON DELETE CASCADE,
    reviewer_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    review_status VARCHAR(40) NOT NULL,
    review_note TEXT,
    reviewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_runtime_reviews_run
    ON runtime_reviews(run_id, reviewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_runtime_reviews_reviewer
    ON runtime_reviews(reviewer_user_id, reviewed_at DESC);

CREATE TABLE IF NOT EXISTS runtime_alerts (
    id SERIAL PRIMARY KEY,
    run_id INTEGER REFERENCES runtime_runs(id) ON DELETE SET NULL,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    alert_type VARCHAR(60) NOT NULL,
    severity VARCHAR(30) DEFAULT 'info',
    runtime_state VARCHAR(60),
    message TEXT,
    actions JSONB DEFAULT '[]'::jsonb,
    acknowledged_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    acknowledged_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_runtime_alerts_user_created
    ON runtime_alerts(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_runtime_alerts_unack
    ON runtime_alerts(user_id, acknowledged_at)
    WHERE acknowledged_at IS NULL;
