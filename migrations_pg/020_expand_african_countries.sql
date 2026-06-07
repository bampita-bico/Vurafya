-- Migration 020: Expand African Countries (7 → 54+)
-- Date: 2026-04-11
-- Purpose: Global Pan-African expansion with multi-currency, barter trade, labor currency support

-- Extend countries_supported table with new columns
ALTER TABLE countries_supported ADD COLUMN region VARCHAR(30); -- North/West/East/Central/Southern Africa
ALTER TABLE countries_supported ADD COLUMN population_millions INTEGER;
ALTER TABLE countries_supported ADD COLUMN mobile_money_code VARCHAR(10); -- M-Pesa, MTN, Orange Money, Airtel
ALTER TABLE countries_supported ADD COLUMN accepts_barter BOOLEAN DEFAULT TRUE;
ALTER TABLE countries_supported ADD COLUMN accepts_labor BOOLEAN DEFAULT TRUE;
ALTER TABLE countries_supported ADD COLUMN inflation_rate_pct DOUBLE PRECISION; -- Annual inflation rate for pricing adjustments
ALTER TABLE countries_supported ADD COLUMN regulatory_body VARCHAR(200); -- Central bank / financial regulator
ALTER TABLE countries_supported ADD COLUMN regulatory_notes TEXT; -- Country-specific payment regulations

-- Update existing 7 East African countries with new fields
UPDATE countries_supported SET region = 'East Africa', mobile_money_code = 'MPESA', population_millions = 47, regulatory_body = 'Bank of Uganda', inflation_rate_pct = 5.2 WHERE country_code = 'UG';
UPDATE countries_supported SET region = 'East Africa', mobile_money_code = 'MPESA', population_millions = 54, regulatory_body = 'Central Bank of Kenya', inflation_rate_pct = 6.8 WHERE country_code = 'KE';
UPDATE countries_supported SET region = 'East Africa', mobile_money_code = 'MPESA', population_millions = 65, regulatory_body = 'Bank of Tanzania', inflation_rate_pct = 4.5 WHERE country_code = 'TZ';
UPDATE countries_supported SET region = 'East Africa', mobile_money_code = 'MTNMM', population_millions = 14, regulatory_body = 'National Bank of Rwanda', inflation_rate_pct = 3.1 WHERE country_code = 'RW';
UPDATE countries_supported SET region = 'East Africa', mobile_money_code = 'ECOCASH', population_millions = 13, regulatory_body = 'Bank of the Republic of Burundi', inflation_rate_pct = 7.3 WHERE country_code = 'BI';
UPDATE countries_supported SET region = 'East Africa', mobile_money_code = 'ZAIN', population_millions = 11, regulatory_body = 'Bank of South Sudan', inflation_rate_pct = 45.0 WHERE country_code = 'SS';
UPDATE countries_supported SET region = 'East Africa', mobile_money_code = 'EVC', population_millions = 18, regulatory_body = 'Central Bank of Somalia', inflation_rate_pct = 6.0 WHERE country_code = 'SO';

-- Insert 47 new African countries (5 regions × 10-15 countries each)

-- NORTH AFRICA (5 countries)
INSERT INTO countries_supported (country_code, country_name, currency_code, currency_symbol, region, language_primary, language_secondary, mobile_money_code, population_millions, accepts_barter, accepts_labor, inflation_rate_pct, regulatory_body) VALUES
('DZ', 'Algeria', 'DZD', 'د.ج', 'North Africa', 'Arabic', 'French', 'MOBILIS', 44, TRUE, TRUE, 4.2, 'Bank of Algeria'),
('EG', 'Egypt', 'EGP', 'E£', 'North Africa', 'Arabic', 'English', 'VODAFONE', 110, TRUE, TRUE, 13.5, 'Central Bank of Egypt'),
('LY', 'Libya', 'LYD', 'ل.د', 'North Africa', 'Arabic', 'Italian', 'ALMADAR', 7, TRUE, TRUE, 2.8, 'Central Bank of Libya'),
('MA', 'Morocco', 'MAD', 'د.م.', 'North Africa', 'Arabic', 'French', 'INWI', 38, TRUE, TRUE, 1.9, 'Bank Al-Maghrib'),
('TN', 'Tunisia', 'TND', 'د.ت', 'North Africa', 'Arabic', 'French', 'ORANGE', 12, TRUE, TRUE, 5.7, 'Central Bank of Tunisia');

