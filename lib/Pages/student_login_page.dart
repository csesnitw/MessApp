import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mess_management_app/Pages/student_home_page.dart';
import 'package:mess_management_app/Pages/student_photo_upload_page.dart';
import 'package:mess_management_app/services/student_auth_service.dart';

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});

  @override
  State<StudentLoginPage> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Sign in with Google
      final googleUser = await _authService.signInWithGoogle();

      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Step 2: Get authentication tokens
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      debugPrint('=== Google Sign-In Successful ===');
      debugPrint('User Email: ${googleUser.email}');
      debugPrint('User Name: ${googleUser.displayName}');

      // Step 3: Sign in to Firebase
      final userCredential = await _authService.signInWithCredential(
        accessToken,
        idToken,
      );
      final user = userCredential.user;

      if (user != null) {
        debugPrint('=== Firebase Sign-In Successful ===');
        debugPrint('Firebase UID: ${user.uid}');

        // Step 4: Save credentials
        await _authService.saveUserCredentials(user.email ?? '', idToken ?? '');

        // Step 5: Verify with backend
        final result = await _authService.verifyUserWithBackend(idToken, user);

        if (mounted) {
          if (result['success']) {
            final student = result['data']['student'];
            final hasPhoto = student['hasUploadedPhoto'] != null &&
                student['hasUploadedPhoto'];

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => hasPhoto
                    ? const StudentHomePage()
                    : const StudentUploadPhotoPage(),
              ),
            );
          } else {
            final message = result['data']['message'] ?? 'Login failed';
            _showError(message);
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      if (mounted) {
        _showErrorDialog('Authentication failed: ${e.message}');
      }
    } catch (error) {
      debugPrint("Sign-in failed: $error");
      if (mounted) {
        _showErrorDialog('Sign-in failed: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Login"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.school,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              const Text(
                'Student Portal',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in with your Google account',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => _handleGoogleSignIn(context),
                  icon: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.login),
                  label: Text(
                    _isLoading ? "Signing in..." : "Login with Google",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}