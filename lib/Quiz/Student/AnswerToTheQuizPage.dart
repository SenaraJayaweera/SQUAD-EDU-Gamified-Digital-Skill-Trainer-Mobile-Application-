// lib/Quiz/Student/AnswerToTheQuizPage.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../Theme/Themes.dart';
import './QuizSummaryPage.dart';

class AnswerToTheQuizPage extends StatefulWidget {
  const AnswerToTheQuizPage({super.key});

  @override
  State<AnswerToTheQuizPage> createState() => _AnswerToTheQuizPageState();
}

class _AnswerToTheQuizPageState extends State<AnswerToTheQuizPage> {
  // ---- Route / data ----
  String _quizId = '';
  String _runId = '';
  String _userId = '';

  Map<String, dynamic> _quiz = {};
  Map<String, dynamic> _preset = {};
  List<Map<String, dynamic>> _questions = [];
  int _attemptsAllowed = 1;

  // ---- Progress ----
  int _index = 0;
  bool _loading = true;
  bool _creatingRun = true;

  // ---- Timer ----
  int _timeAllowedSec = 0;
  int _remainingSec = 0;
  Timer? _tick;
  bool _paused = false;

  // per-question timing
  int _qStartMs = DateTime.now().millisecondsSinceEpoch;

  // selection map: questionIndex(int) -> 'A'|'B'|'C'|'D'
  final Map<int, String> _selectedLetterByIndex = {};

