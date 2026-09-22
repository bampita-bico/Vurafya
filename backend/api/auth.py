from fastapi import APIRouter, Depends, HTTPException, status
from backend.config import settings
from backend.utils.database import get_db
from backend.utils.exceptions import AuthenticationError, ValidationError
from backend.services.auth_service import (
    hash_password, verify_password,
    create_access_token, create_refresh_token, decode_token,
)
from backend.models.schemas import RegisterRequest, LoginRequest, TokenResponse, RefreshRequest
from backend.utils.dependencies import get_current_user
from datetime import datetime, timezone

router = APIRouter()


def _now() -> datetime:
    # Postgres columns here are TIMESTAMP WITHOUT TIME ZONE.
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _tokens(user_id: int, token_version: int = 0) -> TokenResponse:
    return TokenResponse(
        access_token=create_access_token(user_id, token_version),
        refresh_token=create_refresh_token(user_id, token_version),
    )


@router.post("/register", response_model=TokenResponse)
async def register(req: RegisterRequest, db=Depends(get_db)):
    # Check if email already exists
    cursor = await db.execute("SELECT id FROM users WHERE email = ?", (req.email,))
    if await cursor.fetchone():
        raise ValidationError("Email already registered")

    cursor = await db.execute("SELECT id FROM users WHERE username = ?", (req.username,))
    if await cursor.fetchone():
        raise ValidationError("Username already taken")

    pw_hash = hash_password(req.password)
    now = _now()

    # Create user
    cursor = await db.execute(
        "INSERT INTO users (email, username, password_hash, created_at) VALUES (?, ?, ?, ?)",
        (req.email, req.username, pw_hash, now),
    )
    user_id = cursor.lastrowid

    # Create avatar_stats
    await db.execute(
        "INSERT INTO avatar_stats (user_id, level, current_xp, xp_to_next_level, afya_points_balance, current_streak, updated_at) VALUES (?, 1, 0, 100, 0, 0, ?)",
        (user_id, now),
    )

    # Assign free subscription (optional on minimal schemas)
    try:
        await db.execute(
            """INSERT INTO user_subscriptions (user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
               VALUES (?, 1, 'active', 'monthly', date('now'), date('now', '+100 years'))""",
            (user_id,),
        )
    except Exception:
        pass

    await db.commit()

    return _tokens(user_id)


@router.post("/login", response_model=TokenResponse)
async def login(req: LoginRequest, db=Depends(get_db)):
    cursor = await db.execute(
        "SELECT id, password_hash, auth_token_version FROM users WHERE email = ? AND is_active = TRUE", (req.email,)
    )
    user = await cursor.fetchone()
    if not user or not verify_password(req.password, user["password_hash"]):
        raise AuthenticationError("Invalid email or password")

    # Update last_login
    await db.execute(
        "UPDATE users SET last_login = ? WHERE id = ?",
        (_now(), user["id"]),
    )
    await db.commit()

    return _tokens(user["id"], user.get("auth_token_version", 0))


@router.post("/refresh", response_model=TokenResponse)
async def refresh(req: RefreshRequest, db=Depends(get_db)):
    try:
        payload = decode_token(req.refresh_token)
        if payload.get("type") != "refresh":
            raise AuthenticationError("Invalid token type")
        user_id = int(payload["sub"])
    except Exception:
        raise AuthenticationError("Invalid refresh token")

    cursor = await db.execute(
        "SELECT id, is_active, auth_token_version FROM users WHERE id = ?", (user_id,)
    )
    user = await cursor.fetchone()
    if not user or not user.get("is_active", True) or int(payload.get("ver", 0)) != int(user.get("auth_token_version", 0)):
        raise AuthenticationError("Refresh token has been revoked")
    return _tokens(user_id, user.get("auth_token_version", 0))


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    """Revoke all existing access and refresh tokens for this user."""
    await db.execute(
        "UPDATE users SET auth_token_version = auth_token_version + 1 WHERE id = ?",
        (current_user["id"],),
    )
    await db.commit()


@router.post("/demo-login", response_model=TokenResponse)
async def demo_login(db=Depends(get_db)):
    """
    Returns a valid token pair for a deterministic demo account.
    Creates the demo account once if it does not already exist.
    """
    if not settings.DEMO_LOGIN_ENABLED:
        raise HTTPException(status_code=404, detail="Demo login is disabled")
    now = _now()

    cursor = await db.execute(
        "SELECT id, auth_token_version FROM users WHERE email = ?",
        (settings.DEMO_EMAIL,),
    )
    user = await cursor.fetchone()

    if user:
        user_id = user["id"]
        token_version = user.get("auth_token_version", 0)
    else:
        pw_hash = hash_password(settings.DEMO_PASSWORD)
        cursor = await db.execute(
            "INSERT INTO users (email, username, password_hash, created_at) VALUES (?, ?, ?, ?)",
            (settings.DEMO_EMAIL, settings.DEMO_USERNAME, pw_hash, now),
        )
        user_id = cursor.lastrowid
        token_version = 0

        await db.execute(
            "INSERT INTO avatar_stats (user_id, level, current_xp, xp_to_next_level, afya_points_balance, current_streak, updated_at) VALUES (?, 1, 0, 100, 0, 0, ?)",
            (user_id, now),
        )
        try:
            await db.execute(
                """INSERT INTO user_subscriptions (user_id, plan_id, status, billing_cycle, current_period_start, current_period_end)
                   VALUES (?, 1, 'active', 'monthly', date('now'), date('now', '+100 years'))""",
                (user_id,),
            )
        except Exception:
            pass

    await db.execute(
        "UPDATE users SET last_login = ? WHERE id = ?",
        (now, user_id),
    )
    await db.commit()

    return _tokens(user_id, token_version)
