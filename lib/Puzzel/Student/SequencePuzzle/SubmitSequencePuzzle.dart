import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/BackButtonWidget.dart';
import '../../../Theme/Themes.dart';
import 'SequenceQuestionClass.dart';
import '../../../Modules/StudentSideModules/StudentModuleList.dart';
import 'SequenceSubmitService.dart';

class SubmitSequencePuzzlePage extends StatefulWidget {
  final String puzzleId;
  final List<SequenceQuestion> questions;

  const SubmitSequencePuzzlePage({
    super.key,
    required this.puzzleId,
    required this.questions,
  });

  @override
  State<SubmitSequencePuzzlePage> createState() =>
      _SubmitSequencePuzzlePageState();
}

class _SubmitSequencePuzzlePageState extends State<SubmitSequencePuzzlePage> {
  int? _score;
  bool _isLoading = false;
  bool _isSubmitted = false;

  Future<void> _validateAndSubmit(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text('Are you sure you want to submit this puzzle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      int correctCount = 0;
      int totalItems = 0;

      // Fetch correct answers from Firestore for each question
      for (final q in widget.questions) {
        final questionSnapshot = await firestore
            .collection('sequence_puzzles')
            .doc(widget.puzzleId)
            .collection('questions')
            .where('instructions', isEqualTo: q.instructions)
            .limit(1)
            .get();

        if (questionSnapshot.docs.isEmpty) continue;
        final questionDoc = questionSnapshot.docs.first;

        // Fetch sequence_inputs ordered by "order" field
        final inputsSnapshot = await questionDoc.reference
            .collection('sequence_inputs')
            .orderBy('order')
            .get();

        final correctSequence = inputsSnapshot.docs
            .map((doc) => doc['value'] as String)
            .toList();

        totalItems += correctSequence.length;

        for (int i = 0; i < q.droppedItems.length; i++) {
          if (q.droppedItems[i] != null &&
              i < correctSequence.length &&
              q.droppedItems[i] == correctSequence[i]) {
            correctCount++;
          }
        }
      }

      // Save summary via service
      final summaryService = SequencePuzzleSubmitService();
      await summaryService.saveSummary(
        puzzleId: widget.puzzleId,
        correctCount: correctCount,
        totalItems: totalItems,
        submittedAt: DateTime.now(),
      );

      setState(() {
        _score = correctCount;
        _isLoading = false;
        _isSubmitted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You got $correctCount out of $totalItems correct!'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting puzzle: $e')));
    }
  }

  void _finishAttempt(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const StudentModuleList()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: app.headerBg,
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: SizedBox(
                height: 114,
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
                          Icons.assignment_turned_in_outlined,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Summary',
                          style: TextStyle(
                            color: app.headerFg,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ===== WHITE PANEL =====
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: widget.questions.length,
                          itemBuilder: (context, index) {
                            final q = widget.questions[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 18),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: app.border,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Q${index + 1}. ${q.instructions}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: app.label,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Column(
                                    children: q.droppedItems
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                          final idx = entry.key;
                                          return Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: app.border.withOpacity(
                                                    0.2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              q.droppedItems[idx] ??
                                                  "Not answered",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    q.droppedItems[idx] != null
                                                    ? app.label
                                                    : Colors.grey,
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else ...[
                        if (_score != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Your Score: $_score / ${widget.questions.fold(0, (sum, q) => sum + q.droppedItems.length)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: app.label,
                              ),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: _isSubmitted
                              ? () => _finishAttempt(context)
                              : () => _validateAndSubmit(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSubmitted
                                ? Colors.green
                                : app.ctaBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _isSubmitted ? 'Finish Attempt' : 'Submit Puzzle',
                            style: TextStyle(
                              color: app.headerFg,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
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
