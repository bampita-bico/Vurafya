# Vurafya Runtime Upgrade Progress

Date: 2026-06-07

## Completed

- Recovered the previous release APK and placed the canonical copy at
  `releases/Vurafya-v1.0.0-build1-release.apk`; removed duplicate generated APKs.
- Built a fresh runtime-upgrade release APK and placed it at
  `releases/Vurafya-v1.0.0-build1-runtime-upgrade-2026-06-07-release.apk`;
  removed duplicate generated APKs from Flutter/Gradle output folders.
- Added runtime artifact persistence:
  - `backend/services/runtime_artifacts.py`
  - `migrations_pg/091_runtime_artifacts.sql`
  - `migrations/091_runtime_artifacts.sql`
- Added CDFD Runtime public-surface bridge support for doctor, info, domains,
  provider inventory, domain runs, result envelopes, finite audits, reports, and
  run bundles.
- Upgraded `/api/v1/engine/stability` and `/api/v1/engine/trajectory` to return
  runtime envelopes, persisted run metadata, finite audit, provenance, artifact
  paths, and claim boundary.
- Added runtime endpoints:
  - `GET /api/v1/engine/runtime-status`
  - `GET /api/v1/engine/doctor`
  - `GET /api/v1/engine/info`
  - `GET /api/v1/engine/domains`
  - `GET /api/v1/engine/llm/providers`
  - `GET /api/v1/engine/runs`
  - `GET /api/v1/engine/runs/{run_uid}`
  - `POST /api/v1/engine/runs/{run_uid}/review`
  - `POST /api/v1/engine/domain/{domain}`
- Added a Postgres compatibility wrapper around legacy SQLite-style route SQL.
- Updated the background worker to write runtime bundles for scheduled stability
  checks.
- Upgraded React and Flutter clients to show runtime evidence bundles.
- Added focused unit tests in `tests/test_runtime_artifacts.py`.
- Updated `ENGINE_INTEGRATION.md` with the current runtime artifact lifecycle.
- Upgraded Android buildchain pins to Android Gradle Plugin `8.11.1`, Kotlin
  `2.2.20`, and Java/Kotlin target `17`.

## Verified

- Previous APK SHA-256:
  `382ef5cbf0dd80ffaeab1781faa26f5eb4d237bc12263b3cc3cb76de5ad69b3c`
- Runtime-upgrade APK SHA-256:
  `443d6932ba8f9d91fdb02d7215bf7c362abc582df979194bd839538bbc11a68a`
- `python -m compileall backend tests`
- `python -m pytest -q tests/test_runtime_artifacts.py`
- `python -c "from backend.main import app; print(app.title)"`
- CDFD Runtime `doctor --json`
- CDFD Runtime `info --json`
- `npm run build` in `vurafya_web`
- `flutter analyze`
- `flutter test`
- Direct Gradle release build produced the runtime-upgrade APK.
- Docker had no running containers during verification, and local Postgres
  connectivity to `localhost:5432/cdfd` failed, so migrations were not applied
  to a live database in this run.

## Still Needed For A Production-Grade Release

- Apply Postgres migration `091_runtime_artifacts.sql` against the live database.
- Configure production Android signing if this APK will be distributed through a
  store or formal release channel.
- Run a live authenticated smoke test for:
  - `/api/v1/engine/stability`
  - `/api/v1/engine/trajectory`
  - `/api/v1/engine/runs`
  - `/api/v1/engine/runs/{run_uid}/review`
- Add FHIR/SMART export/import around saved runtime runs.
- Add clinician role enforcement for run review and alert acknowledgement.
- Add durable mobile cache storage for recent run bundles instead of only API
  fetch/fallback display.
- Add signed artifact manifests if bundles will be used for external clinical or
  regulatory review.
