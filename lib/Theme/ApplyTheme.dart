import 'package:flutter/material.dart';
import 'ThemeNotifier.dart';
import 'Themes.dart';

class ApplyTheme extends StatelessWidget {
  final Widget child;

  const ApplyTheme({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: currentMode,
          home: child,
        );
      },
    );
  }
}
