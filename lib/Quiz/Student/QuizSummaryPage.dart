// // lib/Quiz/Student/QuizSummaryPage.dart
// import 'dart:math' as math;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:confetti/confetti.dart';
// import 'package:flutter/material.dart';

// import '../../Theme/Themes.dart';
// import './QuizExplanationsPage.dart';

// class QuizSummaryPage extends StatefulWidget {
//   const QuizSummaryPage({super.key});

//   @override
//   State<QuizSummaryPage> createState() => _QuizSummaryPageState();
// }

// class _QuizSummaryPageState extends State<QuizSummaryPage>
//     with SingleTickerProviderStateMixin {
//   String _quizId = '';
//   String _runId = '';

//   late Future<DocumentSnapshot<Map<String, dynamic>>> _future;

//   // Confetti + reactions
//   late final ConfettiController _winCtrl;  // colorful burst for >=60%
//   late final ConfettiController _failCtrl; // grey drizzle for <60%
//   late final AnimationController _shakeCtrl;
//   late final Animation<double> _shakeT;

//   @override
//   void initState() {
//     super.initState();
//     _winCtrl = ConfettiController(duration: const Duration(seconds: 1));
//     _failCtrl = ConfettiController(duration: const Duration(milliseconds: 900));
//     _shakeCtrl =
//         AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
//     _shakeT = CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut);
//   }

//   @override
//   void dispose() {
//     _winCtrl.dispose();
//     _failCtrl.dispose();
//     _shakeCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final args =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

//     _quizId = args?['quizId']?.toString() ?? '';
//     _runId = args?['runId']?.toString() ?? '';

//     _future = FirebaseFirestore.instance
//         .collection('quiz_runs')
//         .doc(_runId)
//         .get();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final app = Theme.of(context).extension<AppColors>()!;

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: SafeArea(
//         child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//           future: _future,
//           builder: (context, snap) {
//             if (snap.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }
//             if (!snap.hasData || !(snap.data?.exists ?? false)) {
//               return const Center(child: Text('Summary not found.'));
//             }

//             final data = snap.data!.data()!;
//             final correct = (data['correctCount'] ?? 0) as int;
//             final wrong = (data['wrongCount'] ?? 0) as int;
//             final total = (correct + wrong).clamp(1, 999);
//             final accuracy = total == 0 ? 0 : ((correct / total) * 100).round();

//             // Trigger the right animation once per build with data
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               final pass = correct >= (total * 0.6).ceil();
//               if (pass) {
//                 if (_winCtrl.state != ConfettiControllerState.playing) {
//                   _winCtrl.play();
//                 }
//               } else {
//                 if (_failCtrl.state != ConfettiControllerState.playing) {
//                   _failCtrl.play();
//                 }
//                 if (!_shakeCtrl.isAnimating) {
//                   _shakeCtrl
//                     ..reset()
//                     ..forward();
//                 }
//               }
//             });

//             return Stack(
//               children: [
//                 // Content
//                 ListView(
//                   padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
//                   children: [
//                     // Shake the title + ring group only when failing
//                     AnimatedBuilder(
//                       animation: _shakeT,
//                       builder: (context, child) {
//                         final phase = _shakeT.value * 2 * math.pi;
//                         final dx = math.sin(phase) * 8.0 * (1.0 - _shakeT.value);
//                         return Transform.translate(
//                           offset: Offset(dx, 0),
//                           child: child,
//                         );
//                       },
//                       child: Column(
//                         children: [
//                           const SizedBox(height: 12),
//                           Text(
//                             'Quiz\nCompleted',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: cs.onSurface,
//                               fontSize: 40,
//                               height: 1.05,
//                               fontWeight: FontWeight.w900,
//                             ),
//                           ),
//                           const SizedBox(height: 28),
//                           _ScoreRing(
//                             valueText: '$correct/$total',
//                             ringColor: const Color(0xFFFFD43B),
//                           ),
//                           const SizedBox(height: 28),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 correct >= (total * 0.6).ceil()
//                                     ? 'Great Job'
//                                     : 'Keep Trying',
//                                 style: TextStyle(
//                                   color: cs.onSurface,
//                                   fontSize: 32,
//                                   fontWeight: FontWeight.w800,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Icon(
//                                 correct >= (total * 0.6).ceil()
//                                     ? Icons.emoji_events
//                                     : Icons.sentiment_dissatisfied_rounded,
//                                 size: 34,
//                                 color: cs.onSurface,
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 24),

