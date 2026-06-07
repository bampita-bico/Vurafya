-- Migration 039: Create Offline Transaction Queue
-- Date: 2026-04-11
-- Purpose: Offline-first architecture for users with poor/no internet connectivity

-- Offline Transaction Queue (Transactions awaiting sync)
CREATE TABLE IF NOT EXISTS offline_transaction_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  -- User & Device
  user_id INTEGER NOT NULL,
  device_id VARCHAR(200),

  -- Transaction Data (Encrypted JSON blob)
  transaction_type VARCHAR(40) NOT NULL, -- barter_exchange / labor_booking / pharmacy_order
  transaction_data TEXT NOT NULL, -- JSON: complete transaction payload
  transaction_data_hash VARCHAR(100), -- SHA-256 hash for integrity check

  -- Timestamps
  created_offline_at TIMESTAMP NOT NULL, -- When transaction was created on device
  queued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- When it was added to queue

  -- Sync Status
  sync_status VARCHAR(40) DEFAULT 'pending', -- pending / processing / synced / failed / conflict
  sync_attempt_count INTEGER DEFAULT 0,
  last_sync_attempt_at TIMESTAMP,
  next_sync_attempt_at TIMESTAMP,

  -- Success/Failure
  synced_at TIMESTAMP,
  sync_error TEXT,
  conflict_detected BOOLEAN DEFAULT FALSE,
  conflict_description TEXT,

  -- Server Reference (After successful sync)
  server_transaction_id INTEGER, -- ID in unified_payment_ledger or other table
  server_transaction_type VARCHAR(40),

  -- Priority
  priority INTEGER DEFAULT 5, -- 1 = highest, 10 = lowest
  is_critical BOOLEAN DEFAULT FALSE, -- Critical transactions (e.g., essential medicine orders) sync first

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Offline Sync Log (Track all sync attempts)
CREATE TABLE IF NOT EXISTS offline_sync_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  offline_transaction_id INTEGER NOT NULL,

  -- Sync Attempt
  sync_attempt_number INTEGER NOT NULL,
  sync_started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  sync_completed_at TIMESTAMP,

  -- Result
  sync_result VARCHAR(40), -- success / failure / conflict / network_error / validation_error
  sync_error TEXT,

  -- Network Conditions
  network_type VARCHAR(40), -- 2g / 3g / 4g / wifi / offline
  network_strength VARCHAR(40), -- weak / moderate / strong

  -- Data Integrity
  data_hash_match BOOLEAN, -- Does hash match original?
  data_corrupted BOOLEAN DEFAULT FALSE,

  FOREIGN KEY (offline_transaction_id) REFERENCES offline_transaction_queue(id) ON DELETE CASCADE
);

