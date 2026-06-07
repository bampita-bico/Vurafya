import aiosqlite
from datetime import datetime, timezone


def _now():
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# Friends
# ---------------------------------------------------------------------------

async def send_friend_request(db: aiosqlite.Connection, user_id: int, friend_id: int) -> dict:
    if user_id == friend_id:
        return {"error": "Cannot add yourself"}
    cursor = await db.execute(
        "SELECT id, status FROM friends WHERE user_id = ? AND friend_id = ?",
        (user_id, friend_id),
    )
    existing = await cursor.fetchone()
    if existing:
        return {"error": f"Already {existing['status']}"}

    now = int(datetime.now(timezone.utc).timestamp())
    cursor = await db.execute(
        "INSERT INTO friends (user_id, friend_id, status, created_at) VALUES (?,?,'pending',?)",
        (user_id, friend_id, now),
    )
    await db.commit()
    return {"request_id": cursor.lastrowid, "status": "pending"}


async def respond_friend_request(db: aiosqlite.Connection, user_id: int, requester_id: int, accept: bool) -> dict:
    cursor = await db.execute(
        "SELECT id FROM friends WHERE user_id = ? AND friend_id = ? AND status = 'pending'",
        (requester_id, user_id),
    )
    req = await cursor.fetchone()
    if not req:
        return {"error": "Friend request not found"}

    now = int(datetime.now(timezone.utc).timestamp())
    if accept:
        await db.execute(
            "UPDATE friends SET status = 'accepted' WHERE id = ?", (req["id"],)
        )
        # Create reverse link
        await db.execute(
            "INSERT OR IGNORE INTO friends (user_id, friend_id, status, created_at) VALUES (?,?,'accepted',?)",
            (user_id, requester_id, now),
        )
    else:
        await db.execute("DELETE FROM friends WHERE id = ?", (req["id"],))
    await db.commit()
    return {"accepted": accept}


async def get_friends(db: aiosqlite.Connection, user_id: int, status: str = "accepted") -> list:
    cursor = await db.execute(
        """SELECT f.*, u.username
           FROM friends f
           JOIN users u ON f.friend_id = u.id
           WHERE f.user_id = ? AND f.status = ?
           ORDER BY f.created_at DESC""",
        (user_id, status),
    )
    return await cursor.fetchall()


async def get_pending_requests(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        """SELECT f.*, u.username
           FROM friends f
           JOIN users u ON f.user_id = u.id
           WHERE f.friend_id = ? AND f.status = 'pending'
           ORDER BY f.created_at DESC""",
        (user_id,),
    )
    return await cursor.fetchall()


async def remove_friend(db: aiosqlite.Connection, user_id: int, friend_id: int) -> dict:
    await db.execute(
        "DELETE FROM friends WHERE (user_id=? AND friend_id=?) OR (user_id=? AND friend_id=?)",
        (user_id, friend_id, friend_id, user_id),
    )
    await db.commit()
    return {"removed": friend_id}


# ---------------------------------------------------------------------------
# Direct messages (chat_messages — consultation_id can be NULL for DMs)
# ---------------------------------------------------------------------------

async def send_message(db: aiosqlite.Connection, sender_id: int, data: dict) -> dict:
    now = _now()
    cursor = await db.execute(
        """INSERT INTO chat_messages
           (sender_id, receiver_id, message_text, sent_at, is_read)
           VALUES (?,?,?,?,0)""",
        (sender_id, data["receiver_id"], data["message_text"], now),
    )
    await db.commit()
    return {"message_id": cursor.lastrowid, "sent_at": now}


async def get_conversation(db: aiosqlite.Connection, user_id: int, other_id: int, limit: int = 50) -> list:
    cursor = await db.execute(
        """SELECT * FROM chat_messages
           WHERE (sender_id=? AND receiver_id=?)
              OR (sender_id=? AND receiver_id=?)
           ORDER BY sent_at DESC LIMIT ?""",
        (user_id, other_id, other_id, user_id, limit),
    )
    rows = await cursor.fetchall()
    # Mark received messages as read
    await db.execute(
        "UPDATE chat_messages SET is_read = 1 WHERE sender_id = ? AND receiver_id = ? AND is_read = 0",
        (other_id, user_id),
    )
    await db.commit()
    return rows


async def get_inbox(db: aiosqlite.Connection, user_id: int) -> list:
    """Latest message per conversation partner."""
    cursor = await db.execute(
        """SELECT sender_id,
                  MAX(sent_at) as last_message_at,
                  SUM(CASE WHEN is_read=0 AND receiver_id=? THEN 1 ELSE 0 END) as unread_count
           FROM chat_messages
           WHERE sender_id = ? OR receiver_id = ?
           GROUP BY CASE WHEN sender_id=? THEN receiver_id ELSE sender_id END
           ORDER BY last_message_at DESC""",
        (user_id, user_id, user_id, user_id),
    )
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Guild chat
# ---------------------------------------------------------------------------

async def send_guild_message(db: aiosqlite.Connection, user_id: int, guild_id: int, text: str) -> dict:
    now = _now()
    # Verify user is in guild
    cursor = await db.execute(
        "SELECT id FROM guild_members WHERE user_id = ? AND guild_id = ? AND is_active = 1",
        (user_id, guild_id),
    )
    if not await cursor.fetchone():
        return {"error": "Not a guild member"}
    cursor = await db.execute(
        """INSERT INTO guild_chat_messages
           (guild_id, user_id, message_text, message_type, is_pinned, is_deleted, created_at)
           VALUES (?,?,?,?,0,0,?)""",
        (guild_id, user_id, text, "text", now),
    )
    await db.commit()
    return {"message_id": cursor.lastrowid, "sent_at": now}


async def get_guild_chat(db: aiosqlite.Connection, guild_id: int, limit: int = 50) -> list:
    cursor = await db.execute(
        """SELECT gcm.*, u.username
           FROM guild_chat_messages gcm
           JOIN users u ON gcm.user_id = u.id
           WHERE gcm.guild_id = ? AND gcm.is_deleted = 0
           ORDER BY gcm.created_at DESC LIMIT ?""",
        (guild_id, limit),
    )
    return await cursor.fetchall()
