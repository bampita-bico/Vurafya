from fastapi import APIRouter, Depends, Query
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import NotFoundError, ValidationError
from backend.services.barter_service import (
    list_goods, list_services, post_good, post_service,
    get_matches, initiate_trade, confirm_trade, complete_trade,
    rate_trade, get_my_trades, get_categories,
)
from backend.models.schemas import (
    PostGoodRequest, PostServiceRequest,
    InitiateTradeRequest, RateTradeRequest,
)

router = APIRouter()


# ── Categories ───────────────────────────────────────────────────────────────

@router.get("/categories")
async def categories(db=Depends(get_db)):
    return {"categories": await get_categories(db)}


# ── Browse goods & services ──────────────────────────────────────────────────

@router.get("/goods")
async def browse_goods(
    category: str = Query(default=None),
    min_value: float = Query(default=None),
    max_value: float = Query(default=None),
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    db=Depends(get_db),
):
    filters = {"category": category, "min_value": min_value,
               "max_value": max_value, "limit": limit, "offset": offset}
    return {"goods": await list_goods(db, filters)}


@router.get("/services")
async def browse_services(
    category: str = Query(default=None),
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    db=Depends(get_db),
):
    return {"services": await list_services(db, {"category": category, "limit": limit, "offset": offset})}


# ── Post listings ─────────────────────────────────────────────────────────────

@router.post("/goods")
async def post_good_listing(
    req: PostGoodRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await post_good(db, current_user["id"], req.model_dump())


@router.post("/services")
async def post_service_listing(
    req: PostServiceRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await post_service(db, current_user["id"], req.model_dump())


# ── Match suggestions ─────────────────────────────────────────────────────────

@router.get("/matches")
async def my_matches(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"matches": await get_matches(db, current_user["id"])}


# ── Trade lifecycle ───────────────────────────────────────────────────────────

@router.post("/trades")
async def start_trade(
    req: InitiateTradeRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await initiate_trade(db, current_user["id"], req.model_dump())
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.post("/trades/{trade_id}/confirm")
async def confirm(
    trade_id: int,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await confirm_trade(db, current_user["id"], trade_id)
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.post("/trades/{trade_id}/complete")
async def complete(
    trade_id: int,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await complete_trade(db, current_user["id"], trade_id)
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.post("/trades/{trade_id}/rate")
async def rate(
    trade_id: int,
    req: RateTradeRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await rate_trade(db, current_user["id"], trade_id, req.model_dump())
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.get("/trades")
async def my_trades(
    status: str = Query(default=None),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return {"trades": await get_my_trades(db, current_user["id"], status)}
