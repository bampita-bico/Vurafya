# Vurafya Engine Integration

Mapping between Vurafya records (biometrics, labs, nutrition) and the app's
**local predictive layer**. **VuraLabs** ships stability and trajectory without
CDFD Runtime. Runtime is an optional sandbox (doctor / info / gallery / CDFL / LLM).

## 0. Dependency rule

| Capability | Dependency |
|---|---|
| Stability / regimes / avatar sync | **Vurafya local** when usable measurements exist |
| Trajectory forecast | **Vurafya local** by default; `VURAFYA_USE_RUNTIME_KERNEL=1` for optional Runtime kernel |
| CDFL, gallery, doctor, info | Optional CDFD Runtime |
| Domain adapters | Retired (HTTP 410) |

If Runtime is missing or slimmed, the health app still works. API routes do not
return 503 solely because Runtime is offline. A local score is intentionally
`null` with `status: insufficient_data` until at least one complete domain has
current measurements; the app never invents a healthy baseline.

## 1. Core variables

Local operating-band bookkeeping:

**Ψₛ = (Φ / C) · S · Mₛ**

Not a validated clinical law — an in-app review surface.

| Variable | Interpretation | Vurafya proxy |
| :--- | :--- | :--- |
| **Φ** | Flux / functional signal | eGFR (renal), pulse (cardio), glucose (metabolic) |
| **C** | Constraint / load | Creatinine, systolic BP, glucose floor |
| **Ψₛ** | Operating ratio | Stability score (balanced near 1.0) |
| **S** | Body scaling | Fixed at 1.0 in the current local implementation |
| **Mₛ** | Chronicity | Fixed at 1.0 in the current local implementation |

## 2. Multi-system grid (2×2)

| Index | System | Φ source | C source |
| :--- | :--- | :--- | :--- |
| [0,0] | Renal | `egfr_ml_min` / 100 | `creatinine_mg_dl` / 1.0 |
| [0,1] | Cardio | 1.0 / (`pulse_bpm` / 70) | `bp_systolic` / 120 |
| [1,0] | Metabolic | `glucose_mg_dl` / 100 | `max(glucose_mg_dl / 100, 0.8)` |
| [1,1] | Immune | Not independently measured | Not independently measured |

## 3. Regimes

| Regime | Ψₛ range | Meaning (in-app) |
|--------|----------|------------------|
| Constrained | &lt; 0.8 | Lower-flux or higher-constraint band |
| Stable | 0.8 – 1.2 | Balanced operating band |
| Overload | &gt; 1.2 | Higher-flux or lower-capacity band |

These are modeling labels for review, not diagnoses or treatment plans.

## 4. Gamification (avatar stats)

- **Health level:** `mean_psi × 100`
- **Energy level:** `metabolic_psi × 100`
- **Immunity level:** `immune_psi × 100`
- **Resilience level:** `1 / std(psi_s) × 50`

Mobile offline mirror: `vurafya_app/lib/core/engine/offline_edge_engine.dart`.

## 5. Artifact lifecycle

Stability/trajectory responses may include envelopes with:

- `finite_audit` — JSON-visible finite-value check
- `provenance` — command, timestamp, engine source (`Vurafya local` when no Runtime)
- `claim_boundary` — modeling / review-support boundary text

Bundles under `RUNTIME_ARTIFACT_ROOT` (default `runtime_runs/`):

- `result.json`, `manifest.json`, `report.md`, `report.html`, `plots/`

Persistence is off for read endpoints by default. Set `RUNTIME_PERSIST_ON_READ=true`
only when retention is intended. Explicit persisted results use the optional
Runtime bundle when present, or a local JSON/HTML/Markdown bundle when absent.
Postgres persistence: `migrations_pg/091_runtime_artifacts.sql`.

## 6. HTTP API (`/api/v1/engine`)

| Method | Path | Notes |
|--------|------|-------|
| GET | `/stability` | Local score + optional runtime envelope |
| GET | `/trajectory?steps=50` | Local forecast by default |
| GET | `/runtime-status` | Import / availability state |
| GET | `/doctor` | CDFD Runtime doctor (optional) |
| GET | `/info` | Runtime info envelope (optional) |
| GET | `/gallery` | Slim Runtime CDFL gallery (optional) |
| GET | `/domains` | **410** — retired |
| GET | `/llm/providers` | Provider inventory (optional) |
| GET | `/runs` | Authenticated user's saved runs |
| GET | `/runs/{run_uid}` | Owner run detail; assigned clinician may pass `patient_user_id` |
| POST | `/runs/{run_uid}/review` | Review marker; requires active clinician role and assignment |
| POST | `/domain/{domain}` | **410** — retired |
| POST | `/execute-dsl` | Custom CDFL via adapter (optional) |

## 7. Clients

- **React** (`vurafya_web`): stability dashboard, trajectory, runtime evidence panel
- **Flutter** (`vurafya_app`): medical screen, offline edge engine fallback with
  explicit local evidence envelope

## 8. Implementation map

| Component | Path |
|-----------|------|
| Local adapter | `backend/services/engine_adapter.py` |
| Runtime bridge | `backend/services/cdfd_bridge.py` |
| Artifacts | `backend/services/runtime_artifacts.py` |
| API routes | `backend/api/engine.py` |
| Background worker | `backend/services/background_worker.py` |
| Sample CDFL | `backend/scripts/medical_rules.cdfl` |

## 9. Environment

| Variable | Purpose |
|----------|---------|
| `ENGINE_PATH` | Path to `CDFD-Runtime` (optional) |
| `VURAFYA_USE_RUNTIME_KERNEL` | `1` to use Runtime kernel for trajectory |
| `RUNTIME_ARTIFACT_ROOT` | Bundle output directory |
| `RUNTIME_REQUIRE_FINITE` | Strict finite audit (default true) |
| `RUNTIME_PERSIST_ON_READ` | Persist stability and trajectory reads (default false) |
| `ENABLE_BACKGROUND_WORKER` | Start the non-essential worker (default false) |
| `ENABLE_MODEL_AUTOMATIONS` | Permit worker model-derived actions (default false) |

---

© 2026 **VuraLabs**
