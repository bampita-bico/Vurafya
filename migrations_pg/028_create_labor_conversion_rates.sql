-- Migration 028: Create Labor Currency Conversion Rates
-- Date: 2026-04-11
-- Purpose: Fair labor rates by skill, proficiency, and country

-- Labor Currency Conversion (Standard rates for fair wage calculation)
CREATE TABLE IF NOT EXISTS labor_currency_conversion (
  id SERIAL PRIMARY KEY,
  skill_category_id INTEGER NOT NULL, -- FK to labor_skill_categories
  country_code VARCHAR(5) NOT NULL, -- UG / KE / NG / ZA / etc.
  proficiency_level VARCHAR(40) NOT NULL, -- beginner / intermediate / expert

  -- Base Rate
  base_hourly_rate_ap INTEGER NOT NULL, -- In Afya Points
  base_hourly_rate_ugx DOUBLE PRECISION NOT NULL, -- In UGX (for display)
  base_hourly_rate_local_currency DOUBLE PRECISION, -- In local currency (NGN, KES, etc.)

  -- Multipliers
  proficiency_multiplier DOUBLE PRECISION NOT NULL, -- beginner: 0.8, intermediate: 1.0, expert: 1.5
  country_cost_of_living_multiplier DOUBLE PRECISION NOT NULL, -- Nigeria: 1.2, Uganda: 1.0, Ethiopia: 0.8
  demand_surge_multiplier DOUBLE PRECISION DEFAULT 1.0, -- High-demand skills: 1.3

  -- Calculated Final Rate
  final_hourly_rate_ap INTEGER, -- base × proficiency × country × demand
  final_hourly_rate_ugx DOUBLE PRECISION,
  final_hourly_rate_local_currency DOUBLE PRECISION,

  -- Minimum Wage Compliance
  meets_minimum_wage BOOLEAN DEFAULT TRUE, -- Meets country's minimum wage?
  minimum_wage_local_currency DOUBLE PRECISION, -- Country's minimum wage per hour

  effective_date DATE DEFAULT CURRENT_DATE,
  expires_at DATE, -- For seasonal adjustments
  is_active BOOLEAN DEFAULT TRUE,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (skill_category_id) REFERENCES labor_skill_categories(id) ON DELETE CASCADE,
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code),
  UNIQUE (skill_category_id, country_code, proficiency_level)
);

-- Country Cost of Living Index (Adjusts labor rates by country)
CREATE TABLE IF NOT EXISTS country_cost_of_living (
  id SERIAL PRIMARY KEY,
  country_code VARCHAR(5) NOT NULL UNIQUE,
  cost_of_living_index DOUBLE PRECISION NOT NULL, -- Base 100 = Uganda, Nigeria 120, Ethiopia 80
  minimum_wage_hourly_local_currency DOUBLE PRECISION, -- Official minimum wage per hour
  minimum_wage_hourly_ugx DOUBLE PRECISION, -- Converted to UGX
  currency_strength_index DOUBLE PRECISION, -- Purchasing power (base 1.0 = UGX)
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code)
);

-- Seed cost of living data for key African countries
INSERT INTO country_cost_of_living (country_code, cost_of_living_index, minimum_wage_hourly_local_currency, minimum_wage_hourly_ugx, currency_strength_index) VALUES
-- East Africa
('UG', 100.0, 1000, 1000, 1.0), -- Uganda baseline
('KE', 115.0, 140, 4830, 0.93), -- Kenya higher cost
('TZ', 85.0, 2000, 3040, 1.12), -- Tanzania lower cost
('RW', 105.0, 240, 672, 0.95), -- Rwanda similar to Uganda
('ET', 75.0, 60, 288, 1.18), -- Ethiopia lowest cost
-- West Africa
('NG', 120.0, 30, 135, 0.88), -- Nigeria highest cost in West Africa
('GH', 110.0, 14, 3136, 0.90), -- Ghana
-- Southern Africa
('ZA', 140.0, 23.19, 4822, 0.75), -- South Africa most expensive
('ZW', 95.0, 0.50, 1.7, 1.05), -- Zimbabwe (hyperinflation)
-- North Africa
('EG', 90.0, 1.5, 8.4, 1.08), -- Egypt lower cost
('MA', 100.0, 14, 385, 1.0); -- Morocco moderate

-- Proficiency Level Definitions
CREATE TABLE IF NOT EXISTS proficiency_level_definitions (
  id SERIAL PRIMARY KEY,
  proficiency_level VARCHAR(40) NOT NULL UNIQUE,
  multiplier DOUBLE PRECISION NOT NULL,
  years_experience_min INTEGER,
  years_experience_max INTEGER,
  description TEXT
);

-- Seed proficiency levels
INSERT INTO proficiency_level_definitions (proficiency_level, multiplier, years_experience_min, years_experience_max, description) VALUES
('beginner', 0.8, 0, 2, 'Entry-level, learning, limited experience'),
('intermediate', 1.0, 2, 5, 'Competent, regular experience, independent work'),
('expert', 1.5, 5, NULL, 'Highly skilled, extensive experience, can train others');

