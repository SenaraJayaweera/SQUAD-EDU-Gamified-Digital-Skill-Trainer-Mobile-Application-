// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// import '../../widgets/BackButtonWidget.dart';
// import '../../Theme/Themes.dart';

// /// STUDENT EMAIL — same UI as TeacherEmailPage + real backend (verifyBeforeUpdateEmail)
// class StudentEmailPage extends StatefulWidget {
//   const StudentEmailPage({super.key});
//   @override
//   State<StudentEmailPage> createState() => _StudentEmailPageState();
// }

// class _StudentEmailPageState extends State<StudentEmailPage> {
//   // Sizes (match TeacherEmailPage)
//   static const double _pillHeight = 54;
//   static const double _pillRadius = 27;
//   static const double _pillHPad = 18;
//   static const double _gapFields = 28;

//   final _newC = TextEditingController();
//   final _confirmC = TextEditingController();
//   final _newNode = FocusNode();
//   final _confirmNode = FocusNode();

//   bool _newDirty = false;
//   bool _confirmDirty = false;
//   bool _submitted = false;
//   bool _saving = false;

//   final _auth = FirebaseAuth.instance;

//   @override
//   void dispose() {
//     _newC.dispose();
//     _confirmC.dispose();
//     _newNode.dispose();
//     _confirmNode.dispose();
//     super.dispose();
//   }

//   // Email regex (strict enough for UI)
//   static final _emailRe =
//       RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$');

//   bool get _newValid => _emailRe.hasMatch(_newC.text.trim());
//   bool get _confirmValid => _emailRe.hasMatch(_confirmC.text.trim());
//   bool get _emailsMatch {
//     final a = _newC.text.trim().toLowerCase();
//     final b = _confirmC.text.trim().toLowerCase();
//     return a.isNotEmpty && b.isNotEmpty && a == b;
//   }

//   bool get _canSubmit => _newValid && _confirmValid && _emailsMatch;

//   bool _showNewError() =>
//       (_submitted || _newDirty) && !_newValid && _newC.text.isNotEmpty;
//   bool _showConfirmMatch() =>
//       (_submitted || _confirmDirty) && _confirmValid && _emailsMatch;
//   bool _showConfirmError() =>
//       (_submitted || _confirmDirty) && _confirmValid && !_emailsMatch;

//   Future<void> _handleConfirm() async {
//     if (!_canSubmit) {
//       setState(() => _submitted = true);
//       return;
//     }

//     final newEmail = _newC.text.trim();

//     setState(() => _saving = true);
//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         throw FirebaseAuthException(code: 'no-user', message: 'Not signed in');
//       }

//       // Sends verification email to newEmail; auth email updates after user clicks link.
//       await user.verifyBeforeUpdateEmail(newEmail);

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Verification sent to $newEmail. Confirm from your inbox to finish.'),
//           behavior: SnackBarBehavior.floating,
//           backgroundColor: Theme.of(context).colorScheme.primary,
//         ),
//       );

//       // Pass hint back to the Profile page (optional)
//       Navigator.of(context).pop({'pendingEmail': newEmail});
//     } on FirebaseAuthException catch (e) {
//       if (!mounted) return;
//       String msg;
//       switch (e.code) {
//         case 'requires-recent-login':
//           msg = 'Please sign in again and retry changing your email.';
//           break;
//         case 'invalid-email':
//           msg = 'That email looks invalid.';
//           break;
//         case 'email-already-in-use':
//           msg = 'That email is already in use.';
//           break;
//         case 'too-many-requests':
//           msg = 'Too many attempts. Please try again later.';
//           break;
//         default:
//           msg = e.message ?? 'Something went wrong';
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(msg),
//           behavior: SnackBarBehavior.floating,
//           backgroundColor: Theme.of(context).colorScheme.error,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           behavior: SnackBarBehavior.floating,
//           backgroundColor: Theme.of(context).colorScheme.error,
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   /// OPTIONAL: call from Profile after app is reopened to mirror Auth.email -> Firestore
//   static Future<bool> syncEmailToFirestoreIfChanged() async {
//     final auth = FirebaseAuth.instance;
//     await auth.currentUser?.reload();
//     final user = auth.currentUser;
//     if (user == null) return false;

//     try {
//       await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
//         'email': user.email,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final app = Theme.of(context).extension<AppColors>()!;

//     Color borderColorForNew() => _showNewError() ? app.error : app.border;

//     Color borderColorForConfirm() {
//       if (_showConfirmError()) return app.error;
//       if (_showConfirmMatch()) return app.success;
//       return app.border;
//     }

