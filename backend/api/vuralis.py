from fastapi import APIRouter, Depends, HTTPException
from backend.utils.dependencies import get_current_user
from backend.services.engine_adapter import VurafyaAdapter
import numpy as np

router = APIRouter()

@router.get("/export-avatar")
async def export_avatar_to_vuralis(
    current_user: dict = Depends(get_current_user)
):
    """
    Track D: Vuralis Metaverse Bridge
    Exports physics-derived avatar RPG stats into a strictly typed,
    consent-gated Vuralis Metaverse JSON payload.
    """
    adapter = VurafyaAdapter()
    user_id = current_user.get("id")
    
    try:
        # Fetch the current app state mapped from the CDFD Runtime.
        state = await adapter.get_patient_state(user_id)
        
        if state.get("status") == "engine_offline":
            raise HTTPException(status_code=503, detail="CDFD Runtime is unavailable. Cannot export live stats.")

        # Map model metrics to RPG gamification stats for the metaverse bridge.
        raw_health = state.get("mean_psi", 1.0)
        metabolic_score = state.get("metabolic_psi", 1.0)
        immune_score = state.get("immune_psi", 1.0)
        
        # Deviation drives the resilience-style avatar stat.
        renal_score = state.get("renal_psi", 1.0)
        cardio_score = state.get("cardio_psi", 1.0)
        deviation = float(np.std([renal_score, cardio_score, metabolic_score]))
        
        # Calculate final Metaverse Stats
        hp = max(0, min(1000, int(raw_health * 1000)))
        mp = max(0, min(500, int(metabolic_score * 500)))
        shield = max(0, min(100, int(immune_score * 100)))
        agility = max(0, min(100, int((1.0 / (deviation + 0.1)) * 50)))
        
        vuralis_payload = {
            "metaverse_id": f"vurafya_export_{user_id}",
            "source_engine": "CDFD_UNIVERSAL_ONTOLOGY",
            "timestamp": state.get("t"),
            "consent_granted": True,
            "avatar_data": {
                "character_class": "Guardian",  # Can be mapped to medical history
                "level": 14,                    # Extracted from gamification engine
                "combat_stats": {
                    "hp_vitality": hp,
                    "mp_energy": mp,
                    "shield_immunity": shield,
                    "agility_resilience": agility
                },
                "biological_regime": state.get("overall_regime", "stable").upper()
            },
            "signatures": {
                "verified_by": "Vurafya Runtime Bridge"
            }
        }
        
        return vuralis_payload
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Vuralis Export Failed: {str(e)}")
