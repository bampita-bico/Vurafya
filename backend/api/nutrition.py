from fastapi import APIRouter, Depends, Query
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import NotFoundError
from backend.services.nutrition_service import (
    search_foods, get_food_detail, get_food_pral, get_food_portions,
    create_meal, get_meals_for_date, get_meal_detail,
    get_daily_dashboard, get_weekly_trends,
)
from backend.models.schemas import MealCreateRequest
from datetime import date

router = APIRouter()


@router.get("/foods/search")
async def search(
    q: str = Query(..., min_length=1),
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    db=Depends(get_db),
):
    return await search_foods(db, q, limit, offset)


@router.get("/foods/{food_id}")
async def food_detail(food_id: int, db=Depends(get_db)):
    result = await get_food_detail(db, food_id)
    if not result:
        raise NotFoundError("Food", food_id)
    return result


@router.get("/foods/{food_id}/pral")
async def food_pral(food_id: int, db=Depends(get_db)):
    result = await get_food_pral(db, food_id)
    if not result:
        raise NotFoundError("PRAL data for food", food_id)
    return result


@router.get("/foods/{food_id}/portions")
async def food_portions(food_id: int, db=Depends(get_db)):
    return {"portions": await get_food_portions(db, food_id)}


@router.post("/meals")
async def log_meal(
    req: MealCreateRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await create_meal(db, current_user["id"], req.model_dump())


@router.get("/meals")
async def list_meals(
    meal_date: str = Query(default=None),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    if not meal_date:
        meal_date = date.today().isoformat()
    meals = await get_meals_for_date(db, current_user["id"], meal_date)
    return {"date": meal_date, "meals": meals}


@router.get("/meals/{meal_id}")
async def meal_detail(
    meal_id: int,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await get_meal_detail(db, meal_id, current_user["id"])
    if not result:
        raise NotFoundError("Meal", meal_id)
    return result


@router.get("/dashboard/daily")
async def daily(
    meal_date: str = Query(default=None),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    if not meal_date:
        meal_date = date.today().isoformat()
    return await get_daily_dashboard(db, current_user["id"], meal_date)


@router.get("/dashboard/weekly")
async def weekly(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    trends = await get_weekly_trends(db, current_user["id"])
    return {"trends": trends}
