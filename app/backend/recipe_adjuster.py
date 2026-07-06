# recipe_adjuster.py — FastAPI version
from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
import re
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

# Words that don't carry substitute-relevant meaning; stripped before matching.
_NOISE_WORDS = {
    "fresh", "boiled", "chopped", "sliced", "grated", "large", "small",
    "medium", "raw", "cooked", "ripe", "whole", "ground", "crushed",
    "minced", "diced", "roasted", "toasted",
}


def _normalize(name: str) -> str:
    """Lowercase, strip punctuation, drop noise words, light singularize."""
    name = name.lower().strip()
    name = re.sub(r"[^a-z0-9\s]", " ", name)
    words = [w for w in name.split() if w not in _NOISE_WORDS]
    words = [
        w[:-1] if w.endswith("s") and len(w) > 3 and not w.endswith("ss") else w
        for w in words
    ]
    return " ".join(words).strip()


# Broad, keyword-triggered fallback options for ingredient categories that
# SUBSTITUTES doesn't have specific entries for (lentils/daal, masala
# blends, etc.). Used only when exact/normalized/whole-word matching in
# SUBSTITUTES finds nothing at all. Level "general" marks these as less
# precise than a curated SUBSTITUTES entry, so the UI can badge them
# differently if it wants to.
CATEGORY_FALLBACKS = [
    (
        {"daal", "dal", "lentil", "lentils", "chana", "masoor", "moong"},
        [
            {"sub": "Any other lentil/daal you have (1:1, adjust cook time)", "level": "general"},
            {"sub": "Split Peas (1:1, cooks slightly longer)", "level": "general"},
        ],
    ),
    (
        {"masala", "seasoning"},
        [
            {"sub": "Curry Powder (1:1, adjust to taste)", "level": "general"},
            {"sub": "Mix of cumin + coriander + chili + turmeric you have (to taste)", "level": "general"},
        ],
    ),
    (
        {"paste"},
        [
            {"sub": "Fresh minced version of the same aromatics (roughly 2x paste amount)", "level": "general"},
        ],
    ),
    (
        {"powder"},
        [
            {"sub": "Closest ground spice you have (start with half, adjust to taste)", "level": "general"},
        ],
    ),
]


def get_substitutes(name: str):
    """
    Look up substitutes for an ingredient name.

    Tries exact match, then normalized match, then a whole-word fallback
    match (e.g. "garlic" found inside "ginger garlic paste"). If none of
    those find anything, falls back to a broad CATEGORY_FALLBACKS match
    (e.g. any "daal"/lentil, any "masala"/spice blend) so the user still
    gets a generic option instead of an empty list.
    """
    if not name:
        return []

    lname = name.lower()

    if lname in SUBSTITUTES:
        return SUBSTITUTES[lname]

    norm = _normalize(name)

    if norm in SUBSTITUTES:
        return SUBSTITUTES[norm]

    norm_words = set(norm.split())
    candidates = [
        key for key in SUBSTITUTES
        if all(kw in norm_words for kw in key.split())
    ]

    if candidates:
        best_key = max(candidates, key=len)
        return SUBSTITUTES[best_key]

    # Nothing specific matched -- try a broad category fallback.
    for keywords, fallback_subs in CATEGORY_FALLBACKS:
        if any(kw in norm_words for kw in keywords):
            return fallback_subs

    return []


# ── NEW: ratio parsing so a chosen substitute actually changes quantity ──

_UNICODE_FRACTIONS = {
    "\u00bc": 0.25, "\u00bd": 0.5, "\u00be": 0.75,
    "\u2153": 1 / 3, "\u2154": 2 / 3, "\u215b": 0.125,
}


def _frac_token_to_float(token: str) -> float:
    """Turn '1\u00bc', '\u00be', '2', '1.5' into a float, mixing numerals + unicode fractions."""
    total = 0.0
    digits = ""
    for ch in token:
        if ch in _UNICODE_FRACTIONS:
            total += _UNICODE_FRACTIONS[ch]
        else:
            digits += ch
    if digits:
        try:
            total += float(digits)
        except ValueError:
            pass
    return total


_FRACTION_CHARS = "".join(_UNICODE_FRACTIONS.keys())
_NUM_TOKEN = rf"[\d{_FRACTION_CHARS}\.]+"


