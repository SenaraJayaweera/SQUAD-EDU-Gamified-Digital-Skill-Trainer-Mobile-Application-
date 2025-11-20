import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../widgets/BackButtonWidget.dart';
import '../../../../Theme/Themes.dart';
import '../../../../Modules/TeacherSideModules/TeacherModuleList.dart';

/// ===== Models =====
class SequenceInput {
  String id; // Firestore document id
  TextEditingController controller;

  SequenceInput({this.id = '', String value = ''})
    : controller = TextEditingController(text: value);
}

class SequenceQuestion {
  String id;
  TextEditingController instructionsController;
  List<SequenceInput> sequenceInputs;

  SequenceQuestion({
    required this.id,
    String instructions = '',
    List<SequenceInput>? inputs,
  }) : instructionsController = TextEditingController(text: instructions),
       sequenceInputs = inputs ?? [SequenceInput()];

  /// Factory method to fetch question from Firestore doc
  static Future<SequenceQuestion> fromDoc(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final inputsSnapshot = await doc.reference
        .collection('sequence_inputs')
        .orderBy('order')
        .get();

    final inputs = inputsSnapshot.docs.map((iDoc) {
      final iData = iDoc.data();
      return SequenceInput(id: iDoc.id, value: iData['value'] ?? '');
    }).toList();

    return SequenceQuestion(
      id: doc.id,
      instructions: data['instructions'] ?? '',
      inputs: inputs,
    );
  }
}

class SequencePuzzle {
  String id;
  TextEditingController puzzleNameController;
  TextEditingController puzzleDescriptionController;
  String moduleId;
  String moduleTitle;
  List<SequenceQuestion> questions;

  SequencePuzzle({
    required this.id,
    String puzzleName = '',
    String puzzleDescription = '',
    required this.moduleId,
    required this.moduleTitle,
    required this.questions,
  }) : puzzleNameController = TextEditingController(text: puzzleName),
       puzzleDescriptionController = TextEditingController(
         text: puzzleDescription,
       );

  /// Factory to fetch puzzle from Firestore
  static Future<SequencePuzzle> fromDoc(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final questionsSnapshot = await doc.reference
        .collection('questions')
        .orderBy('order')
        .get();
    List<SequenceQuestion> questions = [];

    for (var qDoc in questionsSnapshot.docs) {
      final question = await SequenceQuestion.fromDoc(qDoc);
      questions.add(question);
    }

    return SequencePuzzle(
      id: doc.id,
      puzzleName: data['puzzleName'] ?? '',
      puzzleDescription: data['puzzleDescription'] ?? '',
      moduleId: data['moduleId'] ?? '',
      moduleTitle: data['moduleTitle'] ?? '',
      questions: questions,
    );
  }
}

/// ===== Preview Page =====
class SequencePuzzlePreviewPage extends StatefulWidget {
  final String puzzleId;
  const SequencePuzzlePreviewPage({super.key, required this.puzzleId});

  @override
  State<SequencePuzzlePreviewPage> createState() =>
      _SequencePuzzlePreviewPageState();
}

class _SequencePuzzlePreviewPageState extends State<SequencePuzzlePreviewPage> {
  SequencePuzzle? _puzzleData;
  bool _loading = true;
  bool _hasError = false;

  List<String> _removedQuestionIds = [];

  @override
  void initState() {
    super.initState();
    _fetchPuzzleData();
  }

  Future<void> _fetchPuzzleData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('sequence_puzzles')
          .doc(widget.puzzleId)
          .get();
      if (!doc.exists) throw Exception('Puzzle not found');

      final puzzle = await SequencePuzzle.fromDoc(doc);

