import aiosqlite
from datetime import datetime, timezone, date


async def search_foods(db: aiosqlite.Connection, query: str, limit: int = 20, offset: int = 0) -> dict:
    q = f"%{query}%"
    cursor = await db.execute(
        """SELECT f.id, f.name, f.local_name, f.glycemic_index, f.gi_classification
           FROM foods f
           WHERE f.name IS NOT NULL AND (f.name LIKE ? OR f.local_name LIKE ?)
           ORDER BY f.name
           LIMIT ? OFFSET ?""",
        (q, q, limit, offset),
    )
    items = await cursor.fetchall()

    cursor = await db.execute(
        "SELECT COUNT(*) as total FROM foods WHERE name IS NOT NULL AND (name LIKE ? OR local_name LIKE ?)",
        (q, q),
    )
    total_row = await cursor.fetchone()

    return {"items": items, "total": total_row["total"], "offset": offset, "limit": limit}


async def get_food_detail(db: aiosqlite.Connection, food_id: int) -> dict | None:
    cursor = await db.execute(
        "SELECT * FROM foods WHERE id = ? AND name IS NOT NULL", (food_id,)
    )
    food = await cursor.fetchone()
    if not food:
        return None

    cursor = await db.execute(
        """SELECT n.id as nutrient_id, n.name, n.symbol, n.units,
                  fn.amount_per_100g
           FROM food_nutrients fn
           JOIN nutrients n ON n.id = fn.nutrient_id
           WHERE fn.food_id = ?
           ORDER BY n.name""",
        (food_id,),
    )
    nutrients = await cursor.fetchall()

    return {"food": food, "nutrients": nutrients}


async def get_food_pral(db: aiosqlite.Connection, food_id: int) -> dict | None:
    cursor = await db.execute(
        """SELECT * FROM renal_acid_load_data WHERE food_id = ?""", (food_id,)
    )
    pral = await cursor.fetchone()
    if not pral:
        # Try computing from nutrients
        cursor = await db.execute(
            """SELECT
                 SUM(CASE WHEN n.name = 'Protein' THEN fn.amount_per_100g ELSE 0 END) as protein,
                 SUM(CASE WHEN n.name = 'Phosphorus' THEN fn.amount_per_100g ELSE 0 END) as phosphorus,
                 SUM(CASE WHEN n.name = 'Potassium' THEN fn.amount_per_100g ELSE 0 END) as potassium,
                 SUM(CASE WHEN n.name = 'Magnesium' THEN fn.amount_per_100g ELSE 0 END) as magnesium,
                 SUM(CASE WHEN n.name = 'Calcium' THEN fn.amount_per_100g ELSE 0 END) as calcium
               FROM food_nutrients fn
               JOIN nutrients n ON n.id = fn.nutrient_id
               WHERE fn.food_id = ?""",
            (food_id,),
        )
        row = await cursor.fetchone()
        if not row or not row["protein"]:
            return None

        pral_value = (
            0.49 * (row["protein"] or 0)
            + 0.037 * (row["phosphorus"] or 0)
            - 0.021 * (row["potassium"] or 0)
            - 0.026 * (row["magnesium"] or 0)
            - 0.013 * (row["calcium"] or 0)
        )
        return {
            "food_id": food_id,
            "pral_value": round(pral_value, 2),
            "classification": "alkalizing" if pral_value < 0 else "acidifying",
            "protein_g": row["protein"],
            "phosphorus_mg": row["phosphorus"],
            "potassium_mg": row["potassium"],
            "magnesium_mg": row["magnesium"],
            "calcium_mg": row["calcium"],
            "source": "calculated",
        }
    return pral


