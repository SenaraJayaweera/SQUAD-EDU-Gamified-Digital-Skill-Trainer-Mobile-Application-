import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Theme/Themes.dart';
import '../../GameTemplates/Student/StudentTemplateListFolder/StudentTemplates.dart';

class StudentModuleList extends StatelessWidget {
  const StudentModuleList({super.key});

  int getTotalPoints(List<QueryDocumentSnapshot> docs) {
    return docs.fold<int>(0, (int sum, module) {
      final data = module.data() as Map<String, dynamic>;
      final points = (data['points'] ?? 0).toInt();
      return (sum + points).toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cardColor = Theme.of(context).cardColor;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      backgroundColor: app.headerBg,
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'My Enrolled Modules',
                    style: TextStyle(
                      color: app.headerFg,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // ===== STREAM & STATS ROW =====
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Student_to_Module_Enrollment')
                  .doc(user.uid)
                  .collection('modules')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final modules = snapshot.data!.docs;
                final totalPoints = getTotalPoints(modules);
                final totalModules = modules.length;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.book,
                        label: 'Modules',
                        value: totalModules.toString(),
                        iconColor: app.ctaBlue,
                        textColor: app.headerFg,
                      ),
                    ],
                  ),
                );
              },
            ),

            // ===== MODULE LIST =====
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: app.panelBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Student_to_Module_Enrollment')
                      .doc(user.uid)
                      .collection('modules')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final modules = snapshot.data!.docs;

                    if (modules.isEmpty) {
                      return Center(
                        child: Text(
                          'No enrolled modules yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        final moduleId = modules[index].id;

                        // Fetch module data
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('modules')
                              .doc(moduleId)
                              .get(),
                          builder: (context, moduleSnapshot) {
                            if (!moduleSnapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            final moduleData =
                                moduleSnapshot.data!.data()
                                    as Map<String, dynamic>?;

                            if (moduleData == null) return const SizedBox();

                            final teacherId = moduleData['teacherId'];

                            // 🔹 Fetch teacher name using teacherId
                            return FutureBuilder<DocumentSnapshot>(
                              future: teacherId != null
                                  ? FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(teacherId)
                                        .get()
                                  : Future.value(null),
                              builder: (context, teacherSnapshot) {
                                String teacherName = 'Unknown';
                                if (teacherSnapshot.hasData &&
                                    teacherSnapshot.data != null &&
                                    teacherSnapshot.data!.exists) {
                                  final userData =
                                      teacherSnapshot.data!.data()
                                          as Map<String, dynamic>?;
                                  teacherName =
                                      '${userData?['firstName'] ?? 'Unknown'} ${userData?['lastName'] ?? 'Teacher'}';
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _ModuleCard(
                                    module: {
                                      'id': moduleId,
                                      'title': moduleData['title'] ?? '',
                                      'description':
                                          moduleData['description'] ?? '',
                                      'teacher': teacherName,
                                      'points': (moduleData['points'] ?? 0)
                                          .toInt(),
                                      'iconBase64':
                                          moduleData['iconBase64'] ?? '',
                                    },
                                    cardColor: cardColor,
                                    iconColor: app.cardIcon,
                                    iconBgColor: app.cardIconBg,
                                    buttonColor: app.cardButton,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
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

// ===== MODULE CARD =====
class _ModuleCard extends StatelessWidget {
  final Map<String, dynamic> module;
  final Color cardColor;
  final Color iconColor;
  final Color iconBgColor;
  final Color buttonColor;

  const _ModuleCard({
    required this.module,
    required this.cardColor,
    required this.iconColor,
    required this.iconBgColor,
    required this.buttonColor,
  });

  Widget _buildIcon(String? base64Str) {
    if (base64Str != null && base64Str.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Str);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, fit: BoxFit.cover),
        );
      } catch (_) {
        return Icon(Icons.auto_stories, color: iconColor, size: 28);
      }
    } else {
      return Icon(Icons.auto_stories, color: iconColor, size: 28);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildIcon(module['iconBase64']),
          ),
          const SizedBox(width: 16),

          // Module details + buttons
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module['title'],
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  module['description'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Teacher: ${module['teacher']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 12),

                // Buttons on new line
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentTemplates(),
                            settings: RouteSettings(arguments: module),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        minimumSize: const Size(100, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('View'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        final studentUid = user.uid;
                        final moduleId = module['id'];

                        try {
                          // Remove from Student_to_Module_Enrollment
                          await FirebaseFirestore.instance
                              .collection('Student_to_Module_Enrollment')
                              .doc(studentUid)
                              .collection('modules')
                              .doc(moduleId)
                              .delete();

                          // Remove from Module_to_Student_Enrollment
                          await FirebaseFirestore.instance
                              .collection('Module_to_Student_Enrollment')
                              .doc(moduleId)
                              .collection('students')
                              .doc(studentUid)
                              .delete();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Unenrolled from ${module['title']}',
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to unenroll: $e')),
                          );
                        }
                      },
                      icon: Icon(Icons.logout_rounded, color: Colors.redAccent),
                      tooltip: 'Unenroll',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== STAT ITEM =====
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color textColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: textColor)),
      ],
    );
  }
}
