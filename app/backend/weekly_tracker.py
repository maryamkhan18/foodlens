from history_store import load_history
from datetime import datetime, timedelta

def get_weekly_data():

    history = load_history()

    if not history:
        return {}

    now = datetime.now()
    week_ago = now - timedelta(days=7)

    weekly = []

    for item in history:

        item_time = datetime.fromisoformat(item["time"])

        if item_time >= week_ago:
            weekly.append(item)

    if not weekly:
        return {
            "message": "No data for this week"
        }

    total_calories = sum(i["calories"] for i in weekly)
    avg_calories = total_calories / len(weekly)

    healthy = sum(1 for i in weekly if i["health_score"] >= 75)
    unhealthy = len(weekly) - healthy

    return {
        "total_scans": len(weekly),
        "avg_calories": round(avg_calories),
        "healthy_meals": healthy,
        "unhealthy_meals": unhealthy,
        "insight": "You are eating more balanced meals this week 👍"
    }