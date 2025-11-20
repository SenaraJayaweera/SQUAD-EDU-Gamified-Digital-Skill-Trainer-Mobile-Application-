import 'package:flutter/material.dart';
import '../../Theme/Themes.dart';
import '../../widgets/BackButtonWidget.dart';

import 'MatchingPuzzles/MatchingPuzzlePage.dart';
import 'SequencePuzzles/SequencePuzzlePage.dart';
import 'PuzzleData.dart';

class PuzzleCreationPage extends StatefulWidget {
  const PuzzleCreationPage({super.key});

  @override
  State<PuzzleCreationPage> createState() => _PuzzleCreationPageState();
}

class _PuzzleCreationPageState extends State<PuzzleCreationPage> {
  String? _selectedPuzzleType;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _nameError = false;
  bool _descError = false;

  final List<Map<String, dynamic>> _puzzleOptions = [
    {
      'type': 'Matching Puzzle',
      'subtitle': 'Connect related items together',
      'icon': Icons.link,
      'key': 'matching',
    },
    {
      'type': 'Sequence Puzzle',
      'subtitle': 'Order items in correct sequence',
      'icon': Icons.list_alt,
      'key': 'sequence',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final moduleId = args['moduleId'];
    final moduleTitle = args['moduleTitle'];

    // If moduleId is null or empty, show an error and prevent page content
    if (moduleId == null ||
        moduleId.toString().isEmpty ||
        moduleId == 'Unknown') {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Module ID is missing.\nCannot create a puzzle.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.white, // Button background color
                  //foregroundColor: Colors.black, // Text color
                  elevation: 0, // Remove shadow (optional)
                  side: const BorderSide(
                    color: Color(0xFF3E4653), // Border color
                    width: 1, // Border width
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Initialize central data object
    final MatchingPuzzleData puzzleData = MatchingPuzzleData(
      moduleId: moduleId,
      moduleTitle: moduleTitle,
    );

    final SequencePuzzleData S_PuzzleData = SequencePuzzleData(
      moduleId: moduleId,
      moduleTitle: moduleTitle,
    );

    Color _alpha(Color c, double a) => c.withValues(alpha: a);

    return Scaffold(
      backgroundColor: app.headerBg,
      body: SafeArea(
        child: Column(
          children: [
            // === Header ===
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: SizedBox(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: CircleBackButton(),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.extension_rounded,
                          color: app.headerFg,
                          size: 72,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Create Puzzle',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: app.headerFg,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // === Rounded panel ===
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: app.panelBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Puzzle Name', labelColor: app.label),
                      _PillTextField(
                        controller: _nameController,
                        hint: 'Enter puzzle name',
                        icon: Icons.text_fields_rounded,
                        borderColor: _nameError ? Colors.red : app.border,
                        hintColor: app.hint,
                        fillColor: app.panelBg,
                      ),
                      const SizedBox(height: 28),
                      _Label('Puzzle Description', labelColor: app.label),
                      _PillTextField(
                        controller: _descController,
                        hint: 'Enter description...',
                        icon: Icons.description_outlined,
                        borderColor: _descError ? Colors.red : app.border,
                        hintColor: app.hint,
                        fillColor: app.panelBg,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 28),
                      _Label('Select Puzzle Type', labelColor: app.label),
                      const SizedBox(height: 16),
                      ..._puzzleOptions.map((option) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPuzzleButton(
                            title: option['type'],
                            subtitle: option['subtitle'],
                            icon: option['icon'],
                            keyString: option['key'],
                            appColors: app,
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _nameError = _nameController.text.isEmpty;
                              _descError = _descController.text.isEmpty;
                            });

                            if (_nameError || _descError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _nameError && _descError
                                        ? 'Please fill in both fields'
                                        : _nameError
                                        ? 'Please enter a puzzle name'
                                        : 'Please enter a description',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            if (_selectedPuzzleType == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select a puzzle type first',
                                  ),
                                ),
                              );
                              return;
                            }

                            //Update central puzzleData
                            puzzleData.updateName(_nameController.text);
                            puzzleData.updateDescription(_descController.text);
                            puzzleData.updatePuzzleType(_selectedPuzzleType!);

                            S_PuzzleData.updateName(_nameController.text);
                            S_PuzzleData.updateDescription(
                              _descController.text,
                            );
                            S_PuzzleData.updatePuzzleType(_selectedPuzzleType!);

                            // Navigate to the target page
                            Widget targetPage;
                            switch (_selectedPuzzleType) {
                              case 'matching':
                                targetPage = MatchingPuzzlePage(
                                  puzzleData: puzzleData,
                                );
                                break;
                              case 'sequence':
                                targetPage = SequencePuzzlePage(
                                  puzzleData: S_PuzzleData,
                                );
                                break;

                              default:
                                return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => targetPage),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedPuzzleType == null
                                ? _alpha(app.ctaBlue, 0.45)
                                : app.ctaBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Text('Next'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzleButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required String keyString,
    required AppColors appColors,
  }) {
    final bool isSelected = _selectedPuzzleType == keyString;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _selectedPuzzleType = keyString),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? appColors.primaryColor.withOpacity(0.1)
              : appColors.panelBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? appColors.primaryColor : appColors.border,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? appColors.primaryColor.withOpacity(0.2)
                    : appColors.cardIconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? appColors.primaryColor : appColors.cardIcon,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? appColors.primaryColor
                          : appColors.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: appColors.hint),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: appColors.primaryColor),
          ],
        ),
      ),
    );
  }
}

// ===== Helper Widgets =====

class _Label extends StatelessWidget {
  final String text;
  final Color labelColor;
  const _Label(this.text, {required this.labelColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        color: labelColor,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _PillTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color borderColor;
  final Color hintColor;
  final Color fillColor;
  final int maxLines;

  const _PillTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.borderColor,
    required this.hintColor,
    required this.fillColor,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: maxLines == 1 ? 54 : null,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: borderColor, width: 1.6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        crossAxisAlignment: maxLines == 1
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).iconTheme.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: hintColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
