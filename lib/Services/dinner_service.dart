import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DinnerService {
  // Get backend URL based on platform
  String _getBackendUrl(String endpoint) {
    String host;
    if (Platform.isAndroid) {
      host = 'http://10.0.2.2:5002';
    } else {
      host = 'http://localhost:5002';
    }

    if (endpoint.isEmpty || !endpoint.startsWith('/')) {
      throw Exception("Invalid endpoint: $endpoint");
    }

    return '$host$endpoint';
  }

  // Fetch student details from backend
  Future<Map<String, dynamic>> fetchStudentDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenId = prefs.getString("google_id_token");

    if (tokenId == null || tokenId.isEmpty) {
      throw Exception("No tokenId found in SharedPreferences");
    }

    final backendUrl = _getBackendUrl('/api/student/details');
    debugPrint("Fetching student details from: $backendUrl");

    final response = await http.get(
      Uri.parse(backendUrl),
      headers: {"Authorization": "Bearer $tokenId"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)["student"];
      return data;
    } else {
      throw Exception("Failed to fetch student details: ${response.body}");
    }
  }

  // Sync token state to backend (redeem or reset)
  Future<bool> syncTokenToBackend(bool redeem) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString("user_email");
    final tokenId = prefs.getString("google_id_token");

    if (savedEmail == null || savedEmail.isEmpty) {
      debugPrint("No email saved in SharedPreferences, skipping sync.");
      return false;
    }
    if (tokenId == null || tokenId.isEmpty) {
      debugPrint("No tokenId saved in SharedPreferences, skipping sync.");
      return false;
    }

    final backendUrl = _getBackendUrl('/api/student/sync-token');
    debugPrint("Syncing token to backend: $backendUrl");

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $tokenId"
        },
        body: jsonEncode({
          "email": savedEmail,
          "redeemedToken": redeem,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Token synced successfully.");
        return true;
      } else {
        debugPrint("Failed to sync token: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error syncing token: $e");
      return false;
    }
  }
}
