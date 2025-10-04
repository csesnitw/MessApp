import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  static const String baseUrl = "http://10.0.2.2:5002/api/admin"; // Android Emulator
  // If you're running on a real device, replace 10.0.2.2 with your PC IP.

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("atoken");
  }

  // ============ UPLOAD STUDENTS CSV ============
  Future<bool> uploadStudents(File file) async {
    final token = await _getToken();
    if (token == null) return false;

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/upload-csv"),
    );

    request.headers["Authorization"] = "Bearer $token";
    request.files.add(await http.MultipartFile.fromPath("file", file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      print(body['message']); // "CSV uploaded successfully"
      return true;
    } else {
      print("Error: ${response.statusCode} -> ${response.body}");
      return false;
    }
  }


  // ============ RESET STUDENTS ============
  Future<bool> resetStudents() async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse("$baseUrl/students/clear"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 200;
  }

  // ============ UPLOAD WEEK MENU ============
  Future<bool> uploadMenu(File file) async {
    final token = await _getToken();
    if (token == null) return false;
    print(token);
    var request = http.MultipartRequest(
      "PUT",
      Uri.parse("$baseUrl/menu/upload-week-csv"),
    );
    request.headers["Authorization"] = "Bearer $token";
    request.files.add(await http.MultipartFile.fromPath("file", file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      print(body['message']); // "CSV uploaded successfully"
      return true;
    } else {
      print("Error: ${response.statusCode} -> ${response.body}");
      return false;
    }
  }

  // ============ UPDATE SINGLE DAY MENU ============
  Future<bool> updateDayMenu(String day, List<String> breakfast, List<String> lunch, List<String> dinner) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse("$baseUrl/menu/update/$day"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "breakfast": breakfast,
        "lunch": lunch,
        "dinner": dinner,
      }),
    );
    final body = jsonDecode(response.body);
    print(body['error']);
    print(body['message']);
    print(response.statusCode);
    return response.statusCode == 200;
  }

  // ============ ISSUE SPECIAL TOKEN ============
  Future<bool> issueToken() async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse("$baseUrl/special-dinner/redeem"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 200;
  }

  // ============ LOGOUT ============
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("messName");
    await prefs.remove("role");
  }
}
