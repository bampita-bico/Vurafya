# Vurafya Platform Overview

**A presentation document for partners, clinicians, and stakeholders**

| | |
|---|---|
| **Product** | Vurafya |
| **Company** | VuraLabs |
| **Version** | August 2026 |
| **Status** | Working prototype — demo-ready on laptop + Android |

---

## 1. Executive summary

**Vurafya** is a health platform that helps people track nutrition, biometrics, and
care workflows — and gives clinicians a single place to review trends, enter vitals,
and see **operating-band summaries** over time.

It is built for **real-world constraints**: intermittent connectivity, mobile-first
users, and settings where specialist review time is scarce.

**What is live today**

- Android patient app (installable APK)
- Clinician web portal
- Backend API with accounts, biometrics, stability scores, and trajectory views
- Local prediction engine that runs **without** depending on external research software

**What we are careful to say**

Vurafya provides **structured health tracking and model-based review surfaces**.
It does **not** replace clinical judgment, diagnosis, or licensed medical decision-making.

---

## 2. The opportunity

Across many African and emerging-market health systems, the same gaps recur:

| Gap | How Vurafya addresses it |
|-----|---------------------------|
| Poor continuity between visits | Longitudinal biometrics and meal data in one profile |
| Nutrition hard to quantify | Food database, PRAL / renal-friendly tracking, meal logging |
| Patient engagement drops off | Gamified avatar tied to health behaviours |
| Clinicians lack a quick trend view | Doctor portal: stability band, trajectory, quick vitals entry |
| Connectivity is unreliable | Mobile app scores locally when offline; syncs when online |

Vurafya is designed as a **platform**, not a single-feature app: nutrition, medical
consulting, pharmacy adherence, and labs are scaffolded in the data model
for phased rollout.

---

## 3. The product in one picture

```
┌─────────────────────────────────────────────────────────────────┐
│                         VuraLabs                                 │
│                          Vurafya                                 │
├─────────────────┬─────────────────────┬─────────────────────────┤
│  Patient app    │   Doctor portal     │      Backend API        │
│  (Flutter /     │   (React web)       │   (FastAPI + Postgres)  │
│   Android)      │                     │                         │
│                 │                     │                         │
│  • Home / RPG   │  • Stability view   │  • Auth & profiles      │
│  • Biometrics   │  • Trajectory chart │  • Engine / stability    │
│  • Offline      │  • Quick vitals     │  • Biometrics & labs     │
│    scoring      │  • Demo login       │  • Future: pharmacy,     │
│                 │                     │    telehealth            │
└────────┬────────┴──────────┬──────────┴──────────┬──────────────┘
         │                   │                     │
         └───────────────────┴─────────────────────┘
                    Same account, same data
```

---

## 4. Core idea: operating-band review

Vurafya summarises multi-system vitals into a simple **stability score (Ψₛ)** and
places the person in one of three **bands**:

| Band | Meaning (in the app) |
|------|----------------------|
| **Stable** | Vitals sit in a balanced operating range |
| **Constrained** | Signals suggest tighter review may be useful |
| **Overload** | Signals suggest elevated load or flux |

A **trajectory** projects how the score may move over the next steps — useful for
conversation and follow-up planning, not as a standalone clinical forecast.

**Systems in the grid today:** renal, cardio, metabolic, immune — mapped from
eGFR, creatinine, pulse, blood pressure, glucose, HbA1c, and related inputs.

> **Important:** These labels are **in-app modelling and review aids**. They are
> not validated as diagnostic or prognostic tools and are not submitted as medical
> devices in this prototype phase.

---

## 5. What you can see in a live demo (~10 minutes)

### A. Clinician portal (laptop)

1. Open the doctor portal in a browser.
2. Click **Instant demo access** (no setup friction for the audience).
3. Show **Patient** vs **Clinician** views.
4. Enter sample vitals in **Quick Entry** → **Save readings**.
5. Point out:
   - Stability score and regime (stable / constrained / overload)
   - Trajectory chart updating from the new data
   - Evidence panel (provenance, audit metadata when saved)

### B. Patient app (Android phone)

1. Open **Vurafya** from the app drawer.
2. Sign in (demo account or quick registration).
3. Show **Home**: health summary and avatar stats.
4. Show **Medical**: trajectory and regime (online or offline fallback).
5. Optional: turn off Wi‑Fi briefly to show **offline local scoring** still works.

### C. Under the hood (if the audience is technical)

- API health: `GET /health`
- Interactive docs: `/docs`
- Engine: `GET /api/v1/engine/stability` and `/trajectory`

---

## 6. Demo credentials (prototype)

