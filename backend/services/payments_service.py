import aiosqlite
from datetime import datetime, timezone
from backend.services.fraud_service import evaluate_transaction


# ---------------------------------------------------------------------------
# VRC Wallet
# ---------------------------------------------------------------------------

async def get_vrc_wallet(db: aiosqlite.Connection, user_id: int) -> dict:
    """Get or compute VRC balance from transactions (no wallet table yet)."""
    cursor = await db.execute(
        """SELECT COALESCE(SUM(
                CASE WHEN transaction_type IN ('credit', 'conversion_in', 'reward', 'refund') THEN amount
                     WHEN transaction_type IN ('debit', 'conversion_out', 'payment', 'fee') THEN -amount
                     ELSE 0 END
           ), 0) as balance
           FROM vrc_transactions
           WHERE user_id = ? AND status = 'completed'""",
        (user_id,),
    )
    row = await cursor.fetchone()
    balance = row["balance"] if row else 0.0

    # Recent transactions
    cursor = await db.execute(
        """SELECT * FROM vrc_transactions
           WHERE user_id = ?
           ORDER BY created_at DESC
           LIMIT 20""",
        (user_id,),
    )
    recent = await cursor.fetchall()

    return {
        "user_id": user_id,
        "balance_vrc": round(balance, 2),
        "balance_ugx_equivalent": round(balance, 2),  # 1 VRC = 1 UGX
        "recent_transactions": recent,
    }


async def convert_ap_to_vrc(db: aiosqlite.Connection, user_id: int, ap_amount: int) -> dict:
    """Convert Afya Points to VRC. 1 AP = 100 VRC."""
    now = datetime.now(timezone.utc).isoformat()

    # Check AP balance
    cursor = await db.execute(
        "SELECT afya_points_balance FROM avatar_stats WHERE user_id = ?", (user_id,)
    )
    stats = await cursor.fetchone()
    if not stats or (stats["afya_points_balance"] or 0) < ap_amount:
        return {"error": "Insufficient Afya Points"}

    vrc_amount = ap_amount * 100

    # Deduct AP
    await db.execute(
        "UPDATE avatar_stats SET afya_points_balance = afya_points_balance - ? WHERE user_id = ?",
        (ap_amount, user_id),
    )

    # Credit VRC
    cursor = await db.execute(
        """INSERT INTO vrc_transactions
           (user_id, transaction_type, amount, source_currency, source_amount,
            conversion_rate, description, status, created_at)
           VALUES (?, 'conversion_in', ?, 'AP', ?, 100.0, 'AP to VRC conversion', 'completed', ?)""",
        (user_id, vrc_amount, ap_amount, now),
    )
    await db.commit()
    return {
        "ap_spent": ap_amount,
        "vrc_credited": vrc_amount,
        "rate": "1 AP = 100 VRC",
        "transaction_id": cursor.lastrowid,
    }


async def send_vrc(db: aiosqlite.Connection, sender_id: int, data: dict) -> dict:
    """Send VRC to another user."""
    now = datetime.now(timezone.utc).isoformat()
    recipient_id = data["recipient_user_id"]
    amount = data["amount"]

    if amount <= 0:
        return {"error": "Amount must be positive"}
    if sender_id == recipient_id:
        return {"error": "Cannot send to yourself"}

    # Check recipient exists
    cursor = await db.execute("SELECT id FROM users WHERE id = ?", (recipient_id,))
    if not await cursor.fetchone():
        return {"error": "Recipient not found"}

    # Check sender balance
    wallet = await get_vrc_wallet(db, sender_id)
    if wallet["balance_vrc"] < amount:
        return {"error": "Insufficient VRC balance"}

    # Debit sender
    await db.execute(
        """INSERT INTO vrc_transactions
           (user_id, transaction_type, amount, counterparty_user_id, description, status, created_at)
           VALUES (?, 'debit', ?, ?, ?, 'completed', ?)""",
        (sender_id, amount, recipient_id, data.get("description", "VRC transfer"), now),
    )

    # Credit recipient
    await db.execute(
        """INSERT INTO vrc_transactions
           (user_id, transaction_type, amount, counterparty_user_id, description, status, created_at)
           VALUES (?, 'credit', ?, ?, ?, 'completed', ?)""",
        (recipient_id, amount, sender_id, data.get("description", "VRC received"), now),
    )

    await db.commit()
    return {"sent_vrc": amount, "recipient_id": recipient_id, "status": "completed"}


# ---------------------------------------------------------------------------
# Unified payment ledger
# ---------------------------------------------------------------------------

async def get_payment_history(db: aiosqlite.Connection, user_id: int, limit: int = 20) -> list:
    cursor = await db.execute(
        """SELECT * FROM unified_payment_ledger
           WHERE payer_user_id = ?
           ORDER BY created_at DESC
           LIMIT ?""",
        (user_id, limit),
    )
    return await cursor.fetchall()


async def initiate_payment(db: aiosqlite.Connection, payer_id: int, data: dict) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    import json as _json

    total_ugx = data.get("total_amount_ugx", 0)
    fiat_ugx = data.get("fiat_amount_ugx", total_ugx)
    ap_amount = data.get("afya_points_amount", 0)
    lh_amount = data.get("labor_hours_amount", 0.0)
    bc_amount = data.get("barter_credit_amount", 0)
    is_hybrid = (ap_amount > 0 or lh_amount > 0 or bc_amount > 0)

    breakdown = {
        "fiat_ugx": fiat_ugx,
        "afya_points": ap_amount,
        "labor_hours": lh_amount,
        "barter_credits": bc_amount,
    }

    cursor = await db.execute(
        """INSERT INTO unified_payment_ledger
           (transaction_type, transaction_id, transaction_reference,
            payer_user_id, payee_type, payee_id,
            total_amount_ugx, payment_method, is_hybrid_payment, payment_breakdown,
            fiat_amount_ugx, afya_points_amount, labor_hours_amount, barter_credit_amount,
            payment_status, initiated_at, created_at, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)""",
        (
            data.get("transaction_type", "general"),
            data.get("reference_id"),
            f"PAY-{payer_id}-{int(datetime.now().timestamp())}",
            payer_id,
            data.get("payee_type", "platform"),
            data.get("payee_id"),
            total_ugx,
            data.get("payment_method", "mobile_money"),
            is_hybrid,
            _json.dumps(breakdown),
            fiat_ugx,
            ap_amount,
            lh_amount,
            bc_amount,
            now, now, now,
        ),
    )
    ledger_id = cursor.lastrowid
    await db.commit()

    # Fraud evaluation (non-blocking — result appended to response)
    fraud = await evaluate_transaction(db, payer_id, {
        "amount_ugx": total_ugx,
        "transaction_type": data.get("transaction_type", "general"),
        "transaction_id": ledger_id,
        "payee_id": data.get("payee_id"),
    })

    if fraud.get("blocked"):
        # Mark payment as blocked
        await db.execute(
            "UPDATE unified_payment_ledger SET payment_status='blocked' WHERE id=?",
            (ledger_id,),
        )
        await db.commit()
        return {
            "payment_id": ledger_id,
            "status": "blocked",
            "reason": "Transaction blocked by fraud detection",
            "fraud_risk": fraud,
        }

    return {
        "payment_id": ledger_id,
        "total_ugx": total_ugx,
        "is_hybrid": is_hybrid,
        "breakdown": breakdown,
        "status": "pending",
        "fraud_risk_level": fraud.get("risk_level", "low"),
    }
