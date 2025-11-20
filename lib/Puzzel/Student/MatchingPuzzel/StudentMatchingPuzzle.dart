import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/BackButtonWidget.dart';
import '../../../Theme/Themes.dart';
import 'SubmitMatchingPuzzle.dart';
import 'MatchingQuestionClass.dart';

class StudentMatchingPuzzlePage extends StatelessWidget {
  final String puzzleId;
  const StudentMatchingPuzzlePage({super.key, required this.puzzleId});

  @override
  Widget build(BuildContext context) {
    return MatchingPuzzleScreen(puzzleId: puzzleId);
  }
}

class MatchingPuzzleScreen extends StatefulWidget {
  final String puzzleId;
  const MatchingPuzzleScreen({super.key, required this.puzzleId});

  @override
  State<MatchingPuzzleScreen> createState() => _MatchingPuzzleScreenState();
}

class _MatchingPuzzleScreenState extends State<MatchingPuzzleScreen> {
  bool _isLoading = true;
  List<MatchingQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchPuzzleData();
  }

  Future<void> _fetchPuzzleData() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final questionsSnap = await firestore
          .collection('matching_puzzles')
          .doc(widget.puzzleId)
          .collection('questions')
          .orderBy('order')
          .get();

      if (questionsSnap.docs.isEmpty) {
        throw Exception('No questions found for this puzzle.');
      }

      final questions = <MatchingQuestion>[];

      for (var questionDoc in questionsSnap.docs) {
        final pairsSnap = await questionDoc.reference
            .collection('pairs')
            .orderBy('order')
            .get();

        final leftItems = <String>[];
        final rightItems = <String>[];

        for (var pair in pairsSnap.docs) {
          leftItems.add(pair['left']);
          rightItems.add(pair['right']);
        }

        questions.add(
          MatchingQuestion(
            instructions: questionDoc['instructions'] ?? '',
            leftColumnTitle: questionDoc['leftColumnTitle'] ?? 'Left',
            rightColumnTitle: questionDoc['rightColumnTitle'] ?? 'Right',
            leftItems: leftItems,
            rightItems: rightItems..shuffle(),
          ),
        );
      }

      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading puzzle: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getRightItemColor(String rightItem, List<String> allRightItems) {
    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.teal.shade300,
      Colors.pink.shade300,
    ];
    final index = allRightItems.indexOf(rightItem);
    return colors[index % colors.length];
  }

  Widget _buildRightItemDraggable(String rightItem, MatchingQuestion question) {
    if (question.droppedRightItems.containsValue(rightItem)) {
      return const SizedBox(width: 100, height: 40);
    }
    final color = _getRightItemColor(rightItem, question.rightItems);
    return Draggable<String>(
      data: rightItem,
      feedback: Material(
        elevation: 4.0,
        child: _buildDraggableTile(rightItem, color, isDragging: true),
      ),
      childWhenDragging: const SizedBox(width: 100, height: 40),
      child: _buildDraggableTile(rightItem, color),
    );
  }

  Widget _buildDraggableTile(
    String text,
    Color color, {
    bool isDragging = false,
  }) {
    //final app = Theme.of(context).extension<AppColors>()!;
    return IntrinsicWidth(
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: isDragging
              ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Color(0xFF3A3F47),
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRightItemTarget(String leftItem, MatchingQuestion question) {
    final droppedRight = question.droppedRightItems[leftItem];
    final color = droppedRight != null
        ? _getRightItemColor(droppedRight, question.rightItems)
        : Colors.transparent;

    final app = Theme.of(context).extension<AppColors>()!;

    return DragTarget<String>(
      builder: (context, candidateData, rejectedData) {
        if (droppedRight != null) {
          return Draggable<String>(
            data: droppedRight,
            feedback: Material(
              elevation: 4.0,
              child: _buildDraggableTile(droppedRight, color, isDragging: true),
            ),
            childWhenDragging: Container(
              width: double.infinity,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(0xFF3A3F47),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: app.border),
              ),
            ),
            onDragCompleted: () {
              setState(() {
                question.droppedRightItems[leftItem] = null;
              });
            },
            child: Container(
              width: double.infinity,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: app.border),
              ),
              child: Text(
                droppedRight,
                style: TextStyle(
                  color: Color(0xFF3A3F47),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        return Container(
          width: double.infinity,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? app.chipBg : app.panelBg,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: candidateData.isNotEmpty ? app.ctaBlue : app.border,
              width: candidateData.isNotEmpty ? 2.0 : 1.0,
            ),
          ),
        );
      },
      onWillAccept: (data) => true,
      onAcceptWithDetails: (details) {
        setState(() {
          String? prevLeftItem;
          question.droppedRightItems.forEach((key, value) {
            if (value == details.data) prevLeftItem = key;
          });
          if (prevLeftItem != null)
            question.droppedRightItems[prevLeftItem!] = null;
          question.droppedRightItems[leftItem] = details.data;
        });
      },
    );
  }

  void _submitPuzzle() {
    for (var q in _questions) {
      debugPrint('Question: ${q.instructions}');
      debugPrint('Answers: ${q.droppedRightItems}');
    }

    {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubmitPuzzlePage(
            questions: _questions,
            puzzleId: widget.puzzleId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                          Icons.person_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Matching Puzzle',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._questions.map((q) {
                        final questionNumber = _questions.indexOf(q) + 1;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: app.panelBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: app.border, width: 1.5),
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
                              if (q.instructions.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    'Q$questionNumber. ${q.instructions}',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: app.label,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 15),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(width: 20),
                                    // Left Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            q.leftColumnTitle,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: app.label,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          for (var leftItem in q.leftItems) ...[
                                            LeftItemTile(itemName: leftItem),
                                            const SizedBox(height: 10),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    // Right Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            q.rightColumnTitle,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: app.label,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          for (var leftItem in q.leftItems) ...[
                                            _buildRightItemTarget(leftItem, q),
                                            const SizedBox(height: 10),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                'Answers',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: app.label,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: q.rightItems.map((item) {
                                  final isInTarget = q.droppedRightItems
                                      .containsValue(item);
                                  if (isInTarget)
                                    return const SizedBox.shrink();
                                  return _buildRightItemDraggable(item, q);
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      Center(
                        child: ElevatedButton(
                          onPressed: _submitPuzzle,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: app.ctaBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Next',
                            style: TextStyle(fontSize: 16, color: app.headerFg),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
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

class LeftItemTile extends StatelessWidget {
  final String itemName;
  const LeftItemTile({super.key, required this.itemName});

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: app.panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: app.border),
      ),
      child: Text(
        itemName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: app.label,
        ),
      ),
    );
  }
}
