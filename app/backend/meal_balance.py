# ── Nutrition Database ────────────────────────────────────────────
FOOD_DB = {
    # ── Grains & Bread ──────────────────────────────────────────
    "oats":             (300, 10,  54,  5,  4,  50,  3.5, 0),
    "oatmeal":          (300, 10,  54,  5,  4,  50,  3.5, 0),
    "paratha":          (260,  5,  36, 10,  2,  30,  1.5, 0),
    "roti":             (120,  3,  25,  1,  2,  20,  1.0, 0),
    "chapati":          (120,  3,  25,  1,  2,  20,  1.0, 0),
    "bread":            (80,   3,  15,  1,  1,  25,  0.8, 0),
    "brown bread":      (90,   4,  17,  1,  2,  30,  1.2, 0),
    "rice":             (200,  4,  44,  0,  1,  15,  1.0, 0),
    "biryani":          (400, 20,  45, 14,  2,  60,  2.5, 5),
    "chicken biryani":  (420, 25,  45, 14,  2,  60,  2.8, 5),
    "naan":             (280,  8,  50,  5,  2,  40,  1.5, 0),
    "puri":             (200,  3,  24, 10,  1,  20,  0.8, 0),
    "cornflakes":       (360, 10,  84,  1,  2,  10,  8.0, 15),
    "pasta":            (220,  8,  43,  1,  2,  20,  1.2, 0),
    # ── Proteins ────────────────────────────────────────────────
    "egg":              (78,   6,   0,  5,  0,  25,  1.0, 0),
    "omelette":         (150,  11,  2, 11,  0,  50,  1.5, 0),
    "boiled egg":       (78,   6,   0,  5,  0,  25,  1.0, 0),
    "chicken":          (165, 31,   0,  4,  0,  15,  1.0, 0),
    "grilled chicken":  (165, 31,   0,  4,  0,  15,  1.0, 0),
    "chicken curry":    (280, 25,   8, 16,  1,  40,  2.0, 5),
    "beef":             (250, 26,   0, 15,  0,  18,  2.5, 0),
    "mutton":           (294, 25,   0, 20,  0,  22,  2.8, 0),
    "fish":             (130, 26,   0,  3,  0,  30,  0.8, 0),
    "tuna":             (130, 29,   0,  1,  0,  10,  1.0, 0),
    "dal":              (180,  9,  30,  1,  8,  40,  3.5, 5),
    "lentils":          (180,  9,  30,  1,  8,  40,  3.5, 5),
    "chickpeas":        (269, 15,  45,  4, 13,  80,  5.0, 5),
    "chana":            (269, 15,  45,  4, 13,  80,  5.0, 5),
    # ── Dairy ───────────────────────────────────────────────────
    "milk":             (150,  8,  12,  8,  0, 300,  0.1, 2),
    "yogurt":           (100,  5,  12,  3,  0, 180,  0.1, 1),
    "dahi":             (100,  5,  12,  3,  0, 180,  0.1, 1),
    "cheese":           (110,  7,   0,  9,  0, 200,  0.2, 0),
    "paneer":           (265, 18,   4, 20,  0, 480,  0.5, 0),
    "butter":           (100,  0,   0, 11,  0,   2,  0.0, 0),
    # ── Vegetables ──────────────────────────────────────────────
    "salad":            (50,   2,  10,  0,  3,  50,  1.5, 30),
    "vegetables":       (80,   3,  15,  1,  4,  60,  2.0, 25),
    "spinach":          (23,   3,   4,  0,  2, 100,  2.7, 28),
    "tomato":           (20,   1,   4,  0,  1,  10,  0.5, 14),
    "potato":           (160,  4,  37,  0,  2,  15,  1.5, 15),
    "sabzi":            (80,   2,  12,  3,  3,  40,  1.5, 15),
    # ── Fruits ──────────────────────────────────────────────────
    "banana":           (90,   1,  23,  0,  3,   5,  0.3, 9),
    "apple":            (80,   0,  21,  0,  4,  10,  0.1, 8),
    "orange":           (60,   1,  15,  0,  3,  50,  0.1, 53),
    "mango":            (100,  1,  25,  0,  2,   2,  0.2, 36),
    # ── Beverages ───────────────────────────────────────────────
    "tea":              (30,   1,   5,  1,  0,  30,  0.1, 0),
    "chai":             (30,   1,   5,  1,  0,  30,  0.1, 0),
    "coffee":           (5,    0,   1,  0,  0,   5,  0.0, 0),
    "juice":            (110,  1,  26,  0,  0,  10,  0.2, 50),
    # ── Snacks ──────────────────────────────────────────────────
    "nuts":             (170,  5,   6, 15,  2,  20,  0.5, 0),
    "almonds":          (170,  6,   6, 15,  3,  75,  1.0, 0),
    "peanut butter":    (190,  8,   6, 16,  2,  17,  0.5, 0),
    "biscuits":         (150,  2,  22,  6,  0,  30,  0.5, 0),
    "samosa":           (250,  5,  32, 12,  2,  20,  1.5, 5),
}

