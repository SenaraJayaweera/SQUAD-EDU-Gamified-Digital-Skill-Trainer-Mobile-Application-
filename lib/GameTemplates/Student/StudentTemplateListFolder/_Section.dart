import 'package:flutter/material.dart';

class SectionWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const SectionWidget({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: onBg,
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 28, color: onBg),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}
