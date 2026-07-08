import re

# ── Nutrition Database ────────────────────────────────────────────
# tuple format: (calories, protein_g, carbs_g, fat_g, fiber_g, calcium_mg, iron_mg, vitc_mg)
FOOD_DB = {

# ==========================================================
# GRAINS & BREAD
# ==========================================================

"roti": (120,3,25,1,2,20,1.0,0),
"chapati": (120,3,25,1,2,20,1.0,0),
"paratha": (260,5,36,10,2,30,1.5,0),
"naan": (280,8,50,5,2,40,1.5,0),
"puri": (200,3,24,10,1,20,0.8,0),

"bread": (80,3,15,1,1,25,0.8,0),
"white bread": (80,3,15,1,1,25,0.8,0),
"brown bread": (90,4,17,1,2,30,1.2,0),

"rice": (200,4,44,0,1,15,1.0,0),
"white rice": (200,4,44,0,1,15,1.0,0),
"brown rice": (215,5,45,2,3,20,1.2,0),

"oats": (300,10,54,5,4,50,3.5,0),
"oatmeal": (300,10,54,5,4,50,3.5,0),

"cornflakes": (360,10,84,1,2,10,8,15),

"pasta": (220,8,43,1,2,20,1.2,0),

# ==========================================================
# BIRYANI & RICE
# ==========================================================

"biryani": (400,20,45,14,2,60,2.5,5),

"chicken biryani": (420,25,45,14,2,60,2.8,5),

"beef biryani": (450,27,45,16,2,65,3.2,5),

"vegetable biryani": (320,8,55,7,4,70,2.4,15),

"chicken pulao": (390,23,46,10,2,40,2.0,4),

"pulao": (360,10,50,8,2,35,1.5,4),

# ==========================================================
# BREAKFAST
# ==========================================================

"omelette": (150,11,2,11,0,50,1.5,0),

"egg": (78,6,0,5,0,25,1.0,0),

"boiled egg": (78,6,0,5,0,25,1.0,0),

"fried egg": (90,6,0,7,0,25,1.0,0),

"scrambled egg": (95,7,1,7,0,28,1.0,0),

# ==========================================================
# CHICKEN
# ==========================================================

"chicken": (165,31,0,4,0,15,1.0,0),

"grilled chicken": (165,31,0,4,0,15,1.0,0),

"chicken curry": (280,25,8,16,1,40,2.0,5),

"fried chicken": (320,26,8,20,1,25,1.5,0),

"chicken tikka": (220,32,2,9,0,20,1.5,2),

"chicken karahi": (290,30,5,16,1,35,2.2,5),

# ==========================================================
# BEEF
# ==========================================================

"beef": (250,26,0,15,0,18,2.5,0),

"beef curry": (330,28,8,20,1,22,3.5,3),

"beef steak": (270,30,0,17,0,18,2.8,0),

# ==========================================================
# FISH
# ==========================================================

"fish": (130,26,0,3,0,30,0.8,0),

"grilled fish": (150,28,0,4,0,35,1.0,0),

"fried fish": (240,24,8,14,0,30,1.0,0),
# ===== DAIRY =====
"milk": (150,8,12,8,0,300,0.1,2),
"yogurt": (100,5,12,3,0,180,0.1,1),
"dahi": (100,5,12,3,0,180,0.1,1),
"lassi": (150,6,17,4,0,220,0.1,1),
"cheese": (110,7,0,9,0,200,0.2,0),
"paneer": (265,18,4,20,0,480,0.5,0),

# ===== FRUITS =====
"banana": (90,1,23,0,3,5,0.3,9),
"apple": (80,0,21,0,4,10,0.1,8),
"mango": (100,1,25,0,2,2,0.2,36),
"orange": (60,1,15,0,3,50,0.1,53),
"almonds": (170,6,6,15,3,75,1.0,0),

}

LUNCH_PROTEIN  = ["Grilled Chicken + Rice + Salad", "Dal + Roti + Yogurt", "Fish + Vegetables + Brown Rice"]
LUNCH_CARBS    = ["Chicken Pulao + Salad", "Beef Curry + Naan", "Vegetable Biryani + Raita"]
LUNCH_BALANCED = ["Dal + Roti + Sabzi + Yogurt", "Grilled Fish + Rice + Salad", "Lentil Soup + Brown Bread + Vegetables"]

DINNER_PROTEIN  = ["Chicken Soup + Salad", "Egg Omelette + Vegetables", "Grilled Fish + Steamed Vegetables"]
DINNER_CARBS    = ["Dal + Brown Rice", "Chicken Curry + Roti", "Vegetable Soup + Bread"]
DINNER_BALANCED = ["Dal + Roti + Salad", "Chicken + Vegetables + Brown Rice", "Lentil Soup + Egg + Vegetables"]

