import 'package:flutter/material.dart';
import 'ThemeNotifier.dart';
import '../widgets/BackButtonWidget.dart';

enum ThemeOption { light, dark }

class ThemeSelection extends StatefulWidget {
  const ThemeSelection({super.key});

  @override
  State<ThemeSelection> createState() => _ThemeSelectionState();
}

class _ThemeSelectionState extends State<ThemeSelection> {
  // Initialize the state based on the current theme value.
  ThemeOption _selectedOption = themeNotifier.value == ThemeMode.light
      ? ThemeOption.light
      : ThemeOption.dark;

  @override
  Widget build(BuildContext context) {
    final headerColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: SizedBox(
              height: 108,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: CircleBackButton(),
                  ),
                  _HeaderIconAndTitle(
                    title: 'Select Theme',
                    titleColor: headerColor,
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            title: const Text(
              'Light Mode',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Default app theme'),
            leading: Radio<ThemeOption>(
              value: ThemeOption.light,
              groupValue: _selectedOption,
              onChanged: (ThemeOption? value) {
                if (value != null) {
                  setState(() => _selectedOption = value);
                  themeNotifier.value = ThemeMode.light;
                }
              },
            ),
            trailing: const Icon(Icons.wb_sunny_outlined),
          ),
          ListTile(
            title: const Text(
              'Dark Mode',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Optimized for low light'),
            leading: Radio<ThemeOption>(
              value: ThemeOption.dark,
              groupValue: _selectedOption,
              onChanged: (ThemeOption? value) {
                if (value != null) {
                  setState(() => _selectedOption = value);
                  themeNotifier.value = ThemeMode.dark;
                }
              },
            ),
            trailing: const Icon(Icons.nightlight_round),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class _HeaderIconAndTitle extends StatelessWidget {
  final String title;
  final Color? titleColor;

  const _HeaderIconAndTitle({required this.title, this.titleColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
