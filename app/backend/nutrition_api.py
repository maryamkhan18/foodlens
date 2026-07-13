import requests

USDA_API_KEY = "hxfZXehsbrJfKwKgzC0FQgZnExBjLDnuRfVTwn9w"



def get_ingredients_usda(food_name):
    """USDA se ingredients/description lo"""
    try:
        url = "https://api.nal.usda.gov/fdc/v1/foods/search"
        params = {
            "query": food_name,
            "api_key": USDA_API_KEY,
            "pageSize": 1,
        }
        response = requests.get(url, params=params, timeout=8)
        data = response.json()

        if data.get("foods"):
            food = data["foods"][0]
            # ingredients field
            ingredients = food.get("ingredients", "")
            if ingredients:
                return ingredients
            # fallback to description
            return food.get("description", food_name)
    except Exception as e:
        print(f"[USDA ingredients ERROR]: {e}")
    return None


def get_nutrition_usda(food_name):
    """USDA FoodData Central se real nutrition data lo"""
    try:
        url = "https://api.nal.usda.gov/fdc/v1/foods/search"
        params = {
            "query": food_name,
            "api_key": USDA_API_KEY,
            "pageSize": 1,
            "dataType": "Survey (FNDDS)"
        }
        response = requests.get(url, params=params, timeout=8)

        # ---- DEBUG: pehle status code aur raw body check karo ----
        if response.status_code != 200:
            print(f"[USDA ERROR] Non-200 status: {response.status_code} | body: {response.text[:200]}")
            return None

        if not response.text.strip():
            print("[USDA ERROR] Empty response body received (likely rate-limited or blocked).")
            return None

        try:
            data = response.json()
        except ValueError as je:
            print(f"[USDA ERROR] JSON decode failed: {je} | raw body: {response.text[:200]}")
            return None
        # -----------------------------------------------------------

        if data.get("foods"):
            food = data["foods"][0]
            nutrients = {n["nutrientName"]: n["value"] for n in food.get("foodNutrients", [])}

            return {
                "calories": round(float(nutrients.get("Energy", 300))),
                "protein": round(float(nutrients.get("Protein", 10)), 1),
                "carbs": round(float(nutrients.get("Carbohydrate, by difference", 30)), 1),
                "fats": round(float(nutrients.get("Total lipid (fat)", 10)), 1),
                "fiber": round(float(nutrients.get("Fiber, total dietary", 2)), 1),
                "sugar": round(float(nutrients.get("Sugars, total including NLEA", 5)), 1),
                "sodium": round(float(nutrients.get("Sodium, Na", 400))),
                "estimated_portion_grams": 250,
                "health_notes": f"Real USDA nutrition for {food.get('description', food_name)}",
                "source": "USDA FoodData Central"
            }
        else:
            print(f"[USDA WARNING] No foods found for query: {food_name}")
    except requests.exceptions.Timeout:
        print(f"[USDA ERROR] Request timed out for: {food_name}")
    except requests.exceptions.ConnectionError as ce:
        print(f"[USDA ERROR] Connection error (possibly blocked from this host): {ce}")
    except Exception as e:
        print(f"[USDA ERROR]: {e}")
    return None


def get_nutrition(food_name):
    result = get_nutrition_usda(food_name)
    if result:
        return result
    print(f"[WARNING] USDA failed, using fallback for: {food_name}")
    return get_fallback_nutrition(food_name)


def get_fallback_nutrition(food_name):
    # Values are approximate, per typical single-serving portion (~250g unless noted)
    FALLBACK = {
    "bbq": {"calories": 420, "protein": 38, "carbs": 6, "fats": 28, "fiber": 0},
    "biryani": {"calories": 520, "protein": 20, "carbs": 63, "fats": 20, "fiber": 3},
    "burger": {"calories": 540, "protein": 26, "carbs": 42, "fats": 30, "fiber": 3},
    "cake": {"calories": 360, "protein": 5, "carbs": 48, "fats": 17, "fiber": 1},
    "chaat": {"calories": 320, "protein": 8, "carbs": 46, "fats": 12, "fiber": 7},
    "chicken curry": {"calories": 390, "protein": 30, "carbs": 8, "fats": 26, "fiber": 2},
    "chinese": {"calories": 610, "protein": 22, "carbs": 70, "fats": 24, "fiber": 4},
    "dessert": {"calories": 350, "protein": 5, "carbs": 50, "fats": 15, "fiber": 1},
    "french-fries": {"calories": 365, "protein": 4, "carbs": 48, "fats": 17, "fiber": 4},
    "french fries": {"calories": 365, "protein": 4, "carbs": 48, "fats": 17, "fiber": 4},
    "haleem": {"calories": 430, "protein": 24, "carbs": 32, "fats": 22, "fiber": 5},
    "jalebi": {"calories": 420, "protein": 3, "carbs": 78, "fats": 12, "fiber": 0},
    "karahi": {"calories": 460, "protein": 36, "carbs": 7, "fats": 31, "fiber": 1},
    "kebab": {"calories": 310, "protein": 24, "carbs": 3, "fats": 22, "fiber": 0},
    "nihari": {"calories": 500, "protein": 28, "carbs": 9, "fats": 38, "fiber": 1},
    "omelette": {"calories": 220, "protein": 14, "carbs": 2, "fats": 17, "fiber": 0},
    "paratha": {"calories": 330, "protein": 7, "carbs": 38, "fats": 16, "fiber": 3},
    "pizza": {"calories": 430, "protein": 18, "carbs": 48, "fats": 18, "fiber": 3},
    "pulao": {"calories": 410, "protein": 14, "carbs": 55, "fats": 14, "fiber": 2},
    "qorma": {"calories": 470, "protein": 28, "carbs": 9, "fats": 35, "fiber": 1},
    "sandwich": {"calories": 360, "protein": 18, "carbs": 34, "fats": 16, "fiber": 3},
    "snack": {"calories": 280, "protein": 6, "carbs": 32, "fats": 14, "fiber": 2},
}
    key = food_name.lower().strip()
    for k, v in FALLBACK.items():
        if k in key or key in k:
            result = v.copy()
            result["estimated_portion_grams"] = 250
            result["health_notes"] = f"Estimated nutrition for {food_name}"
            result["source"] = "Fallback"
            return result
    result = FALLBACK["default"].copy()
    result["estimated_portion_grams"] = 250
    result["health_notes"] = f"Default estimate for {food_name}"
    result["source"] = "Fallback"
    return result