/*import 'package:flutter/material.dart';
import 'TemplateItem.dart';
import '../../../Theme/Themes.dart';

class TemplateCard extends StatelessWidget {
  final TemplateItem item;
  final double width;
final double height;
  final double bannerHeight;
  final double radius;
  final AppColors app;
  final ColorScheme cs;

  const TemplateCard({
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
    final double codeSize = compact ? 14 : 16;
    final double chipFont = compact ? 10.5 : 12.5;
    final double chipPadV = compact ? 2 : 4;
    final double chipPadH = compact ? 9 : 11;

    final borderColor = app.border.withOpacity(
      Theme.of(context).brightness == Brightness.dark ? 0.35 : 1,
    );

    return SizedBox(
      width: width,
    //  height: height,
      child: Material(
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              top: 0,
            //  bottom: height - bannerHeight,
              child: Image.asset(item.banner, fit: BoxFit.cover),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  _circleTool(context, Icons.delete_outline, onTap: () {}),
                  const SizedBox(width: 10),
                  _circleTool(context, Icons.edit, onTap: () {}),
                ],
              ),
            ),
            Positioned.fill(
              top: bannerHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleSize,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.code,
                          style: TextStyle(
                            fontSize: codeSize,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _chip(
                          context,
                          'Duration 15min',
                          chipFont,
                          chipPadH,
                          chipPadV,
                        ),
                        const SizedBox(width: 10),
                        _chip(
                          context,
                          'Questions 10',
                          chipFont,
                          chipPadH,
                          chipPadV,
                        ),
                        const Spacer(),
                        SizedBox(
                          height: compact ? 36 : 40,
                          width: compact ? 140 : 160,
                          child: ElevatedButton(
                            onPressed: () {},
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
                            child: const Text('PREVIEW'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String text,
    double font,
    double padH,
    double padV,
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

  Widget _circleTool(
    BuildContext context,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    final bg = Colors.white.withOpacity(.92);
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: IgnorePointer(
              ignoring: true,
              child: Icon(icon, size: 22, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
*/
