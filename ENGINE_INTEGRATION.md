# Vurafya Universal Engine Integration

This document defines the mapping between Vurafya records (biometrics, labs, nutrition) and the public **CDFD Runtime**.

## 1. Core Variables Mapping

The engine operates on the master equation:
**Ψ_s = (Φ / C) · S · M_s**

In the Vurafya application domain, these are mapped as follows:

| Engine Variable | Clinical Interpretation | Vurafya Proxy (Biomarkers) |
| :--- | :--- | :--- |
| **Φ (Phi)** | Model flux / functional signal | eGFR (Renal), Heart Rate (Cardio), Glucose Flux (Metabolic) |
| **C (Constraint)** | Model constraint / load signal | Creatinine, Systolic BP, HbA1c |
| **Ψ_s (Psi_s)** | Operating ratio | Runtime stability score (balanced near 1.0) |
| **S (Surface)** | Body Scaling | Height/Weight (BMI Scaling) |
| **M_s (Memory)** | Chronicity | Historical baseline of clinical metrics |

## 2. Multi-System Grid (2x2)

Vurafya initializes a localized spatial grid to model the coupling between major systems:

| Index | System | Phi (Flux) Source | C (Constraint) Source |
| :--- | :--- | :--- | :--- |
| **[0,0]** | **Renal** | `egfr_ml_min` / 100 | `creatinine_mg_dl` / 1.0 |
| **[0,1]** | **Cardio** | 1.0 / (`pulse_bpm` / 70) | `bp_systolic` / 120 |
| **[1,0]** | **Metabolic** | `glucose_mg_dl` / 100 | `hb_a1c` / 5.5 |
| **[1,1]** | **Immune** | Systemic Mean | Systemic Mean |

## 3. Runtime Regimes

Based on the calculated **Ψ_s**, the app displays three runtime regimes:
- **Stable (0.8 < Ψ_s < 1.2)**: Balanced model operating band.
- **Constrained (Ψ_s < 0.8)**: Lower-flux or higher-constraint model state marked for review.
- **Overload (Ψ_s > 1.2)**: Higher-flux or lower-capacity model state marked for review.

The runtime output is a modeling and review surface. It is not a diagnosis,
treatment plan, or substitute for licensed clinical judgment.

## 4. Gamification Link (Avatar Stats)

The engine drives the RPG avatar stats in the mobile app:
- **Health Level**: `mean_psi * 100`
- **Energy Level**: `metabolic_psi * 100`
- **Immunity Level**: `immune_psi * 100`
- **Resilience Level**: `1 / std(psi_s) * 50`

## 5. Runtime Artifact Lifecycle

Every runtime-facing stability or trajectory request is now wrapped in the
current CDFD Runtime result envelope before it is returned to the app. The
envelope records:

- `finite_audit`: strict JSON-visible finite-value audit.
- `provenance`: runtime, language, command, timestamp, Python, and platform.
- `claim_boundary`: deterministic modeling/review-support boundary.
- `payload.runtime_version`: public runtime info, command list, and domain count
  when the runtime surface is available.

The backend writes a run bundle under `RUNTIME_ARTIFACT_ROOT`
(default: `runtime_runs/`) with:

- `result.json`
- `manifest.json`
- `report.md`
- `report.html`
- `plots/`

The same run is recorded in Postgres via `migrations_pg/091_runtime_artifacts.sql`
and in the legacy SQLite migration set via `migrations/091_runtime_artifacts.sql`.
Non-balanced runtime guidance also creates a `runtime_alerts` row for review.

## 6. Runtime API Surface

- `GET /api/v1/engine/stability`: current Vurafya clinical stability plus
  `runtime_envelope`, `runtime_run`, `finite_audit`, `provenance`, and
  `claim_boundary`.
- `GET /api/v1/engine/trajectory?steps=50`: forecast plus saved runtime bundle.
- `GET /api/v1/engine/runtime-status`: import and availability state for kernel,
  decision, DSL, action gateway, ontology, and runtime public surfaces.
- `GET /api/v1/engine/doctor`: CDFD Runtime doctor report.
- `GET /api/v1/engine/info`: runtime info envelope.
- `GET /api/v1/engine/domains`: available runtime domains.
- `GET /api/v1/engine/llm/providers`: provider inventory. Provider calls remain
  above the deterministic runtime engine boundary.
- `GET /api/v1/engine/runs`: authenticated user's recent saved runtime runs.
- `GET /api/v1/engine/runs/{run_uid}`: saved run detail.
- `POST /api/v1/engine/runs/{run_uid}/review`: clinician/user review marker.
- `POST /api/v1/engine/domain/{domain}`: run a public runtime domain and save
  its artifact bundle.

## 7. Client Surfaces

The React portal and Flutter medical screen now expose the saved run evidence:

- run UID
- finite-audit state
- provenance command
- result/manifest/report artifact filenames
- persistence errors when a bundle was written but the database row was not
- claim boundary text

Flutter also annotates offline edge-engine fallbacks with an explicit local
evidence envelope, so users can distinguish synced runtime artifacts from
device-only model output.

## 8. Technical Implementation

- **Adapter**: `backend/services/engine_adapter.py`
- **Runtime bridge**: `backend/services/cdfd_bridge.py`
- **Artifact service**: `backend/services/runtime_artifacts.py`
- **API**: `backend/api/engine.py`
- **Worker**: `backend/services/background_worker.py` (Hourly refresh)
- **DSL**: `backend/scripts/medical_rules.cdfl` (Custom CDFL rules)
- **Postgres migrations**: `migrations_pg/091_runtime_artifacts.sql`
- **SQLite migrations**: `migrations/091_runtime_artifacts.sql`
