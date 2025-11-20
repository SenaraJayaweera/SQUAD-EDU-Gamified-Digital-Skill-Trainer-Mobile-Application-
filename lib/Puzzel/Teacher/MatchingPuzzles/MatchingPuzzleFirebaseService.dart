
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../PuzzleData.dart';

class MatchingPuzzleFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload matching puzzle data to Firebase
  /// Stores creator info and preserves pairs correctly
  Future<void> uploadSequencePuzzle(MatchingPuzzleData puzzleData) async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not signed in');

      // Fetch additional user data from "users" collection
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) throw Exception('User data not found');

      final createdBy = {
        'uid': user.uid,
        'firstName': userData['firstName'] ?? '',
        'lastName': userData['lastName'] ?? '',
      };

      // Add puzzle document
      final docRef = await _firestore.collection('matching_puzzles').add({
        'moduleId': puzzleData.moduleId,
        'moduleTitle': puzzleData.moduleTitle,
        'puzzleName': puzzleData.puzzleName,
        'puzzleDescription': puzzleData.puzzleDescription,
        'selectedPuzzleType': puzzleData.selectedPuzzleType,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add each question
      final questionsRef = docRef.collection('questions');
      for (int qIndex = 0; qIndex < puzzleData.questions.length; qIndex++) {
        final question = puzzleData.questions[qIndex];

        final questionDoc = await questionsRef.add({
          'order': qIndex + 1,
          'instructions': question.instructionsController.text,
          'leftColumnTitle':
              question.leftColumnTitleController.text.isEmpty
                  ? 'N/A'
                  : question.leftColumnTitleController.text,
          'rightColumnTitle':
              question.rightColumnTitleController.text.isEmpty
                  ? 'N/A'
                  : question.rightColumnTitleController.text,
        });

        // Add pairs under each question
        final pairsRef = questionDoc.collection('pairs');
        for (int pIndex = 0; pIndex < question.puzzlePairs.length; pIndex++) {
          final pair = question.puzzlePairs[pIndex];
          await pairsRef.add({
            'order': pIndex + 1,
            'left': pair.left.isEmpty ? '-' : pair.left,
            'right': pair.right.isEmpty ? '-' : pair.right,
          });
        }
      }

      print(' Matching puzzle uploaded successfully!');
    } catch (e) {
      print(' Error uploading matching puzzle: $e');
      rethrow;
    }
  }
}