LUNCH_PROTEIN  = ["Grilled Chicken + Rice + Salad", "Dal + Roti + Yogurt", "Fish + Vegetables + Brown Rice"]
LUNCH_CARBS    = ["Chicken Pulao + Salad", "Beef Curry + Naan", "Vegetable Biryani + Raita"]
LUNCH_BALANCED = ["Dal + Roti + Sabzi + Yogurt", "Grilled Fish + Rice + Salad", "Lentil Soup + Brown Bread + Vegetables"]

DINNER_PROTEIN  = ["Chicken Soup + Salad", "Egg Omelette + Vegetables", "Grilled Fish + Steamed Vegetables"]
DINNER_CARBS    = ["Dal + Brown Rice", "Chicken Curry + Roti", "Vegetable Soup + Bread"]
DINNER_BALANCED = ["Dal + Roti + Salad", "Chicken + Vegetables + Brown Rice", "Lentil Soup + Egg + Vegetables"]


def calculate_targets(age, gender, weight, height, activity, goal):
    if gender == "Female":
        bmr = 447.593 + 9.247 * weight + 3.098 * height - 4.330 * age
    else:
        bmr = 88.362 + 13.397 * weight + 4.799 * height - 5.677 * age

    multipliers = {
        "Sedentary": 1.2,
        "Lightly Active": 1.375,
        "Moderately Active": 1.55,
        "Very Active": 1.725,
    }
    tdee = bmr * multipliers.get(activity, 1.55)

    goal_adj = {"Weight Loss": -300, "Weight Gain": 300, "Maintain Weight": 0, "Healthy Eating": 0}
    calories = round(tdee + goal_adj.get(goal, 0))

    protein = round(weight * 1.0)
    fat = round(calories * 0.25 / 9)
    carbs = round((calories - protein * 4 - fat * 9) / 4)

    is_female = gender == "Female"
    fiber = 25 if is_female else 38
    calcium = 1200 if age >= 50 else 1000
    iron = 18 if is_female else 8
    vitc = 75 if is_female else 90

    return {
        "calories": calories, "protein": protein,
        "carbs": carbs, "fat": fat,
        "fiber": fiber, "calcium": calcium,
        "iron": iron, "vitc": vitc,
    }


def parse_meal(meal_text):
    text = meal_text.lower().strip()
    cal = pro = carb = fat = fiber = calcium = iron = vitc = 0.0
    matched = []

    for food, vals in FOOD_DB.items():
        if food in text:
            qty = 1.0
            try:
                idx = text.find(food)
                before = text[:idx].strip().split()
                if before:
                    last = before[-1]
                    if last.isdigit():
                        qty = float(last)
                    elif last in ["half", "½"]:
                        qty = 0.5
                    elif last in ["two", "double"]:
                        qty = 2.0
                    elif last in ["three"]:
                        qty = 3.0
            except Exception:
                pass

            cal     += vals[0] * qty
            pro     += vals[1] * qty
            carb    += vals[2] * qty
            fat     += vals[3] * qty
            fiber   += vals[4] * qty
            calcium += vals[5] * qty
            iron    += vals[6] * qty
            vitc    += vals[7] * qty
            matched.append(food)

    if not matched:
        cal, pro, carb, fat = 300, 10, 40, 8
        fiber, calcium, iron, vitc = 3, 50, 1.5, 5

    return {
        "calories": round(cal), "protein": round(pro, 1),
        "carbs": round(carb, 1), "fat": round(fat, 1),
        "fiber": round(fiber, 1), "calcium": round(calcium, 1),
        "iron": round(iron, 1), "vitc": round(vitc, 1),
        "matched_foods": matched,
    }


