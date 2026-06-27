import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DietPlannerScreen extends StatefulWidget {
  const DietPlannerScreen({super.key});

  @override
  State<DietPlannerScreen> createState() => _DietPlannerScreenState();
}

class _DietPlannerScreenState extends State<DietPlannerScreen> {
  List conditions = [];
  String? selected;

  List allowed = [];
  List avoid = [];
  List weekly = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    final res = await ApiService.getConditions();
    setState(() => conditions = res);
  }

  void loadCondition(String c) async {
    final a = await ApiService.getAllowed(c);
    final b = await ApiService.getAvoid(c);
    final w = await ApiService.getWeekly(c);

    setState(() {
      selected = c;
      allowed = a;
      avoid = b;
      weekly = w;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Diet Planner")),
      body: Column(
        children: [

          // SELECT DISEASE
          DropdownButton<String>(
            hint: const Text("Select Disease"),
            value: selected,
            items: conditions.map<DropdownMenuItem<String>>((c) {
              return DropdownMenuItem(
                value: c.toString(),
                child: Text(c.toString()),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) loadCondition(v);
            },
          ),

          const SizedBox(height: 10),

          const Text("Allowed Foods"),
          Wrap(children: allowed.map((e) => Chip(label: Text("✅ $e"))).toList()),

          const Text("Avoid Foods"),
          Wrap(children: avoid.map((e) => Chip(label: Text("❌ $e"))).toList()),

          ElevatedButton(
            onPressed: selected == null ? null : () async {
              final res = await ApiService.getWeekly(selected!);
              setState(() => weekly = res);
            },
            child: const Text("Generate 7 Day Plan"),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: weekly.length,
              itemBuilder: (context, i) {
                final d = weekly[i];
                return Card(
                  child: ListTile(
                    title: Text(d["day"]),
                    subtitle: Text(
                      "B: ${d["breakfast"]}\n"
                      "L: ${d["lunch"]}\n"
                      "D: ${d["dinner"]}",
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