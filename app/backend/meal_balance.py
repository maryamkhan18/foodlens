
import re
import random

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

# "tikka" as a standalone word — earlier only "chicken tikka" existed,
# so a plate like "tikka biryani" silently dropped the tikka's nutrition.
"tikka": (220,32,2,9,0,20,1.5,2),

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

# ── Suggestion Pools ──────────────────────────────────────────────
# Built from the actual dishes in FOOD_DB (plus common sides that aren't
# tracked nutritionally but are realistic pairings). These pools are
# intentionally bigger and more varied than a fixed 3-item list, so lunch
# and dinner suggestions differ each time and don't repeat what the user
# just ate.

PROTEIN_FOCUS_POOL = [
    "Grilled Chicken + Brown Rice + Salad",
    "Chicken Tikka + Roti + Raita",
    "Grilled Fish + Steamed Vegetables + Brown Rice",
    "Boiled Eggs + Whole Wheat Toast + Salad",
    "Paneer Tikka + Roti + Cucumber Raita",
    "Chicken Curry + Brown Rice + Salad",
    "Beef Steak + Steamed Vegetables + Salad",
    "Fish Curry + Brown Rice + Vegetables",
    "Chicken Karahi + Roti + Salad",
    "Grilled Chicken + Lentil Soup (Dal) + Salad",
    "Egg White Omelette + Whole Wheat Toast",
    "Beef Curry + Roti + Salad",
    "Grilled Fish + Quinoa + Steamed Greens",
    "Chicken Tikka + Lentil Soup (Dal) + Salad",
]

CARB_FOCUS_POOL = [
    "Chicken Biryani + Raita + Salad",
    "Vegetable Biryani + Yogurt",
    "Chicken Pulao + Salad",
    "Beef Biryani + Raita",
    "Plain Rice + Chicken Curry + Salad",
    "Naan + Chicken Curry + Salad",
    "Whole Wheat Pasta + Grilled Chicken",
    "Vegetable Pulao + Yogurt",
    "Paratha + Omelette + Yogurt",
    "Rice + Beef Curry + Salad",
    "Naan + Chicken Karahi + Salad",
]

BALANCED_POOL = [
    "Dal + Roti + Sabzi + Yogurt",
    "Grilled Fish + Rice + Salad",
    "Lentil Soup (Dal) + Brown Bread + Vegetables",
    "Chicken Curry + Roti + Salad",
    "Vegetable Biryani + Raita",
    "Grilled Chicken + Vegetables + Brown Rice",
    "Egg Curry + Roti + Salad",
    "Fish + Steamed Vegetables + Rice",
    "Paneer + Roti + Salad",
    "Beef Curry + Brown Rice + Vegetables",
    "Chicken Pulao + Cucumber Raita",
    "Oatmeal + Boiled Eggs + Fruit",
]

# Keywords used to detect whether a suggestion overlaps with what the
# user already ate, so we can avoid repeating the same protein/dish twice
# in one day.
_VARIETY_KEYWORDS = [
    "chicken", "beef", "fish", "paneer", "egg", "biryani", "pulao",
    "tikka", "karahi",
]


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
    # UNRECOGNIZED WORDS CHECK
    # ====================================================
    # After removing all matched foods, whatever meaningful words remain
    # were never counted in the totals. We surface them so the analysis
    # doesn't silently pretend the meal was smaller than it actually was.

    STOPWORDS = {
        "and", "with", "a", "an", "the", "of", "some", "plate", "bowl",
        "cup", "glass", "piece", "pieces", "serving", "plain",
    }

    leftover_words = [
        w for w in re.findall(r"[a-zA-Z]+", processed_text)
        if w not in STOPWORDS and not w.isdigit()
    ]
    unrecognized_foods = list(dict.fromkeys(leftover_words))

    # ====================================================
    # UNKNOWN FOOD FALLBACK
    # ====================================================
    # If NOTHING in the text matched any food in our database, we no longer
    # invent a fake guess (the old "assume 300 kcal" behaviour). That silently
    # lied to the user about what they ate. Instead we flag the meal as
    # "not recognized" so the caller can honestly show "Not available"
    # instead of a made-up number.

    recognized = len(matched_foods) > 0

    if not recognized:

        return {

            "calories": None,
            "protein": None,
            "carbs": None,
            "fat": None,
            "fiber": None,
            "calcium": None,
            "iron": None,
            "vitc": None,

            "matched_foods": matched_foods,
            "unrecognized_foods": unrecognized_foods,
            "recognized": False,

        }

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

        "unrecognized_foods": unrecognized_foods,

        "recognized": True,

    }


