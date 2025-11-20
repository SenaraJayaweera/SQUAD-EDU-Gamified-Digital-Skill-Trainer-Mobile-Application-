import 'package:flutter/material.dart';
import 'TemplateItem.dart';
import '../../../Theme/Themes.dart';
import '../../../Puzzel/Student/SequencePuzzle/StudentSequencePuzzle.dart';
import '../../../Puzzel/Student/MatchingPuzzel/StudentMatchingPuzzle.dart';

class PuzzleCard extends StatelessWidget {
  final TemplateItem item;
  final double width;
  final double height;
  final double bannerHeight;
  final double radius;
  final AppColors app;
  final ColorScheme cs;

  const PuzzleCard({
    super.key,
    required this.item,
    required this.width,
    required this.height,
    required this.bannerHeight,
    required this.radius,
    required this.app,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final compact = sw < 390;

    final double titleSize = compact ? 16 : 18;
    final double descSize = compact ? 12 : 14;
    final double chipFont = compact ? 10.5 : 12.5;
    final double chipPadV = compact ? 2 : 4;
    final double chipPadH = compact ? 9 : 11;

    final borderColor = app.border.withOpacity(
      Theme.of(context).brightness == Brightness.dark ? 0.35 : 1,
    );

    return SizedBox(
      width: width,
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner image
            SizedBox(
              height: bannerHeight,
              width: double.infinity,
              child: Image.asset(item.banner, fit: BoxFit.cover),
            ),

            // Title + Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: descSize,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Bottom row: puzzle type chip + preview button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  _chip(
                    context,
                    _getPuzzleType(item.type),
                    chipFont,
                    chipPadH,
                    chipPadV,
                    cs.primary,
                  ),
                  const Spacer(),

                  SizedBox(
                    height: compact ? 36 : 40,
                    width: compact ? 140 : 160,
                    child: ElevatedButton(
                      onPressed: () {
                        Widget destinationPage;

                        switch (item.type) {
                          case TemplateType.matching_puzzle:
                            destinationPage = StudentMatchingPuzzlePage(
                              puzzleId: item.id,
                            );
                            break;
                          case TemplateType.sequence_puzzle:
                            destinationPage = StudentSequencePuzzlePage(
                              puzzleId: item.id,
                            );

                            break;
                          default:
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error: Unknown puzzle type.'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return; 
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => destinationPage),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.accent,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Colors.black.withOpacity(.25),
                            width: 2,
                          ),
                        ),
                        textStyle: TextStyle(
                          fontSize: compact ? 16 : 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text(
                        'PREVIEW',
                        //style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Puzzle type label
  String _getPuzzleType(TemplateType type) {
    switch (type) {
      case TemplateType.matching_puzzle:
        return "Matching Puzzle";
      case TemplateType.sequence_puzzle:
        return "Sequence Puzzle";
      default:
        return "Unknown Type";
    }
  }

  /// Reusable chip widget
  Widget _chip(
    BuildContext context,
    String text,
    double font,
    double padH,
    double padV,
    Color accent,
  ) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(.12) : const Color(0xFFE9EAEE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: font,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
