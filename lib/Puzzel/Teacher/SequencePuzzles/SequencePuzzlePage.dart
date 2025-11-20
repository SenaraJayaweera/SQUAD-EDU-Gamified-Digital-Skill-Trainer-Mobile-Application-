import 'package:flutter/material.dart';
import '../../../widgets/BackButtonWidget.dart';
import '../../../Theme/Themes.dart';
import '../PuzzleData.dart';
import 'SummeryDetails_Sequence.dart';

class SequencePuzzlePage extends StatefulWidget {
  final SequencePuzzleData puzzleData;
  const SequencePuzzlePage({super.key, required this.puzzleData});

  @override
  State<SequencePuzzlePage> createState() => _SequencePuzzlePageState();
}

class _SequencePuzzlePageState extends State<SequencePuzzlePage> {
  late SequencePuzzleData _puzzleData;
  late List<SequenceQuestionModel> _questions;

  @override
  void initState() {
    super.initState();
    _puzzleData = widget.puzzleData;

    // Initialize questions list from central data
    _questions = _puzzleData.questions.isNotEmpty
        ? _puzzleData.questions
        : [SequenceQuestionModel()];
  }

  void _syncToCentral() {
    _puzzleData.questions = _questions
        .map((q) {
          final hasContent =
              q.instructionsController.text.trim().isNotEmpty ||
              q.sequenceInputs.any(
                (input) => input.controller.text.trim().isNotEmpty,
              );
          return hasContent ? q : null;
        })
        .whereType<SequenceQuestionModel>()
        .toList();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(SequenceQuestionModel());
    });
    _syncToCentral();
  }

  void _removeQuestion(int index) {
    if (index == 0) return;
    setState(() {
      _questions.removeAt(index);
    });
    _syncToCentral();
  }

  void _addSequenceInput(int qIndex) {
    setState(() {
      _questions[qIndex].sequenceInputs.add(SequenceInput());
    });
    _syncToCentral();
  }

  void _removeSequenceInput(int qIndex, int inputIndex) {
    if (inputIndex == 0) return;
    setState(() {
      _questions[qIndex].sequenceInputs.removeAt(inputIndex);
    });
    _syncToCentral();
  }

  bool _validateInputs() {
    for (var q in _questions) {
      if (q.instructionsController.text.trim().isEmpty) return false;
      if (q.sequenceInputs.isEmpty) return false;
      for (var input in q.sequenceInputs) {
        if (input.controller.text.trim().isEmpty) return false;
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
            // ===== Header =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: app.headerBg,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const CircleBackButton(),
                  const Spacer(),
                  Text(
                    'Sequence Puzzle',
                    style: textTheme.headlineSmall?.copyWith(
                      color: app.headerFg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // ===== Content =====
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: app.panelBg, // <-- light background for content
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      ..._questions.asMap().entries.map((qEntry) {
                        final qIndex = qEntry.key;
                        final question = qEntry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: app.border.withOpacity(0.8),
                              width: 2.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Question Header
                              Row(
                                children: [
                                  Text(
                                    "Puzzle ${qIndex + 1}",
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (qIndex != 0)
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: colorScheme.error,
                                      ),
                                      onPressed: () => _removeQuestion(qIndex),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Instructions
                              Text(
                                'Instructions',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: app.label,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildModernTextField(
                                controller: question.instructionsController,
                                hintText: 'Enter puzzle instructions',
                                context: context,
                                onChanged: (_) => _syncToCentral(),
                              ),
                              const SizedBox(height: 16),
                              // Sequence Inputs
                              Text(
                                'Sequence Items',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: app.label,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...question.sequenceInputs.asMap().entries.map((
                                sEntry,
                              ) {
                                final sIndex = sEntry.key;
                                final input = sEntry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${sIndex + 1}',
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildModernTextField(
                                          controller: input.controller,
                                          hintText: 'Enter value',
                                          context: context,
                                          onChanged: (_) => _syncToCentral(),
                                        ),
                                      ),
                                      if (sIndex != 0)
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            color: colorScheme.error,
                                          ),
                                          onPressed: () => _removeSequenceInput(
                                            qIndex,
                                            sIndex,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                              // Add new sequence input
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _addSequenceInput(qIndex),
                                  icon: Icon(
                                    Icons.add,
                                    color: colorScheme.primary,
                                  ),
                                  label: Text(
                                    'Add Item',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      // Add Another Puzzle
                      _buildModernAddQuestionButton(context),
                      const SizedBox(height: 16),
                      // Preview Button
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
                            if (!_validateInputs()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Please fill all instructions and sequence items before previewing.',
                                  ),
                                  backgroundColor: colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                              return;
                            }
                            _syncToCentral();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SequencePuzzleViewPage(
                                  puzzleData: _puzzleData,
                                ),
                              ),
                            );
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

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required BuildContext context,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    final app = Theme.of(context).extension<AppColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: app.border.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
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
          ),
        ),
      ),
    );
  }

  Widget _buildModernAddQuestionButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final app = Theme.of(context).extension<AppColors>()!;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: app.fabColor,
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
              Icon(Icons.add_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Add Another Puzzle',
                style: const TextStyle(
                  color: Colors.white,
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
