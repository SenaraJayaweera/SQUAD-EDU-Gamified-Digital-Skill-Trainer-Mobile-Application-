import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/BackButtonWidget.dart'; // shared back button
import '../../Theme/Themes.dart';            // AppColors extension

class TeacherSecurityPasswordPage extends StatefulWidget {
  const TeacherSecurityPasswordPage({super.key});
  @override
  State<TeacherSecurityPasswordPage> createState() =>
      _TeacherSecurityPasswordPageState();
}

class _TeacherSecurityPasswordPageState
    extends State<TeacherSecurityPasswordPage> {
  // Compact pill sizes
  static const double _pillHeight = 52;
  static const double _pillRadius = 26;
  static const double _pillHPad = 18;

  // Controllers / focus
  final _oldC = TextEditingController();
  final _newC = TextEditingController();
  final _confirmC = TextEditingController();
  final _oldNode = FocusNode();
  final _newNode = FocusNode();
  final _confirmNode = FocusNode();

  bool _obsOld = true, _obsNew = true, _obsConfirm = true;
  bool _submitted = false;
  bool _saving = false;

  final _auth = FirebaseAuth.instance;

  // Validation state
  String? _oldError;            // wrong old pwd (set after reauth attempt OR inline check toggle)
  String? _confirmError;        // confirm mismatch
  bool _min8 = false, _upper = false, _lower = false, _num = false, _special = false;

  @override
  void initState() {
    super.initState();
    _oldC.addListener(_validateAllLive);
    _newC.addListener(_validateAllLive);
    _confirmC.addListener(_validateAllLive);
  }

  @override
  void dispose() {
    _oldC.dispose();
    _newC.dispose();
    _confirmC.dispose();
    _oldNode.dispose();
    _newNode.dispose();
    _confirmNode.dispose();
    super.dispose();
  }

  // ===== Validation (real-time) =====
  void _validateAllLive() {
    // Old password: do not pretend to know correctness until we try reauth;
    // just clear any previous error while typing.
    if ((_submitted && _oldC.text.isNotEmpty) || _oldC.text.isNotEmpty) {
      _oldError = null; // reset; we set a concrete message on failed reauth
    }

    // New password: 5 rules → border red until all pass, then green
    final s = _newC.text;
    _min8 = s.length >= 8;
    _upper = RegExp(r'[A-Z]').hasMatch(s);
    _lower = RegExp(r'[a-z]').hasMatch(s);
    _num = RegExp(r'[0-9]').hasMatch(s);
    _special = RegExp(r'''[!@#\$%^&*(),.?":{}|<>_\-\[\]\\/;'"`~+=]''').hasMatch(s);

    // Confirm: red only when mismatch (no green state)
    _confirmError = null;
    if (_submitted || _confirmC.text.isNotEmpty) {
      if (_confirmC.text != _newC.text) {
        _confirmError = 'Passwords do not match';
      }
    }

    setState(() {});
  }

  bool get _newAllOk => _min8 && _upper && _lower && _num && _special;

  // Helpers for borders to match UI precisely (uses themed colors)
  Color _oldBorder(AppColors app) {
    final show = _submitted || _oldC.text.isNotEmpty;
    if (show && _oldError != null) return app.error;
    return app.border;
  }

  Color _newBorder(AppColors app) {
    final show = _submitted || _newC.text.isNotEmpty;
    if (!show) return app.border;
    return _newAllOk ? app.success : app.error;
  }

  Color _confirmBorder(AppColors app) {
    final show = _submitted || _confirmC.text.isNotEmpty;
    if (show && _confirmError != null) return app.error;
    return app.border; // no green state for confirm
  }

  bool get _showChecklist => _submitted || _newC.text.isNotEmpty;

  Future<void> _onConfirmPressed() async {
    FocusScope.of(context).unfocus();
    _submitted = true;
    _validateAllLive();

    // front-end checks first
    if (!_newAllOk || _confirmError != null || _confirmC.text.isEmpty) {
      return;
    }
    if (_oldC.text.isEmpty) {
      setState(() => _oldError = 'Please enter your current password');
      return;
    }

    final user = _auth.currentUser;
    if (user == null || (user.email == null || user.email!.isEmpty)) {
      // Can’t reauth without an email credential in this flow
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in again to change your password.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // 1) Reauthenticate with OLD password
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _oldC.text,
      );
      await user.reauthenticateWithCredential(cred);

      // 2) Update to NEW password
      await user.updatePassword(_newC.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password updated successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      // Map common codes to great UX
      String msg;
      switch (e.code) {
        case 'wrong-password':
          msg = 'The current password you entered is incorrect.';
          _oldError = msg; // also mark field with error
          break;
        case 'invalid-credential':
        case 'user-mismatch':
          msg = 'Please sign in again and try changing your password.';
          break;
        case 'requires-recent-login':
          msg = 'For your security, please sign in again and then retry.';
          break;
        case 'weak-password':
          msg = 'That password is too weak. Please meet all requirements.';
          break;
        case 'too-many-requests':
          msg = 'Too many attempts. Please wait a moment and try again.';
          break;
        default:
          msg = e.message ?? 'Could not update password.';
      }
      if (!mounted) return;
      setState(() {}); // reflect potential _oldError
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // helper to avoid deprecated withOpacity
  Color _alpha(Color c, double a) => c.withValues(alpha: a);

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: app.headerBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header: back (left) + lock + title (center)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: SizedBox(
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: CircleBackButton(), // shared back button
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, color: app.headerFg, size: 64),
                        const SizedBox(height: 10),
                        Text(
                          'Security & Password',
                          style: TextStyle(
                            color: app.headerFg,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // White panel
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
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    24,
                    22,
                    MediaQuery.of(context).viewInsets.bottom + 16, // avoid overflow
                  ),
                  children: [
                    const _Label('Old Password'),
                    _PillPassword(
                      controller: _oldC,
                      focusNode: _oldNode,
                      nextFocus: _newNode,
                      hint: 'Your password',
                      obscure: _obsOld,
                      onToggleObscure: () => setState(() => _obsOld = !_obsOld),
                      borderColor: _oldBorder(app),
                    ),
                    if (_oldError != null) ...[
                      const SizedBox(height: 6),
                      _ErrorRow(text: _oldError!),
                    ],

                    const SizedBox(height: 22),

                    const _Label('New Password'),
                    _PillPassword(
                      controller: _newC,
                      focusNode: _newNode,
                      nextFocus: _confirmNode,
                      hint: 'Your password',
                      obscure: _obsNew,
                      onToggleObscure: () => setState(() => _obsNew = !_obsNew),
                      borderColor: _newBorder(app),
                    ),
                    if (_showChecklist) ...[
                      const SizedBox(height: 6),
                      _PasswordChecklist(
                        ok: _newAllOk,
                        min8: _min8,
                        upper: _upper,
                        lower: _lower,
                        num: _num,
                        special: _special,
                      ),
                    ],

                    const SizedBox(height: 22),

                    const _Label('Confirm Password'),
                    _PillPassword(
                      controller: _confirmC,
                      focusNode: _confirmNode,
                      hint: 'Your password',
                      obscure: _obsConfirm,
                      onToggleObscure: () => setState(() => _obsConfirm = !_obsConfirm),
                      borderColor: _confirmBorder(app),
                    ),
                    if (_confirmError != null) ...[
                      const SizedBox(height: 6),
                      _ErrorRow(text: _confirmError!),
                    ],

                    const SizedBox(height: 28),

                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _onConfirmPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _saving
                              ? _alpha(app.ctaBlue, 0.45)
                              : app.ctaBlue,     // themed CTA
                          foregroundColor: cs.onPrimary,     // readable text
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Confirm'),
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

// ===== Small pieces (theme-aware) =====

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: app.label,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PillPassword extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final String hint;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final Color borderColor;

  const _PillPassword({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggleObscure,
    required this.borderColor,
    this.focusNode,
    this.nextFocus,
  });

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      height: _TeacherSecurityPasswordPageState._pillHeight,
      decoration: BoxDecoration(
        color: app.panelBg,
        borderRadius:
            BorderRadius.circular(_TeacherSecurityPasswordPageState._pillRadius),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: _TeacherSecurityPasswordPageState._pillHPad),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 20, color: app.hint),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction:
                  nextFocus == null ? TextInputAction.done : TextInputAction.next,
              onSubmitted: (_) {
                if (nextFocus != null) {
                  FocusScope.of(context).requestFocus(nextFocus);
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
              obscureText: obscure,
              inputFormatters: [LengthLimitingTextInputFormatter(64)],
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: app.hint,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onToggleObscure,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: textColor,
                ),
                const SizedBox(width: 6),
                Text(
                  obscure ? 'Show' : 'Hide',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String text;
  const _ErrorRow({required this.text});
  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Icon(Icons.error_outline, size: 20, color: app.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: app.error,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// Two-column checklist; whole block red until all rules pass, then green
class _PasswordChecklist extends StatelessWidget {
  final bool ok;
  final bool min8, upper, lower, num, special;
  const _PasswordChecklist({
    required this.ok,
    required this.min8,
    required this.upper,
    required this.lower,
    required this.num,
    required this.special,
  });

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final color = ok ? app.success : app.error;
    final icon = ok
        ? Icon(Icons.check_circle, size: 20, color: app.success)
        : Icon(Icons.error_outline, size: 20, color: app.error);
    final title = ok
        ? 'Strong password.'
        : 'Password must meet all requirements.';

    Widget bullet(String t) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 6, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                t,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          icon,
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ]),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, c) {
          final w = (c.maxWidth - 18) / 2;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bullet('minimum 8 characters'),
                    const SizedBox(height: 8),
                    bullet('one special character'),
                    const SizedBox(height: 8),
                    bullet('one number'),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              SizedBox(
                width: w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bullet('one uppercase character'),
                    const SizedBox(height: 8),
                    bullet('one lowercase character'),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
