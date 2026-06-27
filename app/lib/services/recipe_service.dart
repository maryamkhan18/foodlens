import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipeService {
  static const String baseUrl = "http://YOUR_BACKEND_URL";

  // ─────────────────────────────
  // SEARCH RECIPE
  // ─────────────────────────────
  static Future<Map<String, dynamic>> searchRecipe(String query) async {
    final res = await http.post(
      Uri.parse("$baseUrl/recipe-search"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"query": query}),
    );

    return jsonDecode(res.body);
  }

  // ─────────────────────────────
  // ADJUST RECIPE
  // ─────────────────────────────
  static Future<Map<String, dynamic>> adjustRecipe(
    String recipeName,
    Map<String, double> available,
    Map<String, String> substitutions,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/recipe-adjust"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "recipe_name": recipeName,
        "available": available,
        "substitutions": substitutions,
      }),
    );

    return jsonDecode(res.body);
  }

  // ─────────────────────────────
  // LIST ALL RECIPES
  // ─────────────────────────────
  static Future<List> getAllRecipes() async {
    final res = await http.get(Uri.parse("$baseUrl/recipe-list"));
    return jsonDecode(res.body)["recipes"];
  }
}