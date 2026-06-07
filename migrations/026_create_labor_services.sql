-- Migration 026: Create Labor Services Registry
-- Date: 2026-04-11
-- Purpose: Labor-as-Currency - Users offer ongoing work hours for healthcare payment

-- Labor Services Registry (User skill profiles for time banking)
CREATE TABLE IF NOT EXISTS labor_services_registry (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL, -- Who's offering labor
  service_type VARCHAR(60) NOT NULL, -- Skill category
  service_name VARCHAR(200) NOT NULL, -- E.g., "General Construction Work", "Farm Labor", "Data Entry"
  service_description TEXT,

  -- Proficiency & Experience
  proficiency_level VARCHAR(40) DEFAULT 'intermediate', -- beginner / intermediate / expert
  years_experience INTEGER,
  certifications TEXT, -- JSON array: ["Licensed Electrician", "Certified Welder"]
  portfolio_images TEXT, -- JSON array of work photos

  -- Labor Rates
  hourly_rate_afya_points INTEGER NOT NULL, -- Base rate in Afya Points (100 AP/hour = 10,000 UGX/hour)
  hourly_rate_ugx REAL, -- Converted to UGX for display
  min_hours INTEGER DEFAULT 1, -- Minimum booking (e.g., 4 hours minimum)
  max_hours_per_week INTEGER DEFAULT 40,
  rate_negotiable BOOLEAN DEFAULT TRUE,

  -- Availability
  is_available BOOLEAN DEFAULT TRUE,
  availability_schedule TEXT, -- JSON: {"mon": ["9am-5pm"], "tue": ["9am-5pm"], "weekend": false}
  advance_notice_days INTEGER DEFAULT 1, -- How many days notice needed

  -- Location
  location_district VARCHAR(100),
  location_gps_lat REAL,
  location_gps_lng REAL,
  can_travel BOOLEAN DEFAULT TRUE,
  travel_radius_km INTEGER DEFAULT 20,

  -- Performance Metrics
  rating_avg REAL DEFAULT 0,
  rating_count INTEGER DEFAULT 0,
  hours_completed INTEGER DEFAULT 0, -- Total hours worked
  jobs_completed INTEGER DEFAULT 0,
  reliability_score REAL DEFAULT 0.5, -- 0.0-1.0 (shows up on time, completes work)
  no_show_count INTEGER DEFAULT 0,

  -- Verification
  is_verified_provider BOOLEAN DEFAULT FALSE,
  verified_by INTEGER, -- Staff ID
  verified_at TIMESTAMP,
  background_check_status VARCHAR(40), -- not_started / pending / passed / failed
  background_check_date DATE,

  -- Preferences
  preferred_payment_method VARCHAR(40) DEFAULT 'afya_points', -- afya_points / fiat_currency / barter_credit
  accepts_barter BOOLEAN DEFAULT TRUE,
  seeking_categories TEXT, -- JSON: ["pharmacy", "lab_tests", "consultations"]

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verified_by) REFERENCES medical_staff(id) ON DELETE SET NULL
);

-- Labor Skill Categories (Predefined for consistency)
CREATE TABLE IF NOT EXISTS labor_skill_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_name VARCHAR(60) NOT NULL UNIQUE,
  base_hourly_rate_ap INTEGER NOT NULL, -- Base rate in Afya Points
  base_hourly_rate_ugx REAL NOT NULL, -- Base rate in UGX
  demand_level VARCHAR(40) DEFAULT 'medium', -- low / medium / high / very_high
  demand_multiplier REAL DEFAULT 1.0, -- Surge pricing for high-demand skills
  description TEXT,
  required_certification BOOLEAN DEFAULT FALSE,
  physical_intensity VARCHAR(40), -- low / medium / high / very_high
  skill_tier INTEGER DEFAULT 2, -- 1 = basic, 2 = intermediate, 3 = advanced, 4 = expert
  is_active BOOLEAN DEFAULT TRUE
);

