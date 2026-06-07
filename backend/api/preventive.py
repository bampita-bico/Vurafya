from fastapi import APIRouter, Depends, Query
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import NotFoundError, ValidationError
from backend.services.preventive_service import (
    evaluate_health_rules, get_health_rules,
    get_risk_logs, log_risk_assessment,
    get_user_conditions, get_all_conditions,
    get_condition_nutrition_rules, get_user_nutrition_rules,
    get_nutrient_targets, upsert_nutrient_target,
    get_ckd_status, get_dynamic_food_recommendations,
    get_health_snapshot,
)
from backend.models.schemas import NutrientTargetRequest, LogRiskRequest

router = APIRouter()


# ── Health snapshot (all-in-one) ──────────────────────────────────────────────

@router.get("/snapshot")
async def health_snapshot(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return await get_health_snapshot(db, current_user["id"])


# ── Health rules ──────────────────────────────────────────────────────────────

@router.get("/rules")
async def health_rules(
    category: str = Query(default=None),
    db=Depends(get_db),
):
    return {"rules": await get_health_rules(db, category)}


@router.get("/rules/evaluate")
async def evaluate_rules(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    triggered = await evaluate_health_rules(db, current_user["id"])
    return {
        "user_id": current_user["id"],
        "triggered_count": len(triggered),
        "critical": [r for r in triggered if r["severity"] == "critical"],
        "warnings": [r for r in triggered if r["severity"] == "warning"],
        "all": triggered,
    }


# ── Risk assessments ──────────────────────────────────────────────────────────

@router.get("/risk-logs")
async def risk_logs(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"logs": await get_risk_logs(db, current_user["id"])}


@router.post("/risk-logs")
async def log_risk(
    req: LogRiskRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await log_risk_assessment(db, current_user["id"], req.model_dump())


# ── Medical conditions ────────────────────────────────────────────────────────

@router.get("/conditions")
async def all_conditions(db=Depends(get_db)):
    return {"conditions": await get_all_conditions(db)}


@router.get("/conditions/mine")
async def my_conditions(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"conditions": await get_user_conditions(db, current_user["id"])}


@router.get("/conditions/{condition_id}/nutrition-rules")
async def condition_nutrition(condition_id: int, db=Depends(get_db)):
    return {"rules": await get_condition_nutrition_rules(db, condition_id)}


@router.get("/nutrition-rules")
async def my_nutrition_rules(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"rules": await get_user_nutrition_rules(db, current_user["id"])}


# ── Nutrient targets ──────────────────────────────────────────────────────────

@router.get("/nutrient-targets")
async def nutrient_targets(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"targets": await get_nutrient_targets(db, current_user["id"])}


@router.put("/nutrient-targets")
async def set_nutrient_target(
    req: NutrientTargetRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await upsert_nutrient_target(db, current_user["id"], req.model_dump())


# ── CKD ───────────────────────────────────────────────────────────────────────

@router.get("/ckd/status")
async def ckd_status(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    result = await get_ckd_status(db, current_user["id"])
    if not result:
        return {"message": "No CKD lab data found. Start logging potassium, phosphorus, and eGFR."}
    return result


@router.get("/ckd/food-recommendations")
async def ckd_food_recs(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"recommendations": await get_dynamic_food_recommendations(db, current_user["id"])}
