from fastapi import APIRouter, Body, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.services.engine_adapter import VurafyaAdapter
from backend.services.ai_service import generate_recommendations
from backend.services.cdfd_bridge import (
    CLAIM_BOUNDARY,
    DOMAIN_SURFACES_MESSAGE,
    doctor,
    gallery,
    llm_provider_inventory,
    runtime_info,
    runtime_status,
)
from backend.services.runtime_artifacts import (
    build_patient_envelope,
    get_runtime_run_for_reviewer,
    get_runtime_run,
    list_runtime_runs,
    persist_runtime_result,
    record_runtime_review,
)
from backend.config import settings

router = APIRouter()


class RuntimeReviewRequest(BaseModel):
    patient_user_id: int = Field(gt=0)
    review_status: str = Field(pattern="^(reviewed|acknowledged|needs_follow_up|dismissed)$")
    review_note: str | None = Field(default=None, max_length=2000)


def _runtime_unavailable(name: str):
    raise HTTPException(status_code=503, detail=f"CDFD Runtime {name} surface is unavailable.")


@router.get("/stability")
async def get_patient_stability(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db)
):
    """
    Local Vurafya predictive stability from biometrics/labs.
    CDFD Runtime is optional and does not gate this endpoint.
    """
    adapter = VurafyaAdapter()
    try:
        state = await adapter.get_patient_state(current_user["id"])

        envelope = build_patient_envelope(
            user_id=current_user["id"],
            kind="vurafya_patient_stability",
            command="vurafya local stability",
            payload={"clinical_state": state},
        )
        run_record = None
        if settings.RUNTIME_PERSIST_ON_READ:
            run_record = await persist_runtime_result(
                user_id=current_user["id"],
                result=envelope,
                label="stability",
                source="api",
                clinical_state=state,
            )
            
        return {
            "user_id": current_user["id"],
            "prediction_engine": state.get("prediction_engine", "vurafya_local"),
            "clinical_stability_score": state.get("mean_psi"),
            "clinical_regime": state.get("overall_regime"),
            "runtime_guidance": state.get("runtime_guidance"),
            "runtime_envelope": envelope,
            "runtime_run": run_record,
            "finite_audit": envelope.get("finite_audit"),
            "provenance": envelope.get("provenance"),
            "claim_boundary": state.get("claim_boundary") or CLAIM_BOUNDARY,
            "system_analysis": {
                "renal": {
                    "score": state.get("renal_psi"),
                    "semantic_regime": state.get("regimes", {}).get("renal"),
                    "runtime_guidance": state.get("runtime_guidance_by_system", {}).get("renal"),
                },
                "cardiovascular": {
                    "score": state.get("cardio_psi"),
                    "semantic_regime": state.get("regimes", {}).get("cardio"),
                    "runtime_guidance": state.get("runtime_guidance_by_system", {}).get("cardio"),
                },
                "metabolic": {
                    "score": state.get("metabolic_psi"),
                    "semantic_regime": state.get("regimes", {}).get("metabolic"),
                    "runtime_guidance": state.get("runtime_guidance_by_system", {}).get("metabolic"),
                }
            },
            "timestamp": state.get("t")
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Stability analysis failed: {str(e)}")


@router.get("/trajectory")
async def get_stability_trajectory(
    steps: int = 50,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db)
):
    """
    Local trajectory projection (optional Runtime kernel only if VURAFYA_USE_RUNTIME_KERNEL=1).
    """
    adapter = VurafyaAdapter()
    try:
        state = await adapter.get_patient_state(current_user["id"])
        trajectory = await adapter.predict_trajectory(current_user["id"], steps=steps)
        envelope = build_patient_envelope(
            user_id=current_user["id"],
            kind="vurafya_patient_trajectory",
            command=f"vurafya local trajectory --steps {steps}",
            payload={
                "clinical_state": state,
                "forecast": trajectory,
                "steps": steps,
            },
            status="ok" if trajectory else "warning",
            warnings=[] if trajectory else ["trajectory returned no points"],
        )
        run_record = None
        if settings.RUNTIME_PERSIST_ON_READ:
            run_record = await persist_runtime_result(
                user_id=current_user["id"],
                result=envelope,
                label="trajectory",
                source="api",
                clinical_state=state,
            )
        return {
            "user_id": current_user["id"],
            "prediction_engine": state.get("prediction_engine", "vurafya_local"),
            "forecast": trajectory,
            "runtime_envelope": envelope,
            "runtime_run": run_record,
            "finite_audit": envelope.get("finite_audit"),
            "provenance": envelope.get("provenance"),
            "claim_boundary": state.get("claim_boundary") or CLAIM_BOUNDARY,
        }
    except ValueError as e:
        raise HTTPException(status_code=409, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Trajectory projection failed: {str(e)}")


@router.post("/analyze")
async def trigger_analysis(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db)
):
    """
    Manually triggers a fresh model analysis and generates app-layer summaries.
    """
    return await generate_recommendations(db, current_user["id"])


