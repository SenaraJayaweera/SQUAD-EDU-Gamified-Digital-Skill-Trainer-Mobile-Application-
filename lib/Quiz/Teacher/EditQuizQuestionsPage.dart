// // lib/Quiz/Teacher/EditQuizQuestionsPage.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import './PublishEditedQuizPage.dart';
// import '../../Theme/Themes.dart';
// import './quiz_models.dart' as qm;

// class EditQuizQuestionsPage extends StatefulWidget {
//   const EditQuizQuestionsPage({super.key});

//   @override
//   State<EditQuizQuestionsPage> createState() => _EditQuizQuestionsPageState();
// }

// class _EditQuizQuestionsPageState extends State<EditQuizQuestionsPage> {
//   // ---- layout tokens (match your preview page) ----
//   static const double _hPad = 20;
//   static const double _radius = 16;
//   static const double _fieldH = 56;
//   static const double _bigFieldMinH = 120;
//   static const double _rowGap = 18;
//   static const double _borderW = 1.6;

//   String? _quizId;

//   // Loaded meta for publish hand-off
//   String _moduleId = 'Unknown';
//   String _moduleTitle = 'Module';
//   String _quizTitle = '';

//   // Preset (from doc)
//   late qm.PublishPreset _preset;

//   // Questions list
//   List<qm.QuizQuestion> _qs = [];
//   int _index = 0;

//   bool _loading = true;
//   bool _saving = false;
//   bool _editing = true;

//   // controllers for active question
//   final _qC = TextEditingController();
//   final _hintC = TextEditingController();
//   final _expC = TextEditingController();
//   final Map<String, TextEditingController> _optCtrls = {
//     'A': TextEditingController(),
//     'B': TextEditingController(),
//     'C': TextEditingController(),
//     'D': TextEditingController(),
//   };

//   qm.QuizQuestion get _q => _qs[_index];

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final args = ModalRoute.of(context)?.settings.arguments as Map?;
//     _quizId ??= args?['quizId']?.toString();
//     if (_quizId != null && _loading) {
//       _load();
//     }
//   }

//   @override
//   void dispose() {
//     _qC.dispose();
//     _hintC.dispose();
//     _expC.dispose();
//     for (final c in _optCtrls.values) {
//       c.dispose();
//     }
//     super.dispose();
//   }

//   Future<void> _load() async {
//     try {
//       setState(() => _loading = true);
//       final snap = await FirebaseFirestore.instance
//           .collection('quizzes')
//           .doc(_quizId)
//           .get();

//       if (!snap.exists) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Quiz not found')),
//           );
//           Navigator.pop(context);
//         }
//         return;
//       }

//       final data = snap.data()!;
//       _moduleId = (data['moduleId'] ?? 'Unknown').toString();
//       _moduleTitle = (data['moduleTitle'] ?? 'Module').toString();
//       _quizTitle = (data['quizTitle'] ?? '').toString();

//       final preset = Map<String, dynamic>.from(data['preset'] ?? {});
//       _preset = qm.PublishPreset(
//         difficulty: (preset['difficulty'] ?? 'All').toString(),
//         points: (preset['points'] ?? 0) is int
//             ? preset['points']
//             : int.tryParse('${preset['points']}') ?? 0,
//         hints: (preset['hints'] ?? 'Enable').toString(),
//         lives: (preset['lives'] ?? 0) is int
//             ? preset['lives']
//             : int.tryParse('${preset['lives']}') ?? 0,
//         questions: (preset['questions'] ?? 0) is int
//             ? preset['questions']
//             : int.tryParse('${preset['questions']}') ?? 0,
//         time: (preset['time'] ?? '10 Min').toString(),
//       );

//       final rawQs = (data['questions'] as List<dynamic>? ?? [])
//           .map((e) => Map<String, dynamic>.from(e))
//           .toList();

