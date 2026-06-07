import aiosqlite
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# Glucose
# ---------------------------------------------------------------------------

async def log_glucose(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    cursor = await db.execute(
        """INSERT INTO glucose_monitoring
           (user_id, recorded_at, glucose_mg_dl, measurement_context, meal_id,
            hours_since_meal, insulin_dose_units, medication_taken, physical_activity,
            symptoms, notes)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            user_id,
            data.get("recorded_at", now),
            data["glucose_mg_dl"],
            data.get("measurement_context", "fasting"),
            data.get("meal_id"),
            data.get("hours_since_meal"),
            data.get("insulin_dose_units"),
            data.get("medication_taken"),
            data.get("physical_activity"),
            data.get("symptoms"),
            data.get("notes"),
        ),
    )
    await db.commit()
    return {"log_id": cursor.lastrowid, "glucose_mg_dl": data["glucose_mg_dl"]}


async def get_glucose_history(db: aiosqlite.Connection, user_id: int, days: int = 7) -> dict:
    cursor = await db.execute(
        """SELECT * FROM glucose_monitoring
           WHERE user_id = ? AND recorded_at >= datetime('now', ? || ' days')
           ORDER BY recorded_at DESC""",
        (user_id, f"-{days}"),
    )
    logs = await cursor.fetchall()

    cursor = await db.execute(
        """SELECT AVG(glucose_mg_dl) as avg, MAX(glucose_mg_dl) as max, MIN(glucose_mg_dl) as min
           FROM glucose_monitoring
           WHERE user_id = ? AND recorded_at >= datetime('now', ? || ' days')""",
        (user_id, f"-{days}"),
    )
    stats = await cursor.fetchone()
    return {"logs": logs, "stats": stats, "period_days": days}


# ---------------------------------------------------------------------------
# Vital signs
# ---------------------------------------------------------------------------

async def log_vitals(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    cursor = await db.execute(
        """INSERT INTO vital_signs_history
           (user_id, recorded_at, temperature_c, pulse_bpm, respiratory_rate,
            oxygen_saturation_pct, blood_pressure_systolic, blood_pressure_diastolic,
            measurement_location, measured_by, notes)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            user_id,
            data.get("recorded_at", now),
            data.get("temperature_c"),
            data.get("pulse_bpm"),
            data.get("respiratory_rate"),
            data.get("oxygen_saturation_pct"),
            data.get("blood_pressure_systolic"),
            data.get("blood_pressure_diastolic"),
            data.get("measurement_location", "arm"),
            data.get("measured_by", "self"),
            data.get("notes"),
        ),
    )
    await db.commit()
    return {"log_id": cursor.lastrowid}


async def get_vitals_history(db: aiosqlite.Connection, user_id: int, days: int = 30) -> list:
    cursor = await db.execute(
        """SELECT * FROM vital_signs_history
           WHERE user_id = ? AND recorded_at >= datetime('now', ? || ' days')
           ORDER BY recorded_at DESC""",
        (user_id, f"-{days}"),
    )
    return await cursor.fetchall()


async def get_bp_trends(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        """SELECT * FROM blood_pressure_trends
           WHERE user_id = ?
           ORDER BY analysis_date DESC
           LIMIT 30""",
        (user_id,),
    )
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# CKD biomarkers (creatinine/eGFR, potassium, phosphorus)
# ---------------------------------------------------------------------------

