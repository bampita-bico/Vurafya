# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Vurafya** by Vura iX is a health platform powered by the public **CDFD Runtime**. It uses a flow-under-constraint model to summarize operating-state signals from biometrics, labs, nutrition, and app activity.

**Tagline**: *"Runtime-guided health workflows."*

**Infrastructure**:
- **Primary Database**: `AfyaFigo.db` (SQLite) - Clinical records & biometrics.
- **Ontology Layer**: **Neo4j Graph** - Biological system relationships & cross-system influence.
- **Runtime Core**: **CDFD Runtime** - Stability ($\Psi_s$), trajectory projection, and neutral operating-state guidance.

---

## Architecture: 7-Level Integration

1.  **Level 1 (Physics)**: Fundamental $\Phi/C$ dynamics running in the background.
2.  **Level 2 (DSL)**: **CDFL Language** support for custom model rules (`medical_rules.cdfl`).
3.  **Level 3 (Runtime)**: Async background worker (`background_worker.py`) for population-scale modeling.
4.  **Level 4 (Domain)**: `VurafyaAdapter` mapping biometrics to runtime stability signals.
5.  **Level 5 (Discovery)**: Runtime flags emerging model patterns for review.
6.  **Level 6 (Validation)**: Trajectory checks against historical labs and biometrics.
7.  **Level 7 (Platform)**:
    - **Patient Portal (Flutter)**: Gamified health dashboard and System Harmony view.
    - **Doctor Portal (React)**: Stability dashboards and trajectory projections.

---

## Database & Ontology Access

```bash
# List all tables
python3 -c "import sqlite3; conn = sqlite3.connect('AfyaFigo.db'); cursor = conn.cursor(); cursor.execute(\"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;\"); print('\n'.join([t[0] for t in cursor.fetchall()]))"

# Inspect table schema
python3 -c "import sqlite3; conn = sqlite3.connect('AfyaFigo.db'); cursor = conn.cursor(); cursor.execute('PRAGMA table_info(TABLE_NAME)'); [print(f'{col[1]:30} {col[2]:15} {\"PRIMARY KEY\" if col[5] else \"\"}') for col in cursor.fetchall()]"

# Get row counts (non-empty tables only)
python3 << 'EOF'
import sqlite3
conn = sqlite3.connect('AfyaFigo.db')
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
for table in cursor.fetchall():
    cursor.execute(f"SELECT COUNT(*) FROM {table[0]}")
    count = cursor.fetchone()[0]
    if count > 0:
        print(f"{table[0]}: {count}")
conn.close()
EOF

# Execute custom query
python3 -c "import sqlite3; conn = sqlite3.connect('AfyaFigo.db'); cursor = conn.cursor(); cursor.execute('YOUR_QUERY_HERE'); print(cursor.fetchall())"
```

---

## Architecture: 22 Modules

### **Modules 1-6: Nutrition to Medical** (~150 tables)

1. **Nutrition Science** (25 tables) - Foods, nutrients, PRAL, bioactives, anti-nutrients, cooking science
2. **Meal System** (20 tables) - Meals, recipes, meal planning, portion tracking
3. **Beverage System** (15 tables) - Drinks, cocktails, hydration tracking
4. **User System** (15 tables) - Accounts, profiles, preferences, streaks
5. **Biometrics** (15 tables) - BP, glucose, weight, wearables (■ Vuralis data source with consent)
6. **Medical Consulting** (20 tables) - Tele-consultations, prescriptions, referrals

### **Modules 7-12: Pharmacy to AI** (~80 tables)

7. **Pharmacy** (20 tables) - Medications, inventory, adherence, drug interactions (drug-drug, drug-food, drug-beverage)
8. **Facility Partnerships** (10 tables) - Clinics, labs, hospitals, revenue sharing
9. **Lab & Diagnostics** (10 tables) - Test results, imaging, clinical logs
10. **Preventive Medicine** (10 tables) - Health rules, scoring, condition thresholds, nutrient targets
11. **Gamification RPG** (20 tables) - Achievements, badges, avatar stats, competitions, leaderboards
12. **AI Recommendations** (10 tables) - Personalized suggestions

