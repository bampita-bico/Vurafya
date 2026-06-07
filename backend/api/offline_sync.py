"""
Offline sync endpoints.
Flutter app queues transactions offline, syncs when back online.
"""
import json
import hashlib
from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import ValidationError
from backend.models.schemas import QueueOfflineTransactionRequest, SyncOfflineRequest

router = APIRouter()


def _now():
    return datetime.now(timezone.utc).isoformat()


def _hash_data(data: dict) -> str:
    return hashlib.md5(json.dumps(data, sort_keys=True).encode()).hexdigest()


@router.get("/capabilities")
async def offline_capabilities(db=Depends(get_db)):
    """Which features work offline. Flutter uses this to show offline indicators."""
    cursor = await db.execute("SELECT * FROM offline_capability_status ORDER BY feature_name")
    return {"capabilities": await cursor.fetchall()}


@router.post("/queue")
async def queue_transaction(
    req: QueueOfflineTransactionRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    """Flutter queues a transaction created while offline."""
    now = _now()
    data = req.transaction_data
    data_hash = _hash_data(data)

    # Duplicate check
    cursor = await db.execute(
        """SELECT id FROM offline_transaction_queue
           WHERE user_id=? AND transaction_data_hash=? AND sync_status='pending'""",
        (current_user["id"], data_hash),
    )
    if await cursor.fetchone():
        return {"status": "already_queued"}

    cursor = await db.execute(
        """INSERT INTO offline_transaction_queue
           (user_id, device_id, transaction_type, transaction_data,
            transaction_data_hash, created_offline_at, queued_at,
            sync_status, sync_attempt_count, priority, is_critical)
           VALUES (?,?,?,?,?,?,?,
                   'pending',0,?,?)""",
        (
            current_user["id"],
            req.device_id,
            req.transaction_type,
            json.dumps(data),
            data_hash,
            req.created_offline_at or now,
            now,
            req.priority or 5,
            req.is_critical or False,
        ),
    )
    await db.commit()
    return {"queued_id": cursor.lastrowid, "status": "queued"}


@router.post("/sync")
async def sync_transactions(
    req: SyncOfflineRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    """Process all pending offline transactions for a user's device."""
    now = _now()
    user_id = current_user["id"]

    cursor = await db.execute(
        """SELECT * FROM offline_transaction_queue
           WHERE user_id=? AND device_id=? AND sync_status='pending'
           ORDER BY is_critical DESC, priority DESC, created_offline_at ASC
           LIMIT 50""",
        (user_id, req.device_id),
    )
    pending = await cursor.fetchall()

    results = []
    for item in pending:
        try:
            data = json.loads(item["transaction_data"])
            # Route to appropriate service based on transaction_type
            server_id = None
            error = None

            tx_type = item["transaction_type"]

            if tx_type == "meal_log":
                # Insert meal
                c = await db.execute(
                    """INSERT INTO meals (user_id, meal_name, meal_type, logged_at, created_at)
                       VALUES (?,?,?,?,?)""",
                    (user_id, data.get("meal_name", "Offline Meal"),
                     data.get("meal_type", "snack"),
                     data.get("logged_at", now), now),
                )
                server_id = c.lastrowid

            elif tx_type == "biometric_log":
                # Route to correct biometric table
                metric = data.get("metric_type")
                if metric == "weight":
                    c = await db.execute(
                        "INSERT INTO weight_logs (user_id, weight_kg, measurement_date, created_at) VALUES (?,?,?,?)",
                        (user_id, data["value"], data.get("date", now[:10]), now),
                    )
                    server_id = c.lastrowid

            elif tx_type == "medication_taken":
                c = await db.execute(
                    """INSERT INTO adherence_logs (user_id, schedule_id, taken, taken_at, notes, created_at)
                       VALUES (?,?,1,?,?,?)""",
                    (user_id, data.get("schedule_id"), data.get("taken_at", now),
                     data.get("notes", "Logged offline"), now),
                )
                server_id = c.lastrowid

            # Mark as synced
            await db.execute(
                """UPDATE offline_transaction_queue
                   SET sync_status='synced', synced_at=?,
                       server_transaction_id=?, server_transaction_type=?,
                       sync_attempt_count=sync_attempt_count+1
                   WHERE id=?""",
                (now, server_id, tx_type, item["id"]),
            )
            results.append({"queue_id": item["id"], "status": "synced", "server_id": server_id})

        except Exception as e:
            await db.execute(
                """UPDATE offline_transaction_queue
                   SET sync_status='failed', sync_error=?,
                       sync_attempt_count=sync_attempt_count+1,
                       last_sync_attempt_at=?
                   WHERE id=?""",
                (str(e)[:200], now, item["id"]),
            )
            results.append({"queue_id": item["id"], "status": "failed", "error": str(e)})

    await db.commit()
    synced = sum(1 for r in results if r["status"] == "synced")
    failed = sum(1 for r in results if r["status"] == "failed")
    return {
        "processed": len(results),
        "synced": synced,
        "failed": failed,
        "results": results,
    }


@router.get("/pending-count")
async def pending_count(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    cursor = await db.execute(
        "SELECT COUNT(*) as cnt FROM offline_transaction_queue WHERE user_id=? AND sync_status='pending'",
        (current_user["id"],),
    )
    row = await cursor.fetchone()
    return {"pending": row["cnt"] if row else 0}
