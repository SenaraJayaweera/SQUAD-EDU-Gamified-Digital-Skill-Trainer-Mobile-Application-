// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// // three detail pages
// import 'StudentNamePage.dart';
// import 'StudentEmailPage.dart';
// import 'StudentSecurityPasswordPage.dart';
// import '../../Theme/ThemeSelectionSetting.dart';
// import '../../Theme/Themes.dart'; // AppColors extension
// import '../../Login/LoginPage.dart';

// class StudentUserProfilePage extends StatefulWidget {
//   const StudentUserProfilePage({super.key});

//   @override
//   _StudentUserProfilePageState createState() => _StudentUserProfilePageState();
// }

// class _StudentUserProfilePageState extends State<StudentUserProfilePage>
//     with WidgetsBindingObserver {
//   String _studentName = '';
//   String _studentEmail = '';
//   final _auth = FirebaseAuth.instance;

//   bool _syncing = false;           // guard to avoid re-entrancy
//   String? _lastSyncedAuthEmail;    // to avoid duplicate Firestore writes

//   // Assets
//   static const _trophyAsset =
//       'assets/images/StudentProfileImages/trophy-star.png';
//   static const _avatarAsset = 'assets/images/StudentProfileImages/student.png';

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _loadUserData();
//     // one on-start pickup
//     Future.microtask(_reloadAndSyncEmail);
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   // When coming back to foreground, pick up any verified email change
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       _reloadAndSyncEmail();
//     }
//   }

//   Future<void> _loadUserData() async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();

//       final first = (doc.data()?['firstName'] as String?)?.trim();
//       final last = (doc.data()?['lastName'] as String?)?.trim();
//       final fsEmail = (doc.data()?['email'] as String?)?.trim();

//       if (!mounted) return;
//       setState(() {
//         _studentName = (first != null && first.isNotEmpty) ||
//                 (last != null && last.isNotEmpty)
//             ? '${first ?? ''} ${last ?? ''}'.trim()
//             : (user.displayName ?? 'Student');

//         _studentEmail = fsEmail ?? user.email ?? 'student@gmail.com';
//       });
//     }
//   }

//   // Reload current user from Auth; if email differs from Firestore, mirror it.
//   Future<void> _reloadAndSyncEmail() async {
//     if (_syncing) return;
//     _syncing = true;
//     try {
//       await _auth.currentUser?.reload();
//       final user = _auth.currentUser;
//       if (user == null) return;

//       final authEmail = user.email?.trim();
//       if (authEmail == null || authEmail.isEmpty) return;

//       // Avoid repeated writes for the same email
//       if (_lastSyncedAuthEmail == authEmail && _studentEmail == authEmail) {
//         return;
//       }

//       final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
//       final snap = await ref.get();
//       final fsEmail = (snap.data()?['email'] as String?)?.trim();

//       if (authEmail != fsEmail) {
//         // doc may not exist for some users; use set(merge:true) to be safe
//         await ref.set(
//           {
//             'email': authEmail,
//             'updatedAt': FieldValue.serverTimestamp(),
//           },
//           SetOptions(merge: true),
//         );
//       }

//       if (!mounted) return;
//       setState(() {
//         _studentEmail = authEmail;
//         _lastSyncedAuthEmail = authEmail;
//       });
//     } catch (_) {
//       // swallow; nothing fatal for UI
//     } finally {
//       _syncing = false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final app = Theme.of(context).extension<AppColors>()!;