# Combo drinks: if any of these keywords appear, and the "base" ingredient isn't
# already explicitly mentioned in the text, silently add the base's nutrition.
# Using \b word boundaries so we don't accidentally match "milk" inside some
# unrelated word, or "shake" as a false substring of something else.
# Every combo automatically expands into its ingredients

COMBO_FOODS = {

"banana milkshake":["banana","milk"],
"banana shake":["banana","milk"],
"banana smoothie":["banana","milk"],

"mango milkshake":["mango","milk"],
"mango shake":["mango","milk"],
"mango smoothie":["mango","milk"],

"apple shake":["apple","milk"],

"orange shake":["orange","milk"],

"dry fruit shake":["milk","almonds"],



"tea with milk":["tea","milk"],

"coffee with milk":["coffee","milk"],



"lassi":["yogurt"],

}

QTY_WORDS = {

"half":0.5,
"¼":0.25,
"½":0.5,
"¾":0.75,

"one":1,
"a":1,
"an":1,

"two":2,
"three":3,
"four":4,
"five":5,

"double":2,
"triple":3

}
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


def _find_word_boundary(processed_text, food):
    """Find `food` in `processed_text` on word boundaries only, so short food
    names (e.g. 'egg', 'tea', 'nuts') don't get falsely matched inside an
    unrelated longer word. Returns the match object or None."""
    pattern = r"(?<!\w)" + re.escape(food) + r"(?!\w)"
    return re.search(pattern, processed_text)


def parse_meal(meal_text):

    text = meal_text.lower().strip()

    # ---------- Normalize ----------

    text = text.replace("-", " ")
    text = text.replace(",", " ")
    text = text.replace("/", " ")

    text = re.sub(r"\s+", " ", text)

    calories = 0.0
    protein = 0.0
    carbs = 0.0
    fat = 0.0
    fiber = 0.0
    calcium = 0.0
    iron = 0.0
    vitc = 0.0

    matched_foods = []

    processed_text = text

    # Longest names first
    sorted_foods = sorted(
        FOOD_DB.keys(),
        key=len,
        reverse=True,
    )
    

    # ====================================================
    # SMART COMBO EXPANSION
    # ====================================================

    for combo, ingredients in COMBO_FOODS.items():
        
       if combo in processed_text:

        # remove combo words first
         processed_text = processed_text + " " + " ".join(ingredients)
    # ====================================================
    # COMMON ALIASES
    # ====================================================

    aliases = {

        "chapatti":"chapati",
        "chapattis":"chapati",

        "roti":"roti",
        "rotis":"roti",

        "eggs":"egg",

        "bananas":"banana",

        "mangoes":"mango",

        "apples":"apple",

        "oranges":"orange",

        "milks":"milk",

        "yoghurt":"yogurt",

        "dahi":"yogurt",

        "tea":"chai",

    }
   

    for old,new in aliases.items():

        processed_text = re.sub(
            rf"\b{old}\b",
            new,
            processed_text
        )

    # ====================================================
    # QUANTITY NORMALIZATION
    # ====================================================

    for word,value in QTY_WORDS.items():

        processed_text = re.sub(
            rf"\b{word}\b",
            str(value),
            processed_text
        )
            # ====================================================
    # FOOD DETECTION ENGINE
    # ====================================================

    while True:

        found = False

        for food in sorted_foods:

            match = _find_word_boundary(processed_text, food)

            if match is None:
                continue

            found = True

            qty = 1.0

            before = processed_text[:match.start()].strip().split()

            if before:

                last = before[-1]

                # Numeric quantity
                try:
                    qty = float(last)
                except:
                    pass

            values = FOOD_DB[food]

            calories += values[0] * qty
            protein += values[1] * qty
            carbs += values[2] * qty
            fat += values[3] * qty
            fiber += values[4] * qty
            calcium += values[5] * qty
            iron += values[6] * qty
            vitc += values[7] * qty

            matched_foods.append(food)

            # Remove matched food so it won't be counted again
            processed_text = (
                processed_text[:match.start()]
                + " "
                + processed_text[match.end():]
            )

            break

        if not found:
            break

    # ====================================================
    # REMOVE DUPLICATES
    # ====================================================

    matched_foods = list(dict.fromkeys(matched_foods))
        # ====================================================
    # UNKNOWN FOOD FALLBACK
    # ====================================================

    if len(matched_foods) == 0:

        calories = 300
        protein = 10
        carbs = 40
        fat = 8
        fiber = 3
        calcium = 50
        iron = 1.5
        vitc = 5

    # ====================================================
    # RETURN
    # ====================================================

    return {

        "calories": round(calories),

        "protein": round(protein, 1),

        "carbs": round(carbs, 1),

        "fat": round(fat, 1),

        "fiber": round(fiber, 1),

        "calcium": round(calcium, 1),

        "iron": round(iron, 1),

        "vitc": round(vitc, 1),

        "matched_foods": matched_foods,

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