@router.get("/runtime-status")
async def get_runtime_status():
    status = runtime_status()
    status["vurafya_prediction"] = {
        "primary": "vurafya_local",
        "runtime_required": False,
        "optional_kernel_env": "VURAFYA_USE_RUNTIME_KERNEL",
    }
    return status


@router.get("/doctor")
async def get_runtime_doctor():
    if doctor is None:
        _runtime_unavailable("doctor")
    return doctor()


@router.get("/info")
async def get_runtime_info():
    if runtime_info is None:
        _runtime_unavailable("info")
    return runtime_info()


@router.get("/domains")
async def get_runtime_domains():
    """Retired with slim CDFD Runtime (no domain adapters)."""
    raise HTTPException(
        status_code=410,
        detail={
            "error": "domains_retired",
            "message": DOMAIN_SURFACES_MESSAGE,
            "alternatives": ["GET /api/v1/engine/gallery", "GET /api/v1/engine/doctor", "GET /api/v1/engine/info"],
        },
    )


@router.get("/gallery")
async def get_runtime_gallery(
    nx: int = Query(4, ge=1, le=32),
    ny: int = Query(4, ge=1, le=32),
    steps: int = Query(1, ge=1, le=20),
):
    """Optional slim Runtime CDFL smoke gallery."""
    if gallery is None:
        _runtime_unavailable("gallery")
    return gallery(nx=nx, ny=ny, steps=steps, include_cdfl=True)


@router.get("/llm/providers")
async def get_llm_provider_inventory():
    if llm_provider_inventory is None:
        _runtime_unavailable("LLM provider inventory")
    return llm_provider_inventory()


@router.get("/runs")
async def my_runtime_runs(
    limit: int = Query(20, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    try:
        return {"runs": await list_runtime_runs(current_user["id"], limit=limit)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Runtime run listing failed: {str(e)}")


@router.get("/runs/{run_uid}")
async def runtime_run_detail(
    run_uid: str,
    patient_user_id: int | None = Query(default=None, gt=0),
    current_user: dict = Depends(get_current_user),
):
    if patient_user_id is None or patient_user_id == current_user["id"]:
        run = await get_runtime_run(current_user["id"], run_uid)
    else:
        run = await get_runtime_run_for_reviewer(
            patient_user_id=patient_user_id,
            reviewer_user_id=current_user["id"],
            run_uid=run_uid,
        )
    if not run:
        raise HTTPException(status_code=404, detail="Runtime run not found")
    return run


@router.post("/runs/{run_uid}/review")
async def review_runtime_run(
    run_uid: str,
    req: RuntimeReviewRequest,
    current_user: dict = Depends(get_current_user),
):
    result = await record_runtime_review(
        patient_user_id=req.patient_user_id,
        run_uid=run_uid,
        reviewer_user_id=current_user["id"],
        review_status=req.review_status,
        review_note=req.review_note,
    )
    if result.get("error"):
        status_code = 404 if result["error"] == "runtime run not found" else 403
        raise HTTPException(status_code=status_code, detail=result["error"])
    return result


@router.post("/domain/{domain}")
async def run_runtime_domain(
    domain: str,
    payload: dict = Body(default_factory=dict),
    nx: int = Query(4, ge=1, le=64),
    ny: int = Query(4, ge=1, le=64),
    steps: int = Query(4, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    """Retired with slim CDFD Runtime (no domain adapters)."""
    raise HTTPException(
        status_code=410,
        detail={
            "error": "domains_retired",
            "domain": domain,
            "message": DOMAIN_SURFACES_MESSAGE,
            "alternatives": ["POST /api/v1/engine/execute-dsl", "GET /api/v1/engine/gallery"],
        },
    )


@router.post("/execute-dsl")
async def execute_custom_rules(
    script: str = Body(..., embed=True),
    current_user: dict = Depends(get_current_user)
):
    """
    Optional CDFL rule script execution (requires Runtime DSL).
    """
    adapter = VurafyaAdapter()
    try:
        results = await adapter.execute_dsl(current_user["id"], script)
        return {"results": results, "optional_surface": "cdfl"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Execution Error: {str(e)}")
