// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// import '../../Theme/Themes.dart';
// import './quiz_models.dart' as qm;

// class PublishEditedQuizPage extends StatefulWidget {
//   const PublishEditedQuizPage({super.key});

//   @override
//   State<PublishEditedQuizPage> createState() => _PublishEditedQuizPageState();
// }

// class _PublishEditedQuizPageState extends State<PublishEditedQuizPage>
//     with SingleTickerProviderStateMixin {
//   // Layout
//   static const double _hPad = 20;
//   static const double _radius = 16;
//   static const double _borderW = 1.6;

//   // Attempts
//   final List<String> _attemptsList = const ['1', '2', '3', '5'];
//   String _attempts = '3';

//   // State
//   bool _busy = false;

//   // UI controllers
//   final _titleC = TextEditingController();

//   // Blinking dot (optional subtle attention on status)
//   late final AnimationController _blinkCtrl =
//       AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
//         ..repeat(reverse: true);

//   // Route data
//   String _quizId = '';
//   String _moduleId = 'Unknown';
//   String _moduleTitle = 'Module';
//   late qm.PublishPreset _preset;
//   late List<qm.QuizQuestion> _questions;

//   @override
//   void dispose() {
//     _blinkCtrl.dispose();
//     _titleC.dispose();
//     super.dispose();
//   }

