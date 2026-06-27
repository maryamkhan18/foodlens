def calculate_health_score(nutrition):
    """
    Nutrition dict se health score calculate karo (0-100)
    Calories, protein, carbs, fats, fiber sab consider hoga
    """
    calories = float(nutrition.get("calories", 300))
    protein = nutrition.get("protein", 10)
    carbs = nutrition.get("carbs", 30)
    fats = nutrition.get("fats", 10)
    fiber = nutrition.get("fiber", 0)
    sugar = nutrition.get("sugar", 0)
    sodium = nutrition.get("sodium", 400)

    score = 100

    # --- Calorie penalty ---
    if calories > 700:
        score -= 30
    elif calories > 500:
        score -= 15
    elif calories > 350:
        score -= 5

    # --- Carbs penalty ---
    try:
        if float(carbs) > 60:
            score -= 20
        elif float(carbs) > 40:
            score -= 10
    except:
        pass

    # --- Sugar penalty ---
    try:
        if float(sugar) > 20:
            score -= 15
        elif float(sugar) > 10:
            score -= 7
    except:
        pass

    # --- Sodium penalty ---
    try:
        if float(sodium) > 800:
            score -= 15
        elif float(sodium) > 500:
            score -= 7
    except:
        pass

    # --- Fat penalty ---
    try:
        if float(fats) > 30:
            score -= 15
        elif float(fats) > 20:
            score -= 7
    except:
        pass

    # --- Protein bonus ---
    try:
        if float(protein) > 25:
            score += 15
        elif float(protein) > 15:
            score += 8
        elif float(protein) > 8:
            score += 4
    except:
        pass

    # --- Fiber bonus ---
    try:
        if float(fiber) > 5:
            score += 10
        elif float(fiber) > 2:
            score += 5
    except:
        pass

    # Clamp 0-100
    score = max(0, min(100, score))

    # Verdict
    if score >= 75:
        verdict = "Healthy 🥗"
    elif score >= 50:
        verdict = "Moderate ⚠️"
    else:
        verdict = "Unhealthy ❌"

    return score, verdict