-- Conflict Resolution Strategy
CREATE TABLE IF NOT EXISTS offline_conflict_resolution (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  offline_transaction_id INTEGER NOT NULL,

  -- Conflict Type
  conflict_type VARCHAR(60) NOT NULL, -- double_spending / duplicate_transaction / stale_data / concurrent_modification

  -- Conflicting Data
  local_data TEXT, -- JSON: local version
  server_data TEXT, -- JSON: server version
  conflict_field VARCHAR(100), -- Which field has conflict

  -- Resolution Strategy
  resolution_strategy VARCHAR(60), -- server_wins / client_wins / merge / manual_review / discard_local
  resolution_applied BOOLEAN DEFAULT FALSE,
  resolved_data TEXT, -- JSON: final resolved version

  -- Manual Review
  requires_manual_review BOOLEAN DEFAULT FALSE,
  reviewed_by INTEGER, -- Staff ID
  reviewed_at TIMESTAMP,
  review_notes TEXT,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (offline_transaction_id) REFERENCES offline_transaction_queue(id) ON DELETE CASCADE,
  FOREIGN KEY (reviewed_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- Offline Capability Status (Track which features work offline)
CREATE TABLE IF NOT EXISTS offline_capability_status (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  feature_name VARCHAR(200) NOT NULL UNIQUE,

  -- Offline Support
  supports_offline BOOLEAN DEFAULT FALSE,
  offline_mode VARCHAR(40), -- full / partial / read_only / none

  -- Sync Requirements
  requires_immediate_sync BOOLEAN DEFAULT FALSE, -- Must sync immediately when online
  can_batch_sync BOOLEAN DEFAULT TRUE, -- Can sync multiple transactions in batch

  -- Conflict Handling
  conflict_resolution_strategy VARCHAR(60), -- server_wins / client_wins / merge / manual

  description TEXT,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed offline capabilities
INSERT OR IGNORE INTO offline_capability_status (feature_name, supports_offline, offline_mode, requires_immediate_sync, can_batch_sync, conflict_resolution_strategy, description) VALUES
('barter_listing_create', TRUE, 'full', FALSE, TRUE, 'server_wins', 'Users can create barter listings offline'),
('barter_exchange_initiate', TRUE, 'partial', TRUE, FALSE, 'manual', 'Can initiate trades offline but needs sync before escrow'),
('labor_booking_create', TRUE, 'full', FALSE, TRUE, 'server_wins', 'Users can book labor offline'),
('pharmacy_order_create', TRUE, 'full', TRUE, TRUE, 'manual', 'Orders created offline, synced ASAP'),
('payment_processing', FALSE, 'none', TRUE, FALSE, 'server_wins', 'Payments MUST be online (security)'),
('kyc_submission', TRUE, 'full', FALSE, TRUE, 'server_wins', 'Users can submit KYC docs offline'),
('meal_logging', TRUE, 'full', FALSE, TRUE, 'client_wins', 'Meal logs always client-wins (timestamp determines order)'),
('medication_adherence_log', TRUE, 'full', FALSE, TRUE, 'client_wins', 'Adherence logs synced in batch'),
('biometric_reading', TRUE, 'full', FALSE, TRUE, 'client_wins', 'Blood pressure, weight, glucose readings offline');

-- Device Sync State (Track last sync per device)
CREATE TABLE IF NOT EXISTS device_sync_state (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  device_id VARCHAR(200) NOT NULL,

  -- Last Sync
  last_sync_at TIMESTAMP,
  last_successful_sync_at TIMESTAMP,
  pending_transactions INTEGER DEFAULT 0,
  failed_transactions INTEGER DEFAULT 0,

  -- Sync Performance
  avg_sync_duration_seconds REAL,
  total_sync_count INTEGER DEFAULT 0,
  success_sync_count INTEGER DEFAULT 0,
  failed_sync_count INTEGER DEFAULT 0,

  -- Network Conditions
  last_network_type VARCHAR(40),
  last_network_strength VARCHAR(40),

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (user_id, device_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_offline_queue_user ON offline_transaction_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_offline_queue_status ON offline_transaction_queue(sync_status);
CREATE INDEX IF NOT EXISTS idx_offline_queue_priority ON offline_transaction_queue(priority);
CREATE INDEX IF NOT EXISTS idx_offline_queue_critical ON offline_transaction_queue(is_critical);
CREATE INDEX IF NOT EXISTS idx_offline_queue_next_sync ON offline_transaction_queue(next_sync_attempt_at);

CREATE INDEX IF NOT EXISTS idx_offline_sync_log_transaction ON offline_sync_log(offline_transaction_id);
CREATE INDEX IF NOT EXISTS idx_offline_sync_log_result ON offline_sync_log(sync_result);

CREATE INDEX IF NOT EXISTS idx_offline_conflict_transaction ON offline_conflict_resolution(offline_transaction_id);
CREATE INDEX IF NOT EXISTS idx_offline_conflict_requires_review ON offline_conflict_resolution(requires_manual_review);

CREATE INDEX IF NOT EXISTS idx_device_sync_user ON device_sync_state(user_id);
CREATE INDEX IF NOT EXISTS idx_device_sync_device ON device_sync_state(device_id);

-- View: Pending Sync Queue
CREATE VIEW IF NOT EXISTS v_pending_sync_queue AS
SELECT
  otq.id,
  u.username,
  otq.transaction_type,
  otq.created_offline_at,
  otq.sync_attempt_count,
  otq.priority,
  otq.is_critical,
  otq.next_sync_attempt_at
FROM offline_transaction_queue otq
JOIN users u ON otq.user_id = u.id
WHERE otq.sync_status = 'pending'
  AND (otq.next_sync_attempt_at IS NULL OR otq.next_sync_attempt_at <= CURRENT_TIMESTAMP)
ORDER BY otq.is_critical DESC, otq.priority ASC, otq.created_offline_at ASC;

-- View: Sync Performance by User
CREATE VIEW IF NOT EXISTS v_sync_performance_by_user AS
SELECT
  u.id AS user_id,
  u.username,
  dss.device_id,
  dss.last_sync_at,
  dss.pending_transactions,
  dss.failed_transactions,
  dss.success_sync_count,
  dss.failed_sync_count,
  CASE
    WHEN dss.total_sync_count > 0 THEN CAST(dss.success_sync_count AS REAL) / dss.total_sync_count * 100
    ELSE 0
  END AS sync_success_rate_pct,
  dss.avg_sync_duration_seconds
FROM users u
JOIN device_sync_state dss ON u.id = dss.user_id;

-- Trigger: Increment sync attempt count
CREATE TRIGGER IF NOT EXISTS trg_increment_sync_attempt
AFTER INSERT ON offline_sync_log
FOR EACH ROW
BEGIN
  UPDATE offline_transaction_queue
  SET
    sync_attempt_count = sync_attempt_count + 1,
    last_sync_attempt_at = CURRENT_TIMESTAMP,
    next_sync_attempt_at = CASE
      WHEN sync_attempt_count < 3 THEN datetime('now', '+5 minutes') -- Retry after 5 min (first 3 attempts)
      WHEN sync_attempt_count < 10 THEN datetime('now', '+30 minutes') -- Retry after 30 min (4-10 attempts)
      ELSE datetime('now', '+2 hours') -- Retry after 2 hours (11+ attempts)
    END
  WHERE id = NEW.offline_transaction_id;
END;

-- Trigger: Mark synced on success
CREATE TRIGGER IF NOT EXISTS trg_mark_synced_on_success
AFTER UPDATE OF sync_result ON offline_sync_log
FOR EACH ROW
WHEN NEW.sync_result = 'success'
BEGIN
  UPDATE offline_transaction_queue
  SET
    sync_status = 'synced',
    synced_at = CURRENT_TIMESTAMP
  WHERE id = NEW.offline_transaction_id;
END;

-- Trigger: Update device sync state
CREATE TRIGGER IF NOT EXISTS trg_update_device_sync_state
AFTER UPDATE OF sync_status ON offline_transaction_queue
FOR EACH ROW
BEGIN
  INSERT OR IGNORE INTO device_sync_state (user_id, device_id, last_sync_at, pending_transactions)
  VALUES (
    NEW.user_id,
    NEW.device_id,
    CURRENT_TIMESTAMP,
    (SELECT COUNT(*) FROM offline_transaction_queue WHERE user_id = NEW.user_id AND device_id = NEW.device_id AND sync_status = 'pending')
  )
  ON CONFLICT(user_id, device_id) DO UPDATE SET
    last_sync_at = CURRENT_TIMESTAMP,
    last_successful_sync_at = CASE WHEN NEW.sync_status = 'synced' THEN CURRENT_TIMESTAMP ELSE last_successful_sync_at END,
    pending_transactions = (SELECT COUNT(*) FROM offline_transaction_queue WHERE user_id = NEW.user_id AND device_id = NEW.device_id AND sync_status = 'pending'),
    total_sync_count = total_sync_count + 1,
    success_sync_count = success_sync_count + CASE WHEN NEW.sync_status = 'synced' THEN 1 ELSE 0 END,
    failed_sync_count = failed_sync_count + CASE WHEN NEW.sync_status = 'failed' THEN 1 ELSE 0 END,
    updated_at = CURRENT_TIMESTAMP;
END;

-- Function: Offline Sync Workflow (documented for backend)
/*
OFFLINE-FIRST SYNC WORKFLOW:

1. USER CREATES TRANSACTION OFFLINE
   - Mobile app stores transaction in local SQLite database
   - Generate unique client_transaction_id (UUID)
   - Calculate SHA-256 hash of transaction data
   - Queue for sync with priority level

2. DEVICE COMES ONLINE
   - App detects network connectivity
   - Fetch pending transactions from local queue (ORDER BY priority ASC, created_offline_at ASC)
   - Start sync process

3. SYNC ATTEMPT
   - POST transaction data to server: /api/offline/sync
   - Include: transaction_data, client_transaction_id, data_hash, device_id
   - Server validates: hash match, data integrity, no duplicates
   - Log sync attempt in offline_sync_log

4. CONFLICT DETECTION
   - Check for conflicts:
     a) Double-spending: User already spent these Afya Points
     b) Duplicate transaction: Same transaction already processed
     c) Stale data: Server has newer version
     d) Concurrent modification: Another device modified same data
   - If conflict: Apply resolution strategy (server_wins / client_wins / merge / manual_review)
   - If no conflict: Process transaction normally

5. SYNC RESULT
   - Success: Mark sync_status = 'synced', return server_transaction_id
   - Failure: Mark sync_status = 'failed', log error, schedule retry
   - Conflict: Mark sync_status = 'conflict', queue for manual review

6. RETRY STRATEGY
   - Attempt 1-3: Retry after 5 minutes (network issues)
   - Attempt 4-10: Retry after 30 minutes (validation errors)
   - Attempt 11+: Retry after 2 hours (manual review needed)
   - Max attempts: 20 (after which, flag for admin review)

7. CONFLICT RESOLUTION STRATEGIES:
   - server_wins: Discard local changes, use server data (for payments)
   - client_wins: Keep local changes, overwrite server (for logs, readings)
   - merge: Merge both versions (for additive data like meal logs)
   - manual_review: Security team reviews and decides

OFFLINE CAPABILITIES:
✓ Barter listings: Full offline support
✓ Labor bookings: Full offline support
✓ Pharmacy orders: Partial offline (needs sync before payment)
✗ Payment processing: MUST be online (security requirement)
✓ KYC submission: Full offline support
✓ Meal logging: Full offline support
✓ Medication adherence: Full offline support
✓ Biometric readings: Full offline support

NETWORK CONDITIONS:
- 2G: Batch sync every 1 hour, low priority only
- 3G: Batch sync every 30 minutes, medium priority
- 4G/WiFi: Real-time sync, all priorities
- Offline: Queue locally, sync when online

DATA INTEGRITY:
- SHA-256 hash verification on every sync
- Encryption at rest (local SQLite encrypted)
- Encryption in transit (HTTPS)
- Transaction idempotency (duplicate protection)

CRITICAL TRANSACTIONS (Priority 1):
- Essential medicine orders
- Emergency consultations
- CKD dialysis bookings
- Insulin prescriptions
→ These sync IMMEDIATELY when device comes online
*/
