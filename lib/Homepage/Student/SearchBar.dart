import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../GameTemplates/Student/StudentTemplateListFolder/StudentTemplates.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Searchbar extends StatefulWidget {
  const Searchbar({super.key});

  @override
  State<Searchbar> createState() => SearchbarState();
}

class SearchbarState extends State<Searchbar> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim();
      });
    });
  }

  Stream<QuerySnapshot> _getModules() {
    return FirebaseFirestore.instance
        .collection('modules')
        .orderBy('title')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // 🔍 Modern Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search modules...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                filled: false,
              ),
            ),
          ),
        ),

        // 📋 Modern results section
        if (searchQuery.isNotEmpty)
          StreamBuilder<QuerySnapshot>(
            stream: _getModules(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Searching modules...',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No modules found',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // 🔍 Case-insensitive search filter
              final filteredDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = (data['title'] ?? '').toString().toLowerCase();
                return title.contains(searchQuery.toLowerCase());
              }).toList();

              if (filteredDocs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No results for "$searchQuery"',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try different keywords',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final data =
                            filteredDocs[index].data() as Map<String, dynamic>;
                        final moduleId = filteredDocs[index].id;
                        final title = data['title'] ?? 'Untitled Module';
                        final description = data['description'] ?? '';

                        return Container(
                          margin: EdgeInsets.only(
                            bottom: index == filteredDocs.length - 1 ? 0 : 1,
                          ),
                          decoration: BoxDecoration(
                            border: index == filteredDocs.length - 1
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: colorScheme.outline.withOpacity(
                                        0.1,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.book,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: description.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : null,
                            trailing: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: colorScheme.onSurface.withOpacity(0.4),
                            ),
                            onTap: () async {
                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) throw "User not logged in";
                                final studentUid = user.uid;

                                final moduleDoc = await FirebaseFirestore
                                    .instance
                                    .collection('modules')
                                    .doc(moduleId)
                                    .get();
                                if (!moduleDoc.exists) throw "Module not found";
                                final moduleData = moduleDoc.data()!;
                                final teacherId = moduleData["teacherId"] ?? "";

                                final studentModuleRef = FirebaseFirestore
                                    .instance
                                    .collection('Student_to_Module_Enrollment')
                                    .doc(studentUid)
                                    .collection('modules')
                                    .doc(moduleId);

                                final studentModuleSnapshot =
                                    await studentModuleRef.get();

                                // Enroll if not already enrolled
                                if (!studentModuleSnapshot.exists) {
                                  final now = FieldValue.serverTimestamp();

                                  await studentModuleRef.set({
                                    'moduleName': title,
                                    'teacherId': teacherId,
                                    'enrolledAt': now,
                                  });

                                  await FirebaseFirestore.instance
                                      .collection(
                                        'Module_to_Student_Enrollment',
                                      )
                                      .doc(moduleId)
                                      .collection('students')
                                      .doc(studentUid)
                                      .set({
                                        'studentName':
                                            user.displayName ?? "Student",
                                        'enrolledAt': now,
                                      });
                                }

                                // Navigate after enrollment
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const StudentTemplates(),
                                    settings: RouteSettings(
                                      arguments: {
                                        'id': moduleId,
                                        'title': title,
                                      },
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Enrollment failed: $e'),
                                  ),
                                );
                              }
                            },

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          )
        else
          const SizedBox(),
      ],
    );
  }
}
