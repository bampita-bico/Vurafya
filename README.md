# Vurafya Demo Runbook (Hospital Presentation)

This project includes:
- `backend` (FastAPI API on port `8000`)
- `vurafya_web` (Doctor Portal on port `3000`)

## 1) Quick Start (Local)

From the `Vurafya` directory:

```bash
# Terminal 1 - backend
source venv/bin/activate
PYTHONPATH=/home/bampita/Projects/CDFD:/home/bampita/Projects/CDFD/Vurafya:/home/bampita/Projects/CDFD/CDFD-Runtime \
  python -m uvicorn backend.main:app --host 127.0.0.1 --port 8000
```

```bash
# Terminal 2 - web app
cd vurafya_web
npm install
HOST=127.0.0.1 PORT=3000 npm start
```

Open:
- Web app: `http://127.0.0.1:3000`
- API docs: `http://127.0.0.1:8000/docs`
- Health check: `http://127.0.0.1:8000/health`

## 2) Director Demo Flow (2 minutes)

1. Open the Doctor Portal.
2. Click **Instant demo access** in the Account panel.
3. Switch between **Patient** and **Clinician** views.
4. Enter biometrics in **Quick Entry** and click **Save readings**.
5. Show runtime trajectory refresh and avatar export panel.

## 3) Demo Account

The backend exposes `POST /api/v1/auth/demo-login`:
- Creates the demo user automatically (once).
- Returns valid JWT tokens for the session.

Default demo credentials are environment-configurable:
- `DEMO_EMAIL`
- `DEMO_USERNAME`
- `DEMO_PASSWORD`

## 4) Production Build

```bash
cd vurafya_web
GENERATE_SOURCEMAP=false npm run build
```

Build output: `vurafya_web/build`
