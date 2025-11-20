import 'package:flutter/material.dart';

/// Semantic color pack used across the app (works with both themes).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  // Header (dark) area
  final Color headerBg;
  final Color headerFg; // main header text/icons (white on dark)
  final Color headerFgMuted; // softer header text (80% white)

  // Surfaces / text
  final Color panelBg; // white (light) / dark card (dark)
  final Color label; // section labels on white panel
  final Color hint; // input hint
  final Color iconMuted; // subtle icons inside fields
  final Color border; // default pill border

  // States / accents
  final Color error;
  final Color success;
  final Color ctaBlue; // confirm button blue
  final Color saveGreen; // name page save button
  final Color counterGrey; // character counter

  // Modules / FAB
  final Color primaryColor; // Primary module color
  final Color secondaryColor; // Secondary module color
  final Color iconBgColor; // Background behind icons in module cards
  final Color borderColor; // Border for module cards
  final Color fabColor; // FloatingActionButton background

  final Color cardIconBg; // background for icon in cards
  final Color cardIcon; // icon color
  final Color cardButton; // button color inside cards

  // NEW: Module card & stats colors
  final Color moduleIconColor; // module card icon color
  final Color moduleIconBgColor; // module card icon background
  final Color moduleStatColor; // module stat icon + text

  // NEW: neutrals used on the Teacher Templates screen
  final Color chipBg;          // pill background behind "Duration / Questions"
  final Color chipFg;          // pill text
  final Color actionBubbleBg;  // light circle behind delete/edit icons

  // Story View Page specific colors
  final Color storyCardBg; // Background for story title card
  final Color storyContentBg; // Background for content blocks (paragraph)
  final Color storyContentText; // Text color for content
  final Color storyErrorBg; // Error state background
  final Color storyErrorIcon; // Error icon color
  final Color storyErrorText; // Error text color
  final Color storyDeleteBg; // Delete button background
  final Color storyDeleteIcon; // Delete icon color
  final Color storyShadow; // Shadow color for cards
  final Color storyOverlay; // Video overlay color

  // Form + buttons
final Color borderStrong;     // darker field border on white cards
final Color ctaBlueBorder;    // outline for primary CTA buttons

// Quiz preview states
final Color correctFill;      // background for the correct option chip
final Color correctBorder;    // border for the correct option chip

// Tag chips (per your UI)
final Color tagDiffBg;  final Color tagDiffFg;
final Color tagPointsBg;final Color tagPointsFg;
final Color tagHintsBg; final Color tagHintsFg;
final Color tagTimerBg; final Color tagTimerFg;
final Color tagLivesBg; final Color tagLivesFg;
final Color tagQsBg;    final Color tagQsFg;

