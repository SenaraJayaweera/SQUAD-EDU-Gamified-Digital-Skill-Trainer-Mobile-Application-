import 'package:flutter/material.dart';




// -----------------------------------------------------------------------------
// APP COLORS
// -----------------------------------------------------------------------------
class AppColors extends ThemeExtension<AppColors> {
  final Color moduleIconBgColor;
  final Color moduleIconColor;

  const AppColors({
    required this.moduleIconBgColor,
    required this.moduleIconColor,
  });

  static AppColors fallback() => const AppColors(
    moduleIconBgColor: Color(0xFFE0E0E0),
    moduleIconColor: Colors.black54,
  );

  @override
  AppColors copyWith({Color? moduleIconBgColor, Color? moduleIconColor}) =>
      AppColors(
        moduleIconBgColor: moduleIconBgColor ?? this.moduleIconBgColor,
        moduleIconColor: moduleIconColor ?? this.moduleIconColor,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      moduleIconBgColor: Color.lerp(
        moduleIconBgColor,
        other.moduleIconBgColor,
        t,
      )!,
      moduleIconColor: Color.lerp(moduleIconColor, other.moduleIconColor, t)!,
    );
  }
}