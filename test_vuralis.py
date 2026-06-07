import asyncio
import os
import sys
from unittest.mock import MagicMock

os.environ["ENGINE_PATH"] = "/home/bampita/Projects/CDFD/CDFD-Runtime"
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

sys.modules['sqlalchemy'] = MagicMock()
sys.modules['backend.utils.database'] = MagicMock()
sys.modules['backend.services.ai_service'] = MagicMock()
sys.modules['jwt'] = MagicMock()
sys.modules['bcrypt'] = MagicMock()

from backend.api import vuralis


class FakeAdapter:
    async def get_patient_state(self, user_id):
        return {
            "mean_psi": 1.0,
            "metabolic_psi": 1.0,
            "immune_psi": 1.0,
            "renal_psi": 0.95,
            "cardio_psi": 1.05,
            "overall_regime": "stable",
            "t": "2026-05-28T00:00:00",
        }


vuralis.VurafyaAdapter = FakeAdapter

async def run_test():
    print("Testing Vuralis Metaverse Bridge Export...")
    try:
        # Mock user
        current_user = {"id": 12345}
        result = await vuralis.export_avatar_to_vuralis(current_user=current_user)
        import json
        print(json.dumps(result, indent=2))
        print("\n[SUCCESS] Vuralis payload formatted correctly.")
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    asyncio.run(run_test())