-- Seed labor skill categories (15+ categories as per plan)
INSERT OR IGNORE INTO labor_skill_categories (category_name, base_hourly_rate_ap, base_hourly_rate_ugx, demand_level, demand_multiplier, description, required_certification, physical_intensity, skill_tier) VALUES
-- Tier 1: Basic Skills (80-100 AP/hour)
('General Labor', 80, 8000, 'high', 1.0, 'Loading, unloading, digging, moving items', FALSE, 'very_high', 1),
('Cleaning & Janitorial', 85, 8500, 'high', 1.0, 'House cleaning, office cleaning, deep cleaning', FALSE, 'high', 1),
('Gardening & Landscaping', 90, 9000, 'medium', 1.0, 'Lawn mowing, weeding, planting, basic landscaping', FALSE, 'high', 1),
('Farm Labor', 90, 9000, 'high', 1.1, 'Crop planting, harvesting, livestock care, irrigation', FALSE, 'very_high', 1),

-- Tier 2: Intermediate Skills (100-150 AP/hour)
('Childcare', 100, 10000, 'very_high', 1.3, 'Babysitting, child supervision, homework help', FALSE, 'medium', 2),
('Elderly Care', 110, 11000, 'very_high', 1.4, 'Elderly supervision, medication reminders, companionship', FALSE, 'medium', 2),
('Cooking & Catering', 110, 11000, 'high', 1.2, 'Meal preparation, event catering, baking', FALSE, 'medium', 2),
('Transport & Delivery', 100, 10000, 'high', 1.1, 'Package delivery, goods transport, ride services', FALSE, 'low', 2),
('Security & Guarding', 105, 10500, 'high', 1.2, 'Property security, night guard, watchman', FALSE, 'low', 2),
('Tailoring & Sewing', 115, 11500, 'medium', 1.0, 'Clothing alterations, dress making, repairs', FALSE, 'low', 2),
('Hairdressing & Beauty', 120, 12000, 'medium', 1.0, 'Haircuts, styling, braiding, basic beauty services', FALSE, 'low', 2),

-- Tier 3: Advanced Skills (150-200 AP/hour)
('Teaching & Tutoring', 150, 15000, 'high', 1.2, 'Academic tutoring, exam prep, private lessons', FALSE, 'low', 3),
('Carpentry & Woodwork', 160, 16000, 'medium', 1.1, 'Furniture making, door/window installation, repairs', FALSE, 'high', 3),
('Painting & Decoration', 140, 14000, 'medium', 1.0, 'House painting, wall decoration, artistic work', FALSE, 'medium', 3),
('Welding & Metalwork', 170, 17000, 'medium', 1.2, 'Metal welding, gate fabrication, steel work', TRUE, 'high', 3),
('Auto Repair & Mechanics', 180, 18000, 'high', 1.3, 'Vehicle repair, maintenance, diagnostics', TRUE, 'medium', 3),

-- Tier 4: Expert Skills (200-250 AP/hour)
('Construction & Building', 200, 20000, 'very_high', 1.4, 'Masonry, foundation work, structural building', TRUE, 'very_high', 4),
('Plumbing', 200, 20000, 'very_high', 1.5, 'Pipe installation, leak repairs, sanitation systems', TRUE, 'medium', 4),
('Electrical Work', 220, 22000, 'very_high', 1.6, 'Wiring, electrical installations, troubleshooting', TRUE, 'medium', 4),
('IT & Technology', 250, 25000, 'very_high', 1.7, 'Coding, website building, data entry, tech support', FALSE, 'low', 4);

