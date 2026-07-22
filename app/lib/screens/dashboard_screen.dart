import 'package:flutter/material.dart';
import 'recipe_adjuster_screen.dart'; // ✅ FIX 1: correct import

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      appBar: AppBar(title: const Text("Nutrition Dashboard")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const Text(
              "Today's Calories",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              height: 200,
              width: double.infinity,

              decoration: BoxDecoration(
                color: const Color(0xFFE8734A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),

              child: const Center(
                child: Text(
                  "📊 Graph Coming Soon (Demo Ready)",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Card(
              child: ListTile(
                title: Text("Total Calories"),
                trailing: Text("1250 kcal"),
              ),
            ),

            const Card(
              child: ListTile(
                title: Text("Healthy Score"),
                trailing: Text("Good"),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ FIX 2: RecipeGeneratorScreen → RecipeAdjusterScreen
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecipeAdjusterScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8734A), Color(0xFFF4A261)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8734A).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Text('🍳', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recipe Adjuster',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Adjust recipes to what you have!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}