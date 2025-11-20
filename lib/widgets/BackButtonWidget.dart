import 'package:flutter/material.dart';

class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // Arrow color
    final iconColor = brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    // Circle background
    final bgColor = brightness == Brightness.dark
        ? const Color(0x22FFFFFF)
        : Colors.white;

    // Border color
    final borderColor = brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    // Ripple color
    final rippleColor = brightness == Brightness.dark
        ? Colors.white
        : Colors.black26;

    return Material(
      color: Colors.transparent, // Material itself is transparent
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: rippleColor,
        highlightColor: rippleColor.withOpacity(0.2),
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
