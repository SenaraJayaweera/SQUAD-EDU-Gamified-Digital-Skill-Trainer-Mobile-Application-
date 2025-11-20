import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:frontend/Storymode/Teacher/StoryViewPage.dart';
import '../../Theme/Themes.dart';
import '../../widgets/BackButtonWidget.dart';
import '../../Quiz/Teacher/CreateQuiz.dart';
import '../../Puzzel/Teacher/Puzzels.dart';
import '../../Storymode/Teacher/Stories.dart';

// ===================== Page =====================

class TeacherTemplates extends StatelessWidget {
  const TeacherTemplates({super.key});

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

    const double pageHPad = 20;
    const double sectionGap = 28;
    const double cardRadius = 18;

    // Responsive banner & card
    final bool compact = size.width < 390; // small phones
    final double bannerH = compact ? 90 : 110;

    // keep the old, shorter card height
    final double cardHeight = bannerH + (compact ? 108 : 112);
    final double cardWidth = size.width - (pageHPad * 2);

    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final Stream<QuerySnapshot> storiesStream = moduleId != 'Unknown'
        ? firestore
              .collection('stories')
              .where('moduleId', isEqualTo: moduleId)
              .snapshots()
        : firestore.collection('stories').snapshots();

    final puzzles = <TemplateItem>[]; // empty list
    /*List.generate(
      3,
      (i) => TemplateItem(
        id: 'puzzle_${i + 1}',
        title: ['Puzzle Name Puzzle\nName', 'Word Puzzle', 'Logic Puzzle'][i],
        code: 'PUZZLE ${(i + 1).toString().padLeft(2, '0')}',
        banner: 'assets/images/templates/puzzles_banner.png',
        accent: const Color(0xFF51B9FF),
        type: TemplateType.puzzle,
      ),
    );
*/

    final quizzes = <TemplateItem>[]; // empty list
    /*= List.generate(
      3,
      (i) => TemplateItem(
        id: 'quiz_${i + 1}',
        title: ['Quizz Name Quizz\nName', 'Math Quiz', 'Science Quiz'][i],
        code: 'QUIZZ ${(i + 1).toString().padLeft(2, '0')}',
        banner: 'assets/images/templates/quizz_banner.png',
        accent: const Color(0xFFB9F58B),
        type: TemplateType.quiz,
      ),
    );*/

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
                        fontSize: 28,
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
              onCreateNew: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StoryCreationPage(),
                    settings: RouteSettings(arguments: {'moduleId': moduleId}),
                  ),
                );
              },
              child: StreamBuilder<QuerySnapshot>(
                stream: storiesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SizedBox(
                      height: cardHeight,
                      child: Center(
                        child: Text(
                          'Error loading stories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: cardHeight,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                        ),
                      ),
                    );
                  }

                  final stories = snapshot.data?.docs ?? [];

                  if (stories.isEmpty) {
                    return SizedBox(
                      height: cardHeight,
                      child: Center(
                        child: Text(
                          'No Story Lessons available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    );
                  }

                  // Convert Firestore documents to TemplateItem objects
                  final storyItems = stories.map((doc) {
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

                  return SizedBox(
                    height: cardHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: storyItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, i) => _StoryCard(
                        item: storyItems[i],
                        width: cardWidth,
                        height: cardHeight,
                        bannerHeight: bannerH,
                        radius: cardRadius,
                        app: app,
                        cs: cs,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: sectionGap),

            _Section(
              title: 'Puzzles',
              icon: Icons.extension_rounded,
              onCreateNew: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PuzzleCreationPage(),
                    settings: RouteSettings(
                      arguments: {
                        'moduleId': moduleId,
                        'moduleTitle': moduleTitle,
                      },
                    ),
                  ),
                );
              },
              child: puzzles.isEmpty
                  ? SizedBox(
                      height: cardHeight,
                      child: Center(
                        child: Text(
                          'No Puzzles available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: cardHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: puzzles.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, i) => _TemplateCard(
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
              onCreateNew: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QuizCreationPage(),
                    settings: RouteSettings(
                      arguments: {
                        'moduleId': moduleId,
                        'moduleTitle': moduleTitle,
                      },
                    ),
                  ),
                );
              },
              child: quizzes.isEmpty
                  ? SizedBox(
                      height: cardHeight,
                      child: Center(
                        child: Text(
                          'No quizzes available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: cardHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: quizzes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, i) => _TemplateCard(
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

  // Helper method to calculate total lessons from content
  int _calculateTotalLessons(dynamic content) {
    if (content == null) return 0;
    if (content is List) return content.length;
    return 0;
  }
}

// ===================== Section header =====================

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onCreateNew;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.onCreateNew,
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
              onTap: onCreateNew,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'Create new',
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

// ===================== Card =====================

// ===================== Story Card =====================
class _StoryCard extends StatelessWidget {
  final TemplateItem item;
  final double width;
  final double height;
  final double bannerHeight;
  final double radius;
  final AppColors app;
  final ColorScheme cs;

  const _StoryCard({
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
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== Banner =====
              SizedBox(
                height: bannerHeight,
                width: double.infinity,
                child: Image.asset(item.banner, fit: BoxFit.cover),
              ),

              // ===== Title & Description =====
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                    if (item.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: descSize,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // ===== Bottom Row: Lessons, Points, Preview =====
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Row(
                  children: [
                    _chip(
                      context,
                      'Lesson Contents: ${item.totalLessons ?? 0}',
                      chipFont,
                      chipPadH,
                      chipPadV,
                    ),
                    const SizedBox(width: 10),
                    _chip(
                      context,
                      'Points: ${item.points ?? 0}',
                      chipFont,
                      chipPadH,
                      chipPadV,
                    ),
                    const Spacer(),
                    SizedBox(
                      height: compact ? 36 : 40,
                      width: compact ? 140 : 160,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StoryViewPage(),
                              settings: RouteSettings(
                                arguments: {'storyId': item.id},
                              ),
                            ),
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
                        child: const Text('PREVIEW'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

class _TemplateCard extends StatelessWidget {
  final TemplateItem item;
  final double width;
  final double height;
  final double bannerHeight;
  final double radius;
  final AppColors app;
  final ColorScheme cs;

  const _TemplateCard({
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

    // compact tweaks
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
            Positioned.fill(
              top: 0,
              bottom: height - bannerHeight,
              child: Image.asset(item.banner, fit: BoxFit.cover),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  _circleTool(
                    context,
                    Icons.delete_outline,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Delete ${item.code}')),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _circleTool(
                    context,
                    Icons.edit,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edit ${item.code}')),
                      );
                    },
                  ),
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              const SizedBox.expand(),
              Center(
                child: IgnorePointer(
                  ignoring: true,
                  child: Icon(icon, size: 22, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== Model =====================

enum TemplateType { story, puzzle, quiz }

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

// ===================== Dummy Creation Pages =====================
/*
class StoryCreationPage extends StatelessWidget {
  const StoryCreationPage({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Create Story')));
}

class PuzzleCreationPage extends StatelessWidget {
  const PuzzleCreationPage({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Create Puzzle')));
}

class QuizCreationPage extends StatelessWidget {
  const QuizCreationPage({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Create Quiz')));
}
*/