//     return Scaffold(
//       backgroundColor: app.headerBg,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // ===== HEADER =====
//             Padding(
//               padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 4),
//                   Text(
//                     'Student Profile',
//                     style: TextStyle(
//                       color: app.headerFg,
//                       fontSize: 28,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       ClipOval(
//                         child: Container(
//                           width: 56,
//                           height: 56,
//                           color: Theme.of(context).cardColor.withOpacity(.25),
//                           child: Image.asset(
//                             _avatarAsset,
//                             fit: BoxFit.cover,
//                             errorBuilder: (_, __, ___) => Icon(
//                               Icons.person,
//                               color: app.headerFg,
//                               size: 28,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               _studentName,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 color: app.headerFg,
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               _studentEmail,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 color: app.headerFgMuted,
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         width: 36,
//                         height: 36,
//                         padding: const EdgeInsets.all(6),
//                         decoration: BoxDecoration(
//                           color: Theme.of(context).cardColor.withOpacity(0.15),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Image.asset(_trophyAsset, fit: BoxFit.contain),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // ===== WHITE PANEL =====
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: app.panelBg,
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(28),
//                     topRight: Radius.circular(28),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Expanded(
//                       child: ListView(
//                         padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
//                         children: [
//                           _SectionTitle(
//                             'Personal Information',
//                             grey: true,
//                             colorWhenGrey: app.label,
//                             colorWhenPrimary: cs.onSurface,
//                           ),

//                           _SettingTile(
//                             icon: Icons.person_outline,
//                             title: 'Student Name',
//                             subtitle: _studentName,
//                             onTap: () async {
//                               final result = await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (_) => const StudentNamePage()),
//                               );

//                               if (result != null && mounted) {
//                                 final f = (result['firstName'] as String?)?.trim() ?? '';
//                                 final l = (result['lastName'] as String?)?.trim() ?? '';
//                                 setState(() {
//                                   _studentName = [f, l].where((s) => s.isNotEmpty).join(' ');
//                                 });
//                               }
//                             },
//                             titleColor: cs.onSurface,
//                             subtitleColor:
//                                 Theme.of(context).textTheme.bodyMedium?.color ?? cs.onSurface.withOpacity(.7),
//                             iconColor: cs.onSurface,
//                           ),

//                           _SettingTile(
//                             icon: Icons.alternate_email_outlined,
//                             title: 'Email',
//                             subtitle: _studentEmail,
//                             onTap: () async {
//                               final result = await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (_) => const StudentEmailPage()),
//                               );

//                               if (!mounted) return;

//                               // Show "pending" email immediately if the email page sent it back
//                               if (result is Map && result['pendingEmail'] is String) {
//                                 setState(() => _studentEmail = result['pendingEmail'] as String);
//                               }

//                               // After user possibly verified via email link, try to pick up change
//                               await _reloadAndSyncEmail();
//                             },
//                             titleColor: cs.onSurface,
//                             subtitleColor:
//                                 Theme.of(context).textTheme.bodyMedium?.color ?? cs.onSurface.withOpacity(.7),
//                             iconColor: cs.onSurface,
//                           ),

//                           _SettingTile(
//                             icon: Icons.lock_outline,
//                             title: 'Security & Password',
//                             subtitle: 'Change Password',
//                             onTap: () => Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const StudentSecurityPasswordPage(),
//                               ),
//                             ),
//                             titleColor: cs.onSurface,
//                             subtitleColor:
//                                 Theme.of(context).textTheme.bodyMedium?.color ?? cs.onSurface.withOpacity(.7),
//                             iconColor: cs.onSurface,
//                           ),

//                           _SettingTile(
//                             icon: Icons.brightness_6_outlined,
//                             title: 'Change Theme',
//                             subtitle: 'Toggle Dark / Light Mode',
//                             onTap: () => Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const ThemeSelection()),
//                             ),
//                             titleColor: cs.onSurface,
//                             subtitleColor:
//                                 Theme.of(context).textTheme.bodyMedium?.color ?? cs.onSurface.withOpacity(.7),
//                             iconColor: cs.onSurface,
//                           ),

//                           _SettingTile(
//                             icon: Icons.school_outlined,
//                             title: 'My Learnings',
//                             subtitle: 'Achievements & Progresses',
//                             onTap: () {},
//                             titleColor: cs.onSurface,
//                             subtitleColor:
//                                 Theme.of(context).textTheme.bodyMedium?.color ?? cs.onSurface.withOpacity(.7),
//                             iconColor: cs.onSurface,
//                           ),
//                         ],
//                       ),
//                     ),

