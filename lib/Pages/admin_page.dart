import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mess_management_app/services/admin_service.dart';
import 'role_selection_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final AdminService _adminService = AdminService();
  int _currentIndex = 0;

  // Separate files for students and weekly menu
  File? _studentFile;
  File? _menuFile;

  // For menu editing
  final Map<String, TextEditingController> _controllers = {
    "Breakfast": TextEditingController(),
    "Lunch": TextEditingController(),
    "Dinner": TextEditingController(),
  };

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // ---- FILE PICKERS ----
  Future<void> _pickStudentFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      //allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _studentFile = File(result.files.single.path!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Student file selected: ${_studentFile!.path.split('/').last}")),
      );
    }
  }

  Future<void> _pickMenuFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      //allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _menuFile = File(result.files.single.path!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Menu file selected: ${_menuFile!.path.split('/').last}")),
      );
    }
  }

  // ---- API CALLS ----
  Future<void> _uploadStudents() async {
    if (_studentFile == null) return;
    final success = await _adminService.uploadStudents(_studentFile!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Students uploaded successfully" : "Upload failed")),
    );
  }

  Future<void> _resetStudents() async {
    final success = await _adminService.resetStudents();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "All students cleared" : "Failed to reset")),
    );
  }

  Future<void> _uploadMenu() async {
    if (_menuFile == null) return;
    final success = await _adminService.uploadMenu(_menuFile!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Menu uploaded successfully" : "Menu upload failed")),
    );
  }

  Future<void> _updateDayMenu(String day) async {
    final success = await _adminService.updateDayMenu(
      day,
      _controllers["Breakfast"]!.text.split(","),
      _controllers["Lunch"]!.text.split(","),
      _controllers["Dinner"]!.text.split(","),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Menu for $day updated" : "Update failed")),
    );
  }

  Future<void> _issueToken() async {
    final success = await _adminService.issueToken();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Special token issued" : "Failed to issue token")),
    );
  }

  Future<void> _logout() async {
    await _adminService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      // ---- Menu Editing Page ----
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Edit Mess Menu", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._controllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: entry.key,
                  border: const OutlineInputBorder(),
                  hintText: "Enter items separated by comma",
                ),
              ),
            );
          }),
          ElevatedButton(
            onPressed: () {
              final now = DateTime.now();
              final currentDay = [
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday",
                "Saturday",
                "Sunday"
              ][now.weekday - 1];
              _updateDayMenu(currentDay);
            },
            child: const Text("Save Today's Menu"),
          ),
          const Divider(),
          ElevatedButton.icon(
            onPressed: _pickMenuFile,
            icon: const Icon(Icons.upload_file),
            label: const Text("Select Menu CSV File"),
          ),
          if (_menuFile != null)
            Text("Selected: ${_menuFile!.path.split('/').last}"),
          ElevatedButton(
            onPressed: _uploadMenu,
            child: const Text("Upload Weekly Menu (CSV)"),
          ),
        ],
      ),

      // ---- Special Token Page ----
      Center(
        child: ElevatedButton(
          onPressed: _issueToken,
          child: const Text("Issue Special Dinner Token"),
        ),
      ),

      // ---- Manage Students Page ----
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: _pickStudentFile,
            icon: const Icon(Icons.upload_file),
            label: const Text("Select Student CSV File"),
          ),
          if (_studentFile != null)
            Text("Selected: ${_studentFile!.path.split('/').last}"),
          ElevatedButton(
            onPressed: _uploadStudents,
            child: const Text("Upload Students"),
          ),
          const Divider(),
          ElevatedButton(
            onPressed: _resetStudents,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reset Students"),
          ),
        ],
      ),

      // ---- Settings Page ----
      Center(
        child: ElevatedButton(
          onPressed: _logout,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Logout"),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Menu"),
          BottomNavigationBarItem(icon: Icon(Icons.token), label: "Token"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Students"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
