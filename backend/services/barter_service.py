import aiosqlite
import json
from datetime import datetime, timezone, timedelta


def _now():
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# Catalog listings
# ---------------------------------------------------------------------------

async def list_goods(db: aiosqlite.Connection, filters: dict) -> list:
    q = """SELECT bg.*, u.username, u.display_name
           FROM barter_goods_catalog bg
           JOIN users u ON bg.user_id = u.id
           WHERE bg.is_available = 1"""
    params = []
    if filters.get("category"):
        q += " AND bg.item_category = ?"
        params.append(filters["category"])
    if filters.get("min_value"):
        q += " AND bg.estimated_value_ugx >= ?"
        params.append(filters["min_value"])
    if filters.get("max_value"):
        q += " AND bg.estimated_value_ugx <= ?"
        params.append(filters["max_value"])
    q += " ORDER BY bg.created_at DESC LIMIT ? OFFSET ?"
    params += [filters.get("limit", 20), filters.get("offset", 0)]
    cursor = await db.execute(q, params)
    return await cursor.fetchall()


async def list_services(db: aiosqlite.Connection, filters: dict) -> list:
    q = """SELECT bs.*, u.username, u.display_name
           FROM barter_services_catalog bs
           JOIN users u ON bs.user_id = u.id
           WHERE bs.is_available = 1"""
    params = []
    if filters.get("category"):
        q += " AND bs.service_category = ?"
        params.append(filters["category"])
    q += " ORDER BY bs.created_at DESC LIMIT ? OFFSET ?"
    params += [filters.get("limit", 20), filters.get("offset", 0)]
    cursor = await db.execute(q, params)
    return await cursor.fetchall()


