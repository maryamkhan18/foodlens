import 'dart:io';
import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../services/firebase_service.dart';

class ResultScreen extends StatefulWidget {
  final File image;
  final Map result;

  const ResultScreen({
    super.key,
    required this.image,
    required this.result,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {

  bool spoken = false;

  // ── THEME (visual only — matches reference UI kits) ──
  static const Color bgCream = Color(0xFFFFF8EF);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color primaryOrange = Color(0xFFFF7A45);
  static const Color accentTeal = Color(0xFF1E8A78);
  static const Color textDark = Color(0xFF2D2A26);
  static const Color textGrey = Color(0xFF9A948C);

  @override
  void initState() {
    super.initState();
    saveToFirebase();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!spoken) {
        VoiceService.speak(widget.result);
        spoken = true;
      }
    });
  }

  Future<void> saveToFirebase() async {
    try {
      final foods = widget.result["foods"];
      await FirebaseService.saveScan({
        "foods": foods is List ? foods : [foods.toString()],
        "estimated_calories": widget.result["estimated_calories"] ?? 0,
        "protein": widget.result["protein"] ?? 0,
        "carbs": widget.result["carbs"] ?? 0,
        "fats": widget.result["fats"] ?? 0,
        "fiber": widget.result["fiber"] ?? 0,
        "health_score": widget.result["health_score"] ?? 0,
        "verdict": widget.result["verdict"]?.toString() ?? "",
        "portion_advice": widget.result["portion_advice"]?.toString() ?? "",
        "health_notes": widget.result["health_notes"]?.toString() ?? "",
        "warnings": widget.result["warnings"] ?? [],
      });
    } catch (e) {
      print("[Firebase save error]: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    final List foods = widget.result["foods"] ?? [];

    final List warnings = widget.result["warnings"] ?? [];

    final String calories = widget.result["estimated_calories"]?.toString() ?? "0";
    final String protein = widget.result["protein"]?.toString() ?? "0";
    final String carbs = widget.result["carbs"]?.toString() ?? "0";
    final String fats = widget.result["fats"]?.toString() ?? "0";
    final String fiber = widget.result["fiber"]?.toString() ?? "0";
    final String healthScore = widget.result["health_score"]?.toString() ?? "0";
    final String verdict = widget.result["verdict"]?.toString() ?? "Unknown";
    final String portionAdvice = widget.result["portion_advice"]?.toString() ?? "";
    final String healthNotes = widget.result["health_notes"]?.toString() ?? "";

    int score = int.tryParse(healthScore) ?? 50;

    Color getColor() {
      if (score >= 75) return const Color(0xFF2FAE66);
      if (score >= 40) return primaryOrange;
      return const Color(0xFFE0503A);
    }

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: const Text(
          "AI Meal Analysis",
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: bgCream,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: accentTeal.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.volume_up, color: accentTeal),
              onPressed: () => VoiceService.speak(widget.result),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // IMAGE
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
                child: Image.file(
                  widget.image,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 26),

            // DETECTED FOODS
            const Text("Detected Foods",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: foods.map((food) => Chip(
                label: Text(
                  food.toString(),
                  style: const TextStyle(color: accentTeal, fontWeight: FontWeight.w600),
                ),
                backgroundColor: accentTeal.withOpacity(0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: accentTeal.withOpacity(0.25)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              )).toList(),
            ),

            const SizedBox(height: 28),

            // NUTRITION
            const Text("Nutrition Information",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 14),
            buildCard("🔥", "Calories", "$calories kcal", primaryOrange),
            buildCard("💪", "Protein", "${protein}g", accentTeal),
            buildCard("🍚", "Carbs", "${carbs}g", const Color(0xFFD9A441)),
            buildCard("🧈", "Fats", "${fats}g", const Color(0xFFE0503A)),
            buildCard("🌾", "Fiber", "${fiber}g", const Color(0xFF2FAE66)),

            const SizedBox(height: 26),

            // HEALTH SCORE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [getColor(), getColor().withOpacity(0.75)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: getColor().withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        "Health Score: $healthScore / 100",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(verdict,
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                  if (healthNotes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(healthNotes,
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // PORTION ADVICE
            if (portionAdvice.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: accentTeal.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentTeal.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restaurant, color: accentTeal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(portionAdvice,
                          style: const TextStyle(fontSize: 15, color: textDark)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 26),

            // WARNINGS
            const Text("AI Health Warnings",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 14),

            if (warnings.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2FAE66).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2FAE66).withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: Color(0xFF2FAE66), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text("No major health risks detected",
                          style: TextStyle(color: textDark)),
                    ),
                  ],
                ),
              )
            else
              ...warnings.map((w) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryOrange.withOpacity(0.25)),
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
                        color: primaryOrange.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning, color: primaryOrange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(w.toString(), style: const TextStyle(color: textDark))),
                  ],
                ),
              )),

            const SizedBox(height: 40),
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