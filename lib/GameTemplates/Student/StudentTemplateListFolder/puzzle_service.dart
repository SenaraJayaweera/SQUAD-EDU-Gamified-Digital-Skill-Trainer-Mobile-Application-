import 'package:cloud_firestore/cloud_firestore.dart';
import 'TemplateItem.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class PuzzleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of matching puzzles as List<TemplateItem>
  Stream<List<TemplateItem>> getMatchingPuzzlesItems(String moduleId) {
    return _firestore
        .collection('matching_puzzles')
        .where('moduleId', isEqualTo: moduleId)
        .snapshots()
        .map(mapPuzzles); // Map QuerySnapshot -> List<TemplateItem>
  }

  /// Stream of sequence puzzles as List<TemplateItem>
  Stream<List<TemplateItem>> getSequencePuzzlesItems(String moduleId) {
    return _firestore
        .collection('sequence_puzzles')
        .where('moduleId', isEqualTo: moduleId)
        .snapshots()
        .map(mapPuzzles);
  }

  /// Combined stream of all puzzles
  Stream<List<TemplateItem>> getAllPuzzles(String moduleId) {
    final matchingStream = getMatchingPuzzlesItems(moduleId);
    final sequenceStream = getSequencePuzzlesItems(moduleId);

    return Rx.combineLatest2<
      List<TemplateItem>,
      List<TemplateItem>,
      List<TemplateItem>
    >(
      matchingStream,
      sequenceStream,
      (matching, sequence) => [...matching, ...sequence],
    );
  }

  /// Convert QuerySnapshot -> List<TemplateItem>
  List<TemplateItem> mapPuzzles(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final collection = doc.reference.parent.id;

      final type = collection == 'matching_puzzles'
          ? TemplateType.matching_puzzle
          : TemplateType.sequence_puzzle;

      return TemplateItem(
        id: doc.id,
        type: type,
        title: data['puzzleName'] ?? 'Untitled Puzzle',
        code: data['code'] ?? '',
        banner: data['banner'] ?? 'assets/images/templates/puzzles_banner.png',
        accent: const Color.fromRGBO(185, 245, 139, 1),
        description: data['puzzleDescription'] ?? 'No description',
      );
    }).toList();
  }
}