def generate_analysis(consumed, targets):
    """
    Realistic single-meal analysis.

    Judges the meal mostly on its own absolute numbers (like a nutritionist
    looking at "what's on this one plate"), then adds micronutrient context
    (fiber/calcium/iron/vitamin C) using a fair one-meal share (~1/3 of the
    daily target) rather than just the calorie % of the whole day.
    """

    # ---- Meal wasn't recognized at all: say so plainly, no fake numbers ----
    if not consumed.get("recognized", True):
        unrecog = consumed.get("unrecognized_foods", [])
        if unrecog:
            items = ", ".join(f"'{w}'" for w in unrecog)
            return (
                f"We couldn't find {items} in our food database, so we can't "
                "calculate accurate nutrition for this meal. Try describing it "
                "with more common food names (e.g. roti, rice, chicken, egg), "
                "or log the individual ingredients instead."
            )
        return (
            "We couldn't recognize this meal in our food database, so we "
            "can't calculate accurate nutrition for it. Try describing it "
            "with more common food names, or log the individual ingredients "
            "instead."
        )

    lines = []

    calories = consumed["calories"]
    protein = consumed["protein"]
    carbs = consumed["carbs"]
    fat = consumed["fat"]
    fiber = consumed.get("fiber", 0)
    calcium = consumed.get("calcium", 0)
    iron = consumed.get("iron", 0)
    vitc = consumed.get("vitc", 0)

    cal_pct = calories / max(targets["calories"], 1) * 100

    # ---- Absolute, per-meal calorie judgement (main signal) ----
    if calories < 250:
        lines.append(f"This is a light meal ({calories} kcal).")
    elif calories < 450:
        lines.append(f"This is a moderate, well-portioned meal ({calories} kcal).")
    elif calories < 650:
        lines.append(f"This is a fairly rich meal ({calories} kcal) — go lighter on your next meal.")
    else:
        lines.append(f"This is a heavy, calorie-dense meal ({calories} kcal) — try smaller portions next time.")

    # ---- Fat / oiliness check ----
    if fat > 25:
        lines.append(f"It's also quite high in fat ({fat}g), likely from oil/ghee used in cooking — balance with lighter, low-fat meals for the rest of the day.")
    elif fat > 15:
        lines.append(f"Moderate fat content ({fat}g) — fine occasionally, but don't stack it with more fried/oily food today.")

    # ---- Protein check ----
    if protein < 10:
        lines.append("Protein is on the lower side for a full meal — consider adding chicken, eggs, fish, or lentils.")
    elif protein > 30:
        lines.append("Good protein content in this meal.")

    # ---- Carb check ----
    if carbs > 60:
        lines.append(f"Carb-heavy meal ({carbs}g) — mainly from rice/bread — pair with protein and vegetables to avoid an energy crash later.")

    # ---- Micronutrients: judge against a fair one-meal share (~1/3 of the day) ----
    fiber_share = targets.get("fiber", 30) / 3
    calcium_share = targets.get("calcium", 1000) / 3
    iron_share = targets.get("iron", 10) / 3
    vitc_share = targets.get("vitc", 80) / 3

    if fiber < fiber_share * 0.4:
        lines.append("Fiber is low for this meal — add a side salad, vegetables, or whole grains.")

    if calcium < calcium_share * 0.4:
        lines.append("Calcium is low — a glass of milk, yogurt, or some paneer would help.")

    if iron < iron_share * 0.4:
        lines.append("Iron is low in this meal — beef, spinach, or lentils are good sources to add later today.")

    if vitc < vitc_share * 0.4:
        lines.append("Vitamin C is missing — a piece of fruit (orange, mango) or fresh salad would balance this out.")

    # ---- Daily context (secondary framing, not the main verdict) ----
    if cal_pct >= 30:
        lines.append(f"This single meal already covers about {round(cal_pct)}% of your daily calorie target, so plan the rest of the day accordingly.")

    return " ".join(lines)


