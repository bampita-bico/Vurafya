-- Migration 037: Create SMS Verification System
-- Date: 2026-04-11
-- Purpose: SMS OTP for offline users (many Africans have feature phones, not smartphones)

-- SMS Verification Codes (OTP for offline transactions)
CREATE TABLE IF NOT EXISTS sms_verification_codes (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  phone_number VARCHAR(20) NOT NULL,

  -- OTP Code
  otp_code VARCHAR(10) NOT NULL, -- 6-digit code
  otp_hash VARCHAR(100), -- Hashed OTP for security

  -- Purpose
  verification_purpose VARCHAR(60) NOT NULL, -- phone_verification / transaction_confirmation / kyc_verification / login_2fa / password_reset

  -- Transaction Reference (if confirming a transaction)
  transaction_id INTEGER,
  transaction_type VARCHAR(40),
  transaction_amount_ugx DOUBLE PRECISION,

  -- Status
  status VARCHAR(40) DEFAULT 'pending', -- pending / sent / verified / expired / failed
  sent_at TIMESTAMP,
  verified_at TIMESTAMP,
  expires_at TIMESTAMP, -- Typically 10-15 minutes after sending

  -- Delivery
  sms_provider VARCHAR(60), -- africas_talking / twilio / nexmo
  sms_message_id VARCHAR(200), -- Provider's message ID
  sms_delivery_status VARCHAR(40), -- sent / delivered / failed / rejected
  sms_cost_ugx DOUBLE PRECISION, -- Cost to send SMS

  -- Attempts
  verification_attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 3,
  is_locked BOOLEAN DEFAULT FALSE, -- Locked after max attempts

  -- Fraud Prevention
  ip_address VARCHAR(60),
  user_agent TEXT,
  geolocation_lat DOUBLE PRECISION,
  geolocation_lng DOUBLE PRECISION,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- SMS Template Library (Pre-defined SMS messages)
CREATE TABLE IF NOT EXISTS sms_templates (
  id SERIAL PRIMARY KEY,
  template_code VARCHAR(60) NOT NULL UNIQUE,
  template_name VARCHAR(200) NOT NULL,

  -- Message Template (Variables: {{otp_code}}, {{amount}}, {{transaction_id}})
  message_template TEXT NOT NULL,
  message_length INTEGER, -- Character count

  -- Language
  language_code VARCHAR(5) DEFAULT 'en', -- en / sw (Swahili) / ha (Hausa) / zu (Zulu) / am (Amharic)

  -- Use Case
  purpose VARCHAR(60), -- phone_verification / transaction_confirmation / kyc_verification

  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed SMS templates (English + Swahili)
INSERT INTO sms_templates (template_code, template_name, message_template, language_code, purpose) VALUES
('otp_phone_verify_en', 'Phone Verification OTP (English)', 'Your Vurafya verification code is {{otp_code}}. Valid for 10 minutes. Do not share this code.', 'en', 'phone_verification'),
('otp_phone_verify_sw', 'Phone Verification OTP (Swahili)', 'Nambari yako ya kuthibitisha Vurafya ni {{otp_code}}. Inatekelezwa kwa dakika 10. Usishiriki nambari hii.', 'sw', 'phone_verification'),
('otp_transaction_en', 'Transaction Confirmation OTP (English)', 'Confirm Vurafya payment of {{amount}} UGX. Code: {{otp_code}}. Reply with code to authorize.', 'en', 'transaction_confirmation'),
('otp_transaction_sw', 'Transaction Confirmation OTP (Swahili)', 'Thibitisha malipo ya Vurafya ya {{amount}} UGX. Nambari: {{otp_code}}. Jibu na nambari kuruhusu.', 'sw', 'transaction_confirmation'),
('otp_kyc_en', 'KYC Verification OTP (English)', 'Your Vurafya KYC verification code is {{otp_code}}. Enter this code to complete identity verification.', 'en', 'kyc_verification'),
('otp_login_2fa_en', 'Login 2FA OTP (English)', 'Your Vurafya login code is {{otp_code}}. If you did not request this, contact support immediately.', 'en', 'login_2fa');

-- SMS Provider Configuration
CREATE TABLE IF NOT EXISTS sms_provider_config (
  id SERIAL PRIMARY KEY,
  provider_name VARCHAR(60) NOT NULL UNIQUE, -- africas_talking / twilio / nexmo

  -- API Credentials (ENCRYPTED in production!)
  api_key VARCHAR(500),
  api_secret VARCHAR(500),
  sender_id VARCHAR(20), -- Short code or sender name

  -- Routing (Which countries use this provider)
  supported_countries TEXT, -- JSON array: ["UG", "KE", "TZ", "RW"]
  priority INTEGER DEFAULT 1, -- 1 = primary, 2 = backup

  -- Cost
  cost_per_sms_ugx DOUBLE PRECISION,
  monthly_quota INTEGER, -- Max SMS per month
  monthly_usage INTEGER DEFAULT 0,

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  is_default BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed SMS providers (placeholder - real credentials added in production)
INSERT INTO sms_provider_config (provider_name, supported_countries, cost_per_sms_ugx, is_default) VALUES
('africas_talking', '["UG", "KE", "TZ", "RW", "NG", "ZA"]', 150, TRUE),
('twilio', '["UG", "KE", "TZ", "NG", "ZA", "ET", "GH"]', 200, FALSE);

-- SMS Delivery Log (Track all SMS sent)
CREATE TABLE IF NOT EXISTS sms_delivery_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER,
  phone_number VARCHAR(20) NOT NULL,

  -- Message
  message_text TEXT NOT NULL,
  message_length INTEGER,
  template_code VARCHAR(60),

  -- Provider
  provider_name VARCHAR(60),
  provider_message_id VARCHAR(200),

  -- Status
  delivery_status VARCHAR(40), -- queued / sent / delivered / failed / rejected
  delivery_error TEXT,

  -- Cost
  cost_ugx DOUBLE PRECISION,

  -- Timestamps
  sent_at TIMESTAMP,
  delivered_at TIMESTAMP,
  failed_at TIMESTAMP,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_sms_otp_user ON sms_verification_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_sms_otp_phone ON sms_verification_codes(phone_number);
CREATE INDEX IF NOT EXISTS idx_sms_otp_status ON sms_verification_codes(status);
CREATE INDEX IF NOT EXISTS idx_sms_otp_expires ON sms_verification_codes(expires_at);

CREATE INDEX IF NOT EXISTS idx_sms_template_code ON sms_templates(template_code);
CREATE INDEX IF NOT EXISTS idx_sms_template_purpose ON sms_templates(purpose);

CREATE INDEX IF NOT EXISTS idx_sms_delivery_user ON sms_delivery_log(user_id);
CREATE INDEX IF NOT EXISTS idx_sms_delivery_phone ON sms_delivery_log(phone_number);
CREATE INDEX IF NOT EXISTS idx_sms_delivery_status ON sms_delivery_log(delivery_status);

-- View: Pending OTP Verifications
CREATE VIEW IF NOT EXISTS v_pending_otp_verifications AS
SELECT
  svc.id,
  svc.user_id,
  u.username,
  svc.phone_number,
  svc.verification_purpose,
  svc.transaction_amount_ugx,
  svc.expires_at,
  svc.verification_attempts,
  svc.created_at
FROM sms_verification_codes svc
JOIN users u ON svc.user_id = u.id
WHERE svc.status = 'pending'
  AND svc.expires_at > CURRENT_TIMESTAMP
  AND svc.is_locked = FALSE;

-- Trigger: Auto-expire OTP codes after 10 minutes
-- (Handled by backend cron job, but we document the logic)

-- Trigger: Lock OTP after max attempts
CREATE TRIGGER IF NOT EXISTS trg_lock_otp_after_max_attempts
AFTER UPDATE OF verification_attempts ON sms_verification_codes
FOR EACH ROW
WHEN NEW.verification_attempts >= NEW.max_attempts
BEGIN
  UPDATE sms_verification_codes
  SET is_locked = TRUE, status = 'failed'
  WHERE id = NEW.id;
END;

-- Function: SMS OTP Workflow (documented for backend)
/*
SMS OTP WORKFLOW:

1. USER INITIATES ACTION (e.g., transaction confirmation)
   - Backend generates 6-digit OTP: RAND(100000, 999999)
   - Hash OTP using bcrypt or similar
   - Store in sms_verification_codes table
   - Set expires_at = NOW() + 10 minutes

2. SEND SMS
   - Select template based on purpose + user's language
   - Replace {{otp_code}}, {{amount}} variables
   - Choose SMS provider based on user's country
   - Call provider API (Africa's Talking, Twilio, Nexmo)
   - Log delivery in sms_delivery_log
   - Update sms_verification_codes.sent_at

3. USER RECEIVES SMS
   - User types OTP code into app or USSD interface
   - OR user replies to SMS with OTP code (for feature phones)

4. VERIFY OTP
   - Check if OTP code matches (compare hash)
   - Check if not expired (expires_at > NOW())
   - Check if not locked (is_locked = FALSE)
   - Increment verification_attempts
   - If correct: Update status = 'verified', verified_at = NOW()
   - If wrong: Check if verification_attempts >= max_attempts → lock
   - If locked: User must request new OTP

5. PROCESS TRANSACTION
   - If OTP verified: Proceed with transaction
   - If OTP failed: Block transaction, alert user

OFFLINE USE CASE (Feature Phones):
- User dials USSD code: *123*456#
- System IVR: "Enter pharmacy order ID"
- User enters order ID
- System generates OTP, sends SMS
- User receives SMS with OTP
- System IVR: "Enter OTP code"
- User enters OTP
- System verifies OTP
- Transaction confirmed via SMS

FRAUD PREVENTION:
- Max 3 attempts per OTP
- Max 5 OTP requests per phone number per hour
- Track IP address + geolocation for suspicious patterns
- Flag if OTP requested from different country than user's registered country
*/
