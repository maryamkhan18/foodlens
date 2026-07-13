import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/firebase_service.dart';

class MealBalanceScreen extends StatefulWidget {
  const MealBalanceScreen({super.key});

  @override
  State<MealBalanceScreen> createState() => _MealBalanceScreenState();
}

class _MealBalanceScreenState extends State<MealBalanceScreen> {
  final TextEditingController _mealController = TextEditingController();
  Map? profile;
  Map? result;
  bool loading = false;
  bool analyzing = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final data = await FirebaseService.getProfile();
    if (data != null) {
      setState(() => profile = data);
    }
  }

  Future<void> analyzeMeal() async {
    if (_mealController.text.trim().isEmpty) return;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please set up your profile first")),
      );
      return;
    }

    setState(() => analyzing = true);
    try {
      final response = await http.post(
        Uri.parse(
          "https://foodlens-production-9e4f.up.railway.app/meal-balance",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "profile": {
            "age": profile!["age"],
            "gender": profile!["gender"],
            "weight": profile!["weight"],
            "height": profile!["height"],
            "activity": profile!["activity"],
            "goal": profile!["goal"],
          },
          "meal_input": _mealController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() => result = jsonDecode(response.body));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => analyzing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meal Balance Analyzer"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
              );
              loadProfile();
            },
          ),
        ],
      ),
      body: profile == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Setup your profile first",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileSetupScreen(),
                        ),
                      );
                      loadProfile();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      "Setup Profile",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PROFILE SUMMARY
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.teal],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white, size: 30),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile!["name"] ?? "User",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${profile!["age"]}y • ${profile!["gender"]} • ${profile!["goal"]}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // MEAL INPUT
                  const Text(
                    "What did you eat?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Enter your breakfast or current meal",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _mealController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "e.g. 2 parathas and 1 omelette",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: analyzing ? null : analyzeMeal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: analyzing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Analyze Meal",
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  if (result != null) ...[
                    const SizedBox(height: 30),
                    _buildResult(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildResult() {
    final targets = result!["targets"] as Map;
    final consumed = result!["consumed"] as Map;
    final lunch = result!["lunch_suggestions"] as List;
    final dinner = result!["dinner_suggestions"] as List;

    // analysis String hai backend se
    final String analysisText = result!["analysis"]?.toString() ?? "";

    // micros
    final microsConsumed = result!["micros_consumed"] as Map? ?? {};
    final microsTargets = result!["micros_targets"] as Map? ?? {};

    // unrecognized foods — backend se aane wali woh words jo FOOD_DB mein
    // match nahi hue, isliye unki calories/macros count hi nahi hue
    final unrecognized = (result!["unrecognized_foods"] as List?) ?? [];

    // progress calculate karo
    Map<String, double> progress = {};
    for (var key in targets.keys) {
      double t = double.tryParse(targets[key].toString()) ?? 1;
      double c = double.tryParse(consumed[key]?.toString() ?? "0") ?? 0;
      progress[key.toString()] = t > 0 ? (c / t * 100).clamp(0, 100) : 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DAILY TARGETS
        const Text(
          "Daily Targets",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _macroRow(
          "🔥 Calories",
          targets["calories"],
          consumed["calories"],
          progress["calories"] ?? 0,
          Colors.orange,
        ),
        _macroRow(
          "💪 Protein",
          targets["protein"],
          consumed["protein"],
          progress["protein"] ?? 0,
          Colors.blue,
        ),
        _macroRow(
          "🍚 Carbs",
          targets["carbs"],
          consumed["carbs"],
          progress["carbs"] ?? 0,
          Colors.amber,
        ),
        _macroRow(
          "🧈 Fat",
          targets["fat"],
          consumed["fat"],
          progress["fat"] ?? 0,
          Colors.red,
        ),

        // UNRECOGNIZED FOODS WARNING
        if (unrecognized.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${unrecognized.join(', ')} — not available in our database, so it's not counted in the totals above.",
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // MICROS
        const Text(
          "Micronutrients",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _macroRow(
          "🌾 Fiber",
          microsTargets["fiber_g"],
          microsConsumed["fiber_g"],
          microsTargets["fiber_g"] != null
              ? ((microsConsumed["fiber_g"] ?? 0) /
                        microsTargets["fiber_g"] *
                        100)
                    .clamp(0, 100)
              : 0,
          Colors.green,
        ),
        _macroRow(
          "🦴 Calcium",
          microsTargets["calcium_mg"],
          microsConsumed["calcium_mg"],
          microsTargets["calcium_mg"] != null
              ? ((microsConsumed["calcium_mg"] ?? 0) /
                        microsTargets["calcium_mg"] *
                        100)
                    .clamp(0, 100)
              : 0,
          Colors.teal,
        ),
        _macroRow(
          "🩸 Iron",
          microsTargets["iron_mg"],
          microsConsumed["iron_mg"],
          microsTargets["iron_mg"] != null
              ? ((microsConsumed["iron_mg"] ?? 0) /
                        microsTargets["iron_mg"] *
                        100)
                    .clamp(0, 100)
              : 0,
          Colors.brown,
        ),
        _macroRow(
          "🍊 Vitamin C",
          microsTargets["vitc_mg"],
          microsConsumed["vitc_mg"],
          microsTargets["vitc_mg"] != null
              ? ((microsConsumed["vitc_mg"] ?? 0) /
                        microsTargets["vitc_mg"] *
                        100)
                    .clamp(0, 100)
              : 0,
          Colors.deepOrange,
        ),

        const SizedBox(height: 20),

        // ANALYSIS
        const Text(
          "Meal Analysis",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            analysisText,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
        ),

        const SizedBox(height: 20),

        // LUNCH
        const Text(
          "Suggested Lunch 🍽️",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...lunch.map((l) => _suggestionCard(l.toString(), Colors.green)),

        const SizedBox(height: 20),

        // DINNER
        const Text(
          "Suggested Dinner 🌙",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...dinner.map((d) => _suggestionCard(d.toString(), Colors.indigo)),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _macroRow(
    String label,
    dynamic target,
    dynamic consumed,
    dynamic progress,
    Color color,
  ) {
    double pct = progress is double
        ? progress
        : (double.tryParse(progress.toString()) ?? 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                "${consumed ?? 0} / ${target ?? 0}",
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${pct.toStringAsFixed(0)}% complete",
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionCard(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant_menu, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

// ─── PROFILE SETUP SCREEN ─────────────────────────────────────────────
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String gender = "Male";
  String activity = "Moderately Active";
  String goal = "Maintain Weight";

  @override
  void initState() {
    super.initState();
    loadExisting();
  }

  Future<void> loadExisting() async {
    final p = await FirebaseService.getProfile();
    if (p != null) {
      _nameController.text = p["name"] ?? "";
      _ageController.text = p["age"]?.toString() ?? "";
      _weightController.text = p["weight"]?.toString() ?? "";
      _heightController.text = p["height"]?.toString() ?? "";
      setState(() {
        gender = p["gender"] ?? "Male";
        activity = p["activity"] ?? "Moderately Active";
        goal = p["goal"] ?? "Maintain Weight";
      });
    }
  }

  Future<void> saveProfile() async {
    if (_nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _heightController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final profile = {
      "name": _nameController.text.trim(),
      "age": int.tryParse(_ageController.text) ?? 25,
      "gender": gender,
      "weight": double.tryParse(_weightController.text) ?? 70,
      "height": double.tryParse(_heightController.text) ?? 170,
      "activity": activity,
      "goal": goal,
    };

    await FirebaseService.saveProfile(Map<String, dynamic>.from(profile));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Profile"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.teal],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person, color: Colors.white, size: 30),
                  SizedBox(width: 12),
                  Text(
                    "Personal Information",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            _field("Name", _nameController, "Enter your name"),
            _field("Age", _ageController, "e.g. 25", isNumber: true),
            _field("Weight (kg)", _weightController, "e.g. 70", isNumber: true),
            _field(
              "Height (cm)",
              _heightController,
              "e.g. 170",
              isNumber: true,
            ),

            const SizedBox(height: 15),

            _dropdown("Gender", gender, [
              "Male",
              "Female",
            ], (v) => setState(() => gender = v!)),

            _dropdown("Activity Level", activity, [
              "Sedentary",
              "Lightly Active",
              "Moderately Active",
              "Very Active",
            ], (v) => setState(() => activity = v!)),

            _dropdown("Goal", goal, [
              "Weight Loss",
              "Maintain Weight",
              "Weight Gain",
              "Healthy Eating",
            ], (v) => setState(() => goal = v!)),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Save Profile",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}