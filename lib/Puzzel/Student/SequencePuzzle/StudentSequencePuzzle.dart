import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../widgets/BackButtonWidget.dart';
import '../../../../Theme/Themes.dart';
import 'SubmitSequencePuzzle.dart';
import 'SequenceQuestionClass.dart';

class StudentSequencePuzzlePage extends StatelessWidget {
  final String puzzleId;
  const StudentSequencePuzzlePage({super.key, required this.puzzleId});

  @override
  Widget build(BuildContext context) {
    return SequencePuzzleScreen(puzzleId: puzzleId);
  }
}

class SequencePuzzleScreen extends StatefulWidget {
  final String puzzleId;
  const SequencePuzzleScreen({super.key, required this.puzzleId});

  @override
  State<SequencePuzzleScreen> createState() => _SequencePuzzleScreenState();
}

class _SequencePuzzleScreenState extends State<SequencePuzzleScreen> {
  bool _isLoading = true;
  List<SequenceQuestion> _questions = [];

  final List<Color> _colors = [
    Colors.blue.shade300,
    Colors.green.shade300,
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.red.shade300,
    Colors.teal.shade300,
    Colors.pink.shade300,
  ];

  @override
  void initState() {
    super.initState();
    _fetchPuzzleData();
  }

  Future<void> _fetchPuzzleData() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final questionsSnap = await firestore
          .collection('sequence_puzzles')
          .doc(widget.puzzleId)
          .collection('questions')
          .orderBy('order')
          .get();

      final questions = <SequenceQuestion>[];

      for (var questionDoc in questionsSnap.docs) {
        final inputsSnap = await questionDoc.reference
            .collection('sequence_inputs')
            .orderBy('order')
            .get();

        final items = <String>[];
        for (var input in inputsSnap.docs) {
          items.add(input['value']);
        }

        questions.add(
          SequenceQuestion(
            instructions: questionDoc['instructions'] ?? '',
            sequenceItems: items..shuffle(),
            droppedItems: List<String?>.filled(items.length, null),
          ),
        );
      }

      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading sequence puzzle: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDropBox(int index, SequenceQuestion question) {
    final app = Theme.of(context).extension<AppColors>()!;
    final droppedItem = question.droppedItems[index];
    Color bgColor = droppedItem != null
        ? _colors[index % _colors.length]
        : app.panelBg;

    return DragTarget<String>(
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            // Remove the dropped item if exists
            if (droppedItem != null) {
              setState(() {
                question.droppedItems[index] = null;
              });
            }
          },
          child: Container(
            width: double.infinity,
            height: 50,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty ? app.chipBg : bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: candidateData.isNotEmpty ? app.ctaBlue : app.border,
                width: candidateData.isNotEmpty ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${index + 1}. ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: app.label,
                  ),
                ),
                Expanded(
                  child: Text(
                    droppedItem ?? '',
                    style: TextStyle(
                      color: droppedItem != null ? Colors.white : app.label,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (droppedItem != null)
                  Icon(Icons.close, color: Colors.white, size: 20),
              ],
            ),
          ),
        );
      },
      onWillAccept: (data) => true,
      onAccept: (data) {
        setState(() {
          for (int i = 0; i < question.droppedItems.length; i++) {
            if (question.droppedItems[i] == data)
              question.droppedItems[i] = null;
          }
          question.droppedItems[index] = data;
        });
      },
    );
  }

  Widget _buildDraggableItem(
    String item,
    SequenceQuestion question, {
    int? index,
  }) {
    if (question.droppedItems.contains(item)) return const SizedBox.shrink();

    final color = index != null
        ? _colors[index % _colors.length]
        : Colors.blue.shade300;

    return Draggable<String>(
      data: item,
      feedback: Material(
        elevation: 4,
        child: _buildItemTile(item, color, isDragging: true),
      ),
      childWhenDragging: const SizedBox(width: 100, height: 40),
      child: _buildItemTile(item, color),
    );
  }

  Widget _buildItemTile(String item, Color color, {bool isDragging = false}) {
    return IntrinsicWidth(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 150,
        ), // limit width
        height: 50,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isDragging
              ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)]
              : null,
        ),
        child: Text(
          item,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _submitPuzzle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmitSequencePuzzlePage(
          puzzleId: widget.puzzleId,
          questions: _questions,
        ),
      ),
    );
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
                          Icons.list_alt_outlined,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sequence Puzzle',
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
                    children: [
                      ..._questions.map((q) {
                        final questionNumber = _questions.indexOf(q) + 1;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
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
                              Text(
                                'Q$questionNumber. ${q.instructions}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: app.label,
                                ),
                              ),
                              const SizedBox(height: 15),
                              // Drop boxes
                              Column(
                                children: q.droppedItems.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  return _buildDropBox(index, q);
                                }).toList(),
                              ),
                              const SizedBox(height: 15),
                              // Answers section horizontally
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
                                children: q.sequenceItems
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => _buildDraggableItem(
                                        entry.value,
                                        q,
                                        index: entry.key,
                                      ),
                                    )
                                    .toList(),
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
