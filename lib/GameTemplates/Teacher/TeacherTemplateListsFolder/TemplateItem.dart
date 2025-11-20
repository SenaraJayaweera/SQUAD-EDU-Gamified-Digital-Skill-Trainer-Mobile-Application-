import 'package:flutter/material.dart';

enum TemplateType { story, matching_puzzle, sequence_puzzle, quiz }

class TemplateItem {
  final String id;
  final TemplateType type;
  final String title;
  final String code;
  final String banner;
  final Color accent;
  final String? description;
  final int? totalLessons;
  final int? points;

  TemplateItem({
    required this.id,
    required this.type,
    required this.title,
    required this.code,
    required this.banner,
    required this.accent,
    this.description,
    this.totalLessons,
    this.points,
  });
}
