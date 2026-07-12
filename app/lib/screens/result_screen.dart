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
        "sugar": widget.result["sugar"] ?? 0,
        "sodium": widget.result["sodium"] ?? 0,
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
    final String sugar = widget.result["sugar"]?.toString() ?? "0";
    final String sodium = widget.result["sodium"]?.toString() ?? "0";
    final String healthScore = widget.result["health_score"]?.toString() ?? "0";
    final String verdict = widget.result["verdict"]?.toString() ?? "Unknown";
    final String portionAdvice = widget.result["portion_advice"]?.toString() ?? "";
    final String healthNotes = widget.result["health_notes"]?.toString() ?? "";

    int score = int.tryParse(healthScore) ?? 50;

    Color getColor() {
      if (score >= 75) return Colors.green;
      if (score >= 40) return Colors.orange;
      return Colors.red;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("AI Meal Analysis"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () => VoiceService.speak(widget.result),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.file(
                widget.image,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 25),

            // DETECTED FOODS
            const Text("Detected Foods",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: foods.map((food) => Chip(
                label: Text(food.toString()),
                backgroundColor: Colors.green.shade100,
              )).toList(),
            ),

            const SizedBox(height: 30),

           

            // NUTRITION
            const Text("Nutrition Information",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            buildCard("🔥 Calories", "$calories kcal"),
            buildCard("💪 Protein", "${protein}g"),
            buildCard("🍚 Carbs", "${carbs}g"),
            buildCard("🧈 Fats", "${fats}g"),
            buildCard("🌾 Fiber", "${fiber}g"),
            buildCard("🍬 Sugar", "${sugar}g"),
            buildCard("🧂 Sodium", "${sodium}mg"),

            const SizedBox(height: 30),

            // HEALTH SCORE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [getColor(), getColor().withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Health Score: $healthScore / 100",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(verdict,
                      style: const TextStyle(color: Colors.white, fontSize: 18)),
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(portionAdvice,
                          style: const TextStyle(fontSize: 15)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 25),

            // WARNINGS
            const Text("AI Health Warnings",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            if (warnings.isEmpty)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 10),
                    Expanded(child: Text("No major health risks detected")),
                  ],
                ),
              )
            else
              ...warnings.map((w) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(child: Text(w.toString())),
                  ],
                ),
              )),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget buildCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        title: Text(title),
        trailing: Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}