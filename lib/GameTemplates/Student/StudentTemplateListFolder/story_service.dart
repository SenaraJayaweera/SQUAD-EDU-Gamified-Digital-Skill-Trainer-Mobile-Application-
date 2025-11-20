import 'package:cloud_firestore/cloud_firestore.dart';
import 'TemplateItem.dart';
import 'package:flutter/material.dart';

class StoryService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getStoriesStream(String moduleId) {
    final collection = firestore.collection('stories');

    if (moduleId.isEmpty) {
      // Return an empty stream
      return Stream<QuerySnapshot>.fromIterable([]);
    }

    return collection.where('moduleId', isEqualTo: moduleId).snapshots();
  }

  List<TemplateItem> mapStories(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return TemplateItem(
        id: doc.id,
        type: TemplateType.story,
        title: data['title'] ?? 'Untitled Story',
        code: 'STORY${doc.id.substring(0, 4).toUpperCase()}',
        banner: 'assets/images/templates/story_banner.png',
        accent: const Color.fromRGBO(185, 245, 139, 1),
        description: data['description'] ?? 'No description',
        totalLessons: _calculateTotalLessons(data['content']),
        points: data['points'] ?? 0,
      );
    }).toList();
  }

  int _calculateTotalLessons(dynamic content) {
    if (content == null) return 0;
    if (content is List) return content.length;
    return 0;
  }
}
