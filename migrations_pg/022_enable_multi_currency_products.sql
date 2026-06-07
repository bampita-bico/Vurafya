-- Migration 022: Enable Multi-Currency Product Pricing
-- Date: 2026-04-11
-- Purpose: Allow all products (pharmacy, services, rewards) to be priced in ANY of 54+ currencies

-- Multi-Currency Product Pricing Table (Generic for ALL products)
CREATE TABLE IF NOT EXISTS product_multi_currency_pricing (
  id SERIAL PRIMARY KEY,
  product_type VARCHAR(40) NOT NULL, -- pharmacy_inventory / medical_services / reward_catalog / facility_services
  product_id INTEGER NOT NULL, -- ID from respective table
  currency_code VARCHAR(5) NOT NULL, -- UGX / KES / NGN / ZAR / etc.
  price DOUBLE PRECISION NOT NULL,
  is_manual BOOLEAN DEFAULT FALSE, -- TRUE if manually set, FALSE if auto-converted from base
  base_price_ugx DOUBLE PRECISION, -- Original price in UGX (for auto-conversion reference)
  auto_convert BOOLEAN DEFAULT TRUE, -- Auto-update when exchange rates change
  effective_date DATE DEFAULT CURRENT_DATE,
  expires_at DATE, -- For promotional pricing
  is_active BOOLEAN DEFAULT TRUE,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (currency_code) REFERENCES countries_supported(currency_code),
  UNIQUE (product_type, product_id, currency_code)
);

-- Extend pharmacy_inventory table for multi-currency support
-- Note: These columns may already exist from previous partial execution
-- ALTER TABLE pharmacy_inventory ADD COLUMN currency_code VARCHAR(5) DEFAULT 'UGX';
-- ALTER TABLE pharmacy_inventory ADD COLUMN base_price_ugx DOUBLE PRECISION;
-- ALTER TABLE pharmacy_inventory ADD COLUMN auto_convert_pricing BOOLEAN DEFAULT TRUE;

-- Update existing pharmacy_inventory rows to set base_price_ugx = price
UPDATE pharmacy_inventory SET base_price_ugx = price WHERE base_price_ugx IS NULL;

-- Extend medical_services table (Module 6) for multi-currency support
-- ALTER TABLE medical_services ADD COLUMN currency_code VARCHAR(5) DEFAULT 'UGX';
-- ALTER TABLE medical_services ADD COLUMN base_price_ugx DOUBLE PRECISION;
-- ALTER TABLE medical_services ADD COLUMN auto_convert_pricing BOOLEAN DEFAULT TRUE;

-- Update existing medical_services rows to set base_price_ugx from existing price field
-- (Skipping for now - medical_services schema needs to be checked first)

-- reward_catalog already has multi-currency fields (reward_value_ugx, reward_value_kes, reward_value_tzs)
-- But these are limited to 3 currencies. Extend using product_multi_currency_pricing table.
-- No ALTER needed for reward_catalog - use product_multi_currency_pricing for additional currencies

-- Seed multi-currency pricing for existing products (auto-conversion from UGX base)
-- This will be done via backend cron job, but create a few examples:

-- Example: Seed multi-currency pricing for pharmacy products
-- (In production, this will be auto-generated for all products)
INSERT INTO product_multi_currency_pricing (product_type, product_id, currency_code, price, is_manual, base_price_ugx, auto_convert)
SELECT
  'pharmacy_inventory' AS product_type,
  id AS product_id,
  'KES' AS currency_code,
  ROUND(price * 0.029, 2) AS price, -- Convert UGX to KES
  FALSE AS is_manual,
  price AS base_price_ugx,
  TRUE AS auto_convert
FROM pharmacy_inventory
WHERE price IS NOT NULL
LIMIT 10; -- Sample only, backend will populate all

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_multi_currency_product ON product_multi_currency_pricing(product_type, product_id);
CREATE INDEX IF NOT EXISTS idx_multi_currency_currency ON product_multi_currency_pricing(currency_code);
CREATE INDEX IF NOT EXISTS idx_multi_currency_active ON product_multi_currency_pricing(is_active);
CREATE INDEX IF NOT EXISTS idx_multi_currency_manual ON product_multi_currency_pricing(is_manual);
CREATE INDEX IF NOT EXISTS idx_multi_currency_effective ON product_multi_currency_pricing(effective_date);

CREATE INDEX IF NOT EXISTS idx_pharmacy_inventory_currency ON pharmacy_inventory(currency_code);
CREATE INDEX IF NOT EXISTS idx_facility_services_currency ON facility_services(currency_code);

