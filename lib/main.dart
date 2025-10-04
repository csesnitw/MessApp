import 'package:flutter/material.dart';
import 'package:mess_management_app/Pages/admin_login_page.dart';
import 'package:mess_management_app/Pages/admin_page.dart';
import 'package:mess_management_app/Pages/digital_mess_card.dart';
import 'package:mess_management_app/Pages/student_home_page.dart';
import 'package:mess_management_app/Pages/student_login_page.dart';
import 'package:mess_management_app/Pages/student_photo_upload_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'pages/role_selection_page.dart';
import 'providers/dinner_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove("role");
  //final savedRole = prefs.getString("role");
  runApp(MyApp(initialRole: null));
}

class MyApp extends StatelessWidget {
  final String? initialRole;
  const MyApp({super.key, this.initialRole});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DinnerProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mess Management App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: initialRole == null
            ? const RoleSelectionPage()
            : StudentHomePage(),
      ),
    );
  }
}
