import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SequencePuzzleSubmitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Saves the sequence puzzle summary for a student
  Future<void> saveSummary({
    required String puzzleId,
    required int correctCount,
    required int totalItems,
    required DateTime submittedAt,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No student is logged in.");

    final studentId = user.uid;

    final summaryData = {
      'correctCount': correctCount,
      'totalItems': totalItems,
      'score': totalItems == 0 ? 0 : correctCount / totalItems,
      'submittedAt': submittedAt,
    };

    await _firestore
        .collection('studentSequenceSummary')
        .doc(studentId)
        .collection('puzzles')
        .doc(puzzleId)
        .collection('attempts')
        .add(summaryData);
  }
}
