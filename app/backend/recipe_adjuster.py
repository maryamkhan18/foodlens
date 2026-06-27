# recipe_adjuster.py — FastAPI version
from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
from recipes_data import RECIPES, SUBSTITUTES

router = APIRouter()

# ─── Pydantic Models ─────────────────────────────────────────────────────────

class SearchRequest(BaseModel):
    query: str

class AdjustRequest(BaseModel):
    recipe_name: str
    available: dict
    substitutions: Optional[dict] = {}

# ─── Helpers ─────────────────────────────────────────────────────────────────

def get_substitutes(name: str):
    return SUBSTITUTES.get(name.lower(), [])


def analyze_ingredients(recipe_ingredients, available: dict):
    available = {k.lower(): v for k, v in available.items()}
    missing, low, ratios = [], [], []

    for ing in recipe_ingredients:
        name = ing["name"].lower()
        req  = ing["qty"]
        have = available.get(name)

        if have is None or have <= 0:
            missing.append(ing)
        elif have < req:
            low.append({**ing, "have": have})
            ratios.append(have / req)
        else:
            ratios.append(1.0)

    scale = min(ratios) if ratios else 1.0
    return {
        "missing":      missing,
        "low_qty":      low,
        "scale_factor": round(max(0.1, min(scale, 1.0)), 2),
    }


def scale_recipe(recipe, scale: float):
    return {
        "name":     recipe["name"],
        "category": recipe.get("category", ""),
        "servings": round(recipe["servings"] * scale, 1),
        "ingredients": [
            {"name": i["name"], "qty": round(i["qty"] * scale, 2), "unit": i["unit"]}
            for i in recipe["ingredients"]
        ],
        "steps": recipe["steps"],
    }


def find_recipe(name: str):
    name = name.lower().strip()
    # 1. exact key
    if name in RECIPES:
        return RECIPES[name]
    # 2. match by display name field
    for r in RECIPES.values():
        if r.get("name", "").lower() == name:
            return r
    return None

# ─── Routes ──────────────────────────────────────────────────────────────────

@router.post("/recipe-search")
def search(req: SearchRequest):
    q = req.query.lower().strip()
    if not q:
        return {"found": False, "suggestions": list(RECIPES.keys())[:20]}

    # exact
    if q in RECIPES:
        return {"found": True, "recipe": RECIPES[q]}

    # partial match on key or name
    matches = [
        (k, r) for k, r in RECIPES.items()
        if q in k or q in r.get("name", "").lower()
    ]
    if matches:
        return {"found": True, "recipe": matches[0][1], "total_matches": len(matches)}

    # word-level fallback → suggestions only
    words = q.split()
    suggestions = [
        k for k, r in RECIPES.items()
        if any(w in k or w in r.get("name", "").lower() for w in words)
    ]
    return {"found": False, "suggestions": suggestions[:10]}


@router.post("/recipe-adjust")
def adjust_recipe(req: AdjustRequest):
    recipe = find_recipe(req.recipe_name)
    if recipe is None:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Recipe not found")

    analysis = analyze_ingredients(recipe["ingredients"], req.available)

    # substitutes for missing ingredients
    sub_suggestions = {
        ing["name"]: get_substitutes(ing["name"])
        for ing in analysis["missing"]
    }

    # scale recipe
    adjusted = scale_recipe(recipe, analysis["scale_factor"])

    # apply chosen substitutions
    subs = req.substitutions or {}
    for ing in adjusted["ingredients"]:
        if ing["name"].lower() in subs:
            ing["substituted"] = subs[ing["name"].lower()]

    return {
        "recipe":         recipe,
        "analysis":       analysis,
        "sub_suggestions": sub_suggestions,
        "adjusted_recipe": adjusted,
    }


@router.get("/recipe-list")
def list_recipes():
    return {"recipes": list(RECIPES.keys()), "total": len(RECIPES)}