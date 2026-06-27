import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {

  static final FlutterTts _tts = FlutterTts();

  static Future<void> speak(Map result) async {

    int score = result["health_score"] ?? 50;

    String message = "";

    if (score > 75) {
      message = "Great choice! This meal is healthy and balanced.";
    } 
    else if (score > 40) {
      message = "This meal is okay, but try adding more vegetables.";
    } 
    else {
      message = "This meal is high in calories. Try a healthier option next time.";
    }

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.speak(message);
  }
}