  // difficulty gates
  String get _difficulty => (_preset['difficulty'] ?? 'All').toString();
  bool get _isEasy => _difficulty.toLowerCase() == 'easy';
  bool get _isMedium => _difficulty.toLowerCase() == 'medium';
  bool get _isHard => _difficulty.toLowerCase() == 'hard';
  bool get _hintsEnabled =>
      (_preset['hints'] ?? 'Enable').toString().toLowerCase() == 'enable';

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  // ---------- Load ----------
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _quizId = args?['quizId']?.toString() ?? '';
    if (_quizId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing quizId.')),
        );
        Navigator.pop(context);
      });
      return;
    }
    _load();
  }

  int _parseMinutes(String s) {
    final digits = RegExp(r'\d+').firstMatch(s)?.group(0);
    return int.tryParse(digits ?? '10') ?? 10;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(_quizId)
          .get();

      if (!doc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz not found.')),
        );
        Navigator.pop(context);
        return;
      }

      _quiz = doc.data()!;
      _preset = (_quiz['preset'] ?? <String, dynamic>{})
          .cast<String, dynamic>();
      _questions = ((_quiz['questions'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _attemptsAllowed = (_quiz['attempts'] ?? 1) is int ? _quiz['attempts'] : 1;

      final minutes = _parseMinutes((_preset['time'] ?? '10 Min').toString());
      _timeAllowedSec = minutes * 60;
      _remainingSec = _timeAllowedSec;

      await _enforceAttemptsAndCreateRun();
      _startTimer();

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load quiz: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _enforceAttemptsAndCreateRun() async {
    final runsSnap = await FirebaseFirestore.instance
        .collection('quiz_runs')
        .where('quizId', isEqualTo: _quizId)
        .where('userId', isEqualTo: _userId)
        .where('status', isEqualTo: 'completed')
        .get();

    if (runsSnap.docs.length >= _attemptsAllowed) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Attempts exhausted'),
          content: Text(
              'You have already used all $_attemptsAllowed attempts for this quiz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      Navigator.pop(context);
      return;
    }

    // create run
    final now = Timestamp.now();
    final runRef =
        await FirebaseFirestore.instance.collection('quiz_runs').add({
      'quizId': _quizId,
      'userId': _userId,
      'attemptNo': runsSnap.docs.length + 1,
      'status': 'in_progress',
      'startedAt': now,
      'completedAt': null,
      'timeAllowedSec': _timeAllowedSec,
      'timeTakenMs': 0,
      'pointsPerQuestion':
          (_preset['points'] ?? 0) is int ? _preset['points'] : 0,
      'score': 0,
      'correctCount': 0,
      'wrongCount': 0,
      'answers': [],
    });

    _runId = runRef.id;
    _creatingRun = false;
    _qStartMs = DateTime.now().millisecondsSinceEpoch;
  }

  void _startTimer() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_paused) return;
      if (_remainingSec <= 0) {
        _onSubmit(auto: true);
        return;
      }
      setState(() => _remainingSec--);
    });
  }

  void _togglePause() {
    if (!_isEasy) return;
    setState(() => _paused = !_paused);
  }

  // ---------- Computed ----------
  double get _progressFraction {
    if (_timeAllowedSec <= 0) return 0;
    return _remainingSec / _timeAllowedSec;
  }

  String get _mmss {
    final m = (_remainingSec ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---------- Submit / next ----------
  void _attachTimeToCurrent(int deltaMs) {
    final idx = _questions[_index]['index'] ?? (_index + 1);
    final key = '_time_$idx';
    _questions[_index][key] =
        ((_questions[_index][key] ?? 0) as int) + deltaMs;
  }

  Future<void> _onNextOrSubmit() async {
    if (_index + 1 < _questions.length) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final delta = now - _qStartMs;
      _attachTimeToCurrent(delta);
      setState(() {
        _index++;
        _qStartMs = DateTime.now().millisecondsSinceEpoch;
      });
    } else {
      await _onSubmit();
    }
  }

  Future<void> _onSubmit({bool auto = false}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final delta = now - _qStartMs;
    _attachTimeToCurrent(delta);

    _tick?.cancel();

    final answers = <Map<String, dynamic>>[];
    int correct = 0;

    for (final q in _questions) {
      final qIdx = q['index'] ?? 0;
      final selected = _selectedLetterByIndex[qIdx];

      final choices =
          (q['choices'] as List).cast<Map<String, dynamic>>();
      final corr = choices.firstWhere((c) => c['isCorrect'] == true,
          orElse: () => <String, dynamic>{});
      final corrLetter = (corr['letter'] ?? '').toString();

      final isC = selected != null && selected == corrLetter;
      if (isC) correct++;

      final timeSpent = (q['_time_$qIdx'] ?? 0) as int;

      answers.add({
        'index': qIdx,
        'selected': selected,
        'correctLetter': corrLetter,
        'isCorrect': isC,
        'timeSpentMs': timeSpent,
      });
    }

    final wrong = _questions.length - correct;
    final pointsPerQ =
        (_preset['points'] ?? 0) is int ? _preset['points'] : 0;
    final score = correct * pointsPerQ;
    final timeTakenMs = (_timeAllowedSec - _remainingSec) * 1000;

    try {
      await FirebaseFirestore.instance
          .collection('quiz_runs')
          .doc(_runId)
          .update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
        'timeTakenMs': timeTakenMs,
        'score': score,
        'correctCount': correct,
        'wrongCount': wrong,
        'answers': answers,
      });
    } catch (_) {
      // let navigation continue even if offline; sync later
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const QuizSummaryPage(),
        settings: RouteSettings(
          arguments: {'quizId': _quizId, 'runId': _runId},
        ),
      ),
    );
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
              'Time Remaining',
              style: TextStyle(
                color: app.headerFg,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // back
          Material(
            color: Colors.white.withOpacity(.08),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // big 4 boxes MM:SS for Easy only
  Widget _digitBoxes(BuildContext context) {
    if (!_isEasy) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final digits = _mmss.replaceAll(':', '').split('');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        return Container(
          width: 68,
          height: 62,
          margin: EdgeInsets.only(right: i == 3 ? 0 : 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: cs.onSurface.withOpacity(.2), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            digits[i],
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 25,
              letterSpacing: 1.0,
            ),
          ),
        );
      }),
    );
  }

  // pill progress (green -> red when <30%)
  Widget _pillProgress(BuildContext context) {
    if (_isHard) return const SizedBox.shrink();
    final active =
        _progressFraction <= 0.3 ? const Color(0xFFE74C3C) : const Color(0xFF7AC943);
    const bg = Color(0xFFD9D9D9);

    return LayoutBuilder(builder: (ctx, c) {
      final w = c.maxWidth;
      final filled = (w * _progressFraction).clamp(0, w);
      return SizedBox(
        height: 14,
        child: Stack(
          children: [
            // bg
            Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            // fg
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: filled.toDouble(),
              decoration: BoxDecoration(
                color: active,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      );
    });
  }

  // option tile
  Widget _optionTile({
    required String letter,
    required String text,
    required bool selected,
  }) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: selected ? app.ctaBlue.withOpacity(.12) : app.panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? app.ctaBlue : app.borderStrong,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            '$letter. ',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHint() {
    if (!_hintsEnabled) return;
    final q = _questions[_index];
    final hint = (q['hint'] ?? '').toString().trim();
    if (hint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hint for this question.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF334654),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Hint !!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1.4,
                  color: Colors.white.withOpacity(.25),
                ),
                const SizedBox(height: 18),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  width: 160,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD9534F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('EXIT'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _isEasy
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
              child: FloatingActionButton(
                onPressed: _togglePause,
                backgroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                child: Icon(
                  _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 36,
                  color: Colors.black,
                ),
              ),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: _loading || _creatingRun
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _header(context),

                  // Content
                  Expanded(
                    child: ListView(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        // Easy: digits + bar | Medium: bar only
                        if (_isEasy) ...[
                          const SizedBox(height: 8),
                          _digitBoxes(context),
                          const SizedBox(height: 14),
                          _pillProgress(context),
                        ] else if (_isMedium) ...[
                          const SizedBox(height: 8),
                          _pillProgress(context),
                        ],

                        const SizedBox(height: 24),

                        // Question heading
                        Text(
                          'Question ${_index + 1} Out Of ${_questions.length}',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Question card
                        Container(
                          decoration: BoxDecoration(
                            color: app.panelBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: app.borderStrong,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Text(
                            (_questions[_index]['title'] ?? '').toString(),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Options
                        ...((_questions[_index]['choices'] as List)
                                .cast<Map<String, dynamic>>())
                            .map((c) {
                          final letter = (c['letter'] ?? '').toString();
                          final text = (c['text'] ?? '').toString();
                          final qIdx =
                              _questions[_index]['index'] ?? (_index + 1);
                          final selected =
                              _selectedLetterByIndex[qIdx] == letter;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                setState(() {
                                  _selectedLetterByIndex[qIdx] = letter;
                                });
                              },
                              child: _optionTile(
                                letter: letter,
                                text: text,
                                selected: selected,
                              ),
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 12),

                        // Bottom buttons
                        Row(
                          children: [
                            // Hint button (left) if enabled
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    _hintsEnabled ? _showHint : null,
                                style: OutlinedButton.styleFrom(
                                  minimumSize:
                                      const Size.fromHeight(52),
                                  foregroundColor:
                                      cs.onSurface.withOpacity(.9),
                                  side: BorderSide(
                                    color: app.borderStrong,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                  backgroundColor:
                                      const Color(0xFFE5E5E5),
                                ),
                                child: const Text('Hint ?'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Next / Submit (right)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _onNextOrSubmit,
                                style: ElevatedButton.styleFrom(
                                  minimumSize:
                                      const Size.fromHeight(52),
                                  backgroundColor: app.ctaBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                child: Text(
                                  _index + 1 == _questions.length
                                      ? 'SUBMIT'
                                      : 'NEXT',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
