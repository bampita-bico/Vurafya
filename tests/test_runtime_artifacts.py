import asyncio
import json
from pathlib import Path

import pytest

from backend.services import runtime_artifacts
from backend.utils.database import DatabaseCompatSession


def test_sqlite_style_sql_is_bound_for_postgres():
    statement = DatabaseCompatSession._normalize_sql(
        "INSERT OR IGNORE INTO readings (created_at, value) VALUES (datetime('now'), ?)"
    )
    bound_statement, params = DatabaseCompatSession._bind_positional(statement, [42])

    assert "INSERT INTO readings" in bound_statement
    assert "NOW()" in bound_statement
    assert ":p0)" in bound_statement
    assert bound_statement.endswith("ON CONFLICT DO NOTHING")
    assert params == {"p0": 42}


def test_sqlite_style_sql_rejects_bad_parameter_counts():
    with pytest.raises(ValueError):
        DatabaseCompatSession._bind_positional("SELECT ? + ?", [1])

    with pytest.raises(ValueError):
        DatabaseCompatSession._bind_positional("SELECT ?", [1, 2])


def test_patient_envelope_is_finite_and_claim_bounded():
    result = runtime_artifacts.build_patient_envelope(
        user_id=7,
        kind="vurafya_patient_stability",
        command="vurafya engine stability",
        payload={
            "clinical_state": {
                "mean_psi": 1.01,
                "overall_regime": "stable",
                "runtime_guidance": {"state": "balanced", "actions": ["continue_monitoring"]},
            }
        },
    )

    assert result["kind"] == "vurafya_patient_stability"
    assert result["finite_audit"]["all_finite"] is True
    assert result["payload"]["user_id"] == 7
    assert result["payload"]["claim_boundary"]
    assert result["provenance"]["command"] == "vurafya engine stability"
    json.dumps(result, allow_nan=False)


def test_runtime_bundle_writes_without_database(monkeypatch, tmp_path):
    class FailingSession:
        async def __aenter__(self):
            raise RuntimeError("db disabled for unit test")

        async def __aexit__(self, exc_type, exc, tb):
            return False

    def failing_session_local():
        return FailingSession()

    monkeypatch.setattr(runtime_artifacts.settings, "RUNTIME_ARTIFACT_ROOT", str(tmp_path))
    monkeypatch.setattr(runtime_artifacts, "AsyncSessionLocal", failing_session_local)

    result = runtime_artifacts.build_patient_envelope(
        user_id=7,
        kind="vurafya_patient_stability",
        command="vurafya engine stability",
        payload={"clinical_state": {"mean_psi": 1.0, "overall_regime": "stable"}},
    )

    record = asyncio.run(
        runtime_artifacts.persist_runtime_result(
            user_id=7,
            result=result,
            label="unit",
            source="test",
            clinical_state={"mean_psi": 1.0, "overall_regime": "stable"},
        )
    )

    artifacts = record["artifacts"]
    assert record["persistence_error"] == "db disabled for unit test"
    assert Path(artifacts["result_json"]).exists()
    assert Path(artifacts["report_markdown"]).exists()
    assert Path(artifacts["report_html"]).exists()
    assert Path(artifacts["manifest_json"]).exists()
