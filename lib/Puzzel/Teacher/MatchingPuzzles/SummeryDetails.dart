import 'package:flutter/material.dart';
import '../../../Theme/Themes.dart';
import '../../../widgets/BackButtonWidget.dart';
import '../PuzzleData.dart';
import '../../../Modules/TeacherSideModules/TeacherModuleList.dart';
import '../SubmitConfirmDialog.dart';
import 'MatchingPuzzleFirebaseService.dart';

class MatchingPuzzleViewPage extends StatelessWidget {
  final MatchingPuzzleData puzzleData;
  const MatchingPuzzleViewPage({super.key, required this.puzzleData});

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: app.headerBg,
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER  =====
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.extension,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Puzzle Summery',
                          style: TextStyle(
                            color: app.headerFg,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          puzzleData.moduleTitle.isEmpty
                              ? 'Module Name not set'
                              : puzzleData.moduleTitle,
                          style: TextStyle(
                            color: app.headerFg,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ===== MODERNIZED CONTENT PANEL =====
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
                      // ==== Modern Puzzle Info Card ====
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
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
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.extension_rounded,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    puzzleData.puzzleName.isEmpty
                                        ? 'Puzzle Name not set'
                                        : puzzleData.puzzleName,
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (puzzleData.puzzleDescription.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Description',
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: app.label,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: app.panelBg.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: app.border.withOpacity(
                                          0.5,
                                        ), // Set your desired color & opacity
                                        width:
                                            1.5, // Optional: set border thickness
                                      ),
                                    ),
                                    child: Text(
                                      puzzleData.puzzleDescription,
                                      style: textTheme.bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Type: ${puzzleData.selectedPuzzleType ?? "Not selected"}',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==== Modern Questions List ====
                      ...puzzleData.questions.asMap().entries.map((qEntry) {
                        final qIndex = qEntry.key;
                        final question = qEntry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: app.border.withOpacity(0.2),
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
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.question_answer_rounded,
                                            color: colorScheme.primary,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Question ${qIndex + 1}",
                                            style: textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: colorScheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Instructions
                                if (question
                                    .instructionsController
                                    .text
                                    .isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Question",
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: app.label,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: app.panelBg.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: app.border.withOpacity(
                                              0.5,
                                            ), // Set your desired color & opacity
                                            width:
                                                1.5, // Optional: set border thickness
                                          ),
                                        ),
                                        child: Text(
                                          question.instructionsController.text,
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),

                                // Column Titles with modern border style
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: app.panelBg.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: app.border.withOpacity(
                                        0.5,
                                      ), // border color & opacity
                                      width: 1.5, // border thickness
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Left Column Label
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: app.panelBg.withOpacity(
                                                  0.3,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: app.border.withOpacity(
                                                    0.5,
                                                  ),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                "Left Column",
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: app.hint,
                                                      fontSize: 12,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // Left Column Value
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: app.panelBg.withOpacity(
                                                  0.2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: app.border.withOpacity(
                                                    0.5,
                                                  ),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                question
                                                        .leftColumnTitleController
                                                        .text
                                                        .isEmpty
                                                    ? 'N/A'
                                                    : question
                                                          .leftColumnTitleController
                                                          .text,
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 18,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: app.border.withOpacity(0.5),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Right Column Label
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: app.panelBg.withOpacity(
                                                  0.3,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: app.border.withOpacity(
                                                    0.5,
                                                  ),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                "Right Column",
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: app.hint,
                                                      fontSize: 12,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // Right Column Value
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: app.panelBg.withOpacity(
                                                  0.2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: app.border.withOpacity(
                                                    0.5,
                                                  ),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                question
                                                        .rightColumnTitleController
                                                        .text
                                                        .isEmpty
                                                    ? 'N/A'
                                                    : question
                                                          .rightColumnTitleController
                                                          .text,
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 18,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Pairs Section
                                Text(
                                  "Matching Pairs",
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: app.label,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: app.border.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: question.puzzlePairs
                                        .asMap()
                                        .entries
                                        .map((pairEntry) {
                                          final pairIndex = pairEntry.key;
                                          final pair = pairEntry.value;
                                          return Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: pairIndex.isEven
                                                  ? app.panelBg.withOpacity(0.3)
                                                  : colorScheme.surface,
                                              borderRadius: pairIndex == 0
                                                  ? const BorderRadius.vertical(
                                                      top: Radius.circular(12),
                                                    )
                                                  : pairIndex ==
                                                        question
                                                                .puzzlePairs
                                                                .length -
                                                            1
                                                  ? const BorderRadius.vertical(
                                                      bottom: Radius.circular(
                                                        12,
                                                      ),
                                                    )
                                                  : BorderRadius.zero,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          colorScheme.surface,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: app.border
                                                            .withOpacity(0.5),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      pair.left.isEmpty
                                                          ? '-'
                                                          : pair.left,
                                                      style: textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 18,
                                                          ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary
                                                        .withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: colorScheme.primary,
                                                    size: 16,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          colorScheme.surface,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: app.border
                                                            .withOpacity(0.5),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      pair.right.isEmpty
                                                          ? '-'
                                                          : pair.right,
                                                      style: textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 18,
                                                          ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      // spacing before the button
                      const SizedBox(height: 16),

                      // Button at the end of the scroll content
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showSubmitConfirmDialog(
                              context,
                              onConfirm: () async {
                                final firebaseService =
                                    MatchingPuzzleFirebaseService();
                                try {
                                  await firebaseService.uploadSequencePuzzle(
                                    puzzleData,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Matching puzzle uploaded successfully!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const TeacherModulesPage(),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Upload failed: $e'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                            );
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            'Submit the Puzzle',
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
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
}
