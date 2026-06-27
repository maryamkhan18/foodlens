import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── SCAN HISTORY ────────────────────────────────────────────
  static Future<void> saveScan(Map<String, dynamic> scanData) async {
    try {
      await _db.collection("scan_history").add({
        ...scanData,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("[Firebase ERROR] saveScan: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getScanHistory() async {
    try {
      final snapshot = await _db
          .collection("scan_history")
          .orderBy("timestamp", descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data["doc_id"] = doc.id;
        // Timestamp ko String mein convert karo
        if (data["timestamp"] is Timestamp) {
          data["timestamp"] = (data["timestamp"] as Timestamp).toDate().toIso8601String();
        }
        return data;
      }).toList();
    } catch (e) {
      print("[Firebase ERROR] getScanHistory: $e");
      return [];
    }
  }

  static Future<void> deleteScan(String docId) async {
    try {
      await _db.collection("scan_history").doc(docId).delete();
    } catch (e) {
      print("[Firebase ERROR] deleteScan: $e");
    }
  }

  static Future<void> deleteAllScans() async {
    try {
      final snapshot = await _db.collection("scan_history").get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print("[Firebase ERROR] deleteAllScans: $e");
    }
  }

  // ─── USER PROFILE ────────────────────────────────────────────
  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    try {
      await _db.collection("user_profiles").doc("default_user").set(profile);
    } catch (e) {
      print("[Firebase ERROR] saveProfile: $e");
    }
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final doc = await _db.collection("user_profiles").doc("default_user").get();
      if (doc.exists) return doc.data();
    } catch (e) {
      print("[Firebase ERROR] getProfile: $e");
    }
    return null;
  }

  // ─── RECIPE ADJUSTER ─────────────────────────────────────────
  static Future<void> saveRecipeAdjustment(Map<String, dynamic> data) async {
    try {
      await _db.collection("recipe_adjustments").add({
        ...data,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("[Firebase ERROR] saveRecipeAdjustment: \$e");
    }
  }

  // ─── STATS ───────────────────────────────────────────────────
  static Future<Map<String, int>> getStats() async {
    try {
      final snapshot = await _db.collection("scan_history").get();
      final docs = snapshot.docs.map((d) => d.data()).toList();

      int total = docs.length;
      int healthy = docs.where((d) =>
          (int.tryParse(d["health_score"]?.toString() ?? "0") ?? 0) >= 70).length;
      int alerts = docs.where((d) =>
          (int.tryParse(d["health_score"]?.toString() ?? "0") ?? 0) < 50).length;

      return {"total": total, "healthy": healthy, "alerts": alerts};
    } catch (e) {
      print("[Firebase ERROR] getStats: $e");
      return {"total": 0, "healthy": 0, "alerts": 0};
    }
  }
}