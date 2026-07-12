from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
import shutil
import os
import datetime

from dietary_router import router as dietary_router
from recipe_adjuster import router as recipe_router

from groq_service import analyze_health
from mobilenet_model import detect_food
from history_store import save_history
from ai_insights import generate_insights
from weekly_tracker import get_weekly_data
from nutrition_api import get_nutrition
from health_engine import calculate_health_score
from meal_balance import parse_meal, process_meal_balance
from nutrition_engine import analyze_meal

app = FastAPI()

app.include_router(recipe_router)
app.include_router(dietary_router)


@app.get("/test")
def test_meal():
    return parse_meal("banana shake")


# -------------------------------------------------------
# ANALYZE
# -------------------------------------------------------
@app.post("/analyze")
async def analyze(file: UploadFile = File(...)):

    file_path = f"temp_{file.filename}"

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    detected = detect_food(file_path)
    os.remove(file_path)

    if not detected:
        return {
            "error": "No food detected.",
            "foods": [],
            "health_score": 0,
            "verdict": "No food detected"
        }

    food_name = detected[0]

    local_result = analyze_meal(detected)
    local_total = local_result["total"]

    if local_total["calories"] == 0:

        try:
            nutrition = get_nutrition(food_name)

            estimated_portion = nutrition.get(
                "estimated_portion_grams",
                250
            )

            total = {
                "calories": round(nutrition["calories"]),
                "protein": round(nutrition["protein"], 1),
                "carbs": round(nutrition["carbs"], 1),
                "fats": round(nutrition["fats"], 1),
                "fiber": round(nutrition.get("fiber", 0), 1),
                "sugar": round(nutrition.get("sugar", 0), 1),
                "sodium": round(nutrition.get("sodium", 0))
            }

            nutrition_source = "AI Analysis"
            health_notes = nutrition.get("health_notes", "")

        except Exception as e:

            return {
                "error": str(e),
                "foods": detected
            }

    else:

        total = local_total
        total["fiber"] = 0
        total["sugar"] = 0
        total["sodium"] = 0

        estimated_portion = 250
        nutrition_source = "Local Dataset"
        health_notes = ""

    calories = total["calories"]

    sustainability_score = 80

    food = food_name.lower()

    if "beef" in food or "steak" in food:
        sustainability_score = 45

    elif "chicken" in food:
        sustainability_score = 60

    elif "salad" in food or "vegetable" in food or "rice" in food:
        sustainability_score = 75

    # ---------------- GROQ AI ----------------

    try:

        ai = analyze_health(food_name, total)

        if isinstance(ai.get("nutrition"), dict):
            total = ai["nutrition"]
            calories = total["calories"]

        score = ai.get("health_score", 70)
        verdict = ai.get("verdict", "Healthy")
        warnings = ai.get("warnings", [])
        portion_advice = ai.get("portion_advice", "")
        health_notes = ai.get("health_notes", health_notes)

        if not warnings:
            warnings = [
                "✅ Nutritionally balanced meal."
            ]

    except Exception as e:

        print("Groq Error:", e)

        score, verdict = calculate_health_score(total)

        if calories < 300:
            portion_advice = "Light meal, you can add more protein or vegetables."

        elif calories < 500:
            portion_advice = "Good portion size."

        elif calories < 700:
            portion_advice = "Moderate meal."

        else:
            portion_advice = "Heavy meal."

        warnings = [
            "⚠️ AI analysis unavailable. Showing estimated analysis."
        ]

    save_history({

        "time": str(datetime.datetime.now()),
        "foods": detected,
        "calories": calories,
        "protein": total["protein"],
        "carbs": total["carbs"],
        "fats": total["fats"],
        "health_score": score

    })

    return {

        "foods": detected,

        "nutrition_source": nutrition_source,

        "estimated_portion_grams": estimated_portion,

        "estimated_calories": calories,

        "protein": total["protein"],
        "carbs": total["carbs"],
        "fats": total["fats"],
        "fiber": total.get("fiber", 0),
        "sugar": total.get("sugar", 0),
        "sodium": total.get("sodium", 0),

        "health_score": score,
        "verdict": verdict,

        "health_notes": health_notes,

        "portion_advice": portion_advice,

        "sustainability_score": sustainability_score,

        "warnings": warnings

    }


# -------------------------------------------------------
# MEAL BALANCE
# -------------------------------------------------------

class MealBalanceInput(BaseModel):
    profile: dict
    meal_input: str


@app.post("/meal-balance")
def meal_balance(data: MealBalanceInput):
    return process_meal_balance(
        data.profile,
        data.meal_input
    )


# -------------------------------------------------------
# INSIGHTS
# -------------------------------------------------------

@app.get("/insights")
def insights():
    return generate_insights()


@app.get("/weekly")
def weekly():
    return get_weekly_data()