//                     // Stats card (light grey)
//                     Container(
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFD9D9D9),
//                         borderRadius: BorderRadius.circular(24),
//                       ),
//                       padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
//                       child: DefaultTextStyle(
//                         style: TextStyle(
//                           color: Colors.black87,
//                           fontSize: 24,
//                           fontWeight: FontWeight.w700,
//                         ),
//                         child: Column(
//                           children: [
//                             _row('Correct', '$correct'),
//                             const SizedBox(height: 18),
//                             _row('Incorrect', '$wrong'),
//                             const SizedBox(height: 18),
//                             _row('Accuracy', '$accuracy%'),
//                             const SizedBox(height: 18),
//                             _row('Difficulty Bonus', '+200xp'), // cosmetic
//                           ],
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 28),

//                     // Continue button (solid blue)
//                     SizedBox(
//                       height: 56,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const QuizExplanationsPage(),
//                               settings: RouteSettings(
//                                 arguments: {'quizId': _quizId, 'runId': _runId},
//                               ),
//                             ),
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: app.ctaBlue,
//                           foregroundColor: Colors.white,
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                           textStyle: const TextStyle(
//                             fontWeight: FontWeight.w900,
//                             fontSize: 18,
//                             letterSpacing: 0.4,
//                           ),
//                         ),
//                         child: const Text('CONTINUE'),
//                       ),
//                     ),
//                   ],
//                 ),

//                 // WIN: colorful burst from the ring center
//                 Align(
//                   alignment: Alignment(0, -0.12),
//                   child: ConfettiWidget(
//                     confettiController: _winCtrl,
//                     blastDirectionality: BlastDirectionality.explosive,
//                     numberOfParticles: 22,
//                     maxBlastForce: 20,
//                     minBlastForce: 8,
//                     gravity: 0.9,
//                     colors: const [
//                       Color(0xFFFFC53D),
//                       Color(0xFF69DB7C),
//                       Color(0xFF74C0FC),
//                       Color(0xFFF06595),
//                     ],
//                   ),
//                 ),

//                 // FAIL: dull downward drizzle from top-center
//                 Align(
//                   alignment: Alignment.topCenter,
//                   child: ConfettiWidget(
//                     confettiController: _failCtrl,
//                     blastDirection: math.pi / 2, // straight down
//                     blastDirectionality: BlastDirectionality.directional,
//                     emissionFrequency: 0.0, // single burst
//                     numberOfParticles: 18,
//                     maxBlastForce: 10,
//                     minBlastForce: 4,
//                     gravity: 1.0,
//                     colors: const [
//                       Color(0xFF9E9E9E),
//                       Color(0xFFBDBDBD),
//                       Color(0xFF757575),
//                     ],
//                     createParticlePath: (size) {
//                       // tiny rounded rectangles → not festive
//                       final path = Path()
//                         ..addRRect(RRect.fromRectAndRadius(
//                           Rect.fromLTWH(0, 0, 6, 12),
//                           const Radius.circular(2),
//                         ));
//                       return path;
//                     },
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _row(String left, String right) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(left),
//         Text(right),
//       ],
//     );
//   }
// }

// /// Yellow stroked ring with big center text (e.g., "7/10")
// class _ScoreRing extends StatelessWidget {
//   final String valueText;
//   final Color ringColor;
//   const _ScoreRing({
//     required this.valueText,
//     required this.ringColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 240,
//       height: 240,
//       child: CustomPaint(
//         painter: _RingPainter(color: ringColor, stroke: 18),
//         child: Center(
//           child: Text(
//             valueText,
//             style: const TextStyle(
//               fontSize: 56,
//               fontWeight: FontWeight.w900,
//               letterSpacing: 1.0,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _RingPainter extends CustomPainter {
//   final Color color;
//   final double stroke;
//   _RingPainter({required this.color, required this.stroke});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final r = math.min(size.width, size.height) / 2 - stroke / 2;
//     final center = Offset(size.width / 2, size.height / 2);
//     final paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = stroke
//       ..strokeCap = StrokeCap.round;

//     // Simple full ring (no progress)
//     canvas.drawCircle(center, r, paint);
//   }

//   @override
//   bool shouldRepaint(covariant _RingPainter oldDelegate) {
//     return oldDelegate.color != color || oldDelegate.stroke != stroke;
//     }
// }

//////////////////////////////////////////////////////////////////////////////////////////

// lib/Quiz/Student/QuizSummaryPage.dart
// import 'dart:math' as math;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:confetti/confetti.dart';
// import 'package:flutter/material.dart';

// import '../../Theme/Themes.dart';
// import './QuizExplanationsPage.dart';

// class QuizSummaryPage extends StatefulWidget {
//   const QuizSummaryPage({super.key});

//   @override
//   State<QuizSummaryPage> createState() => _QuizSummaryPageState();
// }

// class _QuizSummaryPageState extends State<QuizSummaryPage>
//     with SingleTickerProviderStateMixin {
//   String _quizId = '';
//   String _runId = '';
//   late Future<DocumentSnapshot<Map<String, dynamic>>> _future;

//   // Animations
//   late final ConfettiController _winCtrl;  // colorful win
//   late final ConfettiController _failCtrl; // grey drizzle
//   late final AnimationController _shakeCtrl;
//   late final Animation<double> _shakeT;

//   @override
//   void initState() {
//     super.initState();
//     // Pass lasts 3 seconds now
//     _winCtrl = ConfettiController(duration: const Duration(seconds: 3));
//     // Fail lasts ~1.4s but very dense
//     _failCtrl = ConfettiController(duration: const Duration(milliseconds: 1400));
//     _shakeCtrl =
//         AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
//     _shakeT = CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut);
//   }

//   @override
//   void dispose() {
//     _winCtrl.dispose();
//     _failCtrl.dispose();
//     _shakeCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final args =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

//     _quizId = args?['quizId']?.toString() ?? '';
//     _runId = args?['runId']?.toString() ?? '';
//     _future = FirebaseFirestore.instance
//         .collection('quiz_runs')
//         .doc(_runId)
//         .get();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final app = Theme.of(context).extension<AppColors>()!;

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: SafeArea(
//         child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//           future: _future,
//           builder: (context, snap) {
//             if (snap.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }
//             if (!snap.hasData || !(snap.data?.exists ?? false)) {
//               return const Center(child: Text('Summary not found.'));
//             }

//             final data = snap.data!.data()!;
//             final correct = (data['correctCount'] ?? 0) as int;
//             final wrong = (data['wrongCount'] ?? 0) as int;
//             final total = (correct + wrong).clamp(1, 999);
//             final accuracy = total == 0 ? 0 : ((correct / total) * 100).round();
//             final passed = correct >= (total * 0.6).ceil();

//             // Trigger appropriate animation (once per data-build)
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (passed) {
//                 if (_winCtrl.state != ConfettiControllerState.playing) {
//                   _winCtrl.play();
//                 }
//               } else {
//                 if (_failCtrl.state != ConfettiControllerState.playing) {
//                   _failCtrl.play();
//                 }
//                 if (!_shakeCtrl.isAnimating) {
//                   _shakeCtrl
//                     ..reset()
//                     ..forward();
//                 }
//               }
//             });

//             return Stack(
//               children: [
//                 // ---------------- Content ----------------
//                 ListView(
//                   padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
//                   children: [
//                     AnimatedBuilder(
//                       animation: _shakeT,
//                       builder: (context, child) {
//                         final phase = _shakeT.value * 2 * math.pi;
//                         final dx = math.sin(phase) * 8.0 * (1.0 - _shakeT.value);
//                         return Transform.translate(offset: Offset(dx, 0), child: child);
//                       },
//                       child: Column(
//                         children: [
//                           const SizedBox(height: 12),
//                           Text(
//                             'Quiz\nCompleted',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: cs.onSurface,
//                               fontSize: 40,
//                               height: 1.05,
//                               fontWeight: FontWeight.w900,
//                             ),
//                           ),
//                           const SizedBox(height: 28),
//                           _ScoreRing(valueText: '$correct/$total', ringColor: const Color(0xFFFFD43B)),
//                           const SizedBox(height: 28),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 passed ? 'Great Job' : 'Keep Trying',
//                                 style: TextStyle(
//                                   color: cs.onSurface,
//                                   fontSize: 32,
//                                   fontWeight: FontWeight.w800,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Icon(
//                                 passed ? Icons.emoji_events : Icons.sentiment_dissatisfied_rounded,
//                                 size: 34,
//                                 color: cs.onSurface,
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     Container(
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFD9D9D9),
//                         borderRadius: BorderRadius.circular(24),
//                       ),
//                       padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
//                       child: DefaultTextStyle(
//                         style: const TextStyle(
//                           color: Colors.black87,
//                           fontSize: 24,
//                           fontWeight: FontWeight.w700,
//                         ),
//                         child: Column(
//                           children: [
//                             _row('Correct', '$correct'),
//                             const SizedBox(height: 18),
//                             _row('Incorrect', '$wrong'),
//                             const SizedBox(height: 18),
//                             _row('Accuracy', '$accuracy%'),
//                             const SizedBox(height: 18),
//                             _row('Difficulty Bonus', '+200xp'),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 28),
//                     SizedBox(
//                       height: 56,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const QuizExplanationsPage(),
//                               settings: RouteSettings(
//                                 arguments: {'quizId': _quizId, 'runId': _runId},
//                               ),
//                             ),
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: app.ctaBlue,
//                           foregroundColor: Colors.white,
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                           textStyle: const TextStyle(
//                             fontWeight: FontWeight.w900,
//                             fontSize: 18,
//                             letterSpacing: 0.4,
//                           ),
//                         ),
//                         child: const Text('CONTINUE'),
//                       ),
//                     ),
//                   ],
//                 ),

//                 // ---------------- PASS: colorful burst (3s) ----------------
//                 Align(
//                   alignment: const Alignment(0, -0.12),
//                   child: ConfettiWidget(
//                     confettiController: _winCtrl,
//                     blastDirectionality: BlastDirectionality.explosive,
//                     emissionFrequency: 0.15,      // more sustained
//                     numberOfParticles: 16,        // per tick
//                     maxBlastForce: 22,
//                     minBlastForce: 9,
//                     gravity: 0.9,
//                     colors: const [
//                       Color(0xFFFFC53D),
//                       Color(0xFF69DB7C),
//                       Color(0xFF74C0FC),
//                       Color(0xFFF06595),
//                     ],
//                   ),
//                 ),

//                 // ---------------- FAIL: thick full-width drizzle ----------------
//                 // Use the SAME controller for 3 emitters to cover the screen.
//                 Align(
//                   alignment: Alignment.topLeft,
//                   child: ConfettiWidget(
//                     confettiController: _failCtrl,
//                     blastDirection: math.pi / 2 - 0.18, // down-left
//                     blastDirectionality: BlastDirectionality.directional,
//                     emissionFrequency: 0.09,    // dense drizzle
//                     numberOfParticles: 10,
//                     maxBlastForce: 10,
//                     minBlastForce: 4,
//                     gravity: 1.1,
//                     colors: const [Color(0xFF9E9E9E), Color(0xFFBDBDBD), Color(0xFF757575)],
//                   ),
//                 ),
//                 Align(
//                   alignment: Alignment.topCenter,
//                   child: ConfettiWidget(
//                     confettiController: _failCtrl,
//                     blastDirection: math.pi / 2, // straight down
//                     blastDirectionality: BlastDirectionality.directional,
//                     emissionFrequency: 0.1,
//                     numberOfParticles: 12,
//                     maxBlastForce: 10,
//                     minBlastForce: 4,
//                     gravity: 1.15,
//                     colors: const [Color(0xFF9E9E9E), Color(0xFFBDBDBD), Color(0xFF757575)],
//                   ),
//                 ),
//                 Align(
//                   alignment: Alignment.topRight,
//                   child: ConfettiWidget(
//                     confettiController: _failCtrl,
//                     blastDirection: math.pi / 2 + 0.18, // down-right
//                     blastDirectionality: BlastDirectionality.directional,
//                     emissionFrequency: 0.08,
//                     numberOfParticles: 10,
//                     maxBlastForce: 10,
//                     minBlastForce: 4,
//                     gravity: 1.1,
//                     colors: const [Color(0xFF9E9E9E), Color(0xFFBDBDBD), Color(0xFF757575)],
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _row(String left, String right) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(left),
//         Text(right),
//       ],
//     );
//   }
// }

// /// Yellow stroked ring with big center text (e.g., "7/10")
// class _ScoreRing extends StatelessWidget {
//   final String valueText;
//   final Color ringColor;
//   const _ScoreRing({required this.valueText, required this.ringColor});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 240,
//       height: 240,
//       child: CustomPaint(
//         painter: _RingPainter(color: ringColor, stroke: 18),
//         child: Center(
//           child: Text(
//             valueText,
//             style: const TextStyle(
//               fontSize: 56,
//               fontWeight: FontWeight.w900,
//               letterSpacing: 1.0,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _RingPainter extends CustomPainter {
//   final Color color;
//   final double stroke;
//   _RingPainter({required this.color, required this.stroke});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final r = math.min(size.width, size.height) / 2 - stroke / 2;
//     final center = Offset(size.width / 2, size.height / 2);
//     final paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = stroke
//       ..strokeCap = StrokeCap.round;
//     canvas.drawCircle(center, r, paint);
//   }

//   @override
//   bool shouldRepaint(covariant _RingPainter oldDelegate) =>
//       oldDelegate.color != color || oldDelegate.stroke != stroke;
// }


//////////////////////////////////////////////////////////////////////////////////////////////

// lib/Quiz/Student/QuizSummaryPage.dart
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../Theme/Themes.dart';
import './QuizExplanationsPage.dart';

class QuizSummaryPage extends StatefulWidget {
  const QuizSummaryPage({super.key});

  @override
  State<QuizSummaryPage> createState() => _QuizSummaryPageState();
}

class _QuizSummaryPageState extends State<QuizSummaryPage>
    with SingleTickerProviderStateMixin {
  String _quizId = '';
  String _runId = '';
  late Future<DocumentSnapshot<Map<String, dynamic>>> _future;

  // Effects
  late final ConfettiController _winCtrl;  // celebration
  late final ConfettiController _failCtrl; // grey drizzle
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeT;

  @override
  void initState() {
    super.initState();
    _winCtrl  = ConfettiController(duration: const Duration(seconds: 3)); // PASS: 3s
    _failCtrl = ConfettiController(duration: const Duration(milliseconds: 1400)); // FAIL
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _shakeT = CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _winCtrl.dispose();
    _failCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    _quizId = args?['quizId']?.toString() ?? '';
    _runId  = args?['runId']?.toString() ?? '';

    _future = FirebaseFirestore.instance
        .collection('quiz_runs')
        .doc(_runId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final app = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.hasData || !(snap.data?.exists ?? false)) {
              return const Center(child: Text('Summary not found.'));
            }

            final data     = snap.data!.data()!;
            final correct  = (data['correctCount'] ?? 0) as int;
            final wrong    = (data['wrongCount'] ?? 0) as int;
            final total    = (correct + wrong).clamp(1, 999);
            final accuracy = ((correct / total) * 100).round();
            final passed   = correct >= (total * 0.6).ceil();

            // Trigger the proper effect exactly once per build with data
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (passed) {
                if (_winCtrl.state != ConfettiControllerState.playing) {
                  _winCtrl.play();
                }
              } else {
                if (_failCtrl.state != ConfettiControllerState.playing) {
                  _failCtrl.play();
                }
                if (!_shakeCtrl.isAnimating) {
                  _shakeCtrl
                    ..reset()
                    ..forward();
                }
              }
            });

            return Stack(
              children: [
                // -------- Content --------
                ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  children: [
                    AnimatedBuilder(
                      animation: _shakeT,
                      builder: (context, child) {
                        final phase = _shakeT.value * 2 * math.pi;
                        final dx = math.sin(phase) * 8.0 * (1.0 - _shakeT.value);
                        return Transform.translate(offset: Offset(dx, 0), child: child);
                      },
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            'Quiz\nCompleted',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 40,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _ScoreRing(
                            valueText: '$correct/$total',
                            ringColor: const Color(0xFFFFD43B),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                passed ? 'Great Job' : 'Keep Trying',
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                passed
                                    ? Icons.emoji_events
                                    : Icons.sentiment_dissatisfied_rounded,
                                size: 34,
                                color: cs.onSurface,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                        child: Column(
                          children: [
                            _row('Correct',   '$correct'),
                            const SizedBox(height: 18),
                            _row('Incorrect', '$wrong'),
                            const SizedBox(height: 18),
                            _row('Accuracy',  '$accuracy%'),
                            const SizedBox(height: 18),
                            _row('Difficulty Bonus', '+200xp'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QuizExplanationsPage(),
                              settings: RouteSettings(
                                arguments: {'quizId': _quizId, 'runId': _runId},
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: app.ctaBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.4,
                          ),
                        ),
                        child: const Text('CONTINUE'),
                      ),
                    ),
                  ],
                ),

                // -------- PASS: colorful burst (3s, gravity <= 1) --------
                Align(
                  alignment: const Alignment(0, -0.12),
                  child: ConfettiWidget(
                    confettiController: _winCtrl,
                    shouldLoop: false,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.15,
                    numberOfParticles: 16,
                    maxBlastForce: 22,
                    minBlastForce: 9,
                    gravity: 0.85, // valid range [0, 1]
                    colors: const [
                      Color(0xFFFFC53D),
                      Color(0xFF69DB7C),
                      Color(0xFF74C0FC),
                      Color(0xFFF06595),
                    ],
                  ),
                ),

                // -------- FAIL: thick, full-width grey drizzle (gravity <= 1) --------
                Align(
                  alignment: Alignment.topLeft,
                  child: ConfettiWidget(
                    confettiController: _failCtrl,
                    shouldLoop: false,
                    blastDirection: math.pi / 2 - 0.18, // down-left
                    blastDirectionality: BlastDirectionality.directional,
                    emissionFrequency: 0.16,
                    numberOfParticles: 18,
                    maxBlastForce: 6,
                    minBlastForce: 2,
                    gravity: 0.98,
                    colors: const [
                      Color(0xFFBDBDBD),
                      Color(0xFF9E9E9E),
                      Color(0xFF757575),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _failCtrl,
                    shouldLoop: false,
                    blastDirection: math.pi / 2,      // straight down
                    blastDirectionality: BlastDirectionality.directional,
                    emissionFrequency: 0.18,
                    numberOfParticles: 22,
                    maxBlastForce: 6,
                    minBlastForce: 2,
                    gravity: 0.99,
                    colors: const [
                      Color(0xFFBDBDBD),
                      Color(0xFF9E9E9E),
                      Color(0xFF757575),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: ConfettiWidget(
                    confettiController: _failCtrl,
                    shouldLoop: false,
                    blastDirection: math.pi / 2 + 0.18, // down-right
                    blastDirectionality: BlastDirectionality.directional,
                    emissionFrequency: 0.16,
                    numberOfParticles: 18,
                    maxBlastForce: 6,
                    minBlastForce: 2,
                    gravity: 0.98,
                    colors: const [
                      Color(0xFFBDBDBD),
                      Color(0xFF9E9E9E),
                      Color(0xFF757575),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(String left, String right) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(left), Text(right)],
    );
  }
}

/// Yellow stroked ring with big center text (e.g., "7/10")
class _ScoreRing extends StatelessWidget {
  final String valueText;
  final Color ringColor;
  const _ScoreRing({required this.valueText, required this.ringColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: CustomPaint(
        painter: _RingPainter(color: ringColor, stroke: 18),
        child: Center(
          child: Text(
            valueText,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double stroke;
  _RingPainter({required this.color, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2 - stroke / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.stroke != stroke;
}
