import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String _getBackendUrl(String endpoint) {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5002$endpoint';
    } else if (Platform.isIOS) {
      return 'http://localhost:5002$endpoint';
    } else {
      return 'http://localhost:5002$endpoint';
    }
  }

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    await _googleSignIn.signOut();
    return await _googleSignIn.signIn();
  }

  Future<UserCredential> signInWithCredential(String? accessToken, String? idToken) async {
    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<Map<String, dynamic>> verifyUserWithBackend(String? token, User user) async {
    if (token == null) {
      throw Exception('Token is null');
    }

    final backendUrl = _getBackendUrl('/api/student/login');

    final response = await http.post(
      Uri.parse(backendUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName,
        'role': 'student',
        'photoUrl': user.photoURL,
        'tokenId': token,
      }),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Connection timeout - Make sure your backend is running');
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Save user info to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (data['user_id'] != null) {
        await prefs.setString('backend_user_id', data['user_id']);
      }

      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': data,
      };
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'statusCode': response.statusCode,
        'data': data,
      };
    }
  }

  Future<void> saveUserCredentials(String email, String idToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_email", email);
    await prefs.setString("google_id_token", idToken);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await TokenManager.clearAllTokens();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}

class TokenManager {
  static Future<String?> getFirebaseToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebase_token');
  }

  static Future<String?> getGoogleAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('google_access_token');
  }

  static Future<String?> getGoogleIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('google_id_token');
  }

  static Future<Map<String, String?>> getAllTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'firebase_token': prefs.getString('firebase_token'),
      'google_access_token': prefs.getString('google_access_token'),
      'google_id_token': prefs.getString('google_id_token'),
      'user_id': prefs.getString('user_id'),
      'user_email': prefs.getString('user_email'),
    };
  }

  static Future<void> clearAllTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('firebase_token');
    await prefs.remove('google_access_token');
    await prefs.remove('google_id_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('backend_user_id');
  }
}