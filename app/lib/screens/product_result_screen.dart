import 'package:flutter/material.dart';

class ProductResultScreen extends StatelessWidget {
  final Map productData;

  const ProductResultScreen({
    super.key,
    required this.productData,
  });

  // ── THEME (visual only — matches reference UI kits) ──
  static const Color bgCream = Color(0xFFFFF8EF);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color primaryOrange = Color(0xFFFF7A45);
  static const Color accentTeal = Color(0xFF1E8A78);
  static const Color textDark = Color(0xFF2D2A26);
  static const Color textGrey = Color(0xFF9A948C);

  // ⚠️ LOGIC UNCHANGED — do not edit calculations below
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

  // ⚠️ LOGIC UNCHANGED — do not edit warnings below
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

    Color scoreColor = score >= 70 ? const Color(0xFF2FAE66) : score >= 40 ? primaryOrange : const Color(0xFFE0503A);
    String verdict = score >= 70 ? "Healthy ✅" : score >= 40 ? "Moderate ⚠️" : "Unhealthy ❌";

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: const Text(
          "Product Analysis",
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: bgCream,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // PRODUCT IMAGE
            if (product["image_url"] != null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.network(
                    product["image_url"],
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 22),

            // PRODUCT NAME
            Text(
              product["product_name"] ?? "Unknown Product",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),

            if (product["brands"] != null) ...[
              const SizedBox(height: 6),
              Text(product["brands"].toString(),
                  style: const TextStyle(color: textGrey, fontSize: 15)),
            ],

            const SizedBox(height: 22),

            // HEALTH SCORE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scoreColor, scoreColor.withOpacity(0.75)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: scoreColor.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Health Score: $score / 100",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(verdict,
                            style: const TextStyle(color: Colors.white, fontSize: 15)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // NUTRITION
            const Text("Nutrition (per 100g)",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 14),

            buildCard("🔥", "Calories", "${nutriments["energy-kcal_100g"] ?? "N/A"} kcal", primaryOrange),
            buildCard("🍬", "Sugar", "${nutriments["sugars_100g"] ?? "N/A"} g", const Color(0xFFE0503A)),
            buildCard("🧈", "Fat", "${nutriments["fat_100g"] ?? "N/A"} g", const Color(0xFFD9A441)),
            buildCard("💪", "Protein", "${nutriments["proteins_100g"] ?? "N/A"} g", accentTeal),
            buildCard("🌾", "Fiber", "${nutriments["fiber_100g"] ?? "N/A"} g", const Color(0xFF2FAE66)),
            buildCard("🧂", "Sodium", "${nutriments["sodium_100g"] ?? "N/A"} g", const Color(0xFF6C8CBF)),

            const SizedBox(height: 26),

            // WARNINGS
            const Text("Health Warnings",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 14),

            ...warnings.map((w) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (w["color"] as Color).withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (w["color"] as Color).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.info_outline, color: w["color"] as Color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(w["text"],
                        style: TextStyle(
                            color: textDark,
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

  Widget buildCard(String emoji, String title, String value, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 15, color: textDark, fontWeight: FontWeight.w500)),
          ),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, color: accent, fontSize: 15)),
        ],
      ),
    );
  }
}