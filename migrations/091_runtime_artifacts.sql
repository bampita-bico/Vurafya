-- Runtime artifact spine for CDFD-backed clinical model outputs.

CREATE TABLE IF NOT EXISTS runtime_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_uid VARCHAR(80) NOT NULL UNIQUE,
    user_id INTEGER NOT NULL,
    run_kind VARCHAR(80),
    command TEXT,
    domain VARCHAR(80) DEFAULT 'medicine',
    source VARCHAR(80) DEFAULT 'api',
    status VARCHAR(30) DEFAULT 'ok',
    clinical_regime VARCHAR(40),
    clinical_stability_score REAL,
    finite_audit TEXT DEFAULT '{}',
    result_payload TEXT DEFAULT '{}',
    explanation_payload TEXT DEFAULT '{}',
    manifest TEXT DEFAULT '{}',
    artifact_root TEXT,
    result_path TEXT,
    report_markdown_path TEXT,
    report_html_path TEXT,
    claim_boundary TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
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
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id INTEGER NOT NULL,
    reviewer_user_id INTEGER NOT NULL,
    review_status VARCHAR(40) NOT NULL,
    review_note TEXT,
    reviewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (run_id) REFERENCES runtime_runs(id) ON DELETE CASCADE,
    FOREIGN KEY (reviewer_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_runtime_reviews_run
    ON runtime_reviews(run_id, reviewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_runtime_reviews_reviewer
    ON runtime_reviews(reviewer_user_id, reviewed_at DESC);

CREATE TABLE IF NOT EXISTS runtime_alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id INTEGER,
    user_id INTEGER NOT NULL,
    alert_type VARCHAR(60) NOT NULL,
    severity VARCHAR(30) DEFAULT 'info',
    runtime_state VARCHAR(60),
    message TEXT,
    actions TEXT DEFAULT '[]',
    acknowledged_by INTEGER,
    acknowledged_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (run_id) REFERENCES runtime_runs(id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (acknowledged_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_runtime_alerts_user_created
    ON runtime_alerts(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_runtime_alerts_unack
    ON runtime_alerts(user_id, acknowledged_at);
