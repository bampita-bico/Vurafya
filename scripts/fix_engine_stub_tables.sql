-- Expand bootstrap stub tables for engine/biometrics queries.
ALTER TABLE vital_signs_history ADD COLUMN IF NOT EXISTS user_id INTEGER;
ALTER TABLE vital_signs_history ADD COLUMN IF NOT EXISTS recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE vital_signs_history ADD COLUMN IF NOT EXISTS blood_pressure_systolic DOUBLE PRECISION;
ALTER TABLE vital_signs_history ADD COLUMN IF NOT EXISTS blood_pressure_diastolic DOUBLE PRECISION;
ALTER TABLE vital_signs_history ADD COLUMN IF NOT EXISTS pulse_rate DOUBLE PRECISION;
ALTER TABLE vital_signs_history ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE glucose_monitoring ADD COLUMN IF NOT EXISTS user_id INTEGER;
ALTER TABLE glucose_monitoring ADD COLUMN IF NOT EXISTS recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE glucose_monitoring ADD COLUMN IF NOT EXISTS glucose_mg_dl DOUBLE PRECISION;

ALTER TABLE creatinine_egfr_logs ADD COLUMN IF NOT EXISTS user_id INTEGER;
ALTER TABLE creatinine_egfr_logs ADD COLUMN IF NOT EXISTS measured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE creatinine_egfr_logs ADD COLUMN IF NOT EXISTS egfr_ml_min DOUBLE PRECISION;
ALTER TABLE creatinine_egfr_logs ADD COLUMN IF NOT EXISTS creatinine_mg_dl DOUBLE PRECISION;
