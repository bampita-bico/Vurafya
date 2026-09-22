# Vurafya Doctor Portal

Clinical workflow dashboard for **Vurafya** by **VuraLabs**.

Review operating-band stability, trajectory projections, and biometric entry.
Prediction runs on the **Vurafya local engine** by default; CDFD Runtime is an
optional review plugin when installed on the API host.

## Features

- **Stability dashboard** — current Ψₛ and regime
- **Trajectory projection** — forecast from local adapter (optional Runtime kernel)
- **Quick Entry** — save biometrics and refresh scores
- **Runtime evidence** — finite audit, provenance, claim boundary when bundles exist
- **Instant demo access** — one-click `POST /api/v1/auth/demo-login`

## Tech stack

- React 18, Tailwind CSS, Lucide Icons
- Recharts for SVG charts
- Axios → Vurafya FastAPI (`/api/v1`)

## Prerequisites

- Node.js 16+
- Vurafya backend on port `8000` (see root `README.md`)

## Development

```bash
npm install
npm start
```

Default: `http://localhost:3000` → API `http://localhost:8000/api/v1`

Override API:

```bash
REACT_APP_API_URL=http://192.168.1.10:8000/api/v1 npm start
```

## Production build

```bash
GENERATE_SOURCEMAP=false npm run build
```

Output: `build/`

## Demo account

Web: click **Instant demo access**.

Credentials (defaults):

- Email: `director.demo@vurafya.local`
- Password: `change-me-demo-password`

## Claim boundary

Stability and trajectory outputs are **model review surfaces**, not diagnoses or
treatment plans. See `ENGINE_INTEGRATION.md` for API details.

---

© 2026 **VuraLabs**