-- Demand Surge Tracking (Adjust rates based on supply/demand)
CREATE TABLE IF NOT EXISTS labor_demand_surge (
  id SERIAL PRIMARY KEY,
  skill_category_id INTEGER NOT NULL,
  country_code VARCHAR(5),
  district VARCHAR(100), -- More granular (e.g., Kampala)
  demand_level VARCHAR(40), -- very_low / low / medium / high / very_high
  surge_multiplier DOUBLE PRECISION NOT NULL, -- 0.8 (low demand) to 1.5 (high demand)
  active_requests INTEGER, -- Number of unfulfilled labor requests
  active_providers INTEGER, -- Number of available providers
  supply_demand_ratio DOUBLE PRECISION, -- active_providers / active_requests
  calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days'), -- Recalculate weekly
  FOREIGN KEY (skill_category_id) REFERENCES labor_skill_categories(id) ON DELETE CASCADE
);

-- Seed labor conversion rates for common skills × countries × proficiency
-- This will be a large dataset, so we seed a few examples and backend populates the rest

-- Example: General Labor in Uganda (3 proficiency levels)
INSERT INTO labor_currency_conversion (skill_category_id, country_code, proficiency_level, base_hourly_rate_ap, base_hourly_rate_ugx, proficiency_multiplier, country_cost_of_living_multiplier, final_hourly_rate_ap, final_hourly_rate_ugx)
SELECT
  lsc.id,
  'UG',
  pld.proficiency_level,
  lsc.base_hourly_rate_ap,
  lsc.base_hourly_rate_ugx,
  pld.multiplier,
  1.0, -- Uganda baseline
  CAST(lsc.base_hourly_rate_ap * pld.multiplier * 1.0 AS INTEGER),
  lsc.base_hourly_rate_ugx * pld.multiplier * 1.0
FROM labor_skill_categories lsc
CROSS JOIN proficiency_level_definitions pld
WHERE lsc.category_name IN ('General Labor', 'Cleaning & Janitorial', 'Farm Labor', 'Construction & Building', 'IT & Technology')
LIMIT 15; -- 5 skills × 3 proficiency levels

-- Example: Same skills in Nigeria (higher cost of living)
INSERT INTO labor_currency_conversion (skill_category_id, country_code, proficiency_level, base_hourly_rate_ap, base_hourly_rate_ugx, proficiency_multiplier, country_cost_of_living_multiplier, final_hourly_rate_ap, final_hourly_rate_ugx)
SELECT
  lsc.id,
  'NG',
  pld.proficiency_level,
  lsc.base_hourly_rate_ap,
  lsc.base_hourly_rate_ugx,
  pld.multiplier,
  1.2, -- Nigeria 20% higher
  CAST(lsc.base_hourly_rate_ap * pld.multiplier * 1.2 AS INTEGER),
  lsc.base_hourly_rate_ugx * pld.multiplier * 1.2
FROM labor_skill_categories lsc
CROSS JOIN proficiency_level_definitions pld
WHERE lsc.category_name IN ('General Labor', 'Cleaning & Janitorial', 'Farm Labor', 'Construction & Building', 'IT & Technology')
LIMIT 15;

-- Example: Same skills in Ethiopia (lower cost of living)
INSERT INTO labor_currency_conversion (skill_category_id, country_code, proficiency_level, base_hourly_rate_ap, base_hourly_rate_ugx, proficiency_multiplier, country_cost_of_living_multiplier, final_hourly_rate_ap, final_hourly_rate_ugx)
SELECT
  lsc.id,
  'ET',
  pld.proficiency_level,
  lsc.base_hourly_rate_ap,
  lsc.base_hourly_rate_ugx,
  pld.multiplier,
  0.8, -- Ethiopia 20% lower
  CAST(lsc.base_hourly_rate_ap * pld.multiplier * 0.8 AS INTEGER),
  lsc.base_hourly_rate_ugx * pld.multiplier * 0.8
FROM labor_skill_categories lsc
CROSS JOIN proficiency_level_definitions pld
WHERE lsc.category_name IN ('General Labor', 'Cleaning & Janitorial', 'Farm Labor', 'Construction & Building', 'IT & Technology')
LIMIT 15;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_labor_conversion_skill ON labor_currency_conversion(skill_category_id);
CREATE INDEX IF NOT EXISTS idx_labor_conversion_country ON labor_currency_conversion(country_code);
CREATE INDEX IF NOT EXISTS idx_labor_conversion_proficiency ON labor_currency_conversion(proficiency_level);
CREATE INDEX IF NOT EXISTS idx_labor_conversion_active ON labor_currency_conversion(is_active);

