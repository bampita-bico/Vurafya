import asyncio
import os
import sys
from unittest.mock import MagicMock

# Setup environment to mimic FastAPI starting up
os.environ["ENGINE_PATH"] = "/home/bampita/Projects/CDFD/CDFD-Runtime"
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Stub out SQLAlchemy to avoid installation issues
sys.modules['sqlalchemy'] = MagicMock()
sys.modules['backend.utils.database'] = MagicMock()
sys.modules['backend.services.ai_service'] = MagicMock()

try:
    from backend.services.engine_adapter import VurafyaAdapter

    # Create a dummy adapter instance
    print("Initializing Adapter...")
    adapter = VurafyaAdapter()

    # Let's test the state engine offline fallback or successful load
    print("\n[Engine Initialization]")
    print(f"CDFD Runtime Active: {adapter.kernel is not None}")

    if adapter.kernel:
        # Mock get_patient_state to return something for testing without DB
        async def mock_get_patient_state(user_id):
            return {
                "renal_psi": 0.9,
                "cardio_psi": 1.0,
                "metabolic_psi": 1.1,
                "mean_psi": 1.0,
                "overall_regime": "stable",
                "raw": {
                    "egfr": 90.0,
                    "creatinine": 1.0,
                    "pulse": 70.0,
                    "sbp": 120.0,
                    "glucose": 100.0
                }
            }

        adapter.get_patient_state = mock_get_patient_state

        print("\n[Physics-Based Trajectory Check]")
        print("Running trajectory for 10 steps...")
        trajectory = asyncio.run(adapter.predict_trajectory(1, steps=10))
        print(f"Trajectory length: {len(trajectory)}")
        if trajectory:
            print(f"Initial Psi: {trajectory[0]['psi']:.4f}")
            print(f"Final Psi: {trajectory[-1]['psi']:.4f}")

        print("\n[DSL Execution Check]")
        sample_script = """
SET domain: medicine
SYSTEM Renal { flux: Patient.filtration_flux; constraint: Patient.renal_constraint }
RULE Review { IF psi > 1.3 ACTION mark_for_review }
"""
        print("Executing DSL script...")
        results = asyncio.run(adapter.execute_dsl(1, sample_script))
        print(f"DSL Results: {results}")

except Exception as e:
    import traceback
    traceback.print_exc()
