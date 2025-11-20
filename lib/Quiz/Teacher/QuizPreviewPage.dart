// // lib/Quiz/Teacher/QuizPreviewPage.dart
// import 'package:flutter/material.dart';

// import '../../Theme/Themes.dart';
// import './PublishQuizPage.dart';
// import './quiz_models.dart' as qm;

// class QuizPreviewPage extends StatefulWidget {
//   final List<qm.QuizQuestion> questions; // from CreateQuiz
//   final qm.PublishPreset preset;
//   final int initialIndex;

//   const QuizPreviewPage({
//     super.key,
//     required this.questions,
//     required this.preset,
//     this.initialIndex = 0,
//   });

//   @override
//   State<QuizPreviewPage> createState() => _QuizPreviewPageState();
// }

// class _QuizPreviewPageState extends State<QuizPreviewPage> {
//   // layout
//   static const double _pageHPad = 20;
//   static const double _panelTopRadius = 28;
//   static const double _radius = 16;
//   static const double _fieldH = 56;
//   static const double _bigFieldMinH = 120;
//   static const double _rowGap = 18;
//   static const double _borderW = 1.6;
//   static const double _overlap = 18.0;

//   late List<qm.QuizQuestion> _qs;
//   late int _index;
//   bool _editing = true;

//   // controllers for active question
//   final _qC = TextEditingController();
//   final _hintC = TextEditingController();
//   final _expC = TextEditingController();
//   final Map<String, TextEditingController> _optCtrls = {}; // A..D

//   qm.QuizQuestion get _q => _qs[_index];

//   @override
//   void initState() {
//     super.initState();
//     _qs = List<qm.QuizQuestion>.from(widget.questions);
//     _index = widget.initialIndex.clamp(0, _qs.length - 1);
//     _hydrateControllers();
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

//   // ========= header (dark bar only; no back button) =========
//   Widget _buildHeader(BuildContext context) {
//     final app = Theme.of(context).extension<AppColors>()!;
//     final topPad = MediaQuery.of(context).padding.top;
//     return Container(
//       color: app.headerBg, // full-bleed dark header
//       padding: EdgeInsets.fromLTRB(_pageHPad, topPad + 14, _pageHPad, 18),
//     );
//   }

//   // ========= data <-> UI =========
//   void _hydrateControllers() {
//     _qC.text = _q.title;
//     _hintC.text = _q.hint;
//     _expC.text = _q.explanation;

//     _optCtrls.clear();
//     for (final c in _q.choices) {
//       _optCtrls[c.letter] = TextEditingController(text: c.text);
//     }
//     setState(() {}); // refresh UI when switching questions
//   }

//   qm.QuizQuestion _buildFromControllers(qm.QuizQuestion base) {
//     final updatedChoices = base.choices.map((c) {
//       final newText = _optCtrls[c.letter]?.text.trim() ?? c.text;
//       return qm.QuizChoice(letter: c.letter, text: newText, isCorrect: c.isCorrect);
//     }).toList();

//     return qm.QuizQuestion(
//       index: base.index,
//       title: _qC.text.trim(),
//       hint: _hintC.text.trim(),
//       explanation: _expC.text.trim(),
//       choices: updatedChoices,
//     );
//   }

//   void _persistBackToModel() {
//     setState(() => _qs[_index] = _buildFromControllers(_q));
//   }

//   void _setCorrectByLetter(String letter) {
//     setState(() {
//       final base = _buildFromControllers(_q);
//       final updatedChoices = base.choices
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
//         choices: updatedChoices,
//       );
//       _hydrateControllers();
//     });
//   }

//   void _nextOrPublish() {
//     _persistBackToModel();

//     // pull args (carried from CreateQuiz)
//     final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

//     final moduleId = args?['moduleId'] ?? 'Unknown';
//     final moduleTitle = args?['moduleTitle'] ?? 'Untitled Module';
//     final quizTitle = args?['quizTitle'] ?? '';

//     if (_index + 1 < _qs.length) {
//       setState(() {
//         _index++;
//         _hydrateControllers();
//       });
//     } else {
//       // Forward everything to Publish page (it performs the Firestore save)
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => PublishQuizPage(preset: widget.preset),
//           settings: RouteSettings(arguments: {
//             'moduleId': moduleId,
//             'moduleTitle': moduleTitle,
//             'quizTitle': quizTitle,
//             'questions': _qs, // full, edited list
//           }),
//         ),
//       );
//     }
//   }

