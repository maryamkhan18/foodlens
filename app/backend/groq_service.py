import os
import json
from groq import Groq

client = Groq(
    api_key=os.getenv("GROQ_API_KEY")
)

def analyze_health(food_name, nutrition):

    prompt = f"""
You are an expert nutritionist.

Food Name:
{food_name}

Nutrition:
{nutrition}

Check if the nutrition values look realistic.

If they are realistic, keep them.
If they are unrealistic, estimate better values.

Return ONLY valid JSON.

{{
    "nutrition": {{
        "calories": 450,
        "protein": 20,
        "carbs": 55,
        "fats": 15,
        "fiber": 5,
        "sugar": 3,
        "sodium": 500
    }},
    "health_score": 85,
    "verdict": "Healthy",
    "health_notes": "High in protein and well balanced.",
    "portion_advice": "One medium serving is ideal.",
    "warnings": [
        "Limit sodium intake.",
        "Avoid overeating.",
        "Drink enough water."
    ]
}}
"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ],
        temperature=0.2,
    )

    content = response.choices[0].message.content.strip()

    # Remove markdown if AI returns ```json
    if content.startswith("```"):
        content = content.replace("```json", "").replace("```", "").strip()

    return json.loads(content)