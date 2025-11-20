import 'package:flutter/material.dart';
import '../../Theme/Themes.dart';
import '../../widgets/BackButtonWidget.dart';

class StudentTemplatesOld extends StatelessWidget {
  const StudentTemplatesOld({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    final module =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    // You can safely access module info like this:
    final moduleId = module?['id'] ?? 'Unknown';
    final moduleTitle = module?['title'] ?? 'Untitled Module';

    // Page constants (identical to Teacher)
    const double pageHPad = 20;
    const double sectionGap = 28;
    const double cardRadius = 18;

    // Sizing identical to Teacher (so the two pages feel the same)
    final bool compact = size.width < 390;
    final double bannerH = compact ? 90 : 110;
    final double cardHeight = bannerH + (compact ? 108 : 112);
    final double cardWidth = size.width - (pageHPad * 2);

    // Student palette differences:
    const Color studentAccent = Color(0xFFB9F58B); // green PREVIEW for all

    // Data (mock)
    final stories = List.generate(
      3,
      (i) => _Item(
        id: 's_story_${i + 1}',
        title: [
          'Story Name Story\nName',
          'Another Story\nName',
          'Third Story Title',
        ][i],
        code: 'STORY ${(i + 1).toString().padLeft(2, '0')}',
        banner: 'assets/images/templates/story_banner.png',
        accent: studentAccent,
        type: _Type.story,
      ),
    );

    final puzzles = List.generate(
      3,
      (i) => _Item(
        id: 's_puzzle_${i + 1}',
        title: ['Puzzle Name Puzzle\nName', 'Word Puzzle', 'Logic Puzzle'][i],
        code: 'PUZZLE ${(i + 1).toString().padLeft(2, '0')}',
        banner: 'assets/images/templates/puzzles_banner.png',
        accent: studentAccent,
        type: _Type.puzzle,
      ),
    );

    final quizzes = List.generate(
      3,
      (i) => _Item(
        id: 's_quiz_${i + 1}',
        title: ['Quizz Name Quizz\nName', 'Math Quiz', 'Science Quiz'][i],
        code: 'QUIZZ ${(i + 1).toString().padLeft(2, '0')}',
        banner: 'assets/images/templates/quizz_banner.png',
        accent: const Color.fromRGBO(185, 245, 139, 1),
        type: _Type.quiz,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(pageHPad, 12, pageHPad, 24),
          children: [
            // ===== Header: Back button + Module Title =====
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleBackButton(),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Text(
                      moduleTitle,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _Section(
              title: 'Story Lessons',
              icon: Icons.menu_book_rounded,
              onViewAll: () {},
              child: SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: stories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) => _StudentCard(
                    item: stories[i],
                    width: cardWidth,
                    height: cardHeight,
                    bannerHeight: bannerH,
                    radius: cardRadius,
                    app: app,
                    cs: cs,
                  ),
                ),
              ),
            ),

            const SizedBox(height: sectionGap),

            _Section(
              title: 'Puzzles',
              icon: Icons.extension_rounded,
              onViewAll: () {},
              child: SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: puzzles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) => _StudentCard(
                    item: puzzles[i],
                    width: cardWidth,
                    height: cardHeight,
                    bannerHeight: bannerH,
                    radius: cardRadius,
                    app: app,
                    cs: cs,
                  ),
                ),
              ),
            ),

            const SizedBox(height: sectionGap),

            _Section(
              title: 'Quizzes',
              icon: Icons.psychology_alt_rounded,
              onViewAll: () {},
              child: SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: quizzes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) => _StudentCard(
                    item: quizzes[i],
                    width: cardWidth,
                    height: cardHeight,
                    bannerHeight: bannerH,
                    radius: cardRadius,
                    app: app,
                    cs: cs,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Section header (same as Teacher) ----------
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onViewAll;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.onViewAll,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: onBg,
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 28, color: onBg),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onViewAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'View all',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationThickness: 2,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: onBg,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

// ---------- Student Card ----------
class _StudentCard extends StatelessWidget {
  final _Item item;
  final double width;
  final double height;
  final double bannerHeight;
  final double radius;
  final AppColors app;
  final ColorScheme cs;

  const _StudentCard({
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

    // Same typography scale you settled on
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
      height: height,
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
            // Banner
            Positioned.fill(
              top: 0,
              bottom: height - bannerHeight,
              child: Image.asset(item.banner, fit: BoxFit.cover),
            ),

            // Single "Download" action (big, easy hit target)
            Positioned(
              top: 12,
              right: 12,
              child: _roundAction(
                context,
                icon: Icons.download_rounded,
                onTap: () {
                  // TODO: hook to your download flow with item.id / item.type
                },
              ),
            ),

            // Content
            Positioned.fill(
              top: bannerHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + right code
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

                    // Chips + PREVIEW (green) aligned right, same row
                    // Row(
                    //   children: [
                    //     _chip(context, 'Duration 15min', chipFont, chipPadH, chipPadV),
                    //     const SizedBox(width: 10),
                    //     _chip(context, 'Questions 10', chipFont, chipPadH, chipPadV),
                    //     const Spacer(),
                    //     const SizedBox(width: 8),

                    //     // Flexible green PREVIEW (no overflow)
                    //     ConstrainedBox(
                    //       constraints: const BoxConstraints(
                    //         minHeight: 28,
                    //         maxHeight: 28,
                    //       ),
                    //       child: FittedBox(
                    //         fit: BoxFit.scaleDown,
                    //         child: ElevatedButton(
                    //           onPressed: () {
                    //             // TODO: preview flow for item.id / item.type
                    //           },
                    //           style: ElevatedButton.styleFrom(
                    //             backgroundColor: item.accent,   // green for all
                    //             foregroundColor: Colors.black,
                    //             elevation: 0,
                    //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    //             minimumSize: const Size(0, 28),
                    //             shape: RoundedRectangleBorder(
                    //               borderRadius: BorderRadius.circular(14),
                    //               side: BorderSide(color: Colors.black.withOpacity(.25), width: 2),
                    //             ),
                    //             textStyle: TextStyle(
                    //               fontSize: compact ? 14 : 15,
                    //               fontWeight: FontWeight.w800,
                    //             ),
                    //           ),
                    //           child: const Text('PREVIEW'),
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // Row with chips + button
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
                        const SizedBox(width: 12), // gap before button
                        // Bigger PREVIEW button
                        SizedBox(
                          height: compact ? 36 : 40, // ⬆️ was ~26–28
                          width: compact ? 140 : 160, // ⬆️ was ~116–128
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
                                fontSize: compact
                                    ? 16
                                    : 18, // ⬆️ larger text too
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

  // Student round action (download) — larger invisible hit target, visible size ~44
  Widget _roundAction(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: 'Download',
      child: Material(
        color: Colors.white.withOpacity(.92),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          onLongPress: onTap,
          borderRadius: BorderRadius.circular(28),
          // Larger tap target without changing visual size
          child: const Padding(
            padding: EdgeInsets.all(6), // increases hit area
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.download_rounded,
                size: 24,
                color: Colors.black87,
              ),
            ),
          ),
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
}

// ---------- Model ----------
enum _Type { story, puzzle, quiz }

class _Item {
  final String id;
  final _Type type;
  final String title;
  final String code;
  final String banner;
  final Color accent;

  _Item({
    required this.id,
    required this.type,
    required this.title,
    required this.code,
    required this.banner,
    required this.accent,
  });
}