//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
//                       child: SizedBox(
//                         width: double.infinity,
//                         height: 56,
//                         child: ElevatedButton(
//                           onPressed: () async {
//                             await FirebaseAuth.instance.signOut();
//                             if (!mounted) return;
//                             Navigator.of(
//                               context,
//                               rootNavigator: true,
//                             ).pushAndRemoveUntil(
//                               MaterialPageRoute(builder: (_) => const Login()),
//                               (route) => false,
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: cs.error,
//                             foregroundColor: cs.onError,
//                             elevation: 4,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(18),
//                             ),
//                             textStyle: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                           child: const Text('Sign Out'),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _SectionTitle extends StatelessWidget {
//   final String text;
//   final bool grey;
//   final Color colorWhenGrey;
//   final Color colorWhenPrimary;

//   const _SectionTitle(
//     this.text, {
//     this.grey = false,
//     required this.colorWhenGrey,
//     required this.colorWhenPrimary,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: grey ? colorWhenGrey : colorWhenPrimary,
//           fontSize: 18,
//           fontWeight: FontWeight.w800,
//         ),
//       ),
//     );
//   }
// }

// class _SettingTile extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String? subtitle;
//   final VoidCallback? onTap;
//   final Color titleColor;
//   final Color subtitleColor;
//   final Color iconColor;

//   const _SettingTile({
//     required this.icon,
//     required this.title,
//     this.subtitle,
//     this.onTap,
//     required this.titleColor,
//     required this.subtitleColor,
//     required this.iconColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final content = Container(
//       height: 64,
//       padding: const EdgeInsets.symmetric(horizontal: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Icon(icon, color: iconColor, size: 28),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w800,
//                     color: titleColor,
//                   ),
//                 ),
//                 if (subtitle != null) ...[
//                   const SizedBox(height: 4),
//                   Text(
//                     subtitle!,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: subtitleColor,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           Icon(Icons.chevron_right_rounded, color: iconColor, size: 22),
//         ],
//       ),
//     );

//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: onTap,
//         child: content,
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'StudentNamePage.dart';
import 'StudentEmailPage.dart';
import 'StudentSecurityPasswordPage.dart';
import '../../Theme/ThemeSelectionSetting.dart';
import '../../Theme/Themes.dart';
import '../../Login/LoginPage.dart';

class StudentUserProfilePage extends StatefulWidget {
  const StudentUserProfilePage({super.key});

  @override
  _StudentUserProfilePageState createState() => _StudentUserProfilePageState();
}

class _StudentUserProfilePageState extends State<StudentUserProfilePage> {
  String _studentName = '';
  String _studentEmail = '';
  final _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _authSub;
  bool _syncing = false; // guard so logs don’t go crazy

  static const _trophyAsset =
      'assets/images/StudentProfileImages/trophy-star.png';
  static const _avatarAsset = 'assets/images/StudentProfileImages/student.png';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _reloadAndSyncEmail();

