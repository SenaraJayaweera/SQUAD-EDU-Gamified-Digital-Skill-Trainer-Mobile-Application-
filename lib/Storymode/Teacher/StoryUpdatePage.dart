import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/BackButtonWidget.dart';
import '../../Theme/Themes.dart';

class LessonBlock {
  String type; // 'paragraph', 'image', 'video'
  TextEditingController controller;
  String? localImagePath;
  String? localVideoPath;
  VideoPlayerController? videoController;
  YoutubePlayerController? ytController;

  LessonBlock({required this.type, String? initialText})
      : controller = TextEditingController(text: initialText);

  void dispose() {
    controller.dispose();
    videoController?.dispose();
    ytController?.dispose();
  }
}

class StoryUpdatePage extends StatefulWidget {
  const StoryUpdatePage({super.key});

  @override
  State<StoryUpdatePage> createState() => _StoryUpdatePageState();
}

class _StoryUpdatePageState extends State<StoryUpdatePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController pointsController =
      TextEditingController(text: '0');
  final TextEditingController descController = TextEditingController();

  List<LessonBlock> contentList = [];
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  bool _isSaving = false;
  bool _isLoading = true;
  String? titleError;
  String? pointsError;
  String? descError;
  String? contentError;
  
  // Story ID and module info
  String? storyId;
  String? moduleId;
  String? moduleName;
  bool _isLoadingModule = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the storyId from route arguments
    if (_isLoading) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      storyId = args?['storyId'];
      
      if (storyId != null) {
        _loadStoryData();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStoryData() async {
    try {
      final doc = await firestore.collection('stories').doc(storyId).get();
      
      if (doc.exists && mounted) {
        final data = doc.data()!;
        
        // Set basic fields
        titleController.text = data['title'] ?? '';
        pointsController.text = (data['points'] ?? 0).toString();
        descController.text = data['description'] ?? '';
        moduleId = data['moduleId'];
        
        // Load content blocks
        final List<dynamic> content = data['content'] ?? [];
        contentList.clear();
        
        for (var item in content) {
          final type = item['type'] as String;
          
          if (type == 'paragraph') {
            final block = LessonBlock(
              type: 'paragraph',
              initialText: item['content'] ?? '',
            );
            contentList.add(block);
          } else if (type == 'image') {
            final block = LessonBlock(type: 'image');
            if (item.containsKey('url')) {
              block.controller.text = item['url'];
            } else if (item.containsKey('base64')) {
              // For base64 images, we'll store the base64 data in the controller
              // and display it properly in the UI
              block.controller.text = 'base64:${item['base64']}';
            }
            block.controller.addListener(() {
              setState(() {});
            });
            contentList.add(block);
          } else if (type == 'video') {
            final block = LessonBlock(
              type: 'video',
              initialText: item['url'] ?? '',
            );
            block.controller.addListener(() {
              setState(() {});
            });
            contentList.add(block);
          }
        }
        
        // Fetch module name
        if (moduleId != null) {
          _fetchModuleName();
        } else {
          setState(() {
            moduleName = 'Unknown Module';
            _isLoadingModule = false;
          });
        }
        
        setState(() {
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showMessage('Story not found', isError: true);
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showMessage('Error loading story: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _fetchModuleName() async {
    try {
      final doc = await firestore.collection('modules').doc(moduleId).get();
      if (doc.exists && mounted) {
        setState(() {
          moduleName = doc.data()?['title'] ?? 'Unknown Module';
          _isLoadingModule = false;
        });
      } else {
        if (mounted) {
          setState(() {
            moduleName = 'Unknown Module';
            _isLoadingModule = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          moduleName = 'Unknown Module';
          _isLoadingModule = false;
        });
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    pointsController.dispose();
    descController.dispose();
    for (var block in contentList) {
      block.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    final app = Theme.of(context).extension<AppColors>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? app.error : app.headerBg,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Block'),
          content: Text(
            'Are you sure you want to delete this ${contentList[index].type} block?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  contentList[index].dispose();
                  contentList.removeAt(index);
                });
                _showMessage('Block deleted');
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).extension<AppColors>()!.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateLesson() async {
    if (_isSaving) {
      _showMessage('Already saving...please wait');
      return;
    }

    // Clear previous errors
    setState(() {
      titleError = null;
      pointsError = null;
      descError = null;
      contentError = null;
    });

    bool hasError = false;

    if (titleController.text.trim().isEmpty) {
      setState(() {
        titleError = 'Please enter a lesson title';
      });
      hasError = true;
    }

    if (pointsController.text.trim().isEmpty ||
        int.tryParse(pointsController.text.trim()) == null ||
        int.parse(pointsController.text.trim()) < 0) {
      setState(() {
        pointsError = 'Points must be a non-negative number';
      });
      hasError = true;
    }

    if (descController.text.trim().isEmpty) {
      setState(() {
        descError = 'Please enter a description';
      });
      hasError = true;
    }

    if (contentList.isEmpty) {
      setState(() {
        contentError = 'Please add at least one content block';
      });
      hasError = true;
    } else {
      bool hasContent = contentList.any((block) {
        if (block.type == 'paragraph' &&
            block.controller.text.trim().isNotEmpty) return true;
        if (block.type == 'image' &&
            (block.localImagePath != null ||
                block.controller.text.trim().isNotEmpty)) return true;
        if (block.type == 'video' &&
            (block.localVideoPath != null ||
                block.controller.text.trim().isNotEmpty)) return true;
        return false;
      });

      if (!hasContent) {
        setState(() {
          contentError = 'Please add content to at least one block';
        });
        hasError = true;
      }
    }

    if (hasError) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      List<Map<String, dynamic>> lessonContent = [];

      for (var block in contentList) {
        if (block.type == 'paragraph' &&
            block.controller.text.trim().isNotEmpty) {
          lessonContent.add({
            'type': 'paragraph',
            'content': block.controller.text.trim(),
          });
        } else if (block.type == 'image') {
          if (block.localImagePath != null) {
            File file = File(block.localImagePath!);
            List<int> imageBytes = await file.readAsBytes();
            String base64Image = base64Encode(imageBytes);

            lessonContent.add({'type': 'image', 'base64': base64Image});
          } else if (block.controller.text.trim().isNotEmpty) {
            // Check if it's a base64 image (from loaded data)
            if (block.controller.text.startsWith('base64:')) {
              lessonContent.add({
                'type': 'image',
                'base64': block.controller.text.substring(7), // Remove 'base64:' prefix
              });
            } else {
              // It's a URL
              lessonContent.add({
                'type': 'image',
                'url': block.controller.text.trim(),
              });
            }
          }
        } else if (block.type == 'video' &&
            block.controller.text.trim().isNotEmpty) {
          lessonContent.add({'type': 'video', 'url': block.controller.text.trim()});
        }
      }

      // Update existing story
      await firestore.collection('stories').doc(storyId).update({
        'title': titleController.text.trim(),
        'points': int.tryParse(pointsController.text) ?? 0,
        'description': descController.text.trim(),
        'content': lessonContent,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Success! Now clean up properly
      
      // 1. Stop the button loading state
      setState(() {
        _isSaving = false;
      });

      // 2. Pop the loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // 3. Show success message
      _showMessage('Lesson updated successfully!');

      // 4. Wait a moment then navigate back
      await Future.delayed(const Duration(milliseconds: 600));

      // 5. Navigate back using pop
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate successful update
      }
    } catch (e) {
      // Error handling
      setState(() {
        _isSaving = false;
      });
      
      Navigator.of(context, rootNavigator: true).pop();
      
      if (mounted) {
        _showMessage('Error updating lesson: ${e.toString()}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: app.headerBg,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(app.ctaBlue),
          ),
        ),
      );
    }
    
    return Scaffold(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Story',
                          style: TextStyle(
                            color: app.headerFg,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _isLoadingModule
                            ? SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    app.headerFgMuted,
                                  ),
                                ),
                              )
                            : Text(
                                moduleName ?? 'Unknown Module',
                                style: TextStyle(
                                  color: app.headerFgMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isSaving ? null : updateLesson,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaving ? app.iconMuted : app.ctaBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(app.headerFg),
                            ),
                          )
                        : Text(
                            'Update Lesson',
                            style: TextStyle(
                              color: app.headerFg,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: Container(
                  width: double.infinity,
                  color: app.panelBg,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Lesson',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: app.label,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Edit and update your lesson content',
                          style: TextStyle(color: app.hint),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField('Lesson Title', 'Enter lesson title',
                            titleController, errorText: titleError),
                        const SizedBox(height: 16),
                        _buildTextField(
                            'Points Awarded', '0', pointsController,
                            keyboardType: TextInputType.number, errorText: pointsError),
                        const SizedBox(height: 16),
                        _buildTextField('Description',
                            'Enter lesson description', descController,
                            maxLines: 3, errorText: descError),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              'Lesson Content',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: app.label,
                              ),
                            ),
                            if (contentError != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  '($contentError)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: app.error,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildAddButton(
                              'Add Text',
                              Theme.of(context).colorScheme.tertiary,
                              Icons.text_fields,
                              () {
                                setState(() {
                                  final block = LessonBlock(type: 'paragraph');
                                  contentList.add(block);
                                });
                                _showMessage('Text block added');
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildAddButton(
                              'Add Image',
                              app.success,
                              Icons.image,
                              () {
                                setState(() {
                                  final block = LessonBlock(type: 'image');
                                  block.controller.addListener(() {
                                    setState(() {});
                                  });
                                  contentList.add(block);
                                });
                                _showMessage('Image block added');
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildAddButton(
                              'Add Video',
                              app.ctaBlue,
                              Icons.videocam,
                              () {
                                setState(() {
                                  final block = LessonBlock(type: 'video');
                                  block.controller.addListener(() {
                                    setState(() {});
                                  });
                                  contentList.add(block);
                                });
                                _showMessage('Video block added');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (contentList.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No content added yet. Use the buttons above to add text, image, or video blocks.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: app.hint,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        else
                          ...contentList.asMap().entries.map((entry) {
                            int i = entry.key;
                            LessonBlock block = entry.value;
                            return _buildContentBlock(block, i);
                          }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint,
      TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text, String? errorText}) {
    final app = Theme.of(context).extension<AppColors>()!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: app.label,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: app.label),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: app.hint),
            filled: true,
            fillColor: app.chipBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: errorText != null ? app.error : app.border),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: errorText != null ? app.error : app.ctaBlue),
              borderRadius: BorderRadius.circular(8.0),
            ),
            errorText: errorText,
            errorStyle: TextStyle(fontSize: 12, color: app.error),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(
      String label, Color color, IconData icon, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Theme.of(context).colorScheme.onTertiary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: Theme.of(context).colorScheme.onTertiary),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildContentBlock(LessonBlock block, int index) {
    switch (block.type) {
      case 'paragraph':
        return _buildParagraphBlock(block, index);
      case 'image':
        return _buildImageBlock(block, index);
      case 'video':
        return _buildVideoBlock(block, index);
      default:
        return const SizedBox();
    }
  }

  Widget _buildParagraphBlock(LessonBlock block, int index) {
    final app = Theme.of(context).extension<AppColors>()!;
    
    return _buildContentCard(
      index: index,
      title: 'Paragraph',
      child: TextField(
        controller: block.controller,
        maxLines: 3,
        style: TextStyle(color: app.label),
        decoration: InputDecoration(
          hintText: 'Start writing your lesson content here...',
          hintStyle: TextStyle(color: app.hint),
          filled: true,
          fillColor: app.chipBg,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildImageBlock(LessonBlock block, int index) {
    final app = Theme.of(context).extension<AppColors>()!;
    bool isBase64 = block.controller.text.startsWith('base64:');
    // Create a unique key based on the content to force widget rebuild when it changes
    final imageKey = ValueKey(block.controller.text);
    
    // Create a separate controller for display purposes
    final displayController = TextEditingController(
      text: isBase64 ? '' : block.controller.text
    );
    
    return _buildContentCard(
      index: index,
      title: 'Image',
      child: Column(
        children: [
          TextField(
            controller: displayController,
            style: TextStyle(color: app.label),
            decoration: InputDecoration(
              hintText: isBase64 ? '(Image loaded from gallery)' : 'Enter image URL here',
              hintStyle: TextStyle(color: app.hint),
              filled: true,
              fillColor: app.chipBg,
              border: InputBorder.none,
            ),
            readOnly: false,
            onChanged: (value) {
              block.controller.text = value;
              setState(() {
                block.localImagePath = null;
              });
            },
          ),
          const SizedBox(height: 8),
          Container(
            key: imageKey, // Force rebuild when content changes
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: app.actionBubbleBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: block.localImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(block.localImagePath!),
                        fit: BoxFit.cover),
                  )
                : (block.controller.text.isNotEmpty && !isBase64
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          block.controller.text,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(Icons.broken_image, size: 50, color: app.hint),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2));
                          },
                        ),
                      )
                    : (isBase64
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(block.controller.text.substring(7)),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(Icons.broken_image, size: 50, color: app.hint),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(Icons.image, size: 50, color: app.hint),
                          ))),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: app.headerBg,
                foregroundColor: app.headerFg,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    block.localImagePath = image.path;
                    block.controller.text = '';
                  });
                }
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick from Gallery',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoBlock(LessonBlock block, int index) {
    final app = Theme.of(context).extension<AppColors>()!;
    // Create a unique key based on the URL to force widget rebuild when URL changes
    final videoKey = ValueKey(block.controller.text);
    bool isYouTube = block.controller.text.isNotEmpty && 
                     YoutubePlayer.convertUrlToId(block.controller.text) != null;
    
    return _buildContentCard(
      index: index,
      title: 'Video',
      child: Column(
        children: [
          TextField(
            controller: block.controller,
            style: TextStyle(color: app.label),
            decoration: InputDecoration(
              hintText: 'Enter video URL here',
              hintStyle: TextStyle(color: app.hint),
              filled: true,
              fillColor: app.chipBg,
              border: InputBorder.none,
            ),
            onChanged: (value) {
              // Trigger rebuild when URL changes
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          Container(
            key: videoKey, // Force rebuild when URL changes
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: app.actionBubbleBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: block.controller.text.isEmpty
                ? Center(
                    child: Icon(Icons.videocam, size: 50, color: app.hint),
                  )
                : (isYouTube
                    ? YoutubePlayerWidget(key: videoKey, url: block.controller.text)
                    : VideoPlayerWidget(key: videoKey, path: block.controller.text)),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard({
    required int index,
    required String title,
    required Widget child,
  }) {
    final app = Theme.of(context).extension<AppColors>()!;
    bool isFirst = index == 0;
    bool isLast = index == contentList.length - 1;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: app.panelBg,
        border: Border.all(color: app.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: app.border.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: app.label,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: isFirst
                    ? null
                    : () {
                        setState(() {
                          final temp = contentList[index - 1];
                          contentList[index - 1] = contentList[index];
                          contentList[index] = temp;
                        });
                      },
                icon: Icon(
                  Icons.arrow_upward,
                  color: isFirst ? app.iconMuted : app.ctaBlue,
                ),
              ),
              IconButton(
                onPressed: isLast
                    ? null
                    : () {
                        setState(() {
                          final temp = contentList[index + 1];
                          contentList[index + 1] = contentList[index];
                          contentList[index] = temp;
                        });
                      },
                icon: Icon(
                  Icons.arrow_downward,
                  color: isLast ? app.iconMuted : app.ctaBlue,
                ),
              ),
              IconButton(
                onPressed: () {
                  _showDeleteConfirmation(index);
                },
                icon: Icon(Icons.delete, color: app.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// Dummy video player widget for local videos
class VideoPlayerWidget extends StatefulWidget {
  final String path;
  const VideoPlayerWidget({super.key, required this.path});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) => setState(() {}))
      ..setLooping(true)
      ..play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}

// Dummy YouTube player widget
class YoutubePlayerWidget extends StatefulWidget {
  final String url;
  const YoutubePlayerWidget({super.key, required this.url});

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.url) ?? '';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      showVideoProgressIndicator: true,
    );
  }
}