-- WEST AFRICA (16 countries)
INSERT INTO countries_supported (country_code, country_name, currency_code, currency_symbol, region, language_primary, language_secondary, mobile_money_code, population_millions, accepts_barter, accepts_labor, inflation_rate_pct, regulatory_body) VALUES
('NG', 'Nigeria', 'NGN', '₦', 'West Africa', 'English', 'Hausa', 'MPESA', 223, TRUE, TRUE, 18.6, 'Central Bank of Nigeria'),
('GH', 'Ghana', 'GHS', '₵', 'West Africa', 'English', 'Akan', 'MTNMM', 34, TRUE, TRUE, 31.7, 'Bank of Ghana'),
('CI', 'Côte d''Ivoire', 'XOF', 'CFA', 'West Africa', 'French', 'Dioula', 'ORANGE', 28, TRUE, TRUE, 2.4, 'BCEAO'),
('SN', 'Senegal', 'XOF', 'CFA', 'West Africa', 'French', 'Wolof', 'ORANGE', 18, TRUE, TRUE, 3.1, 'BCEAO'),
('ML', 'Mali', 'XOF', 'CFA', 'West Africa', 'French', 'Bambara', 'ORANGE', 23, TRUE, TRUE, 3.9, 'BCEAO'),
('BF', 'Burkina Faso', 'XOF', 'CFA', 'West Africa', 'French', 'Moore', 'ORANGE', 23, TRUE, TRUE, 2.7, 'BCEAO'),
('NE', 'Niger', 'XOF', 'CFA', 'West Africa', 'French', 'Hausa', 'AIRTEL', 27, TRUE, TRUE, 4.2, 'BCEAO'),
('TG', 'Togo', 'XOF', 'CFA', 'West Africa', 'French', 'Ewe', 'MOOV', 9, TRUE, TRUE, 4.1, 'BCEAO'),
('BJ', 'Benin', 'XOF', 'CFA', 'West Africa', 'French', 'Fon', 'MTNMM', 14, TRUE, TRUE, 1.7, 'BCEAO'),
('SL', 'Sierra Leone', 'SLL', 'Le', 'West Africa', 'English', 'Krio', 'ORANGE', 9, TRUE, TRUE, 11.2, 'Bank of Sierra Leone'),
('LR', 'Liberia', 'LRD', 'L$', 'West Africa', 'English', 'Liberian', 'LONESTAR', 5, TRUE, TRUE, 7.8, 'Central Bank of Liberia'),
('GM', 'Gambia', 'GMD', 'D', 'West Africa', 'English', 'Mandinka', 'QMONEY', 3, TRUE, TRUE, 11.5, 'Central Bank of the Gambia'),
('GW', 'Guinea-Bissau', 'XOF', 'CFA', 'West Africa', 'Portuguese', 'Crioulo', 'ORANGE', 2, TRUE, TRUE, 2.8, 'BCEAO'),
('GN', 'Guinea', 'GNF', 'FG', 'West Africa', 'French', 'Susu', 'ORANGE', 14, TRUE, TRUE, 9.1, 'Central Bank of Guinea'),
('CV', 'Cape Verde', 'CVE', '$', 'West Africa', 'Portuguese', 'Crioulo', 'UNITEL', 1, TRUE, TRUE, 4.0, 'Bank of Cape Verde'),
('MR', 'Mauritania', 'MRU', 'UM', 'West Africa', 'Arabic', 'French', 'MATTEL', 5, TRUE, TRUE, 3.6, 'Central Bank of Mauritania');

-- CENTRAL AFRICA (8 countries)
INSERT INTO countries_supported (country_code, country_name, currency_code, currency_symbol, region, language_primary, language_secondary, mobile_money_code, population_millions, accepts_barter, accepts_labor, inflation_rate_pct, regulatory_body) VALUES
('CM', 'Cameroon', 'XAF', 'FCFA', 'Central Africa', 'French', 'English', 'ORANGE', 29, TRUE, TRUE, 2.5, 'BEAC'),
('CF', 'Central African Republic', 'XAF', 'FCFA', 'Central Africa', 'French', 'Sango', 'ORANGE', 6, TRUE, TRUE, 4.3, 'BEAC'),
('TD', 'Chad', 'XAF', 'FCFA', 'Central Africa', 'French', 'Arabic', 'AIRTEL', 18, TRUE, TRUE, 3.5, 'BEAC'),
('CG', 'Republic of Congo', 'XAF', 'FCFA', 'Central Africa', 'French', 'Lingala', 'AIRTEL', 6, TRUE, TRUE, 2.2, 'BEAC'),
('CD', 'Democratic Republic of Congo', 'CDF', 'FC', 'Central Africa', 'French', 'Lingala', 'MPESA', 102, TRUE, TRUE, 5.8, 'Central Bank of Congo'),
('GA', 'Gabon', 'XAF', 'FCFA', 'Central Africa', 'French', 'Fang', 'AIRTEL', 2, TRUE, TRUE, 2.0, 'BEAC'),
('GQ', 'Equatorial Guinea', 'XAF', 'FCFA', 'Central Africa', 'Spanish', 'French', 'ORANGE', 2, TRUE, TRUE, 1.3, 'BEAC'),
('ST', 'São Tomé and Príncipe', 'STN', 'Db', 'Central Africa', 'Portuguese', NULL, 'CST', 0.2, TRUE, TRUE, 7.9, 'Central Bank of São Tomé');

