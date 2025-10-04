import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MenuService {
  String _getBackendUrl(String endpoint) {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5002$endpoint';
    } else if (Platform.isIOS) {
      return 'http://localhost:5002$endpoint';
    } else {
      return 'http://localhost:5002$endpoint';
    }
  }

  Future<Map<String, dynamic>> fetchMenu() async {
    final backendUrl = _getBackendUrl('/api/student/menu');
    final prefs = await SharedPreferences.getInstance();
    final tokenId = prefs.getString("google_id_token");

    if (tokenId == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.get(
      Uri.parse(backendUrl),
      headers: {"Authorization": "Bearer $tokenId"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load menu: ${response.statusCode}");
    }
  }
}