async def post_good(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = _now()
    cursor = await db.execute(
        """INSERT INTO barter_goods_catalog
           (user_id, item_name, item_category, item_description, condition,
            estimated_value_ugx, afya_points_equivalent, quantity, unit,
            location_district, delivery_available, delivery_radius_km,
            perishable, seeking_categories, open_to_offers,
            is_available, created_at, updated_at)
           VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,1,?,?)""",
        (
            user_id,
            data["item_name"],
            data["item_category"],
            data.get("item_description"),
            data.get("condition", "good"),
            data["estimated_value_ugx"],
            int(data["estimated_value_ugx"] / 100),   # 1 AP = 100 UGX
            data.get("quantity", 1),
            data.get("unit", "unit"),
            data.get("location_district"),
            data.get("delivery_available", False),
            data.get("delivery_radius_km", 0),
            data.get("perishable", False),
            json.dumps(data.get("seeking_categories", [])),
            data.get("open_to_offers", True),
            now, now,
        ),
    )
    await db.commit()
    return {"good_id": cursor.lastrowid, "status": "listed"}


async def post_service(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = _now()
    cursor = await db.execute(
        """INSERT INTO barter_services_catalog
           (user_id, service_name, service_category, service_description,
            estimated_value_ugx, afya_points_equivalent, duration_hours,
            location_district, can_travel, travel_radius_km,
            seeking_categories, open_to_offers,
            is_available, created_at, updated_at)
           VALUES (?,?,?,?,?,?,?,?,?,?,?,?,1,?,?)""",
        (
            user_id,
            data["service_name"],
            data["service_category"],
            data.get("service_description"),
            data["estimated_value_ugx"],
            int(data["estimated_value_ugx"] / 100),
            data.get("duration_hours", 1.0),
            data.get("location_district"),
            data.get("can_travel", False),
            data.get("travel_radius_km", 0),
            json.dumps(data.get("seeking_categories", [])),
            data.get("open_to_offers", True),
            now, now,
        ),
    )
    await db.commit()
    return {"service_id": cursor.lastrowid, "status": "listed"}


# ---------------------------------------------------------------------------
# Match suggestions
# ---------------------------------------------------------------------------

async def get_matches(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        """SELECT bm.*,
                  CASE WHEN bm.user_a_id = ? THEN bm.user_b_id ELSE bm.user_a_id END AS matched_user_id
           FROM barter_match_scores bm
           WHERE (bm.user_a_id = ? OR bm.user_b_id = ?)
             AND bm.match_score >= 0.7
             AND bm.is_active = 1
             AND bm.trade_initiated = 0
           ORDER BY bm.match_score DESC
           LIMIT 20""",
        (user_id, user_id, user_id),
    )
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Initiate / manage a trade
# ---------------------------------------------------------------------------

async def initiate_trade(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = _now()
    # Basic validation
    if user_id == data.get("party_b_user_id"):
        return {"error": "Cannot trade with yourself"}

    # Get fee rate
    cursor = await db.execute(
        "SELECT rate_pct FROM fee_structure_config WHERE fee_type = 'barter_exchange'",
    )
    fee_row = await cursor.fetchone()
    fee_pct = fee_row["rate_pct"] if fee_row else 3.5

    cursor = await db.execute(
        """INSERT INTO barter_exchange_transactions
           (transaction_type,
            party_a_user_id, party_a_offer_type, party_a_offer_id,
            party_a_offer_description, party_a_afya_points_value,
            party_b_user_id, party_b_offer_type, party_b_offer_id,
            party_b_offer_description, party_b_afya_points_value,
            status, transaction_fee_pct,
            party_a_confirmed, party_b_confirmed,
            initiated_at, created_at, updated_at)
           VALUES ('goods_for_goods',?,?,?,?,?,?,?,?,?,?,'pending',?,0,0,?,?,?)""",
        (
            user_id,
            data.get("offer_type", "good"),
            data.get("offer_id"),
            data.get("offer_description", ""),
            data.get("offer_ap_value", 0),
            data["party_b_user_id"],
            data.get("want_type", "good"),
            data.get("want_id"),
            data.get("want_description", ""),
            data.get("want_ap_value", 0),
            fee_pct,
            now, now, now,
        ),
    )
    tx_id = cursor.lastrowid
    await db.commit()
    return {"trade_id": tx_id, "status": "pending", "fee_pct": fee_pct}


async def confirm_trade(db: aiosqlite.Connection, user_id: int, trade_id: int) -> dict:
    now = _now()
    cursor = await db.execute(
        "SELECT * FROM barter_exchange_transactions WHERE id = ?", (trade_id,)
    )
    trade = await cursor.fetchone()
    if not trade:
        return {"error": "Trade not found"}
    if trade["status"] not in ("pending", "accepted"):
        return {"error": f"Cannot confirm trade in status: {trade['status']}"}

    if user_id == trade["party_a_user_id"]:
        await db.execute(
            "UPDATE barter_exchange_transactions SET party_a_confirmed=1, party_a_confirmed_at=?, updated_at=? WHERE id=?",
            (now, now, trade_id),
        )
    elif user_id == trade["party_b_user_id"]:
        await db.execute(
            "UPDATE barter_exchange_transactions SET party_b_confirmed=1, party_b_confirmed_at=?, updated_at=? WHERE id=?",
            (now, now, trade_id),
        )
    else:
        return {"error": "Not a party to this trade"}

    # Re-fetch to check both confirmed
    cursor = await db.execute(
        "SELECT party_a_confirmed, party_b_confirmed FROM barter_exchange_transactions WHERE id=?",
        (trade_id,),
    )
    updated = await cursor.fetchone()
    if updated["party_a_confirmed"] and updated["party_b_confirmed"]:
        release = (datetime.now(timezone.utc) + timedelta(days=7)).isoformat()
        await db.execute(
            """UPDATE barter_exchange_transactions
               SET status='in_escrow', accepted_at=?, escrow_locked_at=?, escrow_release_at=?, updated_at=?
               WHERE id=?""",
            (now, now, release, now, trade_id),
        )
    await db.commit()
    return {"trade_id": trade_id, "confirmed": True}


async def complete_trade(db: aiosqlite.Connection, user_id: int, trade_id: int) -> dict:
    now = _now()
    cursor = await db.execute(
        "SELECT * FROM barter_exchange_transactions WHERE id = ?", (trade_id,)
    )
    trade = await cursor.fetchone()
    if not trade:
        return {"error": "Trade not found"}
    if trade["status"] != "in_escrow":
        return {"error": "Trade not in escrow"}
    if user_id not in (trade["party_a_user_id"], trade["party_b_user_id"]):
        return {"error": "Not a party to this trade"}

    # Calculate fee
    val = max(trade["party_a_afya_points_value"] or 0, trade["party_b_afya_points_value"] or 0)
    fee_ap = int(val * (trade["transaction_fee_pct"] or 3.5) / 100)
    revenue_ugx = fee_ap * 100  # AP -> UGX

    await db.execute(
        """UPDATE barter_exchange_transactions
           SET status='completed', completed_at=?, fee_paid=1, fee_paid_at=?,
               transaction_fee_afya_points=?, platform_revenue_ugx=?, updated_at=?
           WHERE id=?""",
        (now, now, fee_ap, revenue_ugx, now, trade_id),
    )

    # Log platform revenue
    await db.execute(
        """INSERT INTO platform_revenue_ledger
           (revenue_type, source_transaction_id, source_transaction_type,
            gross_amount_ugx, fee_amount_ugx, net_amount_ugx,
            payment_method, status, created_at, updated_at)
           VALUES ('barter_fee', ?, 'barter_exchange', ?, ?, ?, 'afya_points', 'credited', ?, ?)""",
        (trade_id, revenue_ugx, revenue_ugx, revenue_ugx, now, now),
    )
    await db.commit()
    return {"trade_id": trade_id, "status": "completed", "platform_fee_ap": fee_ap}


async def rate_trade(db: aiosqlite.Connection, user_id: int, trade_id: int, data: dict) -> dict:
    now = _now()
    cursor = await db.execute(
        "SELECT * FROM barter_exchange_transactions WHERE id = ?", (trade_id,)
    )
    trade = await cursor.fetchone()
    if not trade:
        return {"error": "Trade not found"}
    if trade["status"] != "completed":
        return {"error": "Can only rate completed trades"}

    rating = max(1, min(5, data.get("rating", 5)))
    review = data.get("review", "")

    if user_id == trade["party_a_user_id"]:
        await db.execute(
            "UPDATE barter_exchange_transactions SET party_a_rating=?, party_a_review=?, party_a_reviewed_at=?, updated_at=? WHERE id=?",
            (rating, review, now, now, trade_id),
        )
        reviewee = trade["party_b_user_id"]
    elif user_id == trade["party_b_user_id"]:
        await db.execute(
            "UPDATE barter_exchange_transactions SET party_b_rating=?, party_b_review=?, party_b_reviewed_at=?, updated_at=? WHERE id=?",
            (rating, review, now, now, trade_id),
        )
        reviewee = trade["party_a_user_id"]
    else:
        return {"error": "Not a party to this trade"}

    # Insert into transaction_reviews
    await db.execute(
        """INSERT INTO transaction_reviews
           (transaction_id, transaction_type, reviewer_user_id, reviewee_user_id,
            rating, review_text, reliability_rating, quality_rating, fairness_rating,
            would_trade_again, goods_as_described, is_verified_review, created_at)
           VALUES (?, 'barter', ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)""",
        (
            trade_id, user_id, reviewee, rating, review,
            data.get("reliability_rating", rating),
            data.get("quality_rating", rating),
            data.get("fairness_rating", rating),
            data.get("would_trade_again", True),
            data.get("goods_as_described", True),
            now,
        ),
    )
    await db.commit()
    return {"rated": True, "rating": rating}


async def get_my_trades(db: aiosqlite.Connection, user_id: int, status: str = None) -> list:
    q = """SELECT * FROM barter_exchange_transactions
           WHERE party_a_user_id = ? OR party_b_user_id = ?"""
    params = [user_id, user_id]
    if status:
        q += " AND status = ?"
        params.append(status)
    q += " ORDER BY created_at DESC LIMIT 50"
    cursor = await db.execute(q, params)
    return await cursor.fetchall()


async def get_categories(db: aiosqlite.Connection) -> list:
    cursor = await db.execute(
        "SELECT * FROM barter_item_categories WHERE is_active = 1 ORDER BY category_type, category_name"
    )
    return await cursor.fetchall()