async def create_meal(db: aiosqlite.Connection, user_id: int, meal_data: dict) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    meal_date = meal_data.get("meal_date") or date.today().isoformat()

    # Insert meal
    cursor = await db.execute(
        """INSERT INTO meals (user_id, meal_type, meal_date, notes, created_at)
           VALUES (?, ?, ?, ?, ?)""",
        (user_id, meal_data["meal_type"], meal_date, meal_data.get("notes"), now),
    )
    meal_id = cursor.lastrowid

    # Insert components and calculate nutrition
    total_protein = 0
    total_potassium = 0
    total_phosphorus = 0
    total_calories = 0
    total_pral = 0

    for comp in meal_data["components"]:
        food_id = comp["food_id"]
        grams = comp["quantity_grams"]
        ratio = grams / 100.0

        await db.execute(
            """INSERT INTO meal_components (meal_id, food_id, quantity_grams, meal_component_type)
               VALUES (?, ?, ?, ?)""",
            (meal_id, food_id, grams, comp.get("meal_component_type", "main")),
        )

        # Get nutrients for this food
        cursor = await db.execute(
            """SELECT n.name, fn.amount_per_100g
               FROM food_nutrients fn
               JOIN nutrients n ON n.id = fn.nutrient_id
               WHERE fn.food_id = ?""",
            (food_id,),
        )
        nutrients = await cursor.fetchall()

        protein = phosphorus = potassium = magnesium = calcium = calories = 0
        for nut in nutrients:
            val = (nut["amount_per_100g"] or 0) * ratio
            name = nut["name"]
            if name == "Protein":
                protein = val
            elif name == "Phosphorus":
                phosphorus = val
            elif name == "Potassium":
                potassium = val
            elif name == "Magnesium":
                magnesium = val
            elif name == "Calcium":
                calcium = val
            elif name == "Calories":
                calories = val

        total_protein += protein
        total_potassium += potassium
        total_phosphorus += phosphorus
        total_calories += calories

        pral = 0.49 * protein + 0.037 * phosphorus - 0.021 * potassium - 0.026 * magnesium - 0.013 * calcium
        total_pral += pral

    # Insert meal nutrition calculation
    await db.execute(
        """INSERT INTO meal_nutrition_calculations
           (meal_id, calories_total, protein_g_total, potassium_mg_total,
            phosphorus_mg_total, pral_total, calculated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?)""",
        (meal_id, round(total_calories, 1), round(total_protein, 1),
         round(total_potassium, 1), round(total_phosphorus, 1),
         round(total_pral, 2), now),
    )

    await db.commit()

    return {
        "meal_id": meal_id,
        "meal_type": meal_data["meal_type"],
        "meal_date": meal_date,
        "components_count": len(meal_data["components"]),
        "nutrition": {
            "calories": round(total_calories, 1),
            "protein_g": round(total_protein, 1),
            "potassium_mg": round(total_potassium, 1),
            "phosphorus_mg": round(total_phosphorus, 1),
            "pral": round(total_pral, 2),
        },
    }


async def get_meals_for_date(db: aiosqlite.Connection, user_id: int, meal_date: str) -> list:
    cursor = await db.execute(
        """SELECT m.id, m.meal_type, m.meal_date, m.notes, m.created_at,
                  mnc.calories_total, mnc.protein_g_total,
                  mnc.potassium_mg_total, mnc.phosphorus_mg_total, mnc.pral_total
           FROM meals m
           LEFT JOIN meal_nutrition_calculations mnc ON m.id = mnc.meal_id
           WHERE m.user_id = ? AND m.meal_date = ?
           ORDER BY m.created_at""",
        (user_id, meal_date),
    )
    return await cursor.fetchall()


async def get_meal_detail(db: aiosqlite.Connection, meal_id: int, user_id: int) -> dict | None:
    cursor = await db.execute(
        """SELECT m.*, mnc.calories_total, mnc.protein_g_total,
                  mnc.potassium_mg_total, mnc.phosphorus_mg_total, mnc.pral_total
           FROM meals m
           LEFT JOIN meal_nutrition_calculations mnc ON m.id = mnc.meal_id
           WHERE m.id = ? AND m.user_id = ?""",
        (meal_id, user_id),
    )
    meal = await cursor.fetchone()
    if not meal:
        return None

    cursor = await db.execute(
        """SELECT mc.*, f.name as food_name, f.local_name
           FROM meal_components mc
           JOIN foods f ON mc.food_id = f.id
           WHERE mc.meal_id = ?""",
        (meal_id,),
    )
    components = await cursor.fetchall()

    return {"meal": meal, "components": components}


async def get_daily_dashboard(db: aiosqlite.Connection, user_id: int, meal_date: str) -> dict:
    # Sum all meals for the day
    cursor = await db.execute(
        """SELECT
             COALESCE(SUM(mnc.calories_total), 0) as total_calories,
             COALESCE(SUM(mnc.protein_g_total), 0) as total_protein_g,
             COALESCE(SUM(mnc.potassium_mg_total), 0) as total_potassium_mg,
             COALESCE(SUM(mnc.phosphorus_mg_total), 0) as total_phosphorus_mg,
             COALESCE(SUM(mnc.pral_total), 0) as total_pral,
             COUNT(m.id) as meal_count
           FROM meals m
           JOIN meal_nutrition_calculations mnc ON m.id = mnc.meal_id
           WHERE m.user_id = ? AND m.meal_date = ?""",
        (user_id, meal_date),
    )
    daily = await cursor.fetchone()

    # Get user's nutrient targets
    cursor = await db.execute(
        """SELECT nt.*, n.name as nutrient_name
           FROM nutrient_targets nt
           JOIN nutrients n ON nt.nutrient_id = n.id
           WHERE nt.user_id = ?""",
        (user_id,),
    )
    targets = await cursor.fetchall()

    return {"date": meal_date, "totals": daily, "targets": targets}


async def get_weekly_trends(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        """SELECT m.meal_date,
             SUM(mnc.calories_total) as calories,
             SUM(mnc.protein_g_total) as protein_g,
             SUM(mnc.potassium_mg_total) as potassium_mg,
             SUM(mnc.phosphorus_mg_total) as phosphorus_mg,
             SUM(mnc.pral_total) as pral,
             COUNT(m.id) as meals
           FROM meals m
           JOIN meal_nutrition_calculations mnc ON m.id = mnc.meal_id
           WHERE m.user_id = ? AND m.meal_date >= date('now', '-7 days')
           GROUP BY m.meal_date
           ORDER BY m.meal_date""",
        (user_id,),
    )
    return await cursor.fetchall()
