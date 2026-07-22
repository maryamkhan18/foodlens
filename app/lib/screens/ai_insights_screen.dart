import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  List scans = [];
  String insight = "";
  String recommendation = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadData();
  }

  Future<void> loadData() async {
    scans = await FirebaseService.getScanHistory();
    generateInsights();
    setState(() => loading = false);
  }

  void generateInsights() {
    if (scans.isEmpty) {
      setState(() {
        insight = "No data available yet";
        recommendation = "Start scanning meals to get AI insights.";
      });
      return;
    }

    int highCal = 0;
    int unhealthy = 0;
    int totalCal = 0;
    Map<String, int> foodCount = {};

    for (var item in scans) {
      int cal = int.tryParse(item["estimated_calories"]?.toString() ?? "0") ?? 0;
      int score = int.tryParse(item["health_score"]?.toString() ?? "50") ?? 50;

      totalCal += cal;
      if (cal > 500) highCal++;
      if (score < 50) unhealthy++;

      // foods list handle karo
      final foods = item["foods"];
      String foodKey = foods is List ? foods.first.toString() : foods.toString();
      foodCount[foodKey] = (foodCount[foodKey] ?? 0) + 1;
    }

    String mostEaten = foodCount.entries.isNotEmpty
        ? foodCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : "N/A";

    int avgCal = totalCal ~/ scans.length;

    setState(() {
      insight = "📊 ${scans.length} meals logged\n"
          "🔥 Avg calories: $avgCal kcal\n"
          "⚠️ High-calorie meals: $highCal\n"
          "❌ Unhealthy choices: $unhealthy\n"
          "🍽️ Most eaten: $mostEaten";

      if (unhealthy > scans.length / 2) {
        recommendation = "Your diet needs improvement. Reduce fried & processed food. Try adding more vegetables and lean protein.";
      } else if (highCal > scans.length / 2) {
        recommendation = "Calorie intake is high. Try smaller portions and avoid sugary drinks.";
      } else {
        recommendation = "Good job! Keep it up. Try increasing protein & fiber for better nutrition.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      appBar: AppBar(
        title: const Text("AI Diet Insights"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // AI ANALYSIS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8734A), Color(0xFFF4A261)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("🧠 AI Analysis",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(insight,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15, height: 1.8)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // STATS ROW
                  if (scans.isNotEmpty) ...[
                    Row(
                      children: [
                        _statCard("Total Scans", scans.length.toString(), const Color(0xFFE8734A)),
                        const SizedBox(width: 12),
                        _statCard(
                          "Healthy",
                          scans.where((e) =>
                            (int.tryParse(e["health_score"]?.toString() ?? "0") ?? 0) >= 70
                          ).length.toString(),
                          Colors.teal,
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          "Unhealthy",
                          scans.where((e) =>
                            (int.tryParse(e["health_score"]?.toString() ?? "0") ?? 0) < 50
                          ).length.toString(),
                          Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                  ],

                  // RECOMMENDATION
                  const Text("💡 AI Recommendation",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C9A62).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF7C9A62).withOpacity(0.3)),
                    ),
                    child: Text(recommendation,
                        style: const TextStyle(fontSize: 16, height: 1.5)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 5),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}