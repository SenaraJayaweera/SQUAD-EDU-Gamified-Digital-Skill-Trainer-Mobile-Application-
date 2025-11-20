import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'TeacherEmailPage.dart';
import 'TeacherNamePage.dart';
import 'TeacherSecurityPasswordPage.dart';
import '../../Theme/ThemeSelectionSetting.dart';
import '../../Theme/Themes.dart';
import '../../Login/LoginPage.dart';

class TeacherUserProfilePage extends StatefulWidget {
  const TeacherUserProfilePage({super.key});

  @override
  _TeacherUserProfilePageState createState() => _TeacherUserProfilePageState();
}

class _TeacherUserProfilePageState extends State<TeacherUserProfilePage> {
  final _auth = FirebaseAuth.instance;

  String _teacherName = 'Teacher';
  String _teacherEmail = 'teacher@gmail.com';
  bool _loading = true;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  StreamSubscription<User?>? _authSub;

  // Assets
  static const _trophyAsset =
      'assets/images/StudentProfileImages/trophy-star.png';
  static const _avatarAsset = 'assets/images/StudentProfileImages/student.png';

  @override
  void initState() {
    super.initState();
    _bindStreamsAndLoad();
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _bindStreamsAndLoad() async {
    await _loadUserData(); // initial paint asap

    final user = _auth.currentUser;
    if (user == null) return;

    // Listen to Firestore user doc for live name/email updates.
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    _userDocSub = docRef.snapshots().listen((doc) {
      if (!mounted) return;
      final data = doc.data();
      final first = (data?['firstName'] as String?)?.trim();
      final last = (data?['lastName'] as String?)?.trim();
      final fsEmail = (data?['email'] as String?)?.trim();

      final name = (first?.isNotEmpty == true || last?.isNotEmpty == true)
          ? '${first ?? ''} ${last ?? ''}'.trim()
          : _auth.currentUser?.displayName ?? _teacherName;

      setState(() {
        _teacherName = name.isNotEmpty ? name : 'Teacher';
        // Prefer Firestore email if present, else fall back to auth email.
        _teacherEmail = (fsEmail?.isNotEmpty == true)
            ? fsEmail!
            : (_auth.currentUser?.email ?? _teacherEmail);
        _loading = false;
      });
    });

    // Listen to Auth changes (e.g., email changed after verification)
    _authSub = _auth.userChanges().listen((u) async {
      if (!mounted) return;
      // If Auth email differs from what we show, update state and mirror to Firestore.
      final authEmail = u?.email ?? '';
      if (authEmail.isNotEmpty && authEmail != _teacherEmail) {
        setState(() => _teacherEmail = authEmail);
        await _syncEmailToFirestoreIfChanged();
      }
    });
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};
      final first = (data['firstName'] as String?)?.trim();
      final last = (data['lastName'] as String?)?.trim();
      final fsEmail = (data['email'] as String?)?.trim();
      final name = (first?.isNotEmpty == true || last?.isNotEmpty == true)
          ? '${first ?? ''} ${last ?? ''}'.trim()
          : (user.displayName ?? 'Teacher');

      if (!mounted) return;
      setState(() {
        _teacherName = name.isNotEmpty ? name : 'Teacher';
        _teacherEmail = (fsEmail?.isNotEmpty == true)
            ? fsEmail!
            : (user.email ?? 'teacher@gmail.com');
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Mirrors the auth email into Firestore if different.
  Future<void> _syncEmailToFirestoreIfChanged() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snap = await docRef.get();
      final fsEmail = (snap.data()?['email'] as String?)?.trim();
      final authEmail = user.email?.trim();

      if (authEmail != null && authEmail.isNotEmpty && fsEmail != authEmail) {
        await docRef.update({
          'email': authEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // ignore – not fatal for UI
    }
  }

  Future<void> _openNamePage() async {
    // Wait for edit screen to close, then refresh from Firestore.
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TeacherNamePage()),
    );
    // If TeacherNamePage writes to Firestore, our snapshot listener will update.
    // We also force a refresh in case it popped without writing.
    await _loadUserData();
  }

  Future<void> _openEmailPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TeacherEmailPage()),
    );

    // If your TeacherEmailPage returns {'pendingEmail': '...'} after verifyBeforeUpdateEmail,
    // we can notify here. (When you wire backend like Student flow.)
    if (result is Map && result['pendingEmail'] is String) {
      final pending = (result['pendingEmail'] as String).trim();
      if (pending.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification sent to $pending. Confirm from your inbox to finish.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }

    // After user confirms via email, Firebase Auth email changes.
    // Our auth listener will trigger and then this mirrors to Firestore.
    await _syncEmailToFirestoreIfChanged();
    await _loadUserData();
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Teacher Profile',
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
                        child: _loading
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _ShimmerBar(color: app.headerFg, width: 140),
                                  const SizedBox(height: 6),
                                  _ShimmerBar(
                                      color: app.headerFgMuted, width: 180),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _teacherName,
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
                                    _teacherEmail,
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
                            title: 'Teacher Name',
                            subtitle: _teacherName,
                            onTap: _openNamePage,
                            titleColor: cs.onSurface,
                            subtitleColor:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                    cs.onSurface.withOpacity(.7),
                            iconColor: cs.onSurface,
                          ),
                          _SettingTile(
                            icon: Icons.alternate_email_outlined,
                            title: 'Email',
                            subtitle: _teacherEmail,
                            onTap: _openEmailPage,
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
                                    const TeacherSecurityPasswordPage(),
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
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushAndRemoveUntil(
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

// ===== Helper Widgets =====

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

class _ShimmerBar extends StatelessWidget {
  final Color color;
  final double width;
  const _ShimmerBar({required this.color, required this.width});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: width,
      decoration: BoxDecoration(
        color: color.withOpacity(.25),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