### **Modules 13-17: Social to Infrastructure** (~40 tables)

13. **Social Health** (15 tables) - Friends, chat, community
14. **Commerce** (10 tables) - Orders, transactions
15. **Afya Points** (5 tables) - Loyalty currency
16. **Research** (5 tables) - Analytics, aggregated data
17. **Infrastructure** (10 tables) - Audit logs, notifications, metadata

### **Modules 18-22: Payment System** (~55 tables)
*Revolutionary payment for broke communities: barter + labor + fiat + points*

18. **Multi-Currency** (7 tables) - 54 African countries, 45 currencies (42 fiat + AP + LH + BC)
19. **Barter Trade** (8 tables) - Goods/services exchange (3.5% fee)
20. **Labor-as-Currency** (10 tables) - Time banking (5% fee)
21. **Unified Payments** (12 tables) - Hybrid payments + trust scoring
22. **Revenue & Compliance** (30 tables) - 70% revenue + 30% social good, KYC/AML, fraud detection

**Payment Methods**: Fiat, Afya Points (AP), Labor Hours (LH), Barter Credits (BC)  
**Target**: Month 12: $23K/month (30,000 users, 20 countries)

---

## Key Clinical Formulas

### PRAL (Potential Renal Acid Load) for CKD
```
PRAL = 0.49×Protein(g) + 0.037×P(mg) - 0.021×K(mg) - 0.026×Mg(mg) - 0.013×Ca(mg)
```
- **Negative** = Alkalizing (encourage for CKD)
- **Positive** = Acidifying (limit for CKD)
- **Critical**: Track individual 3Ps (Protein, Potassium, Phosphorus) separately for dialysis patients (rapid fluctuations)

### Nutritional Accounting
```
actual_intake = amount_per_100g × (quantity_grams / 100) × retention_factor
```

### Glycemic Load
```
GL = (GI × available_carb_g) / 100
```
- Low: <10, Medium: 11-19, High: ≥20

---

## Design Patterns

### Naming Conventions
- **Foreign keys**: `{table}_id` (e.g., `user_id`, `food_id`)
- **Junction tables**: `{table_a}_{table_b}` (e.g., `food_nutrients`, `drug_drug_interactions`)
- **User activity**: `user_{action}` (e.g., `user_achievements`, `user_recent_foods`)
- **Search infrastructure**: `{domain}_search_index`, `{domain}_search_tokens`, `{domain}_popularity`

### Standard Columns
- `id INTEGER PRIMARY KEY` - Auto-increment
- `created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP`
- `is_active BOOLEAN` - Soft delete
- `is_verified BOOLEAN` - Data quality flag
- `user_id INTEGER` - For user-specific data

### JSON Columns (TEXT type)
```sql
-- medications.brand_names
["Glucophage", "Metformin SR"]

-- medications.dosage_forms
["tablet", "capsule", "syrup"]

-- medication_schedules.scheduled_times
["07:00", "13:00", "19:00"]

-- Query JSON in SQLite
SELECT json_extract(brand_names, '$[0]') FROM medications;
```

### Multi-Tenancy
1. **Global Reference Data** (no user_id): `foods`, `nutrients`, `medications`, `facilities`
2. **User-Specific Data** (user_id): `meals`, `consultations`, `pharmacy_orders`
3. **User-Generated** (created_by_user): `recipes`, `food_submissions`

---

## Regional Context: Pan-African

**Target**: 54 African countries (Uganda, Kenya, Tanzania, Nigeria, Ghana, South Africa, etc.)  
**Currencies**: 42 fiat + Afya Points (AP) + Labor Hours (LH) + Barter Credits (BC)  
**Languages**: English, Swahili, Hausa, Zulu, Amharic

### Regional Data Fields
- `local_name` - Vernacular names (Matoke, Posho, Jollof)
- `region_code` - UG.N, KE.C, TZ.C (sub-regional)
- `regulatory_body` - NDA Uganda, PPB Kenya, TFDA Tanzania

---

## Important Tables by Use Case

