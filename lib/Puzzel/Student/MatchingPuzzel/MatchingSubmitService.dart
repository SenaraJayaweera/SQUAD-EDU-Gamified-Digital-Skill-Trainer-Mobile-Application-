import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubmitMatchingSummaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveSummary({
    required String puzzleId,
    required int correctCount,
    required int totalPairs,
    required DateTime submittedAt,
  }) async {
    try {
      // Get the currently logged-in student
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("No student is logged in.");
      }

      final studentId = user.uid;

      // Each student's puzzle attempts stored separately
      final attemptData = {
        'correctCount': correctCount,
        'totalPairs': totalPairs,
        'score': totalPairs == 0 ? 0 : correctCount / totalPairs,
        'submittedAt': submittedAt,
      };

      await _firestore
          .collection('studentPuzzleSummary')
          .doc(studentId)
          .collection('puzzles')
          .doc(puzzleId)
          .collection('attempts')
          .add(attemptData);
    } catch (e) {
      throw Exception('Error saving puzzle summary: $e');
    }
  }
}
