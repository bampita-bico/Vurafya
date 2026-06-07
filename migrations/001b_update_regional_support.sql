-- Migration 001b: Update Regional Support for 7+ East African Countries
-- Date: 2026-04-11
-- Purpose: Expand from 3 countries (UG, KE, TZ) to 7+ countries

-- Add gamification opt-in column to user_Profiles
ALTER TABLE user_Profiles ADD COLUMN gamification_enabled BOOLEAN DEFAULT FALSE;

-- Create country configuration table (dynamic, not hard-coded)
CREATE TABLE countries_supported (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  country_code VARCHAR(5) NOT NULL UNIQUE, -- UG, KE, TZ, RW, BI, SS, SO, etc.
  country_name VARCHAR(100) NOT NULL,
  currency_code VARCHAR(5) NOT NULL UNIQUE, -- UGX, KES, TZS, RWF, BIF, SSP, etc.
  currency_symbol VARCHAR(10),
  language_primary VARCHAR(50), -- English, Swahili, Kinyarwanda, Kirundi, etc.
  language_secondary VARCHAR(50),
  is_active BOOLEAN DEFAULT TRUE,
  added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed initial 7 countries
INSERT OR IGNORE INTO countries_supported (country_code, country_name, currency_code, currency_symbol, language_primary, language_secondary) VALUES
('UG', 'Uganda', 'UGX', 'USh', 'English', 'Swahili'),
('KE', 'Kenya', 'KES', 'KSh', 'English', 'Swahili'),
('TZ', 'Tanzania', 'TZS', 'TSh', 'Swahili', 'English'),
('RW', 'Rwanda', 'RWF', 'FRw', 'Kinyarwanda', 'English'),
('BI', 'Burundi', 'BIF', 'FBu', 'Kirundi', 'French'),
('SS', 'South Sudan', 'SSP', 'SS£', 'English', 'Arabic'),
('SO', 'Somalia', 'SOS', 'Sh.So.', 'Somali', 'Arabic');

-- Create sub-regional codes table (for seasonal_availability granularity)
CREATE TABLE subregions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  country_code VARCHAR(5) NOT NULL,
  subregion_code VARCHAR(10) NOT NULL UNIQUE, -- UG.N, UG.C, KE.R, etc.
  subregion_name VARCHAR(100),
  FOREIGN KEY (country_code) REFERENCES countries_supported(country_code)
);

-- Seed sub-regions (examples for MVP)
INSERT OR IGNORE INTO subregions (country_code, subregion_code, subregion_name) VALUES
('UG', 'UG.N', 'Northern Uganda'),
('UG', 'UG.C', 'Central Uganda'),
('UG', 'UG.E', 'Eastern Uganda'),
('UG', 'UG.W', 'Western Uganda'),
('KE', 'KE.R', 'Kenyan Rift Valley'),
('KE', 'KE.C', 'Central Kenya'),
('KE', 'KE.Coast', 'Coastal Kenya'),
('TZ', 'TZ.C', 'Coastal Tanzania'),
('TZ', 'TZ.N', 'Northern Tanzania'),
('RW', 'RW.K', 'Kigali Region'),
('BI', 'BI.B', 'Bujumbura Region');

-- Note: Existing tables (foods, pharmacy_locations, etc.) already have region_code columns
-- Future data can use the new country codes (RW, BI, SS, SO)
-- No schema changes needed - just expanded value range

-- Create index on country lookup
CREATE INDEX idx_countries_supported_code ON countries_supported(country_code);
CREATE INDEX idx_subregions_country ON subregions(country_code);
