class MatchingQuestion {
  final String instructions;
  final String leftColumnTitle;
  final String rightColumnTitle;
  final List<String> leftItems;
  final List<String> rightItems;
  final Map<String, String?> droppedRightItems;

  MatchingQuestion({
    required this.instructions,
    required this.leftColumnTitle,
    required this.rightColumnTitle,
    required this.leftItems,
    required this.rightItems,
  }) : droppedRightItems = {for (var item in leftItems) item: null};
}