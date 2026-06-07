import asyncio
import os
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RUNTIME_ROOT = PROJECT_ROOT.parent / "CDFD-Runtime"

os.environ.setdefault("ENGINE_PATH", str(RUNTIME_ROOT))
sys.path.append(str(PROJECT_ROOT))

from backend.services.engine_adapter import VurafyaAdapter
from backend.services.cdfd_bridge import ONTOLOGY_AVAILABLE, ontology

async def test_integration():
    print("=== Testing Vurafya-Engine Integration ===")
    adapter = VurafyaAdapter()

    # Use user_id 1 (Assuming there is a user with ID 1 in the seed data)
    user_id = 1

    print(f"\n1. Fetching model state for user {user_id}...")
    try:
        state = await adapter.get_patient_state(user_id)
        print(f"Success! Current Psi_s: {state.get('mean_psi', 1.0):.4f}")
        print(f"Regime: {state.get('overall_regime')}")
    except Exception as e:
        print(f"Failed to fetch patient state: {e}")
        return

    print(f"\n2. Running 50-step trajectory projection...")
    try:
        trajectory = await adapter.predict_trajectory(user_id, steps=50)
        print(f"Success! Predicted Psi_s at T=50: {trajectory[-1]['psi_s']:.4f}")
    except Exception as e:
        print(f"Failed to predict trajectory: {e}")

    print(f"\n3. Executing CDFL script...")
    script_path = PROJECT_ROOT / "backend/scripts/medical_rules.cdfl"
    try:
        script = script_path.read_text()
        results = await adapter.execute_dsl(user_id, script)
        print(f"Success! DSL Results:")
        for r in results:
            print(f"  - {r}")
    except Exception as e:
        print(f"Failed to execute DSL: {e}")

    print("\n4. Verifying Neo4j Ontology Sync...")
    try:
        if not ONTOLOGY_AVAILABLE or ontology is None:
            raise RuntimeError("Optional Neo4j graph helper is unavailable")
        # This will test driver initialization and basic connectivity
        fields = ontology.list_fields()
        print(f"Success! Neo4j Connection established. Fields found: {[f['id'] for f in fields]}")

        # Test sync for user
        sync_res = await adapter.sync_ontology(user_id)
        print(f"Success! Patient {user_id} synced to Neo4j. Nodes synced: {sync_res['nodes_synced']}")

        # Verify graph retrieval
        graph = ontology.get_patient_graph(f"patient_{user_id}")
        print(f"Success! Retrieved biological graph with {len(graph['systems'])} systems.")
    except Exception as e:
        print(f"Neo4j Verification Warning: {e}")
        print("Note: Ensure Neo4j container is running and BOLT port 7687 is open.")

    print("\n=== Integration Test Complete ===")

if __name__ == "__main__":
    asyncio.run(test_integration())
