"""
FlutterWave webhook + payment initiation endpoints.
Flutter app calls POST /api/v1/flutterwave/initiate to get a payment link.
FlutterWave calls POST /api/v1/flutterwave/webhook after payment completes.
"""
import hashlib
import hmac
import json
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, Request, Header, HTTPException
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import ValidationError
from backend.models.schemas import FlutterwaveInitiateRequest
from backend.config import settings

router = APIRouter()


def _now():
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# Initiate a FlutterWave payment
# Flutter app calls this, gets back a payment link to open in-app browser.
# ---------------------------------------------------------------------------

@router.post("/initiate")
async def initiate_payment(
    req: FlutterwaveInitiateRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    now = _now()
    user_id = current_user["id"]

    # Get user email for FLW
    cursor = await db.execute("SELECT email, username FROM users WHERE id = ?", (user_id,))
    user = await cursor.fetchone()
    if not user:
        raise ValidationError("User not found")

    tx_ref = f"VFY-{user_id}-{int(datetime.now(timezone.utc).timestamp())}"

    # Log to unified_payment_ledger as 'pending'
    cursor = await db.execute(
        """INSERT INTO unified_payment_ledger
           (transaction_type, transaction_reference, payer_user_id,
            payee_type, payee_id, total_amount_ugx,
            payment_method, is_hybrid_payment,
            fiat_amount_ugx, fiat_currency_code,
            payment_status, initiated_at, created_at, updated_at)
           VALUES (?,?,?,?,?,?,?,0,?,?,
                   'pending',?,?,?)""",
        (
            req.transaction_type,
            tx_ref,
            user_id,
            req.payee_type,
            req.payee_id,
            req.amount_ugx,
            "mobile_money",
            req.amount_ugx,
            req.currency or "UGX",
            now, now, now,
        ),
    )
    ledger_id = cursor.lastrowid
    await db.commit()

    # Log to payment_gateways_log
    await db.execute(
        """INSERT INTO payment_gateways_log
           (user_id, order_id, gateway_name, transaction_ref,
            amount_ugx, currency, status, processed_at)
           VALUES (?,?,?,?,?,?,?,?)""",
        (user_id, ledger_id, "flutterwave", tx_ref,
         req.amount_ugx, req.currency or "UGX", "initiated", now),
    )
    await db.commit()

    # Build FlutterWave payload for Flutter SDK
    flw_payload = {
        "tx_ref": tx_ref,
        "amount": str(req.amount_ugx),
        "currency": req.currency or "UGX",
        "redirect_url": f"{settings.APP_BASE_URL}/api/v1/flutterwave/redirect",
        "payment_options": "mobilemoneyuganda,mobilemoneyrwanda,mpesa,card",
        "customer": {
            "email": user["email"],
            "name": user["username"],
        },
        "customizations": {
            "title": "Vurafya Health Payment",
            "description": req.description or "Vurafya service payment",
            "logo": f"{settings.APP_BASE_URL}/static/logo.png",
        },
        "meta": {
            "ledger_id": ledger_id,
            "user_id": user_id,
            "transaction_type": req.transaction_type,
            "payee_type": req.payee_type,
            "payee_id": req.payee_id,
        },
    }

    return {
        "tx_ref": tx_ref,
        "ledger_id": ledger_id,
        "flw_payload": flw_payload,
        "amount_ugx": req.amount_ugx,
        "status": "initiated",
    }


# ---------------------------------------------------------------------------
# FlutterWave webhook — called by FLW server after payment
# ---------------------------------------------------------------------------

@router.post("/webhook")
async def flutterwave_webhook(
    request: Request,
    db=Depends(get_db),
    verif_hash: str = Header(default=None, alias="verif-hash"),
):
    body = await request.body()
    body_text = body.decode("utf-8")

    # Verify webhook signature
    if settings.FLW_SECRET_HASH:
        expected = settings.FLW_SECRET_HASH
        if verif_hash != expected:
            raise HTTPException(status_code=401, detail="Invalid webhook signature")

    try:
        payload = json.loads(body_text)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON")

    event = payload.get("event", "")
    data = payload.get("data", {})
    tx_ref = data.get("tx_ref", "")
    status = data.get("status", "")
    flw_id = str(data.get("id", ""))
    amount = data.get("amount", 0)
    currency = data.get("currency", "UGX")
    now = _now()

    # Update payment_gateways_log
    await db.execute(
        """UPDATE payment_gateways_log
           SET status=?, error_message=?, processed_at=?
           WHERE transaction_ref=?""",
        (
            "completed" if status == "successful" else "failed",
            data.get("processor_response"),
            now,
            tx_ref,
        ),
    )

    if event == "charge.completed" and status == "successful":
        # Complete the ledger entry
        await db.execute(
            """UPDATE unified_payment_ledger
               SET payment_status='completed', completed_at=?, updated_at=?
               WHERE transaction_reference=?""",
            (now, now, tx_ref),
        )

        # Get ledger record to determine downstream actions
        cursor = await db.execute(
            "SELECT * FROM unified_payment_ledger WHERE transaction_reference=?",
            (tx_ref,),
        )
        ledger = await cursor.fetchone()
        if ledger:
            # Log platform revenue (example: pharmacy 10%, consultation 15%)
            fee_pct = 10.0  # Default; real value is on the ledger
            revenue = ledger["total_amount_ugx"] * fee_pct / 100

            await db.execute(
                """INSERT INTO platform_revenue_ledger
                   (revenue_source, amount_ugx, user_id, transaction_id, transaction_type,
                    revenue_date, month, year, created_at)
                   VALUES ('flutterwave_fiat',?,?,?,?,date('now'),
                           date('now','start of month'), cast(strftime('%Y','now') as int),?)""",
                (revenue, ledger["payer_user_id"], ledger["id"],
                 ledger["transaction_type"], now),
            )

    else:
        # Payment failed
        await db.execute(
            """UPDATE unified_payment_ledger
               SET payment_status='failed', failed_at=?,
                   failure_reason=?, updated_at=?
               WHERE transaction_reference=?""",
            (now, data.get("processor_response", "Payment failed"), now, tx_ref),
        )

    await db.commit()
    return {"status": "ok"}


# ---------------------------------------------------------------------------
# Redirect after payment (FLW redirects browser here)
# Flutter app intercepts this URL via deep link / in-app browser callback.
# ---------------------------------------------------------------------------

@router.get("/redirect")
async def flutterwave_redirect(
    status: str = "cancelled",
    tx_ref: str = "",
    transaction_id: str = "",
    db=Depends(get_db),
):
    now = _now()
    if status == "successful" and tx_ref:
        await db.execute(
            """UPDATE unified_payment_ledger
               SET payment_status='completed', completed_at=?, updated_at=?
               WHERE transaction_reference=? AND payment_status='pending'""",
            (now, now, tx_ref),
        )
        await db.commit()

    return {
        "status": status,
        "tx_ref": tx_ref,
        "transaction_id": transaction_id,
        "message": "Payment processed. You may return to the app.",
    }
