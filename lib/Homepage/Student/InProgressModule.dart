
/*
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../../Theme/Themes.dart';

// -----------------------------------------------------------------------------
// ENROLLED MODULES (STATEFUL)
// -----------------------------------------------------------------------------
class EnrolledModules extends StatefulWidget {
  const EnrolledModules({super.key});

  @override
  State<EnrolledModules> createState() => _EnrolledModulesState();
}

class _EnrolledModulesState extends State<EnrolledModules> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    final enrolledStream = FirebaseFirestore.instance
        .collection('Student_to_Module_Enrollment')
        .doc(user.uid)
        .collection('modules')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: enrolledStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final modules = snapshot.data!.docs;

        if (modules.isEmpty) {
          return const Center(child: Text("No enrolled modules"));
        }

        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index].data() as Map<String, dynamic>;
              final moduleName = module["moduleName"] ?? "Untitled Module";
              final imageBase64 = module["iconBase64"] as String?;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _EnrolledModuleCard(
                  moduleName: moduleName,
                  imageBase64: imageBase64,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _EnrolledModuleCard extends StatelessWidget {
  final String moduleName;
  final String? imageBase64;

  const _EnrolledModuleCard({required this.moduleName, this.imageBase64});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: app.label.withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // center vertically
        crossAxisAlignment: CrossAxisAlignment.center, // center horizontally
        children: [
          // Module Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade200,
            ),
            child: imageBase64 != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(imageBase64!),
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.auto_stories,
                    color: Colors.grey.shade700,
                    size: 32,
                  ),
          ),
          const SizedBox(height: 12),

          // Module Name
          Text(
            moduleName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
*/