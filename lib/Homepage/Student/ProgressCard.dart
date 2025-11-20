import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressCard extends StatefulWidget {
  final ThemeData theme;

  const ProgressCard({required this.theme, super.key});

  @override
  State<ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<ProgressCard> {
  int totalQuizScore = 0;
  int totalStoryPoints = 0;
  bool isLoading = true;

  String? userId;

  @override
  void initState() {
    super.initState();
    _initUserAndFetchCounts();
  }

  Future<void> _initUserAndFetchCounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      await _fetchProgressCounts();
    } else {
      debugPrint('No user is currently logged in.');
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchProgressCounts() async {
    try {
      // 1️⃣ Total quiz score
      int quizScore = 0;
      if (userId != null) {
        final quizSnapshot = await FirebaseFirestore.instance
            .collection('quiz_runs')
            .where('userId', isEqualTo: userId)
            .get();

        for (var doc in quizSnapshot.docs) {
          final score = (doc.data()['score'] as num?)?.toInt() ?? 0;
          quizScore += score;
          debugPrint('Quiz ${doc.id} score: $score');
        }
      }

      // 2️⃣ Total story points
      int storyPoints = 0;
      if (userId != null) {
        final storyDoc = await FirebaseFirestore.instance
            .collection('storyProgress')
            .doc(userId)
            .get();

        if (storyDoc.exists) {
          final storiesMap = storyDoc.data();
          storiesMap?.forEach((storyId, storyData) {
            final points = (storyData['points'] as num?)?.toInt() ?? 0;
            storyPoints += points;
            debugPrint('Story $storyId points: $points');
          });
        }
      }

      setState(() {
        totalQuizScore = quizScore;
        totalStoryPoints = storyPoints;
        isLoading = false;
      });

      debugPrint('FINAL: Quiz=$totalQuizScore, Story=$totalStoryPoints');
    } catch (e) {
      debugPrint('Error fetching progress counts: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _debugFirestoreStructure() async {
    debugPrint('\n🔥 FIREBASE CONSOLE STRUCTURE CHECK 🔥');
    debugPrint('Please check your Firebase Console for this structure:');
    debugPrint('');
    debugPrint('quiz_runs/');
    debugPrint('  └── [runId] (userId, score, etc)');
    debugPrint('');
    debugPrint('storyProgress/');
    debugPrint('  └── $userId/');
    debugPrint('      └── [storyId] (points, progress, etc)');
    debugPrint('');
    debugPrint(
      'If the structure is different, adjust the queries accordingly.',
    );
  }

  Future<void> refreshProgress() async {
    setState(() => isLoading = true);
    await _fetchProgressCounts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart,
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Progress at',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
                  onPressed: refreshProgress,
                  tooltip: 'Refresh Progress',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _ProgressItem(
                    value: '$totalQuizScore',
                    label: 'Total Quiz Score',
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                _divider(theme),
                Expanded(
                  child: _ProgressItem(
                    value: '$totalStoryPoints',
                    label: 'Total Story Lessons',
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Container(
      width: 1,
      height: 60,
      color: theme.colorScheme.onPrimary.withOpacity(0.3),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ProgressItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
        ),
      ],
    );
  }
}