    // Listen to changes while this page is alive (guarded)
    _authSub = _auth.userChanges().listen((_) {
      if (_syncing) return;
      _reloadAndSyncEmail();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _studentName = doc.exists &&
                doc.data()?['firstName'] != null &&
                doc.data()?['lastName'] != null
            ? '${doc['firstName']} ${doc['lastName']}'
            : user.displayName ?? 'Student';
        _studentEmail = doc.exists && doc.data()?['email'] != null
            ? (doc['email'] as String)
            : (user.email ?? 'student@gmail.com');
      });
    }
  }

  // Reload Auth, mirror new email to Firestore, refresh header
  Future<void> _reloadAndSyncEmail() async {
    _syncing = true;
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user == null) return;

      final authEmail = user.email;

      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snap = await ref.get();
      final fsEmail = snap.data()?['email'] as String?;

      if (authEmail != null && authEmail != fsEmail) {
        await ref.update({
          'email': authEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted && authEmail != null) {
        setState(() => _studentEmail = authEmail);
      }
    } finally {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: app.headerBg,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Student Profile',
                    style: TextStyle(
                      color: app.headerFg,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: Container(
                          width: 56,
                          height: 56,
                          color: Theme.of(context).cardColor.withOpacity(.25),
                          child: Image.asset(
                            _avatarAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: app.headerFg,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _studentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: app.headerFg,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _studentEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: app.headerFgMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(_trophyAsset, fit: BoxFit.contain),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // PANEL
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
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                        children: [
                          _SectionTitle(
                            'Personal Information',
                            grey: true,
                            colorWhenGrey: app.label,
                            colorWhenPrimary: cs.onSurface,
                          ),

                          _SettingTile(
                            icon: Icons.person_outline,
                            title: 'Student Name',
                            subtitle: _studentName,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StudentNamePage(),
                                ),
                              );
                              if (result != null && mounted) {
                                final f =
                                    (result['firstName'] as String?)?.trim() ?? '';
                                final l =
                                    (result['lastName'] as String?)?.trim() ?? '';
                                setState(() {
                                  _studentName =
                                      [f, l].where((s) => s.isNotEmpty).join(' ');
                                });
                              }
                            },
                            titleColor: cs.onSurface,
                            subtitleColor:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                    cs.onSurface.withOpacity(.7),
                            iconColor: cs.onSurface,
                          ),

                          _SettingTile(
                            icon: Icons.alternate_email_outlined,
                            title: 'Email',
                            subtitle: _studentEmail,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StudentEmailPage(),
                                ),
                              );
                              if (!mounted) return;

                              // Show pending immediately if returned
                              if (result is Map &&
                                  result['pendingEmail'] is String) {
                                setState(() =>
                                    _studentEmail = result['pendingEmail'] as String);
                              }

                              // Try to pick up a completed change
                              await _reloadAndSyncEmail();
                            },
                            titleColor: cs.onSurface,
                            subtitleColor:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                    cs.onSurface.withOpacity(.7),
                            iconColor: cs.onSurface,
                          ),

                          _SettingTile(
                            icon: Icons.lock_outline,
                            title: 'Security & Password',
                            subtitle: 'Change Password',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const StudentSecurityPasswordPage(),
                              ),
                            ),
                            titleColor: cs.onSurface,
                            subtitleColor:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                    cs.onSurface.withOpacity(.7),
                            iconColor: cs.onSurface,
                          ),

                          _SettingTile(
                            icon: Icons.brightness_6_outlined,
                            title: 'Change Theme',
                            subtitle: 'Toggle Dark / Light Mode',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ThemeSelection(),
                              ),
                            ),
                            titleColor: cs.onSurface,
                            subtitleColor:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                    cs.onSurface.withOpacity(.7),
                            iconColor: cs.onSurface,
                          ),

                          _SettingTile(
                            icon: Icons.school_outlined,
                            title: 'My Learnings',
                            subtitle: 'Achievements & Progresses',
                            onTap: () {},
                            titleColor: cs.onSurface,
                            subtitleColor:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                    cs.onSurface.withOpacity(.7),
                            iconColor: cs.onSurface,
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (!mounted) return;
                            Navigator.of(context, rootNavigator: true)
                                .pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const Login()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.error,
                            foregroundColor: cs.onError,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ),
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
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final bool grey;
  final Color colorWhenGrey;
  final Color colorWhenPrimary;

  const _SectionTitle(
    this.text, {
    this.grey = false,
    required this.colorWhenGrey,
    required this.colorWhenPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: grey ? colorWhenGrey : colorWhenPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color titleColor;
  final Color subtitleColor;
  final Color iconColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    required this.titleColor,
    required this.subtitleColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: iconColor, size: 22),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
