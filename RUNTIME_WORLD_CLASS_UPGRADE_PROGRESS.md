# Vurafya Release & Upgrade Log

**Product:** Vurafya by **VuraLabs**

---

## 2026-08-28 — Local-first decoupling & mobile build 4

### Completed

- **Runtime decoupling:** stability and trajectory use Vurafya local adapter by default;
  no `engine_offline` gate when Runtime is absent.
- **Optional Runtime:** `VURAFYA_USE_RUNTIME_KERNEL=1` for kernel trajectory; CDFL/
  gallery/doctor soft-fail; `/domains` and `/domain/*` return **410**.
- **Auth fixes:** Postgres timestamp handling; sequence grants for `cdfd` DB user.
- **Mobile build 4:** `releases/Vurafya-v1.0.0-build4-vuralabs-2026-08-28-release.apk`
  - API URL: laptop LAN IP (`api_client.dart`)
  - Launcher label: **Vurafya**
  - Version `1.0.0+4`, debug-signed for sideload
- **Branding:** docs updated to **VuraLabs** (not Vura iX / Vura Labs).
- **Tests:** `tests/test_local_prediction.py` + `tests/test_runtime_artifacts.py`.

### Verified

- `POST /api/v1/auth/demo-login` and login with demo credentials
- `flutter build apk --release` on T420
- `adb install` on Samsung SM_A235F

### Still needed

- Production signing keystore (Play Store / formal distribution)
- Stable API hostname or build-time config for mobile (avoid hard-coded LAN IP)
- Full `migrations_pg` apply on clean Postgres (bootstrap + later migrations)
- Clinician role enforcement for run review
- Durable mobile cache for run bundles

---

## 2026-06-07 — Runtime artifact upgrade (build 1–2)

### Completed

- Canonical APKs:
  - `releases/Vurafya-v1.0.0-build1-release.apk`
  - `releases/Vurafya-v1.0.0-build1-runtime-upgrade-2026-06-07-release.apk`
- Runtime artifact persistence (`runtime_artifacts.py`, migration `091`)
- CDFD Runtime public-surface bridge (doctor, info, domains at the time, LLM inventory)
- Engine API envelopes: finite audit, provenance, claim boundary
- React + Flutter runtime evidence UI
- Android: AGP 8.11.1, Kotlin 2.2.20, Java 17

### Verified (June 2026)

- APK SHA-256 recorded in git notes for build 1 and runtime-upgrade build
- `pytest tests/test_runtime_artifacts.py`
- `npm run build`, `flutter analyze`, `flutter test`

### Superseded

- Domain adapters and Neo4j webapp removed from slim CDFD Runtime v1.1.1+
- Product spine moved to **local prediction** (Aug 2026)

---

## APK index

| File | Build | Notes |
|------|-------|-------|
| `Vurafya-v1.0.0-build1-release.apk` | 1 | Initial release (unsigned in some builds) |
| `Vurafya-v1.0.0-build1-runtime-upgrade-2026-06-07-release.apk` | 1 | Runtime UI upgrade |
| `Vurafya-v1.0.0-build2-local-prediction-2026-08-25-release.apk` | 2 | Local prediction backend |
| `Vurafya-v1.0.0-build2-local-prediction-2026-08-25-release-signed.apk` | 2 | Debug-signed |
| `Vurafya-v1.0.0-build4-vuralabs-2026-08-28-release.apk` | 4 | VuraLabs branding, LAN API, label **Vurafya** |

---

© 2026 **VuraLabs**
