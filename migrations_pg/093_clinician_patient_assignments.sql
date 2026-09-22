-- Explicit clinician-to-patient authorization for review of model-run artifacts.
CREATE TABLE IF NOT EXISTS clinician_patient_assignments (
    id SERIAL PRIMARY KEY,
    clinician_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    patient_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    UNIQUE (clinician_user_id, patient_user_id)
);

CREATE INDEX IF NOT EXISTS idx_clinician_patient_assignments_patient
    ON clinician_patient_assignments(patient_user_id, is_active);
