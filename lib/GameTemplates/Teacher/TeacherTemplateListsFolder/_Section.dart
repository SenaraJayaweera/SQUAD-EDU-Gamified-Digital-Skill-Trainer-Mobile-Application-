import 'package:flutter/material.dart';

class SectionWidget  extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onCreateNew;
  final Widget child;

  const SectionWidget ({
    required this.title,
    required this.icon,
    required this.onCreateNew,
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
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onCreateNew,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'Create new',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationThickness: 2,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: onBg,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}
