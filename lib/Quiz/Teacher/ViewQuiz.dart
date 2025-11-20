// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import './EditQuizQuestionsPage.dart';
// import '../../Theme/Themes.dart';
// import '../../widgets/BackButtonWidget.dart'; // CircleBackButton

// class ViewQuizPage extends StatefulWidget {
//   const ViewQuizPage({super.key});

//   @override
//   State<ViewQuizPage> createState() => _ViewQuizPageState();
// }

// class _ViewQuizPageState extends State<ViewQuizPage> {
//   // ---- layout tokens ----
//   static const double _pageHPad = 20;
//   static const double _fieldH = 56;
//   static const double _radius = 16;
//   static const double _borderW = 1.6;

//   late String quizId;

//   // controllers / state
//   final _titleC = TextEditingController();
//   final _pointsC = TextEditingController();

//   String? _difficulty;
//   String? _hints;
//   String? _timer;
//   String? _lives;
//   String? _questions;

//   bool _loading = true;
//   bool _saving = false;

//   // dropdown data
//   final _difficulties = const ['Easy', 'Medium', 'Hard', 'All'];
//   final _hintsList = const ['Enable', 'Disable'];
//   final _timers = const ['10 Min', '15 Min', '20 Min', '30 Min', '45 Min'];
//   final _livesList = const ['1', '2', '3', '4', '5'];
//   final _questionsList = const ['5', '10', '15', '20', '25'];

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final args = ModalRoute.of(context)?.settings.arguments as Map?;
//     quizId = (args?['quizId'] ?? '').toString();
//     _load();
//   }

//   @override
//   void dispose() {
//     _titleC.dispose();
//     _pointsC.dispose();
//     super.dispose();
//   }

//   // =================== Firestore I/O ===================

//   Future<void> _load() async {
//     if (quizId.isEmpty) {
//       setState(() => _loading = false);
//       return;
//     }
//     try {
//       final snap = await FirebaseFirestore.instance
//           .collection('quizzes')
//           .doc(quizId)
//           .get();

//       final data = snap.data();
//       if (data == null) {
//         setState(() => _loading = false);
//         return;
//       }

//       final preset = Map<String, dynamic>.from(data['preset'] ?? {});
//       _titleC.text = (data['quizTitle'] ?? '').toString();
//       _pointsC.text = (preset['points'] ?? 20).toString();

//       _difficulty = (preset['difficulty'] ?? 'All').toString();
//       _hints = (preset['hints'] ?? 'Enable').toString();
//       _timer = (preset['time'] ?? '10 Min').toString();
//       _lives = (preset['lives'] ?? 3).toString();
//       _questions = (preset['questions'] ?? 10).toString();

//       setState(() => _loading = false);
//     } catch (_) {
//       setState(() => _loading = false);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to load quiz.'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }

//   Future<void> _saveMeta() async {
//     if (_saving) return;
//     final app = Theme.of(context).extension<AppColors>()!;
//     final pts = int.tryParse(_pointsC.text.trim());
//     if (_titleC.text.trim().isEmpty ||
//         pts == null ||
//         _difficulty == null ||
//         _hints == null ||
//         _timer == null ||
//         _lives == null ||
//         _questions == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: app.error,
//           content: const Text('Please complete every field (points must be a number).'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }

//     setState(() => _saving = true);
//     try {
//       await FirebaseFirestore.instance.collection('quizzes').doc(quizId).update({
//         'quizTitle': _titleC.text.trim(),
//         'preset.difficulty': _difficulty,
//         'preset.points': pts,
//         'preset.hints': _hints,
//         'preset.lives': int.tryParse(_lives!) ?? 0,
//         'preset.questions': int.tryParse(_questions!) ?? 0,
//         'preset.time': _timer,
//       });
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Saved.'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Save failed: $e'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   Future<void> _confirmDelete() async {
//     final yes = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Delete Quiz'),
//         content: const Text('Are you sure you want to delete this Quiz?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
//           FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Delete')),
//         ],
//       ),
//     );
//     if (yes != true) return;

//     try {
//       await FirebaseFirestore.instance.collection('quizzes').doc(quizId).delete();
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Quiz deleted.'), behavior: SnackBarBehavior.floating),
//       );
//       Navigator.of(context).pop(); // back to list
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Delete failed: $e'), behavior: SnackBarBehavior.floating),
//       );
//     }
//   }

//   Future<void> _saveAndMoveToQuestions() async {
//     await _saveMeta();
//     // if (!mounted) return;
//     // // Navigate to your second screen (edit questions). Provide quizId.
//     // Navigator.pushNamed(
//     //   context,
//     //   '/edit-quiz-questions',
//     //   arguments: {'quizId': quizId},
//     // );
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const EditQuizQuestionsPage(),
//         settings: RouteSettings(arguments: {'quizId': quizId}),
//       ),
//     );
//   }

//   // =================== UI helpers ===================

//   Widget _tag(BuildContext context,
//       {required IconData icon, required String label, required Color bg, required Color fg}) {
//     return Container(
//       height: 36,
//       decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       alignment: Alignment.centerLeft,
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 18, color: fg),
//           const SizedBox(width: 8),
//           Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
//         ],
//       ),
//     );
//   }

