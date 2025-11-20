import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../PuzzleData.dart';

class SequencePuzzleFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload sequence puzzle data to Firebase (with correct order)
  /// Also stores the creator's uid, firstName, and lastName
  Future<void> uploadSequencePuzzle(SequencePuzzleData puzzleData) async {
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

      // Create a document reference inside your puzzles collection
      final docRef = await _firestore.collection('sequence_puzzles').add({
        'moduleId': puzzleData.moduleId,
        'moduleTitle': puzzleData.moduleTitle,
        'puzzleName': puzzleData.puzzleName,
        'puzzleDescription': puzzleData.puzzleDescription,
        'selectedPuzzleType': puzzleData.selectedPuzzleType,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add each question in correct order
      final questionsRef = docRef.collection('questions');
      for (int qIndex = 0; qIndex < puzzleData.questions.length; qIndex++) {
        final question = puzzleData.questions[qIndex];
        final questionDoc = await questionsRef.add({
          'order': qIndex + 1, // keep question order
          'instructions': question.instructionsController.text,
        });

        // Add sequence items (inputs) under each question
        final inputsRef = questionDoc.collection('sequence_inputs');
        for (
          int sIndex = 0;
          sIndex < question.sequenceInputs.length;
          sIndex++
        ) {
          final input = question.sequenceInputs[sIndex];
          await inputsRef.add({
            'order': sIndex + 1, // correct sequence order
            'value': input.controller.text,
          });
        }
      }

      print('✅ Puzzle uploaded successfully!');
    } catch (e) {
      print('❌ Error uploading puzzle: $e');
      rethrow;
    }
  }
}
