import 'package:flutter/material.dart';

class QuestionPair {
  String left;
  String right;

  QuestionPair({this.left = '', this.right = ''});
}

class QuestionDataModel {
  TextEditingController instructionsController;
  TextEditingController leftColumnTitleController;
  TextEditingController rightColumnTitleController;
  List<QuestionPair> puzzlePairs;

  QuestionDataModel({
    String instructions = '',
    String leftColumnTitle = '',
    String rightColumnTitle = '',
    List<QuestionPair>? initialPairs,
  }) : instructionsController = TextEditingController(text: instructions),
       leftColumnTitleController = TextEditingController(text: leftColumnTitle),
       rightColumnTitleController = TextEditingController(
         text: rightColumnTitle,
       ),
       puzzlePairs = initialPairs ?? [QuestionPair()];
}

class MatchingPuzzleData {
  String moduleId;
  String moduleTitle;
  String puzzleName;
  String puzzleDescription;
  String? selectedPuzzleType;
  List<QuestionDataModel> questions;

  MatchingPuzzleData({
    required this.moduleId,
    this.moduleTitle = '',
    this.puzzleName = '',
    this.puzzleDescription = '',
    this.selectedPuzzleType,
    List<QuestionDataModel>? initialQuestions,
  }) : questions = initialQuestions ?? [QuestionDataModel()];

  /// Update puzzle name
  void updateName(String name) => puzzleName = name;

  /// Update puzzle description
  void updateDescription(String desc) => puzzleDescription = desc;

  /// Update selected puzzle type
  void updatePuzzleType(String type) => selectedPuzzleType = type;

  /// Add a question
  void addQuestion() => questions.add(QuestionDataModel());

  /// Remove a question
  void removeQuestion(int index) {
    if (index >= 0 && index < questions.length) questions.removeAt(index);
  }

  /// Add a pair to a specific question
  void addPair(int questionIndex) {
    if (questionIndex >= 0 && questionIndex < questions.length) {
      questions[questionIndex].puzzlePairs.add(QuestionPair());
    }
  }

  /// Remove a pair from a specific question
  void removePair(int questionIndex, int pairIndex) {
    if (questionIndex >= 0 &&
        questionIndex < questions.length &&
        pairIndex >= 0 &&
        pairIndex < questions[questionIndex].puzzlePairs.length) {
      questions[questionIndex].puzzlePairs.removeAt(pairIndex);
    }
  }
}



// ===================== Sequence Puzzle Centralized Classes =====================

class SequenceInput {
  TextEditingController controller;

  SequenceInput({String value = ''}) : controller = TextEditingController(text: value);
}

class SequenceQuestionModel {
  TextEditingController instructionsController;
  List<SequenceInput> sequenceInputs;

  SequenceQuestionModel({String instructions = '', List<SequenceInput>? initialInputs})
      : instructionsController = TextEditingController(text: instructions),
        sequenceInputs = initialInputs ?? [SequenceInput()]; // First input is always present
}

class SequencePuzzleData {
  String moduleId;
  String moduleTitle;
  String puzzleName;
  String puzzleDescription;
  String? selectedPuzzleType;
  List<SequenceQuestionModel> questions;

  SequencePuzzleData({
    required this.moduleId,
    this.moduleTitle = '',
    this.puzzleName = '',
    this.puzzleDescription = '',
    this.selectedPuzzleType,
    List<SequenceQuestionModel>? initialQuestions,
  }) : questions = initialQuestions ?? [SequenceQuestionModel()];

  /// Update puzzle name
  void updateName(String name) => puzzleName = name;

  /// Update puzzle description
  void updateDescription(String desc) => puzzleDescription = desc;

  /// Update selected puzzle type
  void updatePuzzleType(String type) => selectedPuzzleType = type;

  /// Add a question
  void addQuestion() => questions.add(SequenceQuestionModel());

  /// Remove a question (cannot remove first)
  void removeQuestion(int index) {
    if (index > 0 && index < questions.length) questions.removeAt(index);
  }

  /// Add a sequence input to a specific question
  void addSequenceInput(int questionIndex) {
    if (questionIndex >= 0 && questionIndex < questions.length) {
      questions[questionIndex].sequenceInputs.add(SequenceInput());
    }
  }

  /// Remove a sequence input from a specific question (cannot remove first)
  void removeSequenceInput(int questionIndex, int inputIndex) {
    if (questionIndex >= 0 &&
        questionIndex < questions.length &&
        inputIndex > 0 &&
        inputIndex < questions[questionIndex].sequenceInputs.length) {
      questions[questionIndex].sequenceInputs.removeAt(inputIndex);
    }
  }
}

