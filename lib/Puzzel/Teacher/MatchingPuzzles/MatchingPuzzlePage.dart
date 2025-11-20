import 'package:flutter/material.dart';
import '../../../widgets/BackButtonWidget.dart';
import '../PuzzleData.dart';
import 'SummeryDetails.dart';
import '../../../Theme/Themes.dart';

class QuestionData {
  TextEditingController instructionsController;
  TextEditingController leftColumnTitleController;
  TextEditingController rightColumnTitleController;
  List<Map<String, String>> puzzlePairs;

  QuestionData({
    String instructions = '',
    String leftColumnTitle = '',
    String rightColumnTitle = '',
    List<Map<String, String>>? initialPairs,
  }) : instructionsController = TextEditingController(text: instructions),
       leftColumnTitleController = TextEditingController(text: leftColumnTitle),
       rightColumnTitleController = TextEditingController(
         text: rightColumnTitle,
       ),
       puzzlePairs =
           initialPairs ??
           [
             {'left': '', 'right': ''},
           ];
}

class MatchingPuzzlePage extends StatefulWidget {
  final MatchingPuzzleData puzzleData;
  const MatchingPuzzlePage({super.key, required this.puzzleData});

  @override
  State<MatchingPuzzlePage> createState() => _MatchingPuzzlePageState();
}

class _MatchingPuzzlePageState extends State<MatchingPuzzlePage> {
  late MatchingPuzzleData _puzzleData;
  List<QuestionData> _questions = [];

  @override
  void initState() {
    super.initState();
    _puzzleData = widget.puzzleData;

    if (_puzzleData.questions.isNotEmpty) {
      _questions = _puzzleData.questions.map((qModel) {
        return QuestionData(
          instructions: qModel.instructionsController.text,
          leftColumnTitle: qModel.leftColumnTitleController.text,
          rightColumnTitle: qModel.rightColumnTitleController.text,
          initialPairs: qModel.puzzlePairs
              .map((pair) => {'left': pair.left, 'right': pair.right})
              .toList(),
        );
      }).toList();
    } else {
      _questions = [QuestionData()];
    }
  }

  void _syncToCentral() {
    _puzzleData.questions = _questions
        .map((q) {
          final nonEmptyPairs = q.puzzlePairs
              .where(
                (p) =>
                    (p['left']?.trim().isNotEmpty ?? false) ||
                    (p['right']?.trim().isNotEmpty ?? false),
              )
              .toList();

          final hasContent =
              q.instructionsController.text.trim().isNotEmpty ||
              q.leftColumnTitleController.text.trim().isNotEmpty ||
              q.rightColumnTitleController.text.trim().isNotEmpty ||
              nonEmptyPairs.isNotEmpty;

          if (!hasContent) return null;

          return QuestionDataModel(
            instructions: q.instructionsController.text,
            leftColumnTitle: q.leftColumnTitleController.text,
            rightColumnTitle: q.rightColumnTitleController.text,
            initialPairs: nonEmptyPairs
                .map((p) => QuestionPair(left: p['left']!, right: p['right']!))
                .toList(),
          );
        })
        .whereType<QuestionDataModel>()
        .toList();
  }

  void _addPair(int questionIndex) {
    setState(() {
      _questions[questionIndex].puzzlePairs.add({'left': '', 'right': ''});
    });
    _syncToCentral();
  }

