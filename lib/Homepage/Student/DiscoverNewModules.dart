import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:async/async.dart'; // for StreamZip
import 'AppColors.dart';

class DiscoverNewModules extends StatefulWidget {
  const DiscoverNewModules({super.key});

  @override
  State<DiscoverNewModules> createState() => _DiscoverNewModulesState();
}

class _DiscoverNewModulesState extends State<DiscoverNewModules> {
  Set<String> enrolledIds = {};

  /// Fetch counts for a module: quizzes, puzzles (matching+sequence), stories
  Future<Map<String, int>> _getCounts(String moduleId) async {
    final firestore = FirebaseFirestore.instance;

    final quizzesSnap = await firestore
        .collection('quizzes')
        .where('moduleId', isEqualTo: moduleId)
        .get();

    final matchingSnap = await firestore
        .collection('matching_puzzles')
        .where('moduleId', isEqualTo: moduleId)
        .get();

    final sequenceSnap = await firestore
        .collection('sequence_puzzles')
        .where('moduleId', isEqualTo: moduleId)
        .get();

    final storiesSnap = await firestore
        .collection('stories')
        .where('moduleId', isEqualTo: moduleId)
        .get();

    final totalPuzzles = matchingSnap.docs.length + sequenceSnap.docs.length;

    return {
      'quizzes': quizzesSnap.docs.length,
      'puzzles': totalPuzzles,
      'stories': storiesSnap.docs.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    final modulesStream = FirebaseFirestore.instance
        .collection('modules')
        .snapshots();
    final enrolledStream = FirebaseFirestore.instance
        .collection('Student_to_Module_Enrollment')
        .doc(user.uid)
        .collection('modules')
        .snapshots();

    return StreamBuilder<List<QuerySnapshot>>(
      stream: StreamZip([modulesStream, enrolledStream]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allModules = snapshot.data![0].docs;
        final enrolledDocs = snapshot.data![1].docs;

        enrolledIds = enrolledDocs.map((e) => e.id).toSet();

        final newModules = allModules
            .where((m) => !enrolledIds.contains(m.id))
            .toList();

        if (newModules.isEmpty) {
          return const Center(child: Text("No new modules available"));
        }

        return SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: newModules.length,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemBuilder: (context, index) {
              final moduleDoc = newModules[index];
              final moduleData = moduleDoc.data() as Map<String, dynamic>;
              final moduleId = moduleDoc.id;

              return FutureBuilder<Map<String, int>>(
                future: _getCounts(moduleId),
                builder: (context, countsSnapshot) {
                  final counts =
                      countsSnapshot.data ??
                      {'quizzes': 0, 'puzzles': 0, 'stories': 0};

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: DiscoverModuleCard(
                      moduleId: moduleId,
                      moduleName: moduleData["title"] ?? "Untitled Module",
                      quizzes: counts['quizzes']!,
                      puzzles: counts['puzzles']!,
                      storyLessons: counts['stories']!,
                      rating: (moduleData["rating"] as num?)?.toDouble() ?? 0.0,
                      imageBase64: moduleData["iconBase64"],
                      onEnrolled: () {
                        setState(() {
                          enrolledIds.add(moduleId);
                        });
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class DiscoverModuleCard extends StatelessWidget {
  final String moduleId;
  final String moduleName;
  final int quizzes;
  final int puzzles;
  final int storyLessons;
  final double rating;
  final String? imageBase64;
  final VoidCallback? onEnrolled;

  const DiscoverModuleCard({
    required this.moduleId,
    required this.moduleName,
    required this.quizzes,
    required this.puzzles,
    required this.storyLessons,
    required this.rating,
    this.imageBase64,
    this.onEnrolled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>() ?? AppColors.fallback();

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: appColors.moduleIconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: imageBase64 != null
                  ? Image.memory(base64Decode(imageBase64!), fit: BoxFit.cover)
                  : Icon(Icons.auto_stories, color: appColors.moduleIconColor),
            ),
            const SizedBox(height: 10),
            Text(moduleName, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLessonCount(context, Icons.quiz, '$quizzes Quizzes'),
                  _buildLessonCount(
                    context,
                    Icons.extension,
                    '$puzzles Puzzles',
                  ),
                  _buildLessonCount(
                    context,
                    Icons.menu_book,
                    '$storyLessons Story Lessons',
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) throw "User not logged in";
                      final studentUid = user.uid;

                      final studentDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(studentUid)
                          .get();
                      final studentName =
                          studentDoc.data()?["name"] ?? "Student";

                      final moduleDoc = await FirebaseFirestore.instance
                          .collection('modules')
                          .doc(moduleId)
                          .get();
                      final teacherId = moduleDoc.data()?["teacherId"] ?? "";

                      final now = FieldValue.serverTimestamp();

                      await FirebaseFirestore.instance
                          .collection('Student_to_Module_Enrollment')
                          .doc(studentUid)
                          .collection('modules')
                          .doc(moduleId)
                          .set({
                            'moduleName': moduleName,
                            'teacherId': teacherId,
                            'enrolledAt': now,
                          });

                      await FirebaseFirestore.instance
                          .collection('Module_to_Student_Enrollment')
                          .doc(moduleId)
                          .collection('students')
                          .doc(studentUid)
                          .set({'studentName': studentName, 'enrolledAt': now});

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Enrolled in $moduleName')),
                      );

                      onEnrolled?.call();
                    } catch (e) {
                      debugPrint('Enrollment error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Enrollment failed: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: theme.colorScheme.onPrimary,
                    minimumSize: const Size(100, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Enroll'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCount(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface),
          const SizedBox(width: 4),
          Text(text, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
