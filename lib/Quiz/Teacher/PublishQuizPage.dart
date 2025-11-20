// // lib/Quiz/Teacher/PublishQuizPage.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// import '../../Theme/Themes.dart';
// import './quiz_models.dart' as qm;

// class PublishQuizPage extends StatefulWidget {
//   final qm.PublishPreset preset;

//   const PublishQuizPage({
//     super.key,
//     required this.preset,
//   });

//   @override
//   State<PublishQuizPage> createState() => _PublishQuizPageState();
// }

// class _PublishQuizPageState extends State<PublishQuizPage>
//     with SingleTickerProviderStateMixin {
//   // Layout tokens
//   static const double _hPad = 20;
//   static const double _radius = 16;
//   static const double _borderW = 1.6;

//   // Attempts
//   final List<String> _attemptsList = const ['1', '2', '3', '5'];
//   String _attempts = '3';

//   bool _busy = false;

//   // Blinking red dot
//   late final AnimationController _blinkCtrl =
//       AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
//         ..repeat(reverse: true);

//   @override
//   void dispose() {
//     _blinkCtrl.dispose();
//     super.dispose();
//   }

//   // ----------------- Status chip -----------------
//   Widget _statusChip(BuildContext ctx) {
//     final app = Theme.of(ctx).extension<AppColors>()!;
//     final cs = Theme.of(ctx).colorScheme;
//     return Container(
//       height: 36,
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: BoxDecoration(
//         color: app.tagTimerBg, // soft blue like your UI
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'Draft',
//             style: TextStyle(
//               color: cs.onSurface,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const SizedBox(width: 8),
//           FadeTransition(
//             opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_blinkCtrl),
//             child: Container(
//               width: 14,
//               height: 14,
//               decoration: const BoxDecoration(
//                 color: Color(0xFFD1646C), // red
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ----------------- Dashed panel -----------------
//   Widget _dashedPanel({required Widget child}) {
//     final app = Theme.of(context).extension<AppColors>()!;
//     return CustomPaint(
//       painter: _DashedBorderPainter(
//         color: app.borderStrong,
//         strokeWidth: _borderW,
//         dashWidth: 6,
//         dashGap: 5,
//         radius: 18,
//       ),
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
//         child: child,
//       ),
//     );
//   }

//   // ----------------- Row for preset table -----------------
//   Widget _row(BuildContext context, String left, String right) {
//     final cs = Theme.of(context).colorScheme;
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               left,
//               style: TextStyle(
//                 color: cs.onSurface,
//                 fontSize: 20,
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//           ),
//           Text(
//             right,
//             style: TextStyle(
//               color: cs.onSurface,
//               fontSize: 20,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ----------------- Publish -----------------
//   Future<void> _publish() async {
//     if (_busy) return;

//     final args =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

//     final String moduleId = args?['moduleId']?.toString() ?? 'Unknown';
//     final String moduleTitle = args?['moduleTitle']?.toString() ?? 'Untitled';
//     final String quizTitle = args?['quizTitle']?.toString() ?? 'Quiz';
//     final List<qm.QuizQuestion> questions =
//         (args?['questions'] as List<qm.QuizQuestion>? ?? <qm.QuizQuestion>[]);

//     if (questions.isEmpty) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('No questions to publish.'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }

//     setState(() => _busy = true);

//     try {
//       final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

//       // Build preset map
//       final presetMap = {
//         'difficulty': widget.preset.difficulty,
//         'points': widget.preset.points,
//         'hints': widget.preset.hints,
//         'lives': widget.preset.lives,
//         'questions': widget.preset.questions,
//         'time': widget.preset.time,
//       };

//       final payload = <String, dynamic>{
//         'moduleId': moduleId,
//         'moduleTitle': moduleTitle,
//         'quizTitle': quizTitle,
//         'createdBy': uid,
//         'status': 'Published',
//         'attempts': int.tryParse(_attempts) ?? 3,
//         'preset': presetMap,
//         'createdAt': Timestamp.now(),
//         'questions': questions.map((q) {
//           return {
//             'index': q.index,
//             'title': q.title,
//             'hint': q.hint,
//             'explanation': q.explanation,
//             'choices': q.choices.map((c) {
//               return {
//                 'letter': c.letter,
//                 'text': c.text,
//                 'isCorrect': c.isCorrect,
//               };
//             }).toList(),
//           };
//         }).toList(),
//       };

//       await FirebaseFirestore.instance.collection('quizzes').add(payload);

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Quiz saved to Firestore.'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       Navigator.of(context).popUntil((r) => r.isFirst);
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to publish: $e'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _busy = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final app = Theme.of(context).extension<AppColors>()!;

//     final args =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

//     final moduleTitle = args?['moduleTitle']?.toString() ?? 'Module';

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: SafeArea(
//         bottom: false,
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 24),
//           children: [
//             // Title line (no dark header)
//             Text(
//               'Publish Quiz',
//               style: TextStyle(
//                 color: cs.onSurface,
//                 fontSize: 28,
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//             const SizedBox(height: 22),

//             // Status
//             Text(
//               'Status',
//               style: TextStyle(
//                 color: cs.onSurface,
//                 fontSize: 21,
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//             const SizedBox(height: 10),
//             _statusChip(context),

//             const SizedBox(height: 24),

//             // Target Module
//             Text(
//               'Target Module',
//               style: TextStyle(
//                 color: cs.onSurface,
//                 fontSize: 21,
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Container(
//               height: 56,
//               alignment: Alignment.centerLeft,
//               decoration: BoxDecoration(
//                 color: app.panelBg,
//                 borderRadius: BorderRadius.circular(_radius),
//                 border: Border.all(color: app.borderStrong, width: _borderW),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 14),
//               child: Text(
//                 moduleTitle,
//                 style: TextStyle(
//                   color: cs.onSurface,
//                   fontWeight: FontWeight.w700,
//                   fontSize: 18,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 24),

//             // Preset dashed panel
//             _dashedPanel(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Preset',
//                     style: TextStyle(
//                       color: cs.onSurface,
//                       fontSize: 21,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   _row(context, 'Difficulty', widget.preset.difficulty),
//                   _row(context, 'Points', widget.preset.points.toString()),
//                   _row(context, 'Hints', widget.preset.hints),
//                   _row(context, 'Lives', widget.preset.lives.toString()),
//                   _row(context, 'Questions', widget.preset.questions.toString()),
//                   _row(context, 'Time', widget.preset.time),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 24),

//             // Attempts
//             Text(
//               'Attempts',
//               style: TextStyle(
//                 color: cs.onSurface,
//                 fontSize: 28,
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Container(
//               height: 56,
//               decoration: BoxDecoration(
//                 color: app.panelBg,
//                 borderRadius: BorderRadius.circular(_radius),
//                 border: Border.all(color: app.borderStrong, width: _borderW),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 14),
//               child: DropdownButton<String>(
//                 isExpanded: true,
//                 value: _attempts,
//                 underline: const SizedBox.shrink(),
//                 borderRadius: BorderRadius.circular(14),
//                 items: _attemptsList
//                     .map((a) => DropdownMenuItem<String>(
//                           value: a,
//                           child: Text(
//                             a,
//                             style: TextStyle(
//                               color: cs.onSurface,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ))
//                     .toList(),
//                 onChanged: (v) => setState(() => _attempts = v ?? _attempts),
//               ),
//             ),

//             const SizedBox(height: 26),

//             // Publish button
//             SizedBox(
//               height: 56,
//               child: ElevatedButton(
//                 onPressed: _busy ? null : _publish,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: app.ctaBlue,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(18),
//                     side: BorderSide(color: app.ctaBlueBorder, width: 1.6),
//                   ),
//                   textStyle: const TextStyle(
//                     fontWeight: FontWeight.w800,
//                     fontSize: 18,
//                   ),
//                 ),
//                 child: _busy
//                     ? const SizedBox(
//                         width: 22,
//                         height: 22,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2.6,
//                           valueColor:
//                               AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                       )
//                     : const Text('PUBLISH'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ================= Dashed Border Painter =================
// class _DashedBorderPainter extends CustomPainter {
//   final Color color;
//   final double strokeWidth;
//   final double dashWidth;
//   final double dashGap;
//   final double radius;

//   _DashedBorderPainter({
//     required this.color,
//     required this.strokeWidth,
//     required this.dashWidth,
//     required this.dashGap,
//     this.radius = 0,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final rrect = RRect.fromRectAndRadius(
//       Offset.zero & size,
//       Radius.circular(radius),
//     );

//     final path = Path()..addRRect(rrect);
//     final paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth;

//     final dashPath = _createDashedPath(path, dashWidth, dashGap);
//     canvas.drawPath(dashPath, paint);
//   }

//   Path _createDashedPath(Path source, double dashWidth, double dashGap) {
//     final dest = Path();
//     for (final metric in source.computeMetrics()) {
//       double distance = 0.0;
//       while (distance < metric.length) {
//         final len = dashWidth;
//         dest.addPath(
//           metric.extractPath(distance, distance + len),
//           Offset.zero,
//         );
//         distance += dashWidth + dashGap;
//       }
//     }
//     return dest;
//   }

//   @override
//   bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
//     return oldDelegate.color != color ||
//         oldDelegate.strokeWidth != strokeWidth ||
//         oldDelegate.dashWidth != dashWidth ||
//         oldDelegate.dashGap != dashGap ||
//         oldDelegate.radius != radius;
//   }
// }

//////////////////////////////////////////////////////////////////////////////////////

// lib/Quiz/Teacher/PublishQuizPage.dart
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Theme/Themes.dart';
import './quiz_models.dart' as qm;

class PublishQuizPage extends StatefulWidget {
  final qm.PublishPreset preset;

  const PublishQuizPage({
    super.key,
    required this.preset,
  });

  @override
  State<PublishQuizPage> createState() => _PublishQuizPageState();
}

class _PublishQuizPageState extends State<PublishQuizPage>
    with SingleTickerProviderStateMixin {
  // layout tokens
  static const double _pad = 20;
  static const double _radius = 16;
  static const double _borderW = 1.6;
  static const double _fieldH = 56;

  // attempts dropdown values
  final List<String> _attemptsList = const ['1', '2', '3', '5'];
  String _attempts = '3';

  bool _busy = false;

  // blink for status dot
  late final AnimationController _blinkCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  // ------------- small tag chip (icon + label, colored) -------------
  Widget _tag({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
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

  // ------------- rounded, read-only value box -------------
  Widget _valueBox(String text, {TextAlign align = TextAlign.left}) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: _fieldH,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: app.panelBg,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: app.borderStrong, width: _borderW),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ------------- status pill on right (“Publish ●” blinking) -------------
  Widget _statusPill() {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: _fieldH,
      decoration: BoxDecoration(
        color: app.panelBg,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: app.borderStrong, width: _borderW),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Publish',
              style: TextStyle(
                  color: cs.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
          FadeTransition(
            opacity: Tween<double>(begin: .35, end: 1).animate(_blinkCtrl),
            child: Container(
              width: 14,
              height: 14,
              decoration:
                  const BoxDecoration(color: Color(0xFFD1646C), shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }

  // ------------- publish to Firestore (unchanged backend) -------------
  Future<void> _publish() async {
    if (_busy) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String moduleId = args?['moduleId']?.toString() ?? 'Unknown';
    final String moduleTitle = args?['moduleTitle']?.toString() ?? 'Untitled';
    final String quizTitle = args?['quizTitle']?.toString() ?? 'Quiz';
    final List<qm.QuizQuestion> questions =
        (args?['questions'] as List<qm.QuizQuestion>? ?? <qm.QuizQuestion>[]);

    if (questions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions to publish.')),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      final presetMap = {
        'difficulty': widget.preset.difficulty,
        'points': widget.preset.points,
        'hints': widget.preset.hints,
        'lives': widget.preset.lives,
        'questions': widget.preset.questions,
        'time': widget.preset.time,
      };

      final payload = <String, dynamic>{
        'moduleId': moduleId,
        'moduleTitle': moduleTitle,
        'quizTitle': quizTitle,
        'createdBy': uid,
        'status': 'Published',
        'attempts': int.tryParse(_attempts) ?? 3,
        'preset': presetMap,
        'createdAt': Timestamp.now(),
        'questions': questions.map((q) {
          return {
            'index': q.index,
            'title': q.title,
            'hint': q.hint,
            'explanation': q.explanation,
            'choices': q.choices
                .map((c) =>
                    {'letter': c.letter, 'text': c.text, 'isCorrect': c.isCorrect})
                .toList(),
          };
        }).toList(),
      };

      await FirebaseFirestore.instance.collection('quizzes').add(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz saved to Firestore.')),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = Theme.of(context).extension<AppColors>()!;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final quizTitle = args?['quizTitle']?.toString() ?? 'Quiz Title';
    final moduleTitle = args?['moduleTitle']?.toString() ?? 'Target Module';

    // color tokens to match your screenshot
    const _roseBg = Color(0xFFE7C0CF);
    const _roseFg = Color(0xFF7C2D40);

    const _lavBg = Color(0xFFE2D3FF);
    const _lavFg = Color(0xFF5E41B2);

    const _redTagBg = Color(0xFFF6C7CB);
    const _redTagFg = Color(0xFF7C2830);

    const _tealTagBg = Color(0xFFCBE6EA);
    const _tealTagFg = Color(0xFF205D67);

    const _yellowBg = Color(0xFFF7E2A7);
    const _yellowFg = Color(0xFF6B4F00);

    const _greenBg = Color(0xFFCDEFD9);
    const _greenFg = Color(0xFF1F6B3A);

    const _orangeBg = Color(0xFFF8D1A6);
    const _orangeFg = Color(0xFF7A3F06);

    const _pinkBg = Color(0xFFF7C8CF);
    const _pinkFg = Color(0xFF7C2440);

    const _blueBg = Color(0xFFCCE1F7);
    const _blueFg = Color(0xFF1C4F7A);

    const _greyBg = Color(0xFFD9D9D9);
    const _greyFg = Color(0xFF333333);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(_pad, 16, _pad, 24),
          children: [
            // top title under dark area (like your design)
            Text(
              'Publish  Quiz',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),

            // Quiz Title
            _tag(icon: Icons.event_note_outlined, label: 'Quiz Title', bg: _roseBg, fg: _roseFg),
            const SizedBox(height: 10),
            _valueBox(quizTitle),

            const SizedBox(height: 18),

            // Target Module
            _tag(icon: Icons.fact_check_outlined, label: 'Target Module', bg: _lavBg, fg: _lavFg),
            const SizedBox(height: 10),
            _valueBox(moduleTitle),

            const SizedBox(height: 22),

            // Attempts + Status row (two columns)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tag(icon: Icons.add_box_outlined, label: 'Attempts', bg: _redTagBg, fg: _redTagFg),
                      const SizedBox(height: 10),
                      Container(
                        height: _fieldH,
                        decoration: BoxDecoration(
                          color: app.panelBg,
                          borderRadius: BorderRadius.circular(_radius),
                          border: Border.all(color: app.borderStrong, width: _borderW),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _attempts,
                          underline: const SizedBox.shrink(),
                          borderRadius: BorderRadius.circular(14),
                          items: _attemptsList
                              .map((a) => DropdownMenuItem<String>(
                                    value: a,
                                    child: Text(
                                      a,
                                      style: TextStyle(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _attempts = v ?? _attempts),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tag(icon: Icons.local_offer_outlined, label: 'Status', bg: _tealTagBg, fg: _tealTagFg),
                      const SizedBox(height: 10),
                      _statusPill(),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Difficulty + Points
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tag(icon: Icons.local_fire_department, label: 'Difficulty', bg: _yellowBg, fg: _yellowFg),
                      const SizedBox(height: 10),
                      _valueBox(widget.preset.difficulty),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tag(icon: Icons.bolt, label: 'Points', bg: _greenBg, fg: _greenFg),
                      const SizedBox(height: 10),
                      _valueBox(widget.preset.points.toString(), align: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Hints + Lives
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tag(icon: Icons.lightbulb_outline, label: 'Hints', bg: _orangeBg, fg: _orangeFg),
                      const SizedBox(height: 10),
                      _valueBox(widget.preset.hints),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tag(icon: Icons.favorite_border, label: 'Lives', bg: _pinkBg, fg: _pinkFg),
                      const SizedBox(height: 10),
                      _valueBox(widget.preset.lives.toString(), align: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Timer + Questions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tag(icon: Icons.schedule_outlined, label: 'Timer', bg: _blueBg, fg: _blueFg),
                      const SizedBox(height: 10),
                      _valueBox(widget.preset.time),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tag(icon: Icons.priority_high_rounded, label: 'Questions', bg: _greyBg, fg: _greyFg),
                      const SizedBox(height: 10),
                      _valueBox(widget.preset.questions.toString(), align: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            // Publish button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _busy ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: app.ctaBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: app.ctaBlueBorder, width: 1.6),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Publish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
