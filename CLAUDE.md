# CLAUDE.md

Guidance for Claude Code and contributors working in the **Vurafya** repository.

## Project overview

**Vurafya** is a health platform by **VuraLabs** (one word, not “Vura Labs”).

It spans nutrition, biometrics, medical workflows, pharmacy, gamification, and
pan-African nutrition — with a **local predictive layer** for operating-band
summaries from vitals, labs, and activity.

**CDFD Runtime** (sibling repo `CDFD-Runtime/`) is optional research software:
doctor, info, gallery, CDFL, LLM. It is **not** the product spine. Stability and
trajectory work without it.

**Claim boundary:** Ψₛ bands, regimes, and trajectories are **app bookkeeping /
model review surfaces**. They are not validated clinical predictions, diagnoses,
or treatment plans.

---

## Repository map

```
Vurafya/
├── backend/           # FastAPI — auth, engine, game, pharmacy, …
├── vurafya_web/       # React doctor portal
├── vurafya_app/       # Flutter patient app
├── migrations_pg/     # PostgreSQL migrations (primary for API)
├── migrations/        # Legacy SQLite migrations
├── scripts/           # migrate.py, seed, verification
├── tests/             # pytest (local prediction, runtime artifacts)
├── releases/          # Canonical signed APKs
├── seed_data/         # CSV nutrition seeds
├── ENGINE_INTEGRATION.md
└── README.md          # Runbook (start here)
```

---

## Architecture (current)

### Prediction stack

| Layer | Location | Notes |
|-------|----------|-------|
| **Local backend** | `backend/services/engine_adapter.py` | Biomarker → Ψₛ grid; never gates on Runtime |
| **Local mobile** | `vurafya_app/lib/core/engine/offline_edge_engine.dart` | Same band logic offline |
| **Runtime bridge** | `backend/services/cdfd_bridge.py` | Soft-fail imports; domains retired |
| **Artifacts** | `backend/services/runtime_artifacts.py` | Provenance tagged “Vurafya local” when no Runtime |
| **API** | `backend/api/engine.py` | No 503 when Runtime offline; `/domains` → 410 |

Environment:

- `VURAFYA_USE_RUNTIME_KERNEL=1` — optional Runtime kernel for trajectory
- `ENGINE_PATH` — path to `CDFD-Runtime` (optional)
- `DATABASE_URL` — PostgreSQL connection string

### Clients

- **Flutter** (`vurafya_app`): Riverpod, go_router, Dio. API base URL in
  `lib/core/api/api_client.dart` — must be LAN IP for physical devices.
- **React** (`vurafya_web`): CRA, Tailwind, Recharts. Demo login button calls
  `POST /api/v1/auth/demo-login`.

### Database

- **Primary:** PostgreSQL via SQLAlchemy + asyncpg (`backend/utils/database.py`).
  Legacy route SQL uses `DatabaseCompatSession` (`?` placeholders, SQLite-isms
  normalized for Postgres).
- **Legacy file:** `AfyaFigo.db` archived at `../archives/vurafya-legacy/` — schema
  reference only; the API reads Postgres via `DATABASE_URL`.
- **Migrations:** `python scripts/migrate.py` with `DATABASE_URL` set. Use
  `migrations_pg/` for Postgres.

After bootstrap migrations, ensure the app DB user has **sequence** grants
(`GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES …`) or inserts fail.

### Auth

- `backend/api/auth.py` — register, login, refresh, demo-login
- Demo defaults in `backend/config.py` / `.env`
- Postgres timestamps: use naive UTC (`datetime.now(timezone.utc).replace(tzinfo=None)`)
  for `TIMESTAMP WITHOUT TIME ZONE` columns

---

## Common commands

```bash
# API (from Vurafya/)
source venv/bin/activate
export DATABASE_URL="postgresql://cdfd:PASSWORD@localhost:5432/cdfd"
export PYTHONPATH="$(pwd)"
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000

# Migrations
DATABASE_URL="postgresql://postgres:PASSWORD@localhost:5432/cdfd" python scripts/migrate.py

# Tests
python -m pytest -q tests/test_local_prediction.py tests/test_runtime_artifacts.py

# Web
cd vurafya_web && npm start

# Mobile
cd vurafya_app && flutter build apk --release
```

