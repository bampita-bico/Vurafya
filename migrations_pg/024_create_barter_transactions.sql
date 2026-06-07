-- Migration 024: Create Barter Exchange Transactions
-- Date: 2026-04-11
-- Purpose: Record all barter trades with escrow, verification, and dispute resolution

-- Barter Exchange Transactions (Main transaction record)
CREATE TABLE IF NOT EXISTS barter_exchange_transactions (
  id SERIAL PRIMARY KEY,
  transaction_type VARCHAR(40), -- goods_for_goods / goods_for_services / services_for_services / goods_for_healthcare / services_for_healthcare

  -- Party A (Initiator - who starts the trade)
  party_a_user_id INTEGER NOT NULL,
  party_a_offer_type VARCHAR(40), -- barter_good / barter_service
  party_a_offer_id INTEGER, -- ID from barter_goods_catalog or barter_services_catalog
  party_a_offer_description TEXT, -- Cached description
  party_a_afya_points_value INTEGER, -- Platform's valuation

  -- Party B (Receiver - who accepts the trade)
  party_b_user_id INTEGER NOT NULL,
  party_b_offer_type VARCHAR(40), -- barter_good / barter_service / pharmacy_product / medical_service
  party_b_offer_id INTEGER, -- ID from respective catalog
  party_b_offer_description TEXT,
  party_b_afya_points_value INTEGER,

  -- Exchange Details
  value_difference_points INTEGER, -- If Party A's value > Party B's, difference in Afya Points
  balance_payment_method VARCHAR(40), -- afya_points / fiat_currency / labor_hours / NULL (even trade)
  balance_payment_amount DOUBLE PRECISION,
  balance_payment_currency VARCHAR(10), -- UGX / KES / AP / LH

  -- Status Lifecycle
  status VARCHAR(40) DEFAULT 'pending', -- pending / accepted / in_escrow / completed / cancelled / disputed
  initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  accepted_at TIMESTAMP,
  escrow_locked_at TIMESTAMP,
  escrow_release_at TIMESTAMP,
  completed_at TIMESTAMP,
  cancelled_at TIMESTAMP,
  cancellation_reason TEXT,

  -- Verification (Both parties must confirm)
  party_a_confirmed BOOLEAN DEFAULT FALSE,
  party_a_confirmed_at TIMESTAMP,
  party_b_confirmed BOOLEAN DEFAULT FALSE,
  party_b_confirmed_at TIMESTAMP,

  -- Facility/Staff Verification (Optional for high-value trades)
  facility_verified BOOLEAN DEFAULT FALSE,
  verified_by INTEGER, -- Staff ID
  verified_at TIMESTAMP,
  verification_notes TEXT,

  -- Platform Revenue (Transaction fees)
  transaction_fee_pct DOUBLE PRECISION DEFAULT 3.5, -- 3.5% fee on barter exchanges
  transaction_fee_ap INTEGER, -- Fee charged in Afya Points
  transaction_fee_ugx DOUBLE PRECISION, -- Converted fee to UGX for accounting
  fee_paid BOOLEAN DEFAULT FALSE,
  fee_paid_at TIMESTAMP,

  -- Dispute Resolution
  dispute_raised BOOLEAN DEFAULT FALSE,
  dispute_raised_by INTEGER, -- user_id who raised dispute
  dispute_raised_at TIMESTAMP,
  dispute_reason TEXT,
  dispute_status VARCHAR(40), -- pending_review / under_investigation / resolved / escalated
  dispute_resolved_at TIMESTAMP,
  dispute_resolution_notes TEXT,
  dispute_resolved_by INTEGER, -- Staff/admin who resolved

  -- Ratings & Reviews (After completion)
  party_a_rating INTEGER, -- 1-5 stars
  party_a_review TEXT,
  party_a_reviewed_at TIMESTAMP,
  party_b_rating INTEGER,
  party_b_review TEXT,
  party_b_reviewed_at TIMESTAMP,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (party_a_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (party_b_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verified_by) REFERENCES medical_staff(id) ON DELETE SET NULL,
  FOREIGN KEY (dispute_raised_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (dispute_resolved_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- Escrow Locks (Prevents items from being traded multiple times)
CREATE TABLE IF NOT EXISTS barter_escrow_locks (
  id SERIAL PRIMARY KEY,
  transaction_id INTEGER NOT NULL,
  item_type VARCHAR(40), -- barter_good / barter_service
  item_id INTEGER NOT NULL,
  locked_by_user_id INTEGER NOT NULL,
  locked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL, -- Auto-release after 48 hours if not completed
  is_released BOOLEAN DEFAULT FALSE,
  released_at TIMESTAMP,
  FOREIGN KEY (transaction_id) REFERENCES barter_exchange_transactions(id) ON DELETE CASCADE,
  FOREIGN KEY (locked_by_user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Transaction Reviews (Peer reviews after exchange)
CREATE TABLE IF NOT EXISTS transaction_reviews (
  id SERIAL PRIMARY KEY,
  transaction_id INTEGER NOT NULL,
  transaction_type VARCHAR(40), -- barter_exchange / labor_booking / pharmacy_order
  reviewer_user_id INTEGER NOT NULL,
  reviewed_user_id INTEGER NOT NULL, -- User being reviewed
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5), -- 1-5 stars
  review_text TEXT,
  review_prompts TEXT, -- JSON: {"fair_trade": true, "on_time": true, "as_described": true}
  helpful_count INTEGER DEFAULT 0, -- How many users found this review helpful
  reported BOOLEAN DEFAULT FALSE,
  reported_reason TEXT,
  is_verified_review BOOLEAN DEFAULT FALSE, -- Verified by platform (transaction actually happened)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (transaction_id) REFERENCES barter_exchange_transactions(id) ON DELETE CASCADE,
  FOREIGN KEY (reviewer_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (reviewed_user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (transaction_id, reviewer_user_id)
);

-- Barter Transaction Timeline (Audit trail of status changes)
CREATE TABLE IF NOT EXISTS barter_transaction_timeline (
  id SERIAL PRIMARY KEY,
  transaction_id INTEGER NOT NULL,
  status_from VARCHAR(40),
  status_to VARCHAR(40) NOT NULL,
  changed_by INTEGER, -- user_id or staff_id
  change_reason TEXT,
  automated BOOLEAN DEFAULT FALSE, -- TRUE if system-triggered (e.g., escrow timeout)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (transaction_id) REFERENCES barter_exchange_transactions(id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_barter_transactions_party_a ON barter_exchange_transactions(party_a_user_id);
CREATE INDEX IF NOT EXISTS idx_barter_transactions_party_b ON barter_exchange_transactions(party_b_user_id);
CREATE INDEX IF NOT EXISTS idx_barter_transactions_status ON barter_exchange_transactions(status);
CREATE INDEX IF NOT EXISTS idx_barter_transactions_type ON barter_exchange_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_barter_transactions_created ON barter_exchange_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_barter_transactions_dispute ON barter_exchange_transactions(dispute_raised);

CREATE INDEX IF NOT EXISTS idx_escrow_locks_transaction ON barter_escrow_locks(transaction_id);
CREATE INDEX IF NOT EXISTS idx_escrow_locks_item ON barter_escrow_locks(item_type, item_id);
CREATE INDEX IF NOT EXISTS idx_escrow_locks_released ON barter_escrow_locks(is_released);
CREATE INDEX IF NOT EXISTS idx_escrow_locks_expires ON barter_escrow_locks(expires_at);

CREATE INDEX IF NOT EXISTS idx_transaction_reviews_transaction ON transaction_reviews(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_reviews_reviewer ON transaction_reviews(reviewer_user_id);
CREATE INDEX IF NOT EXISTS idx_transaction_reviews_reviewed ON transaction_reviews(reviewed_user_id);
CREATE INDEX IF NOT EXISTS idx_transaction_reviews_rating ON transaction_reviews(rating);

CREATE INDEX IF NOT EXISTS idx_transaction_timeline_transaction ON barter_transaction_timeline(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_timeline_created ON barter_transaction_timeline(created_at);

-- Trigger: Auto-calculate transaction fee when status changes to 'accepted'
CREATE TRIGGER IF NOT EXISTS trg_calculate_barter_transaction_fee
AFTER UPDATE OF status ON barter_exchange_transactions
FOR EACH ROW
WHEN NEW.status = 'accepted' AND OLD.status = 'pending'
BEGIN
  UPDATE barter_exchange_transactions
  SET
    transaction_fee_afya_points = CAST((NEW.party_a_afya_points_value + NEW.party_b_afya_points_value) * NEW.transaction_fee_pct / 100 AS INTEGER),
    platform_revenue_ugx = ((NEW.party_a_afya_points_value + NEW.party_b_afya_points_value) * NEW.transaction_fee_pct / 100) * 100 -- 1 AP = 100 UGX
  WHERE id = NEW.id;
END;

-- Trigger: Auto-create escrow locks when status changes to 'in_escrow'
CREATE TRIGGER IF NOT EXISTS trg_create_escrow_locks
AFTER UPDATE OF status ON barter_exchange_transactions
FOR EACH ROW
WHEN NEW.status = 'in_escrow' AND OLD.status = 'accepted'
BEGIN
  -- Lock Party A's item
  INSERT INTO barter_escrow_locks (transaction_id, item_type, item_id, locked_by_user_id, expires_at)
  VALUES (NEW.id, NEW.party_a_offer_type, NEW.party_a_offer_id, NEW.party_a_user_id, CURRENT_TIMESTAMP + INTERVAL '48 hours');

  -- Lock Party B's item (if it's a barter item, not a healthcare service)
  INSERT INTO barter_escrow_locks (transaction_id, item_type, item_id, locked_by_user_id, expires_at)
  SELECT NEW.id, NEW.party_b_offer_type, NEW.party_b_offer_id, NEW.party_b_user_id, CURRENT_TIMESTAMP + INTERVAL '48 hours'
  WHERE NEW.party_b_offer_type IN ('barter_good', 'barter_service');

  -- Mark items as unavailable in catalogs
  UPDATE barter_goods_catalog SET is_available = FALSE
  WHERE id = NEW.party_a_offer_id AND NEW.party_a_offer_type = 'barter_good';

  UPDATE barter_services_catalog SET is_available = FALSE
  WHERE id = NEW.party_a_offer_id AND NEW.party_a_offer_type = 'barter_service';

  UPDATE barter_goods_catalog SET is_available = FALSE
  WHERE id = NEW.party_b_offer_id AND NEW.party_b_offer_type = 'barter_good';

  UPDATE barter_services_catalog SET is_available = FALSE
  WHERE id = NEW.party_b_offer_id AND NEW.party_b_offer_type = 'barter_service';
END;

-- Trigger: Release escrow and mark items available when status changes to 'completed' or 'cancelled'
CREATE TRIGGER IF NOT EXISTS trg_release_escrow
AFTER UPDATE OF status ON barter_exchange_transactions
FOR EACH ROW
WHEN NEW.status IN ('completed', 'cancelled') AND OLD.status = 'in_escrow'
BEGIN
  -- Release escrow locks
  UPDATE barter_escrow_locks
  SET is_released = TRUE, released_at = CURRENT_TIMESTAMP
  WHERE transaction_id = NEW.id AND is_released = FALSE;

  -- If cancelled, mark items available again
  UPDATE barter_goods_catalog SET is_available = TRUE
  WHERE id IN (
    SELECT item_id FROM barter_escrow_locks
    WHERE transaction_id = NEW.id AND item_type = 'barter_good'
  ) AND NEW.status = 'cancelled';

  UPDATE barter_services_catalog SET is_available = TRUE
  WHERE id IN (
    SELECT item_id FROM barter_escrow_locks
    WHERE transaction_id = NEW.id AND item_type = 'barter_service'
  ) AND NEW.status = 'cancelled';

  -- If completed, remove items from catalog (no longer available)
  DELETE FROM barter_goods_catalog
  WHERE id IN (
    SELECT item_id FROM barter_escrow_locks
    WHERE transaction_id = NEW.id AND item_type = 'barter_good'
  ) AND NEW.status = 'completed';

  DELETE FROM barter_services_catalog
  WHERE id IN (
    SELECT item_id FROM barter_escrow_locks
    WHERE transaction_id = NEW.id AND item_type = 'barter_service'
  ) AND NEW.status = 'completed';
END;

-- Trigger: Log status changes to timeline
CREATE TRIGGER IF NOT EXISTS trg_log_barter_status_change
AFTER UPDATE OF status ON barter_exchange_transactions
FOR EACH ROW
WHEN NEW.status != OLD.status
BEGIN
  INSERT INTO barter_transaction_timeline (transaction_id, status_from, status_to, automated)
  VALUES (NEW.id, OLD.status, NEW.status, FALSE);
END;

-- Trigger: Update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS trg_update_barter_transaction_timestamp
AFTER UPDATE ON barter_exchange_transactions
FOR EACH ROW
BEGIN
  UPDATE barter_exchange_transactions SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Trigger: Auto-update user trust ratings after review
CREATE TRIGGER IF NOT EXISTS trg_update_trust_after_review
AFTER INSERT ON transaction_reviews
FOR EACH ROW
BEGIN
  -- Update barter_services_catalog rating for service providers
  UPDATE barter_services_catalog
  SET
    rating_count = rating_count + 1,
    rating_avg = ((rating_avg * rating_count) + NEW.rating) / (rating_count + 1)
  WHERE user_id = NEW.reviewed_user_id;
END;
