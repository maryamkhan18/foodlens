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
        "bbq": {"calories": 280, "protein": 22, "carbs": 5, "fats": 20, "fiber": 1, "sugar": 1, "sodium": 550},
        "biryani": {"calories": 290, "protein": 12, "carbs": 40, "fats": 10, "fiber": 2, "sugar": 2, "sodium": 450},
        "burger": {"calories": 295, "protein": 17, "carbs": 24, "fats": 14, "fiber": 1, "sugar": 5, "sodium": 600},
        "cake": {"calories": 350, "protein": 5, "carbs": 50, "fats": 15, "fiber": 1, "sugar": 35, "sodium": 300},
        "chaat": {"calories": 180, "protein": 5, "carbs": 30, "fats": 6, "fiber": 4, "sugar": 8, "sodium": 500},
        "chicken curry": {"calories": 250, "protein": 20, "carbs": 8, "fats": 15, "fiber": 2, "sugar": 3, "sodium": 600},
        "chinese": {"calories": 320, "protein": 12, "carbs": 45, "fats": 10, "fiber": 2, "sugar": 5, "sodium": 700},
        "dessert": {"calories": 300, "protein": 4, "carbs": 45, "fats": 12, "fiber": 1, "sugar": 30, "sodium": 150},
        "french-fries": {"calories": 312, "protein": 3.4, "carbs": 41, "fats": 15, "fiber": 3.8, "sugar": 0.3, "sodium": 210},
        "french fries": {"calories": 312, "protein": 3.4, "carbs": 41, "fats": 15, "fiber": 3.8, "sugar": 0.3, "sodium": 210},
        "haleem": {"calories": 280, "protein": 18, "carbs": 25, "fats": 12, "fiber": 3, "sugar": 1, "sodium": 550},
        "jalebi": {"calories": 350, "protein": 2, "carbs": 60, "fats": 12, "fiber": 0.5, "sugar": 50, "sodium": 50},
        "karahi": {"calories": 320, "protein": 22, "carbs": 8, "fats": 22, "fiber": 1, "sugar": 2, "sodium": 600},
        "kebab": {"calories": 250, "protein": 22, "carbs": 5, "fats": 16, "fiber": 1, "sugar": 1, "sodium": 500},
        "nihari": {"calories": 300, "protein": 20, "carbs": 10, "fats": 20, "fiber": 1, "sugar": 1, "sodium": 650},
        "omelette": {"calories": 155, "protein": 11, "carbs": 1.6, "fats": 12, "fiber": 0, "sugar": 0.6, "sodium": 250},
        "paratha": {"calories": 260, "protein": 6, "carbs": 30, "fats": 13, "fiber": 2, "sugar": 1, "sodium": 350},
        "pizza": {"calories": 266, "protein": 11, "carbs": 33, "fats": 10, "fiber": 2, "sugar": 4, "sodium": 550},
        "pulao": {"calories": 240, "protein": 8, "carbs": 40, "fats": 6, "fiber": 1.5, "sugar": 1, "sodium": 400},
        "qorma": {"calories": 300, "protein": 18, "carbs": 10, "fats": 22, "fiber": 1, "sugar": 2, "sodium": 550},
        "sandwich": {"calories": 250, "protein": 10, "carbs": 30, "fats": 9, "fiber": 2, "sugar": 3, "sodium": 450},
        "snack": {"calories": 260, "protein": 5, "carbs": 28, "fats": 14, "fiber": 2, "sugar": 2, "sodium": 400},

        # ---- purani entries bhi rakhi hain (extra coverage ke liye) ----
        "nasi goreng": {"calories": 250, "protein": 8, "carbs": 35, "fats": 10, "fiber": 2, "sugar": 3, "sodium": 500},
        "fried rice": {"calories": 250, "protein": 8, "carbs": 35, "fats": 10, "fiber": 2, "sugar": 3, "sodium": 500},
        "chicken": {"calories": 200, "protein": 25, "carbs": 0, "fats": 12, "fiber": 0, "sugar": 0, "sodium": 300},
        "rice": {"calories": 130, "protein": 3, "carbs": 28, "fats": 1, "fiber": 1, "sugar": 0, "sodium": 10},

        "default": {"calories": 300, "protein": 10, "carbs": 35, "fats": 12, "fiber": 2, "sugar": 5, "sodium": 400},
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