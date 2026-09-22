# Vurafya

**Vurafya** is a health platform by **VuraLabs**. It combines nutrition, biometrics,
medical workflows, and gamification with a **local predictive layer** for
operating-band summaries — stability (Ψₛ), trajectory projection, and avatar sync.

CDFD Runtime is an **optional** research sandbox (doctor, info, gallery, CDFL, LLM).
It is **not** required for the app to predict or for clinicians to review local scores.

## Repository layout

| Path | Role |
|------|------|
| `backend/` | FastAPI API (port `8000`) |
| `vurafya_web/` | Doctor portal — React (port `3000` dev) |
| `vurafya_app/` | Patient app — Flutter (Android APK) |
| `migrations_pg/` | PostgreSQL migrations (primary) |
| `migrations/` | Legacy SQLite migrations |
| `releases/` | Signed APK builds |
| `seed_data/` | CSV nutrition seeds (300 foods and beverages) |

Legacy SQLite snapshot `AfyaFigo.db` is archived outside this repo at
`../archives/vurafya-legacy/AfyaFigo.db` (reference only; API uses Postgres).

## Prerequisites

- Python 3.11+ with `venv` at `Vurafya/venv`
- PostgreSQL 15 (Docker or local)
- Node.js 16+ (doctor portal)
- Flutter SDK (mobile app)
- Android SDK; a private release keystore is required only for release APKs

## 1) Start PostgreSQL

From the `Vurafya` directory:

```bash
docker compose up -d postgres
```

This starts **`vurafya_db`** on host port **5435** (volume `postgres_data`).

Apply migrations:

```bash
cd Vurafya
DATABASE_URL="postgresql://cdfd:change-me-postgres-password@localhost:5435/cdfd" \
  python scripts/migrate.py
```

Load nutrition seed data (foods, nutrients, PRAL):

```bash
DATABASE_URL="postgresql://cdfd:change-me-postgres-password@localhost:5435/cdfd" \
  python scripts/import_seed_postgres.py
```

The catalog has 300 foods, including 8 beverages. Every item has a 100 g
entry; foods also have editable estimate presets for one cup (150 g) and one
plate (350 g). Beverages use cup (250 mL) and bottle (500 mL) presets instead.

Grant sequence permissions if bootstrap used a superuser:

```bash
docker exec vurafya_db psql -U cdfd -d cdfd -c \
  "GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO cdfd;"
```

## 2) Start the API

```bash
cd Vurafya
source venv/bin/activate
cp .env.example .env   # edit JWT_SECRET and DATABASE_URL

export DATABASE_URL="postgresql://cdfd:change-me-postgres-password@localhost:5435/cdfd"
export PYTHONPATH="/home/bampita/Projects/CDFD/Vurafya"
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

Verify:

- Health: `http://127.0.0.1:8000/health`
- Docs: `http://127.0.0.1:8000/docs`

For phone testing, bind `0.0.0.0` and use your laptop's LAN IP (e.g. `172.31.0.51`).

## 3) Doctor portal (web)

```bash
cd vurafya_web
npm install
HOST=127.0.0.1 PORT=3000 npm start
```

Open `http://127.0.0.1:3000`. Override API URL with `REACT_APP_API_URL`.
For the explicitly labeled development demo button, also set
`REACT_APP_DEMO_LOGIN_ENABLED=true`; do not set it for production builds.

**Demo flow (2 min):**

1. Click **Instant demo access**
2. Switch Patient / Clinician views
3. Enter biometrics in **Quick Entry** → **Save readings**
4. Review stability and trajectory panels

## 4) Mobile app (Flutter)

### Point the app at your API

Pass the endpoint at build or run time; source edits are not required:

```bash
flutter run --dart-define=VURAFYA_API_URL=http://YOUR_LAN_IP:8000/api/v1
```

- Emulator → host: `http://10.0.2.2:8000/api/v1`
- Physical phone → same Wi‑Fi as the laptop, use LAN IP

### Build release APK

```bash
cd vurafya_app
flutter pub get
flutter build apk --release --dart-define=VURAFYA_API_URL=https://api.example.com/api/v1
```

Create the untracked `vurafya_app/android/key.properties` before a release build:

```properties
storeFile=/absolute/path/to/release.keystore
storePassword=...
keyAlias=...
keyPassword=...
```

Release builds refuse to use a debug key. Canonical copies live in `releases/`.
Canonical copies live in `releases/`.

Latest build (Aug 2026):
`releases/Vurafya-v1.0.0-build4-vuralabs-2026-08-28-release.apk`

### Install on a phone

```bash
adb install -r releases/Vurafya-v1.0.0-build4-vuralabs-2026-08-28-release.apk
```

Launcher label: **Vurafya**. Phone and laptop must share Wi‑Fi for login.

## 5) Accounts

**Demo** is enabled by default only for development. Set `DEMO_LOGIN_ENABLED=false`
in every production deployment; then `/api/v1/auth/demo-login` returns 404.

When enabled, it is auto-created on first `POST /api/v1/auth/demo-login`:

| Field | Default |
|-------|---------|
| Email | `director.demo@vurafya.local` |
| Username | `director_demo` |
| Password | `vurafya123` |

Override via `.env`: `DEMO_EMAIL`, `DEMO_USERNAME`, `DEMO_PASSWORD`.

**Mobile:** use **Sign In** with demo credentials, or **Sign Up** to register.

## 6) Prediction architecture (summary)

| Capability | Source |
|------------|--------|
| Stability / regimes | Vurafya local with real, usable current measurements |
| Trajectory | Local mean-reverting forecast by default |
| Runtime kernel trajectory | Optional: `VURAFYA_USE_RUNTIME_KERNEL=1` |
| CDFL / gallery / doctor | Optional CDFD Runtime plugin |
| Domain adapters | Retired → HTTP 410 |

See `ENGINE_INTEGRATION.md` for variable mapping and API surface.

## 7) Tests

```bash
cd Vurafya
source venv/bin/activate
python -m pytest -q tests/test_local_prediction.py tests/test_runtime_artifacts.py
```

Install test tools first with `python -m pip install -r backend/requirements-dev.txt`.

## 8) Production web build

```bash
cd vurafya_web
GENERATE_SOURCEMAP=false npm run build
```

Output: `vurafya_web/build`

## Further reading

- `docs/Vurafya-Platform-Presentation.md` — **stakeholder presentation** (print or share)
- `CLAUDE.md` — developer context for AI assistants and contributors
- `ENGINE_INTEGRATION.md` — local engine mapping and API endpoints
- `RUNTIME_WORLD_CLASS_UPGRADE_PROGRESS.md` — release and upgrade log

---

© 2026 **VuraLabs**
