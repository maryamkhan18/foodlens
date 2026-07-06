import os
import requests
import json
import re

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
# ─── YOLO trained dishes — exact 5 ───
INGREDIENTS_DATA = {
    "nasi goreng": "rice, egg, chicken, soy sauce, garlic, shallots, onion, chili, tomato, cucumber, green onion, sesame oil, fish sauce, sweet soy sauce",
    "rawon":       "beef, black nuts (kluwek), lemongrass, galangal, garlic, shallots, red chili, salt, oil, green onion, bean sprouts, boiled egg",
    "rendang":     "beef, coconut milk, lemongrass, galangal, garlic, shallots, red chili, turmeric, kaffir lime leaves, coriander, salt",
    "sate":        "chicken, soy sauce, garlic, shallots, turmeric, coriander, peanut sauce, lemon, skewers, sweet soy sauce",
    "soto":        "chicken, rice vermicelli, bean sprouts, boiled egg, celery, fried shallots, garlic, turmeric, ginger, lemongrass, lime, chicken broth",
}

NUTRITION_DATA = {
    "nasi goreng": {"calories": 300, "protein": 10, "carbs": 40, "fats": 12, "fiber": 2, "sugar": 4,  "sodium": 550, "estimated_portion_grams": 300, "health_notes": "Popular Indonesian fried rice, moderate calories. High sodium due to soy sauce."},
    "rawon":       {"calories": 220, "protein": 18, "carbs": 10, "fats": 14, "fiber": 2, "sugar": 2,  "sodium": 600, "estimated_portion_grams": 350, "health_notes": "Rich beef black soup, high protein. Watch sodium intake."},
    "rendang":     {"calories": 350, "protein": 25, "carbs": 8,  "fats": 24, "fiber": 2, "sugar": 3,  "sodium": 500, "estimated_portion_grams": 250, "health_notes": "Slow-cooked beef in coconut milk. High protein but also high fat."},
    "sate":        {"calories": 250, "protein": 22, "carbs": 12, "fats": 14, "fiber": 1, "sugar": 6,  "sodium": 450, "estimated_portion_grams": 200, "health_notes": "Grilled skewered meat, good protein source. Peanut sauce adds calories."},
    "soto":        {"calories": 180, "protein": 14, "carbs": 18, "fats": 6,  "fiber": 2, "sugar": 3,  "sodium": 500, "estimated_portion_grams": 400, "health_notes": "Light Indonesian soup, relatively healthy and low calorie."},
}


def get_ingredients(food_name):
    key = food_name.lower().strip()
    for k, v in INGREDIENTS_DATA.items():
        if k in key or key in k:
            return v
    return "ingredients not available"


def get_ingredients_fallback(food_name):
    return get_ingredients(food_name)


def get_nutrition_from_gemini(food_name, ingredients_text):
    key = food_name.lower().strip()
    for k, v in NUTRITION_DATA.items():
        if k in key or key in k:
            return v.copy()
    # default
    return {
        "calories": 300, "protein": 10, "carbs": 35, "fats": 12,
        "fiber": 2, "sugar": 5, "sodium": 400,
        "estimated_portion_grams": 250,
        "health_notes": f"Estimated nutrition for {food_name}"
    }


def get_fallback_nutrition(food_name):
    return get_nutrition_from_gemini(food_name, "")