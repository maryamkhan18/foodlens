import requests

USDA_API_KEY = "Jpjx05kVTq0Evhoe3TYvySvjZv6Uni05YBsOe79z"

def get_ingredients_usda(food_name):
    """USDA se ingredients/description lo"""
    try:
        url = "https://api.nal.usda.gov/fdc/v1/foods/search"
        params = {
            "query": food_name,
            "api_key": USDA_API_KEY,
            "pageSize": 1,
        }
        response = requests.get(url, params=params)
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
        response = requests.get(url, params=params)
        data = response.json()

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
    FALLBACK = {
        "nasi goreng": {"calories": 250, "protein": 8, "carbs": 35, "fats": 10, "fiber": 2, "sugar": 3, "sodium": 500},
        "fried rice": {"calories": 250, "protein": 8, "carbs": 35, "fats": 10, "fiber": 2, "sugar": 3, "sodium": 500},
        "chicken": {"calories": 200, "protein": 25, "carbs": 0, "fats": 12, "fiber": 0, "sugar": 0, "sodium": 300},
        "rice": {"calories": 130, "protein": 3, "carbs": 28, "fats": 1, "fiber": 1, "sugar": 0, "sodium": 10},
        "burger": {"calories": 295, "protein": 17, "carbs": 24, "fats": 14, "fiber": 1, "sugar": 5, "sodium": 600},
        "pizza": {"calories": 266, "protein": 11, "carbs": 33, "fats": 10, "fiber": 2, "sugar": 4, "sodium": 550},
        "biryani": {"calories": 290, "protein": 12, "carbs": 40, "fats": 10, "fiber": 2, "sugar": 2, "sodium": 450},
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