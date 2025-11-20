// lib/Teacher/Templates/quiz_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'TemplateItem.dart';

class QuizService {
  final CollectionReference _quizCollection = FirebaseFirestore.instance
      .collection('quizzes');

  Stream<List<TemplateItem>> getAllQuizzes(String moduleId) {
    return _quizCollection
        .where('moduleId', isEqualTo: moduleId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final preset = data['preset'] ?? {};
            final points = preset['points'] is int
                ? preset['points']
                : int.tryParse(preset['points']?.toString() ?? '') ?? 0;

            return TemplateItem(
              id: doc.id,
              type: TemplateType.quiz,
              title: data['quizTitle'] ?? 'Untitled Quiz',
              code: data['moduleId'] ?? '',
              banner: 'assets/images/templates/quizz_banner.png',
              accent: const Color.fromRGBO(185, 245, 139, 1),
              description: 'Difficulty: ${preset['difficulty'] ?? 'N/A'}',
              totalLessons: (data['questions'] as List?)?.length ?? 0,
              points: points,
            );
          }).toList(),
        );
  }
}
