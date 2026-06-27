import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class DietTrackerScreen extends StatefulWidget {
  const DietTrackerScreen({super.key});

  @override
  State<DietTrackerScreen> createState() => _DietTrackerScreenState();
}

class _DietTrackerScreenState extends State<DietTrackerScreen> {
  List scans = [];
  int totalCalories = 0;
  int totalProtein = 0;
  int totalCarbs = 0;
  int totalFats = 0;
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
    final parsed = await FirebaseService.getScanHistory();

    int cal = 0, prot = 0, carb = 0, fat = 0;
    for (var item in parsed) {
      cal += int.tryParse(item["estimated_calories"]?.toString() ?? "0") ?? 0;
      prot += int.tryParse(item["protein"]?.toString() ?? "0") ?? 0;
      carb += int.tryParse(item["carbs"]?.toString() ?? "0") ?? 0;
      fat += int.tryParse(item["fats"]?.toString() ?? "0") ?? 0;
    }

    setState(() {
      scans = parsed;
      totalCalories = cal;
      totalProtein = prot;
      totalCarbs = carb;
      totalFats = fat;
      loading = false;
    });
  }

  String getHealthSummary() {
    if (scans.isEmpty) return "No data yet";
    int healthy = scans.where((e) =>
      (int.tryParse(e["health_score"]?.toString() ?? "0") ?? 0) > 60
    ).length;
    double ratio = healthy / scans.length;
    if (ratio > 0.7) return "Great Diet 🥗";
    if (ratio > 0.4) return "Average Diet ⚠️";
    return "Unhealthy Diet 🍔";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Diet Tracker"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // SUMMARY CARD
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.teal],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Weekly Summary",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text("🔥 Total Calories: $totalCalories kcal",
                          style: const TextStyle(color: Colors.white, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text("💪 Total Protein: ${totalProtein}g",
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      Text("🍚 Total Carbs: ${totalCarbs}g",
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      Text("🧈 Total Fats: ${totalFats}g",
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(getHealthSummary(),
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // RECENT MEALS
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Recent Meals",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: scans.isEmpty
                      ? const Center(
                          child: Text("No meals scanned yet",
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: scans.length,
                          itemBuilder: (context, index) {
                            final item = scans[index];
                            final foods = item["foods"];
                            final foodName = foods is List
                                ? (foods).join(", ")
                                : foods.toString();
                            final cal = item["estimated_calories"]?.toString() ?? "0";
                            final score = int.tryParse(
                                item["health_score"]?.toString() ?? "0") ?? 0;

                            Color scoreColor = score >= 70
                                ? Colors.green
                                : score >= 40
                                    ? Colors.orange
                                    : Colors.red;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: scoreColor.withOpacity(0.15),
                                  child: Icon(Icons.fastfood, color: scoreColor),
                                ),
                                title: Text(foodName,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("$cal kcal"),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: scoreColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text("$score",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: scoreColor)),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}