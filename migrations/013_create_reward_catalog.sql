-- Migration 013: Create Reward Catalog
-- Date: 2026-04-11
-- Purpose: Define Afya Points spending catalog

CREATE TABLE reward_catalog (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  reward_name VARCHAR(120) NOT NULL,
  reward_type VARCHAR(60), -- pharmacy_discount / lab_test_voucher / consultation_credit / cosmetic / premium
  cost_afya_points INTEGER NOT NULL,
  reward_value_ugx REAL,
  reward_value_kes REAL,
  reward_value_tzs REAL,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  stock_count INTEGER, -- NULL = unlimited
  max_per_user INTEGER DEFAULT 10, -- Max redemptions per user
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- PHARMACY DISCOUNTS (Most popular, CKD medication focus)
INSERT OR IGNORE INTO reward_catalog (reward_name, reward_type, cost_afya_points, reward_value_ugx, reward_value_kes, reward_value_tzs, description) VALUES
('UGX 5,000 Pharmacy Discount', 'pharmacy_discount', 500, 5000, 400, 10000, 'Use on any pharmacy order - great for CKD medications'),
('UGX 12,000 Pharmacy Discount', 'pharmacy_discount', 1000, 12000, 1000, 24000, 'Larger discount for expensive medications'),
('UGX 35,000 Pharmacy Discount', 'pharmacy_discount', 2500, 35000, 2800, 70000, 'Maximum discount for comprehensive medication orders');

-- LAB TEST VOUCHERS (CKD-focused)
INSERT OR IGNORE INTO reward_catalog (reward_name, reward_type, cost_afya_points, reward_value_ugx, reward_value_kes, reward_value_tzs, description) VALUES
('Free Basic Blood Test', 'lab_test_voucher', 800, 15000, 1200, 30000, 'CBC + Urinalysis at partner lab'),
('Free Kidney Function Panel', 'lab_test_voucher', 2000, 35000, 2800, 70000, 'Creatinine, eGFR, Urea - CKD monitoring'),
('Free HbA1c Test', 'lab_test_voucher', 1500, 25000, 2000, 50000, 'Diabetes monitoring (3-month glucose average)'),
('Free Lipid Profile', 'lab_test_voucher', 1800, 30000, 2400, 60000, 'Cholesterol panel for cardiovascular health');

-- CONSULTATIONS
INSERT OR IGNORE INTO reward_catalog (reward_name, reward_type, cost_afya_points, reward_value_ugx, reward_value_kes, reward_value_tzs, description) VALUES
('Free 15min Tele-Consultation', 'consultation_credit', 1200, 20000, 1600, 40000, 'General practitioner consultation'),
('Free 30min Specialist Consult', 'consultation_credit', 2500, 50000, 4000, 100000, 'Nephrologist, Endocrinologist, Cardiologist');

-- COSMETICS (Virtual items)
INSERT OR IGNORE INTO reward_catalog (reward_name, reward_type, cost_afya_points, reward_value_ugx, reward_value_kes, reward_value_tzs, description, stock_count) VALUES
('Common Cosmetic', 'cosmetic', 100, NULL, NULL, NULL, 'Unlock common rarity cosmetic of your choice', NULL),
('Uncommon Cosmetic', 'cosmetic', 300, NULL, NULL, NULL, 'Unlock uncommon rarity cosmetic', NULL),
('Rare Cosmetic', 'cosmetic', 800, NULL, NULL, NULL, 'Unlock rare rarity cosmetic', NULL),
('Epic Cosmetic', 'cosmetic', 2000, NULL, NULL, NULL, 'Unlock epic rarity cosmetic', NULL);

-- PREMIUM FEATURES
INSERT OR IGNORE INTO reward_catalog (reward_name, reward_type, cost_afya_points, reward_value_ugx, reward_value_kes, reward_value_tzs, description, max_per_user) VALUES
('1 Week Pro Subscription', 'premium', 1200, 15000, 1200, 30000, 'Access premium skills and features for 7 days', 52),
('1 Month Pro Subscription', 'premium', 5000, 50000, 4000, 100000, 'Full month of Pro features', 12),
('3 Months Pro Subscription', 'premium', 12000, 120000, 10000, 240000, 'Save 20% on Pro subscription', 4);

CREATE INDEX idx_reward_catalog_type ON reward_catalog(reward_type);
CREATE INDEX idx_reward_catalog_active ON reward_catalog(is_active);
CREATE INDEX idx_reward_catalog_points ON reward_catalog(cost_afya_points);