-- Create view for unified product pricing across all currencies
CREATE VIEW IF NOT EXISTS v_product_pricing_all_currencies AS
-- Pharmacy inventory
SELECT
  'pharmacy_inventory' AS product_type,
  pi.id AS product_id,
  pi.medication_id,
  m.generic_name AS product_name,
  pmcp.currency_code,
  pmcp.price,
  pmcp.is_manual,
  pmcp.base_price_ugx,
  pi.pharmacy_id,
  pl.pharmacy_name,
  pl.address AS pharmacy_location
FROM pharmacy_inventory pi
JOIN product_multi_currency_pricing pmcp ON pi.id = pmcp.product_id AND pmcp.product_type = 'pharmacy_inventory'
JOIN medications m ON pi.medication_id = m.id
JOIN pharmacy_locations pl ON pi.pharmacy_id = pl.id
WHERE pmcp.is_active = TRUE

UNION ALL

-- Facility services
SELECT
  'facility_services' AS product_type,
  fs.id AS product_id,
  NULL AS medication_id,
  fs.service_name AS product_name,
  pmcp.currency_code,
  pmcp.price,
  pmcp.is_manual,
  pmcp.base_price_ugx,
  fs.facility_id AS pharmacy_id,
  pf.facility_name AS pharmacy_name,
  pf.address AS pharmacy_location
FROM facility_services fs
JOIN product_multi_currency_pricing pmcp ON fs.id = pmcp.product_id AND pmcp.product_type = 'facility_services'
JOIN partner_facilities pf ON fs.facility_id = pf.id
WHERE pmcp.is_active = TRUE

UNION ALL

-- Reward catalog
SELECT
  'reward_catalog' AS product_type,
  rc.id AS product_id,
  NULL AS medication_id,
  rc.reward_name AS product_name,
  pmcp.currency_code,
  pmcp.price,
  pmcp.is_manual,
  pmcp.base_price_ugx,
  NULL AS pharmacy_id,
  'Vurafya Rewards' AS pharmacy_name,
  'Platform-wide' AS pharmacy_location
FROM reward_catalog rc
JOIN product_multi_currency_pricing pmcp ON rc.id = pmcp.product_id AND pmcp.product_type = 'reward_catalog'
WHERE pmcp.is_active = TRUE;

-- Trigger: Auto-populate product_multi_currency_pricing when new product added
CREATE TRIGGER IF NOT EXISTS trg_auto_create_multi_currency_pharmacy
AFTER INSERT ON pharmacy_inventory
FOR EACH ROW
WHEN NEW.price IS NOT NULL
BEGIN
  -- Insert UGX pricing (base)
  INSERT INTO product_multi_currency_pricing (product_type, product_id, currency_code, price, is_manual, base_price_ugx, auto_convert)
  VALUES ('pharmacy_inventory', NEW.id, 'UGX', NEW.price, FALSE, NEW.price, TRUE);

  -- Insert KES pricing (auto-converted)
  INSERT INTO product_multi_currency_pricing (product_type, product_id, currency_code, price, is_manual, base_price_ugx, auto_convert)
  VALUES ('pharmacy_inventory', NEW.id, 'KES', ROUND(NEW.price * 0.029, 2), FALSE, NEW.price, TRUE);

  -- Insert TZS pricing (auto-converted)
  INSERT INTO product_multi_currency_pricing (product_type, product_id, currency_code, price, is_manual, base_price_ugx, auto_convert)
  VALUES ('pharmacy_inventory', NEW.id, 'TZS', ROUND(NEW.price * 0.66, 2), FALSE, NEW.price, TRUE);

  -- Insert NGN pricing (auto-converted)
  INSERT INTO product_multi_currency_pricing (product_type, product_id, currency_code, price, is_manual, base_price_ugx, auto_convert)
  VALUES ('pharmacy_inventory', NEW.id, 'NGN', ROUND(NEW.price * 0.22, 2), FALSE, NEW.price, TRUE);

  -- Additional currencies will be populated by backend cron job
END;

-- Trigger: Auto-populate multi-currency pricing for facility services
CREATE TRIGGER IF NOT EXISTS trg_auto_create_multi_currency_services
AFTER INSERT ON facility_services
FOR EACH ROW
WHEN NEW.price_ugx IS NOT NULL
BEGIN
  INSERT INTO product_multi_currency_pricing (product_type, product_id, currency_code, price, is_manual, base_price_ugx, auto_convert)
  VALUES ('facility_services', NEW.id, 'UGX', NEW.price_ugx, FALSE, NEW.price_ugx, TRUE);

  INSERT INTO product_multi_currency_pricing (product_type, product_id, currency_code, price, is_manual, base_price_ugx, auto_convert)
  VALUES ('facility_services', NEW.id, 'KES', ROUND(NEW.price_ugx * 0.029, 2), FALSE, NEW.price_ugx, TRUE);
END;

-- Function to get product price in any currency (via view)
-- Usage: SELECT * FROM v_product_pricing_all_currencies WHERE product_id = 123 AND currency_code = 'NGN'
