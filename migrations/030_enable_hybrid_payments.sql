-- Migration 030: Enable Hybrid Payments on Existing Tables
-- Date: 2026-04-11
-- Purpose: Extend pharmacy_orders and other transaction tables to support hybrid payments

-- Extend pharmacy_orders table for hybrid payment support
ALTER TABLE pharmacy_orders ADD COLUMN payment_method VARCHAR(40) DEFAULT 'fiat_only';
ALTER TABLE pharmacy_orders ADD COLUMN is_hybrid_payment BOOLEAN DEFAULT FALSE;
ALTER TABLE pharmacy_orders ADD COLUMN payment_breakdown TEXT; -- JSON
ALTER TABLE pharmacy_orders ADD COLUMN labor_hours_committed REAL DEFAULT 0;
ALTER TABLE pharmacy_orders ADD COLUMN barter_credits_used INTEGER DEFAULT 0;
ALTER TABLE pharmacy_orders ADD COLUMN unified_payment_id INTEGER;
ALTER TABLE pharmacy_orders ADD COLUMN hybrid_payment_approved BOOLEAN DEFAULT TRUE; -- Facility must approve non-fiat

-- Update existing pharmacy_orders to set unified_payment_id (will be populated by backend)
-- Placeholder: This would be done via backend migration script

-- Create table for pharmacy acceptance of alternative payments
CREATE TABLE IF NOT EXISTS pharmacy_payment_acceptance (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pharmacy_id INTEGER NOT NULL UNIQUE,
  accepts_afya_points BOOLEAN DEFAULT TRUE,
  accepts_labor_hours BOOLEAN DEFAULT FALSE, -- Can pharmacy use labor?
  accepts_barter_goods BOOLEAN DEFAULT FALSE,
  accepts_barter_services BOOLEAN DEFAULT FALSE,

  -- Labor preferences (if accepts labor)
  preferred_labor_skills TEXT, -- JSON array: ["Cleaning", "Security", "General Labor"]
  max_labor_hours_per_month REAL, -- Max labor hours pharmacy can use

  -- Barter preferences (if accepts barter)
  seeking_goods_categories TEXT, -- JSON array: ["Food", "Household Items"]
  seeking_services_categories TEXT, -- JSON array: ["Transport", "Cleaning"]

  -- Limits
  max_afya_points_per_order INTEGER, -- Max points accepted per single order
  min_fiat_percentage REAL DEFAULT 30.0, -- Require at least 30% in fiat currency

  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (pharmacy_id) REFERENCES pharmacy_locations(id) ON DELETE CASCADE
);

-- Create table for facility service payment acceptance
CREATE TABLE IF NOT EXISTS facility_payment_acceptance (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  facility_id INTEGER NOT NULL UNIQUE,
  accepts_afya_points BOOLEAN DEFAULT TRUE,
  accepts_labor_hours BOOLEAN DEFAULT TRUE, -- Facilities more likely to use labor
  accepts_barter_goods BOOLEAN DEFAULT FALSE,
  accepts_barter_services BOOLEAN DEFAULT TRUE,

  -- Labor preferences
  preferred_labor_skills TEXT, -- JSON array
  max_labor_hours_per_month REAL,

  -- Barter preferences
  seeking_goods_categories TEXT,
  seeking_services_categories TEXT,

  -- Limits
  max_afya_points_per_service INTEGER,
  min_fiat_percentage REAL DEFAULT 20.0, -- Facilities more flexible (20% min fiat)

  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE
);

-- Seed pharmacy payment acceptance defaults (all pharmacies accept Afya Points by default)
INSERT OR IGNORE INTO pharmacy_payment_acceptance (pharmacy_id, accepts_afya_points, accepts_labor_hours, max_afya_points_per_order, min_fiat_percentage)
SELECT id, TRUE, FALSE, 5000, 30.0
FROM pharmacy_locations
WHERE id NOT IN (SELECT pharmacy_id FROM pharmacy_payment_acceptance);

-- Seed facility payment acceptance defaults
INSERT OR IGNORE INTO facility_payment_acceptance (facility_id, accepts_afya_points, accepts_labor_hours, max_afya_points_per_service, min_fiat_percentage)
SELECT id, TRUE, TRUE, 10000, 20.0
FROM facility_partners
WHERE id NOT IN (SELECT facility_id FROM facility_payment_acceptance);