//   void _prev() {
//     _persistBackToModel();
//     if (_index > 0) {
//       setState(() {
//         _index--;
//         _hydrateControllers();
//       });
//     }
//   }

//   // ========= build =========
//   @override
//   Widget build(BuildContext context) {
//     final app = Theme.of(context).extension<AppColors>()!;
//     final cs = Theme.of(context).colorScheme;

//     final topPad = MediaQuery.of(context).padding.top;
//     final headerHeight = topPad + 86;

//     final correctMap = {for (final c in _q.choices) c.letter: c.isCorrect};

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: Stack(
//         children: [
//           _buildHeader(context),

//           // Rounded white panel under the dark header
//           Positioned.fill(
//             top: headerHeight - _overlap,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: app.panelBg,
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(_panelTopRadius),
//                 ),
//               ),
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(_pageHPad, 24, _pageHPad, 24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Page title inside white panel (no back button)
//                     Text(
//                       'Question ${_index + 1}',
//                       style: TextStyle(
//                         color: cs.onSurface,
//                         fontSize: 26,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     const SizedBox(height: 10),

//                     // Question text field
//                     _RoundedFieldShell(
//                       radius: _radius,
//                       borderWidth: _borderW,
//                       borderColor: app.borderStrong,
//                       minHeight: _fieldH,
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                       child: TextField(
//                         controller: _qC,
//                         readOnly: !_editing,
//                         minLines: 1,
//                         maxLines: 4,
//                         decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
//                         style: TextStyle(
//                           color: cs.onSurface,
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: _rowGap),

//                     // Options A–D
//                     ..._q.choices.map((c) {
//                       final ctrl = _optCtrls[c.letter]!;
//                       final isCorrect = correctMap[c.letter] ?? false;
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 14),
//                         child: GestureDetector(
//                           onDoubleTap: _editing ? () => _setCorrectByLetter(c.letter) : null,
//                           child: _OptionTile(
//                             letter: c.letter,
//                             controller: ctrl,
//                             readOnly: !_editing,
//                             isCorrect: isCorrect,
//                             radius: _radius,
//                             height: _fieldH,
//                             borderWidth: _borderW,
//                             borderColor: isCorrect ? app.correctBorder : app.borderStrong,
//                             fillColor: isCorrect ? app.correctFill : app.panelBg,
//                             textColor: cs.onSurface,
//                           ),
//                         ),
//                       );
//                     }).toList(),

//                     // Edit / Save & Next
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _BigButton(
//                             label: _editing ? 'DONE EDITING' : 'EDIT QUESTION',
//                             fg: cs.onSurface,
//                             bg: app.chipBg,
//                             border: app.border,
//                             onTap: () {
//                               if (_editing) _persistBackToModel();
//                               setState(() => _editing = !_editing);
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 14),
//                         Expanded(
//                           child: _BigButton(
//                             label: 'SAVE & NEXT Q',
//                             fg: Colors.white,
//                             bg: app.ctaBlue,
//                             border: app.ctaBlueBorder,
//                             onTap: _nextOrPublish,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: _rowGap),

//                     // Hint
//                     Text(
//                       'Hint',
//                       style: TextStyle(
//                         color: cs.onSurface,
//                         fontSize: 22,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     _RoundedFieldShell(
//                       radius: _radius,
//                       borderWidth: _borderW,
//                       borderColor: app.borderStrong,
//                       minHeight: _bigFieldMinH,
//                       padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
//                       child: TextField(
//                         controller: _hintC,
//                         readOnly: !_editing,
//                         minLines: 3,
//                         maxLines: 6,
//                         decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
//                         style: TextStyle(
//                           color: cs.onSurface,
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                           height: 1.35,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: _rowGap),

//                     // Answer Explanation
//                     Text(
//                       'Answer Explanation',
//                       style: TextStyle(
//                         color: cs.onSurface,
//                         fontSize: 22,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     _RoundedFieldShell(
//                       radius: _radius,
//                       borderWidth: _borderW,
//                       borderColor: app.borderStrong,
//                       minHeight: _bigFieldMinH,
//                       padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
//                       child: TextField(
//                         controller: _expC,
//                         readOnly: !_editing,
//                         minLines: 4,
//                         maxLines: 8,
//                         decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
//                         style: TextStyle(
//                           color: cs.onSurface,
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                           height: 1.35,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 14),

