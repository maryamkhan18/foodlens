from food_dataset import food_dataset

def analyze_meal(detected_items):

    total = {
        "calories": 0,
        "protein": 0,
        "carbs": 0,
        "fats": 0
    }

    breakdown = []

    for item in detected_items:

        data = food_dataset.get(item, None)

        if data:

            total["calories"] += data["calories"]
            total["protein"] += data["protein"]
            total["carbs"] += data["carbs"]
            total["fats"] += data["fats"]

            breakdown.append({
                "item": item,
                "calories": data["calories"]
            })

    return {
        "total": total,
        "breakdown": breakdown
    }