def parse_sub_ratio(sub_text: str) -> float:
    """
    Extract a quantity multiplier from a substitute description, e.g.:

        "Melted Butter (1:1)"                      -> 1.0
        "Applesauce (\u00bd amount for baking)"      -> 0.5
        "Baking Soda (3x amount)"                   -> 3.0
        "Honey (\u00be cup per 1 cup sugar)"          -> 0.75
        "Sugar Syrup (1\u00bc cup sugar + \u00bc cup water)" -> 1.25

    Falls back to 1.0 (i.e. "use the same quantity") if nothing parseable.
    Note: this scales QUANTITY only, it does not swap units -- for subs
    that change units entirely (e.g. eggs -> tbsp yogurt) the number will
    be right but the displayed unit stays the original recipe's unit.
    """
    if not sub_text:
        return 1.0

    text = sub_text.lower()
    paren = re.search(r"\(([^)]*)\)", text)
    inner = paren.group(1) if paren else text

    # "1:1", "2:1" ratio style
    m = re.search(r"(\d+(?:\.\d+)?)\s*:\s*(\d+(?:\.\d+)?)", inner)
    if m:
        a, b = float(m.group(1)), float(m.group(2))
        if b != 0:
            return a / b

    # "Nx amount" style, e.g. "3x amount", "2x amount"
    m = re.search(rf"({_NUM_TOKEN})\s*x\s*amount", inner)
    if m:
        val = _frac_token_to_float(m.group(1))
        if val > 0:
            return val

    # "<frac> (of )?amount" style, e.g. "half amount", "\u00be amount for baking"
    m = re.search(rf"({_NUM_TOKEN})\s*(?:of\s*)?amount", inner)
    if m:
        val = _frac_token_to_float(m.group(1))
        if val > 0:
            return val

    # "<frac> <unit> per ..." / "<frac> <unit> ..." at the start of the
    # parenthetical, e.g. "\u00be cup per 1 cup sugar", "1\u00bc cup sugar + ..."
    m = re.match(rf"({_NUM_TOKEN})\s*[a-z]+", inner)
    if m:
        val = _frac_token_to_float(m.group(1))
        if val > 0:
            return val

    return 1.0


def analyze_ingredients(recipe_ingredients, available: dict, substitutions: dict = None):
    available = {k.lower(): v for k, v in available.items()}
    substitutions = {k.lower(): v for k, v in (substitutions or {}).items()}
    missing, low, ratios = [], [], []

    for ing in recipe_ingredients:
        name = ing["name"].lower()
        req  = ing["qty"]
        have = available.get(name)

        # If the user already chose a substitute for this ingredient,
        # treat it as fulfilled -- it shouldn't drag the recipe scale
        # down or keep showing up as "missing".
        if name in substitutions:
            ratios.append(1.0)
            continue

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

    subs = {k.lower(): v for k, v in (req.substitutions or {}).items()}

    analysis = analyze_ingredients(recipe["ingredients"], req.available, subs)

    # substitutes for ingredients still missing (and not already resolved
    # by a chosen substitution)
    sub_suggestions = {
        ing["name"]: get_substitutes(ing["name"])
        for ing in analysis["missing"]
    }

    # scale recipe
    adjusted = scale_recipe(recipe, analysis["scale_factor"])

    # apply chosen substitutions -- NEW: actually re-scale quantity using
    # the substitute's own ratio (e.g. "3/4 amount", "1:1", "3x amount")
    # instead of just tagging the name and leaving qty untouched.
    for ing in adjusted["ingredients"]:
        key = ing["name"].lower()
        if key in subs:
            sub_text = subs[key]
            ratio = parse_sub_ratio(sub_text)
            ing["qty"] = round(ing["qty"] * ratio, 2)
            ing["substituted"] = sub_text
            ing["sub_ratio"] = ratio

    return {
        "recipe":         recipe,
        "analysis":       analysis,
        "sub_suggestions": sub_suggestions,
        "adjusted_recipe": adjusted,
    }


@router.get("/recipe-list")
def list_recipes():
    return {"recipes": list(RECIPES.keys()), "total": len(RECIPES)}