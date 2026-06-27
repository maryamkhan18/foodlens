import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() => loading = true);
    final data = await FirebaseService.getScanHistory();
    setState(() {
      history = data;
      loading = false;
    });
  }

  Future<void> deleteItem(int index) async {
    final docId = history[index]["doc_id"]?.toString() ?? "";
    if (docId.isNotEmpty) {
      await FirebaseService.deleteScan(docId);
    }
    setState(() => history.removeAt(index));
  }

  Future<void> deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear All History"),
        content: const Text("Are you sure you want to delete all scan history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseService.deleteAllScans();
      setState(() => history = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan History"),
        centerTitle: true,
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: deleteAll,
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.grey),
                      SizedBox(height: 15),
                      Text("No scans yet",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text("Start scanning food to build your history",
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final foods = item["foods"];
                    final foodName = foods is List
                        ? (foods).join(", ")
                        : foods.toString();
                    final calories = item["estimated_calories"]?.toString() ?? "0";
                    final score = item["health_score"]?.toString() ?? "0";
                    final scoreInt = int.tryParse(score) ?? 0;

                    Color scoreColor = scoreInt >= 70
                        ? Colors.green
                        : scoreInt >= 40 ? Colors.orange : Colors.red;

                    return Dismissible(
                      key: Key(item["doc_id"]?.toString() ?? index.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white, size: 30),
                      ),
                      onDismissed: (_) => deleteItem(index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.fastfood, color: Colors.green, size: 28),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(foodName,
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  Text("$calories kcal",
                                      style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: scoreColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text("Score: $score",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, color: scoreColor)),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => deleteItem(index),
                              child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}