-- Migration 022b: Enable Multi-Currency Product Pricing (Simplified)
-- Date: 2026-04-11
-- Purpose: Allow all products to be priced in ANY of 54+ currencies

-- Multi-Currency Product Pricing Table (Generic for ALL products)
CREATE TABLE IF NOT EXISTS product_multi_currency_pricing (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_type VARCHAR(40) NOT NULL, -- pharmacy_inventory / medical_services / reward_catalog
  product_id INTEGER NOT NULL, -- ID from respective table
  currency_code VARCHAR(5) NOT NULL, -- UGX / KES / NGN / ZAR / etc.
  price REAL NOT NULL,
  is_manual BOOLEAN DEFAULT FALSE, -- TRUE if manually set, FALSE if auto-converted from base
  base_price_ugx REAL, -- Original price in UGX (for auto-conversion reference)
  auto_convert BOOLEAN DEFAULT TRUE, -- Auto-update when exchange rates change
  effective_date DATE DEFAULT CURRENT_DATE,
  expires_at DATE, -- For promotional pricing
  is_active BOOLEAN DEFAULT TRUE,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (currency_code) REFERENCES countries_supported(country_code),
  UNIQUE (product_type, product_id, currency_code)
);

-- Update existing pharmacy_inventory rows to set base_price_ugx = price
UPDATE pharmacy_inventory SET base_price_ugx = price WHERE base_price_ugx IS NULL;

-- Seed multi-currency pricing for pharmacy products (sample)
INSERT OR IGNORE INTO product_multi_currency_pricing (product_type, product_id, currency_code, price, is_manual, base_price_ugx, auto_convert)
SELECT
  'pharmacy_inventory' AS product_type,
  id AS product_id,
  'KES' AS currency_code,
  ROUND(price * 0.029, 2) AS price,
  FALSE AS is_manual,
  price AS base_price_ugx,
  TRUE AS auto_convert
FROM pharmacy_inventory
WHERE price IS NOT NULL
LIMIT 10;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_multi_currency_product ON product_multi_currency_pricing(product_type, product_id);
CREATE INDEX IF NOT EXISTS idx_multi_currency_currency ON product_multi_currency_pricing(currency_code);
CREATE INDEX IF NOT EXISTS idx_multi_currency_active ON product_multi_currency_pricing(is_active);
CREATE INDEX IF NOT EXISTS idx_pharmacy_inventory_currency ON pharmacy_inventory(currency_code);

-- Trigger: Auto-populate product_multi_currency_pricing when new pharmacy product added
CREATE TRIGGER IF NOT EXISTS trg_auto_create_multi_currency_pharmacy
AFTER INSERT ON pharmacy_inventory
FOR EACH ROW
WHEN NEW.price IS NOT NULL
BEGIN
  -- Insert UGX pricing (base)
  INSERT OR IGNORE INTO product_multi_currency_pricing (product_type, product_id, currency_code, price, is_manual, base_price_ugx, auto_convert)
  VALUES ('pharmacy_inventory', NEW.id, 'UGX', NEW.price, FALSE, NEW.price, TRUE);

  -- Insert KES pricing (auto-converted)
  INSERT OR IGNORE INTO product_multi_currency_pricing (product_type, product_id, currency_code, price, is_manual, base_price_ugx, auto_convert)
  VALUES ('pharmacy_inventory', NEW.id, 'KES', ROUND(NEW.price * 0.029, 2), FALSE, NEW.price, TRUE);

  -- Insert TZS pricing (auto-converted)
  INSERT OR IGNORE INTO product_multi_currency_pricing (product_type, product_id, currency_code, price, is_manual, base_price_ugx, auto_convert)
  VALUES ('pharmacy_inventory', NEW.id, 'TZS', ROUND(NEW.price * 0.66, 2), FALSE, NEW.price, TRUE);

  -- Insert NGN pricing (auto-converted)
  INSERT OR IGNORE INTO product_multi_currency_pricing (product_type, product_id, currency_code, price, is_manual, base_price_ugx, auto_convert)
  VALUES ('pharmacy_inventory', NEW.id, 'NGN', ROUND(NEW.price * 0.22, 2), FALSE, NEW.price, TRUE);
END;