//   // ----------------- Header (rounded like your screenshot, no back button) -----------------
//   Widget _header(BuildContext context, String title) {
//     final app = Theme.of(context).extension<AppColors>()!;
//     final top = MediaQuery.of(context).padding.top;
//     return Container(
//       decoration: BoxDecoration(
//         color: app.headerBg,
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(28),
//           bottomRight: Radius.circular(28),
//         ),
//       ),
//       padding: EdgeInsets.fromLTRB(_hPad, top + 14, _hPad, 18),
//       child: Text(
//         title,
//         style: TextStyle(
//           color: app.headerFg,
//           fontSize: 28,
//           fontWeight: FontWeight.w800,
//         ),
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
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               left,
//               style: TextStyle(
//                 color: cs.onSurface,
//                 fontSize: 26, // bigger to match your weighty UI
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//           ),
//           Text(
//             right,
//             style: TextStyle(
//               color: cs.onSurface,
//               fontSize: 26,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ----------------- Status chip: "Edited" with blinking dot -----------------
//   Widget _statusEditedChip(BuildContext ctx) {
//     final cs = Theme.of(ctx).colorScheme;
//     final app = Theme.of(ctx).extension<AppColors>()!;
//     return Container(
//       height: 36,
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: BoxDecoration(
//         color: app.chipBg, // soft neutral
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'Edited',
//             style: TextStyle(
//               color: cs.onSurface,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const SizedBox(width: 8),
//           FadeTransition(
//             opacity: Tween<double>(begin: .35, end: 1).animate(_blinkCtrl),
//             child: Container(
//               width: 14,
//               height: 14,
//               decoration: const BoxDecoration(
//                 color: Color(0xFFD1646C), // red dot
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _saveEdit() async {
//     if (_busy) return;
//     setState(() => _busy = true);

//     try {
//       final title = _titleC.text.trim();

//       final presetMap = {
//         'difficulty': _preset.difficulty,
//         'points': _preset.points,
//         'hints': _preset.hints,
//         'lives': _preset.lives,
//         'questions': _questions.length,
//         'time': _preset.time,
//       };

//       final payload = <String, dynamic>{
//         'moduleId': _moduleId,
//         'moduleTitle': _moduleTitle,
//         'quizTitle': title,
//         'status': 'Edited', // <<<<<< IMPORTANT
//         'attempts': int.tryParse(_attempts) ?? 3,
//         'preset': presetMap,
//         'questions': _questions.map((q) => q.toMap()).toList(),
//         // keep createdBy/createdAt as-is (we only update above fields)
//       };

//       await FirebaseFirestore.instance
//           .collection('quizzes')
//           .doc(_quizId)
//           .update(payload);

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Edits saved to Firestore.'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       Navigator.of(context).popUntil((r) => r.isFirst);
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to save: $e'),
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

//     // Read route args once
//     final args =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

//     if (_quizId.isEmpty && args != null) {
//       _quizId = args['quizId']?.toString() ?? '';
//       _moduleId = args['moduleId']?.toString() ?? 'Unknown';
//       _moduleTitle = args['moduleTitle']?.toString() ?? 'Module';
//       _preset = args['preset'] as qm.PublishPreset;
//       _questions = (args['questions'] as List<qm.QuizQuestion>);
//       _titleC.text = (args['quizTitle']?.toString() ?? '');
//       final at = args['attempts'];
//       if (at != null) _attempts = at.toString();
//     }

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: SafeArea(
//         bottom: false,
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 24),
//           children: [
//             _header(context, 'Publish Quiz'),
//             const SizedBox(height: 22),

//             // Quiz Title
//             Text(
//               'Quiz Title',
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
//               alignment: Alignment.centerLeft,
//               padding: const EdgeInsets.symmetric(horizontal: 14),
//               child: TextField(
//                 controller: _titleC,
//                 decoration: const InputDecoration(
//                   isCollapsed: true,
//                   border: InputBorder.none,
//                 ),
//                 style: TextStyle(
//                   color: cs.onSurface,
//                   fontWeight: FontWeight.w700,
//                   fontSize: 18,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 22),

//             // Target Module
//             Text(
//               'Target Module',
//               style: TextStyle(
//                 color: cs.onSurface,
//                 fontSize: 28,
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
//                 _moduleTitle,
//                 style: TextStyle(
//                   color: cs.onSurface,
//                   fontWeight: FontWeight.w700,
//                   fontSize: 18,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 22),

//             // Status (Edited)
//             Row(
//               children: [
//                 Text(
//                   'Status',
//                   style: TextStyle(
//                     color: cs.onSurface,
//                     fontSize: 28,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 _statusEditedChip(context),
//               ],
//             ),

//             const SizedBox(height: 22),

//             // Preset dashed panel
//             _dashedPanel(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Preset',
//                     style: TextStyle(
//                       color: cs.onSurface,
//                       fontSize: 28,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   _row(context, 'Difficulty', _preset.difficulty),
//                   _row(context, 'Points', _preset.points.toString()),
//                   _row(context, 'Hints', _preset.hints),
//                   _row(context, 'Lives', _preset.lives.toString()),
//                   _row(context, 'Questions', _preset.questions.toString()),
//                   _row(context, 'Time', _preset.time),
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

//             // Save Edit button
//             SizedBox(
//               height: 56,
//               child: ElevatedButton(
//                 onPressed: _busy ? null : _saveEdit,
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
//                     : const Text('Save Edit'),
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

///////////////////////////////////////////////////////////////////////////

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// import '../../Theme/Themes.dart';
// import './quiz_models.dart' as qm;

// class PublishEditedQuizPage extends StatefulWidget {
//   const PublishEditedQuizPage({super.key});

//   @override
//   State<PublishEditedQuizPage> createState() => _PublishEditedQuizPageState();
// }

// class _PublishEditedQuizPageState extends State<PublishEditedQuizPage>
//     with SingleTickerProviderStateMixin {
//   // Layout
//   static const double _hPad = 20;
//   static const double _radius = 16;
//   static const double _borderW = 1.6;

//   // Attempts list (keep values as strings for Dropdown)
//   static const List<String> _attemptsItems = ['1', '2', '3', '5'];
//   String _attempts = '3'; // current dropdown value (always one of items)

//   bool _busy = false;

//   // UI controllers
//   final _titleC = TextEditingController();

//   // subtle blinking dot for “Edited”
//   late final AnimationController _blinkCtrl =
//       AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
//         ..repeat(reverse: true);

//   // Route data
//   String _quizId = '';
//   String _moduleId = 'Unknown';
//   String _moduleTitle = 'Module';
//   late qm.PublishPreset _preset;
//   late List<qm.QuizQuestion> _questions;

//   @override
//   void dispose() {
//     _blinkCtrl.dispose();
//     _titleC.dispose();
//     super.dispose();
//   }

//   // Dark header with rounded bottom (no back button)
//   Widget _header(BuildContext context, String title) {
//     final app = Theme.of(context).extension<AppColors>()!;
//     final top = MediaQuery.of(context).padding.top;
//     return Container(
//       decoration: BoxDecoration(
//         color: app.headerBg,
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(28),
//           bottomRight: Radius.circular(28),
//         ),
//       ),
//       padding: EdgeInsets.fromLTRB(_hPad, top + 14, _hPad, 18),
//       child: Text(
//         title,
//         style: TextStyle(
//           color: app.headerFg,
//           fontSize: 28,
//           fontWeight: FontWeight.w800,
//         ),
//       ),
//     );
//   }

//   // Dashed panel painter wrapper
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

//   // big row style to match your UI
//   Widget _row(BuildContext context, String left, String right) {
//     final cs = Theme.of(context).colorScheme;
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               left,
//               style: TextStyle(
//                 color: cs.onSurface,
//                 fontSize: 26,
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//           ),
//           Text(
//             right,
//             style: TextStyle(
//               color: cs.onSurface,
//               fontSize: 26,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // “Edited” chip with red blinking dot
//   Widget _statusEditedChip(BuildContext ctx) {
//     final cs = Theme.of(ctx).colorScheme;
//     final app = Theme.of(ctx).extension<AppColors>()!;
//     return Container(
//       height: 36,
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: BoxDecoration(
//         color: app.chipBg,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text('Edited', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800)),
//           const SizedBox(width: 8),
//           FadeTransition(
//             opacity: Tween<double>(begin: .35, end: 1).animate(_blinkCtrl),
//             child: Container(
//               width: 14, height: 14,
//               decoration: const BoxDecoration(color: Color(0xFFD1646C), shape: BoxShape.circle),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Normalize attempts -> must be in _attemptsItems
//   String _normalizeAttempts(dynamic value) {
//     final v = value?.toString().trim();
//     if (v == null || !_attemptsItems.contains(v)) return _attemptsItems.first;
//     return v;
//   }

//   Future<void> _saveEdit() async {
//     if (_busy) return;
//     setState(() => _busy = true);

//     try {
//       final title = _titleC.text.trim();
//       final presetMap = {
//         'difficulty': _preset.difficulty,
//         'points': _preset.points,
//         'hints': _preset.hints,
//         'lives': _preset.lives,
//         // the TRUTH for Questions is the edited list length:
//         'questions': _questions.length,
//         'time': _preset.time,
//       };

//       await FirebaseFirestore.instance.collection('quizzes').doc(_quizId).update({
//         'moduleId': _moduleId,
//         'moduleTitle': _moduleTitle,
//         'quizTitle': title,
//         'status': 'Edited',                  // important
//         'attempts': int.tryParse(_attempts) ?? 3,
//         'preset': presetMap,
//         'questions': _questions.map((q) => q.toMap()).toList(),
//       });

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text('Edits saved to Firestore.'),
//         behavior: SnackBarBehavior.floating,
//       ));
//       Navigator.of(context).popUntil((r) => r.isFirst);
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Failed to save: $e'),
//         behavior: SnackBarBehavior.floating,
//       ));
//     } finally {
//       if (mounted) setState(() => _busy = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final app = Theme.of(context).extension<AppColors>()!;

//     // Read route args once (from EditQuizQuestionsPage)
//     final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
//     if (_quizId.isEmpty && args != null) {
//       _quizId = args['quizId']?.toString() ?? '';
//       _moduleId = args['moduleId']?.toString() ?? 'Unknown';
//       _moduleTitle = args['moduleTitle']?.toString() ?? 'Module';
//       _preset = args['preset'] as qm.PublishPreset;
//       _questions = (args['questions'] as List<qm.QuizQuestion>);
//       _titleC.text = (args['quizTitle']?.toString() ?? '');
//       _attempts = _normalizeAttempts(args['attempts']);
//       // also make sure preset.questions mirrors edits while previewing:
//       _preset = qm.PublishPreset(
//         difficulty: _preset.difficulty,
//         points: _preset.points,
//         hints: _preset.hints,
//         lives: _preset.lives,
//         questions: _questions.length,  // <— ensures dashed panel shows new count
//         time: _preset.time,
//       );
//     }

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: SafeArea(
//         bottom: false,
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 24),
//           children: [
//             _header(context, 'Publish Edited Quiz'),
//             const SizedBox(height: 22),

//             // Quiz Title
//             Text('Quiz Title',
//               style: TextStyle(color: cs.onSurface, fontSize: 28, fontWeight: FontWeight.w800)),
//             const SizedBox(height: 10),
//             Container(
//               height: 56,
//               decoration: BoxDecoration(
//                 color: app.panelBg,
//                 borderRadius: BorderRadius.circular(_radius),
//                 border: Border.all(color: app.borderStrong, width: _borderW),
//               ),
//               alignment: Alignment.centerLeft,
//               padding: const EdgeInsets.symmetric(horizontal: 14),
//               child: TextField(
//                 controller: _titleC,
//                 decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
//                 style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 18),
//               ),
//             ),

//             const SizedBox(height: 22),

//             // Target Module
//             Text('Target Module',
//               style: TextStyle(color: cs.onSurface, fontSize: 28, fontWeight: FontWeight.w800)),
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
//               child: Text(_moduleTitle,
//                 style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 18)),
//             ),

//             const SizedBox(height: 22),

//             // Status (Edited)
//             Row(
//               children: [
//                 Text('Status',
//                   style: TextStyle(color: cs.onSurface, fontSize: 28, fontWeight: FontWeight.w800)),
//                 const SizedBox(width: 12),
//                 _statusEditedChip(context),
//               ],
//             ),

//             const SizedBox(height: 22),

//             // Preset dashed panel (QUESTION COUNT reflects _questions.length)
//             _dashedPanel(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Preset',
//                       style: TextStyle(color: cs.onSurface, fontSize: 28, fontWeight: FontWeight.w800)),
//                   const SizedBox(height: 8),
//                   _row(context, 'Difficulty', _preset.difficulty),
//                   _row(context, 'Points', _preset.points.toString()),
//                   _row(context, 'Hints', _preset.hints),
//                   _row(context, 'Lives', _preset.lives.toString()),
//                   _row(context, 'Questions', _questions.length.toString()), // <—
//                   _row(context, 'Time', _preset.time),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 24),

//             // Attempts
//             Text('Attempts',
//               style: TextStyle(color: cs.onSurface, fontSize: 28, fontWeight: FontWeight.w800)),
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
//                 value: _attempts,                         // always guaranteed in items
//                 underline: const SizedBox.shrink(),
//                 borderRadius: BorderRadius.circular(14),
//                 items: _attemptsItems.map((a) =>
//                   DropdownMenuItem<String>(
//                     value: a,
//                     child: Text(a, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700)),
//                   )).toList(growable: false),
//                 onChanged: (v) => setState(() => _attempts = v ?? _attempts),
//               ),
//             ),

//             const SizedBox(height: 26),

//             // Save Edit
//             SizedBox(
//               height: 56,
//               child: ElevatedButton(
//                 onPressed: _busy ? null : _saveEdit,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: app.ctaBlue,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(18),
//                     side: BorderSide(color: app.ctaBlueBorder, width: 1.6),
//                   ),
//                   textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
//                 ),
//                 child: _busy
//                     ? const SizedBox(
//                         width: 22, height: 22,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2.6,
//                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                       )
//                     : const Text('Save Edit'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ===== dashed painter =====
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
//     final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
//     final path = Path()..addRRect(rrect);
//     final paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth;

//     final dashed = _createDashedPath(path, dashWidth, dashGap);
//     canvas.drawPath(dashed, paint);
//   }

//   Path _createDashedPath(Path source, double dashWidth, double dashGap) {
//     final dest = Path();
//     for (final metric in source.computeMetrics()) {
//       double distance = 0;
//       while (distance < metric.length) {
//         final next = distance + dashWidth;
//         dest.addPath(metric.extractPath(distance, next), Offset.zero);
//         distance = next + dashGap;
//       }
//     }
//     return dest;
//   }

//   @override
//   bool shouldRepaint(covariant _DashedBorderPainter old) =>
//       old.color != color ||
//       old.strokeWidth != strokeWidth ||
//       old.dashWidth != dashWidth ||
//       old.dashGap != dashGap ||
//       old.radius != radius;
// }

/////////////////////////////////////////////////////////////////pahala weda

// lib/Quiz/Teacher/PublishEditedQuizPage.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// import '../../Theme/Themes.dart';
// import './quiz_models.dart' as qm;

// class PublishEditedQuizPage extends StatefulWidget {
//   const PublishEditedQuizPage({super.key});

//   @override
//   State<PublishEditedQuizPage> createState() => _PublishEditedQuizPageState();
// }

// class _PublishEditedQuizPageState extends State<PublishEditedQuizPage>
//     with SingleTickerProviderStateMixin {
//   // Layout
//   static const double _hPad = 20;
//   static const double _radius = 16;
//   static const double _borderW = 1.6;

//   // Attempts dropdown (string values)
//   static const List<String> _attemptsItems = ['1', '2', '3', '5'];
//   String _attempts = '3';

//   bool _busy = false;

//   // Controllers
//   final _titleC = TextEditingController();

//   // Soft blinking red dot for “Edited”
//   late final AnimationController _blinkCtrl =
//       AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
//         ..repeat(reverse: true);

//   // Route data
//   String _quizId = '';
//   String _moduleId = 'Unknown';
//   String _moduleTitle = 'Module';
//   late qm.PublishPreset _preset;
//   late List<qm.QuizQuestion> _questions;

//   @override
//   void dispose() {
//     _blinkCtrl.dispose();
//     _titleC.dispose();
//     super.dispose();
//   }

//   // ---------- small UI helpers ----------
//   Widget _chip(BuildContext context,
//       {required IconData icon,
//       required String label,
//       required Color bg,
//       required Color fg}) {
//     return Container(
//       height: 36,
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration:
//           BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 18, color: fg),
//           const SizedBox(width: 8),
//           Text(label,
//               style:
//                   TextStyle(color: fg, fontWeight: FontWeight.w800, height: 1)),
//         ],
//       ),
//     );
//   }

//   Widget _outlinedBox(BuildContext context, {required Widget child}) {
//     final app = Theme.of(context).extension<AppColors>()!;
//     return Container(
//       height: 56,
//       alignment: Alignment.centerLeft,
//       decoration: BoxDecoration(
//         color: app.panelBg,
//         borderRadius: BorderRadius.circular(_radius),
//         border: Border.all(color: app.borderStrong, width: _borderW),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       child: child,
//     );
//   }

//   String _normalizeAttempts(dynamic value) {
//     final v = value?.toString().trim();
//     if (v == null || !_attemptsItems.contains(v)) return _attemptsItems.first;
//     return v;
//   }

//   Future<void> _saveEdit() async {
//     if (_busy) return;
//     setState(() => _busy = true);

//     try {
//       final title = _titleC.text.trim();

//       final presetMap = {
//         'difficulty': _preset.difficulty,
//         'points': _preset.points,
//         'hints': _preset.hints,
//         'lives': _preset.lives,
//         'questions': _questions.length, // <- truth from edited list
//         'time': _preset.time,
//       };

//       await FirebaseFirestore.instance
//           .collection('quizzes')
//           .doc(_quizId)
//           .update({
//         'moduleId': _moduleId,
//         'moduleTitle': _moduleTitle,
//         'quizTitle': title,
//         'status': 'Edited',
//         'attempts': int.tryParse(_attempts) ?? 3,
//         'preset': presetMap,
//         'questions': _questions.map((q) => q.toMap()).toList(),
//       });

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text('Edits saved to Firestore.'),
//         behavior: SnackBarBehavior.floating,
//       ));
//       Navigator.of(context).popUntil((r) => r.isFirst);
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Failed to save: $e'),
//         behavior: SnackBarBehavior.floating,
//       ));
//     } finally {
//       if (mounted) setState(() => _busy = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final app = Theme.of(context).extension<AppColors>()!;

//     // Read arguments (once)
//     final args =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
//     if (_quizId.isEmpty && args != null) {
//       _quizId = args['quizId']?.toString() ?? '';
//       _moduleId = args['moduleId']?.toString() ?? 'Unknown';
//       _moduleTitle = args['moduleTitle']?.toString() ?? 'Module';
//       _preset = args['preset'] as qm.PublishPreset;
//       _questions = (args['questions'] as List<qm.QuizQuestion>);
//       _titleC.text = (args['quizTitle']?.toString() ?? '');
//       _attempts = _normalizeAttempts(args['attempts']);

//       // reflect latest question count visually while previewing
//       _preset = qm.PublishPreset(
//         difficulty: _preset.difficulty,
//         points: _preset.points,
//         hints: _preset.hints,
//         lives: _preset.lives,
//         questions: _questions.length,
//         time: _preset.time,
//       );
//     }

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: SafeArea(
//         bottom: false,
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 24),
//           children: [
//             // Title (no dark header)
//             Text('Publish Edited Quiz',
//                 style: TextStyle(
//                     color: cs.onSurface,
//                     fontSize: 30,
//                     fontWeight: FontWeight.w800)),
//             const SizedBox(height: 22),

//             // Quiz Title
//             _chip(context,
//                 icon: Icons.event_note_rounded,
//                 label: 'Quiz Title',
//                 bg: const Color(0xFFEBD1DE),
//                 fg: const Color(0xFF6D2D4B)),
//             const SizedBox(height: 10),
//             _outlinedBox(
//               context,
//               child: TextField(
//                 controller: _titleC,
//                 decoration: const InputDecoration(
//                     isCollapsed: true, border: InputBorder.none),
//                 style: TextStyle(
//                     color: cs.onSurface,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 18),
//               ),
//             ),

//             const SizedBox(height: 22),

//             // Target Module
//             _chip(context,
//                 icon: Icons.sticky_note_2_outlined,
//                 label: 'Target Module',
//                 bg: const Color(0xFFDAD1F7),
//                 fg: const Color(0xFF4532A3)),
//             const SizedBox(height: 10),
//             _outlinedBox(
//               context,
//               child: Text(
//                 _moduleTitle,
//                 style: TextStyle(
//                     color: cs.onSurface,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 18),
//               ),
//             ),

//             const SizedBox(height: 22),

//             // Attempts + Status row
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _chip(context,
//                           icon: Icons.add_box_outlined,
//                           label: 'Attempts',
//                           bg: const Color(0xFFF1B5BD),
//                           fg: const Color(0xFF7E1221)),
//                       const SizedBox(height: 10),
//                       _outlinedBox(
//                         context,
//                         child: DropdownButton<String>(
//                           isExpanded: true,
//                           value: _attempts,
//                           underline: const SizedBox.shrink(),
//                           borderRadius: BorderRadius.circular(14),
//                           items: _attemptsItems
//                               .map((a) => DropdownMenuItem<String>(
//                                     value: a,
//                                     child: Text(a,
//                                         style: TextStyle(
//                                             color: cs.onSurface,
//                                             fontWeight: FontWeight.w700)),
//                                   ))
//                               .toList(growable: false),
//                           onChanged: (v) =>
//                               setState(() => _attempts = v ?? _attempts),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 18),
//                 // Status chip + blinking dot to the right
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _chip(context,
//                         icon: Icons.sell_outlined,
//                         label: 'Status',
//                         bg: const Color(0xFFD0E8F1),
//                         fg: const Color(0xFF2D6C83)),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Text('Edited',
//                             style: TextStyle(
//                                 color: cs.onSurface,
//                                 fontWeight: FontWeight.w800,
//                                 fontSize: 18)),
//                         const SizedBox(width: 8),
//                         FadeTransition(
//                           opacity: Tween(begin: .35, end: 1.0).animate(_blinkCtrl),
//                           child: Container(
//                             width: 12,
//                             height: 12,
//                             decoration: const BoxDecoration(
//                               color: Color(0xFFD1646C),
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),

//             const SizedBox(height: 26),

//             // Two-column PRESET summary (no dashed frame)
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Left column: Difficulty / Hints / Timer
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _chip(context,
//                           icon: Icons.local_fire_department,
//                           label: 'Difficulty',
//                           bg: app.tagDiffBg,
//                           fg: app.tagDiffFg),
//                       const SizedBox(height: 10),
//                       Text(_preset.difficulty,
//                           style: TextStyle(
//                               color: cs.onSurface,
//                               fontWeight: FontWeight.w800,
//                               fontSize: 26)),
//                       const SizedBox(height: 22),

//                       _chip(context,
//                           icon: Icons.lightbulb_outline,
//                           label: 'Hints',
//                           bg: app.tagHintsBg,
//                           fg: app.tagHintsFg),
//                       const SizedBox(height: 10),
//                       Text(_preset.hints,
//                           style: TextStyle(
//                               color: cs.onSurface,
//                               fontWeight: FontWeight.w800,
//                               fontSize: 26)),
//                       const SizedBox(height: 22),

//                       _chip(context,
//                           icon: Icons.timer_outlined,
//                           label: 'Timer',
//                           bg: app.tagTimerBg,
//                           fg: app.tagTimerFg),
//                       const SizedBox(height: 10),
//                       Text(_preset.time,
//                           style: TextStyle(
//                               color: cs.onSurface,
//                               fontWeight: FontWeight.w800,
//                               fontSize: 26)),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(width: 18),

//                 // Right column: Points / Lives / Questions
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _chip(context,
//                           icon: Icons.bolt,
//                           label: 'Points',
//                           bg: app.tagPointsBg,
//                           fg: app.tagPointsFg),
//                       const SizedBox(height: 10),
//                       Text(_preset.points.toString(),
//                           style: TextStyle(
//                               color: cs.onSurface,
//                               fontWeight: FontWeight.w800,
//                               fontSize: 26)),
//                       const SizedBox(height: 22),

//                       _chip(context,
//                           icon: Icons.favorite_border,
//                           label: 'Lives',
//                           bg: app.tagLivesBg,
//                           fg: app.tagLivesFg),
//                       const SizedBox(height: 10),
//                       Text(_preset.lives.toString(),
//                           style: TextStyle(
//                               color: cs.onSurface,
//                               fontWeight: FontWeight.w800,
//                               fontSize: 26)),
//                       const SizedBox(height: 22),

//                       _chip(context,
//                           icon: Icons.error_outline,
//                           label: 'Questions',
//                           bg: app.tagQsBg,
//                           fg: cs.onSurface),
//                       const SizedBox(height: 10),
//                       // <- ALWAYS the edited list length
//                       Text(_questions.length.toString(),
//                           style: TextStyle(
//                               color: cs.onSurface,
//                               fontWeight: FontWeight.w800,
//                               fontSize: 26)),
//                     ],
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 28),

//             // Save
//             SizedBox(
//               height: 56,
//               child: ElevatedButton(
//                 onPressed: _busy ? null : _saveEdit,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: app.ctaBlue,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(18),
//                     side: BorderSide(color: app.ctaBlueBorder, width: 1.6),
//                   ),
//                   textStyle:
//                       const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
//                     : const Text('Save Edit'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// lib/Quiz/Teacher/PublishEditedQuizPage.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../Theme/Themes.dart';
import './quiz_models.dart' as qm;

class PublishEditedQuizPage extends StatefulWidget {
  const PublishEditedQuizPage({super.key});

  @override
  State<PublishEditedQuizPage> createState() => _PublishEditedQuizPageState();
}

class _PublishEditedQuizPageState extends State<PublishEditedQuizPage>
    with SingleTickerProviderStateMixin {
  // Layout tokens
  static const double _hPad = 20;
  static const double _panelTopRadius = 28;
  static const double _rowGap = 18;
  static const double _fieldH = 56;
  static const double _radius = 16;
  static const double _borderW = 1.6;

  // Attempts (only editable control on this screen)
  static const List<String> _attemptItems = ['1', '2', '3', '5'];
  String _attempts = '3';

  // Route / data
  String _quizId = '';
  String _moduleId = 'Unknown';
  String _moduleTitle = 'Module';
  late qm.PublishPreset _preset;
  late List<qm.QuizQuestion> _questions;
  final _title = ValueNotifier<String>('');

  // Save state
  bool _busy = false;

  // tiny blinking dot for Status
  late final AnimationController _blinkCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _blinkCtrl.dispose();
    _title.dispose();
    super.dispose();
  }

  String _normalizeAttempt(dynamic v) {
    final s = v?.toString();
    if (s == null || !_attemptItems.contains(s)) return '3';
    return s;
  }

  Future<void> _saveEdit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final title = _title.value.trim();

      // Keep preset synced; questions count driven by edited list
      final presetMap = {
        'difficulty': _preset.difficulty,
        'points': _preset.points,
        'hints': _preset.hints,
        'lives': _preset.lives,
        'questions': _questions.length,
        'time': _preset.time,
      };

      await FirebaseFirestore.instance.collection('quizzes').doc(_quizId).update({
        'moduleId': _moduleId,
        'moduleTitle': _moduleTitle,
        'quizTitle': title,
        'status': 'Edited',
        'attempts': int.tryParse(_attempts) ?? 3,
        'preset': presetMap,
        'questions': _questions.map((q) => q.toMap()).toList(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Edits saved.'),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ===== UI helpers
  Widget _blackHeader(BuildContext context, String title) {
    final top = MediaQuery.of(context).padding.top;
    final app = Theme.of(context).extension<AppColors>()!;
    return Container(
      color: app.headerBg, // pure black header
      padding: EdgeInsets.fromLTRB(_hPad, top + 14, _hPad, 18),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: app.headerFg,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _chip(BuildContext context,
      {required IconData icon, required String label, required Color bg, required Color fg}) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _lockedBox(BuildContext context, String text) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: _fieldH,
      decoration: BoxDecoration(
        color: app.panelBg,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: app.borderStrong, width: _borderW),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 18),
      ),
    );
  }

  Widget _attemptDropdown(BuildContext context) {
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
      child: DropdownButton<String>(
        isExpanded: true,
        value: _attempts,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(14),
        items: _attemptItems
            .map((a) => DropdownMenuItem<String>(
                  value: a,
                  child: Text(a, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700)),
                ))
            .toList(growable: false),
        onChanged: (v) => setState(() => _attempts = v ?? _attempts),
      ),
    );
  }

  Widget _statusEdited(BuildContext context) {
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
        children: [
          Text('Edited', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(width: 8),
          FadeTransition(
            opacity: Tween<double>(begin: .35, end: 1).animate(_blinkCtrl),
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(color: Color(0xFFD1646C), shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // read route args exactly once
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (_quizId.isEmpty && args != null) {
      _quizId = args['quizId']?.toString() ?? '';
      _moduleId = args['moduleId']?.toString() ?? 'Unknown';
      _moduleTitle = args['moduleTitle']?.toString() ?? 'Module';
      _preset = args['preset'] as qm.PublishPreset;
      _questions = (args['questions'] as List<qm.QuizQuestion>);
      _title.value = (args['quizTitle']?.toString() ?? '');
      _attempts = _normalizeAttempt(args['attempts']);
    }

    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.of(context).padding.top;
    const overlap = 18.0;
    final headerHeight = topPad + 86;

    // Keep Questions display in sync with edited list
    final questionCount = _questions.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _blackHeader(context, 'Publish Edited Quiz'),
          // white rounded panel under header
          Positioned.fill(
            top: headerHeight - overlap,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(_panelTopRadius)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(_hPad, 24, _hPad, 24),
                children: [
                  // ---- Quiz Title (locked)
                  _chip(context,
                      icon: Icons.event_note_rounded,
                      label: 'Quiz Title',
                      bg: const Color(0xFFF1CBDC),
                      fg: const Color(0xFF7E2D59)),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String>(
                    valueListenable: _title,
                    builder: (_, title, __) => _lockedBox(context, title),
                  ),
                  const SizedBox(height: _rowGap),

                  // ---- Target Module (locked)
                  _chip(context,
                      icon: Icons.sticky_note_2_outlined,
                      label: 'Target Module',
                      bg: const Color(0xFFE0D2FF),
                      fg: const Color(0xFF5C41CF)),
                  const SizedBox(height: 8),
                  _lockedBox(context, _moduleTitle),
                  const SizedBox(height: _rowGap),

                  // ---- Attempts + Status row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _chip(context,
                                icon: Icons.app_registration_rounded,
                                label: 'Attempts',
                                bg: const Color(0xFFF9C2C7),
                                fg: const Color(0xFFAA2E3C)),
                            const SizedBox(height: 8),
                            _attemptDropdown(context),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _chip(context,
                                icon: Icons.sell_outlined,
                                label: 'Status',
                                bg: const Color(0xFFCDEBF7),
                                fg: const Color(0xFF216E8A)),
                            const SizedBox(height: 8),
                            _statusEdited(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _rowGap),

                  // ---- Two columns of locked facts
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _chip(context,
                                icon: Icons.local_fire_department_outlined,
                                label: 'Difficulty',
                                bg: app.tagDiffBg,
                                fg: app.tagDiffFg),
                            const SizedBox(height: 8),
                            _lockedBox(context, _preset.difficulty),
                            const SizedBox(height: 16),

                            _chip(context,
                                icon: Icons.lightbulb_outline,
                                label: 'Hints',
                                bg: app.tagHintsBg,
                                fg: app.tagHintsFg),
                            const SizedBox(height: 8),
                            _lockedBox(context, _preset.hints),
                            const SizedBox(height: 16),

                            _chip(context,
                                icon: Icons.timer_outlined,
                                label: 'Timer',
                                bg: app.tagTimerBg,
                                fg: app.tagTimerFg),
                            const SizedBox(height: 8),
                            _lockedBox(context, _preset.time),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // RIGHT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _chip(context,
                                icon: Icons.bolt, label: 'Points', bg: app.tagPointsBg, fg: app.tagPointsFg),
                            const SizedBox(height: 8),
                            _lockedBox(context, _preset.points.toString()),
                            const SizedBox(height: 16),

                            _chip(context,
                                icon: Icons.favorite_border,
                                label: 'Lives',
                                bg: app.tagLivesBg,
                                fg: app.tagLivesFg),
                            const SizedBox(height: 8),
                            _lockedBox(context, _preset.lives.toString()),
                            const SizedBox(height: 16),

                            _chip(context,
                                icon: Icons.error_outline,
                                label: 'Questions',
                                bg: app.tagQsBg,
                                fg: app.tagQsFg),
                            const SizedBox(height: 8),
                            _lockedBox(context, questionCount.toString()),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // Save Edit CTA
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _saveEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: app.ctaBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: app.ctaBlueBorder, width: 1.6),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
                          : const Text('Save Edit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
