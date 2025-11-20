import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../Theme/Themes.dart';

class QuizExplanationsPage extends StatefulWidget {
  const QuizExplanationsPage({super.key});

  @override
  State<QuizExplanationsPage> createState() => _QuizExplanationsPageState();
}

class _QuizExplanationsPageState extends State<QuizExplanationsPage> {
  String _quizId = '';
  String _runId  = '';

  bool _loading = true;

  // data
  late List<Map<String, dynamic>> _questions;
  late Map<int, String> _selectedByIndex; // index -> letter

  // pager
  int _i = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _quizId = args?['quizId']?.toString() ?? '';
    _runId  = args?['runId']?.toString()  ?? '';

    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // quiz
    final qDoc  = await FirebaseFirestore.instance.collection('quizzes').doc(_quizId).get();
    final qData = qDoc.data() ?? {};
    _questions = (qData['questions'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // run
    final rDoc  = await FirebaseFirestore.instance.collection('quiz_runs').doc(_runId).get();
    final rData = rDoc.data() ?? {};
    final answers = (rData['answers'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    _selectedByIndex = {
      for (final a in answers) (a['index'] ?? 0) as int : (a['selected'] ?? '').toString()
    };

    if (mounted) setState(() => _loading = false);
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
      padding: EdgeInsets.fromLTRB(20, top + 18, 20, 18),
      alignment: Alignment.center,
      child: Text(
        'Quiz Explanation',
        style: TextStyle(
          color: app.headerFg,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _option({
    required BuildContext context,
    required String letter,
    required String text,
    required bool isCorrect,
    required bool isSelectedWrong,
  }) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs  = Theme.of(context).colorScheme;

    // colors to match your mock
    final Color okFill  = const Color(0xFFC8F6AE); // soft green fill
    final Color badFill = const Color(0xFFFFB8B8); // soft red/pink fill
    final Color okBorder  = const Color(0xFF2E7D32);
    final Color badBorder = const Color(0xFFC62828);

    final Color bg   = isCorrect ? okFill : (isSelectedWrong ? badFill : app.panelBg);
    final Color br   = isCorrect ? okBorder : (isSelectedWrong ? badBorder : app.borderStrong);
    final double bw  = isCorrect || isSelectedWrong ? 2.0 : 1.6;

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: br, width: bw),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            '$letter. ',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 19,
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

  Widget _explanationBox(BuildContext context, String text) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs  = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: app.panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: app.borderStrong, width: 1.6),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Text(
        text,
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs  = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _header(context),

                  // page
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      children: [
                        // Q heading
                        Text(
                          'Question ${_i + 1}',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Question prompt card
                        Container(
                          decoration: BoxDecoration(
                            color: app.panelBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: app.borderStrong, width: 1.6),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Text(
                            (_questions[_i]['title'] ?? '').toString(),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // options styled like mock
                        ...(() {
                          final q = _questions[_i];
                          final idx = q['index'] ?? (_i + 1);
                          final selected = (_selectedByIndex[idx] ?? '').toString();
                          final choices = (q['choices'] as List)
                              .map((e) => Map<String, dynamic>.from(e))
                              .toList();
                          final correct = choices.firstWhere(
                            (c) => c['isCorrect'] == true,
                            orElse: () => <String, dynamic>{},
                          );
                          final correctLetter = (correct['letter'] ?? '').toString();

                          return choices.map((c) {
                            final letter = (c['letter'] ?? '').toString();
                            final text   = (c['text'] ?? '').toString();
                            final isCorrect = letter == correctLetter;
                            final isSelectedWrong = (letter == selected) && !isCorrect;

                            return _option(
                              context: context,
                              letter: letter,
                              text: text,
                              isCorrect: isCorrect,
                              isSelectedWrong: isSelectedWrong,
                            );
                          }).toList();
                        })(),

                        const SizedBox(height: 22),

                        // Answer Explanation title
                        Text(
                          'Answer Explanation',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _explanationBox(
                          context,
                          (_questions[_i]['explanation'] ?? '').toString(),
                        ),

                        const SizedBox(height: 26),

                        // NEXT / FINISH button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            // onPressed: () {
                            //   if (_i + 1 < _questions.length) {
                            //     setState(() => _i++);
                            //   } else {
                            //     // finished: go back to the first route (modules/home)
                            //     Navigator.of(context).popUntil((r) => r.isFirst);
                            //   }
                            // },

                            onPressed: () {
                              if (_i + 1 < _questions.length) {
                                setState(() => _i++);
                              } else {
                                // ✅ Navigate directly to StudentModuleList
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/StudentModuleList', // 👈 your route name
                                  (route) => false,     // clears previous routes
                                );
                              }
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: app.ctaBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(color: app.ctaBlueBorder, width: 1.6),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            child: Text(_i + 1 < _questions.length ? 'NEXT' : 'FINISH'),
                          ),
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