-- EAST AFRICA (5 new countries - 7 existing already in DB)
INSERT INTO countries_supported (country_code, country_name, currency_code, currency_symbol, region, language_primary, language_secondary, mobile_money_code, population_millions, accepts_barter, accepts_labor, inflation_rate_pct, regulatory_body) VALUES
('ET', 'Ethiopia', 'ETB', 'Br', 'East Africa', 'Amharic', 'Oromo', 'MPESA', 126, TRUE, TRUE, 33.9, 'National Bank of Ethiopia'),
('ER', 'Eritrea', 'ERN', 'Nfk', 'East Africa', 'Tigrinya', 'Arabic', NULL, 4, TRUE, TRUE, 2.5, 'Bank of Eritrea'),
('DJ', 'Djibouti', 'DJF', 'Fdj', 'East Africa', 'French', 'Arabic', 'D-MONEY', 1, TRUE, TRUE, 1.8, 'Central Bank of Djibouti'),
('SC', 'Seychelles', 'SCR', '₨', 'East Africa', 'English', 'French', NULL, 0.1, TRUE, TRUE, 1.2, 'Central Bank of Seychelles'),
('MU', 'Mauritius', 'MUR', '₨', 'East Africa', 'English', 'French', 'JUICE', 1, TRUE, TRUE, 6.5, 'Bank of Mauritius');

-- SOUTHERN AFRICA (13 countries)
INSERT INTO countries_supported (country_code, country_name, currency_code, currency_symbol, region, language_primary, language_secondary, mobile_money_code, population_millions, accepts_barter, accepts_labor, inflation_rate_pct, regulatory_body) VALUES
('ZA', 'South Africa', 'ZAR', 'R', 'Southern Africa', 'English', 'Zulu', 'VODACOM', 60, TRUE, TRUE, 5.9, 'South African Reserve Bank'),
('ZW', 'Zimbabwe', 'ZWL', 'Z$', 'Southern Africa', 'English', 'Shona', 'ECOCASH', 16, TRUE, TRUE, 193.4, 'Reserve Bank of Zimbabwe'),
('ZM', 'Zambia', 'ZMW', 'ZK', 'Southern Africa', 'English', 'Bemba', 'AIRTEL', 20, TRUE, TRUE, 9.1, 'Bank of Zambia'),
('BW', 'Botswana', 'BWP', 'P', 'Southern Africa', 'English', 'Setswana', 'MASCOM', 3, TRUE, TRUE, 3.0, 'Bank of Botswana'),
('NA', 'Namibia', 'NAD', 'N$', 'Southern Africa', 'English', 'Afrikaans', 'MTNMM', 3, TRUE, TRUE, 6.1, 'Bank of Namibia'),
('LS', 'Lesotho', 'LSL', 'L', 'Southern Africa', 'Sesotho', 'English', 'MPESA', 2, TRUE, TRUE, 6.0, 'Central Bank of Lesotho'),
('SZ', 'Eswatini', 'SZL', 'E', 'Southern Africa', 'Swazi', 'English', 'MTNMM', 1, TRUE, TRUE, 3.7, 'Central Bank of Eswatini'),
('MW', 'Malawi', 'MWK', 'MK', 'Southern Africa', 'English', 'Chichewa', 'AIRTEL', 21, TRUE, TRUE, 20.9, 'Reserve Bank of Malawi'),
('MZ', 'Mozambique', 'MZN', 'MT', 'Southern Africa', 'Portuguese', 'Makhuwa', 'MPESA', 33, TRUE, TRUE, 5.7, 'Bank of Mozambique'),
('AO', 'Angola', 'AOA', 'Kz', 'Southern Africa', 'Portuguese', 'Umbundu', 'UNITEL', 36, TRUE, TRUE, 13.6, 'National Bank of Angola'),
('MG', 'Madagascar', 'MGA', 'Ar', 'Southern Africa', 'Malagasy', 'French', 'ORANGE', 30, TRUE, TRUE, 5.8, 'Central Bank of Madagascar'),
('KM', 'Comoros', 'KMF', 'CF', 'Southern Africa', 'Comorian', 'French', 'TELMA', 1, TRUE, TRUE, 0.5, 'Central Bank of Comoros'),
('RE', 'Réunion', 'EUR', '€', 'Southern Africa', 'French', 'Creole', NULL, 1, TRUE, TRUE, 1.9, 'European Central Bank');

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_countries_region ON countries_supported(region);
CREATE INDEX IF NOT EXISTS idx_countries_accepts_barter ON countries_supported(accepts_barter);
CREATE INDEX IF NOT EXISTS idx_countries_accepts_labor ON countries_supported(accepts_labor);
CREATE INDEX IF NOT EXISTS idx_countries_currency ON countries_supported(currency_code);
CREATE INDEX IF NOT EXISTS idx_countries_mobile_money ON countries_supported(mobile_money_code);
