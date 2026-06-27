import json
import random
import os


class DietaryRestrictionService:
    def __init__(self):
        base_dir = os.path.dirname(__file__)
        path = os.path.join(base_dir, "diseases.json")

        # FIX: encoding issue + proper loading
        with open(path, "r", encoding="utf-8") as f:
            self.db = json.load(f)["conditions"]

    def get_all_conditions(self):
        return list(self.db.keys())

    def get_allowed(self, condition):
        return self.db.get(condition, {}).get("allow", [])

    def get_avoid(self, condition):
        return self.db.get(condition, {}).get("avoid", [])

    def generate_weekly_plan(self, condition):
        data = self.db.get(condition)
        if not data:
            return []

        meals = data.get("meals", {})

        days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

        plan = []
        for day in days:
            plan.append({
                "day": day,
                "breakfast": random.choice(meals.get("breakfast", ["N/A"])),
                "lunch": random.choice(meals.get("lunch", ["N/A"])),
                "dinner": random.choice(meals.get("dinner", ["N/A"]))
            })

        return plan