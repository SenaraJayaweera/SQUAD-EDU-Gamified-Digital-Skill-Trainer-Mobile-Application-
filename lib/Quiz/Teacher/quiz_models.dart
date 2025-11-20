// import 'package:cloud_firestore/cloud_firestore.dart';

// /// Each answer choice (A, B, C, D)
// class QuizChoice {
//   final String letter;
//   final String text;
//   final bool isCorrect;

//   QuizChoice({
//     required this.letter,
//     required this.text,
//     required this.isCorrect,
//   });

//   Map<String, dynamic> toMap() => {
//         'letter': letter,
//         'text': text,
//         'isCorrect': isCorrect,
//       };

//   factory QuizChoice.fromMap(Map<String, dynamic> map) => QuizChoice(
//         letter: map['letter'] ?? '',
//         text: map['text'] ?? '',
//         isCorrect: map['isCorrect'] ?? false,
//       );
// }

// /// Each question in the quiz
// class QuizQuestion {
//   final int index;
//   final String title;
//   final String hint;
//   final String explanation;
//   final List<QuizChoice> choices;

//   QuizQuestion({
//     required this.index,
//     required this.title,
//     required this.hint,
//     required this.explanation,
//     required this.choices,
//   });

//   Map<String, dynamic> toMap() => {
//         'index': index,
//         'title': title,
//         'hint': hint,
//         'explanation': explanation,
//         'choices': choices.map((c) => c.toMap()).toList(),
//       };

//   factory QuizQuestion.fromMap(Map<String, dynamic> map) => QuizQuestion(
//         index: map['index'] ?? 0,
//         title: map['title'] ?? '',
//         hint: map['hint'] ?? '',
//         explanation: map['explanation'] ?? '',
//         choices: (map['choices'] as List<dynamic>? ?? [])
//             .map((c) => QuizChoice.fromMap(Map<String, dynamic>.from(c)))
//             .toList(),
//       );
// }

// /// Top-level quiz document
// class QuizModel {
//   final String moduleId;
//   final String moduleTitle;
//   final String createdBy;
//   final String status;
//   final int attempts;
//   final Map<String, dynamic> preset;
//   final Timestamp createdAt;

//   QuizModel({
//     required this.moduleId,
//     required this.moduleTitle,
//     required this.createdBy,
//     required this.status,
//     required this.attempts,
//     required this.preset,
//     required this.createdAt,
//   });

//   Map<String, dynamic> toMap() => {
//         'moduleId': moduleId,
//         'moduleTitle': moduleTitle,
//         'createdBy': createdBy,
//         'status': status,
//         'attempts': attempts,
//         'preset': preset,
//         'createdAt': createdAt,
//       };
// }

import 'package:cloud_firestore/cloud_firestore.dart';

/// ====== Publish preset used across Create -> Preview -> Publish ======
class PublishPreset {
  final String difficulty; // Easy | Medium | Hard | All
  final int points;        // per-question (or total – your choice)
  final String hints;      // Enable | Disable
  final int lives;         // e.g. 3
  final int questions;     // e.g. 10
  final String time;       // e.g. "10 Min"

  const PublishPreset({
    required this.difficulty,
    required this.points,
    required this.hints,
    required this.lives,
    required this.questions,
    required this.time,
  });

  Map<String, dynamic> toMap() => {
        'difficulty': difficulty,
        'points': points,
        'hints': hints,
        'lives': lives,
        'questions': questions,
        'time': time,
      };

  factory PublishPreset.fromMap(Map<String, dynamic> map) => PublishPreset(
        difficulty: map['difficulty']?.toString() ?? 'All',
        points: (map['points'] is int)
            ? map['points'] as int
            : int.tryParse('${map['points']}') ?? 0,
        hints: map['hints']?.toString() ?? 'Enable',
        lives: (map['lives'] is int)
            ? map['lives'] as int
            : int.tryParse('${map['lives']}') ?? 0,
        questions: (map['questions'] is int)
            ? map['questions'] as int
            : int.tryParse('${map['questions']}') ?? 0,
        time: map['time']?.toString() ?? '10 Min',
      );
}

/// ====== Each answer choice (A, B, C, D) ======
class QuizChoice {
  final String letter;
  final String text;
  final bool isCorrect;

  QuizChoice({
    required this.letter,
    required this.text,
    required this.isCorrect,
  });

  Map<String, dynamic> toMap() => {
        'letter': letter,
        'text': text,
        'isCorrect': isCorrect,
      };

  factory QuizChoice.fromMap(Map<String, dynamic> map) => QuizChoice(
        letter: map['letter'] ?? '',
        text: map['text'] ?? '',
        isCorrect: map['isCorrect'] ?? false,
      );
}

/// ====== Each question in the quiz ======
class QuizQuestion {
  final int index;
  final String title;
  final String hint;
  final String explanation;
  final List<QuizChoice> choices;

  QuizQuestion({
    required this.index,
    required this.title,
    required this.hint,
    required this.explanation,
    required this.choices,
  });

  Map<String, dynamic> toMap() => {
        'index': index,
        'title': title,
        'hint': hint,
        'explanation': explanation,
        'choices': choices.map((c) => c.toMap()).toList(),
      };

  factory QuizQuestion.fromMap(Map<String, dynamic> map) => QuizQuestion(
        index: map['index'] ?? 0,
        title: map['title'] ?? '',
        hint: map['hint'] ?? '',
        explanation: map['explanation'] ?? '',
        choices: (map['choices'] as List<dynamic>? ?? [])
            .map((c) => QuizChoice.fromMap(Map<String, dynamic>.from(c)))
            .toList(),
      );
}

/// ====== Top-level quiz document (what you store in Firestore) ======
class QuizModel {
  final String moduleId;
  final String moduleTitle;
  final String createdBy;
  final String status;          // e.g. 'draft' | 'published'
  final int attempts;
  final Map<String, dynamic> preset; // usually PublishPreset.toMap()
  final Timestamp createdAt;

  QuizModel({
    required this.moduleId,
    required this.moduleTitle,
    required this.createdBy,
    required this.status,
    required this.attempts,
    required this.preset,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'moduleId': moduleId,
        'moduleTitle': moduleTitle,
        'createdBy': createdBy,
        'status': status,
        'attempts': attempts,
        'preset': preset,
        'createdAt': createdAt,
      };

  /// Optional: helper if you ever read it back.
  factory QuizModel.fromMap(Map<String, dynamic> map) => QuizModel(
        moduleId: map['moduleId'] ?? '',
        moduleTitle: map['moduleTitle'] ?? '',
        createdBy: map['createdBy'] ?? '',
        status: map['status'] ?? 'draft',
        attempts: (map['attempts'] is int)
            ? map['attempts'] as int
            : int.tryParse('${map['attempts']}') ?? 1,
        preset: Map<String, dynamic>.from(map['preset'] ?? const {}),
        createdAt: map['createdAt'] is Timestamp
            ? map['createdAt'] as Timestamp
            : Timestamp.now(),
      );
}