### CKD Management
- `renal_acid_load_data` - PRAL values (301/302 foods with complete 5 components)
- `v_protein_content`, `v_potassium_content`, `v_phosphorus_content` - Individual 3P tracking
- `v_pral_live` - Dynamic PRAL calculation
- `meal_nutrition_calculations` - Meal-level 3P totals (protein_g_total, potassium_mg_total, phosphorus_mg_total)
- `potassium_logs`, `phosphorus_logs`, `creatinine_egfr_logs` - Lab tracking

### Medication Safety
- `medications` - Drug catalog (generic_name, brand_names, drug_class)
- `drug_drug_interactions` - Drug-to-drug (severity: mild/moderate/severe/contraindicated)
- `drug_food_interactions` - Drug-to-food (e.g., Warfarin + leafy greens)
- `drug_beverage_interactions` - Drug-to-beverage (e.g., Alcohol + Metronidazole)
- `medication_schedules` - Dosing times
- `adherence_logs` - Patient compliance

### Nutrition Tracking
- `foods` (302 foods), `nutrients`, `food_nutrients` (3,924 records, 100% coverage)
- `meals`, `meal_components`, `meal_nutrition_calculations`
- `daily_nutrition_summary` - Aggregated daily intake
- `nutrient_targets` - Personalized RDA

### Gamification
- `achievements`, `user_achievements`, `badges`
- `avatar_stats` - Level, HP, strength, agility (■ linked to biometrics with consent)
- `challenges`, `competitions`, `leaderboards`

### Payment System
- `unified_payment_ledger` - Master record for ALL transactions
- `barter_exchange_transactions`, `labor_booking_requests`
- `user_trust_ratings` - Reputation score (0.0-1.0)
- `pharmacy_orders` - Hybrid payment support

---

## Data Quality

### Nutrient Data Sources
- USDA FoodData Central
- FAO INFOODS African food composition tables
- Regional food databases

### Data Quality Levels
- `measured` - Lab-tested
- `calculated` - From known components
- `estimated` - Statistical estimation
- `imputed` - Filled from similar foods

---

## Vuralis Integration

**One-way data flow**: Vurafya → Vuralis  
**Requires**: User opt-in consent  
**Columns marked ■**: Read by Vuralis for avatar behavior (primarily Module 5: Biometrics)  
**Vurafya is standalone**: Does not depend on Vuralis

---

## PostgreSQL Migration Notes

**Data Types**:
- SQLite `INTEGER PK` → PostgreSQL `SERIAL PRIMARY KEY`
- SQLite `TEXT` → PostgreSQL `TEXT` or `VARCHAR(n)`
- SQLite `REAL` → PostgreSQL `NUMERIC(10,2)`
- SQLite JSON (TEXT) → PostgreSQL `JSONB`

**Indexes**:
- B-tree on foreign keys
- GIN on JSONB columns
- GIN on tsvector for full-text search

**Partitioning**:
- `audit_logs` by date
- `clinical_logs` by user_id range

---

## Documentation

**PDFs**: 
- `Vurafya 1A Nutrition to Medical.pdf` (39 pages, Modules 1-6)
- `Vurafya 1B Pharmacy to Vuralis Bridge.pdf` (51 pages, Modules 7-17 + Vuralis map)

**Status Reports**:
- `PRAL_3P_TRACKING_STATUS.md` - PRAL + 3P implementation complete (Phase 1 & 2)
- `MIGRATION_STATUS_REPORT.md` - Migration application summary
- `REBUILD_COMPLETE.md` - Full rebuild report

**For exact schemas, enums, constraints**: Always refer to PDFs.

---

## Summary

Vurafya is a **418-table, 22-module health platform** covering:
- Nutrition science (302 foods, 100% coverage, PRAL + 3P tracking)
- Medical consultations (tele-health, prescriptions)
- Pharmacy operations (drug safety, adherence, inventory)
- Gamification RPG (achievements, avatar stats)
- Revolutionary payments (barter + labor + fiat + points for broke communities)

**Regional Focus**: Pan-African (54 countries)  
**Clinical Standards**: FAO, USDA, WHO  
**Design Philosophy**: Self-sufficient workflows, transparent calculations, clear model boundaries