---

## Mobile release notes

- **Application ID:** `com.vurafx.vurafya_app` (historical package name)
- **Launcher label:** `Vurafya` (`AndroidManifest.xml`)
- **Signing:** debug keystore at `~/.android/debug.keystore` for local APKs;
  `android/app/build.gradle` `signingConfigs.release` → debug for sideload builds
- **Install:** `adb install -r releases/Vurafya-…-release.apk`
- Rebuild required when LAN IP changes (`api_client.dart`)

---

## Engine integration (short)

Ψₛ = (Φ / C) · S · Mₛ — used as **operating-band bookkeeping** in-app.

| System | Φ proxy | C proxy |
|--------|---------|---------|
| Renal | eGFR / 100 | creatinine |
| Cardio | 70 / pulse | systolic BP / 120 |
| Metabolic | glucose / 100 | HbA1c / 5.5 |
| Immune | systemic mean | systemic mean |

Regimes: **constrained** (&lt;0.8), **stable** (0.8–1.2), **overload** (&gt;1.2).

Full mapping and HTTP surface: `ENGINE_INTEGRATION.md`.

---

## Domain modules (data model)

Vurafya’s schema is large (~400+ tables across nutrition, medical, pharmacy,
gamification and compliance). Migrations live under `migrations_pg/`.

### Modules 1–6: Nutrition → Medical

Nutrition science, meals, beverages, users, biometrics (Vuralis bridge with
consent), tele-consultations.

### Modules 7–12: Pharmacy → AI

Pharmacy, facilities, labs, preventive rules, RPG gamification, AI recommendations.

### Modules 13–17: Social → Infrastructure

Social, commerce, Afya Points, research aggregates, audit/notifications.

## Key clinical formulas

### PRAL (Potential Renal Acid Load)

```
PRAL = 0.49×Protein(g) + 0.037×P(mg) - 0.021×K(mg) - 0.026×Mg(mg) - 0.013×Ca(mg)
```

Negative = alkalizing; positive = acidifying. Track protein, potassium, and
phosphorus separately for CKD/dialysis workflows.

### Nutritional accounting

```
actual_intake = amount_per_100g × (quantity_grams / 100) × retention_factor
```

### Glycemic load

```
GL = (GI × available_carb_g) / 100
```

---

## Design patterns

- **Foreign keys:** `{table}_id`
- **Junction tables:** `{table_a}_{table_b}`
- **User activity:** `user_{action}`
- **Standard columns:** `id`, `created_at`, `is_active`, `is_verified`, `user_id`
- **JSON:** stored as TEXT (SQLite legacy) or JSONB (Postgres targets)

### Multi-tenancy

1. Global reference data (no `user_id`): foods, nutrients, medications
2. User-specific data: meals, consultations, orders
3. User-generated: recipes, submissions

---

## Regional context

Pan-African focus: 54 countries, 45 currencies (42 fiat + AP + LH + BC).
Regional fields: `local_name`, `region_code`, `regulatory_body`.

---

## Vuralis integration

One-way: Vurafya → Vuralis (with user consent). Vurafya does not depend on Vuralis.

---

## What not to claim

- Do not describe CDFD/AFL or Runtime as demonstrated predictive surplus
- Do not imply clinical validation of Ψₛ or trajectory outputs
- Do not require Runtime for core app demos — local path must work
- Company name is **VuraLabs**

---

## Documentation index

| File | Purpose |
|------|---------|
| `README.md` | Runbook: Postgres, API, web, mobile, login |
| `ENGINE_INTEGRATION.md` | Engine mapping and `/api/v1/engine/*` |
| `RUNTIME_WORLD_CLASS_UPGRADE_PROGRESS.md` | Release history |
| `vurafya_app/README.md` | Flutter app |
| `vurafya_web/README.md` | Doctor portal |
| `.env.example` | Environment template |

---

© 2026 **VuraLabs**
