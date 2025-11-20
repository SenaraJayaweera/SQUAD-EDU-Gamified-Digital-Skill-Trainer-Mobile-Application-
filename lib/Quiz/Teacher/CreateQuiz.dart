// lib/Quiz/Teacher/CreateQuiz.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/BackButtonWidget.dart';        // CircleBackButton
import '../../Theme/Themes.dart';
import './QuizPreviewPage.dart';
import './quiz_models.dart' as qm;                   // PublishPreset & question models

class QuizCreationPage extends StatefulWidget {
  const QuizCreationPage({super.key});

  @override
  State<QuizCreationPage> createState() => _QuizCreationPageState();
}

class _QuizCreationPageState extends State<QuizCreationPage> {
  // layout tokens
  static const double _pageHPad = 20;
  static const double _fieldH = 56;
  static const double _radius = 16;
  static const double _borderW = 1.6;

  // inputs
  final _titleC = TextEditingController();
  final _pointsC = TextEditingController(text: '20');

  String? _difficulty = 'Medium';
  String? _hints = 'Enable';
  String? _timer = '10 Min';
  String? _lives = '3';
  String? _questions = '10';

  bool _busy = false;

  // dropdown data
  final _difficulties = const ['Easy', 'Medium', 'Hard'];
  final _hintsList = const ['Enable', 'Disable'];
  final _timers = const ['10 Min', '15 Min', '20 Min', '30 Min', '45 Min'];
  final _livesList = const ['1', '2', '3', '4'];
  final _questionsList = const ['5', '10', '15', '20'];

  @override
  void dispose() {
    _titleC.dispose();
    _pointsC.dispose();
    super.dispose();
  }

  bool get _valid {
    final pts = int.tryParse(_pointsC.text.trim());
    return _titleC.text.trim().isNotEmpty &&
        _difficulty != null &&
        _hints != null &&
        _timer != null &&
        _lives != null &&
        _questions != null &&
        pts != null &&
        pts > 0;
  }

  // ---------- small tag chip ----------
  Widget _tag(BuildContext context,
      {required IconData icon,
      required String label,
      required Color bg,
      required Color fg}) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
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

  // ---------- outlined field shell ----------
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
          icon: Icon(Icons.expand_more_rounded,
              size: 26, color: cs.onSurface.withOpacity(.75)),
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(
                      e,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
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

  TextStyle _labelStyle(BuildContext context) => TextStyle(
        color: Theme.of(context).extension<AppColors>()!.label,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      );

  // ---------- preset to pass forward ----------
  qm.PublishPreset _buildPreset() {
    return qm.PublishPreset(
      difficulty: _difficulty ?? 'All',
      points: int.tryParse(_pointsC.text.trim()) ?? 0,
      hints: _hints ?? 'Enable',
      lives: int.tryParse(_lives ?? '0') ?? 0,
      questions: int.tryParse(_questions ?? '0') ?? 0,
      time: _timer ?? '10 Min',
    );
  }

  // ---------- placeholder questions (Quiz title NOT reused) ----------
  List<qm.QuizQuestion> _buildQuestions(int count) {
    List<qm.QuizChoice> choices() => [
          qm.QuizChoice(letter: 'A', text: 'Option A', isCorrect: false),
          qm.QuizChoice(letter: 'B', text: 'Option B', isCorrect: true),
          qm.QuizChoice(letter: 'C', text: 'Option C', isCorrect: false),
          qm.QuizChoice(letter: 'D', text: 'Option D', isCorrect: false),
        ];

    return List.generate(count, (i) {
      final idx = i + 1;
      return qm.QuizQuestion(
        index: idx,
        title: 'Question $idx',
        hint: 'Type Hint Here',
        explanation: 'Type Explanation Here',
        choices: choices(),
      );
    });
  }

  Future<void> _onSetup() async {
    if (_busy) return;
    if (!_valid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please complete every field.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _busy = true);

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final moduleId = args?['moduleId']?.toString() ?? 'Unknown';
    final moduleTitle = args?['moduleTitle']?.toString() ?? 'Untitled Module';
    final count = int.tryParse(_questions ?? '10') ?? 10;

    final preset = _buildPreset();
    final questions = _buildQuestions(count);

    if (!mounted) return;
    setState(() => _busy = false);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPreviewPage(questions: questions, preset: preset),
        settings: RouteSettings(arguments: {
          'moduleId': moduleId,
          'moduleTitle': moduleTitle,
          'quizTitle': _titleC.text.trim(),
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final moduleTitle = args?['moduleTitle']?.toString() ?? 'Setup the Quiz';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(_pageHPad, 12, _pageHPad, 24),
          children: [
            // ===== Top row (white) with title + your back button =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    moduleTitle, // “Setup the Quiz” or module name from args
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const CircleBackButton(),
              ],
            ),

            const SizedBox(height: 18),

            // Quiz Title
            Text('Quiz Title', style: _labelStyle(context)),
            const SizedBox(height: 8),
            _outlinedField(
              context,
              child: TextField(
                controller: _titleC,
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                decoration: InputDecoration(
                  hintText: 'Type Quiz Title Here',
                  hintStyle: TextStyle(
                    color: app.hint,
                    fontWeight: FontWeight.w600,
                  ),
                  isCollapsed: true,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
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
                      _dropdown(context,
                          value: _difficulty,
                          items: _difficulties,
                          onChanged: (v) => setState(() => _difficulty = v)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tag(context,
                          icon: Icons.bolt,
                          label: 'Points',
                          bg: app.tagPointsBg,
                          fg: app.tagPointsFg),
                      const SizedBox(height: 8),
                      _outlinedField(
                        context,
                        child: TextField(
                          controller: _pointsC,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3)
                          ],
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
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
                      _dropdown(context,
                          value: _hints,
                          items: _hintsList,
                          onChanged: (v) => setState(() => _hints = v)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tag(context,
                          icon: Icons.alarm,
                          label: 'Timer',
                          bg: app.tagTimerBg,
                          fg: app.tagTimerFg),
                      const SizedBox(height: 8),
                      _dropdown(context,
                          value: _timer,
                          items: _timers,
                          onChanged: (v) => setState(() => _timer = v)),
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
                      _tag(context,
                          icon: Icons.favorite_border,
                          label: 'Lives',
                          bg: app.tagLivesBg,
                          fg: app.tagLivesFg),
                      const SizedBox(height: 8),
                      _dropdown(context,
                          value: _lives,
                          items: _livesList,
                          onChanged: (v) => setState(() => _lives = v)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tag(context,
                          icon: Icons.error_outline,
                          label: 'Questions',
                          bg: app.tagQsBg,
                          fg: app.tagQsFg),
                      const SizedBox(height: 8),
                      _dropdown(context,
                          value: _questions,
                          items: _questionsList,
                          onChanged: (v) => setState(() => _questions = v)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // CTA
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _onSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: app.ctaBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: app.ctaBlueBorder, width: 1.6),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('SETUP THE QUIZ'),
              ),
            ),

            const SizedBox(height: 18),
            Text(
              'Preview…',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