//       _qs = rawQs.map((m) => qm.QuizQuestion.fromMap(m)).toList();
//       if (_qs.isEmpty) {
//         // Shouldn't happen, but guard
//         _qs = [
//           qm.QuizQuestion(
//             index: 1,
//             title: 'Question 1',
//             hint: '',
//             explanation: '',
//             choices: [
//               qm.QuizChoice(letter: 'A', text: 'Option A', isCorrect: true),
//               qm.QuizChoice(letter: 'B', text: 'Option B', isCorrect: false),
//               qm.QuizChoice(letter: 'C', text: 'Option C', isCorrect: false),
//               qm.QuizChoice(letter: 'D', text: 'Option D', isCorrect: false),
//             ],
//           )
//         ];
//       }
//       _index = 0;
//       _hydrateControllers();
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load quiz: $e')),
//       );
//       Navigator.pop(context);
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   void _hydrateControllers() {
//     _qC.text = _q.title;
//     _hintC.text = _q.hint;
//     _expC.text = _q.explanation;
//     for (final c in _q.choices) {
//       _optCtrls[c.letter]?.text = c.text;
//     }
//     setState(() {});
//   }

//   qm.QuizQuestion _buildFromControllers(qm.QuizQuestion base) {
//     final updatedChoices = base.choices.map((c) {
//       final txt = _optCtrls[c.letter]?.text.trim() ?? c.text;
//       return qm.QuizChoice(letter: c.letter, text: txt, isCorrect: c.isCorrect);
//     }).toList();

//     return qm.QuizQuestion(
//       index: base.index,
//       title: _qC.text.trim(),
//       hint: _hintC.text.trim(),
//       explanation: _expC.text.trim(),
//       choices: updatedChoices,
//     );
//   }

//   void _setCorrectByLetter(String letter) {
//     setState(() {
//       final base = _buildFromControllers(_q);
//       final updated = base.choices
//           .map((c) => qm.QuizChoice(
//                 letter: c.letter,
//                 text: c.text,
//                 isCorrect: c.letter == letter,
//               ))
//           .toList();
//       _qs[_index] = qm.QuizQuestion(
//         index: base.index,
//         title: base.title,
//         hint: base.hint,
//         explanation: base.explanation,
//         choices: updated,
//       );
//       _hydrateControllers();
//     });
//   }

//   Future<void> _saveCurrentToFirestore({bool goNext = false}) async {
//     if (_saving) return;
//     setState(() => _saving = true);
//     try {
//       // Update in-memory question from controllers
//       _qs[_index] = _buildFromControllers(_q);

//       // Push the whole questions array
//       final payloadQs = _qs.map((q) => q.toMap()).toList();

//       // Also keep preset.questions accurate
//       final presetMap = {
//         'difficulty': _preset.difficulty,
//         'points': _preset.points,
//         'hints': _preset.hints,
//         'lives': _preset.lives,
//         'questions': _qs.length,
//         'time': _preset.time,
//       };

//       await FirebaseFirestore.instance.collection('quizzes').doc(_quizId).update(
//         {
//           'questions': payloadQs,
//           'preset': presetMap,
//           'quizTitle': _quizTitle, // unchanged
//         },
//       );

//       if (!mounted) return;

//       if (goNext) {
//         // If last -> forward to publish page with updated data
//         if (_index + 1 >= _qs.length) {
//           // await Navigator.pushReplacement(
//           //   context,
//           //   MaterialPageRoute(
//           //     builder: (_) => PublishQuizPage(preset: _preset),
//           //     settings: RouteSettings(arguments: {
//           //       'moduleId': _moduleId,
//           //       'moduleTitle': _moduleTitle,
//           //       'quizTitle': _quizTitle,
//           //       'questions': _qs, // edited list
//           //     }),
//           //   ),
//           // );
//           // return;
//           // AFTER saving the last question:
//           await Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (_) => const PublishEditedQuizPage(),
//               settings: RouteSettings(arguments: {
//                 'quizId': _quizId,                 // IMPORTANT: update existing doc
//                 'moduleId': _moduleId,
//                 'moduleTitle': _moduleTitle,
//                 'quizTitle': _quizTitle,           // current title shown/editable
//                 'preset': _preset,                 // qm.PublishPreset
//                 'questions': _qs,                  // edited list
//                 'attempts': '3',                   // optional default you want to show
//               }),
//             ),
//           );
//         }
//         setState(() {
//           _index++;
//           _hydrateControllers();
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Question saved'),
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Save failed: $e')),
//       );
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   Future<void> _deleteThisQuestion() async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Delete Question'),
//         content:
//             const Text('Are you sure you want to delete this Question?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
//           TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
//         ],
//       ),
//     );
//     if (confirmed != true) return;

//     if (_qs.length == 1) {
//       // delete last question -> you might decide to delete the quiz, but here we just block
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Quiz must have at least one question.')),
//       );
//       return;
//     }

//     setState(() => _saving = true);
//     try {
//       _qs.removeAt(_index);
//       // reindex 1..n
//       for (var i = 0; i < _qs.length; i++) {
//         _qs[i] = qm.QuizQuestion(
//           index: i + 1,
//           title: _qs[i].title,
//           hint: _qs[i].hint,
//           explanation: _qs[i].explanation,
//           choices: _qs[i].choices,
//         );
//       }
//       if (_index >= _qs.length) _index = _qs.length - 1;

//       final payloadQs = _qs.map((q) => q.toMap()).toList();
//       final presetMap = {
//         'difficulty': _preset.difficulty,
//         'points': _preset.points,
//         'hints': _preset.hints,
//         'lives': _preset.lives,
//         'questions': _qs.length,
//         'time': _preset.time,
//       };

//       await FirebaseFirestore.instance.collection('quizzes').doc(_quizId).update({
//         'questions': payloadQs,
//         'preset': presetMap,
//       });

//       if (!mounted) return;
//       _hydrateControllers();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Question deleted')),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Delete failed: $e')),
//       );
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   void _prev() {
//     if (_index == 0) return;
//     setState(() {
//       _qs[_index] = _buildFromControllers(_q);
//       _index--;
//       _hydrateControllers();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final app = Theme.of(context).extension<AppColors>()!;

//     if (_quizId == null) {
//       return const Scaffold(
//         body: Center(child: Text('Missing quizId in route arguments')),
//       );
//     }

//     if (_loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     final correct = {for (final c in _q.choices) c.letter: c.isCorrect};

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: SafeArea(
//         bottom: false,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Title row with trash button
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       'Question ${_index + 1}',
//                       style: TextStyle(
//                         color: cs.onSurface,
//                         fontSize: 26,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                   ),
//                   // delete question icon
//                   InkWell(
//                     onTap: _saving ? null : _deleteThisQuestion,
//                     borderRadius: BorderRadius.circular(24),
//                     child: Container(
//                       width: 42,
//                       height: 42,
//                       decoration: BoxDecoration(
//                         color: app.chipBg,
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(Icons.delete_outline, color: Color(0xFFD1646C)),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),

//               // Question field
//               _RoundedFieldShell(
//                 radius: _radius,
//                 borderWidth: _borderW,
//                 borderColor: app.borderStrong,
//                 minHeight: _fieldH,
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                 child: TextField(
//                   controller: _qC,
//                   readOnly: !_editing,
//                   minLines: 1,
//                   maxLines: 4,
//                   decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: 'Edit Question'),
//                   style: TextStyle(
//                     color: cs.onSurface,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: _rowGap),

//               // Options A-D
//               ...['A', 'B', 'C', 'D'].map((letter) {
//                 final isCorrect = correct[letter] ?? false;
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 14),
//                   child: GestureDetector(
//                     onDoubleTap: _editing ? () => _setCorrectByLetter(letter) : null,
//                     child: _OptionTile(
//                       letter: letter,
//                       controller: _optCtrls[letter]!,
//                       readOnly: !_editing,
//                       isCorrect: isCorrect,
//                       radius: _radius,
//                       height: _fieldH,
//                       borderWidth: _borderW,
//                       borderColor: isCorrect ? app.correctBorder : app.borderStrong,
//                       fillColor: isCorrect ? app.correctFill : app.panelBg,
//                       textColor: cs.onSurface,
//                     ),
//                   ),
//                 );
//               }),

//               // Hint
//               Text(
//                 'Hint',
//                 style: TextStyle(
//                   color: cs.onSurface,
//                   fontSize: 22,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               _RoundedFieldShell(
//                 radius: _radius,
//                 borderWidth: _borderW,
//                 borderColor: app.borderStrong,
//                 minHeight: _bigFieldMinH,
//                 padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
//                 child: TextField(
//                   controller: _hintC,
//                   readOnly: !_editing,
//                   minLines: 3,
//                   maxLines: 6,
//                   decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: 'Edit Hint'),
//                   style: TextStyle(
//                     color: cs.onSurface,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w700,
//                     height: 1.35,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: _rowGap),

//               // Explanation
//               Text(
//                 'Answer Explanation',
//                 style: TextStyle(
//                   color: cs.onSurface,
//                   fontSize: 22,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               _RoundedFieldShell(
//                 radius: _radius,
//                 borderWidth: _borderW,
//                 borderColor: app.borderStrong,
//                 minHeight: _bigFieldMinH,
//                 padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
//                 child: TextField(
//                   controller: _expC,
//                   readOnly: !_editing,
//                   minLines: 4,
//                   maxLines: 8,
//                   decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: 'Edit Explanation'),
//                   style: TextStyle(
//                     color: cs.onSurface,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w700,
//                     height: 1.35,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 14),

//               // Buttons row
//               Row(
//                 children: [
//                   Expanded(
//                     child: SizedBox(
//                       height: 50,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           if (_editing) {
//                             // Commit local only
//                             _qs[_index] = _buildFromControllers(_q);
//                           }
//                           setState(() => _editing = !_editing);
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: app.ctaBlue,
//                           foregroundColor: Colors.white,
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             side: BorderSide(color: app.ctaBlueBorder, width: 1.4),
//                           ),
//                           textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
//                         ),
//                         child: Text(_editing ? 'DONE EDITING' : 'EDIT QUESTION'),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),

//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: _index == 0 || _saving ? null : _prev,
//                       style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
//                       child: const Text('Previous Q'),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: _saving ? null : () => _saveCurrentToFirestore(goNext: true),
//                       style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
//                       child: const Text('Save & Next Q'),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ======= small shared widgets =======

// class _RoundedFieldShell extends StatelessWidget {
//   final Widget child;
//   final double radius;
//   final double borderWidth;
//   final Color borderColor;
//   final EdgeInsets? padding;
//   final double? minHeight;

//   const _RoundedFieldShell({
//     required this.child,
//     required this.radius,
//     required this.borderWidth,
//     required this.borderColor,
//     this.padding,
//     this.minHeight,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final app = Theme.of(context).extension<AppColors>()!;
//     return Container(
//       constraints: BoxConstraints(minHeight: minHeight ?? _EditQuizQuestionsPageState._fieldH),
//       decoration: BoxDecoration(
//         color: app.panelBg,
//         borderRadius: BorderRadius.circular(radius),
//         border: Border.all(color: borderColor, width: borderWidth),
//       ),
//       padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
//       alignment: Alignment.centerLeft,
//       child: child,
//     );
//   }
// }

// class _OptionTile extends StatelessWidget {
//   final String letter;
//   final TextEditingController controller;
//   final bool readOnly;
//   final bool isCorrect;
//   final double radius;
//   final double height;
//   final double borderWidth;
//   final Color borderColor;
//   final Color fillColor;
//   final Color textColor;

//   const _OptionTile({
//     required this.letter,
//     required this.controller,
//     required this.readOnly,
//     required this.isCorrect,
//     required this.radius,
//     required this.height,
//     required this.borderWidth,
//     required this.borderColor,
//     required this.fillColor,
//     required this.textColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: height,
//       decoration: BoxDecoration(
//         color: fillColor,
//         borderRadius: BorderRadius.circular(radius),
//         border: Border.all(color: borderColor, width: borderWidth),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       alignment: Alignment.centerLeft,
//       child: Row(
//         children: [
//           Text(
//             '$letter. ',
//             style: TextStyle(
//               color: textColor,
//               fontSize: 18,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const SizedBox(width: 2),
//           Expanded(
//             child: TextField(
//               controller: controller,
//               readOnly: readOnly,
//               decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
//               style: TextStyle(
//                 color: textColor,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

/////////////////////////////////////////////////////////////////////////////

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import './PublishEditedQuizPage.dart';
import '../../Theme/Themes.dart';
import './quiz_models.dart' as qm;

class EditQuizQuestionsPage extends StatefulWidget {
  const EditQuizQuestionsPage({super.key});

  @override
  State<EditQuizQuestionsPage> createState() => _EditQuizQuestionsPageState();
}

class _EditQuizQuestionsPageState extends State<EditQuizQuestionsPage> {
  // Layout tokens
  static const double _hPad = 20;
  static const double _radius = 16;
  static const double _fieldH = 56;
  static const double _bigFieldMinH = 120;
  static const double _rowGap = 18;
  static const double _borderW = 1.6;

  String? _quizId;

  // Meta needed for publish handoff
  String _moduleId = 'Unknown';
  String _moduleTitle = 'Module';
  String _quizTitle = '';

  late qm.PublishPreset _preset;

  // Questions
  List<qm.QuizQuestion> _qs = [];
  int _index = 0;

  bool _loading = true;
  bool _saving = false;
  bool _editing = true;

  // Controllers
  final _qC = TextEditingController();
  final _hintC = TextEditingController();
  final _expC = TextEditingController();
  final Map<String, TextEditingController> _optCtrls = {
    'A': TextEditingController(),
    'B': TextEditingController(),
    'C': TextEditingController(),
    'D': TextEditingController(),
  };

  qm.QuizQuestion get _q => _qs[_index];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _quizId ??= args?['quizId']?.toString();
    if (_quizId != null && _loading) {
      _load();
    }
  }

  @override
  void dispose() {
    _qC.dispose();
    _hintC.dispose();
    _expC.dispose();
    for (final c in _optCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ----------------- Load quiz -----------------
  Future<void> _load() async {
    try {
      setState(() => _loading = true);

      final snap = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(_quizId)
          .get();

      if (!snap.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz not found')),
          );
          Navigator.pop(context);
        }
        return;
      }

      final data = snap.data()!;
      _moduleId = (data['moduleId'] ?? 'Unknown').toString();
      _moduleTitle = (data['moduleTitle'] ?? 'Module').toString();
      _quizTitle = (data['quizTitle'] ?? '').toString();

      final preset = Map<String, dynamic>.from(data['preset'] ?? {});
      _preset = qm.PublishPreset(
        difficulty: (preset['difficulty'] ?? 'All').toString(),
        points: (preset['points'] ?? 0) is int
            ? preset['points']
            : int.tryParse('${preset['points']}') ?? 0,
        hints: (preset['hints'] ?? 'Enable').toString(),
        lives: (preset['lives'] ?? 0) is int
            ? preset['lives']
            : int.tryParse('${preset['lives']}') ?? 0,
        questions: (preset['questions'] ?? 0) is int
            ? preset['questions']
            : int.tryParse('${preset['questions']}') ?? 0,
        time: (preset['time'] ?? '10 Min').toString(),
      );

      final rawQs = (data['questions'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _qs = rawQs.map((m) => qm.QuizQuestion.fromMap(m)).toList();
      if (_qs.isEmpty) {
        _qs = [
          qm.QuizQuestion(
            index: 1,
            title: 'Question 1',
            hint: '',
            explanation: '',
            choices: [
              qm.QuizChoice(letter: 'A', text: 'Option A', isCorrect: true),
              qm.QuizChoice(letter: 'B', text: 'Option B', isCorrect: false),
              qm.QuizChoice(letter: 'C', text: 'Option C', isCorrect: false),
              qm.QuizChoice(letter: 'D', text: 'Option D', isCorrect: false),
            ],
          )
        ];
      }

      _index = 0;
      _hydrateControllers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load quiz: $e')),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ----------------- Data <-> UI -----------------
  void _hydrateControllers() {
    _qC.text = _q.title;
    _hintC.text = _q.hint;
    _expC.text = _q.explanation;
    for (final c in _q.choices) {
      _optCtrls[c.letter]?.text = c.text;
    }
    setState(() {});
  }

  qm.QuizQuestion _buildFromControllers(qm.QuizQuestion base) {
    final updatedChoices = base.choices.map((c) {
      final txt = _optCtrls[c.letter]?.text.trim() ?? c.text;
      return qm.QuizChoice(letter: c.letter, text: txt, isCorrect: c.isCorrect);
    }).toList();

    return qm.QuizQuestion(
      index: base.index,
      title: _qC.text.trim(),
      hint: _hintC.text.trim(),
      explanation: _expC.text.trim(),
      choices: updatedChoices,
    );
  }

  void _setCorrectByLetter(String letter) {
    setState(() {
      final base = _buildFromControllers(_q);
      final updated = base.choices
          .map((c) => qm.QuizChoice(
                letter: c.letter,
                text: c.text,
                isCorrect: c.letter == letter,
              ))
          .toList();
      _qs[_index] = qm.QuizQuestion(
        index: base.index,
        title: base.title,
        hint: base.hint,
        explanation: base.explanation,
        choices: updated,
      );
      _hydrateControllers();
    });
  }

  // ----------------- Save current question -----------------
  Future<void> _saveCurrentToFirestore({bool goNext = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      _qs[_index] = _buildFromControllers(_q);

      final payloadQs = _qs.map((q) => q.toMap()).toList();
      final presetMap = {
        'difficulty': _preset.difficulty,
        'points': _preset.points,
        'hints': _preset.hints,
        'lives': _preset.lives,
        'questions': _qs.length,
        'time': _preset.time,
      };

      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(_quizId)
          .update({
        'questions': payloadQs,
        'preset': presetMap,
        'quizTitle': _quizTitle,
      });

      if (!mounted) return;

      if (goNext) {
        if (_index + 1 >= _qs.length) {
          // After last question → go to PublishEditedQuizPage
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const PublishEditedQuizPage(),
              settings: RouteSettings(arguments: {
                'quizId': _quizId,
                'moduleId': _moduleId,
                'moduleTitle': _moduleTitle,
                'quizTitle': _quizTitle,
                'preset': _preset,
                'questions': _qs,
                'attempts': '3',
              }),
            ),
          );
          return;
        }
        setState(() {
          _index++;
          _hydrateControllers();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ----------------- Delete current question -----------------
  Future<void> _deleteThisQuestion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this Question?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    if (confirmed != true) return;

    if (_qs.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz must have at least one question.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      _qs.removeAt(_index);
      // Reindex from 1..n
      for (var i = 0; i < _qs.length; i++) {
        _qs[i] = qm.QuizQuestion(
          index: i + 1,
          title: _qs[i].title,
          hint: _qs[i].hint,
          explanation: _qs[i].explanation,
          choices: _qs[i].choices,
        );
      }
      if (_index >= _qs.length) _index = _qs.length - 1;

      final payloadQs = _qs.map((q) => q.toMap()).toList();
      final presetMap = {
        'difficulty': _preset.difficulty,
        'points': _preset.points,
        'hints': _preset.hints,
        'lives': _preset.lives,
        'questions': _qs.length,
        'time': _preset.time,
      };

      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(_quizId)
          .update({
        'questions': payloadQs,
        'preset': presetMap,
      });

      if (!mounted) return;
      _hydrateControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _prev() {
    if (_index == 0) return;
    setState(() {
      _qs[_index] = _buildFromControllers(_q);
      _index--;
      _hydrateControllers();
    });
  }

  // ----------------- Small UI helpers -----------------
  Widget _chip({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = Theme.of(context).extension<AppColors>()!;

    if (_quizId == null) {
      return const Scaffold(
        body: Center(child: Text('Missing quizId in route arguments')),
      );
    }

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final correct = {for (final c in _q.choices) c.letter: c.isCorrect};

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + trash
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Question ${_index + 1}',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _saving ? null : _deleteThisQuestion,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: app.chipBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline, color: Color(0xFFD1646C)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Question field
              _RoundedFieldShell(
                radius: _radius,
                borderWidth: _borderW,
                borderColor: app.borderStrong,
                minHeight: _fieldH,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: TextField(
                  controller: _qC,
                  readOnly: !_editing,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Edit Question',
                  ),
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: _rowGap),

              // Options A–D
              ...['A', 'B', 'C', 'D'].map((letter) {
                final isCorrect = correct[letter] ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GestureDetector(
                    onDoubleTap: _editing ? () => _setCorrectByLetter(letter) : null,
                    child: _OptionTile(
                      letter: letter,
                      controller: _optCtrls[letter]!,
                      readOnly: !_editing,
                      isCorrect: isCorrect,
                      radius: _radius,
                      height: _fieldH,
                      borderWidth: _borderW,
                      borderColor: isCorrect ? app.correctBorder : app.borderStrong,
                      fillColor: isCorrect ? app.correctFill : app.panelBg,
                      textColor: cs.onSurface,
                    ),
                  ),
                );
              }).toList(),

              // Hints chip
              _chip(
                icon: Icons.lightbulb_outline,
                label: 'Hints',
                bg: app.tagHintsBg,
                fg: app.tagHintsFg,
              ),
              const SizedBox(height: 10),

              // Hint field
              _RoundedFieldShell(
                radius: _radius,
                borderWidth: _borderW,
                borderColor: app.borderStrong,
                minHeight: _bigFieldMinH,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: TextField(
                  controller: _hintC,
                  readOnly: !_editing,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Edit Hint',
                  ),
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: _rowGap),

              // Answer Explanation chip
              _chip(
                icon: Icons.display_settings_outlined,
                label: 'Answer Explanation',
                bg: app.tagPointsBg, // soft green-ish like your mock
                fg: app.tagPointsFg,
              ),
              const SizedBox(height: 10),

              // Explanation field
              _RoundedFieldShell(
                radius: _radius,
                borderWidth: _borderW,
                borderColor: app.borderStrong,
                minHeight: _bigFieldMinH,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: TextField(
                  controller: _expC,
                  readOnly: !_editing,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Edit Explanation',
                  ),
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Primary button (edit/done editing)
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_editing) {
                      _qs[_index] = _buildFromControllers(_q); // keep local
                    }
                    setState(() => _editing = !_editing);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: app.ctaBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: app.ctaBlueBorder, width: 1.4),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  child: Text(_editing ? 'DONE EDITING' : 'EDIT QUESTION'),
                ),
              ),
              const SizedBox(height: 12),

              // Prev / Save & Next
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _index == 0 || _saving ? null : _prev,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Previous Q'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => _saveCurrentToFirestore(goNext: true),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Save & Next Q'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- Shared Widgets -----------------
class _RoundedFieldShell extends StatelessWidget {
  final Widget child;
  final double radius;
  final double borderWidth;
  final Color borderColor;
  final EdgeInsets? padding;
  final double? minHeight;

  const _RoundedFieldShell({
    required this.child,
    required this.radius,
    required this.borderWidth,
    required this.borderColor,
    this.padding,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? _EditQuizQuestionsPageState._fieldH),
      decoration: BoxDecoration(
        color: app.panelBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String letter;
  final TextEditingController controller;
  final bool readOnly;
  final bool isCorrect;
  final double radius;
  final double height;
  final double borderWidth;
  final Color borderColor;
  final Color fillColor;
  final Color textColor;

  const _OptionTile({
    required this.letter,
    required this.controller,
    required this.readOnly,
    required this.isCorrect,
    required this.radius,
    required this.height,
    required this.borderWidth,
    required this.borderColor,
    required this.fillColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            '$letter. ',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
