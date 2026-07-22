from history_store import load_history

def generate_insights():

    history = load_history()

    if not history:
        return "No data available yet."

    total_calories = sum(h["calories"] for h in history)
    avg_calories = total_calories / len(history)

    unhealthy_count = sum(1 for h in history if h["health_score"] < 70)

    most_common_foods = {}

    for h in history:
        for f in h["foods"]:
            most_common_foods[f] = most_common_foods.get(f, 0) + 1

    top_food = max(most_common_foods, key=most_common_foods.get)

    return {
        "avg_calories": avg_calories,
        "unhealthy_meals": unhealthy_count,
        "most_common_food": top_food,
        "message": "You are consuming more " + top_food + " lately."
    }