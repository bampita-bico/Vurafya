from fastapi import APIRouter, Depends, Query
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import NotFoundError, ValidationError
from backend.services.game_extras_service import (
    get_bosses, start_boss_fight, deal_boss_damage,
    get_guilds, create_guild, join_guild, get_my_guild,
    get_crafting_recipes, craft_recipe, get_crafting_inventory,
    get_pet_species, get_my_pets, adopt_pet, care_for_pet,
    get_world_map, get_leaderboard,
)
from backend.services.subscription_service import get_user_tier
from backend.models.schemas import (
    CreateGuildRequest, CraftRecipeRequest, AdoptPetRequest, PetCareRequest,
    BossDamageRequest,
)

router = APIRouter()


# ── Bosses ──────────────────────────────────────────────────────────────────

@router.get("/bosses")
async def list_bosses(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    tier = await get_user_tier(db, current_user["id"])
    return {"bosses": await get_bosses(db, current_user["id"], tier)}


@router.post("/bosses/{boss_id}/start")
async def fight_boss(
    boss_id: int,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    tier = await get_user_tier(db, current_user["id"])
    result = await start_boss_fight(db, current_user["id"], boss_id, tier)
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.post("/bosses/{boss_id}/damage")
async def damage_boss(
    boss_id: int,
    req: BossDamageRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await deal_boss_damage(db, current_user["id"], boss_id, req.damage)
    if "error" in result:
        raise ValidationError(result["error"])
    return result


# ── Guilds ──────────────────────────────────────────────────────────────────

@router.get("/guilds")
async def list_guilds(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    tier = await get_user_tier(db, current_user["id"])
    return {"guilds": await get_guilds(db, current_user["id"], tier)}


@router.post("/guilds")
async def make_guild(
    req: CreateGuildRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    tier = await get_user_tier(db, current_user["id"])
    result = await create_guild(db, current_user["id"], tier, req.model_dump())
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.post("/guilds/{guild_id}/join")
async def join(
    guild_id: int,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    tier = await get_user_tier(db, current_user["id"])
    result = await join_guild(db, current_user["id"], tier, guild_id)
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.get("/guilds/me")
async def my_guild(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    result = await get_my_guild(db, current_user["id"])
    if not result:
        return {"guild": None}
    return result


# ── Crafting ─────────────────────────────────────────────────────────────────

@router.get("/crafting/recipes")
async def crafting_recipes(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    tier = await get_user_tier(db, current_user["id"])
    return {"recipes": await get_crafting_recipes(db, current_user["id"], tier)}


@router.post("/crafting/craft")
async def craft(
    req: CraftRecipeRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    tier = await get_user_tier(db, current_user["id"])
    result = await craft_recipe(db, current_user["id"], tier, req.model_dump())
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.get("/crafting/inventory")
async def crafting_inventory(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"inventory": await get_crafting_inventory(db, current_user["id"])}


# ── Pets ─────────────────────────────────────────────────────────────────────

@router.get("/pets/species")
async def pet_species(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    tier = await get_user_tier(db, current_user["id"])
    return {"species": await get_pet_species(db, tier)}


@router.get("/pets")
async def my_pets(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"pets": await get_my_pets(db, current_user["id"])}


@router.post("/pets/adopt")
async def adopt(
    req: AdoptPetRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    tier = await get_user_tier(db, current_user["id"])
    result = await adopt_pet(db, current_user["id"], tier, req.model_dump())
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.post("/pets/{pet_id}/care")
async def care(
    pet_id: int,
    req: PetCareRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await care_for_pet(db, current_user["id"], pet_id, req.action)
    if "error" in result:
        raise NotFoundError("Pet", pet_id)
    return result


# ── World map ─────────────────────────────────────────────────────────────────

@router.get("/world-map")
async def world_map(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    tier = await get_user_tier(db, current_user["id"])
    return {"regions": await get_world_map(db, current_user["id"], tier)}


# ── Leaderboard ───────────────────────────────────────────────────────────────

@router.get("/leaderboard")
async def leaderboard(db=Depends(get_db)):
    return {"leaderboard": await get_leaderboard(db)}
