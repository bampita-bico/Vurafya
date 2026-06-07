from fastapi import APIRouter, Depends, Query
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import NotFoundError, ValidationError
from backend.services.social_service import (
    send_friend_request, respond_friend_request,
    get_friends, get_pending_requests, remove_friend,
    send_message, get_conversation, get_inbox,
    send_guild_message, get_guild_chat,
)
from backend.models.schemas import (
    FriendResponseRequest, SendMessageRequest, SendGuildMessageRequest,
)

router = APIRouter()


# ── Friends ───────────────────────────────────────────────────────────────────

@router.post("/friends/{friend_id}/request")
async def add_friend(
    friend_id: int,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await send_friend_request(db, current_user["id"], friend_id)
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.post("/friends/{requester_id}/respond")
async def respond_request(
    requester_id: int,
    req: FriendResponseRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await respond_friend_request(db, current_user["id"], requester_id, req.accept)
    if "error" in result:
        raise NotFoundError("Friend request", requester_id)
    return result


@router.get("/friends")
async def my_friends(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"friends": await get_friends(db, current_user["id"])}


@router.get("/friends/requests")
async def friend_requests(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"requests": await get_pending_requests(db, current_user["id"])}


@router.delete("/friends/{friend_id}")
async def unfriend(
    friend_id: int,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await remove_friend(db, current_user["id"], friend_id)


# ── Direct messages ───────────────────────────────────────────────────────────

@router.get("/messages")
async def inbox(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"inbox": await get_inbox(db, current_user["id"])}


@router.get("/messages/{other_user_id}")
async def conversation(
    other_user_id: int,
    limit: int = Query(50, le=200),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return {"messages": await get_conversation(db, current_user["id"], other_user_id, limit)}


@router.post("/messages")
async def send_dm(
    req: SendMessageRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await send_message(db, current_user["id"], req.model_dump())


# ── Guild chat ────────────────────────────────────────────────────────────────

@router.get("/guilds/{guild_id}/chat")
async def guild_chat(
    guild_id: int,
    limit: int = Query(50, le=200),
    db=Depends(get_db),
):
    return {"messages": await get_guild_chat(db, guild_id, limit)}


@router.post("/guilds/{guild_id}/chat")
async def post_guild_message(
    guild_id: int,
    req: SendGuildMessageRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await send_guild_message(db, current_user["id"], guild_id, req.message_text)
    if "error" in result:
        raise ValidationError(result["error"])
    return result
