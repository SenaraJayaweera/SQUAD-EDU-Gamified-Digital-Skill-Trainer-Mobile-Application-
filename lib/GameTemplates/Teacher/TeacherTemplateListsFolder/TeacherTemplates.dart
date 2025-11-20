import 'package:flutter/material.dart';
import '../../../Theme/Themes.dart';
import '../../../widgets/BackButtonWidget.dart';
import '../../../Storymode/Teacher/Stories.dart';
import '_Section.dart';
import '_StoryCard.dart';
import '_QuizCard.dart';
import 'TemplateItem.dart';
import 'story_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'puzzle_service.dart';
import '_PuzzleCard.dart';
import '../../../Quiz/Teacher/CreateQuiz.dart';
import '../../../Puzzel/Teacher/Puzzels.dart';
import 'Quiz_Service.dart';

class TeacherTemplates extends StatelessWidget {
  const TeacherTemplates({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final module =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    final moduleId = module?['id'] ?? 'Unknown';
    final moduleTitle = module?['title'] ?? 'Untitled Module';

    const double pageHPad = 20;
    const double sectionGap = 28;
    const double cardRadius = 18;

    final bool compact = size.width < 390;
    final double bannerH = compact ? 90 : 110;
    final double cardHeight = bannerH + (compact ? 108 : 160);
    final double cardWidth = size.width - (pageHPad * 2);

    final storyService = StoryService();
    final puzzleService = PuzzleService();
    //final quizzes = <TemplateItem>[];
    final quizService = QuizService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(pageHPad, 12, pageHPad, 24),
          children: [
            // Header
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

            // Story Section
            SectionWidget(
              title: 'Lessons',
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
                stream: storyService.getStoriesStream(moduleId),
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

                  final storyItems = storyService.mapStories(snapshot.data!);

                  if (storyItems.isEmpty) {
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

                  return SizedBox(
                    height: cardHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: storyItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, i) => Builder(
                        builder: (ctx) => SizedBox(
                          height: cardHeight,
                          child: StoryCard(
                            item: storyItems[i],
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
                  );
                },
              ),
            ),

            // Puzzle Section
            const SizedBox(height: sectionGap),
            SectionWidget(
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
              child: SizedBox(
                height: cardHeight,
                child: StreamBuilder<List<TemplateItem>>(
                  stream: puzzleService.getAllPuzzles(moduleId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading puzzles'));
                    }

                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final puzzleItems = snapshot.data!;

                    if (puzzleItems.isEmpty) {
                      return Center(
                        child: Text(
                          'No Puzzles available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: puzzleItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, i) => SizedBox(
                        height: cardHeight,
                        child: PuzzleCard(
                          item: puzzleItems[i],
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
            ),

            const SizedBox(height: sectionGap),

            // Quiz Section
            const SizedBox(height: sectionGap),
            SectionWidget(
              title: 'Quizzes',
              icon: Icons.psychology_alt_rounded,
              onCreateNew: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const QuizCreationPage(), // your quiz creation page
                    settings: RouteSettings(
                      arguments: {
                        'moduleId': moduleId,
                        'moduleTitle': moduleTitle,
                      },
                    ),
                  ),
                );
              },
              child: SizedBox(
                height: cardHeight,
                child: StreamBuilder<List<TemplateItem>>(
                  stream: quizService.getAllQuizzes(moduleId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading quizzes'));
                    }
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final quizItems = snapshot.data!;
                    if (quizItems.isEmpty) {
                      return Center(
                        child: Text(
                          'No Quizzes available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: quizItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, i) => QuizCard(
                        item: quizItems[i],
                        width: cardWidth,
                        height: cardHeight,
                        bannerHeight: bannerH,
                        radius: cardRadius,
                        app: app,
                        cs: cs,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
