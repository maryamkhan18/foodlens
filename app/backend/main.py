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
from gemini_service import get_ingredients, get_ingredients_fallback
from nutrition_api import get_nutrition, get_ingredients_usda
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

    try:
        ingredients_text = get_ingredients_usda(food_name) or get_ingredients(food_name) or get_ingredients_fallback(food_name) or ""
    except Exception:
        ingredients_text = "Could not fetch ingredients"

    local_result = analyze_meal(detected)
    local_total  = local_result["total"]

    if local_total["calories"] == 0:
        try:
            gemini_nutrition  = get_nutrition(food_name)
            portion           = gemini_nutrition.get("estimated_portion_grams", 250)
            total = {
                "calories": round(gemini_nutrition["calories"]),
                "protein":  round(gemini_nutrition["protein"], 1),
                "carbs":    round(gemini_nutrition["carbs"], 1),
                "fats":     round(gemini_nutrition["fats"], 1),
                "fiber":    round(gemini_nutrition.get("fiber", 0), 1),
                "sugar":    round(gemini_nutrition.get("sugar", 0), 1),
                "sodium":   round(gemini_nutrition.get("sodium", 0)),
            }
            health_notes      = gemini_nutrition.get("health_notes", "")
            nutrition_source  = "AI Analysis"
            estimated_portion = portion
        except Exception as e:
            return {
                "error": f"AI analysis failed: {str(e)}",
                "foods": detected,
                "ingredients": ingredients_text
            }
    else:
        total             = local_total
        total["fiber"]    = 0
        total["sugar"]    = 0
        total["sodium"]   = 0
        health_notes      = ""
        nutrition_source  = "Local Dataset"
        estimated_portion = 250

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
    protein   = total.get("protein", 0)
    fats      = total.get("fats", 0)
    carbs_val = total.get("carbs", 0)
    sugar     = total.get("sugar", 0)
    sodium    = total.get("sodium", 0)
    fiber     = total.get("fiber", 0)

    if calories > 800:
        warnings.append(f"⚠️ Very high calories ({calories} kcal) — consider smaller portion")
    elif calories > 600:
        warnings.append(f"⚠️ High calorie meal ({calories} kcal) — balance with lighter meals today")
    if fats > 30:
        warnings.append(f"⚠️ High fat content ({fats}g) — limit saturated fat intake")
    elif fats > 20:
        warnings.append(f"⚠️ Moderate fat content ({fats}g) — watch daily fat limit")
    if sodium > 800:
        warnings.append(f"⚠️ Very high sodium ({sodium}mg) — risk of high blood pressure")
    elif sodium > 500:
        warnings.append(f"⚠️ High sodium ({sodium}mg) — not good for blood pressure")
    if sugar > 20:
        warnings.append(f"⚠️ High sugar ({sugar}g) — risk of blood sugar spike")
    elif sugar > 12:
        warnings.append(f"⚠️ Moderate sugar ({sugar}g) — watch daily sugar intake")
    if carbs_val > 70:
        warnings.append(f"⚠️ High carbohydrates ({carbs_val}g) — may cause energy crash")
    if protein < 8:
        warnings.append(f"⚠️ Low protein ({protein}g) — add lean meat or eggs for balance")
    if fiber < 2:
        warnings.append("💡 Low fiber — add vegetables or whole grains for better digestion")
    if not warnings:
        warnings.append("✅ Nutritionally balanced meal — great choice!")

    sustainability_score = 80
    ingredients_text = ingredients_text or ""
    if "beef" in ingredients_text.lower() or "meat" in ingredients_text.lower():
        sustainability_score = 45
    elif "chicken" in ingredients_text.lower():
        sustainability_score = 60
    elif "vegetable" in ingredients_text.lower() or "rice" in ingredients_text.lower():
        sustainability_score = 75

    save_history({
        "time":         str(datetime.datetime.now()),
        "foods":        detected,
        "calories":     calories,
        "protein":      total["protein"],
        "carbs":        total["carbs"],
        "fats":         total["fats"],
        "health_score": score
    })

    return {
        "foods":                   detected,
        "ingredients":             ingredients_text,
        "nutrition_source":        nutrition_source,
        "estimated_portion_grams": estimated_portion,
        "estimated_calories":      calories,
        "protein":                 total["protein"],
        "carbs":                   total["carbs"],
        "fats":                    total["fats"],
        "fiber":                   total.get("fiber", "N/A"),
        "sugar":                   total.get("sugar", "N/A"),
        "sodium":                  total.get("sodium", "N/A"),
        "health_score":            score,
        "verdict":                 verdict,
        "health_notes":            health_notes,
        "portion_advice":          portion_advice,
        "sustainability_score":    sustainability_score,
        "warnings":                warnings
    }


# -------------------------------------------------------
# COMPARE ENDPOINT
# -------------------------------------------------------
@app.post("/compare")
async def compare(file1: UploadFile = File(...), file2: UploadFile = File(...)):

    path1 = f"temp1_{file1.filename}"
    path2 = f"temp2_{file2.filename}"

    with open(path1, "wb") as buffer:
        shutil.copyfileobj(file1.file, buffer)
    with open(path2, "wb") as buffer:
        shutil.copyfileobj(file2.file, buffer)

    food1 = detect_food(path1)
    food2 = detect_food(path2)

    os.remove(path1)
    os.remove(path2)

    async def get_meal_data(foods):
        if not foods:
            return {"calories": 0, "protein": 0, "carbs": 0, "fats": 0}, 0
        local = analyze_meal(foods)["total"]
        if local["calories"] == 0:
            gemini_n = get_nutrition(foods[0])
            factor   = gemini_n.get("estimated_portion_grams", 250) / 100
            local    = {
                "calories": round(gemini_n["calories"] * factor),
                "protein":  round(gemini_n["protein"]  * factor, 1),
                "carbs":    round(gemini_n["carbs"]    * factor, 1),
                "fats":     round(gemini_n["fats"]     * factor, 1),
            }
        score, _ = calculate_health_score(local)
        return local, score

    result1, s1 = await get_meal_data(food1)
    result2, s2 = await get_meal_data(food2)

    if s1 > s2:
        winner, reason = "Image 1", "Healthier nutritional balance"
    elif s2 > s1:
        winner, reason = "Image 2", "Healthier nutritional balance"
    else:
        winner, reason = "Tie", "Both meals are nutritionally similar"

    return {
        "image1": {"foods": food1, "calories": result1["calories"], "health_score": s1},
        "image2": {"foods": food2, "calories": result2["calories"], "health_score": s2},
        "winner": winner,
        "reason": reason
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
