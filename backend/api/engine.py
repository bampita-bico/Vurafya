from fastapi import APIRouter, Body, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.services.engine_adapter import VurafyaAdapter
from backend.services.ai_service import generate_recommendations
from backend.services.cdfd_bridge import (
    CLAIM_BOUNDARY,
    doctor,
    list_domains,
    llm_provider_inventory,
    run_domain,
    runtime_info,
    runtime_status,
)
from backend.services.runtime_artifacts import (
    build_patient_envelope,
    get_runtime_run,
    list_runtime_runs,
    persist_runtime_result,
    record_runtime_review,
)

router = APIRouter()


class RuntimeReviewRequest(BaseModel):
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
    Returns the current predictive stability metrics for the logged-in patient.
    Exposes app-ready summaries of the CDFD Runtime model state.
    """
    adapter = VurafyaAdapter()
    try:
        state = await adapter.get_patient_state(current_user["id"])
        
        if state.get("status") == "engine_offline":
            raise HTTPException(status_code=503, detail="CDFD Runtime is currently unavailable.")

        envelope = build_patient_envelope(
            user_id=current_user["id"],
            kind="vurafya_patient_stability",
            command="vurafya engine stability",
            payload={"clinical_state": state},
        )
        run_record = await persist_runtime_result(
            user_id=current_user["id"],
            result=envelope,
            label="stability",
            source="api",
            clinical_state=state,
        )
            
        return {
            "user_id": current_user["id"],
            "clinical_stability_score": state.get("mean_psi"),
            "clinical_regime": state.get("overall_regime"),
            "runtime_guidance": state.get("runtime_guidance"),
            "runtime_envelope": envelope,
            "runtime_run": {
                "run_uid": run_record["run_uid"],
                "db_record": run_record["db_record"],
                "summary": run_record["summary"],
                "artifacts": run_record["artifacts"],
                "persistence_error": run_record["persistence_error"],
            },
            "finite_audit": envelope.get("finite_audit"),
            "provenance": envelope.get("provenance"),
            "claim_boundary": CLAIM_BOUNDARY,
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
        raise HTTPException(status_code=500, detail=f"Runtime analysis failed: {str(e)}")

@router.get("/trajectory")
async def get_stability_trajectory(
    steps: int = 50,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db)
):
    """
    Returns a CDFD Runtime trajectory projection for the patient.
    """
    adapter = VurafyaAdapter()
    try:
        state = await adapter.get_patient_state(current_user["id"])
        if state.get("status") == "engine_offline":
            raise HTTPException(status_code=503, detail="CDFD Runtime is currently unavailable.")
        trajectory = await adapter.predict_trajectory(current_user["id"], steps=steps)
        envelope = build_patient_envelope(
            user_id=current_user["id"],
            kind="vurafya_patient_trajectory",
            command=f"vurafya engine trajectory --steps {steps}",
            payload={
                "clinical_state": state,
                "forecast": trajectory,
                "steps": steps,
            },
            status="ok" if trajectory else "warning",
            warnings=[] if trajectory else ["trajectory returned no points"],
        )
        run_record = await persist_runtime_result(
            user_id=current_user["id"],
            result=envelope,
            label="trajectory",
            source="api",
            clinical_state=state,
        )
        return {
            "user_id": current_user["id"],
            "forecast": trajectory,
            "runtime_envelope": envelope,
            "runtime_run": {
                "run_uid": run_record["run_uid"],
                "db_record": run_record["db_record"],
                "summary": run_record["summary"],
                "artifacts": run_record["artifacts"],
                "persistence_error": run_record["persistence_error"],
            },
            "finite_audit": envelope.get("finite_audit"),
            "provenance": envelope.get("provenance"),
            "claim_boundary": CLAIM_BOUNDARY,
        }
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
    return runtime_status()


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
    if list_domains is None:
        _runtime_unavailable("domains")
    return list_domains()


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
    current_user: dict = Depends(get_current_user),
):
    run = await get_runtime_run(current_user["id"], run_uid)
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
        user_id=current_user["id"],
        run_uid=run_uid,
        reviewer_user_id=current_user["id"],
        review_status=req.review_status,
        review_note=req.review_note,
    )
    if result.get("error"):
        raise HTTPException(status_code=404, detail=result["error"])
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
    if run_domain is None:
        _runtime_unavailable("domain")
    result = run_domain(domain, payload, nx=nx, ny=ny, steps=steps)
    run_record = await persist_runtime_result(
        user_id=current_user["id"],
        result=result,
        label=f"domain-{domain}",
        source="api",
        domain=domain,
    )
    return {
        "result": result,
        "runtime_run": {
            "run_uid": run_record["run_uid"],
            "db_record": run_record["db_record"],
            "summary": run_record["summary"],
            "artifacts": run_record["artifacts"],
            "persistence_error": run_record["persistence_error"],
        },
    }


@router.post("/execute-dsl")
async def execute_custom_rules(
    script: str = Body(..., embed=True),
    current_user: dict = Depends(get_current_user)
):
    """
    Executes a custom CDFL rule script.
    """
    adapter = VurafyaAdapter()
    try:
        results = await adapter.execute_dsl(current_user["id"], script)
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Execution Error: {str(e)}")