CREATE INDEX IF NOT EXISTS idx_demand_surge_skill ON labor_demand_surge(skill_category_id);
CREATE INDEX IF NOT EXISTS idx_demand_surge_country ON labor_demand_surge(country_code);
CREATE INDEX IF NOT EXISTS idx_demand_surge_district ON labor_demand_surge(district);
CREATE INDEX IF NOT EXISTS idx_demand_surge_expires ON labor_demand_surge(expires_at);

-- View: Labor Rate Lookup (for easy querying)
CREATE VIEW IF NOT EXISTS v_labor_rates AS
SELECT
  lsc.category_name AS skill_name,
  lsc.skill_tier,
  cs.country_name,
  lcc.country_code,
  lcc.proficiency_level,
  lcc.base_hourly_rate_ap AS base_rate_ap,
  lcc.final_hourly_rate_ap AS final_rate_ap,
  lcc.final_hourly_rate_ugx AS final_rate_ugx,
  lcc.proficiency_multiplier,
  lcc.country_cost_of_living_multiplier,
  lcc.demand_surge_multiplier,
  lcc.meets_minimum_wage,
  lcc.is_active
FROM labor_currency_conversion lcc
JOIN labor_skill_categories lsc ON lcc.skill_category_id = lsc.id
JOIN countries_supported cs ON lcc.country_code = cs.country_code
WHERE lcc.is_active = TRUE;

-- Trigger: Auto-calculate final rate when conversion rate inserted/updated
CREATE TRIGGER IF NOT EXISTS trg_auto_calc_labor_final_rate
AFTER INSERT ON labor_currency_conversion
FOR EACH ROW
WHEN NEW.final_hourly_rate_ap IS NULL
BEGIN
  UPDATE labor_currency_conversion
  SET
    final_hourly_rate_ap = CAST(NEW.base_hourly_rate_ap * NEW.proficiency_multiplier * NEW.country_cost_of_living_multiplier * NEW.demand_surge_multiplier AS INTEGER),
    final_hourly_rate_ugx = NEW.base_hourly_rate_ugx * NEW.proficiency_multiplier * NEW.country_cost_of_living_multiplier * NEW.demand_surge_multiplier
  WHERE id = NEW.id;
END;

-- Trigger: Recalculate final rate when multipliers updated
CREATE TRIGGER IF NOT EXISTS trg_recalc_labor_rate_on_update
AFTER UPDATE OF proficiency_multiplier, country_cost_of_living_multiplier, demand_surge_multiplier ON labor_currency_conversion
FOR EACH ROW
BEGIN
  UPDATE labor_currency_conversion
  SET
    final_hourly_rate_ap = CAST(NEW.base_hourly_rate_ap * NEW.proficiency_multiplier * NEW.country_cost_of_living_multiplier * NEW.demand_surge_multiplier AS INTEGER),
    final_hourly_rate_ugx = NEW.base_hourly_rate_ugx * NEW.proficiency_multiplier * NEW.country_cost_of_living_multiplier * NEW.demand_surge_multiplier,
    last_updated = CURRENT_TIMESTAMP
  WHERE id = NEW.id;
END;

-- Function to get labor rate (example SQL, backend would call this)
/*
USAGE EXAMPLE:
Get hourly rate for expert construction worker in Nigeria:

SELECT final_hourly_rate_ap, final_hourly_rate_ugx
FROM v_labor_rates
WHERE skill_name = 'Construction & Building'
  AND country_code = 'NG'
  AND proficiency_level = 'expert';

Result: 336 AP/hour (200 base × 1.5 proficiency × 1.2 country × 0.93 demand)
*/

-- Stored calculation logic (documented for backend implementation)
/*
LABOR RATE CALCULATION:

Step 1: Get base rate from labor_skill_categories
  - General Labor: 80 AP/hour
  - IT & Technology: 250 AP/hour

Step 2: Apply proficiency multiplier
  - Beginner: ×0.8
  - Intermediate: ×1.0
  - Expert: ×1.5

Step 3: Apply country cost of living multiplier
  - Uganda (baseline): ×1.0
  - Nigeria: ×1.2
  - Ethiopia: ×0.8
  - South Africa: ×1.4

Step 4: Apply demand surge multiplier (optional)
  - Low demand: ×0.8
  - Normal: ×1.0
  - High demand: ×1.3

Step 5: Final calculation
  final_rate = base_rate × proficiency × country × demand

EXAMPLE 1: Beginner General Labor in Uganda
  80 AP × 0.8 × 1.0 × 1.0 = 64 AP/hour (6,400 UGX)

EXAMPLE 2: Expert Construction in Nigeria
  200 AP × 1.5 × 1.2 × 1.0 = 360 AP/hour (36,000 UGX equivalent)

EXAMPLE 3: Intermediate IT in South Africa
  250 AP × 1.0 × 1.4 × 1.3 (high demand) = 455 AP/hour (45,500 UGX equivalent)
*/
