from fastapi import APIRouter, Depends, Query
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import NotFoundError, ValidationError
from backend.services.admin_service import (
    get_platform_summary, get_daily_revenue, get_current_month_revenue,
    get_revenue_vs_target, get_top_revenue_countries, get_monthly_summaries,
    get_country_revenue, get_revenue_targets,
    get_subscription_analytics, get_consultation_revenue, get_partner_performance,
    get_fraud_rules, get_fraud_alerts, resolve_fraud_alert,
    get_high_risk_users, get_users_requiring_kyc,
    get_social_good_summary, get_vulnerable_population_summary,
)
from backend.models.schemas import ResolveFraudAlertRequest

router = APIRouter()


# ── Platform health ──────────────────────────────────────────────────────────

@router.get("/summary")
async def platform_summary(db=Depends(get_db)):
    return await get_platform_summary(db)


# ── Revenue ──────────────────────────────────────────────────────────────────

@router.get("/revenue/daily")
async def daily_revenue(
    days: int = Query(30, le=365),
    db=Depends(get_db),
):
    return {"data": await get_daily_revenue(db, days)}


@router.get("/revenue/current-month")
async def current_month(db=Depends(get_db)):
    return await get_current_month_revenue(db)


@router.get("/revenue/vs-target")
async def vs_target(db=Depends(get_db)):
    return {"targets": await get_revenue_vs_target(db)}


@router.get("/revenue/by-country")
async def by_country(
    month: str = Query(default=None, description="YYYY-MM-01"),
    db=Depends(get_db),
):
    return {"countries": await get_country_revenue(db, month)}


@router.get("/revenue/top-countries")
async def top_countries(db=Depends(get_db)):
    return {"countries": await get_top_revenue_countries(db)}


@router.get("/revenue/monthly-summaries")
async def monthly_summaries(
    months: int = Query(12, le=36),
    db=Depends(get_db),
):
    return {"summaries": await get_monthly_summaries(db, months)}


@router.get("/revenue/targets")
async def revenue_targets(db=Depends(get_db)):
    return {"targets": await get_revenue_targets(db)}


# ── Subscriptions ─────────────────────────────────────────────────────────────

@router.get("/subscriptions/analytics")
async def subscription_analytics(db=Depends(get_db)):
    return {"plans": await get_subscription_analytics(db)}


# ── Consultations ─────────────────────────────────────────────────────────────

@router.get("/consultations/revenue")
async def consultation_revenue(db=Depends(get_db)):
    return {"breakdown": await get_consultation_revenue(db)}


# ── Partners ─────────────────────────────────────────────────────────────────

@router.get("/partners/performance")
async def partner_performance(db=Depends(get_db)):
    return {"partners": await get_partner_performance(db)}


# ── Fraud management ─────────────────────────────────────────────────────────

@router.get("/fraud/rules")
async def fraud_rules(db=Depends(get_db)):
    return {"rules": await get_fraud_rules(db)}


@router.get("/fraud/alerts")
async def fraud_alerts(
    status: str = Query(default=None, description="pending | reviewed | auto_cleared"),
    limit: int = Query(50, le=200),
    db=Depends(get_db),
):
    return {"alerts": await get_fraud_alerts(db, status, limit)}


@router.post("/fraud/alerts/{alert_id}/resolve")
async def resolve_alert(
    alert_id: int,
    req: ResolveFraudAlertRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await resolve_fraud_alert(db, alert_id, current_user["id"], req.model_dump())
    if "error" in result:
        raise NotFoundError("Alert", alert_id)
    return result


@router.get("/fraud/high-risk-users")
async def high_risk_users(db=Depends(get_db)):
    return {"users": await get_high_risk_users(db)}


@router.get("/compliance/kyc-required")
async def kyc_required(db=Depends(get_db)):
    return {"users": await get_users_requiring_kyc(db)}


# ── Social good ───────────────────────────────────────────────────────────────

@router.get("/social-good/summary")
async def social_good(db=Depends(get_db)):
    return {
        "current_month": await get_social_good_summary(db),
        "population": await get_vulnerable_population_summary(db),
    }