      setState(() {
        _puzzleData = puzzle;
        _loading = false;
      });
    } catch (e) {
      print('Error fetching puzzle: $e');
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  void _removeQuestion(int index) {
    // if (index == 0) return;

    final removed = _puzzleData!.questions.removeAt(index);
    if (removed.id.isNotEmpty) {
      _removedQuestionIds.add(removed.id); // track for deletion
    }

    setState(() {});
  }

  void _addQuestion() {
    if (_puzzleData == null) return;

    setState(() {
      _puzzleData!.questions.add(
        SequenceQuestion(
          id: '', // Will be generated when syncing to Firestore
          instructions: '',
        ),
      );
    });
  }

  void _addSequenceInput(int qIndex) {
    setState(
      () => _puzzleData?.questions[qIndex].sequenceInputs.add(SequenceInput()),
    );
  }

  void _removeSequenceInput(int qIndex, int inputIndex) {
    final inputs = _puzzleData!.questions[qIndex].sequenceInputs;
    if (inputs.length <= 1) return;
    setState(() {
      inputs.removeAt(inputIndex);
    });
  }

  Future<void> _syncToFirestore() async {
    if (_puzzleData == null) return;

    // Delete removed questions from Firestore
    final docRef = FirebaseFirestore.instance
        .collection('sequence_puzzles')
        .doc(_puzzleData!.id);

    for (var qId in _removedQuestionIds) {
      await docRef.collection('questions').doc(qId).delete();
    }
    _removedQuestionIds.clear();

    // Validate all questions before saving
    for (var q in _puzzleData!.questions) {
      if (q.instructionsController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All questions must have instructions!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return; // Stop saving
      }
    }

    // Update puzzle info
    await docRef.update({
      'puzzleName': _puzzleData!.puzzleNameController.text,
      'puzzleDescription': _puzzleData!.puzzleDescriptionController.text,
    });

    // Loop through questions
    for (var q in _puzzleData!.questions) {
      DocumentReference qRef;

      if (q.id.isNotEmpty) {
        // Existing question → update
        qRef = docRef.collection('questions').doc(q.id);
        await qRef.update({'instructions': q.instructionsController.text});
      } else {
        // New question → create
        qRef = await docRef.collection('questions').add({
          'instructions': q.instructionsController.text,
          'order': _puzzleData!.questions.indexOf(q),
        });
        q.id = qRef.id; // Save the new Firestore ID
      }

      // Handle inputs
      final inputsSnapshot = await qRef.collection('sequence_inputs').get();

      // Delete removed inputs
      for (var doc in inputsSnapshot.docs) {
        if (!q.sequenceInputs.any((i) => i.id == doc.id)) {
          await doc.reference.delete();
        }
      }

      // Update existing / add new inputs
      for (int i = 0; i < q.sequenceInputs.length; i++) {
        final input = q.sequenceInputs[i];
        if (input.id.isNotEmpty) {
          // Update existing input
          await qRef.collection('sequence_inputs').doc(input.id).update({
            'value': input.controller.text,
            'order': i,
          });
        } else {
          // Add new input
          final newDoc = await qRef.collection('sequence_inputs').add({
            'value': input.controller.text,
            'order': i,
          });
          input.id = newDoc.id; // Save the Firestore ID
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Puzzle synced successfully!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deletePuzzle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          title: Text(
            'Delete Puzzle',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to delete this puzzle? This action cannot be undone.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && _puzzleData != null) {
      await FirebaseFirestore.instance
          .collection('sequence_puzzles')
          .doc(_puzzleData!.id)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Puzzle deleted successfully!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TeacherModulesPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    if (_loading)
      return Scaffold(
        backgroundColor: app.headerBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(app.ctaBlue),
              ),
              SizedBox(height: 16),
              Text(
                'Loading Sequence Puzzle...',
                style: TextStyle(
                  color: app.headerFg,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    if (_hasError || _puzzleData == null)
      return Scaffold(
        backgroundColor: app.headerBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: app.error),
              SizedBox(height: 16),
              Text(
                'Puzzle not found',
                style: TextStyle(
                  color: app.error,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please check your connection and try again.',
                style: TextStyle(color: app.hint, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

    final puzzle = _puzzleData!;
    return Scaffold(
      backgroundColor: app.headerBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: app.headerBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleBackButton(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Sequence Puzzle Profile',
                      style: textTheme.headlineSmall?.copyWith(
                        color: app.headerFg,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [app.panelBg, app.panelBg.withOpacity(0.95)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Puzzle Name
                      _buildTextField(
                        puzzle.puzzleNameController,
                        'Puzzle Name',
                      ),
                      const SizedBox(height: 20),

                      // Puzzle Description
                      _buildTextField(
                        puzzle.puzzleDescriptionController,
                        'Puzzle Description',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 32),

                      // Questions
                      ...puzzle.questions
                          .map((q) => _buildQuestionCard(q))
                          .toList(),
                      const SizedBox(height: 20),

                      // Add Question Button
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addQuestion,
                          icon: Icon(Icons.add_rounded, size: 20),
                          label: Text('Add Question'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: app.ctaBlue.withOpacity(0.1),
                            foregroundColor: app.ctaBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Save Changes Button
                      Container(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _syncToFirestore,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: app.saveGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: app.saveGreen.withOpacity(0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Delete Puzzle Button
                      Container(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _deletePuzzle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            foregroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Delete Puzzle',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    final app = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: app.label,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: app.label,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: app.panelBg,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: app.border.withOpacity(0.9),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: app.ctaBlue, width: 2.0),
              ),
              hintText: 'Enter $label...',
              hintStyle: TextStyle(color: app.hint, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(SequenceQuestion question) {
    final app = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final questionIndex = _puzzleData!.questions.indexOf(question);
    final canDeleteQuestion = _puzzleData!.questions.length > 1;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Card content
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: app.panelBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: app.border.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24), // Space for delete icon
              // Instructions
              _buildTextField(question.instructionsController, 'Instructions'),
              const SizedBox(height: 20),

              // Sequence inputs
              ...question.sequenceInputs.asMap().entries.map((entry) {
                final i = entry.key;
                final input = entry.value;
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: input.controller,
                            decoration: InputDecoration(
                              //labelText: 'Sequence Item ${i + 1}',
                              filled: true,
                              fillColor: app.panelBg,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: app.border.withOpacity(0.9),
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: app.ctaBlue,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        margin: EdgeInsets.only(bottom: 4),
                        child: IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                          onPressed: () =>
                              _removeSequenceInput(questionIndex, i),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.all(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Add Item Button
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: EdgeInsets.only(top: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => _addSequenceInput(questionIndex),
                    icon: Icon(Icons.add_rounded, size: 18),
                    label: Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: app.ctaBlue.withOpacity(0.1),
                      foregroundColor: app.ctaBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Centered delete button
        if (canDeleteQuestion)
          Positioned(
            top: 18,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                onPressed: () => _removeQuestion(questionIndex),
              ),
            ),
          ),
      ],
    );
  }
}
