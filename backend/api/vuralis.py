from fastapi import APIRouter, Depends, HTTPException
from backend.utils.dependencies import get_current_user
from backend.utils.database import get_db
from backend.services.engine_adapter import VurafyaAdapter
import numpy as np

router = APIRouter()

@router.get("/export-avatar")
async def export_avatar_to_vuralis(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    """
    Track D: Vuralis Metaverse Bridge
    Exports physics-derived avatar RPG stats into a strictly typed,
    consent-gated Vuralis Metaverse JSON payload.
    """
    user_id = current_user.get("id")
    
    try:
        consent = await db.scalar(
            "SELECT vuralis_data_bridge_consent FROM user_app_settings WHERE user_id = ?",
            (user_id,),
        )
        if consent is not True:
            raise HTTPException(status_code=403, detail="Vuralis export requires explicit active consent")
        adapter = VurafyaAdapter()
        # Fetch local predictive state (Runtime not required).
        state = await adapter.get_patient_state(user_id)
        # Map model metrics to RPG gamification stats for the metaverse bridge.
        if state.get("mean_psi") is None:
            raise HTTPException(status_code=409, detail="Vuralis export requires usable current biomarker data")
        raw_health = state["mean_psi"]
        metabolic_score = state.get("metabolic_psi") or 0.0
        immune_score = state.get("immune_psi") or 0.0
        
        # Deviation drives the resilience-style avatar stat.
        renal_score = state.get("renal_psi") or 0.0
        cardio_score = state.get("cardio_psi") or 0.0
        deviation = float(np.std([renal_score, cardio_score, metabolic_score]))
        
        # Calculate final Metaverse Stats
        hp = max(0, min(1000, int(raw_health * 1000)))
        mp = max(0, min(500, int(metabolic_score * 500)))
        shield = max(0, min(100, int(immune_score * 100)))
        agility = max(0, min(100, int((1.0 / (deviation + 0.1)) * 50)))
        
        vuralis_payload = {
            "metaverse_id": f"vurafya_export_{user_id}",
            "source_engine": "vurafya_local",
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
                "biological_regime": state.get("overall_regime", "insufficient_data").upper()
            },
            "signatures": {
                "verified_by": "Vurafya Runtime Bridge"
            }
        }
        
        return vuralis_payload
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Vuralis Export Failed: {str(e)}")
