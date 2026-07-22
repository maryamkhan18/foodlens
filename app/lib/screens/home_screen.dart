import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'barcode_screen.dart';
import 'camera_screen.dart';
import 'diet_tracker_screen.dart';
import 'ai_insights_screen.dart';
import 'meal_balance_screen.dart';
import 'recipe_adjuster_screen.dart';
import 'diet_planner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> fade;
  late Animation<Offset> slide;

  int totalScans   = 0;
  int healthyMeals = 0;
  int alerts       = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadStats();
  }

  Future<void> loadStats() async {
    final stats = await FirebaseService.getStats();
    setState(() {
      totalScans   = stats["total"]   ?? 0;
      healthyMeals = stats["healthy"] ?? 0;
      alerts       = stats["alerts"]  ?? 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget statCard(String title, String value, IconData icon, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title,
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      body: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text("AI FoodLens ",
                      style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text("Smart AI-powered food analysis",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 25),

                  // HERO CARD
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFE8734A), Color(0xFFF4A261)]),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE8734A).withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant, size: 45, color: Colors.white),
                        SizedBox(height: 10),
                        Text("Analyze Your Meal Instantly",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text("Calories, nutrition & health score using AI",
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // STATS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      statCard("Scans", totalScans.toString(),
                          Icons.camera_alt, const Color(0xFFE8734A)),
                      statCard("Healthy", healthyMeals.toString(),
                          Icons.favorite, const Color(0xFF7C9A62)),
                      statCard("Alerts", alerts.toString(),
                          Icons.warning, const Color(0xFFE0A458)),
                    ],
                  ),

                  const SizedBox(height: 30),

                  buildCard(
                    title: "Scan Food",
                    subtitle: "Analyze food using camera AI",
                    icon: Icons.camera_alt,
                    color: const Color(0xFFE8734A),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const CameraScreen())),
                  ),
                  buildCard(
                    title: "Barcode Scanner",
                    subtitle: "Scan packaged food products",
                    icon: Icons.qr_code_scanner,
                    color: const Color(0xFFE0A458),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const BarcodeScreen())),
                  ),
                  buildCard(
                    title: "Meal Balance Analyzer",
                    subtitle: "Personalized daily nutrition plan",
                    icon: Icons.balance,
                    color: const Color(0xFF7C9A62),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const MealBalanceScreen())),
                  ),
                  buildCard(
                    title: "Recipe Adjuster",
                    subtitle: "Adjust recipes to what you have",
                    icon: Icons.tune,
                    color: const Color(0xFFD9695B),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const RecipeAdjusterScreen())),
                  ),
                 
                  buildCard(
                    title: "Weekly Diet Tracker",
                    subtitle: "Track your nutrition weekly",
                    icon: Icons.calendar_month,
                    color: const Color(0xFFC98A4B),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const DietTrackerScreen())),
                  ),
                  buildCard(
  title: "Diet Planner",
  subtitle: "Disease based meal system",
  icon: Icons.health_and_safety,
  color: const Color(0xFFB05C3D),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const DietPlannerScreen(),
    ),
  ),
),
                  buildCard(
                    title: "AI Insights",
                    subtitle: "Smart diet analysis from history",
                    icon: Icons.insights,
                    color: const Color(0xFF8C6B4F),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const AIInsightsScreen())),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}