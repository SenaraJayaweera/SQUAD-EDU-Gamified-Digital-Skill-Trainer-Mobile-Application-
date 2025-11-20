import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../widgets/BackButtonWidget.dart';
import '../../../../Theme/Themes.dart';
import '../../../../Modules/TeacherSideModules/TeacherModuleList.dart';

/// Models
class MatchingPair {
  String id; // Firestore document id
  String left;
  String right;

  MatchingPair({this.id = '', required this.left, required this.right});
}

class MatchingQuestion {
  String id;
  TextEditingController instructionsController;
  TextEditingController leftColumnTitleController;
  TextEditingController rightColumnTitleController;
  List<MatchingPair> pairs;

  MatchingQuestion({
    required this.id,
    String instructions = '',
    String leftColumnTitle = '',
    String rightColumnTitle = '',
    List<MatchingPair>? initialPairs,
  }) : instructionsController = TextEditingController(text: instructions),
       leftColumnTitleController = TextEditingController(text: leftColumnTitle),
       rightColumnTitleController = TextEditingController(
         text: rightColumnTitle,
       ),
       pairs = initialPairs ?? [MatchingPair(left: '', right: '')];
}

class MatchingPuzzle {
  String id;
  TextEditingController puzzleNameController;
  TextEditingController puzzleDescriptionController;
  String moduleId;
  String moduleTitle;
  List<MatchingQuestion> questions;

