import 'package:flutter/material.dart';
import '../../Theme/Themes.dart';

Future<void> showSubmitConfirmDialog(
  BuildContext context, {
  required VoidCallback onConfirm,
  String title = 'Confirm Submission',
  String message = 'Are you sure you want to submit this puzzle?',
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final app = Theme.of(context).extension<AppColors>()!;

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: app.panelBg,
        title: Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          message,
          style: textTheme.bodyMedium?.copyWith(
            color: app.hint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: app.primaryColor,
              foregroundColor: colorScheme.onPrimary,
            ),
            onPressed: () {
              Navigator.of(context).pop(); // close dialog first
              onConfirm(); // then run custom action
            },
            child: Text(
              'Submit',
              style: textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}
