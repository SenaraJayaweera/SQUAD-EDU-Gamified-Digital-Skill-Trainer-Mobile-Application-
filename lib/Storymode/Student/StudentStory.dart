import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import '../../widgets/BackButtonWidget.dart';
import '../../Theme/Themes.dart';

class StudentStoryPage extends StatefulWidget {
  final String? studentId;
  const StudentStoryPage({super.key, this.studentId});

  @override
  State<StudentStoryPage> createState() => _StudentStoryPageState();
}

class _StudentStoryPageState extends State<StudentStoryPage> with SingleTickerProviderStateMixin {
  int currentStep = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? storyData;
  List<Map<String, dynamic>> steps = [];
  String? storyId;
  String? moduleId;
  String? moduleName;
  String? studentId;
  bool hasExistingProgress = false;
  bool hasStarted = false;
  bool isCompleted = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Translation state
  Map<int, String> translatedContent = {};
  Map<int, bool> isTranslating = {};
  Map<int, bool> showTranslated = {};
  Map<int, bool> isListening = {};

  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      try {
        setState(() {
          isListening[currentStep] = true;
        });
        
        await flutterTts.setLanguage("en-US");
        await flutterTts.setPitch(1.0);
        await flutterTts.setSpeechRate(0.5);
        await flutterTts.speak(text);
      } catch (e) {
        print('TTS error: $e');
      }
    }
  }

  Future<void> _stopListening() async {
    await flutterTts.stop();
    if (mounted) {
      setState(() {
        isListening[currentStep] = false;
      });
    }
  }

  Future<void> _translateText(String text, String targetLanguage) async {
    try {
      setState(() {
        isTranslating[currentStep] = true;
      });

      final translator = GoogleTranslator();
      final translation = await translator.translate(text, to: targetLanguage);
      
      if (mounted) {
        setState(() {
          translatedContent[currentStep] = translation.toString();
          showTranslated[currentStep] = true;
          isTranslating[currentStep] = false;
        });
      }
    } catch (e) {
      print('Translation error: $e');
      if (mounted) {
        final colors = Theme.of(context).extension<AppColors>()!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: colors.headerFg),
                const SizedBox(width: 12),
                const Expanded(child: Text('Translation failed. Try again')),
              ],
            ),
            backgroundColor: colors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      setState(() {
        isTranslating[currentStep] = false;
      });
    }
  }

  void _cancelTranslation() {
    setState(() {
      isTranslating[currentStep] = false;
      showTranslated[currentStep] = false;
      translatedContent.remove(currentStep);
    });
  }

  void _showLanguageDialog() {
    final colors = Theme.of(context).extension<AppColors>()!;
    final languages = {
      'Sinhala': 'si',
      'Spanish': 'es',
      'French': 'fr',
      'German': 'de',
      'Japanese': 'ja',
      'Arabic': 'ar',
      'Portuguese': 'pt',
      'Hindi': 'hi',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.panelBg,
        title: Text(
          'Select Language',
          style: TextStyle(color: colors.label),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: languages.entries.map((entry) {
              return ListTile(
                title: Text(
                  entry.key,
                  style: TextStyle(color: colors.label),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _translateText(steps[currentStep]['content'], entry.value);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final currentUser = FirebaseAuth.instance.currentUser;
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    storyId = args?['storyId'];
    
    studentId = widget.studentId ?? 
                args?['studentId'] ?? 
                currentUser?.uid;
    
    if (storyId != null && _isLoading) {
      _fetchStoryData();
    }
  }

  Future<void> _fetchStoryData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .get();
          
      if (doc.exists && mounted) {
        storyData = doc.data();
        moduleId = storyData?['moduleId'];

        if (moduleId != null) {
          final moduleDoc = await FirebaseFirestore.instance
              .collection('modules')
              .doc(moduleId)
              .get();
          if (moduleDoc.exists) {
            moduleName = moduleDoc.data()?['title'] ?? 'Module';
          }
        }

        final content = storyData?['content'] as List<dynamic>? ?? [];
        steps = content.map<Map<String, dynamic>>((block) {
          final type = block['type'] as String;
          String contentData = '';

          if (type == 'paragraph') {
            contentData = block['content'] ?? '';
          } else if (type == 'image') {
            if (block.containsKey('base64')) {
              contentData = block['base64'];
            } else if (block.containsKey('url')) {
              contentData = block['url'];
            }
          } else if (type == 'video') {
            contentData = block['url'] ?? '';
          }

          return {
            'type': type,
            'content': contentData,
            'label': type[0].toUpperCase() + type.substring(1),
            'isBase64': type == 'image' && block.containsKey('base64'),
            'isUrl': (type == 'image' && block.containsKey('url')) || type == 'video',
            'description': block['description'] ?? '',
          };
        }).toList();

        await _loadProgress();

        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching story: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProgress() async {
    if (studentId == null || storyId == null) return;

    try {
      final progressDoc = await FirebaseFirestore.instance
          .collection('storyProgress')
          .doc(studentId)
          .get();

      if (progressDoc.exists) {
        final data = progressDoc.data();
        
        if (data != null && data.containsKey(storyId!)) {
          final storyProgress = data[storyId!] as Map<String, dynamic>;
          
          isCompleted = storyProgress.containsKey('completedAt');
          
          if (isCompleted) {
            hasExistingProgress = true;
            hasStarted = false;
            currentStep = 0;
          } else {
            hasStarted = true;
            hasExistingProgress = false;
            
            if (storyProgress.containsKey('currentStep')) {
              final savedStep = storyProgress['currentStep'] as int;
              if (savedStep < steps.length) {
                currentStep = savedStep;
              }
            }
          }
        } else {
          hasStarted = false;
          hasExistingProgress = false;
          currentStep = 0;
        }
      } else {
        hasStarted = false;
        hasExistingProgress = false;
        currentStep = 0;
      }
    } catch (e) {
      print('Error loading progress: $e');
    }
  }

  Future<void> _saveCurrentStep() async {
    if (studentId == null || storyId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('storyProgress')
          .doc(studentId)
          .set({
        storyId!: {
          'currentStep': currentStep,
          'totalSteps': steps.length,
          'lastAccessedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
      
      if (!hasStarted) {
        setState(() {
          hasStarted = true;
        });
      }
    } catch (e) {
      print('Error saving current step: $e');
    }
  }

  Future<bool> _saveCompletion() async {
    if (studentId == null || storyId == null) return false;
    if (_isSaving) return false;

    setState(() {
      _isSaving = true;
    });

    try {
      final points = storyData?['points'] ?? 0;
      
      await FirebaseFirestore.instance
          .collection('storyProgress')
          .doc(studentId)
          .set({
        storyId!: {
          'points': points,
          'currentStep': steps.length - 1,
          'totalSteps': steps.length,
          'completedAt': FieldValue.serverTimestamp(),
          'lastAccessedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
      
      if (mounted) {
        setState(() {
          _isSaving = false;
          hasExistingProgress = true;
          isCompleted = true;
          hasStarted = false;
        });
      }
      
      return true;
    } catch (e) {
      print('Error saving completion: $e');
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
      
      return false;
    }
  }

  void _startLearning() {
    setState(() {
      hasStarted = true;
      currentStep = 0;
    });
    _animationController.reset();
    _animationController.forward();
    _saveCurrentStep();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.headerBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colors.ctaBlue,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading lesson...',
                style: TextStyle(
                  color: colors.headerFgMuted,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (steps.isEmpty) {
      return Scaffold(
        backgroundColor: colors.headerBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 80,
                color: colors.headerFgMuted,
              ),
              const SizedBox(height: 20),
              Text(
                "No story content available",
                style: TextStyle(
                  color: colors.headerFg,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final double progress = (currentStep + 1) / steps.length;
    final current = steps[currentStep];

    return Scaffold(
      backgroundColor: colors.headerBg,
      body: Column(
        children: [
          _buildHeader(colors),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.panelBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgressSection(colors, progress),
                          const SizedBox(height: 32),
                          if (!hasStarted && !hasExistingProgress)
                            _buildStartLearningCard()
                          else
                            _buildLessonContent(current),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.headerBg,
            colors.headerBg.withOpacity(0.9),
          ],
        ),
      ),
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      child: Column(
        children: [
          Row(
            children: [
              const CircleBackButton(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storyData?['title'] ?? "Lesson",
                      style: TextStyle(
                        color: colors.headerFg,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (moduleName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.ctaBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              moduleName!,
                              style: TextStyle(
                                color: colors.ctaBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (hasExistingProgress)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.success.withOpacity(0.15),
                      colors.success.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.success.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: colors.success, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Completed',
                      style: TextStyle(
                        color: colors.success,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(AppColors colors, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                storyData?['description'] ?? storyData?['title'] ?? "Lesson",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.label,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.ctaBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${(progress * 100).round()}%",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.ctaBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: colors.border.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.ctaBlue,
                      colors.cardButton,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: colors.ctaBlue.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStartLearningCard() {
    final colors = Theme.of(context).extension<AppColors>()!;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.ctaBlue,
            colors.cardButton,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.ctaBlue.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              size: 60,
              color: colors.headerFg,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Ready to Start?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.headerFg,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Begin your learning journey',
            style: TextStyle(
              fontSize: 16,
              color: colors.headerFg.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(
                colors,
                Icons.layers_outlined,
                '${steps.length} steps',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                colors,
                Icons.star_outline,
                '${storyData?['points'] ?? 0} pts',
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startLearning,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.headerFg,
                foregroundColor: colors.ctaBlue,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Start Learning',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(AppColors colors, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.headerFg, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: colors.headerFg,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent(Map<String, dynamic> step) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final type = step['type'];
    final content = step['content'];
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.ctaBlue.withOpacity(0.12),
                colors.cardButton.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.ctaBlue.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.ctaBlue, colors.cardButton],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.ctaBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${currentStep + 1}',
                  style: TextStyle(
                    color: colors.headerFg,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Step ${currentStep + 1} of ${steps.length}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.ctaBlue,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colors.storyCardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: colors.storyShadow.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _buildContentByType(type, content, step),
        ),
      ],
    );
  }

  Widget _buildContentByType(String type, String content, Map<String, dynamic> step) {
    final colors = Theme.of(context).extension<AppColors>()!;
    
    switch (type) {
      case 'paragraph':
        final hasTranslation = translatedContent.containsKey(currentStep);
        final isViewingTranslation = showTranslated[currentStep] ?? false;
        final displayText = (isViewingTranslation && hasTranslation)
            ? translatedContent[currentStep]!
            : content;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.ctaBlue.withOpacity(0.15),
                        colors.ctaBlue.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.auto_stories_outlined,
                    color: colors.ctaBlue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Reading Material',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.label,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.storyContentBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border.withOpacity(0.3)),
                  ),
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 17,
                      color: colors.storyContentText,
                      height: 1.9,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (isViewingTranslation && hasTranslation)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showTranslated[currentStep] = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.ctaBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, size: 14, color: colors.headerFg),
                            const SizedBox(width: 4),
                            Text(
                              'Original',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.headerFg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isListening[currentStep] ?? false
                        ? _stopListening
                        : () => _speak(content),
                    icon: Icon(
                      isListening[currentStep] ?? false
                          ? Icons.stop_circle_rounded
                          : Icons.volume_up_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isListening[currentStep] ?? false ? "Stop" : "Listen",
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isListening[currentStep] ?? false
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isTranslating[currentStep] ?? false
                        ? _cancelTranslation
                        : (isViewingTranslation && hasTranslation)
                            ? _cancelTranslation
                            : _showLanguageDialog,
                    icon: isTranslating[currentStep] ?? false
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(colors.headerFg),
                            ),
                          )
                        : Icon(
                            (isViewingTranslation && hasTranslation)
                                ? Icons.close_rounded
                                : Icons.translate,
                            size: 18,
                          ),
                    label: Text(
                      isTranslating[currentStep] ?? false
                          ? "Cancel"
                          : (isViewingTranslation && hasTranslation)
                              ? "Cancel"
                              : (hasTranslation ? "Translated" : "Translate"),
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTranslating[currentStep] ?? false
                          ? const Color(0xFFD32F2F)
                          : ((isViewingTranslation && hasTranslation)
                              ? const Color(0xFFD32F2F)
                              : (hasTranslation
                                  ? colors.success
                                  : const Color(0xFF6A1B9A))),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildNavigationButtons(),
          ],
        );

      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.secondaryColor.withOpacity(0.15),
                        colors.secondaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: colors.secondaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Visual Content',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.label,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: colors.storyShadow.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: step['isBase64'] == true
                    ? Image.memory(
                        base64Decode(step['content']),
                        fit: BoxFit.contain,
                        errorBuilder: (context, _, __) => _buildErrorImage(colors),
                      )
                    : Image.network(
                        step['content'],
                        fit: BoxFit.contain,
                        errorBuilder: (context, _, __) => _buildErrorImage(colors),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: colors.chipBg,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colors.ctaBlue,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 28),
            _buildNavigationButtons(),
          ],
        );

      case 'video':
        final videoId = YoutubePlayer.convertUrlToId(content) ?? '';
        final isYouTube = videoId.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.error.withOpacity(0.15),
                        colors.error.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    color: colors.error,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Video Lesson',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.label,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: colors.storyShadow.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: isYouTube
                    ? YoutubePlayer(
                        controller: YoutubePlayerController(
                          initialVideoId: videoId,
                          flags: const YoutubePlayerFlags(autoPlay: false),
                        ),
                        showVideoProgressIndicator: true,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors.storyOverlay.withOpacity(0.8),
                              colors.storyOverlay.withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            size: 80,
                            color: colors.headerFg,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 28),
            _buildNavigationButtons(),
          ],
        );

      default:
        return Center(
          child: Text(
            "Unknown content type",
            style: TextStyle(color: colors.storyErrorText),
          ),
        );
    }
  }

  Widget _buildErrorImage(AppColors colors) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: colors.storyErrorBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_rounded,
              size: 60,
              color: colors.storyErrorIcon.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Image unavailable',
              style: TextStyle(
                color: colors.storyErrorText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isLastStep = currentStep == steps.length - 1;
    final isFirstStep = currentStep == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.chipBg.withOpacity(0.5),
            colors.chipBg.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isFirstStep)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _goToPreviousStep,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: const Text("Previous"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.label,
                  side: BorderSide(color: colors.border, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          
          if (!isFirstStep) const SizedBox(width: 14),
          
          if (isFirstStep)
            ElevatedButton(
              onPressed: _goToNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                shadowColor: const Color(0xFF1565C0).withOpacity(0.4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Next",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            )
          else
            Expanded(
              child: ElevatedButton(
                onPressed: _goToNextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastStep ? colors.success : const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastStep ? "Complete" : "Next",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _goToNextStep() {
    if (currentStep < steps.length - 1) {
      setState(() {
        currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
      _saveCurrentStep();
    } else {
      _showCompletionDialog();
    }
  }

  void _goToPreviousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
      _saveCurrentStep();
    }
  }

  void _showCompletionDialog() async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final points = storyData?['points'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.panelBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: CircularProgressIndicator(
            color: colors.ctaBlue,
            strokeWidth: 3,
          ),
        ),
      ),
    );

    final success = await _saveCompletion();

    if (mounted) Navigator.of(context).pop();

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.headerFg),
              const SizedBox(width: 12),
              const Expanded(child: Text('Progress could not be saved')),
            ],
          ),
          backgroundColor: colors.error,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: colors.panelBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.success.withOpacity(0.2),
                        colors.success.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🎉', style: TextStyle(fontSize: 60)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colors.label,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You\'ve completed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.hint,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  storyData?['title'] ?? 'this lesson',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.label,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.success.withOpacity(0.15),
                        colors.success.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: colors.secondaryColor, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        '+$points points',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.success,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.ctaBlue,
                      foregroundColor: colors.headerFg,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue Learning',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}