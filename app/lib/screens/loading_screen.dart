import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'result_screen.dart';

class LoadingScreen extends StatefulWidget {
  final File image;

  const LoadingScreen({super.key, required this.image});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {

  List<String> steps = [
    "Scanning image...",
    "Detecting food type...",
    "Analyzing ingredients...",
    "Calculating nutrition...",
    "Generating health score..."
  ];

  int index = 0;
  String text = "Initializing AI...";

  Timer? timer;

  @override
  void initState() {
    super.initState();
    animateSteps();
    startProcess();
  }

  // 🔥 STEP ANIMATION (FIXED + SAFE)
  void animateSteps() {
    timer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!mounted) return;

      setState(() {
        text = steps[index];
        index++;

        if (index >= steps.length) {
          index = 0; // loop safe
        }
      });
    });
  }

  // 🔥 API CALL
  Future<void> startProcess() async {

    try {
      final result = await ApiService.analyzeFood(widget.image);

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      timer?.cancel();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            image: widget.image,
            result: result,
          ),
        ),
      );
    } catch (e) {

      if (!mounted) return;

      timer?.cancel();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AI analysis failed. Try again.")),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8734A), Color(0xFFF4A261)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // 🔥 ICON WITH GLOW FEEL
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 80,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "AI FoodLens Processing",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // 🔥 STEP TEXT
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  text,
                  key: ValueKey(text),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔥 PROGRESS INDICATOR
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}