//   Widget _outlinedField(BuildContext context, {required Widget child}) {
//     final app = Theme.of(context).extension<AppColors>()!;
//     return Container(
//       height: _fieldH,
//       decoration: BoxDecoration(
//         color: app.panelBg,
//         border: Border.all(color: app.borderStrong, width: _borderW),
//         borderRadius: BorderRadius.circular(_radius),
//       ),
//       alignment: Alignment.centerLeft,
//       child: child,
//     );
//   }

//   Widget _dropdown(
//     BuildContext context, {
//     required String? value,
//     required List<String> items,
//     required ValueChanged<String?> onChanged,
//   }) {
//     final app = Theme.of(context).extension<AppColors>()!;
//     final cs = Theme.of(context).colorScheme;
//     return _outlinedField(
//       context,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 14),
//         child: DropdownButton<String>(
//           isExpanded: true,
//           value: value,
//           underline: const SizedBox.shrink(),
//           icon: Icon(Icons.expand_more_rounded, size: 26, color: cs.onSurface.withOpacity(.75)),
//           items: items
//               .map((e) => DropdownMenuItem<String>(
//                     value: e,
//                     child: Text(
//                       e,
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
//                     ),
//                   ))
//               .toList(),
//           onChanged: onChanged,
//           dropdownColor: app.panelBg,
//           borderRadius: BorderRadius.circular(_radius),
//         ),
//       ),
//     );
//   }

//   TextStyle _labelStyle(BuildContext context) =>
//       TextStyle(color: Theme.of(context).extension<AppColors>()!.label, fontSize: 18, fontWeight: FontWeight.w800);

//   // =================== BUILD ===================

