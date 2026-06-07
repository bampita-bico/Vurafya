import jwt
from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from backend.utils.database import get_db
from backend.utils.exceptions import AuthenticationError, FeatureGatedError
from backend.services.auth_service import decode_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db=Depends(get_db),
) -> dict:
    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            raise AuthenticationError("Invalid token type")
        user_id = int(payload["sub"])
    except jwt.ExpiredSignatureError:
        raise AuthenticationError("Token expired")
    except jwt.InvalidTokenError:
        raise AuthenticationError("Invalid token")

    cursor = await db.execute("SELECT id, email, username FROM users WHERE id = ?", (user_id,))
    user = await cursor.fetchone()
    if not user:
        raise AuthenticationError("User not found")
    return user


def require_tier(min_tier: int):
    async def checker(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
        cursor = await db.execute(
            """SELECT COALESCE(sp.tier, 1) as tier
               FROM users u
               LEFT JOIN user_subscriptions us ON u.id = us.user_id AND us.status IN ('active', 'trial')
               LEFT JOIN subscription_plans sp ON us.plan_id = sp.id
               WHERE u.id = ?""",
            (current_user["id"],),
        )
        row = await cursor.fetchone()
        tier = row["tier"] if row else 1
        if tier < min_tier:
            tier_names = {2: "Plus", 3: "Pro"}
            raise FeatureGatedError("subscription_tier", min_tier)
        return current_user
    return checker


def require_feature(feature_key: str):
    async def checker(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
        # Get user tier
        cursor = await db.execute(
            """SELECT COALESCE(sp.tier, 1) as tier
               FROM users u
               LEFT JOIN user_subscriptions us ON u.id = us.user_id AND us.status IN ('active', 'trial')
               LEFT JOIN subscription_plans sp ON us.plan_id = sp.id
               WHERE u.id = ?""",
            (current_user["id"],),
        )
        row = await cursor.fetchone()
        user_tier = row["tier"] if row else 1

        # Get feature requirement
        cursor = await db.execute(
            "SELECT required_tier, free_limit, plus_limit, pro_limit FROM subscription_features WHERE feature_key = ?",
            (feature_key,),
        )
        feature = await cursor.fetchone()
        if not feature:
            return {"allowed": True, "limit": None}

        if user_tier < feature["required_tier"]:
            raise FeatureGatedError(feature_key, feature["required_tier"])

        limit = None
        if user_tier == 1:
            limit = feature["free_limit"]
        elif user_tier == 2:
            limit = feature["plus_limit"]
        elif user_tier == 3:
            limit = feature["pro_limit"]

        return {"allowed": True, "limit": limit}
    return checker
