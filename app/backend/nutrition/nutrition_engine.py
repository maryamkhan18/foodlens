from food_dataset import food_dataset
from portion_estimator import estimate_portion

def analyze_meal(detected_items):

    total = {
        "calories": 0,
        "protein": 0,
        "carbs": 0,
        "fats": 0
    }

    breakdown = []

    for item in detected_items:

        data = food_dataset.get(item)

        if data:

            grams = estimate_portion(item)

            multiplier = grams / 100

            calories = data["calories_per_100g"] * multiplier

            protein = data["protein"] * multiplier
            carbs = data["carbs"] * multiplier
            fats = data["fats"] * multiplier

            total["calories"] += int(calories)
            total["protein"] += int(protein)
            total["carbs"] += int(carbs)
            total["fats"] += int(fats)

            breakdown.append({
                "item": item,
                "grams": grams,
                "calories": int(calories)
            })

    return {
        "total": total,
        "breakdown": breakdown
    }