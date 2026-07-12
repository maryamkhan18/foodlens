from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
import shutil
import os
import datetime
from dietary_router import router as dietary_router

from mobilenet_model import detect_food
from history_store import save_history
from ai_insights import generate_insights
from weekly_tracker import get_weekly_data
from nutrition_api import get_nutrition
from health_engine import calculate_health_score
from meal_balance import parse_meal, process_meal_balance
from nutrition_engine import analyze_meal

# ── Recipe Adjuster ──
from recipe_adjuster import router as recipe_router

app = FastAPI()


@app.get("/test")
def test_meal():
    return parse_meal("banana shake")


# Register recipe routes
app.include_router(recipe_router)
app.include_router(dietary_router)


# -------------------------------------------------------
# ANALYZE ENDPOINT
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
            "error": "No food detected in image. Please upload a clearer food image.",
            "foods": [],
            "health_score": 0,
            "verdict": "No food detected"
        }

    food_name = detected[0]

    local_result = analyze_meal(detected)
    local_total = local_result["total"]

    if local_total["calories"] == 0:
        try:
            gemini_nutrition = get_nutrition(food_name)
            portion = gemini_nutrition.get("estimated_portion_grams", 250)
            total = {
                "calories": round(gemini_nutrition["calories"]),
                "protein": round(gemini_nutrition["protein"], 1),
                "carbs": round(gemini_nutrition["carbs"], 1),
                "fats": round(gemini_nutrition["fats"], 1),
                "fiber": round(gemini_nutrition.get("fiber", 0), 1),
                "sugar": round(gemini_nutrition.get("sugar", 0), 1),
                "sodium": round(gemini_nutrition.get("sodium", 0)),
            }
            health_notes = gemini_nutrition.get("health_notes", "")
            nutrition_source = "AI Analysis"
            estimated_portion = portion
        except Exception as e:
            return {
                "error": f"AI analysis failed: {str(e)}",
                "foods": detected,
            }
    else:
        total = local_total
        total["fiber"] = 0
        total["sugar"] = 0
        total["sodium"] = 0
        health_notes = ""
        nutrition_source = "Local Dataset"
        estimated_portion = 250

    # ---------------------------------------------------
    # HEALTH ANALYSIS (Groq AI with fallback)
    # ---------------------------------------------------
    calories = total["calories"]
    sustainability_score = 80
    food = food_name.lower()

    if "beef" in food or "steak" in food:
        sustainability_score = 45
    elif "chicken" in food:
        sustainability_score = 60
    elif "vegetable" in food or "salad" in food or "rice" in food:
        sustainability_score = 75

        score, verdict = calculate_health_score(total)

    calories = total["calories"]

    if calories < 300:
        portion_advice = "Light meal, you can add more protein or vegetables."
    elif calories < 500:
        portion_advice = "Good portion size, well balanced."
    elif calories < 700:
        portion_advice = "Moderate meal, try reducing carbs slightly."
    else:
        portion_advice = "Heavy meal! Reduce portion size and fats."

    warnings = []

    protein = total.get("protein", 0)
    fats = total.get("fats", 0)
    carbs = total.get("carbs", 0)
    sugar = total.get("sugar", 0)
    sodium = total.get("sodium", 0)
    fiber = total.get("fiber", 0)

    if calories > 800:
        warnings.append("⚠️ Very high calorie meal.")
    elif calories > 600:
        warnings.append("⚠️ High calorie meal.")

    if fats > 30:
        warnings.append("⚠️ High fat content.")

    if sodium > 800:
        warnings.append("⚠️ Very high sodium.")

    if sugar > 20:
        warnings.append("⚠️ High sugar content.")

    if protein < 8:
        warnings.append("⚠️ Low protein.")

    if fiber < 2:
        warnings.append("💡 Low fiber. Add vegetables.")

    if not warnings:
        warnings.append("✅ Nutritionally balanced meal.")

    sustainability_score = 80
    food = food_name.lower()

    if "beef" in food or "steak" in food:
        sustainability_score = 45
    elif "chicken" in food:
        sustainability_score = 60
    elif "vegetable" in food or "salad" in food or "rice" in food:
        sustainability_score = 75
        # Fallback
        score, verdict = calculate_health_score(total)

        if calories < 300:
            portion_advice = "Light meal, you can add more protein or vegetables."
        elif calories < 500:
            portion_advice = "Good portion size."
        elif calories < 700:
            portion_advice = "Moderate meal."
        else:
            portion_advice = "Heavy meal."

        warnings = ["⚠️ AI health analysis unavailable. Showing estimated analysis."]

    # ---------------------------------------------------
    # SAVE HISTORY + RETURN (dono cases ke liye common)
    # ---------------------------------------------------
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
        "fiber": total.get("fiber", "N/A"),
        "sugar": total.get("sugar", "N/A"),
        "sodium": total.get("sodium", "N/A"),
        "health_score": score,
        "verdict": verdict,
        "health_notes": health_notes,
        "portion_advice": portion_advice,
        "sustainability_score": sustainability_score,
        "warnings": warnings
    }


# -------------------------------------------------------
# MEAL BALANCE ENDPOINT
# -------------------------------------------------------
class MealBalanceInput(BaseModel):
    profile: dict
    meal_input: str


@app.post("/meal-balance")
def meal_balance(data: MealBalanceInput):
    return process_meal_balance(data.profile, data.meal_input)


# -------------------------------------------------------
# INSIGHTS + WEEKLY
# -------------------------------------------------------
@app.get("/insights")
def insights():
    return generate_insights()


@app.get("/weekly")
def weekly():
    return get_weekly_data()