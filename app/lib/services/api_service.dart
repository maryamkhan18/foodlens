import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiService {

  static Future<Map<String, dynamic>> analyzeFood(
      File imageFile) async {

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://192.168.100.9:8000/analyze"),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    var response = await request.send();

    var responseData =
        await response.stream.bytesToString();

    return jsonDecode(responseData);
  }
  // ================= DIETARY FEATURE =================



  static const baseUrl = "http://192.168.100.9:8000";

  // GET CONDITIONS
  static Future<List> getConditions() async {
    final res = await http.get(Uri.parse("$baseUrl/diet/conditions"));
    return jsonDecode(res.body);
  }

  // GET ALLOWED
  static Future<List> getAllowed(String condition) async {
    final res = await http.get(Uri.parse("$baseUrl/diet/$condition/allowed"));
    return jsonDecode(res.body);
  }

  // GET AVOID
  static Future<List> getAvoid(String condition) async {
    final res = await http.get(Uri.parse("$baseUrl/diet/$condition/avoid"));
    return jsonDecode(res.body);
  }

  // GET WEEKLY PLAN
  static Future<List> getWeekly(String condition) async {
    final res = await http.get(Uri.parse("$baseUrl/diet/$condition/weekly"));
    return jsonDecode(res.body);
  }
}



