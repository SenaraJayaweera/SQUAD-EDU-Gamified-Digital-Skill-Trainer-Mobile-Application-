import 'package:flutter/material.dart';
import 'package:frontend/Theme/Themes.dart';

import 'Login/LoginPage.dart';

import 'Navigation/StudentNavigation.dart';
import 'Navigation/TeacherNavigation.dart';
import '../Registration/SignUp.dart';

import 'Theme/ThemeNotifier.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async {
  //firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'SQUAD Login',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => Login(),
            '/StudentHomePage': (context) => StudentNavigationBar(),
            '/TeacherHomePage': (context) => TeacherNavigationBar(),
            '/SignUpPage': (context) => SignUpPage(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