def generate_analysis(consumed, targets):
    lines = []
    cal_pct  = consumed["calories"] / max(targets["calories"], 1) * 100
    pro_pct  = consumed["protein"]  / max(targets["protein"],  1) * 100
    carb_pct = consumed["carbs"]    / max(targets["carbs"],    1) * 100
    fat_pct  = consumed["fat"]      / max(targets["fat"],      1) * 100

    if cal_pct < 20:
        lines.append("Your meal is light — you still have most of your daily calories remaining.")
    elif cal_pct < 40:
        lines.append("Good start! About a third of your daily calories consumed.")
    else:
        lines.append("This meal is quite calorie-dense. Lighter meals ahead are recommended.")

    if pro_pct < 25:
        lines.append("Protein intake is low — prioritize protein-rich foods in next meals.")
    elif pro_pct > 60:
        lines.append("Great protein intake from this meal!")
    else:
        lines.append("Protein is moderate — continue with protein-rich lunch and dinner.")

    if carb_pct > 50:
        lines.append("Carbohydrate-heavy meal. Balance with proteins and healthy fats.")
    elif carb_pct < 15:
        lines.append("Low carb meal — include energy-giving foods during the day.")

    if fat_pct < 20:
        lines.append("Healthy fats are low. Include nuts, seeds, or olive oil in later meals.")

    return " ".join(lines)


def get_suggestions(remaining):
    if remaining["protein"] > 40:
        return LUNCH_PROTEIN, DINNER_PROTEIN
    elif remaining["carbs"] > 150:
        return LUNCH_CARBS, DINNER_CARBS
    else:
        return LUNCH_BALANCED, DINNER_BALANCED


def process_meal_balance(profile: dict, meal_input: str) -> dict:
    """Main function — FastAPI se call hoga"""
    age      = int(profile.get("age", 25))
    gender   = profile.get("gender", "Male")
    weight   = float(profile.get("weight", 70))
    height   = float(profile.get("height", 170))
    activity = profile.get("activity", "Moderately Active")
    goal     = profile.get("goal", "Healthy Eating")

    targets  = calculate_targets(age, gender, weight, height, activity, goal)
    consumed = parse_meal(meal_input)

    remaining = {
        "calories": max(0, targets["calories"] - consumed["calories"]),
        "protein":  max(0, round(targets["protein"] - consumed["protein"], 1)),
        "carbs":    max(0, round(targets["carbs"]   - consumed["carbs"],   1)),
        "fat":      max(0, round(targets["fat"]     - consumed["fat"],     1)),
    }

    analysis = generate_analysis(consumed, targets)
    lunch, dinner = get_suggestions(remaining)

    return {
        "consumed": {
            "calories": consumed["calories"],
            "protein":  consumed["protein"],
            "carbs":    consumed["carbs"],
            "fat":      consumed["fat"],
        },
        "targets": targets,
        "remaining": remaining,
        "micros_consumed": {
            "fiber_g":    consumed["fiber"],
            "calcium_mg": consumed["calcium"],
            "iron_mg":    consumed["iron"],
            "vitc_mg":    consumed["vitc"],
        },
        "micros_targets": {
            "fiber_g":    targets["fiber"],
            "calcium_mg": targets["calcium"],
            "iron_mg":    targets["iron"],
            "vitc_mg":    targets["vitc"],
        },
        "analysis": analysis,
        "lunch_suggestions": lunch,
        "dinner_suggestions": dinner,
        "matched_foods": consumed.get("matched_foods", []),
    }