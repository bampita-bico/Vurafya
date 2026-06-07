"""Persistence layer for CDFD Runtime artifacts inside Vurafya."""
from __future__ import annotations

import json
import math
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping

from sqlalchemy import text

from backend.config import settings
from backend.services.cdfd_bridge import (
    CLAIM_BOUNDARY,
    RUNTIME_SURFACES_AVAILABLE,
    clean_json,
    create_run_bundle,
    explanation_for_result,
    result_envelope,
    runtime_info,
)
from backend.utils.database import AsyncSessionLocal


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _json(value: Any) -> str:
    cleaned = clean_json(value) if clean_json else value
    return json.dumps(cleaned, sort_keys=True, allow_nan=False, default=str)


def _safe_float(value: Any) -> float | None:
    try:
        numeric = float(value)
    except (TypeError, ValueError):
        return None
    return numeric if math.isfinite(numeric) else None


def _runtime_version() -> dict[str, Any]:
    if not RUNTIME_SURFACES_AVAILABLE or runtime_info is None:
        return {"name": "CDFD Runtime", "status": "unavailable"}
    info = runtime_info()
    payload = info.get("payload", {}) if isinstance(info, Mapping) else {}
    return {
        "name": payload.get("name", "CDFD Runtime"),
        "language": payload.get("language", "CDFL"),
        "domain_count": payload.get("domain_count"),
        "commands": payload.get("commands", []),
        "provenance": info.get("provenance", {}),
    }


def build_patient_envelope(
    *,
    user_id: int,
    kind: str,
    command: str,
    payload: Mapping[str, Any],
    status: str = "ok",
    warnings: list[str] | None = None,
    errors: list[str] | None = None,
) -> dict[str, Any]:
    """Wrap a Vurafya clinical payload in the current runtime envelope shape."""
    body = {
        "user_id": user_id,
        "runtime_version": _runtime_version(),
        "claim_boundary": CLAIM_BOUNDARY,
        **dict(payload),
    }
    if result_envelope:
        return result_envelope(
            kind,
            command,
            body,
            status=status,
            warnings=warnings,
            errors=errors,
        )
    return {
        "kind": kind,
        "status": status,
        "payload": body,
        "warnings": warnings or [],
        "errors": errors or [],
        "finite_audit": {"all_finite": True, "non_finite_paths": []},
        "provenance": {
            "runtime": "CDFD Runtime",
            "language": "CDFL",
            "command": command,
            "timestamp_utc": _now(),
        },
    }


def _run_summary(result: Mapping[str, Any], clinical_state: Mapping[str, Any] | None = None) -> dict[str, Any]:
    payload = result.get("payload", {}) if isinstance(result, Mapping) else {}
    clinical = clinical_state or payload.get("clinical_state") or {}
    guidance = clinical.get("runtime_guidance") if isinstance(clinical, Mapping) else {}
    return {
        "kind": result.get("kind"),
        "status": result.get("status"),
        "command": (result.get("provenance") or {}).get("command"),
        "finite_audit": result.get("finite_audit", {}),
        "clinical_regime": clinical.get("overall_regime") if isinstance(clinical, Mapping) else None,
        "clinical_stability_score": _safe_float(clinical.get("mean_psi")) if isinstance(clinical, Mapping) else None,
        "guidance_state": guidance.get("state") if isinstance(guidance, Mapping) else None,
        "claim_boundary": CLAIM_BOUNDARY,
    }


