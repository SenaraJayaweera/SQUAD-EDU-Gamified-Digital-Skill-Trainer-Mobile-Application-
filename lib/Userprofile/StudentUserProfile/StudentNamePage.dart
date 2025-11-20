import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/BackButtonWidget.dart';
import '../../Theme/Themes.dart';

class StudentNamePage extends StatefulWidget {
  const StudentNamePage({super.key});
  @override
  State<StudentNamePage> createState() => _StudentNamePageState();
}

class _StudentNamePageState extends State<StudentNamePage> {
  final _firstC = TextEditingController();
  final _lastC = TextEditingController();
  final _firstNode = FocusNode();
  final _lastNode = FocusNode();

  bool _firstDirty = false;
  bool _lastDirty = false;
  bool _submitted = false;

  // Validation
  static final _nameRe = RegExp(r"^[A-Za-z][A-Za-z\s'\-]{0,14}$");
  String? _validate(String v) {
    final s = v.trim();
    if (s.isEmpty || s.length > 15) return 'Please enter a valid name';
    return _nameRe.hasMatch(s) ? null : 'Please enter a valid name';
  }

  String? get _firstErr => _validate(_firstC.text);
  String? get _lastErr => _validate(_lastC.text);

  bool get _showFirstError => (_submitted || _firstDirty) && _firstErr != null;
  bool get _showLastError => (_submitted || _lastDirty) && _lastErr != null;

  Color _borderFor(bool showErr, AppColors app) =>
      showErr ? app.error : app.border;

  // -------- load current values so inputs are prefilled
  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && snap.exists) {
        _firstC.text = (snap.data()?['firstName'] as String?)?.trim() ?? '';
        _lastC.text = (snap.data()?['lastName'] as String?)?.trim() ?? '';
        setState(() {}); // refresh counters
      }
    } catch (_) {
      // keep fields empty on error
    }
  }

  @override
  void dispose() {
    _firstC.dispose();
    _lastC.dispose();
    _firstNode.dispose();
    _lastNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final pillHeight = screenHeight * 0.06;
    final pillHPad = screenWidth * 0.04;
    final buttonHeight = screenHeight * 0.07;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: app.headerBg,
      body: SafeArea(
        child: Column(
          children: [
            // ===== FIXED HEADER =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: SizedBox(
                height: 114,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: CircleBackButton(),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, color: Colors.white, size: 64),
                        const SizedBox(height: 10),
                        Text(
                          'Student Name',
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

            // ===== White panel =====
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
                  padding: EdgeInsets.fromLTRB(
                    22,
                    24,
                    22,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('First Name'),
                      _PillNameField(
                        controller: _firstC,
                        focusNode: _firstNode,
                        nextFocus: _lastNode,
                        hint: 'First Name',
                        height: pillHeight,
                        radius: 22,
                        hPad: pillHPad,
                        borderColor: _borderFor(_showFirstError, app),
                        hintColor: app.hint,
                        onChanged: (_) {
                          if (!_firstDirty) _firstDirty = true;
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 4),
                      _OutsideCounter(
                        len: _firstC.text.trim().length,
                        max: 15,
                        color: app.counterGrey,
                      ),
                      if (_showFirstError) _TightErrorRow(errorText: _firstErr ?? ''),

                      const SizedBox(height: 22),

                      const _Label('Last Name'),
                      _PillNameField(
                        controller: _lastC,
                        focusNode: _lastNode,
                        hint: 'Last Name',
                        height: pillHeight,
                        radius: 22,
                        hPad: pillHPad,
                        borderColor: _borderFor(_showLastError, app),
                        hintColor: app.hint,
                        onChanged: (_) {
                          if (!_lastDirty) _lastDirty = true;
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 4),
                      _OutsideCounter(
                        len: _lastC.text.trim().length,
                        max: 15,
                        color: app.counterGrey,
                      ),
                      if (_showLastError) _TightErrorRow(errorText: _lastErr ?? ''),

                      const SizedBox(height: 28),

                      SizedBox(
                        height: buttonHeight,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            FocusScope.of(context).unfocus();
                            setState(() => _submitted = true);
                            if (_firstErr != null || _lastErr != null) return;

                            // ---- SAVE to Firestore: ONLY firstName, lastName (no fullName)
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            try {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .update({
                                'firstName': _firstC.text.trim(),
                                'lastName': _lastC.text.trim(),
                                'updatedAt': FieldValue.serverTimestamp(),
                              });

                              if (!mounted) return;
                              // Return just first/last to caller
                              Navigator.of(context).pop({
                                'firstName': _firstC.text.trim(),
                                'lastName': _lastC.text.trim(),
                              });
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Save failed: $e'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: app.saveGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Text('Save'),
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

// ===== Reusable pieces =====

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
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PillNameField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final String hint;
  final double height;
  final double radius;
  final double hPad;
  final Color borderColor;
  final Color hintColor;
  final ValueChanged<String> onChanged;

  const _PillNameField({
    required this.controller,
    required this.hint,
    required this.height,
    required this.radius,
    required this.hPad,
    required this.borderColor,
    required this.hintColor,
    required this.onChanged,
    this.focusNode,
    this.nextFocus,
  });

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: app.panelBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1.6),
      ),
      padding: EdgeInsets.symmetric(horizontal: hPad),
      alignment: Alignment.centerLeft,
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
        onChanged: onChanged,
        inputFormatters: [
          LengthLimitingTextInputFormatter(15),
          FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s'\-]")),
        ],
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          counterText: '',
        ),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: app.label,
        ),
        textCapitalization: TextCapitalization.words,
      ),
    );
  }
}

class _OutsideCounter extends StatelessWidget {
  final int len;
  final int max;
  final Color color;
  const _OutsideCounter({
    required this.len,
    required this.max,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$len/$max',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      );
}

class _TightErrorRow extends StatelessWidget {
  final String errorText;
  const _TightErrorRow({required this.errorText});
  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: app.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorText,
              style: TextStyle(
                color: app.error,
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
