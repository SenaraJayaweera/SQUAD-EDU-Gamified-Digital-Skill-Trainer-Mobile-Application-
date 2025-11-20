import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../widgets/BackButtonWidget.dart';
import '../../Theme/Themes.dart';

class EditModulePage extends StatefulWidget {
  final Map<String, dynamic> moduleData; // Module data including document ID

  const EditModulePage({super.key, required this.moduleData});

  @override
  State<EditModulePage> createState() => _EditModulePageState();
}

class _EditModulePageState extends State<EditModulePage> {
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  final _titleNode = FocusNode();
  final _descNode = FocusNode();

  bool _titleDirty = false;
  bool _descDirty = false;
  bool _submitted = false;
  bool _loading = false;

  File? _iconFile;
  final picker = ImagePicker();
  String? _existingIconBase64;

  @override
  void initState() {
    super.initState();
    _titleC.text = widget.moduleData['title'] ?? '';
    _descC.text = widget.moduleData['description'] ?? '';
    _existingIconBase64 = widget.moduleData['iconBase64'];
  }

  String? _validateTitle(String v) {
    final s = v.trim();
    if (s.isEmpty || s.length < 3) return 'Please enter a valid title';
    return null;
  }

  String? _validateDesc(String v) {
    final s = v.trim();
    if (s.isEmpty || s.length < 10) return 'Please enter a longer description';
    return null;
  }

  String? get _titleErr => _validateTitle(_titleC.text);
  String? get _descErr => _validateDesc(_descC.text);

  bool get _showTitleError => (_submitted || _titleDirty) && _titleErr != null;
  bool get _showDescError => (_submitted || _descDirty) && _descErr != null;

  Color _borderFor(bool showErr, AppColors app) =>
      showErr ? app.error : app.border;

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _iconFile = File(picked.path));
    }
  }

  Future<String> _compressAndConvertBase64(File file) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 512,
      minHeight: 512,
      quality: 80,
    );
    return base64Encode(compressed!);
  }

  Future<void> _updateModule() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);

    if (_titleErr != null || _descErr != null || (_iconFile == null && _existingIconBase64 == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fix errors & select an icon")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String? iconBase64 = _existingIconBase64;
      if (_iconFile != null) {
        iconBase64 = await _compressAndConvertBase64(_iconFile!);
      }

      await FirebaseFirestore.instance
          .collection("modules")
          .doc(widget.moduleData['id'])
          .update({
        "title": _titleC.text.trim(),
        "description": _descC.text.trim(),
        "iconBase64": iconBase64,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Module "${_titleC.text}" updated')),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    _titleNode.dispose();
    _descNode.dispose();
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  const CircleBackButton(),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Module',
                    style: TextStyle(
                      color: app.headerFg,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 140,
              child: Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).cardColor.withOpacity(.25),
                      backgroundImage: _iconFile != null
                          ? FileImage(_iconFile!)
                          : (_existingIconBase64 != null
                              ? MemoryImage(base64Decode(_existingIconBase64!))
                              : null) as ImageProvider<Object>?,
                      child: (_iconFile == null && _existingIconBase64 == null)
                          ? Icon(Icons.auto_stories, size: 50, color: app.headerFg)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: app.ctaBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
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
                      const _Label('Module Title'),
                      _PillField(
                        controller: _titleC,
                        focusNode: _titleNode,
                        nextFocus: _descNode,
                        hint: 'Enter title',
                        height: pillHeight,
                        radius: 22,
                        hPad: pillHPad,
                        borderColor: _borderFor(_showTitleError, app),
                        hintColor: app.hint,
                        onChanged: (_) {
                          if (!_titleDirty) _titleDirty = true;
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 4),
                      _OutsideCounter(
                        len: _titleC.text.trim().length,
                        max: 30,
                        color: app.counterGrey,
                      ),
                      if (_showTitleError)
                        _TightErrorRow(errorText: _titleErr ?? ''),
                      const SizedBox(height: 22),
                      const _Label('Description'),
                      _PillMultilineField(
                        controller: _descC,
                        focusNode: _descNode,
                        hint: 'What will students learn?',
                        minLines: 3,
                        maxLines: 6,
                        radius: 18,
                        hPad: pillHPad,
                        borderColor: _borderFor(_showDescError, app),
                        hintColor: app.hint,
                        onChanged: (_) {
                          if (!_descDirty) _descDirty = true;
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 4),
                      _OutsideCounter(
                        len: _descC.text.trim().length,
                        max: 200,
                        color: app.counterGrey,
                      ),
                      if (_showDescError)
                        _TightErrorRow(errorText: _descErr ?? ''),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: buttonHeight,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _updateModule,
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
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Update Module'),
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
// ===== Reusable Widgets =====
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

class _PillField extends StatelessWidget {
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

  const _PillField({
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
        textInputAction: nextFocus == null ? TextInputAction.done : TextInputAction.next,
        onSubmitted: (_) {
          if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
        },
        onChanged: onChanged,
        inputFormatters: [LengthLimitingTextInputFormatter(30)],
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
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }
}

class _PillMultilineField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final int minLines;
  final int maxLines;
  final double radius;
  final double hPad;
  final Color borderColor;
  final Color hintColor;
  final ValueChanged<String> onChanged;

  const _PillMultilineField({
    required this.controller,
    required this.hint,
    required this.minLines,
    required this.maxLines,
    required this.radius,
    required this.hPad,
    required this.borderColor,
    required this.hintColor,
    required this.onChanged,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: app.panelBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1.6),
      ),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 10),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        minLines: minLines,
        maxLines: maxLines,
        onChanged: onChanged,
        inputFormatters: [LengthLimitingTextInputFormatter(200)],
        decoration: InputDecoration(
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
        textCapitalization: TextCapitalization.sentences,
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