//
final Color tagPurpleBg; final Color tagPurpleFg; // “Quiz Title”, “Rules”
final Color tagRedBg;    final Color tagRedFg;    // “Attempts”


  const AppColors({
    // header
    required this.headerBg,
    required this.headerFg,
    required this.headerFgMuted,
    // surfaces / text
    required this.panelBg,
    required this.label,
    required this.hint,
    required this.iconMuted,
    required this.border,
    // states / accents
    required this.error,
    required this.success,
    required this.ctaBlue,
    required this.saveGreen,
    required this.counterGrey,
    // modules / FAB
    required this.primaryColor,
    required this.secondaryColor,
    required this.iconBgColor,
    required this.borderColor,
    required this.fabColor,
    required this.cardIconBg,
    required this.cardIcon,
    required this.cardButton,
    required this.moduleIconColor,
    required this.moduleIconBgColor,
    required this.moduleStatColor,
    // new templatecards
    required this.chipBg,
    required this.chipFg,
    required this.actionBubbleBg,
    // story view
    required this.storyCardBg,
    required this.storyContentBg,
    required this.storyContentText,
    required this.storyErrorBg,
    required this.storyErrorIcon,
    required this.storyErrorText,
    required this.storyDeleteBg,
    required this.storyDeleteIcon,
    required this.storyShadow,
    required this.storyOverlay,
    //quiz colors
    required this.borderStrong,
    required this.ctaBlueBorder,
    required this.correctFill,
    required this.correctBorder,
    required this.tagDiffBg,  required this.tagDiffFg,
    required this.tagPointsBg,required this.tagPointsFg,
    required this.tagHintsBg, required this.tagHintsFg,
    required this.tagTimerBg, required this.tagTimerFg,
    required this.tagLivesBg, required this.tagLivesFg,
    required this.tagQsBg,    required this.tagQsFg,
    required this.tagPurpleBg, required this.tagPurpleFg,
    required this.tagRedBg,    required this.tagRedFg,
  });

  // Light design tokens
  static const light = AppColors(
    headerBg: Color(0xFF111315),
    headerFg: Colors.white,
    headerFgMuted: Color(0xCCFFFFFF), // 80% white
    panelBg: Colors.white,
    label: Color(0xFF3A3F47),
    hint: Color(0xFF97A1B0),
    iconMuted: Color(0xFF9DA6B4),
    border: Color(0xFFD7DEE7),
    error: Color(0xFFE53935),
    success: Color(0xFF54B225),
    ctaBlue: Color(0xFF51B9FF),
    saveGreen: Color(0xFF52B433),
    counterGrey: Color(0xFF8B93A3),
    primaryColor: Color(0xFF4CAF50),
    secondaryColor: Color(0xFFFF9800),
    iconBgColor: Color(0xFFE0E0E0),
    borderColor: Color(0xFFBDBDBD),
    fabColor: Color(0xFF2196F3),
    cardIconBg: Color(0xFFEDE7F6),
    cardIcon: Color(0xFF673AB7),
    cardButton: Color(0xFF512DA8),
    moduleIconColor: Color(0xFF2196F3),      // blue
    moduleIconBgColor: Color(0xFFBBDEFB),    // light blue
    moduleStatColor: Color(0xFF616161),      // grey[700]
    chipBg: Color(0xFFE7E8EB),
    chipFg: Colors.black87,
    actionBubbleBg: Color(0xFFEDEFF2),
    storyCardBg: Colors.white,
    storyContentBg: Colors.white,
    storyContentText: Color(0xFF2D3748),
    storyErrorBg: Color(0xFFFFEBEE), // light red
    storyErrorIcon: Colors.red,
    storyErrorText: Color(0xFF757575), // grey[600]
    storyDeleteBg: Color(0xFFFFEBEE), // light red
    storyDeleteIcon: Colors.red,
    storyShadow: Colors.black,
    storyOverlay: Colors.black,
    borderStrong: Color(0xFF2F3A46),
    ctaBlueBorder: Color(0xFF318FD1),
    correctFill: Color(0xFFC8F89A),
    correctBorder: Color(0xFF9DD86B),
    tagDiffBg: Color(0xFFFFECB3),
    tagPointsBg: Color(0xFFC8FAD9),
    tagHintsBg: Color(0xFFFFE0B2),
    tagTimerBg: Color(0xFFCCE5FF),
    tagLivesBg: Color(0xFFFFD6D6),
    tagQsBg: Color(0xFFE6E6E6),
    tagDiffFg: Color(0xFF6A4D00),
    tagPointsFg: Color(0xFF064D2E),
    tagHintsFg: Color(0xFF5D3B00),
    tagTimerFg: Color(0xFF0D3B66),
    tagLivesFg: Color(0xFF7A1F1F),
    tagQsFg: Color(0xFF333333),
    tagPurpleBg: Color(0xFFE7D6FF),
    tagPurpleFg: Color(0xFF7A48D9),
    tagRedBg: Color(0xFFFBD2D6),
    tagRedFg: Color(0xFFCC3C49),

  );

  // Dark design tokens
  static const dark = AppColors(
    headerBg: Color(0xFF111315),
    headerFg: Colors.white,
    headerFgMuted: Color(0xCCFFFFFF),
    panelBg: Color(0xFF1C1F22),
    label: Color(0xFFE7E9ED),
    hint: Color(0xFF9AA4B2),
    iconMuted: Color(0xFFB7C0CE),
    border: Color(0xFF3E4653),
    error: Color(0xFFFF6B6B),
    success: Color(0xFF6AD15B),
    ctaBlue: Color(0xFF51B9FF),
    saveGreen: Color(0xFF52B433),
    counterGrey: Color(0xFFA8B0BF),
    primaryColor: Color(0xFF66BB6A),
    secondaryColor: Color(0xFFFFB74D),
    iconBgColor: Color(0xFF2C2F33),
    borderColor: Color(0xFF555555),
    fabColor: Color(0xFF2196F3),
    cardIconBg: Color(0xFF3A3F47),
    cardIcon: Color(0xFFBB86FC),
    cardButton: Color(0xFF7C4DFF),
    moduleIconColor: Color(0xFF64B5F6),      // lighter blue
    moduleIconBgColor: Color(0xFF2C2F33),    // dark bg
    moduleStatColor: Color(0xFFB0BEC5),      // grey variant
    chipBg: Color(0xFF2A2F37),
    chipFg: Colors.white,
    actionBubbleBg: Color(0xFF2E343D),
    storyCardBg: Color(0xFF2C2F33),
    storyContentBg: Color(0xFF2C2F33),
    storyContentText: Color(0xFFE7E9ED),
    storyErrorBg: Color(0xFF3E2723), // dark red/brown
    storyErrorIcon: Color(0xFFFF6B6B),
    storyErrorText: Color(0xFFB0BEC5),
    storyDeleteBg: Color(0xFF3E2723), // dark red/brown
    storyDeleteIcon: Color(0xFFFF6B6B),
    storyShadow: Colors.black,
    storyOverlay: Colors.black,
    borderStrong: Color(0xFF3E4653),
    ctaBlueBorder: Color(0xFF2B6EA8),
    correctFill: Color(0xFF2F4F1E),
    correctBorder: Color(0xFF5EA33A),
    tagDiffBg: Color(0xFF3A3118),
    tagPointsBg: Color(0xFF193427),
    tagHintsBg: Color(0xFF3A2A12),
    tagTimerBg: Color(0xFF1C2C40),
    tagLivesBg: Color(0xFF3B1F1F),
    tagQsBg: Color(0xFF2A2F37),
    tagDiffFg: Color(0xFFF6D889),
    tagPointsFg: Color(0xFF9BE4C0),
    tagHintsFg: Color(0xFFF9C784),
    tagTimerFg: Color(0xFFAED2FF),
    tagLivesFg: Color(0xFFFFA3A3),
    tagQsFg: Color(0xFFE7E9ED),
    tagPurpleBg: Color(0xFF2E2547),
    tagPurpleFg: Color(0xFFC9A8FF),
    tagRedBg: Color(0xFF3F2226),
    tagRedFg: Color(0xFFF7A8B0),
  );

  @override
  AppColors copyWith({
    Color? headerBg,
    Color? headerFg,
    Color? headerFgMuted,
    Color? panelBg,
    Color? label,
    Color? hint,
    Color? iconMuted,
    Color? border,
    Color? error,
    Color? success,
    Color? ctaBlue,
    Color? saveGreen,
    Color? counterGrey,
    Color? primaryColor,
    Color? secondaryColor,
    Color? iconBgColor,
    Color? borderColor,
    Color? fabColor,
    Color? cardIconBg,
    Color? cardIcon,
    Color? cardButton,
    Color? moduleIconColor,
    Color? moduleIconBgColor,
    Color? moduleStatColor,
    Color? chipBg,
    Color? chipFg,
    Color? actionBubbleBg,
    Color? storyCardBg,
    Color? storyContentBg,
    Color? storyContentText,
    Color? storyErrorBg,
    Color? storyErrorIcon,
    Color? storyErrorText,
    Color? storyDeleteBg,
    Color? storyDeleteIcon,
    Color? storyShadow,
    Color? storyOverlay,
    Color? borderStrong, ctaBlueBorder, correctFill, correctBorder,
    Color? tagDiffBg, 
    Color? tagDiffFg,
    Color? tagPointsBg, 
    Color? tagPointsFg,
    Color? tagHintsBg, 
    Color? tagHintsFg,
    Color? tagTimerBg, 
    Color? tagTimerFg,
    Color? tagLivesBg, 
    Color? tagLivesFg,
    Color? tagQsBg, 
    Color? tagQsFg,
    Color? tagPurpleBg, Color? tagPurpleFg,
    Color? tagRedBg,    Color? tagRedFg,
  }) {
    return AppColors(
      headerBg: headerBg ?? this.headerBg,
      headerFg: headerFg ?? this.headerFg,
      headerFgMuted: headerFgMuted ?? this.headerFgMuted,
      panelBg: panelBg ?? this.panelBg,
      label: label ?? this.label,
      hint: hint ?? this.hint,
      iconMuted: iconMuted ?? this.iconMuted,
      border: border ?? this.border,
      error: error ?? this.error,
      success: success ?? this.success,
      ctaBlue: ctaBlue ?? this.ctaBlue,
      saveGreen: saveGreen ?? this.saveGreen,
      counterGrey: counterGrey ?? this.counterGrey,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      iconBgColor: iconBgColor ?? this.iconBgColor,
      borderColor: borderColor ?? this.borderColor,
      fabColor: fabColor ?? this.fabColor,
      cardIconBg: cardIconBg ?? this.cardIconBg,
      cardIcon: cardIcon ?? this.cardIcon,
      cardButton: cardButton ?? this.cardButton,
      moduleIconColor: moduleIconColor ?? this.moduleIconColor,
      moduleIconBgColor: moduleIconBgColor ?? this.moduleIconBgColor,
      moduleStatColor: moduleStatColor ?? this.moduleStatColor,
      chipBg: chipBg ?? this.chipBg,
      chipFg: chipFg ?? this.chipFg,
      actionBubbleBg: actionBubbleBg ?? this.actionBubbleBg,
      storyCardBg: storyCardBg ?? this.storyCardBg,
      storyContentBg: storyContentBg ?? this.storyContentBg,
      storyContentText: storyContentText ?? this.storyContentText,
      storyErrorBg: storyErrorBg ?? this.storyErrorBg,
      storyErrorIcon: storyErrorIcon ?? this.storyErrorIcon,
      storyErrorText: storyErrorText ?? this.storyErrorText,
      storyDeleteBg: storyDeleteBg ?? this.storyDeleteBg,
      storyDeleteIcon: storyDeleteIcon ?? this.storyDeleteIcon,
      storyShadow: storyShadow ?? this.storyShadow,
      storyOverlay: storyOverlay ?? this.storyOverlay,
      // quiz / tags (NEW)
      borderStrong:  borderStrong  ?? this.borderStrong,
      ctaBlueBorder: ctaBlueBorder ?? this.ctaBlueBorder,
      correctFill:   correctFill   ?? this.correctFill,
      correctBorder: correctBorder ?? this.correctBorder,
      tagDiffBg:   tagDiffBg   ?? this.tagDiffBg,
      tagDiffFg:   tagDiffFg   ?? this.tagDiffFg,
      tagPointsBg: tagPointsBg ?? this.tagPointsBg,
      tagPointsFg: tagPointsFg ?? this.tagPointsFg,
      tagHintsBg:  tagHintsBg  ?? this.tagHintsBg,
      tagHintsFg:  tagHintsFg  ?? this.tagHintsFg,
      tagTimerBg:  tagTimerBg  ?? this.tagTimerBg,
      tagTimerFg:  tagTimerFg  ?? this.tagTimerFg,
      tagLivesBg:  tagLivesBg  ?? this.tagLivesBg,
      tagLivesFg:  tagLivesFg  ?? this.tagLivesFg,
      tagQsBg:     tagQsBg     ?? this.tagQsBg,
      tagQsFg:     tagQsFg     ?? this.tagQsFg,
      tagPurpleBg: tagPurpleBg ?? this.tagPurpleBg,
      tagPurpleFg: tagPurpleFg ?? this.tagPurpleFg,
      tagRedBg: tagRedBg ?? this.tagRedBg,
      tagRedFg: tagRedFg ?? this.tagRedFg,

    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      headerBg: l(headerBg, other.headerBg),
      headerFg: l(headerFg, other.headerFg),
      headerFgMuted: l(headerFgMuted, other.headerFgMuted),
      panelBg: l(panelBg, other.panelBg),
      label: l(label, other.label),
      hint: l(hint, other.hint),
      iconMuted: l(iconMuted, other.iconMuted),
      border: l(border, other.border),
      error: l(error, other.error),
      success: l(success, other.success),
      ctaBlue: l(ctaBlue, other.ctaBlue),
      saveGreen: l(saveGreen, other.saveGreen),
      counterGrey: l(counterGrey, other.counterGrey),
      primaryColor: l(primaryColor, other.primaryColor),
      secondaryColor: l(secondaryColor, other.secondaryColor),
      iconBgColor: l(iconBgColor, other.iconBgColor),
      borderColor: l(borderColor, other.borderColor),
      fabColor: l(fabColor, other.fabColor),
      cardIconBg: l(cardIconBg, other.cardIconBg),
      cardIcon: l(cardIcon, other.cardIcon),
      cardButton: l(cardButton, other.cardButton),
      moduleIconColor: l(moduleIconColor, other.moduleIconColor),
      moduleIconBgColor: l(moduleIconBgColor, other.moduleIconBgColor),
      moduleStatColor: l(moduleStatColor, other.moduleStatColor),
      chipBg: l(chipBg, other.chipBg),
      chipFg: l(chipFg, other.chipFg),
      actionBubbleBg: l(actionBubbleBg, other.actionBubbleBg),
      storyCardBg: l(storyCardBg, other.storyCardBg),
      storyContentBg: l(storyContentBg, other.storyContentBg),
      storyContentText: l(storyContentText, other.storyContentText),
      storyErrorBg: l(storyErrorBg, other.storyErrorBg),
      storyErrorIcon: l(storyErrorIcon, other.storyErrorIcon),
      storyErrorText: l(storyErrorText, other.storyErrorText),
      storyDeleteBg: l(storyDeleteBg, other.storyDeleteBg),
      storyDeleteIcon: l(storyDeleteIcon, other.storyDeleteIcon),
      storyShadow: l(storyShadow, other.storyShadow),
      storyOverlay: l(storyOverlay, other.storyOverlay),
      // quiz / tags (NEW)
      borderStrong:  l(borderStrong,  other.borderStrong),
      ctaBlueBorder: l(ctaBlueBorder, other.ctaBlueBorder),
      correctFill:   l(correctFill,   other.correctFill),
      correctBorder: l(correctBorder, other.correctBorder),
      tagDiffBg:   l(tagDiffBg,   other.tagDiffBg),
      tagDiffFg:   l(tagDiffFg,   other.tagDiffFg),
      tagPointsBg: l(tagPointsBg, other.tagPointsBg),
      tagPointsFg: l(tagPointsFg, other.tagPointsFg),
      tagHintsBg:  l(tagHintsBg,  other.tagHintsBg),
      tagHintsFg:  l(tagHintsFg,  other.tagHintsFg),
      tagTimerBg:  l(tagTimerBg,  other.tagTimerBg),
      tagTimerFg:  l(tagTimerFg,  other.tagTimerFg),
      tagLivesBg:  l(tagLivesBg,  other.tagLivesBg),
      tagLivesFg:  l(tagLivesFg,  other.tagLivesFg),
      tagQsBg:     l(tagQsBg,     other.tagQsBg),
      tagQsFg:     l(tagQsFg,     other.tagQsFg),
      tagPurpleBg: l(tagPurpleBg, other.tagPurpleBg),
      tagPurpleFg: l(tagPurpleFg, other.tagPurpleFg),
      tagRedBg: l(tagRedBg, other.tagRedBg),
      tagRedFg: l(tagRedFg, other.tagRedFg),

    );
  }
}

// AppTheme
class AppTheme {
  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    iconTheme: const IconThemeData(color: Colors.black87),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Colors.blue,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.black),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(color: Colors.black87),
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: Colors.deepPurple,
      onPrimary: Colors.white,
      secondary: Colors.blueAccent,
      onSecondary: Colors.white,
      tertiary: Colors.amber,
      onTertiary: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black,
      error: Colors.red,
      onError: Colors.white,
    ),
    extensions: const [AppColors.light],
  );

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF111315),
    cardColor: const Color(0xFF1C1F22),
    iconTheme: const IconThemeData(color: Colors.white70),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.grey),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111315),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF111315),
      indicatorColor: Colors.blue,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.white70),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(color: Colors.white70),
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF9068B2),
      onPrimary: Colors.white,
      secondary: Colors.lightBlueAccent,
      onSecondary: Colors.black,
      tertiary: Colors.amber,
      onTertiary: Colors.black,
      surface: Color(0xFF1C1F22),
      onSurface: Colors.white,
      error: Colors.redAccent,
      onError: Colors.black,
      
    ),
    extensions: const [AppColors.dark],
  );
}
