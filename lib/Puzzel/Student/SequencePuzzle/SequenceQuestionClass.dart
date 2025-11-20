class SequenceQuestion {
  final String instructions;
  final List<String> sequenceItems;
  final List<String?> droppedItems;

  SequenceQuestion({
    required this.instructions,
    required this.sequenceItems,
    required this.droppedItems,
  });
}