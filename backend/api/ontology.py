from fastapi import APIRouter, Depends, HTTPException
from backend.utils.dependencies import get_current_user
from backend.services.cdfd_bridge import ONTOLOGY_AVAILABLE, ontology

router = APIRouter()

@router.get("/graph")
async def get_patient_biological_graph(
    current_user: dict = Depends(get_current_user)
):
    """
    Returns the biological graph for the patient, showing systems,
    biomarkers, and latest stability states.
    Uses JSON Graph Format (JGF) mapping from the optional graph layer.
    """
    if not ONTOLOGY_AVAILABLE:
        raise HTTPException(status_code=503, detail="Clinical Graph module is offline.")
        
    patient_id = f"patient_{current_user['id']}"
    try:
        graph = ontology.get_patient_graph(patient_id)
        return {
            "patient_id": patient_id,
            "format": "JGF",
            "graph": graph
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch clinical graph: {str(e)}")

@router.get("/influence")
async def get_system_influence_map(
    max_hops: int = 3,
    current_user: dict = Depends(get_current_user)
):
    """
    Returns the influence paths between biological systems (e.g. Metabolic -> Renal).
    """
    if not ONTOLOGY_AVAILABLE:
        raise HTTPException(status_code=503, detail="Clinical Graph module is offline.")
        
    patient_id = f"patient_{current_user['id']}"
    try:
        influence = ontology.cross_system_influence(patient_id, max_hops=max_hops)
        return influence
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch influence map: {str(e)}")

@router.get("/overload-analysis")
async def explain_clinical_overload(
    threshold: float = 1.2,
    current_user: dict = Depends(get_current_user)
):
    """
    Identifies which systems are overloaded and which biomarkers are driving it.
    Adds app-facing labels to the runtime's flux and constraint drivers.
    """
    if not ONTOLOGY_AVAILABLE:
        raise HTTPException(status_code=503, detail="Clinical Graph module is offline.")
        
    patient_id = f"patient_{current_user['id']}"
    try:
        analysis = ontology.explain_overload(patient_id, psi_threshold=threshold)
        
        # Abstract terminology for the frontend
        if "drivers" in analysis:
            for driver in analysis["drivers"]:
                if driver.get("role") == "constraint":
                    driver["clinical_role"] = "Constraint Driver"
                elif driver.get("role") == "flux":
                    driver["clinical_role"] = "Flux Driver"
                    
        return analysis
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Overload analysis failed: {str(e)}")
