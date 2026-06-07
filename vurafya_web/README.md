# Vurafya Doctor Portal

A clinical workflow dashboard for model review, powered by the public **CDFD Runtime**.

## Features
- **Stability Dashboard**: Current runtime stability score (Ψ_s).
- **Trajectory Projection**: 50-step model projection from the current state.
- **Biological Ontology**: Cross-system influence visualization using Neo4j.
- **Runtime Guidance**: Neutral flux and constraint labels from CDFD Runtime.
- **Instant Demo Access**: One-click demo login for stakeholder presentations.

## Tech Stack
- **Frontend**: React 18, Tailwind CSS, Lucide Icons.
- **Charts**: Recharts (High-performance SVG charting).
- **Backend Integration**: Axios connecting to the Vurafya Python API.

## Getting Started

### Prerequisites
- Node.js (v16+)
- Vurafya Backend running (default: http://localhost:8000)

### Installation
```bash
npm install
```

### Running in Development
```bash
npm start
```

### Production Build
```bash
npm run build
```

## API Configuration
By default, the portal connects to `http://localhost:8000/api/v1`. You can override this by setting `REACT_APP_API_URL` in your environment.

---
© 2026 Vura iX