  void _removePair(int questionIndex, int pairIndex) {
    setState(() {
      _questions[questionIndex].puzzlePairs.removeAt(pairIndex);
    });
    _syncToCentral();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuestionData());
    });
    _syncToCentral();
  }

  void _removeQuestion(int index) {
    if (index == 0) return; // prevent deleting first question
    setState(() {
      _questions.removeAt(index);
    });
    _syncToCentral();
  }

  bool _validateInputs() {
    for (var q in _questions) {
      if (q.instructionsController.text.trim().isEmpty ||
          q.leftColumnTitleController.text.trim().isEmpty ||
          q.rightColumnTitleController.text.trim().isEmpty) {
        return false;
      }
      if (q.puzzlePairs.isEmpty) return false;
      for (var pair in q.puzzlePairs) {
        if ((pair['left']?.trim().isEmpty ?? true) ||
            (pair['right']?.trim().isEmpty ?? true)) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: app.headerBg,
      body: SafeArea(
        child: Column(
          children: [
            // ===== MODERN HEADER =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: app.headerBg,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleBackButton(),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.extension_outlined,
                          color: app.headerFg,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // Balance for the back button
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Matching Puzzle',
                    style: textTheme.headlineSmall?.copyWith(
                      color: app.headerFg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            // ===== MODERN CONTENT AREA =====
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: app.panelBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Questions List
                      ..._questions.asMap().entries.map((qEntry) {
                        final qIndex = qEntry.key;
                        final question = qEntry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: app.border.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Question Header
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "Puzzle ${qIndex + 1}",
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (qIndex != 0)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.error.withOpacity(
                                            0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            color: colorScheme.error,
                                            size: 22,
                                          ),
                                          tooltip: 'Delete this question',
                                          onPressed: () =>
                                              _removeQuestion(qIndex),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Instructions
                                _buildSectionLabel('Instructions', app),
                                const SizedBox(height: 8),
                                _buildModernTextField(
                                  controller: question.instructionsController,
                                  hintText:
                                      'e.g. Match each country with its capital city',
                                  context: context,
                                  maxLines: 2,
                                  onChanged: (_) => _syncToCentral(),
                                ),
                                const SizedBox(height: 20),

                                // Column Titles
                                _buildSectionLabel('Column Titles', app),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 4,
                                              bottom: 6,
                                            ),
                                            child: Text(
                                              'Left Column',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: app.hint,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                          _buildModernTextField(
                                            controller: question
                                                .leftColumnTitleController,
                                            hintText: 'e.g. Countries',
                                            context: context,
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            onChanged: (_) => _syncToCentral(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 4,
                                              bottom: 6,
                                            ),
                                            child: Text(
                                              'Right Column',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: app.hint,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                          _buildModernTextField(
                                            controller: question
                                                .rightColumnTitleController,
                                            hintText: 'e.g. Capitals',
                                            context: context,
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            onChanged: (_) => _syncToCentral(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Pairs Section
                                Row(
                                  children: [
                                    _buildSectionLabel('Matching Pairs', app),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: app.chipBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${question.puzzlePairs.length} pairs',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: app.chipFg,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                ...question.puzzlePairs
                                    .asMap()
                                    .entries
                                    .map(
                                      (pEntry) => _buildModernPairRow(
                                        qIndex,
                                        pEntry.key,
                                        pEntry.value,
                                        context,
                                      ),
                                    )
                                    .toList(),

                                _buildModernAddPairButton(context, qIndex),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // Add Question Button
                      _buildModernAddQuestionButton(context),
                      const SizedBox(height: 32),

                      // Next Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_validateInputs()) {
                              _syncToCentral();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MatchingPuzzleViewPage(
                                    puzzleData: _puzzleData,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Please fill all required fields before proceeding.',
                                  ),
                                  backgroundColor: colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: app.primaryColor,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Preview Puzzle',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: colorScheme.onPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildSectionLabel(String text, AppColors app) {
    return Text(
      text,
      style: TextStyle(
        color: app.label,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required BuildContext context,
    EdgeInsets padding = const EdgeInsets.all(0),
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    final app = Theme.of(context).extension<AppColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: app.label.withOpacity(0.3),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.45),
              fontWeight: FontWeight.w400,
              fontSize: 14.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernPairRow(
    int questionIndex,
    int pairIndex,
    Map<String, String> pair,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final app = Theme.of(context).extension<AppColors>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: app.border.withOpacity(0.25), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ===== Left Input =====
          Expanded(
            child: TextField(
              controller: TextEditingController(text: pair['left']),
              onChanged: (value) {
                pair['left'] = value;
                _syncToCentral();
              },
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Left item',
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.35),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: app.label.withOpacity(0.3),
                    width: 1.1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.45),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),

          // ===== Swap Icon =====
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: colorScheme.primary,
              size: 18,
            ),
          ),

          // ===== Right Input =====
          Expanded(
            child: TextField(
              controller: TextEditingController(text: pair['right']),
              onChanged: (value) {
                pair['right'] = value;
                _syncToCentral();
              },
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Right item',
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.35),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: app.label.withOpacity(0.3),
                    width: 1.1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.45),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ===== Delete Button =====
          if (pairIndex != 0)
            Container(
              decoration: BoxDecoration(
                color: app.actionBubbleBg,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                  size: 20,
                ),
                onPressed: () => _removePair(questionIndex, pairIndex),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernAddPairButton(BuildContext context, int questionIndex) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        onPressed: () => _addPair(questionIndex),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        label: Text(
          'Add New Pair',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        icon: Icon(Icons.add_rounded, size: 20, color: colorScheme.primary),
      ),
    );
  }

  Widget _buildModernAddQuestionButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final app = Theme.of(context).extension<AppColors>()!;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: app.fabColor, // Blue background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addQuestion,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                /* decoration: BoxDecoration(
                  color: Colors.white, // Circle icon background white
                  shape: BoxShape.circle,
                ),*/
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white, // Blue icon
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Add Another Puzzle',
                style: TextStyle(
                  color: Colors.white, // White text on blue
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
