from fastapi import APIRouter, Depends, Query
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import NotFoundError
from backend.services.ai_service import (
    get_recommendations, generate_recommendations, dismiss_recommendation,
)

router = APIRouter()


@router.get("")
async def my_recommendations(
    category: str = Query(default=None, description="nutrition | medication | monitoring | platform"),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    recs = await get_recommendations(db, current_user["id"], category)
    return {
        "recommendations": recs,
        "count": len(recs),
    }


@router.post("/generate")
async def generate(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return await generate_recommendations(db, current_user["id"])


@router.post("/{rec_id}/dismiss")
async def dismiss(
    rec_id: int,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await dismiss_recommendation(db, current_user["id"], rec_id)
