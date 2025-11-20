import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'ProgressCard.dart';
import 'DiscoverNewModules.dart';
import 'SearchBar.dart';

class Studenthomepage extends StatelessWidget {
  const Studenthomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LearningDashboardPage();
  }
}

// -----------------------------------------------------------------------------
// DASHBOARD PAGE
// -----------------------------------------------------------------------------
class LearningDashboardPage extends StatelessWidget {
  const LearningDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AppBarSection(theme: theme),
            const SizedBox(height: 25),
            const Searchbar(),
            const SizedBox(height: 20),
            ProgressCard(theme: theme),
            const SizedBox(height: 25),
            /*
            _SectionHeader(
              title: 'In Progress',
              theme: theme,
              onViewAll: () {
                debugPrint('View All In Progress tapped');
              },
            ),
            const SizedBox(height: 15),
            const EnrolledModules(),
            const SizedBox(height: 20),
            */
            _SectionHeader(
              title: 'Discover New Modules',
              theme: theme,
              onViewAll: () {
                debugPrint('View All Discover New Modules tapped');
              },
            ),
            const SizedBox(height: 15),
            const DiscoverNewModules(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// APP BAR
// -----------------------------------------------------------------------------
class _AppBarSection extends StatelessWidget {
  final ThemeData theme;
  const _AppBarSection({required this.theme});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final fullName =
            '${userData?['firstName'] ?? 'Unknown'} ${userData?['lastName'] ?? 'Student'}';

        return Padding(
          padding: const EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: theme.colorScheme.secondary,
                child: Icon(Icons.person, color: theme.colorScheme.onSecondary),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back, $fullName!',
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      fullName,
                      style: theme.textTheme.headlineLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// SECTION HEADER
// -----------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final ThemeData theme;

  const _SectionHeader({
    required this.title,
    this.onViewAll,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