| Field | Value |
|-------|--------|
| Email | `director.demo@vurafya.local` |
| Password | `change-me-demo-password` |

On mobile: **Sign In** with the above, or **Sign Up** to create a new account.

**Phone + laptop:** both must be on the **same Wi‑Fi**; the app is built to talk to
the API on the presenter’s machine.

---

## 7. What is built vs planned

### Built and demonstrable

| Area | Status |
|------|--------|
| User accounts (register, login, JWT) | ✓ |
| Stability & trajectory engine (local) | ✓ |
| Doctor portal UI | ✓ |
| Android APK (sideload install) | ✓ |
| Offline mobile scoring | ✓ |
| Large Postgres schema (nutrition, pharmacy, …) | ✓ schema; selective UI |
| Research runtime (CDFD) as optional plugin | ✓ optional, not required |

### Planned / not production-ready

| Area | Notes |
|------|--------|
| Clinical validation study | Not yet run |
| Play Store release & production signing | Debug-signed APK today |
| Full pharmacy flows in UI | Data model exists; UI partial |
| Regulatory / medical device pathway | Not started |
| Hosted cloud deployment | Local / LAN demo today |

---

## 8. Technology stack (credibility)

| Layer | Choice |
|-------|--------|
| Mobile | Flutter (Android; iOS possible) |
| Web | React, Tailwind, Recharts |
| API | Python FastAPI |
| Database | PostgreSQL (primary) |
| Auth | JWT access + refresh tokens |
| Optional research layer | CDFD Runtime (open-source sibling project) |

All three clients share one API. Prediction runs on **Vurafya’s own adapter** first;
research runtime is additive, not a hard dependency.

---

## 9. Regional and commercial vision

**Geographic focus:** Pan-African design — local foods, regional regulatory fields,
regional food coverage and care-delivery workflows in the long-range data model.

**Near-term commercial path (conversation starter)**

1. **Pilot with a clinic or NGO** — vitals + nutrition + review dashboard.
2. **Subscription or facility licence** for the doctor portal + patient seats.
3. **Data partnerships** only with explicit consent and clear governance.

---

## 10. Honest boundaries (questions we expect)

| Question | Answer |
|----------|--------|
| Is this FDA / CE marked? | **No.** Prototype / research software. |
| Does Ψₛ predict clinical outcomes? | **Not demonstrated.** It is an in-app summary for review. |
| Can it run without internet? | **Partially.** Core scoring works offline; sync needs connectivity. |
| Is patient data encrypted in production? | **Prototype defaults.** Production needs hardened hosting, TLS, secrets management. |
| Who owns the IP? | **VuraLabs** — platform, adapters, and application layer. |

---

## 11. Suggested next steps after this meeting

1. **Agree pilot scope** — one ward, one condition (e.g. CKD nutrition), or one community cohort.
2. **Define success metrics** — engagement, vitals capture rate, clinician time saved.
3. **Legal & ethics** — consent form, data residency, supervisor/clinician oversight.
4. **Deployment** — move from LAN demo to hosted API + store or managed APK distribution.
5. **Validation plan** — if claims tighten, design a study *before* marketing changes.

---

## 12. One-line pitches

**For a clinician:**
*“Vurafya gives you a longitudinal view of vitals and nutrition, with a simple banded summary so you can spot who needs attention first.”*

**For a partner / funder:**
*“VuraLabs has a working mobile + web health platform with offline-capable scoring and a path to nutrition and pharmacy — built for African connectivity realities.”*

**For a technical reviewer:**
*“Three-tier app on FastAPI/Postgres; local engine first; optional CDFD research runtime; honest claim boundary on all model outputs.”*

---

## Appendix A — Files & artefacts

| Item | Location |
|------|----------|
| Latest Android APK | `Vurafya/releases/Vurafya-v1.0.0-build4-vuralabs-2026-08-28-release.apk` |
| Technical runbook | `Vurafya/README.md` |
| Engine detail | `Vurafya/ENGINE_INTEGRATION.md` |
| API docs (when server running) | `http://<host>:8000/docs` |

---

## Appendix B — Presenter checklist

- [ ] PostgreSQL running
- [ ] API started on `0.0.0.0:8000`
- [ ] Doctor portal open in browser
- [ ] Phone on same Wi‑Fi as laptop
- [ ] Vurafya app installed and logged in
- [ ] Sample vitals ready to type (e.g. eGFR 72, BP 128/82, glucose 105)
- [ ] Backup: screenshots if live demo fails

---

**VuraLabs** · **Vurafya** · August 2026

*This document describes a working prototype. Wording is intentional: we present
what is built, what is modelled, and what still requires validation.*