//                     // Prev / Next (disabled when at ends)
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: _index == 0 ? null : _prev,
//                             style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
//                             child: const Text('Previous Q'),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: _index + 1 == _qs.length
//                                 ? null
//                                 : () {
//                                     _persistBackToModel();
//                                     setState(() {
//                                       _index++;
//                                       _hydrateControllers();
//                                     });
//                                   },
//                             style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
//                             child: const Text('Next'),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Double-tap an option to set it as the correct answer.',
//                       style: TextStyle(
//                         color: cs.onSurface.withOpacity(.6),
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // =================== helpers ===================

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
//       constraints: BoxConstraints(minHeight: minHeight ?? _QuizPreviewPageState._fieldH),
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
//               decoration: const InputDecoration(
//                 isCollapsed: true,
//                 border: InputBorder.none,
//               ),
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

// class _BigButton extends StatelessWidget {
//   final String label;
//   final Color bg;
//   final Color fg;
//   final Color border;
//   final VoidCallback? onTap;

//   const _BigButton({
//     required this.label,
//     required this.bg,
//     required this.fg,
//     required this.border,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 50,
//       child: ElevatedButton(
//         onPressed: onTap,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: bg,
//           foregroundColor: fg,
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//             side: BorderSide(color: border, width: 1.4),
//           ),
//           textStyle: const TextStyle(
//             fontWeight: FontWeight.w800,
//             fontSize: 16,
//           ),
//         ),
//         child: Text(label),
//       ),
//     );
//   }
// }


/////////////////////////////////////////////////////////////////////////////////


// lib/Quiz/Teacher/QuizPreviewPage.dart
import 'package:flutter/material.dart';

import '../../Theme/Themes.dart';
import './PublishQuizPage.dart';
import './quiz_models.dart' as qm;

class QuizPreviewPage extends StatefulWidget {
  final List<qm.QuizQuestion> questions; // from CreateQuiz
  final qm.PublishPreset preset;
  final int initialIndex;

  const QuizPreviewPage({
    super.key,
    required this.questions,
    required this.preset,
    this.initialIndex = 0,
  });

  @override
  State<QuizPreviewPage> createState() => _QuizPreviewPageState();
}

class _QuizPreviewPageState extends State<QuizPreviewPage> {
  // layout
  static const double _pageHPad = 20;
  static const double _panelTopRadius = 28;
  static const double _radius = 16;
  static const double _fieldH = 56;
  static const double _bigFieldMinH = 120;
  static const double _rowGap = 18;
  static const double _borderW = 1.6;
  static const double _overlap = 18.0;

  late List<qm.QuizQuestion> _qs;
  late int _index;
  bool _editing = false; // start like your screenshot: “EDIT QUESTION” shown first

  // controllers for active question
  final _qC = TextEditingController();
  final _hintC = TextEditingController();
  final _expC = TextEditingController();
  final Map<String, TextEditingController> _optCtrls = {}; // A..D

  qm.QuizQuestion get _q => _qs[_index];

  @override
  void initState() {
    super.initState();
    _qs = List<qm.QuizQuestion>.from(widget.questions);
    _index = widget.initialIndex.clamp(0, _qs.length - 1);
    _hydrateControllers();
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

  // ========= header (dark bar only; no back button/title) =========
  Widget _buildHeader(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: app.headerBg, // full-bleed dark header
      padding: EdgeInsets.fromLTRB(_pageHPad, topPad + 14, _pageHPad, 18),
    );
  }

  // ========= data <-> UI =========
  void _hydrateControllers() {
    _qC.text = _q.title;
    _hintC.text = _q.hint;
    _expC.text = _q.explanation;

    _optCtrls.clear();
    for (final c in _q.choices) {
      _optCtrls[c.letter] = TextEditingController(text: c.text);
    }
    setState(() {}); // refresh UI when switching questions
  }

