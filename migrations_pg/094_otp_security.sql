-- Repair the bootstrap placeholder before hardening OTP storage.  Migration 037
-- uses CREATE TABLE IF NOT EXISTS, so it cannot add these columns to a table
-- that bootstrap created with only an id.
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS user_id INTEGER;
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20);
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS otp_code VARCHAR(10);
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS otp_hash VARCHAR(100);
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS verification_purpose VARCHAR(60);
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS transaction_id INTEGER;
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS transaction_type VARCHAR(40);
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS transaction_amount_ugx DOUBLE PRECISION;
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS status VARCHAR(40) DEFAULT 'pending';
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS sent_at TIMESTAMP;
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP;
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP;
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS sms_provider VARCHAR(60);
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS verification_attempts INTEGER DEFAULT 0;
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS max_attempts INTEGER DEFAULT 3;
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS is_locked BOOLEAN DEFAULT FALSE;
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE sms_verification_codes ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Plaintext OTP values must never be retained.
ALTER TABLE sms_verification_codes
    ALTER COLUMN otp_code DROP NOT NULL;

UPDATE sms_verification_codes
SET otp_code = NULL
WHERE otp_code IS NOT NULL;
