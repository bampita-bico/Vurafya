-- Migration 021: Create Currency Conversion Matrix
-- Date: 2026-04-11
-- Purpose: Real-time exchange rates for 54+ African currencies + Afya Points + Labor Hours + Barter Credits

-- Currency Exchange Rates (Fiat-to-Fiat)
CREATE TABLE IF NOT EXISTS currency_exchange_rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_currency_code VARCHAR(5) NOT NULL, -- UGX, KES, NGN, ZAR, etc.
  to_currency_code VARCHAR(5) NOT NULL, -- Target currency
  exchange_rate REAL NOT NULL, -- How many 'to' units per 1 'from' unit (e.g., 1 UGX = 0.029 KES)
  rate_source VARCHAR(100), -- Central Bank / XE.com / Manual / API
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  update_frequency VARCHAR(20) DEFAULT 'daily', -- daily / hourly / realtime
  UNIQUE (from_currency_code, to_currency_code)
);

-- Universal Currency Matrix (All-to-All Conversion: Fiat + Afya Points + Labor + Barter)
-- Star topology: All currencies convert through UGX base
CREATE TABLE IF NOT EXISTS universal_currency_matrix (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  currency_type VARCHAR(40) NOT NULL, -- fiat / afya_points / labor_hour / barter_credit
  currency_code VARCHAR(10), -- UGX / KES / AP / LH / BC (NULL for afya_points/labor/barter)
  ugx_exchange_rate REAL NOT NULL, -- 1 unit of this currency = X UGX
  is_base_currency BOOLEAN DEFAULT FALSE, -- TRUE for UGX only
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  UNIQUE (currency_type, currency_code)
);

-- Exchange Rate Locks (24-hour rate protection against volatility)
CREATE TABLE IF NOT EXISTS exchange_rate_locks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  transaction_id INTEGER, -- Reference to pharmacy_order, barter_exchange, labor_booking
  transaction_type VARCHAR(40), -- pharmacy_order / barter_exchange / labor_booking
  from_currency_code VARCHAR(10) NOT NULL,
  to_currency_code VARCHAR(10) NOT NULL,
  locked_rate REAL NOT NULL,
  locked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL, -- locked_at + 24 hours
  is_used BOOLEAN DEFAULT FALSE, -- Marked TRUE when transaction completes
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Exchange Rate History (For accounting and auditing)
CREATE TABLE IF NOT EXISTS exchange_rate_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_currency_code VARCHAR(5) NOT NULL,
  to_currency_code VARCHAR(5) NOT NULL,
  exchange_rate REAL NOT NULL,
  rate_source VARCHAR(100),
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed base currency (UGX = 1.0)
INSERT OR IGNORE INTO universal_currency_matrix (currency_type, currency_code, ugx_exchange_rate, is_base_currency) VALUES
('fiat', 'UGX', 1.0, TRUE);

-- Seed Afya Points conversion (1000 UGX = 10 AP, so 1 AP = 100 UGX)
INSERT OR IGNORE INTO universal_currency_matrix (currency_type, currency_code, ugx_exchange_rate) VALUES
('afya_points', 'AP', 100.0);

-- Seed Labor Hour conversion (1 hour = 10,000 UGX base rate, adjusted by skill/country later)
INSERT OR IGNORE INTO universal_currency_matrix (currency_type, currency_code, ugx_exchange_rate) VALUES
('labor_hour', 'LH', 10000.0);

-- Seed Barter Credit conversion (1 BC = 1,000 UGX base valuation)
INSERT OR IGNORE INTO universal_currency_matrix (currency_type, currency_code, ugx_exchange_rate) VALUES
('barter_credit', 'BC', 1000.0);

-- Seed fiat currency exchange rates (all convert through UGX base)
-- East Africa
INSERT OR IGNORE INTO universal_currency_matrix (currency_type, currency_code, ugx_exchange_rate) VALUES
('fiat', 'KES', 34.5),  -- 1 KES = 34.5 UGX
('fiat', 'TZS', 1.52),  -- 1 TZS = 1.52 UGX
('fiat', 'RWF', 2.8),   -- 1 RWF = 2.8 UGX
('fiat', 'BIF', 0.12),  -- 1 BIF = 0.12 UGX
('fiat', 'SSP', 0.65),  -- 1 SSP = 0.65 UGX
('fiat', 'SOS', 0.0065), -- 1 SOS = 0.0065 UGX
('fiat', 'ETB', 4.8),   -- 1 ETB = 4.8 UGX
('fiat', 'ERN', 18.2),  -- 1 ERN = 18.2 UGX
('fiat', 'DJF', 1.54),  -- 1 DJF = 1.54 UGX
('fiat', 'SCR', 19.5),  -- 1 SCR = 19.5 UGX
('fiat', 'MUR', 6.3);   -- 1 MUR = 6.3 UGX

-- West Africa
INSERT OR IGNORE INTO universal_currency_matrix (currency_type, currency_code, ugx_exchange_rate) VALUES
('fiat', 'NGN', 4.5),   -- 1 NGN = 4.5 UGX
('fiat', 'GHS', 224.0), -- 1 GHS = 224 UGX
('fiat', 'XOF', 0.47),  -- 1 XOF (CFA West) = 0.47 UGX
('fiat', 'SLL', 0.013), -- 1 SLL = 0.013 UGX
('fiat', 'LRD', 1.42),  -- 1 LRD = 1.42 UGX
('fiat', 'GMD', 4.9),   -- 1 GMD = 4.9 UGX
('fiat', 'GNF', 0.032), -- 1 GNF = 0.032 UGX
('fiat', 'CVE', 2.65),  -- 1 CVE = 2.65 UGX
('fiat', 'MRU', 7.3);   -- 1 MRU = 7.3 UGX

