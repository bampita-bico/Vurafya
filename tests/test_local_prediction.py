"""The local prediction path must work without optional CDFD Runtime surfaces."""
import asyncio

from backend.services import engine_adapter
from backend.services.engine_adapter import _band, _local_trajectory, VurafyaAdapter, USE_RUNTIME_KERNEL


def test_band_thresholds():
    assert _band(1.0) == "stable"
    assert _band(1.3) == "overload"
    assert _band(0.5) == "constrained"


def test_local_trajectory_shape():
    rows = _local_trajectory(1.0, "stable", steps=10)
    assert len(rows) == 10
    assert rows[0]["source"] == "vurafya_local"
    assert "psi_s" in rows[-1]
    assert rows[-1]["regime"] in {"stable", "overload", "constrained"}


def test_local_trajectory_is_reproducible_across_processes():
    assert _local_trajectory(1.0, "stable", steps=10) == _local_trajectory(1.0, "stable", steps=10)


def test_adapter_defaults_to_local_kernel_off():
    assert USE_RUNTIME_KERNEL is False
    adapter = VurafyaAdapter()
    assert adapter.kernel is None


def test_missing_biometrics_are_not_presented_as_stable(monkeypatch):
    class EmptySession:
        async def __aenter__(self):
            return self

        async def __aexit__(self, exc_type, exc, tb):
            return False

        async def execute(self, *_args, **_kwargs):
            class Result:
                def mappings(self):
                    return self

                def first(self):
                    return None

            return Result()

    monkeypatch.setattr(engine_adapter, "AsyncSessionLocal", EmptySession)
    state = asyncio.run(VurafyaAdapter().get_patient_state(7))

    assert state["status"] == "insufficient_data"
    assert state["mean_psi"] is None
    assert state["overall_regime"] == "insufficient_data"
    assert state["runtime_guidance"]["state"] == "insufficient_data"