-- Hybrid Payment Approval Queue (Pharmacy/facility must approve non-standard payments)
CREATE TABLE IF NOT EXISTS hybrid_payment_approval_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  unified_payment_id INTEGER NOT NULL,
  transaction_type VARCHAR(40), -- pharmacy_order / facility_service
  transaction_id INTEGER,

  -- Payee who must approve
  approver_type VARCHAR(40), -- pharmacy / facility
  approver_id INTEGER,

  -- Payment details for review
  total_amount_ugx REAL,
  fiat_amount_ugx REAL,
  fiat_percentage REAL,
  non_fiat_components TEXT, -- JSON: components that need approval

  -- Status
  approval_status VARCHAR(40) DEFAULT 'pending', -- pending / approved / rejected / expired
  approved_by INTEGER, -- Staff ID who approved
  approved_at TIMESTAMP,
  rejected_at TIMESTAMP,
  rejection_reason TEXT,
  expires_at TIMESTAMP DEFAULT (datetime('now', '+24 hours')), -- Auto-reject after 24 hours

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (unified_payment_id) REFERENCES unified_payment_ledger(id) ON DELETE CASCADE,
  FOREIGN KEY (approved_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_pharmacy_payment_acceptance ON pharmacy_payment_acceptance(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_facility_payment_acceptance ON facility_payment_acceptance(facility_id);
CREATE INDEX IF NOT EXISTS idx_hybrid_approval_queue_payment ON hybrid_payment_approval_queue(unified_payment_id);
CREATE INDEX IF NOT EXISTS idx_hybrid_approval_queue_status ON hybrid_payment_approval_queue(approval_status);
CREATE INDEX IF NOT EXISTS idx_hybrid_approval_queue_approver ON hybrid_payment_approval_queue(approver_type, approver_id);
CREATE INDEX IF NOT EXISTS idx_hybrid_approval_queue_expires ON hybrid_payment_approval_queue(expires_at);

-- View: Pharmacy Hybrid Payment Capability
CREATE VIEW IF NOT EXISTS v_pharmacy_payment_options AS
SELECT
  pl.id AS pharmacy_id,
  pl.pharmacy_name,
  ppa.accepts_afya_points,
  ppa.accepts_labor_hours,
  ppa.accepts_barter_goods,
  ppa.accepts_barter_services,
  ppa.max_afya_points_per_order,
  ppa.min_fiat_percentage,
  ppa.preferred_labor_skills,
  ppa.seeking_goods_categories
FROM pharmacy_locations pl
LEFT JOIN pharmacy_payment_acceptance ppa ON pl.id = ppa.pharmacy_id;

-- View: Facility Hybrid Payment Capability
CREATE VIEW IF NOT EXISTS v_facility_payment_options AS
SELECT
  fp.id AS facility_id,
  fp.facility_name,
  fpa.accepts_afya_points,
  fpa.accepts_labor_hours,
  fpa.accepts_barter_goods,
  fpa.accepts_barter_services,
  fpa.max_afya_points_per_service,
  fpa.min_fiat_percentage,
  fpa.preferred_labor_skills,
  fpa.seeking_services_categories
FROM facility_partners fp
LEFT JOIN facility_payment_acceptance fpa ON fp.id = fpa.facility_id;

-- Trigger: Auto-create approval queue entry for hybrid payments above threshold
CREATE TRIGGER IF NOT EXISTS trg_create_hybrid_approval_queue
AFTER INSERT ON unified_payment_ledger
FOR EACH ROW
WHEN NEW.is_hybrid_payment = TRUE
  AND NEW.transaction_type IN ('pharmacy_order', 'facility_service')
  AND NEW.requires_approval = TRUE
BEGIN
  INSERT OR IGNORE INTO hybrid_payment_approval_queue (
    unified_payment_id,
    transaction_type,
    transaction_id,
    approver_type,
    approver_id,
    total_amount_ugx,
    fiat_amount_ugx,
    fiat_percentage,
    non_fiat_components
  )
  VALUES (
    NEW.id,
    NEW.transaction_type,
    NEW.transaction_id,
    NEW.payee_type,
    NEW.payee_id,
    NEW.total_amount_ugx,
    NEW.fiat_amount_ugx,
    (NEW.fiat_amount_ugx / NEW.total_amount_ugx) * 100,
    NEW.payment_breakdown
  );
END;

-- Trigger: Update pharmacy_orders when hybrid payment approved
CREATE TRIGGER IF NOT EXISTS trg_update_order_on_approval
AFTER UPDATE OF approval_status ON hybrid_payment_approval_queue
FOR EACH ROW
WHEN NEW.approval_status = 'approved'
  AND NEW.transaction_type = 'pharmacy_order'
BEGIN
  UPDATE pharmacy_orders
  SET
    hybrid_payment_approved = TRUE,
    status = 'ready'
  WHERE id = NEW.transaction_id;
END;

-- Trigger: Cancel order if hybrid payment rejected
CREATE TRIGGER IF NOT EXISTS trg_cancel_order_on_rejection
AFTER UPDATE OF approval_status ON hybrid_payment_approval_queue
FOR EACH ROW
WHEN NEW.approval_status = 'rejected'
  AND NEW.transaction_type = 'pharmacy_order'
BEGIN
  UPDATE pharmacy_orders
  SET
    status = 'cancelled',
    hybrid_payment_approved = FALSE
  WHERE id = NEW.transaction_id;

  UPDATE unified_payment_ledger
  SET
    payment_status = 'failed',
    failed_at = CURRENT_TIMESTAMP,
    failure_reason = 'Hybrid payment rejected: ' || NEW.rejection_reason
  WHERE id = NEW.unified_payment_id;
END;

-- Trigger: Auto-expire pending approvals after 24 hours
-- (This would be handled by a backend cron job, but we document it here)
/*
CRON JOB: Expire old approval requests
Schedule: Every hour
Query:
  UPDATE hybrid_payment_approval_queue
  SET approval_status = 'expired'
  WHERE approval_status = 'pending'
    AND expires_at < CURRENT_TIMESTAMP;
*/