async def persist_runtime_result(
    *,
    user_id: int,
    result: Mapping[str, Any],
    label: str,
    source: str,
    domain: str = "medicine",
    clinical_state: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    """Create a disk bundle and record a DB row for a runtime result."""
    run_uid = str(uuid.uuid4())
    artifact_root = Path(settings.RUNTIME_ARTIFACT_ROOT).expanduser()
    artifact_root.mkdir(parents=True, exist_ok=True)

    bundle: dict[str, Any] = {}
    if create_run_bundle:
        bundle = create_run_bundle(result, root=artifact_root, label=f"{user_id}-{label}-{run_uid[:8]}")

    explanation = None
    if explanation_for_result:
        try:
            explanation = explanation_for_result(result)
        except Exception:
            explanation = None

    summary = _run_summary(result, clinical_state)
    artifacts = dict(bundle.get("artifacts", {}) if isinstance(bundle, Mapping) else {})
    if isinstance(bundle, Mapping):
        if bundle.get("manifest"):
            artifacts["manifest_json"] = bundle["manifest"]
        if bundle.get("run_dir"):
            artifacts["run_dir"] = bundle["run_dir"]
    finite = result.get("finite_audit", {}) if isinstance(result, Mapping) else {}
    payload = result.get("payload", {}) if isinstance(result, Mapping) else {}

    db_record: dict[str, Any] | None = None
    persistence_error = None
    try:
        async with AsyncSessionLocal() as session:
            row = await session.execute(
                text(
                    """
                    INSERT INTO runtime_runs (
                        run_uid, user_id, run_kind, command, domain, source,
                        status, clinical_regime, clinical_stability_score,
                        finite_audit, result_payload, explanation_payload,
                        manifest, artifact_root, result_path,
                        report_markdown_path, report_html_path, claim_boundary,
                        created_at
                    )
                    VALUES (
                        :run_uid, :user_id, :run_kind, :command, :domain, :source,
                        :status, :clinical_regime, :clinical_stability_score,
                        CAST(:finite_audit AS jsonb), CAST(:result_payload AS jsonb),
                        CAST(:explanation_payload AS jsonb), CAST(:manifest AS jsonb),
                        :artifact_root, :result_path, :report_markdown_path,
                        :report_html_path, :claim_boundary, NOW()
                    )
                    RETURNING id, run_uid, created_at
                    """
                ),
                {
                    "run_uid": run_uid,
                    "user_id": user_id,
                    "run_kind": result.get("kind"),
                    "command": (result.get("provenance") or {}).get("command"),
                    "domain": domain,
                    "source": source,
                    "status": result.get("status"),
                    "clinical_regime": summary["clinical_regime"],
                    "clinical_stability_score": summary["clinical_stability_score"],
                    "finite_audit": _json(finite),
                    "result_payload": _json(payload),
                    "explanation_payload": _json(explanation or {}),
                    "manifest": _json(bundle),
                    "artifact_root": str(artifact_root),
                    "result_path": artifacts.get("result_json"),
                    "report_markdown_path": artifacts.get("report_markdown"),
                    "report_html_path": artifacts.get("report_html"),
                    "claim_boundary": CLAIM_BOUNDARY,
                },
            )
            saved = row.mappings().first()
            if saved and summary.get("guidance_state") and summary["guidance_state"] != "balanced":
                severity = "critical" if "critical" in str(summary["guidance_state"]) else "warning"
                clinical = clinical_state or {}
                guidance = clinical.get("runtime_guidance") if isinstance(clinical, Mapping) else {}
                await session.execute(
                    text(
                        """
                        INSERT INTO runtime_alerts (
                            run_id, user_id, alert_type, severity, runtime_state,
                            message, actions, created_at
                        )
                        VALUES (
                            :run_id, :user_id, 'runtime_guidance', :severity,
                            :runtime_state, :message, CAST(:actions AS jsonb), NOW()
                        )
                        """
                    ),
                    {
                        "run_id": saved["id"],
                        "user_id": user_id,
                        "severity": severity,
                        "runtime_state": summary["guidance_state"],
                        "message": guidance.get("reason") if isinstance(guidance, Mapping) else None,
                        "actions": _json(guidance.get("actions", []) if isinstance(guidance, Mapping) else []),
                    },
                )
            await session.commit()
            db_record = dict(saved) if saved else None
    except Exception as exc:
        persistence_error = str(exc)

    return {
        "run_uid": run_uid,
        "db_record": db_record,
        "summary": summary,
        "bundle": bundle,
        "artifacts": artifacts,
        "persistence_error": persistence_error,
    }


async def list_runtime_runs(user_id: int, limit: int = 20) -> list[dict[str, Any]]:
    async with AsyncSessionLocal() as session:
        rows = await session.execute(
            text(
                """
                SELECT id, run_uid, run_kind, command, domain, source, status,
                       clinical_regime, clinical_stability_score,
                       finite_audit, manifest, created_at
                FROM runtime_runs
                WHERE user_id = :user_id
                ORDER BY created_at DESC
                LIMIT :limit
                """
            ),
            {"user_id": user_id, "limit": limit},
        )
        return [dict(row) for row in rows.mappings().all()]


async def get_runtime_run(user_id: int, run_uid: str) -> dict[str, Any] | None:
    async with AsyncSessionLocal() as session:
        rows = await session.execute(
            text(
                """
                SELECT *
                FROM runtime_runs
                WHERE user_id = :user_id AND run_uid = :run_uid
                LIMIT 1
                """
            ),
            {"user_id": user_id, "run_uid": run_uid},
        )
        row = rows.mappings().first()
        return dict(row) if row else None


async def record_runtime_review(
    *,
    user_id: int,
    run_uid: str,
    reviewer_user_id: int,
    review_status: str,
    review_note: str | None = None,
) -> dict[str, Any]:
    async with AsyncSessionLocal() as session:
        run = await session.execute(
            text("SELECT id FROM runtime_runs WHERE user_id = :user_id AND run_uid = :run_uid"),
            {"user_id": user_id, "run_uid": run_uid},
        )
        run_row = run.mappings().first()
        if not run_row:
            return {"error": "runtime run not found"}
        saved = await session.execute(
            text(
                """
                INSERT INTO runtime_reviews (
                    run_id, reviewer_user_id, review_status, review_note, reviewed_at
                )
                VALUES (:run_id, :reviewer_user_id, :review_status, :review_note, NOW())
                RETURNING id, reviewed_at
                """
            ),
            {
                "run_id": run_row["id"],
                "reviewer_user_id": reviewer_user_id,
                "review_status": review_status,
                "review_note": review_note,
            },
        )
        row = saved.mappings().first()
        await session.commit()
        return {"run_uid": run_uid, "review": dict(row) if row else None}
