import 'package:flutter/material.dart';

class ProductResultScreen extends StatelessWidget {
  final Map productData;

  const ProductResultScreen({
    super.key,
    required this.productData,
  });

  int calculateScore(Map nutriments) {
    int score = 100;
    double calories = double.tryParse(nutriments["energy-kcal_100g"]?.toString() ?? "0") ?? 0;
    double sugar = double.tryParse(nutriments["sugars_100g"]?.toString() ?? "0") ?? 0;
    double fat = double.tryParse(nutriments["fat_100g"]?.toString() ?? "0") ?? 0;
    double protein = double.tryParse(nutriments["proteins_100g"]?.toString() ?? "0") ?? 0;
    double fiber = double.tryParse(nutriments["fiber_100g"]?.toString() ?? "0") ?? 0;
    double sodium = double.tryParse(nutriments["sodium_100g"]?.toString() ?? "0") ?? 0;

    if (calories > 500) score -= 25;
    else if (calories > 300) score -= 10;

    if (sugar > 20) score -= 25;
    else if (sugar > 10) score -= 10;

    if (fat > 25) score -= 20;
    else if (fat > 15) score -= 10;

    if (sodium > 1) score -= 20; // sodium in g
    else if (sodium > 0.5) score -= 10;

    if (protein > 15) score += 10;
    if (fiber > 3) score += 10;

    return score.clamp(0, 100);
  }

  List<Map<String, dynamic>> getWarnings(Map nutriments) {
    List<Map<String, dynamic>> warnings = [];

    double calories = double.tryParse(nutriments["energy-kcal_100g"]?.toString() ?? "0") ?? 0;
    double sugar = double.tryParse(nutriments["sugars_100g"]?.toString() ?? "0") ?? 0;
    double fat = double.tryParse(nutriments["fat_100g"]?.toString() ?? "0") ?? 0;
    double sodium = double.tryParse(nutriments["sodium_100g"]?.toString() ?? "0") ?? 0;
    double protein = double.tryParse(nutriments["proteins_100g"]?.toString() ?? "0") ?? 0;
    double fiber = double.tryParse(nutriments["fiber_100g"]?.toString() ?? "0") ?? 0;

    if (calories > 500)
      warnings.add({"text": "⚠️ High calories (${calories.toInt()} kcal/100g)", "color": Colors.red});
    if (sugar > 20)
      warnings.add({"text": "⚠️ Very high sugar (${sugar.toInt()}g) — risk of blood sugar spike", "color": Colors.red});
    else if (sugar > 10)
      warnings.add({"text": "⚠️ Moderate sugar (${sugar.toInt()}g) — consume in moderation", "color": Colors.orange});
    if (fat > 25)
      warnings.add({"text": "⚠️ High fat content (${fat.toInt()}g)", "color": Colors.orange});
    if (sodium > 1)
      warnings.add({"text": "⚠️ High sodium — not good for blood pressure", "color": Colors.orange});
    if (protein < 3)
      warnings.add({"text": "💡 Low protein — not filling enough", "color": Colors.blue});
    if (fiber < 1)
      warnings.add({"text": "💡 Low fiber — poor digestive benefit", "color": Colors.blue});

    if (warnings.isEmpty)
      warnings.add({"text": "✅ Nutritionally balanced product!", "color": Colors.green});

    return warnings;
  }

  @override
  Widget build(BuildContext context) {
    final product = productData["product"];
    final nutriments = product["nutriments"] ?? {};

    int score = calculateScore(nutriments);
    List<Map<String, dynamic>> warnings = getWarnings(nutriments);

    Color scoreColor = score >= 70 ? Colors.green : score >= 40 ? Colors.orange : Colors.red;
    String verdict = score >= 70 ? "Healthy ✅" : score >= 40 ? "Moderate ⚠️" : "Unhealthy ❌";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Analysis"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // PRODUCT IMAGE
            if (product["image_url"] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  product["image_url"],
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 20),

            // PRODUCT NAME
            Text(
              product["product_name"] ?? "Unknown Product",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            if (product["brands"] != null) ...[
              const SizedBox(height: 5),
              Text(product["brands"].toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 15)),
            ],

            const SizedBox(height: 20),

            // HEALTH SCORE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [scoreColor, scoreColor.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Health Score: $score / 100",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(verdict,
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // NUTRITION
            const Text("Nutrition (per 100g)",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            buildCard("🔥 Calories", "${nutriments["energy-kcal_100g"] ?? "N/A"} kcal"),
            buildCard("🍬 Sugar", "${nutriments["sugars_100g"] ?? "N/A"} g"),
            buildCard("🧈 Fat", "${nutriments["fat_100g"] ?? "N/A"} g"),
            buildCard("💪 Protein", "${nutriments["proteins_100g"] ?? "N/A"} g"),
            buildCard("🌾 Fiber", "${nutriments["fiber_100g"] ?? "N/A"} g"),
            buildCard("🧂 Sodium", "${nutriments["sodium_100g"] ?? "N/A"} g"),

            const SizedBox(height: 25),

            // WARNINGS
            const Text("Health Warnings",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ...warnings.map((w) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (w["color"] as Color).withOpacity(0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: w["color"] as Color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(w["text"],
                        style: TextStyle(
                            color: w["color"] as Color,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget buildCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(title),
        trailing: Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}