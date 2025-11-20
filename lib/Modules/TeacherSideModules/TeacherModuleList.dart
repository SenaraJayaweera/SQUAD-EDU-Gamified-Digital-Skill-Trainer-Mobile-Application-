import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/Modules/TeacherSideModules/TeacherEditModule.dart';
import '../../Theme/Themes.dart';
import 'TeacherModuleCreation.dart';
import '../../GameTemplates/Teacher/TeacherTemplateListsFolder/TeacherTemplates.dart';

class TeacherModulesPage extends StatelessWidget {
  const TeacherModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: app.headerBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Modules',
                    style: TextStyle(
                      color: app.headerFg,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('modules')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final modules = snapshot.data!.docs;
                final totalModules = modules.length;

                final totalPoints = modules.fold<int>(0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final points = (data['totalPoints'] ?? 0) as num;
                  return sum + points.toInt();
                });

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
                      _StatItem(
                        icon: Icons.emoji_events,
                        label: 'Points',
                        value: totalPoints.toString(),
                        iconColor: app.secondaryColor,
                        textColor: app.headerFg,
                      ),
                    ],
                  ),
                );
              },
            ),
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
                      .collection('modules')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final modules = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        'id': doc.id,
                        'title': data['title'] ?? '',
                        'description': data['description'] ?? '',
                        'iconBase64': data['iconBase64'] ?? '',
                        'totalPoints': (data['totalPoints'] ?? 0) as num,
                      };
                    }).toList();

                    if (modules.isEmpty) {
                      return Center(
                        child: Text(
                          'No modules created yet',
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        final module = modules[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ModuleCard(
                            module: module,
                            cardColor: cardColor,
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateModulePage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Module'),
        backgroundColor: app.fabColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final Map<String, dynamic> module;
  final Color cardColor;

  const _ModuleCard({required this.module, required this.cardColor});

  Widget _buildIcon(String? base64Str, AppColors colors) {
    if (base64Str != null && base64Str.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Str);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, fit: BoxFit.cover),
        );
      } catch (_) {
        return Icon(Icons.auto_stories, color: colors.moduleIconColor);
      }
    } else {
      return Icon(Icons.auto_stories, color: colors.moduleIconColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPoints = (module['totalPoints'] as num).toInt();

    return Stack(
      children: [
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.extension<AppColors>()!.moduleIconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildIcon(
                      module['iconBase64'],
                      theme.extension<AppColors>()!,
                    ),
                  ),
                  const SizedBox(width: 16),
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 16,
                              color: theme
                                  .extension<AppColors>()!
                                  .moduleStatColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalPoints',
                              style: TextStyle(
                                color: theme
                                    .extension<AppColors>()!
                                    .moduleStatColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeacherTemplates(),
                          settings: RouteSettings(arguments: module),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      minimumSize: const Size(120, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Go to Module'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  iconSize: 20,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditModulePage(moduleData: module),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.orange),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  iconSize: 20,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Module'),
                        content: const Text(
                          'Are you sure you want to delete this module?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('modules')
                          .doc(module['id'])
                          .delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Module deleted')),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
