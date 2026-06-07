from fastapi import APIRouter, Depends
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import NotFoundError, ValidationError
from backend.services.subscription_service import (
    get_plans, get_user_subscription, check_feature_access,
    get_all_features_for_user, upgrade_subscription,
)
from backend.models.schemas import UpgradeRequest

router = APIRouter()


@router.get("/plans")
async def list_plans(db=Depends(get_db)):
    plans = await get_plans(db)
    return {"plans": plans}


@router.get("/me")
async def my_subscription(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    sub = await get_user_subscription(db, current_user["id"])
    if not sub:
        return {"plan_name": "Afya Free", "tier": 1, "status": "active"}
    return sub


@router.get("/features")
async def list_features(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    features = await get_all_features_for_user(db, current_user["id"])
    return {"features": features}


@router.get("/features/{feature_key}/check")
async def check_feature(
    feature_key: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await check_feature_access(db, current_user["id"], feature_key)


@router.post("/upgrade")
async def upgrade(
    req: UpgradeRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await upgrade_subscription(db, current_user["id"], req.plan_id, req.billing_cycle)
    if "error" in result:
        raise NotFoundError("Plan", req.plan_id)
    return result