//   @override
//   Widget build(BuildContext context) {
//     final app = Theme.of(context).extension<AppColors>()!;
//     final cs = Theme.of(context).colorScheme;

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: AppBar(
//         backgroundColor: app.headerBg,
//         foregroundColor: app.headerFg,
//         elevation: 0,
//         title: const Text('Edit Quiz', style: TextStyle(fontWeight: FontWeight.w800)),
//         actions: const [Padding(padding: EdgeInsets.only(right: 10), child: CircleBackButton())],
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : SafeArea(
//               bottom: false,
//               child: ListView(
//                 padding: const EdgeInsets.fromLTRB(_pageHPad, 12, _pageHPad, 24),
//                 children: [
//                   // ====== Edit Quiz Title + Delete button row ======
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text('Edit Quiz Title', style: _labelStyle(context)),
//                             const SizedBox(height: 8),
//                             _outlinedField(
//                               context,
//                               child: TextField(
//                                 controller: _titleC,
//                                 decoration: InputDecoration(
//                                   hintText: 'Type Quiz Title Here',
//                                   hintStyle: TextStyle(color: app.hint, fontWeight: FontWeight.w600),
//                                   isCollapsed: true,
//                                   border: InputBorder.none,
//                                   contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//                                 ),
//                                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       // Delete circular button
//                       Material(
//                         color: app.actionBubbleBg,
//                         shape: const CircleBorder(),
//                         child: InkWell(
//                           customBorder: const CircleBorder(),
//                           onTap: _confirmDelete,
//                           child: const Padding(
//                             padding: EdgeInsets.all(12.0),
//                             child: Icon(Icons.delete_outline_rounded, size: 26, color: Color(0xFFD1646C)),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 22),

//                   // Row 1: Difficulty / Points
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _tag(context,
//                                 icon: Icons.local_fire_department,
//                                 label: 'Difficulty',
//                                 bg: app.tagDiffBg,
//                                 fg: app.tagDiffFg),
//                             const SizedBox(height: 8),
//                             _dropdown(context, value: _difficulty, items: _difficulties, onChanged: (v) {
//                               setState(() => _difficulty = v);
//                             }),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 14),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _tag(context, icon: Icons.bolt, label: 'Points', bg: app.tagPointsBg, fg: app.tagPointsFg),
//                             const SizedBox(height: 8),
//                             _outlinedField(
//                               context,
//                               child: TextField(
//                                 controller: _pointsC,
//                                 keyboardType: TextInputType.number,
//                                 decoration: const InputDecoration(
//                                   isCollapsed: true,
//                                   border: InputBorder.none,
//                                   contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//                                 ),
//                                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // Row 2: Hints / Timer
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _tag(context, icon: Icons.lightbulb_outline, label: 'Hints', bg: app.tagHintsBg, fg: app.tagHintsFg),
//                             const SizedBox(height: 8),
//                             _dropdown(context, value: _hints, items: _hintsList, onChanged: (v) {
//                               setState(() => _hints = v);
//                             }),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 14),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _tag(context, icon: Icons.alarm, label: 'Timer', bg: app.tagTimerBg, fg: app.tagTimerFg),
//                             const SizedBox(height: 8),
//                             _dropdown(context, value: _timer, items: _timers, onChanged: (v) {
//                               setState(() => _timer = v);
//                             }),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // Row 3: Lives / Questions
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _tag(context, icon: Icons.favorite_border, label: 'Lives', bg: app.tagLivesBg, fg: app.tagLivesFg),
//                             const SizedBox(height: 8),
//                             _dropdown(context, value: _lives, items: _livesList, onChanged: (v) {
//                               setState(() => _lives = v);
//                             }),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 14),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _tag(context, icon: Icons.error_outline, label: 'Questions', bg: app.tagQsBg, fg: app.tagQsFg),
//                             const SizedBox(height: 8),
//                             _dropdown(context, value: _questions, items: _questionsList, onChanged: (v) {
//                               setState(() => _questions = v);
//                             }),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 24),

//                   // CTA
//                   SizedBox(
//                     height: 56,
//                     child: ElevatedButton(
//                       onPressed: _saving ? null : _saveAndMoveToQuestions,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: app.ctaBlue,
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(18),
//                           side: BorderSide(color: app.ctaBlueBorder, width: 1.6),
//                         ),
//                         textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
//                       ),
//                       child: _saving
//                           ? const SizedBox(
//                               width: 22,
//                               height: 22,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2.6,
//                                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                               ),
//                             )
//                           : const Text('Move To the Questions'),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

//////////////////////////////////////////////////////

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import './EditQuizQuestionsPage.dart';
import '../../Theme/Themes.dart';
import '../../widgets/BackButtonWidget.dart'; // CircleBackButton

class ViewQuizPage extends StatefulWidget {
  const ViewQuizPage({super.key});

  @override
  State<ViewQuizPage> createState() => _ViewQuizPageState();
}

class _ViewQuizPageState extends State<ViewQuizPage> {
  // ---- layout tokens ----
  static const double _pageHPad = 20;
  static const double _fieldH = 56;
  static const double _radius = 16;
  static const double _borderW = 1.6;

  late String quizId;

  // controllers / state
  final _titleC = TextEditingController();
  final _pointsC = TextEditingController();

  String? _difficulty;
  String? _hints;
  String? _timer;
  String? _lives;
  String? _questions;

  bool _loading = true;
  bool _saving = false;

  // dropdown data
  final _difficulties = const ['Easy', 'Medium', 'Hard', 'All'];
  final _hintsList = const ['Enable', 'Disable'];
  final _timers = const ['10 Min', '15 Min', '20 Min', '30 Min', '45 Min'];
  final _livesList = const ['1', '2', '3', '4', '5'];
  final _questionsList = const ['5', '10', '15', '20', '25'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    quizId = (args?['quizId'] ?? '').toString();
    _load();
  }

  @override
  void dispose() {
    _titleC.dispose();
    _pointsC.dispose();
    super.dispose();
  }

  // =================== Firestore I/O ===================

  Future<void> _load() async {
    if (quizId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId)
          .get();

      final data = snap.data();
      if (data == null) {
        setState(() => _loading = false);
        return;
      }

      final preset = Map<String, dynamic>.from(data['preset'] ?? {});
      _titleC.text = (data['quizTitle'] ?? '').toString();
      _pointsC.text = (preset['points'] ?? 20).toString();

      _difficulty = (preset['difficulty'] ?? 'All').toString();
      _hints = (preset['hints'] ?? 'Enable').toString();
      _timer = (preset['time'] ?? '10 Min').toString();
      _lives = (preset['lives'] ?? 3).toString();

      // ✅ FIX: Prevent crash when Firestore preset.questions (like 19) not in dropdown options
      final presetQ = (preset['questions'] ?? 10).toString();
      _questions = _questionsList.contains(presetQ)
          ? presetQ
          : _questionsList.first;

      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load quiz.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveMeta() async {
    if (_saving) return;
    final app = Theme.of(context).extension<AppColors>()!;
    final pts = int.tryParse(_pointsC.text.trim());
    if (_titleC.text.trim().isEmpty ||
        pts == null ||
        _difficulty == null ||
        _hints == null ||
        _timer == null ||
        _lives == null ||
        _questions == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: app.error,
          content: const Text('Please complete every field (points must be a number).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('quizzes').doc(quizId).update({
        'quizTitle': _titleC.text.trim(),
        'preset.difficulty': _difficulty,
        'preset.points': pts,
        'preset.hints': _hints,
        'preset.lives': int.tryParse(_lives!) ?? 0,
        'preset.questions': int.tryParse(_questions!) ?? 0,
        'preset.time': _timer,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: const Text('Are you sure you want to delete this Quiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Delete')),
        ],
      ),
    );
    if (yes != true) return;

    try {
      await FirebaseFirestore.instance.collection('quizzes').doc(quizId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz deleted.'), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pop(); // back to list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _saveAndMoveToQuestions() async {
    await _saveMeta();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditQuizQuestionsPage(),
        settings: RouteSettings(arguments: {'quizId': quizId}),
      ),
    );
  }

  // =================== UI helpers ===================

  Widget _tag(BuildContext context,
      {required IconData icon, required String label, required Color bg, required Color fg}) {
    return Container(
      height: 36,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
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

  Widget _outlinedField(BuildContext context, {required Widget child}) {
    final app = Theme.of(context).extension<AppColors>()!;
    return Container(
      height: _fieldH,
      decoration: BoxDecoration(
        color: app.panelBg,
        border: Border.all(color: app.borderStrong, width: _borderW),
        borderRadius: BorderRadius.circular(_radius),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  Widget _dropdown(
    BuildContext context, {
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    return _outlinedField(
      context,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          underline: const SizedBox.shrink(),
          icon: Icon(Icons.expand_more_rounded, size: 26, color: cs.onSurface.withOpacity(.75)),
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(
                      e,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          dropdownColor: app.panelBg,
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context) =>
      TextStyle(color: Theme.of(context).extension<AppColors>()!.label, fontSize: 18, fontWeight: FontWeight.w800);

  // =================== BUILD ===================

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: app.headerBg,
        foregroundColor: app.headerFg,
        elevation: 0,
        title: const Text('Edit Quiz', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: const [Padding(padding: EdgeInsets.only(right: 10), child: CircleBackButton())],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(_pageHPad, 12, _pageHPad, 24),
                children: [
                  // ====== Edit Quiz Title + Delete button row ======
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit Quiz Title', style: _labelStyle(context)),
                            const SizedBox(height: 8),
                            _outlinedField(
                              context,
                              child: TextField(
                                controller: _titleC,
                                decoration: InputDecoration(
                                  hintText: 'Type Quiz Title Here',
                                  hintStyle: TextStyle(color: app.hint, fontWeight: FontWeight.w600),
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                ),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Delete circular button
                      Material(
                        color: app.actionBubbleBg,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _confirmDelete,
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Icon(Icons.delete_outline_rounded, size: 26, color: Color(0xFFD1646C)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Row 1: Difficulty / Points
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _tag(context,
                                icon: Icons.local_fire_department,
                                label: 'Difficulty',
                                bg: app.tagDiffBg,
                                fg: app.tagDiffFg),
                            const SizedBox(height: 8),
                            _dropdown(context, value: _difficulty, items: _difficulties, onChanged: (v) {
                              setState(() => _difficulty = v);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _tag(context, icon: Icons.bolt, label: 'Points', bg: app.tagPointsBg, fg: app.tagPointsFg),
                            const SizedBox(height: 8),
                            _outlinedField(
                              context,
                              child: TextField(
                                controller: _pointsC,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                ),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Row 2: Hints / Timer
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _tag(context,
                                icon: Icons.lightbulb_outline,
                                label: 'Hints',
                                bg: app.tagHintsBg,
                                fg: app.tagHintsFg),
                            const SizedBox(height: 8),
                            _dropdown(context, value: _hints, items: _hintsList, onChanged: (v) {
                              setState(() => _hints = v);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _tag(context, icon: Icons.alarm, label: 'Timer', bg: app.tagTimerBg, fg: app.tagTimerFg),
                            const SizedBox(height: 8),
                            _dropdown(context, value: _timer, items: _timers, onChanged: (v) {
                              setState(() => _timer = v);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Row 3: Lives / Questions
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _tag(context, icon: Icons.favorite_border, label: 'Lives', bg: app.tagLivesBg, fg: app.tagLivesFg),
                            const SizedBox(height: 8),
                            _dropdown(context, value: _lives, items: _livesList, onChanged: (v) {
                              setState(() => _lives = v);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _tag(context, icon: Icons.error_outline, label: 'Questions', bg: app.tagQsBg, fg: app.tagQsFg),
                            const SizedBox(height: 8),
                            _dropdown(context, value: _questions, items: _questionsList, onChanged: (v) {
                              setState(() => _questions = v);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // CTA
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveAndMoveToQuestions,
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
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Move To the Questions'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
