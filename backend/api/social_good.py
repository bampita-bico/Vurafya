from fastapi import APIRouter, Depends
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import ValidationError
from backend.services.social_good_service import (
    register_vulnerable, get_vulnerable_profile,
    get_social_good_summary, get_social_good_goals, get_impact_history,
)
from backend.models.schemas import RegisterVulnerableRequest

router = APIRouter()


# ── Vulnerable registration ───────────────────────────────────────────────────

@router.post("/register")
async def register(
    req: RegisterVulnerableRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await register_vulnerable(db, current_user["id"], req.model_dump())


@router.get("/profile")
async def my_profile(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    profile = await get_vulnerable_profile(db, current_user["id"])
    if not profile:
        return {"registered": False}
    return profile


# ── Impact ────────────────────────────────────────────────────────────────────

@router.get("/summary")
async def summary(db=Depends(get_db)):
    return await get_social_good_summary(db)


@router.get("/goals")
async def goals(db=Depends(get_db)):
    return {"goals": await get_social_good_goals(db)}


@router.get("/my-impact")
async def my_impact(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"impact": await get_impact_history(db, current_user["id"])}
