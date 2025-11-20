import 'package:cloud_firestore/cloud_firestore.dart';
import 'TemplateItem.dart';
import 'package:flutter/material.dart';

class StoryService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getStoriesStream(String moduleId) {
    if (moduleId != 'Unknown') {
      return firestore
          .collection('stories')
          .where('moduleId', isEqualTo: moduleId)
          .snapshots();
    } else {
      return firestore.collection('stories').snapshots();
    }
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
        accent: const Color(0xFF51B9FF),
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
