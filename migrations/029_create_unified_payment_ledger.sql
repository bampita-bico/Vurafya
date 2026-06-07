-- Migration 029: Create Unified Payment Ledger
-- Date: 2026-04-11
-- Purpose: Single ledger for ALL transactions (fiat, points, barter, labor, hybrid)

-- Unified Payment Ledger (Master record of all transactions)
CREATE TABLE IF NOT EXISTS unified_payment_ledger (
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  -- Transaction Identity
  transaction_type VARCHAR(40) NOT NULL, -- pharmacy_order / barter_exchange / labor_payment / facility_service / reward_redemption / consultation_booking
  transaction_id INTEGER NOT NULL, -- ID from respective transaction table
  transaction_reference VARCHAR(100), -- Human-readable reference (e.g., "ORDER-2026-0001")

  -- Parties Involved
  payer_user_id INTEGER NOT NULL,
  payee_type VARCHAR(40), -- pharmacy / facility / user / platform
  payee_id INTEGER, -- pharmacy_id / facility_id / user_id

  -- Payment Amount (Total)
  total_amount_ugx REAL NOT NULL, -- Total transaction value in UGX
  total_amount_local_currency REAL, -- In payer's local currency
  local_currency_code VARCHAR(5), -- KES / NGN / ZAR / etc.

  -- Payment Method
  payment_method VARCHAR(40) NOT NULL, -- fiat_only / afya_points_only / labor_only / barter_only / hybrid
  is_hybrid_payment BOOLEAN DEFAULT FALSE,

  -- Payment Breakdown (JSON for hybrid payments)
  payment_breakdown TEXT, -- JSON: {"fiat_ugx": 30000, "afya_points": 300, "labor_hours": 2, "barter_credit": 1}

  -- Individual Payment Components
  fiat_amount_ugx REAL DEFAULT 0,
  fiat_currency_code VARCHAR(5),
  afya_points_amount INTEGER DEFAULT 0,
  labor_hours_amount REAL DEFAULT 0,
  labor_hours_value_ugx REAL DEFAULT 0,
  barter_credit_amount INTEGER DEFAULT 0,
  barter_credit_value_ugx REAL DEFAULT 0,

  -- Status
  payment_status VARCHAR(40) DEFAULT 'pending', -- pending / processing / completed / failed / refunded / disputed
  initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  failed_at TIMESTAMP,
  failure_reason TEXT,

  -- Platform Fees
  transaction_fee_pct REAL, -- Variable by transaction type (0-5%)
  transaction_fee_ugx REAL,
  transaction_fee_ap INTEGER,
  fee_waived BOOLEAN DEFAULT FALSE,
  fee_waiver_reason TEXT, -- social_good / vulnerable_population / promotional

  -- Revenue Attribution
  platform_revenue_ugx REAL,
  partner_revenue_ugx REAL, -- For facility/pharmacy partners
  partner_commission_pct REAL,

  -- Exchange Rates (Locked at transaction time)
  exchange_rate_lock_id INTEGER, -- FK to exchange_rate_locks
  exchange_rates_json TEXT, -- JSON snapshot of rates used

  -- Verification & Approval
  requires_approval BOOLEAN DEFAULT FALSE,
  approved_by INTEGER, -- Staff/admin who approved
  approved_at TIMESTAMP,

  -- Dispute
  dispute_raised BOOLEAN DEFAULT FALSE,
  dispute_id INTEGER,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (payer_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (exchange_rate_lock_id) REFERENCES exchange_rate_locks(id) ON DELETE SET NULL,
  FOREIGN KEY (approved_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- Hybrid Payment Details (Expanded detail for complex hybrid payments)
CREATE TABLE IF NOT EXISTS hybrid_payment_details (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  unified_payment_id INTEGER NOT NULL,

  -- Component Details
  component_type VARCHAR(40) NOT NULL, -- fiat / afya_points / labor_hours / barter_credit
  component_amount REAL NOT NULL, -- Amount in native unit (UGX, AP, hours, credits)
  component_value_ugx REAL NOT NULL, -- Converted to UGX for accounting
  component_percentage REAL, -- % of total payment

  -- Labor-Specific Details
  labor_service_id INTEGER, -- If labor component
  labor_booking_id INTEGER, -- Reference to booking
  hours_committed REAL,
  hourly_rate_ap INTEGER,

  -- Barter-Specific Details
  barter_item_type VARCHAR(40), -- barter_good / barter_service
  barter_item_id INTEGER, -- Reference to catalog item
  barter_exchange_id INTEGER, -- Reference to exchange transaction

  -- Status
  component_status VARCHAR(40) DEFAULT 'pending', -- pending / committed / completed / failed
  completed_at TIMESTAMP,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (unified_payment_id) REFERENCES unified_payment_ledger(id) ON DELETE CASCADE,
  FOREIGN KEY (labor_service_id) REFERENCES labor_services_registry(id) ON DELETE SET NULL,
  FOREIGN KEY (labor_booking_id) REFERENCES labor_booking_requests(id) ON DELETE SET NULL,
  FOREIGN KEY (barter_exchange_id) REFERENCES barter_exchange_transactions(id) ON DELETE SET NULL
);

-- Payment Method Preferences (User's preferred payment methods)
CREATE TABLE IF NOT EXISTS user_payment_preferences (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL UNIQUE,

  -- Preference Order (1 = most preferred)
  preferred_method_1 VARCHAR(40) DEFAULT 'afya_points',
  preferred_method_2 VARCHAR(40) DEFAULT 'fiat_currency',
  preferred_method_3 VARCHAR(40) DEFAULT 'labor_hours',
  preferred_method_4 VARCHAR(40) DEFAULT 'barter_credit',

  -- Auto-Hybrid Settings
  enable_auto_hybrid BOOLEAN DEFAULT FALSE, -- Automatically use multiple methods to cover cost
  max_afya_points_per_transaction INTEGER, -- Don't spend more than X points per transaction
  max_labor_hours_per_month REAL, -- Don't commit more than X hours per month

  -- Defaults
  default_fiat_currency VARCHAR(5), -- User's preferred currency

  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_unified_payment_payer ON unified_payment_ledger(payer_user_id);
CREATE INDEX IF NOT EXISTS idx_unified_payment_type ON unified_payment_ledger(transaction_type);
CREATE INDEX IF NOT EXISTS idx_unified_payment_status ON unified_payment_ledger(payment_status);
CREATE INDEX IF NOT EXISTS idx_unified_payment_method ON unified_payment_ledger(payment_method);
CREATE INDEX IF NOT EXISTS idx_unified_payment_created ON unified_payment_ledger(created_at);
CREATE INDEX IF NOT EXISTS idx_unified_payment_payee ON unified_payment_ledger(payee_type, payee_id);
CREATE INDEX IF NOT EXISTS idx_unified_payment_hybrid ON unified_payment_ledger(is_hybrid_payment);

CREATE INDEX IF NOT EXISTS idx_hybrid_details_payment ON hybrid_payment_details(unified_payment_id);
CREATE INDEX IF NOT EXISTS idx_hybrid_details_type ON hybrid_payment_details(component_type);
CREATE INDEX IF NOT EXISTS idx_hybrid_details_labor ON hybrid_payment_details(labor_booking_id);
CREATE INDEX IF NOT EXISTS idx_hybrid_details_barter ON hybrid_payment_details(barter_exchange_id);

CREATE INDEX IF NOT EXISTS idx_payment_preferences_user ON user_payment_preferences(user_id);

-- View: User Payment History (for easy lookup)
CREATE VIEW IF NOT EXISTS v_user_payment_history AS
SELECT
  upl.id AS payment_id,
  upl.transaction_type,
  upl.transaction_reference,
  u.username AS payer,
  upl.total_amount_ugx,
  upl.payment_method,
  upl.is_hybrid_payment,
  upl.payment_status,
  upl.afya_points_amount,
  upl.labor_hours_amount,
  upl.barter_credit_amount,
  upl.transaction_fee_ugx,
  upl.platform_revenue_ugx,
  upl.completed_at,
  upl.created_at
FROM unified_payment_ledger upl
JOIN users u ON upl.payer_user_id = u.id
ORDER BY upl.created_at DESC;

-- Trigger: Auto-calculate payment breakdown percentages
CREATE TRIGGER IF NOT EXISTS trg_calc_payment_breakdown_pct
AFTER INSERT ON hybrid_payment_details
FOR EACH ROW
BEGIN
  UPDATE hybrid_payment_details
  SET component_percentage = (NEW.component_value_ugx / (
    SELECT total_amount_ugx FROM unified_payment_ledger WHERE id = NEW.unified_payment_id
  )) * 100
  WHERE id = NEW.id;
END;

-- Trigger: Mark payment as completed when all components completed
CREATE TRIGGER IF NOT EXISTS trg_complete_hybrid_payment
AFTER UPDATE OF component_status ON hybrid_payment_details
FOR EACH ROW
WHEN NEW.component_status = 'completed'
BEGIN
  UPDATE unified_payment_ledger
  SET
    payment_status = 'completed',
    completed_at = CURRENT_TIMESTAMP
  WHERE id = NEW.unified_payment_id
    AND NOT EXISTS (
      SELECT 1 FROM hybrid_payment_details
      WHERE unified_payment_id = NEW.unified_payment_id
        AND component_status != 'completed'
    );
END;

-- Trigger: Update timestamp
CREATE TRIGGER IF NOT EXISTS trg_update_unified_payment_timestamp
AFTER UPDATE ON unified_payment_ledger
FOR EACH ROW
BEGIN
  UPDATE unified_payment_ledger SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Trigger: Create payment preference defaults for new users
CREATE TRIGGER IF NOT EXISTS trg_create_payment_preferences
AFTER INSERT ON users
FOR EACH ROW
BEGIN
  INSERT OR IGNORE INTO user_payment_preferences (user_id, default_fiat_currency)
  VALUES (NEW.id, 'UGX');
END;

-- Function to calculate optimal payment split (documented for backend)
/*
HYBRID PAYMENT OPTIMIZATION:

Given: User wants to pay 100,000 UGX for medication
Available: 500 AP (50,000 UGX), 30,000 UGX cash, 2 labor hours (20,000 UGX)

Optimization logic:
1. Check user preferences (preferred_method_1, preferred_method_2, etc.)
2. Check available balances (AP balance, cash, labor hours available)
3. Minimize transaction fees (labor has 5% fee, barter 3.5%, points 0%)
4. Suggest split:
   - Use all Afya Points first (0% fee): 500 AP = 50,000 UGX
   - Use all cash: 30,000 UGX
   - Use labor to cover remainder: 20,000 UGX = 2 hours
   Total: 50,000 + 30,000 + 20,000 = 100,000 UGX ✓

Payment breakdown:
{
  "afya_points": 500,
  "fiat_ugx": 30000,
  "labor_hours": 2
}

Platform fees:
- Afya Points: 0 UGX (0% fee)
- Fiat: 0 UGX (0% fee on fiat)
- Labor: 1,000 UGX (5% of 20,000)
Total fee: 1,000 UGX

Net to pharmacy: 100,000 UGX (user pays 1,000 UGX fee separately)
*/