-- Labor Booking Requests (Users request labor services)
CREATE TABLE IF NOT EXISTS labor_booking_requests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  requester_user_id INTEGER NOT NULL, -- Who needs the labor
  labor_service_id INTEGER NOT NULL, -- Which labor service they're booking
  provider_user_id INTEGER NOT NULL, -- Who's providing the labor

  -- Booking Details
  hours_requested REAL NOT NULL,
  hourly_rate_ap INTEGER NOT NULL, -- Locked-in rate
  total_cost_ap INTEGER NOT NULL,
  booking_date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  work_location_address TEXT,
  work_location_gps_lat REAL,
  work_location_gps_lng REAL,
  work_description TEXT,

  -- Payment Method
  payment_method VARCHAR(40), -- afya_points / fiat_currency / hybrid / barter_exchange
  payment_breakdown TEXT, -- JSON: {"afya_points": 500, "fiat_ugx": 50000}

  -- Status
  status VARCHAR(40) DEFAULT 'pending', -- pending / accepted / confirmed / in_progress / completed / cancelled / disputed
  requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  accepted_at TIMESTAMP,
  confirmed_at TIMESTAMP, -- Both parties confirm details
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  cancelled_at TIMESTAMP,
  cancellation_reason TEXT,

  -- Verification (Work completion proof)
  verification_required BOOLEAN DEFAULT TRUE,
  verified_by INTEGER, -- Staff ID or requester_user_id (peer verification)
  verification_method VARCHAR(40), -- facility_staff / requester_confirmation / gps_checkin / photo_proof
  verification_photos TEXT, -- JSON array of before/after photos
  verified_at TIMESTAMP,

  -- Ratings (After completion)
  requester_rating INTEGER, -- Requester rates provider (1-5 stars)
  requester_review TEXT,
  provider_rating INTEGER, -- Provider rates requester (were they respectful, clear instructions?)
  provider_review TEXT,

  -- Platform Revenue
  transaction_fee_pct REAL DEFAULT 5.0, -- 5% fee on labor transactions
  transaction_fee_ap INTEGER,
  platform_revenue_ugx REAL,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (requester_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (labor_service_id) REFERENCES labor_services_registry(id) ON DELETE CASCADE,
  FOREIGN KEY (provider_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_labor_services_user ON labor_services_registry(user_id);
CREATE INDEX IF NOT EXISTS idx_labor_services_type ON labor_services_registry(service_type);
CREATE INDEX IF NOT EXISTS idx_labor_services_available ON labor_services_registry(is_available);
CREATE INDEX IF NOT EXISTS idx_labor_services_location ON labor_services_registry(location_district);
CREATE INDEX IF NOT EXISTS idx_labor_services_rating ON labor_services_registry(rating_avg);
CREATE INDEX IF NOT EXISTS idx_labor_services_verified ON labor_services_registry(is_verified_provider);

CREATE INDEX IF NOT EXISTS idx_labor_bookings_requester ON labor_booking_requests(requester_user_id);
CREATE INDEX IF NOT EXISTS idx_labor_bookings_provider ON labor_booking_requests(provider_user_id);
CREATE INDEX IF NOT EXISTS idx_labor_bookings_service ON labor_booking_requests(labor_service_id);
CREATE INDEX IF NOT EXISTS idx_labor_bookings_status ON labor_booking_requests(status);
CREATE INDEX IF NOT EXISTS idx_labor_bookings_date ON labor_booking_requests(booking_date);

-- Trigger: Auto-calculate labor cost when booking created
CREATE TRIGGER IF NOT EXISTS trg_auto_calc_labor_cost
AFTER INSERT ON labor_booking_requests
FOR EACH ROW
WHEN NEW.total_cost_ap IS NULL
BEGIN
  UPDATE labor_booking_requests
  SET total_cost_ap = CAST(NEW.hours_requested * NEW.hourly_rate_ap AS INTEGER)
  WHERE id = NEW.id;
END;

-- Trigger: Auto-calculate transaction fee when booking accepted
CREATE TRIGGER IF NOT EXISTS trg_calc_labor_transaction_fee
AFTER UPDATE OF status ON labor_booking_requests
FOR EACH ROW
WHEN NEW.status = 'accepted' AND OLD.status = 'pending'
BEGIN
  UPDATE labor_booking_requests
  SET
    transaction_fee_ap = CAST(NEW.total_cost_ap * NEW.transaction_fee_pct / 100 AS INTEGER),
    platform_revenue_ugx = (NEW.total_cost_ap * NEW.transaction_fee_pct / 100) * 100
  WHERE id = NEW.id;
END;

-- Trigger: Update provider metrics when job completed
CREATE TRIGGER IF NOT EXISTS trg_update_labor_metrics
AFTER UPDATE OF status ON labor_booking_requests
FOR EACH ROW
WHEN NEW.status = 'completed' AND OLD.status = 'in_progress'
BEGIN
  UPDATE labor_services_registry
  SET
    hours_completed = hours_completed + NEW.hours_requested,
    jobs_completed = jobs_completed + 1,
    rating_count = rating_count + 1,
    rating_avg = ((rating_avg * rating_count) + COALESCE(NEW.requester_rating, rating_avg)) / (rating_count + 1)
  WHERE id = NEW.labor_service_id;
END;

-- Trigger: Update timestamp
CREATE TRIGGER IF NOT EXISTS trg_update_labor_services_timestamp
AFTER UPDATE ON labor_services_registry
FOR EACH ROW
BEGIN
  UPDATE labor_services_registry SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS trg_update_labor_booking_timestamp
AFTER UPDATE ON labor_booking_requests
FOR EACH ROW
BEGIN
  UPDATE labor_booking_requests SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
