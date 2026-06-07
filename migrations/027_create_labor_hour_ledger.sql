-- Migration 027: Create Labor Hour Ledger
-- Date: 2026-04-11
-- Purpose: Track all work done by users, verify completion, and record payment

-- Labor Hour Ledger (Master record of all work performed)
CREATE TABLE IF NOT EXISTS labor_hour_ledger (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL, -- Who worked
  labor_service_id INTEGER NOT NULL, -- Which service they provided
  labor_booking_id INTEGER, -- Reference to booking (if booked via platform)

  -- Work Details
  service_type VARCHAR(60) NOT NULL,
  hours_worked REAL NOT NULL,
  hourly_rate_ap INTEGER NOT NULL, -- Rate at time of work
  total_earned_ap INTEGER NOT NULL, -- hours_worked × hourly_rate_ap
  total_earned_ugx REAL, -- Converted to UGX for accounting

  -- Work Date & Time
  work_date DATE NOT NULL,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  actual_duration_hours REAL, -- Calculated from start/end time

  -- Client/Requester
  client_user_id INTEGER, -- Who requested the work (peer-to-peer)
  client_facility_id INTEGER, -- Or facility that requested work
  work_location_address TEXT,
  work_location_gps_lat REAL,
  work_location_gps_lng REAL,
  work_description TEXT,

  -- Verification (CRITICAL for trust)
  is_verified BOOLEAN DEFAULT FALSE,
  verified_by INTEGER, -- Staff ID or client_user_id
  verification_method VARCHAR(40), -- facility_staff / client_confirmation / gps_checkin / photo_proof / peer_verification
  verification_notes TEXT,
  verification_photos TEXT, -- JSON array: before/after work photos
  verified_at TIMESTAMP,

  -- GPS Check-in/Check-out (Automated verification)
  checkin_gps_lat REAL,
  checkin_gps_lng REAL,
  checkin_timestamp TIMESTAMP,
  checkout_gps_lat REAL,
  checkout_gps_lng REAL,
  checkout_timestamp TIMESTAMP,
  gps_verification_passed BOOLEAN,

  -- Payment Status
  payment_status VARCHAR(40) DEFAULT 'pending', -- pending / processing / paid / disputed
  payment_method VARCHAR(40), -- afya_points / fiat_currency / barter_credit / hybrid
  payment_breakdown TEXT, -- JSON: {"afya_points": 500, "fiat_ugx": 50000}
  paid_at TIMESTAMP,

  -- Platform Fee
  transaction_fee_pct REAL DEFAULT 5.0,
  transaction_fee_ap INTEGER,
  net_earned_ap INTEGER, -- total_earned_ap - transaction_fee_ap
  platform_revenue_ugx REAL,

  -- Dispute
  dispute_raised BOOLEAN DEFAULT FALSE,
  dispute_reason TEXT,
  dispute_raised_by INTEGER,
  dispute_resolved_at TIMESTAMP,

  -- Social Good Tracking (0% fee for vulnerable populations)
  is_social_good BOOLEAN DEFAULT FALSE, -- TRUE if client is vulnerable (elderly, disabled, child)
  social_good_reason TEXT,
  fee_waived BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (labor_service_id) REFERENCES labor_services_registry(id) ON DELETE CASCADE,
  FOREIGN KEY (labor_booking_id) REFERENCES labor_booking_requests(id) ON DELETE SET NULL,
  FOREIGN KEY (client_user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (client_facility_id) REFERENCES facility_partners(id) ON DELETE SET NULL,
  FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (dispute_raised_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Labor Verification Queue (Pending verifications)
CREATE TABLE IF NOT EXISTS labor_verification_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  labor_hour_ledger_id INTEGER NOT NULL,
  verification_type VARCHAR(40), -- facility_staff / peer_verification / gps_auto
  assigned_to INTEGER, -- Staff ID who should verify
  priority VARCHAR(40) DEFAULT 'normal', -- low / normal / high / urgent
  status VARCHAR(40) DEFAULT 'pending', -- pending / in_review / approved / rejected
  rejection_reason TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  FOREIGN KEY (labor_hour_ledger_id) REFERENCES labor_hour_ledger(id) ON DELETE CASCADE,
  FOREIGN KEY (assigned_to) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- Labor Earnings Summary (User's total earnings by skill)
CREATE TABLE IF NOT EXISTS labor_earnings_summary (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  service_type VARCHAR(60),
  month DATE NOT NULL, -- YYYY-MM-01
  total_hours_worked REAL DEFAULT 0,
  total_earned_ap INTEGER DEFAULT 0,
  total_earned_ugx REAL DEFAULT 0,
  jobs_completed INTEGER DEFAULT 0,
  avg_hourly_rate_ap INTEGER,
  verified_hours REAL DEFAULT 0, -- Hours with verification
  unverified_hours REAL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (user_id, service_type, month)
);

-- Labor No-Show Log (Track reliability)
CREATE TABLE IF NOT EXISTS labor_no_show_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  labor_booking_id INTEGER NOT NULL,
  provider_user_id INTEGER NOT NULL,
  requester_user_id INTEGER NOT NULL,
  scheduled_date DATE NOT NULL,
  no_show_type VARCHAR(40), -- provider_no_show / requester_cancelled_last_minute / both_no_show
  reported_by INTEGER NOT NULL,
  report_notes TEXT,
  penalty_applied BOOLEAN DEFAULT FALSE,
  penalty_amount_ap INTEGER, -- Afya Points penalty
  is_legitimate_excuse BOOLEAN, -- TRUE if valid reason (emergency, illness)
  excuse_notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (labor_booking_id) REFERENCES labor_booking_requests(id) ON DELETE CASCADE,
  FOREIGN KEY (provider_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (requester_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (reported_by) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_labor_ledger_user ON labor_hour_ledger(user_id);
CREATE INDEX IF NOT EXISTS idx_labor_ledger_service ON labor_hour_ledger(labor_service_id);
CREATE INDEX IF NOT EXISTS idx_labor_ledger_booking ON labor_hour_ledger(labor_booking_id);
CREATE INDEX IF NOT EXISTS idx_labor_ledger_date ON labor_hour_ledger(work_date);
CREATE INDEX IF NOT EXISTS idx_labor_ledger_verified ON labor_hour_ledger(is_verified);
CREATE INDEX IF NOT EXISTS idx_labor_ledger_payment ON labor_hour_ledger(payment_status);
CREATE INDEX IF NOT EXISTS idx_labor_ledger_client ON labor_hour_ledger(client_user_id);
CREATE INDEX IF NOT EXISTS idx_labor_ledger_facility ON labor_hour_ledger(client_facility_id);

CREATE INDEX IF NOT EXISTS idx_verification_queue_ledger ON labor_verification_queue(labor_hour_ledger_id);
CREATE INDEX IF NOT EXISTS idx_verification_queue_assigned ON labor_verification_queue(assigned_to);
CREATE INDEX IF NOT EXISTS idx_verification_queue_status ON labor_verification_queue(status);

CREATE INDEX IF NOT EXISTS idx_earnings_summary_user ON labor_earnings_summary(user_id);
CREATE INDEX IF NOT EXISTS idx_earnings_summary_month ON labor_earnings_summary(month);

CREATE INDEX IF NOT EXISTS idx_no_show_provider ON labor_no_show_log(provider_user_id);
CREATE INDEX IF NOT EXISTS idx_no_show_requester ON labor_no_show_log(requester_user_id);
CREATE INDEX IF NOT EXISTS idx_no_show_date ON labor_no_show_log(scheduled_date);

-- View: User Labor Earnings (for easy lookup)
CREATE VIEW IF NOT EXISTS v_user_labor_earnings AS
SELECT
  u.id AS user_id,
  u.username,
  COUNT(DISTINCT lhl.id) AS total_jobs,
  SUM(lhl.hours_worked) AS total_hours_worked,
  SUM(lhl.total_earned_ap) AS total_earned_ap,
  SUM(lhl.total_earned_ugx) AS total_earned_ugx,
  SUM(lhl.transaction_fee_ap) AS total_fees_paid_ap,
  SUM(lhl.net_earned_ap) AS total_net_earned_ap,
  AVG(lhl.hourly_rate_ap) AS avg_hourly_rate_ap,
  SUM(CASE WHEN lhl.is_verified = TRUE THEN lhl.hours_worked ELSE 0 END) AS verified_hours,
  SUM(CASE WHEN lhl.is_verified = FALSE THEN lhl.hours_worked ELSE 0 END) AS unverified_hours,
  COUNT(DISTINCT DATE(lhl.work_date, 'start of month')) AS months_active
FROM users u
LEFT JOIN labor_hour_ledger lhl ON u.id = lhl.user_id
GROUP BY u.id, u.username;

-- Trigger: Auto-add to verification queue when labor hour logged
CREATE TRIGGER IF NOT EXISTS trg_add_to_verification_queue
AFTER INSERT ON labor_hour_ledger
FOR EACH ROW
WHEN NEW.is_verified = FALSE AND NEW.verification_method IS NOT NULL
BEGIN
  INSERT OR IGNORE INTO labor_verification_queue (labor_hour_ledger_id, verification_type, priority)
  VALUES (
    NEW.id,
    NEW.verification_method,
    CASE
      WHEN NEW.hours_worked >= 8 THEN 'high' -- Full day work needs priority verification
      WHEN NEW.total_earned_ap >= 1000 THEN 'high' -- High-value work
      ELSE 'normal'
    END
  );
END;

-- Trigger: Calculate net earnings when verified
CREATE TRIGGER IF NOT EXISTS trg_calc_net_labor_earnings
AFTER UPDATE OF is_verified ON labor_hour_ledger
FOR EACH ROW
WHEN NEW.is_verified = TRUE AND OLD.is_verified = FALSE
BEGIN
  UPDATE labor_hour_ledger
  SET
    transaction_fee_ap = CAST(NEW.total_earned_ap * NEW.transaction_fee_pct / 100 AS INTEGER),
    net_earned_ap = NEW.total_earned_ap - CAST(NEW.total_earned_ap * NEW.transaction_fee_pct / 100 AS INTEGER),
    platform_revenue_ugx = (NEW.total_earned_ap * NEW.transaction_fee_pct / 100) * 100,
    payment_status = 'processing'
  WHERE id = NEW.id AND NEW.fee_waived = FALSE;

  -- If social good (fee waived), mark as paid immediately
  UPDATE labor_hour_ledger
  SET
    transaction_fee_ap = 0,
    net_earned_ap = NEW.total_earned_ap,
    platform_revenue_ugx = 0,
    payment_status = 'paid',
    paid_at = CURRENT_TIMESTAMP
  WHERE id = NEW.id AND NEW.fee_waived = TRUE;

  -- Update verification queue status
  UPDATE labor_verification_queue
  SET status = 'approved', completed_at = CURRENT_TIMESTAMP
  WHERE labor_hour_ledger_id = NEW.id AND status = 'pending';
END;

-- Trigger: Update monthly earnings summary
CREATE TRIGGER IF NOT EXISTS trg_update_earnings_summary
AFTER UPDATE OF is_verified ON labor_hour_ledger
FOR EACH ROW
WHEN NEW.is_verified = TRUE AND OLD.is_verified = FALSE
BEGIN
  INSERT OR IGNORE INTO labor_earnings_summary (user_id, service_type, month, total_hours_worked, total_earned_ap, total_earned_ugx, jobs_completed, verified_hours)
  VALUES (
    NEW.user_id,
    NEW.service_type,
    DATE(NEW.work_date, 'start of month'),
    NEW.hours_worked,
    NEW.total_earned_ap,
    NEW.total_earned_ugx,
    1,
    NEW.hours_worked
  )
  ON CONFLICT(user_id, service_type, month) DO UPDATE SET
    total_hours_worked = total_hours_worked + NEW.hours_worked,
    total_earned_ap = total_earned_ap + NEW.total_earned_ap,
    total_earned_ugx = total_earned_ugx + NEW.total_earned_ugx,
    jobs_completed = jobs_completed + 1,
    verified_hours = verified_hours + NEW.hours_worked;
END;

-- Trigger: Update timestamp
CREATE TRIGGER IF NOT EXISTS trg_update_labor_ledger_timestamp
AFTER UPDATE ON labor_hour_ledger
FOR EACH ROW
BEGIN
  UPDATE labor_hour_ledger SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Trigger: Credit Afya Points to user's account when payment processed
CREATE TRIGGER IF NOT EXISTS trg_credit_afya_points_labor
AFTER UPDATE OF payment_status ON labor_hour_ledger
FOR EACH ROW
WHEN NEW.payment_status = 'paid' AND OLD.payment_status = 'processing'
BEGIN
  -- Credit Afya Points to user (this would normally call backend API, but we log it in ledger)
  INSERT OR IGNORE INTO afya_points_ledger (user_id, points_change, transaction_type, action_type, reference_id, reference_table, balance_after, notes)
  VALUES (
    NEW.user_id,
    NEW.net_earned_ap,
    'earned',
    'labor_completed',
    NEW.id,
    'labor_hour_ledger',
    (SELECT COALESCE(MAX(balance_after), 0) + NEW.net_earned_ap FROM afya_points_ledger WHERE user_id = NEW.user_id),
    'Earned from ' || NEW.hours_worked || ' hours of ' || NEW.service_type
  );

  -- Record platform revenue
  INSERT OR IGNORE INTO platform_revenue_ledger (revenue_source, amount_ugx, amount_ap, user_id, reference_id, reference_table)
  VALUES (
    'labor_transaction_fees',
    NEW.platform_revenue_ugx,
    NEW.transaction_fee_ap,
    NEW.user_id,
    NEW.id,
    'labor_hour_ledger'
  );
END;