def _pick_suggestions(pool, count, exclude_keywords=None, avoid=None):
    """Randomly pick `count` unique suggestions from `pool`.
    - exclude_keywords: skip items containing any of these words (used to
      avoid repeating what the user just ate, e.g. don't suggest more
      chicken dishes right after a chicken meal — if that leaves too few
      options, we fall back to the full pool so we always return something).
    - avoid: items already chosen elsewhere (e.g. lunch picks, so dinner
      doesn't repeat them).
    """
    exclude_keywords = exclude_keywords or []
    avoid = avoid or []

    candidates = [item for item in pool if item not in avoid]

    if exclude_keywords:
        filtered = [
            item for item in candidates
            if not any(kw in item.lower() for kw in exclude_keywords)
        ]
        # only use the filtered (variety-aware) list if it still leaves
        # enough choices; otherwise fall back so we don't run dry
        if len(filtered) >= count:
            candidates = filtered

    random.shuffle(candidates)
    return candidates[:count]


def get_suggestions(remaining, matched_foods=None):
    """
    Builds varied lunch + dinner suggestions from bigger pools (instead of
    a fixed 3-item list), chosen based on what macro the user still needs
    most, and avoids repeating dishes similar to what they just ate.
    """
    matched_foods = matched_foods or []
    matched_lower = [f.lower() for f in matched_foods]

    eaten_keywords = [
        kw for kw in _VARIETY_KEYWORDS
        if any(kw in food for food in matched_lower)
    ]

    # "tikka" / "karahi" alone (without an explicit protein word) are
    # almost always chicken dishes in this cuisine, so treat them as
    # "chicken already eaten" too, even though the DB entry is generic.
    if ("tikka" in matched_lower or "karahi" in matched_lower) and "chicken" not in eaten_keywords:
        eaten_keywords.append("chicken")

    if remaining["protein"] > 40:
        primary_pool = PROTEIN_FOCUS_POOL
    elif remaining["carbs"] > 150:
        primary_pool = CARB_FOCUS_POOL
    else:
        primary_pool = BALANCED_POOL

    # Combine primary pool with the others so there's always a wide,
    # varied set to draw from (primary pool is just tried first/weighted).
    full_pool = list(dict.fromkeys(
        primary_pool + BALANCED_POOL + PROTEIN_FOCUS_POOL + CARB_FOCUS_POOL
    ))

    lunch = _pick_suggestions(full_pool, 5, exclude_keywords=eaten_keywords)
    dinner = _pick_suggestions(
        full_pool, 5, exclude_keywords=eaten_keywords, avoid=lunch
    )

    return lunch, dinner


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

    # ====================================================
    # MEAL NOT RECOGNIZED AT ALL
    # ====================================================
    # Nothing in the FOOD_DB matched, so we honestly report "Not available"
    # instead of fabricating calorie/macro numbers. Daily targets and
    # lunch/dinner suggestions still make sense to show though.
    if not consumed.get("recognized", True):

        analysis = generate_analysis(consumed, targets)

        # We don't know what the user still needs today, so suggestions
        # fall back to balanced, general-purpose options.
        neutral_remaining = {"calories": 0, "protein": 0, "carbs": 0, "fat": 0}
        lunch, dinner = get_suggestions(neutral_remaining, [])

        na = "Not available"

        return {
            "consumed": {
                "calories": na,
                "protein":  na,
                "carbs":    na,
                "fat":      na,
            },
            "targets": targets,
            "remaining": {
                "calories": na,
                "protein":  na,
                "carbs":    na,
                "fat":      na,
            },
            "micros_consumed": {
                "fiber_g":    na,
                "calcium_mg": na,
                "iron_mg":    na,
                "vitc_mg":    na,
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
            "matched_foods": [],
            "unrecognized_foods": consumed.get("unrecognized_foods", []),
        }

    remaining = {
        "calories": max(0, targets["calories"] - consumed["calories"]),
        "protein":  max(0, round(targets["protein"] - consumed["protein"], 1)),
        "carbs":    max(0, round(targets["carbs"]   - consumed["carbs"],   1)),
        "fat":      max(0, round(targets["fat"]     - consumed["fat"],     1)),
    }

    analysis = generate_analysis(consumed, targets)
    lunch, dinner = get_suggestions(remaining, consumed.get("matched_foods", []))

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
        "unrecognized_foods": consumed.get("unrecognized_foods", []),
    }