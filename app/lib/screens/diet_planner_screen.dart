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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      appBar: AppBar(
        title: const Text(
          "Diet Planner",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFFFDF6EC),
        foregroundColor: const Color(0xFF3A2E28),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // SELECT DISEASE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text("Select a condition"),
                    value: selected,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
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
                ),
              ),

              const SizedBox(height: 20),

              if (selected != null) ...[
                _buildFoodSection(
                  title: "Allowed Foods",
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  items: allowed,
                  emptyLabel: "No allowed foods listed",
                ),

                const SizedBox(height: 16),

                _buildFoodSection(
                  title: "Avoid Foods",
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                  items: avoid,
                  emptyLabel: "No restricted foods listed",
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final res = await ApiService.getWeekly(selected!);
                      setState(() => weekly = res);
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text(
                      "Generate 7 Day Plan",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],

              Expanded(
                child: selected == null
                    ? _buildEmptyState()
                    : weekly.isEmpty
                        ? _buildNoPlanState()
                        : ListView.separated(
                            itemCount: weekly.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final d = weekly[i];
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                      color: Colors.grey.shade200),
                                ),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d["day"].toString(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _mealRow("Breakfast",
                                          d["breakfast"], Icons.wb_sunny_outlined),
                                      const SizedBox(height: 4),
                                      _mealRow("Lunch",
                                          d["lunch"], Icons.lunch_dining_outlined),
                                      const SizedBox(height: 4),
                                      _mealRow("Dinner",
                                          d["dinner"], Icons.dinner_dining_outlined),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodSection({
    required String title,
    required IconData icon,
    required Color color,
    required List items,
    required String emptyLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          items.isEmpty
              ? Text(
                  emptyLabel,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items.map((e) {
                    return Chip(
                      label: Text(e.toString()),
                      backgroundColor: color.withOpacity(0.08),
                      labelStyle: TextStyle(
                        color: color.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      side: BorderSide(color: color.withOpacity(0.3)),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _mealRow(String label, dynamic value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey.shade800, fontSize: 13.5),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value?.toString() ?? "-"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "Select a condition to get started",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlanState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 44, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "Tap \"Generate 7 Day Plan\" to see your meals",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}