import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  String _getBackendUrl(String endpoint) {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5002$endpoint';
    } else if (Platform.isIOS) {
      return 'http://localhost:5002$endpoint';
    } else {
      return 'http://localhost:5002$endpoint';
    }
  }
  Future<bool> login(String username, String password) async {
    String baseUrl = _getBackendUrl("/api/admin/login");
    final url = Uri.parse(baseUrl);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("atoken", data["token"]);
      await prefs.setString("role", data["role"]);
      await prefs.setString("messName", data["messName"]);

      return true;
    } else {
      final body = jsonDecode(response.body);
      print(body['error']);
      return false;
    }
  }
}
