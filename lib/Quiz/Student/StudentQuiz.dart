import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../Theme/Themes.dart';
import './AnswerToTheQuizPage.dart';

class StudentQuizPage extends StatefulWidget {
  const StudentQuizPage({super.key});

  @override
  State<StudentQuizPage> createState() => _StudentQuizPageState();
}

class _StudentQuizPageState extends State<StudentQuizPage> {
  String? _quizId;
  late Future<DocumentSnapshot<Map<String, dynamic>>> _future;

  Map<String, dynamic> _safeMap(dynamic v) =>
      v is Map<String, dynamic> ? v : <String, dynamic>{};
  String _str(dynamic v, {String fallback = ''}) => v?.toString() ?? fallback;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _quizId = args?['quizId']?.toString();
    _future = FirebaseFirestore.instance.collection('quizzes').doc(_quizId).get();
  }

  // ---------- UI bits ----------
  Widget _header(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        color: app.headerBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Get Ready For Quizz.....',
              style: TextStyle(
                color: app.headerFg,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Material(
            color: Colors.white.withOpacity(.08),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 22, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    double? width,
    EdgeInsets? padding,
  }) {
    return Container(
      height: 36,
      width: width,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _pillValue(BuildContext context, String value) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: app.panelBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: app.borderStrong, width: 1.6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        value,
        style: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _rulesPanel({
    required BuildContext context,
    required String time,
    required String attempts,
    required String hints,
    required String points,
  }) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: app.panelBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: app.borderStrong, width: 1.6),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        children: [
          Row(
            children: [
              _tag(
                icon: Icons.timer_outlined,
                label: 'Timer',
                bg: app.tagTimerBg,
                fg: app.tagTimerFg,
                width: 90,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(time,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 18)),
              ),
              _tag(
                icon: Icons.backup_table_outlined,
                label: 'Attempts',
                bg: app.tagRedBg,
                fg: app.tagRedFg,
                width: 110,
              ),
              const SizedBox(width: 12),
              Text(attempts,
                  style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _tag(
                icon: Icons.lightbulb_outline,
                label: 'Hints',
                bg: app.tagHintsBg,
                fg: app.tagHintsFg,
                width: 90,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(hints,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 18)),
              ),
              _tag(
                icon: Icons.bolt,
                label: 'Points',
                bg: app.tagPointsBg,
                fg: app.tagPointsFg,
                width: 100,
              ),
              const SizedBox(width: 14),
              Text(points,
                  style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndStart(String quizId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Quiz'),
        content: const Text(
            'Are you sure you want to attempt this quiz? There is no going back.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Start')),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AnswerToTheQuizPage(),
          settings: RouteSettings(arguments: {'quizId': quizId}),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snap.hasData || !(snap.data?.exists ?? false)) {
                    return const Center(child: Text('Quiz not found.'));
                  }

                  final data = snap.data!.data()!;
                  final preset = _safeMap(data['preset']);
                  final quizTitle = _str(data['quizTitle'], fallback: 'Quiz');
                  final difficulty = _str(preset['difficulty'], fallback: 'All');
                  final time = _str(preset['time'], fallback: '10 Min');
                  final points = _str(preset['points'] ?? 0);
                  final attempts = _str(data['attempts'] ?? 1);
                  final hints = _str(preset['hints'], fallback: 'Enable');

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: _tag(
                          icon: Icons.event_note_outlined,
                          label: 'Quiz Title',
                          bg: app.tagPurpleBg,
                          fg: app.tagPurpleFg,
                          width: 110,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        quizTitle,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),

                      Align(
                        alignment: Alignment.topLeft,
                        child: _tag(
                          icon: Icons.local_fire_department,
                          label: 'Difficulty',
                          bg: app.tagDiffBg,
                          fg: app.tagDiffFg,
                          width: 120,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _pillValue(context, difficulty),
                      const SizedBox(height: 18),

                      Align(
                        alignment: Alignment.topLeft,
                        child: _tag(
                          icon: Icons.balance_outlined,
                          label: 'Rules',
                          bg: app.tagPurpleBg,
                          fg: app.tagPurpleFg,
                          width: 90,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _rulesPanel(
                        context: context,
                        time: time,
                        attempts: attempts,
                        hints: hints,
                        points: points,
                      ),

                      const SizedBox(height: 22),
                      Text(
                        'Pro tip:-  Please Pay attention to the quiz rules',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _quizId == null ? null : () => _confirmAndStart(_quizId!),
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
                          child: const Text("Start the Quiz"),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