async def log_creatinine(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    cursor = await db.execute(
        """INSERT INTO creatinine_egfr_logs
           (user_id, creatinine_mg_dl, egfr_ml_min, egfr_formula, measured_at,
            ckd_stage, measurement_context, lab_facility_id, notes,
            bun_mg_dl, urine_albumin_mg, created_at, entered_by)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            user_id,
            data["creatinine_mg_dl"],
            data.get("egfr_ml_min"),
            data.get("egfr_formula", "CKD-EPI"),
            data.get("measured_at", now),
            data.get("ckd_stage"),
            data.get("measurement_context", "routine"),
            data.get("lab_facility_id"),
            data.get("notes"),
            data.get("bun_mg_dl"),
            data.get("urine_albumin_mg"),
            now,
            "self",
        ),
    )
    await db.commit()
    return {"log_id": cursor.lastrowid, "creatinine_mg_dl": data["creatinine_mg_dl"]}


async def log_potassium(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    value = data["potassium_value"]
    unit = data.get("unit", "mEq/L")
    # Flag critical: <3.5 or >5.5 mEq/L
    is_critical = value < 3.5 or value > 5.5 if unit == "mEq/L" else False
    risk = "critical" if is_critical else ("high" if value > 5.0 else "normal")

    cursor = await db.execute(
        """INSERT INTO potassium_logs
           (user_id, potassium_value, unit, measured_at, measurement_context,
            lab_facility_id, notes, is_critical, risk_level, created_at, entered_by)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            user_id, value, unit,
            data.get("measured_at", now),
            data.get("measurement_context", "routine"),
            data.get("lab_facility_id"),
            data.get("notes"),
            is_critical, risk, now, "self",
        ),
    )
    await db.commit()
    return {"log_id": cursor.lastrowid, "potassium_value": value, "risk_level": risk, "is_critical": is_critical}


async def log_phosphorus(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    value = data["phosphorus_mg_dl"]
    is_elevated = value > 4.5
    risk = "elevated" if is_elevated else "normal"

    cursor = await db.execute(
        """INSERT INTO phosphorus_logs
           (user_id, phosphorus_mg_dl, measured_at, measurement_context,
            lab_facility_id, notes, is_elevated, risk_level,
            calcium_mg_dl, pth_pg_ml, vitamin_d_ng_ml, created_at, entered_by)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            user_id, value,
            data.get("measured_at", now),
            data.get("measurement_context", "routine"),
            data.get("lab_facility_id"),
            data.get("notes"),
            is_elevated, risk,
            data.get("calcium_mg_dl"),
            data.get("pth_pg_ml"),
            data.get("vitamin_d_ng_ml"),
            now, "self",
        ),
    )
    await db.commit()
    return {"log_id": cursor.lastrowid, "phosphorus_mg_dl": value, "risk_level": risk}


async def get_ckd_dashboard(db: aiosqlite.Connection, user_id: int) -> dict:
    """Latest CKD biomarkers + trends for CKD dashboard."""
    cursor = await db.execute(
        "SELECT * FROM creatinine_egfr_logs WHERE user_id = ? ORDER BY measured_at DESC LIMIT 5",
        (user_id,),
    )
    creatinine = await cursor.fetchall()

    cursor = await db.execute(
        "SELECT * FROM potassium_logs WHERE user_id = ? ORDER BY measured_at DESC LIMIT 5",
        (user_id,),
    )
    potassium = await cursor.fetchall()

    cursor = await db.execute(
        "SELECT * FROM phosphorus_logs WHERE user_id = ? ORDER BY measured_at DESC LIMIT 5",
        (user_id,),
    )
    phosphorus = await cursor.fetchall()

    # 7-day nutrition totals for 3P
    cursor = await db.execute(
        """SELECT meal_date,
             SUM(protein_g_total) as protein_g,
             SUM(potassium_mg_total) as potassium_mg,
             SUM(phosphorus_mg_total) as phosphorus_mg,
             SUM(pral_total) as pral
           FROM meals m
           JOIN meal_nutrition_calculations mnc ON m.id = mnc.meal_id
           WHERE m.user_id = ? AND m.meal_date >= date('now', '-7 days')
           GROUP BY meal_date ORDER BY meal_date""",
        (user_id,),
    )
    nutrition_trends = await cursor.fetchall()

    return {
        "creatinine_egfr": creatinine,
        "potassium": potassium,
        "phosphorus": phosphorus,
        "nutrition_3p_trends": nutrition_trends,
    }