//     // Newer Flutter deprecates withOpacity; use withValues(alpha: ...)
//     Color _alpha(Color c, double a) => c.withValues(alpha: a);

//     return Scaffold(
//       backgroundColor: app.headerBg,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header (same as TeacherEmailPage)
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
//               child: SizedBox(
//                 height: 130,
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: const [
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: CircleBackButton(),
//                     ),
//                     _HeaderIconAndTitle(),
//                   ],
//                 ),
//               ),
//             ),

//             // Rounded panel
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
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _Label('New Email', labelColor: app.label),
//                       _PillEmailField(
//                         controller: _newC,
//                         focusNode: _newNode,
//                         nextFocus: _confirmNode,
//                         hint: 'linda@framcreative.com',
//                         height: _pillHeight,
//                         radius: _pillRadius,
//                         hPad: _pillHPad,
//                         borderColor: borderColorForNew(),
//                         iconColor: app.iconMuted,
//                         hintColor: app.hint,
//                         textSize: 18,
//                         fillColor: app.panelBg,
//                         onChanged: (_) {
//                           if (!_newDirty) _newDirty = true;
//                           setState(() {});
//                         },
//                       ),
//                       if (_showNewError())
//                         _TightErrorRow(
//                           text: 'Please Enter Valid Email',
//                           color: app.error,
//                         ),

//                       const SizedBox(height: _gapFields),

//                       _Label('Confirm Email', labelColor: app.label),
//                       _PillEmailField(
//                         controller: _confirmC,
//                         focusNode: _confirmNode,
//                         hint: 'linda@framcreative.com',
//                         height: _pillHeight,
//                         radius: _pillRadius,
//                         hPad: _pillHPad,
//                         borderColor: borderColorForConfirm(),
//                         iconColor: app.iconMuted,
//                         hintColor: app.hint,
//                         textSize: 18,
//                         fillColor: app.panelBg,
//                         onChanged: (_) {
//                           if (!_confirmDirty) _confirmDirty = true;
//                           setState(() {});
//                         },
//                       ),
//                       if (_showConfirmError())
//                         _TightErrorRow(text: 'Email does not match', color: app.error),
//                       if (_showConfirmMatch())
//                         _TightOkRow(text: 'Email Matched', color: app.success),

//                       const SizedBox(height: 28),

//                       SizedBox(
//                         height: 56,
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           onPressed: _saving ? null : _handleConfirm,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: _saving
//                                 ? _alpha(app.ctaBlue, 0.45)
//                                 : (_canSubmit ? app.ctaBlue : _alpha(app.ctaBlue, 0.45)),
//                             foregroundColor: _canSubmit ? Colors.white : app.iconMuted,
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(18),
//                             ),
//                             textStyle: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),
//                           child: _saving
//                               ? const SizedBox(
//                                   height: 20,
//                                   width: 20,
//                                   child: CircularProgressIndicator(strokeWidth: 2),
//                                 )
//                               : const Text('Confirm'),
//                         ),
//                       ),

//                       const SizedBox(height: 10),
//                       Text(
//                         "After confirming the link in your inbox, re-open this app. We'll automatically pick up your new email.",
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: cs.onSurface.withValues(alpha: 0.7),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ===== Header widgets =====

// class _HeaderIconAndTitle extends StatelessWidget {
//   const _HeaderIconAndTitle({super.key});
//   @override
//   Widget build(BuildContext context) {
//     final app = Theme.of(context).extension<AppColors>()!;
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(Icons.alternate_email_rounded, color: app.headerFg, size: 76),
//         const SizedBox(height: 10),
//         Text(
//           'Email',
//           style: TextStyle(
//             color: app.headerFg,
//             fontSize: 28,
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ===== Form widgets =====

// class _Label extends StatelessWidget {
//   final String text;
//   final Color labelColor;
//   const _Label(this.text, {required this.labelColor, super.key});
//   @override
//   Widget build(BuildContext context) => Padding(
//         padding: const EdgeInsets.only(bottom: 10),
//         child: Text(
//           text,
//           style: TextStyle(
//             color: labelColor,
//             fontSize: 16,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       );
// }

// class _PillEmailField extends StatelessWidget {
//   final TextEditingController controller;
//   final FocusNode? focusNode;
//   final FocusNode? nextFocus;
//   final String hint;
//   final double height;
//   final double radius;
//   final double hPad;
//   final Color borderColor;
//   final Color iconColor;
//   final Color hintColor;
//   final Color fillColor;
//   final double textSize;
//   final ValueChanged<String> onChanged;

//   const _PillEmailField({
//     required this.controller,
//     required this.hint,
//     required this.height,
//     required this.radius,
//     required this.hPad,
//     required this.borderColor,
//     required this.iconColor,
//     required this.hintColor,
//     required this.fillColor,
//     required this.textSize,
//     required this.onChanged,
//     this.focusNode,
//     this.nextFocus,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: height,
//       decoration: BoxDecoration(
//         color: fillColor,
//         borderRadius: BorderRadius.circular(radius),
//         border: Border.all(color: borderColor, width: 1.6),
//       ),
//       padding: EdgeInsets.symmetric(horizontal: hPad),
//       alignment: Alignment.centerLeft,
//       child: Row(
//         children: [
//           Icon(Icons.mail_outline_rounded, color: iconColor, size: 22),
//           const SizedBox(width: 10),
//           Expanded(
//             child: TextField(
//               controller: controller,
//               focusNode: focusNode,
//               keyboardType: TextInputType.emailAddress,
//               textInputAction:
//                   nextFocus == null ? TextInputAction.done : TextInputAction.next,
//               onSubmitted: (_) {
//                 if (nextFocus != null) {
//                   FocusScope.of(context).requestFocus(nextFocus);
//                 } else {
//                   FocusScope.of(context).unfocus();
//                 }
//               },
//               onChanged: onChanged,
//               inputFormatters: [
//                 LengthLimitingTextInputFormatter(100),
//                 FilteringTextInputFormatter.deny(RegExp(r'\s')),
//               ],
//               decoration: InputDecoration(
//                 isCollapsed: true,
//                 border: InputBorder.none,
//                 hintText: hint,
//                 hintStyle: TextStyle(
//                   color: hintColor,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               style: TextStyle(
//                 fontSize: textSize,
//                 fontWeight: FontWeight.w600,
//                 color: Theme.of(context).colorScheme.onSurface,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _TightErrorRow extends StatelessWidget {
//   final String text;
//   final Color color;
//   const _TightErrorRow({required this.text, required this.color, super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 6),
//       child: Row(
//         children: [
//           Icon(Icons.error_outline, size: 18, color: color),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(
//                 color: color,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _TightOkRow extends StatelessWidget {
//   final String text;
//   final Color color;
//   const _TightOkRow({required this.text, required this.color, super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 6),
//       child: Row(
//         children: [
//           Icon(Icons.check_circle_outline, size: 18, color: color),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(
//                 color: color,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/BackButtonWidget.dart';
import '../../Theme/Themes.dart';

class StudentEmailPage extends StatefulWidget {
  const StudentEmailPage({super.key});
  @override
  State<StudentEmailPage> createState() => _StudentEmailPageState();
}

class _StudentEmailPageState extends State<StudentEmailPage> {
  // Match Teacher page sizes
  static const double _pillHeight = 54;
  static const double _pillRadius = 27;
  static const double _pillHPad = 18;
  static const double _gapFields = 28;

  final _newC = TextEditingController();
  final _confirmC = TextEditingController();
  final _newNode = FocusNode();
  final _confirmNode = FocusNode();

  bool _newDirty = false;
  bool _confirmDirty = false;
  bool _submitted = false;
  bool _saving = false;

  final _auth = FirebaseAuth.instance;

  // Email regex
  static final _emailRe =
      RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$');

  bool get _newValid => _emailRe.hasMatch(_newC.text.trim());
  bool get _confirmValid => _emailRe.hasMatch(_confirmC.text.trim());
  bool get _emailsMatch {
    final a = _newC.text.trim().toLowerCase();
    final b = _confirmC.text.trim().toLowerCase();
    return a.isNotEmpty && b.isNotEmpty && a == b;
  }
  bool get _canSubmit => _newValid && _confirmValid && _emailsMatch;

  bool _showNewError() =>
      (_submitted || _newDirty) && !_newValid && _newC.text.isNotEmpty;
  bool _showConfirmMatch() =>
      (_submitted || _confirmDirty) && _confirmValid && _emailsMatch;
  bool _showConfirmError() =>
      (_submitted || _confirmDirty) && _confirmValid && !_emailsMatch;

  // Send verification to new email, then return a pending hint
  Future<void> _handleConfirm() async {
    if (!_canSubmit) {
      setState(() => _submitted = true);
      return;
    }

    final newEmail = _newC.text.trim();
    setState(() => _saving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(code: 'no-user', message: 'Not signed in');
      }

      await user.verifyBeforeUpdateEmail(newEmail);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification sent to $newEmail. Confirm from your inbox to finish.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      // Return a hint so profile can show pending state
      Navigator.of(context).pop({'pendingEmail': newEmail});
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'requires-recent-login':
          msg = 'Please sign in again and retry changing your email.';
          break;
        case 'invalid-email':
          msg = 'That email looks invalid.';
          break;
        case 'email-already-in-use':
          msg = 'That email is already in use.';
          break;
        case 'too-many-requests':
          msg = 'Too many attempts. Please try again later.';
          break;
        default:
          msg = e.message ?? 'Something went wrong';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // UI helpers
  Color _alpha(Color c, double a) => c.withValues(alpha: a);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = Theme.of(context).extension<AppColors>()!;

    Color borderForNew() => _showNewError() ? app.error : app.border;
    Color borderForConfirm() {
      if (_showConfirmError()) return app.error;
      if (_showConfirmMatch()) return app.success;
      return app.border;
    }

    return Scaffold(
      backgroundColor: app.headerBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: SizedBox(
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CircleBackButton(),
                    ),
                    _HeaderIconAndTitle(),
                  ],
                ),
              ),
            ),

            // Panel
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('New Email', labelColor: app.label),
                      _PillEmailField(
                        controller: _newC,
                        focusNode: _newNode,
                        nextFocus: _confirmNode,
                        hint: 'linda@framcreative.com',
                        height: _pillHeight,
                        radius: _pillRadius,
                        hPad: _pillHPad,
                        borderColor: borderForNew(),
                        iconColor: app.iconMuted,
                        hintColor: app.hint,
                        textSize: 18,
                        fillColor: app.panelBg,
                        onChanged: (_) {
                          if (!_newDirty) _newDirty = true;
                          setState(() {});
                        },
                      ),
                      if (_showNewError())
                        _TightErrorRow(
                          text: 'Please Enter Valid Email',
                          color: app.error,
                        ),
                      const SizedBox(height: _gapFields),

                      _Label('Confirm Email', labelColor: app.label),
                      _PillEmailField(
                        controller: _confirmC,
                        focusNode: _confirmNode,
                        hint: 'linda@framcreative.com',
                        height: _pillHeight,
                        radius: _pillRadius,
                        hPad: _pillHPad,
                        borderColor: borderForConfirm(),
                        iconColor: app.iconMuted,
                        hintColor: app.hint,
                        textSize: 18,
                        fillColor: app.panelBg,
                        onChanged: (_) {
                          if (!_confirmDirty) _confirmDirty = true;
                          setState(() {});
                        },
                      ),
                      if (_showConfirmError())
                        _TightErrorRow(text: 'Email does not match', color: app.error),
                      if (_showConfirmMatch())
                        _TightOkRow(text: 'Email Matched', color: app.success),

                      const SizedBox(height: 28),
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _handleConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _saving
                                ? _alpha(app.ctaBlue, 0.45)
                                : (_canSubmit
                                    ? app.ctaBlue
                                    : _alpha(app.ctaBlue, 0.45)),
                            foregroundColor:
                                _canSubmit ? Colors.white : app.iconMuted,
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
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Confirm'),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        "After confirming the link in your inbox, re-open this app. We'll automatically pick up your new email.",
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Header + form bits
class _HeaderIconAndTitle extends StatelessWidget {
  const _HeaderIconAndTitle({super.key});
  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.alternate_email_rounded, color: app.headerFg, size: 76),
        const SizedBox(height: 10),
        Text('Email',
            style: TextStyle(
              color: app.headerFg,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            )),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color labelColor;
  const _Label(this.text, {required this.labelColor, super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            color: labelColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _PillEmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final String hint;
  final double height;
  final double radius;
  final double hPad;
  final Color borderColor;
  final Color iconColor;
  final Color hintColor;
  final Color fillColor;
  final double textSize;
  final ValueChanged<String> onChanged;

  const _PillEmailField({
    super.key,
    required this.controller,
    required this.hint,
    required this.height,
    required this.radius,
    required this.hPad,
    required this.borderColor,
    required this.iconColor,
    required this.hintColor,
    required this.fillColor,
    required this.textSize,
    required this.onChanged,
    this.focusNode,
    this.nextFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1.6),
      ),
      padding: EdgeInsets.symmetric(horizontal: hPad),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(Icons.mail_outline_rounded, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction:
                  nextFocus == null ? TextInputAction.done : TextInputAction.next,
              onSubmitted: (_) {
                if (nextFocus != null) {
                  FocusScope.of(context).requestFocus(nextFocus);
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
              onChanged: onChanged,
              inputFormatters: [
                LengthLimitingTextInputFormatter(100),
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: hintColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TightErrorRow extends StatelessWidget {
  final String text;
  final Color color;
  const _TightErrorRow({required this.text, required this.color, super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TightOkRow extends StatelessWidget {
  final String text;
  final Color color;
  const _TightOkRow({required this.text, required this.color, super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
