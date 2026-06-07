from fastapi import APIRouter, Depends
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import NotFoundError, ValidationError
from backend.services.game_service import (
    get_avatar, get_character_classes, choose_class,
    get_available_quests, get_quest_detail, get_achievements,
    claim_daily_login, get_streaks,
)
from backend.services.subscription_service import get_user_tier
from backend.models.schemas import ChooseClassRequest

router = APIRouter()


@router.get("/avatar")
async def my_avatar(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    avatar = await get_avatar(db, current_user["id"])
    if not avatar:
        raise NotFoundError("Avatar", current_user["id"])
    return avatar


@router.get("/classes")
async def list_classes(db=Depends(get_db)):
    classes = await get_character_classes(db)
    return {"classes": classes}


@router.put("/avatar/class")
async def select_class(
    req: ChooseClassRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await choose_class(db, current_user["id"], req.class_id)
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.get("/quests")
async def list_quests(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    tier = await get_user_tier(db, current_user["id"])
    quests = await get_available_quests(db, current_user["id"], tier)
    return {"quests": quests}


@router.get("/quests/{quest_id}")
async def quest_detail(quest_id: int, db=Depends(get_db)):
    result = await get_quest_detail(db, quest_id)
    if not result:
        raise NotFoundError("Quest", quest_id)
    return result


@router.get("/achievements")
async def list_achievements(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    tier = await get_user_tier(db, current_user["id"])
    achievements = await get_achievements(db, current_user["id"], tier)
    return {"achievements": achievements}


@router.post("/daily-login")
async def daily_login(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return await claim_daily_login(db, current_user["id"])


@router.get("/streaks")
async def my_streaks(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return await get_streaks(db, current_user["id"])