-- Central Africa
INSERT OR IGNORE INTO universal_currency_matrix (currency_type, currency_code, ugx_exchange_rate) VALUES
('fiat', 'XAF', 0.47),  -- 1 XAF (CFA Central) = 0.47 UGX
('fiat', 'CDF', 0.11),  -- 1 CDF = 0.11 UGX
('fiat', 'STN', 12.1);  -- 1 STN = 12.1 UGX

-- North Africa
INSERT OR IGNORE INTO universal_currency_matrix (currency_type, currency_code, ugx_exchange_rate) VALUES
('fiat', 'DZD', 2.05),  -- 1 DZD = 2.05 UGX
('fiat', 'EGP', 5.6),   -- 1 EGP = 5.6 UGX
('fiat', 'LYD', 56.8),  -- 1 LYD = 56.8 UGX
('fiat', 'MAD', 27.5),  -- 1 MAD = 27.5 UGX
('fiat', 'TND', 88.0);  -- 1 TND = 88.0 UGX

-- Southern Africa
INSERT OR IGNORE INTO universal_currency_matrix (currency_type, currency_code, ugx_exchange_rate) VALUES
('fiat', 'ZAR', 208.0), -- 1 ZAR = 208 UGX
('fiat', 'ZWL', 0.0034), -- 1 ZWL = 0.0034 UGX (hyperinflation)
('fiat', 'ZMW', 13.5),  -- 1 ZMW = 13.5 UGX
('fiat', 'BWP', 328.0), -- 1 BWP = 328 UGX
('fiat', 'NAD', 208.0), -- 1 NAD = 208 UGX (pegged to ZAR)
('fiat', 'LSL', 208.0), -- 1 LSL = 208 UGX (pegged to ZAR)
('fiat', 'SZL', 208.0), -- 1 SZL = 208 UGX (pegged to ZAR)
('fiat', 'MWK', 0.21),  -- 1 MWK = 0.21 UGX
('fiat', 'MZN', 4.3),   -- 1 MZN = 4.3 UGX
('fiat', 'AOA', 0.56),  -- 1 AOA = 0.56 UGX
('fiat', 'MGA', 0.063), -- 1 MGA = 0.063 UGX
('fiat', 'KMF', 0.63),  -- 1 KMF = 0.63 UGX
('fiat', 'EUR', 3050.0); -- 1 EUR = 3,050 UGX (Réunion)

-- Seed pairwise fiat-to-fiat rates (most common pairs)
-- These will be auto-calculated from universal_currency_matrix, but seed a few manually for speed
INSERT OR IGNORE INTO currency_exchange_rates (from_currency_code, to_currency_code, exchange_rate, rate_source) VALUES
('UGX', 'KES', 0.029, 'Central Bank'),
('UGX', 'TZS', 0.66, 'Central Bank'),
('UGX', 'NGN', 0.22, 'Central Bank'),
('UGX', 'ZAR', 0.0048, 'Central Bank'),
('KES', 'UGX', 34.5, 'Central Bank'),
('KES', 'TZS', 22.8, 'Central Bank'),
('NGN', 'UGX', 4.5, 'Central Bank'),
('ZAR', 'UGX', 208.0, 'Central Bank');

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_exchange_rates_from ON currency_exchange_rates(from_currency_code);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_to ON currency_exchange_rates(to_currency_code);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_updated ON currency_exchange_rates(last_updated);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_active ON currency_exchange_rates(is_active);

CREATE INDEX IF NOT EXISTS idx_universal_currency_type ON universal_currency_matrix(currency_type);
CREATE INDEX IF NOT EXISTS idx_universal_currency_code ON universal_currency_matrix(currency_code);
CREATE INDEX IF NOT EXISTS idx_universal_currency_active ON universal_currency_matrix(is_active);

CREATE INDEX IF NOT EXISTS idx_rate_locks_user ON exchange_rate_locks(user_id);
CREATE INDEX IF NOT EXISTS idx_rate_locks_expires ON exchange_rate_locks(expires_at);
CREATE INDEX IF NOT EXISTS idx_rate_locks_used ON exchange_rate_locks(is_used);

CREATE INDEX IF NOT EXISTS idx_rate_history_from ON exchange_rate_history(from_currency_code);
CREATE INDEX IF NOT EXISTS idx_rate_history_to ON exchange_rate_history(to_currency_code);
CREATE INDEX IF NOT EXISTS idx_rate_history_recorded ON exchange_rate_history(recorded_at);

-- Create view for easy currency conversion lookup
CREATE VIEW IF NOT EXISTS v_currency_conversion AS
SELECT
  from_curr.currency_code AS from_currency,
  to_curr.currency_code AS to_currency,
  from_curr.currency_type AS from_type,
  to_curr.currency_type AS to_type,
  (to_curr.ugx_exchange_rate / from_curr.ugx_exchange_rate) AS conversion_rate,
  from_curr.last_updated AS rate_updated_at
FROM universal_currency_matrix from_curr
CROSS JOIN universal_currency_matrix to_curr
WHERE from_curr.is_active = TRUE
  AND to_curr.is_active = TRUE
  AND from_curr.id != to_curr.id;

-- Trigger: Archive exchange rates to history when updated
CREATE TRIGGER IF NOT EXISTS trg_archive_exchange_rate
AFTER UPDATE OF exchange_rate ON currency_exchange_rates
FOR EACH ROW
BEGIN
  INSERT OR IGNORE INTO exchange_rate_history (from_currency_code, to_currency_code, exchange_rate, rate_source)
  VALUES (OLD.from_currency_code, OLD.to_currency_code, OLD.exchange_rate, OLD.rate_source);
END;
