-- Migration 023: Create Barter Catalogs
-- Date: 2026-04-11
-- Purpose: User-generated goods and services for barter exchange

-- Barter Goods Catalog (Physical items for trade)
CREATE TABLE IF NOT EXISTS barter_goods_catalog (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL, -- Who's offering the good
  item_name VARCHAR(200) NOT NULL,
  item_category VARCHAR(60), -- Food, Clothing, Electronics, Household, Farm Produce, Crafts, Tools, Building Materials, Livestock, Furniture, Books
  item_description TEXT,
  condition VARCHAR(40), -- New, Like New, Good, Fair, Poor
  estimated_value_ugx DOUBLE PRECISION, -- User's own estimate
  afya_points_equivalent INTEGER, -- Platform valuation (auto-calculated or manually set)
  quantity INTEGER DEFAULT 1,
  unit VARCHAR(40), -- Piece, Kg, Liters, Bags, Bundles, Boxes, etc.

  -- Location
  location_district VARCHAR(100),
  location_gps_lat DOUBLE PRECISION,
  location_gps_lng DOUBLE PRECISION,
  delivery_available BOOLEAN DEFAULT FALSE,
  delivery_radius_km INTEGER, -- How far willing to deliver

  -- Media
  photos TEXT, -- JSON array of photo URLs: ["url1.jpg", "url2.jpg"]

  -- Verification
  is_available BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT FALSE, -- Facility staff verified this exists
  verified_by INTEGER, -- Staff ID who verified
  verified_at TIMESTAMP,
  verification_method VARCHAR(40), -- facility_staff / photo_proof / peer_verification

  -- Expiry (for perishables)
  expires_at DATE, -- Listing expiry (e.g., farm produce spoils)
  perishable BOOLEAN DEFAULT FALSE,

  -- Trading preferences
  seeking_items TEXT, -- JSON array: ["Medication", "Lab Test", "Consultation"]
  seeking_categories TEXT, -- JSON array: ["pharmacy", "medical_services"]
  open_to_offers BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verified_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- Barter Services Catalog (One-time services for trade, NOT ongoing labor)
CREATE TABLE IF NOT EXISTS barter_services_catalog (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL, -- Who's offering the service
  service_name VARCHAR(200) NOT NULL,
  service_category VARCHAR(60), -- Repair, Transport, Tutoring, Photography, Hairdressing, Catering, Tailoring, IT Services, Plumbing, Electrical, Carpentry, Painting, Event Planning
  service_description TEXT,

  -- Valuation
  estimated_value_ugx DOUBLE PRECISION,
  afya_points_equivalent INTEGER,
  duration_hours DOUBLE PRECISION, -- How long the service takes

  -- Location
  location_district VARCHAR(100),
  location_gps_lat DOUBLE PRECISION,
  location_gps_lng DOUBLE PRECISION,
  can_travel BOOLEAN DEFAULT FALSE, -- Can travel to client location
  travel_radius_km INTEGER,

  -- Portfolio
  portfolio_images TEXT, -- JSON array of past work photos
  certifications TEXT, -- JSON array: ["Certified Electrician", "Licensed Plumber"]

  -- Ratings
  rating_avg DOUBLE PRECISION DEFAULT 0, -- Average rating from past exchanges
  rating_count INTEGER DEFAULT 0,
  completed_services INTEGER DEFAULT 0,

  -- Availability
  is_available BOOLEAN DEFAULT TRUE,
  availability_schedule TEXT, -- JSON: {"mon": ["9am-5pm"], "tue": ["9am-5pm"], "weekend": false}

  -- Trading preferences
  seeking_items TEXT, -- JSON array: What they want in exchange
  seeking_categories TEXT,
  open_to_offers BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Barter Item Categories (Predefined for consistency)
CREATE TABLE IF NOT EXISTS barter_item_categories (
  id SERIAL PRIMARY KEY,
  category_name VARCHAR(60) NOT NULL UNIQUE,
  category_type VARCHAR(40), -- goods / services
  parent_category_id INTEGER, -- For hierarchical categories
  icon_ref VARCHAR(100), -- Icon for UI
  is_active BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (parent_category_id) REFERENCES barter_item_categories(id) ON DELETE SET NULL
);

-- Seed barter categories
INSERT INTO barter_item_categories (category_name, category_type) VALUES
-- Goods
('Food & Groceries', 'goods'),
('Farm Produce', 'goods'),
('Livestock & Poultry', 'goods'),
('Clothing & Textiles', 'goods'),
('Electronics', 'goods'),
('Household Items', 'goods'),
('Tools & Equipment', 'goods'),
('Building Materials', 'goods'),
('Crafts & Handmade', 'goods'),
('Furniture', 'goods'),
('Books & Media', 'goods'),
('Jewelry & Accessories', 'goods'),

-- Services
('Repair Services', 'services'),
('Transport & Delivery', 'services'),
('Tutoring & Education', 'services'),
('Photography & Videography', 'services'),
('Hairdressing & Beauty', 'services'),
('Catering & Cooking', 'services'),
('Tailoring & Sewing', 'services'),
('IT & Tech Support', 'services'),
('Plumbing', 'services'),
('Electrical Work', 'services'),
('Carpentry & Woodwork', 'services'),
('Painting & Decoration', 'services'),
('Event Planning', 'services'),
('Gardening & Landscaping', 'services');

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_barter_goods_user ON barter_goods_catalog(user_id);
CREATE INDEX IF NOT EXISTS idx_barter_goods_category ON barter_goods_catalog(item_category);
CREATE INDEX IF NOT EXISTS idx_barter_goods_available ON barter_goods_catalog(is_available);
CREATE INDEX IF NOT EXISTS idx_barter_goods_location ON barter_goods_catalog(location_district);
CREATE INDEX IF NOT EXISTS idx_barter_goods_verified ON barter_goods_catalog(is_verified);
CREATE INDEX IF NOT EXISTS idx_barter_goods_expires ON barter_goods_catalog(expires_at);
CREATE INDEX IF NOT EXISTS idx_barter_goods_created ON barter_goods_catalog(created_at);

CREATE INDEX IF NOT EXISTS idx_barter_services_user ON barter_services_catalog(user_id);
CREATE INDEX IF NOT EXISTS idx_barter_services_category ON barter_services_catalog(service_category);
CREATE INDEX IF NOT EXISTS idx_barter_services_available ON barter_services_catalog(is_available);
CREATE INDEX IF NOT EXISTS idx_barter_services_location ON barter_services_catalog(location_district);
CREATE INDEX IF NOT EXISTS idx_barter_services_rating ON barter_services_catalog(rating_avg);
CREATE INDEX IF NOT EXISTS idx_barter_services_created ON barter_services_catalog(created_at);

-- Trigger: Auto-calculate afya_points_equivalent when user sets estimated_value_ugx
CREATE TRIGGER IF NOT EXISTS trg_auto_calc_barter_goods_points
AFTER INSERT ON barter_goods_catalog
FOR EACH ROW
WHEN NEW.estimated_value_ugx IS NOT NULL AND NEW.afya_points_equivalent IS NULL
BEGIN
  UPDATE barter_goods_catalog
  SET afya_points_equivalent = CAST(NEW.estimated_value_ugx / 100 AS INTEGER)
  WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS trg_auto_calc_barter_services_points
AFTER INSERT ON barter_services_catalog
FOR EACH ROW
WHEN NEW.estimated_value_ugx IS NOT NULL AND NEW.afya_points_equivalent IS NULL
BEGIN
  UPDATE barter_services_catalog
  SET afya_points_equivalent = CAST(NEW.estimated_value_ugx / 100 AS INTEGER)
  WHERE id = NEW.id;
END;

-- Trigger: Update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS trg_update_barter_goods_timestamp
AFTER UPDATE ON barter_goods_catalog
FOR EACH ROW
BEGIN
  UPDATE barter_goods_catalog SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS trg_update_barter_services_timestamp
AFTER UPDATE ON barter_services_catalog
FOR EACH ROW
BEGIN
  UPDATE barter_services_catalog SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
