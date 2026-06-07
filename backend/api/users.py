from fastapi import APIRouter, Depends
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import NotFoundError
from backend.services.user_service import (
    get_complete_profile, update_profile, submit_health_declaration, get_user_conditions,
)
from backend.models.schemas import ProfileUpdate, HealthDeclarationRequest

router = APIRouter()


@router.get("/me")
async def get_me(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    profile = await get_complete_profile(db, current_user["id"])
    if not profile:
        raise NotFoundError("User", current_user["id"])
    return profile


@router.put("/me/profile")
async def update_my_profile(
    data: ProfileUpdate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    await update_profile(db, current_user["id"], data.model_dump(exclude_none=True))
    return {"status": "updated"}


@router.get("/me/conditions")
async def get_my_conditions(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    conditions = await get_user_conditions(db, current_user["id"])
    return {"conditions": conditions}


@router.post("/me/health-declaration")
async def declare_health(
    req: HealthDeclarationRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await submit_health_declaration(
        db, current_user["id"], req.condition_id,
        req.stage, req.severity, req.declaration_source,
    )
    if "error" in result:
        raise NotFoundError("Condition", req.condition_id)
    return result


@router.get("/conditions")
async def list_conditions(db=Depends(get_db)):
    cursor = await db.execute(
        "SELECT id, condition_name, category, description, icd_10_code FROM medical_conditions ORDER BY category, condition_name"
    )
    conditions = await cursor.fetchall()
    return {"conditions": conditions}


@router.get("/health-declaration/flow")
async def get_declaration_flow(db=Depends(get_db)):
    cursor = await db.execute(
        "SELECT * FROM condition_onboarding_flow ORDER BY sequence_order"
    )
    questions = await cursor.fetchall()
    return {"questions": questions}