  MatchingPuzzle({
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

  /// Fetch from Firestore
  static Future<MatchingPuzzle> fromDoc(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final questionsSnapshot = await doc.reference
        .collection('questions')
        .orderBy('order')
        .get();

    List<MatchingQuestion> questions = [];

    for (var qDoc in questionsSnapshot.docs) {
      final qData = qDoc.data();
      final pairsSnapshot = await qDoc.reference
          .collection('pairs')
          .orderBy('order')
          .get();

      final pairs = pairsSnapshot.docs.map((pDoc) {
        final pData = pDoc.data();
        return MatchingPair(
          id: pDoc.id,
          left: pData['left'] ?? '',
          right: pData['right'] ?? '',
        );
      }).toList();

      questions.add(
        MatchingQuestion(
          id: qDoc.id,
          instructions: qData['instructions'] ?? '',
          leftColumnTitle: qData['leftColumnTitle'] ?? '',
          rightColumnTitle: qData['rightColumnTitle'] ?? '',
          initialPairs: pairs,
        ),
      );
    }

    return MatchingPuzzle(
      id: doc.id,
      puzzleName: data['puzzleName'] ?? '',
      puzzleDescription: data['puzzleDescription'] ?? '',
      moduleId: data['moduleId'] ?? '',
      moduleTitle: data['moduleTitle'] ?? '',
      questions: questions,
    );
  }
}

/// Editable Preview Page
class MatchingPuzzlePreviewPage extends StatefulWidget {
  final String puzzleId;
  const MatchingPuzzlePreviewPage({super.key, required this.puzzleId});

  @override
  State<MatchingPuzzlePreviewPage> createState() =>
      _MatchingPuzzlePreviewPageState();
}

class _MatchingPuzzlePreviewPageState extends State<MatchingPuzzlePreviewPage> {
  MatchingPuzzle? _puzzleData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchPuzzleData();
  }

  Future<void> _fetchPuzzleData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('matching_puzzles')
          .doc(widget.puzzleId)
          .get();

      if (doc.exists) {
        final puzzle = await MatchingPuzzle.fromDoc(doc);
        setState(() {
          _puzzleData = puzzle;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _syncToFirestore() async {
    if (_puzzleData == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('matching_puzzles')
        .doc(_puzzleData!.id);

    await docRef.update({
      'puzzleName': _puzzleData!.puzzleNameController.text,
      'puzzleDescription': _puzzleData!.puzzleDescriptionController.text,
    });

    for (var q in _puzzleData!.questions) {
      final qRef = docRef.collection('questions').doc(q.id);
      await qRef.update({
        'instructions': q.instructionsController.text,
        'leftColumnTitle': q.leftColumnTitleController.text,
        'rightColumnTitle': q.rightColumnTitleController.text,
      });

      final pairsSnapshot = await qRef.collection('pairs').get();
      for (int i = 0; i < q.pairs.length; i++) {
        if (i < pairsSnapshot.docs.length) {
          await pairsSnapshot.docs[i].reference.update({
            'left': q.pairs[i].left,
            'right': q.pairs[i].right,
          });
        } else {
          await qRef.collection('pairs').add({
            'left': q.pairs[i].left,
            'right': q.pairs[i].right,
            'order': i,
          });
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

  void _addPair(MatchingQuestion question) {
    setState(() {
      question.pairs.add(MatchingPair(left: '', right: ''));
    });
  }

  void _removePair(MatchingQuestion question, int index) async {
    final pair = question.pairs[index];

    if (pair.id.isNotEmpty) {
      // Delete from Firestore
      final qRef = FirebaseFirestore.instance
          .collection('matching_puzzles')
          .doc(_puzzleData!.id)
          .collection('questions')
          .doc(question.id)
          .collection('pairs')
          .doc(pair.id);

      await qRef.delete();
    }

    // Remove from local list
    setState(() {
      question.pairs.removeAt(index);
    });
  }

  // Add this inside your _MatchingPuzzlePreviewPageState class:

  void _deletePuzzle() async {
    final TextEditingController confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          title: const Text(
            'Delete Puzzle',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to delete this puzzle? '
                'Type "delete" to confirm.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                decoration: InputDecoration(
                  hintText: 'Type "delete" here',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (confirmController.text.trim().toLowerCase() == 'delete') {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You must type "delete" to confirm!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && _puzzleData != null) {
      try {
        // Delete the puzzle document
        await FirebaseFirestore.instance
            .collection('matching_puzzles')
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

        // Navigate back to module list
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TeacherModulesPage()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete puzzle: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    // final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        // backgroundColor: app.headerBg,
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
                'Loading Puzzle...',
                style: TextStyle(
                  color: app.label,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError || _puzzleData == null) {
      return Scaffold(
        backgroundColor: app.headerBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: app.error),
              SizedBox(height: 16),
              Text(
                'Failed to load puzzle.',
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
    }

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
                      'Matching Puzzle Profile',
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
                        controller: puzzle.puzzleNameController,
                        label: 'Puzzle Name',
                        context: context,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: puzzle.puzzleDescriptionController,
                        label: 'Puzzle Description',
                        context: context,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 32),

                      // Questions
                      ...puzzle.questions.map((q) {
                        return _buildQuestionCard(q);
                      }).toList(),

                      const SizedBox(height: 32),
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
                                'Delete Entire Puzzle',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required BuildContext context,
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
              fontSize: 16,
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

  Widget _buildQuestionCard(MatchingQuestion question) {
    final app = Theme.of(context).extension<AppColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: app.panelBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: app.border.withOpacity(0.15)),
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
          // Instructions
          _buildTextField(
            controller: question.instructionsController,
            label: 'Instructions',
            context: context,
          ),
          const SizedBox(height: 16),

          // Column Titles
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: question.leftColumnTitleController,
                  label: 'Left Column',
                  context: context,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: question.rightColumnTitleController,
                  label: 'Right Column',
                  context: context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pairs
          ...question.pairs.asMap().entries.map((entry) {
            final i = entry.key;
            final pair = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        controller: TextEditingController(text: pair.left),
                        onChanged: (val) => pair.left = val,
                        decoration: InputDecoration(
                          //labelText: 'Left Item',
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
                  const SizedBox(width: 12),
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
                        controller: TextEditingController(text: pair.right),
                        onChanged: (val) => pair.right = val,
                        decoration: InputDecoration(
                          //labelText: 'Right Item',
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
                    margin: EdgeInsets.only(top: 4),
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                      onPressed: () => _removePair(question, i),
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

          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _addPair(question),
              icon: Icon(Icons.add_rounded, size: 20),
              label: Text('Add Pair'),
              style: ElevatedButton.styleFrom(
                backgroundColor: app.ctaBlue.withOpacity(0.1),
                foregroundColor: app.ctaBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                shadowColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