  qm.QuizQuestion _buildFromControllers(qm.QuizQuestion base) {
    final updatedChoices = base.choices.map((c) {
      final newText = _optCtrls[c.letter]?.text.trim() ?? c.text;
      return qm.QuizChoice(letter: c.letter, text: newText, isCorrect: c.isCorrect);
    }).toList();

    return qm.QuizQuestion(
      index: base.index,
      title: _qC.text.trim(),
      hint: _hintC.text.trim(),
      explanation: _expC.text.trim(),
      choices: updatedChoices,
    );
  }

  void _persistBackToModel() {
    setState(() => _qs[_index] = _buildFromControllers(_q));
  }

  void _setCorrectByLetter(String letter) {
    setState(() {
      final base = _buildFromControllers(_q);
      final updatedChoices = base.choices
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
        choices: updatedChoices,
      );
      _hydrateControllers();
    });
  }

  void _nextOrPublish() {
    _persistBackToModel();

    // carry context from CreateQuiz → Preview → Publish
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final moduleId = args?['moduleId'] ?? 'Unknown';
    final moduleTitle = args?['moduleTitle'] ?? 'Untitled Module';
    final quizTitle = args?['quizTitle'] ?? '';

    if (_index + 1 < _qs.length) {
      setState(() {
        _index++;
        _hydrateControllers();
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PublishQuizPage(preset: widget.preset),
          settings: RouteSettings(arguments: {
            'moduleId': moduleId,
            'moduleTitle': moduleTitle,
            'quizTitle': quizTitle,
            'questions': _qs, // full, edited list
          }),
        ),
      );
    }
  }

  void _prev() {
    _persistBackToModel();
    if (_index > 0) {
      setState(() {
        _index--;
        _hydrateControllers();
      });
    }
  }

  // ========= build =========
  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;

    final topPad = MediaQuery.of(context).padding.top;
    final headerHeight = topPad + 86;

    final correctMap = {for (final c in _q.choices) c.letter: c.isCorrect};

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildHeader(context),

          // Rounded white panel under the dark header
          Positioned.fill(
            top: headerHeight - _overlap,
            child: Container(
              decoration: BoxDecoration(
                color: app.panelBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_panelTopRadius),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(_pageHPad, 24, _pageHPad, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page title inside white panel (no back button)
                    Text(
                      'Question ${_index + 1}',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
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
                        decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: _rowGap),

                    // Options A–D
                    ..._q.choices.map((c) {
                      final ctrl = _optCtrls[c.letter]!;
                      final isCorrect = correctMap[c.letter] ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: GestureDetector(
                          onDoubleTap: _editing ? () => _setCorrectByLetter(c.letter) : null,
                          child: _OptionTile(
                            letter: c.letter,
                            controller: ctrl,
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

                    // BIG BLUE “EDIT QUESTION” button (full width)
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_editing) _persistBackToModel();
                          setState(() => _editing = !_editing);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: app.ctaBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: app.ctaBlueBorder, width: 1.6),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        child: Text(_editing ? 'DONE EDITING' : 'EDIT QUESTION'),
                      ),
                    ),
                    const SizedBox(height: _rowGap),

                    // Orange Hints tag
                    _Tag(icon: Icons.lightbulb_outline, label: 'Hints', bg: app.tagHintsBg, fg: app.tagHintsFg),
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
                        decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: _rowGap),

                    // Green Answer Explanation tag
                    _Tag(icon: Icons.school_outlined, label: 'Answer Explanation', bg: app.tagPointsBg, fg: app.tagPointsFg),
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
                        decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Prev / Save & Next row (smaller buttons)
                    Row(
                      children: [
                        Expanded(
                          child: _GrayButton(
                            label: 'Previous Q',
                            onPressed: _index == 0 ? null : _prev,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _BlueButton(
                            label: 'Save & Next Q',
                            onPressed: _nextOrPublish,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Double-tap an option to set it as the correct answer.',
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =================== helpers ===================

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  const _Tag({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

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
      constraints: BoxConstraints(minHeight: minHeight ?? _QuizPreviewPageState._fieldH),
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

// Small gray button like your screenshot
class _GrayButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _GrayButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: app.chipBg,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: app.border, width: 1.4),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        child: Text(label),
      ),
    );
  }
}

// Small blue button like your screenshot
class _BlueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _BlueButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
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
        child: Text(label),
      ),
    );
  }
}
