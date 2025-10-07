import 'package:flutter/material.dart';
import '../services/dinner_service.dart';

class DinnerProvider extends ChangeNotifier {
  final DinnerService _dinnerService = DinnerService();

  // --- Student details & token ---
  String name = "";
  String email = "";
  String photoUrl = "";
  bool hasUploadedPhoto = false;
  bool token = false;
  String mess = "";
  String rollNo = "";

  // Fetch student details from backend
  Future<void> fetchStudentDetails() async {
    final data = await _dinnerService.fetchStudentDetails();

    name = data["name"] ?? "";
    email = data["email"] ?? "";
    photoUrl = data["photoUrl"] ?? "";
    hasUploadedPhoto = data["hasUploadedPhoto"] ?? false;
    mess = data["mess"] ?? "";
    rollNo = data["rollNo"] ?? "";
    token = (data["specialToken"]["active"] == true &&
        data["specialToken"]["redeemed"] == false);


    notifyListeners();
  }

  // Redeem dinner token via backend
  Future<void> redeemDinner() async {
    final success = await _dinnerService.syncTokenToBackend(true);
    if (success) {
      print("changed");
      token = false;
      notifyListeners();
    }
  }

  // Reset dinner token via backend
  Future<void> resetDinner() async {
    final success = await _dinnerService.syncTokenToBackend(false);
    if (success) {
      print("changed");
      token = true;
      notifyListeners();
    }
  }
}
