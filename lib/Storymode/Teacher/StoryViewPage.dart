import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/Storymode/Teacher/StoryUpdatePage.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../Theme/Themes.dart';
import '../../widgets/BackButtonWidget.dart';

class StoryViewPage extends StatefulWidget {
  const StoryViewPage({super.key});

  @override
  State<StoryViewPage> createState() => _StoryViewPageState();
}

class _StoryViewPageState extends State<StoryViewPage> {
  Map<String, dynamic>? storyData;
  String? storyId;
  bool _isLoading = true;
  bool _isDeleting = false;
  
  // Module name variables
  String? moduleId;
  String? moduleName;
  bool _isLoadingModule = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    storyId = args?['storyId'];

    if (storyId != null) {
      _fetchStory(storyId!);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStory(String storyId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('stories').doc(storyId).get();
      if (doc.exists) {
        setState(() {
          storyData = doc.data();
          moduleId = storyData?['moduleId'];
          _isLoading = false;
        });
        
        // Fetch module name if moduleId exists
        if (moduleId != null && _isLoadingModule) {
          await _fetchModuleName();
        } else {
          setState(() => _isLoadingModule = false);
        }
      } else {
        setState(() {
          storyData = null;
          _isLoading = false;
          _isLoadingModule = false;
        });
      }
    } catch (e) {
      setState(() {
        storyData = null;
        _isLoading = false;
        _isLoadingModule = false;
      });
    }
  }

  Future<void> _fetchModuleName() async {
    if (moduleId == null) {
      setState(() => _isLoadingModule = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('modules').doc(moduleId).get();
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

  Future<void> _deleteStory() async {
    if (storyId == null) return;
    final app = Theme.of(context).extension<AppColors>()!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: app.storyDeleteBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber_rounded, color: app.storyDeleteIcon, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Delete Story', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this story? This action cannot be undone.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: app.ctaBlue,
              foregroundColor: app.headerFg,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await FirebaseFirestore.instance.collection('stories').doc(storyId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: app.headerFg),
                const SizedBox(width: 12),
                const Text('Story deleted successfully'),
              ],
            ),
            backgroundColor: app.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: app.headerFg),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to delete: $e')),
              ],
            ),
            backgroundColor: app.ctaBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _editStory() {
    if (storyId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoryUpdatePage(),
        settings: RouteSettings(
          arguments: {'storyId': storyId},
        ),
      ),
    ).then((result) {
      if (result == true && storyId != null) {
        _fetchStory(storyId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: app.headerBg,
      body: SafeArea(
        child: Column(
          children: [
            // ===================== Header =====================
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
                                  color: app.headerFg,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ===================== Content Panel =====================
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : storyData == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: app.storyErrorBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.error_outline, size: 64, color: app.storyErrorIcon),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Story not found',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This story may have been deleted',
                                  style: TextStyle(fontSize: 14, color: app.storyErrorText),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            children: [
                              SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  22,
                                  24,
                                  22,
                                  MediaQuery.of(context).viewInsets.bottom + 100,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _StoryCardTitle(
                                      title: storyData!['title'] ?? '',
                                      description: storyData!['description'] ?? '',
                                      points: storyData!['points'] ?? 0,
                                      totalLessons: (storyData!['content'] as List?)?.length ?? 0,
                                      moduleName: moduleName ?? 'Unknown Module',
                                      cs: cs,
                                      app: app,
                                    ),
                                    const SizedBox(height: 24),
                                    if (storyData!['content'] != null && storyData!['content'] is List)
                                      ...List<Map<String, dynamic>>.from(storyData!['content'])
                                          .asMap()
                                          .entries
                                          .map(
                                            (entry) => _StoryContentBlock(
                                              index: entry.key + 1,
                                              block: entry.value,
                                              cs: cs,
                                              app: app,
                                            ),
                                          )
                                          .toList(),
                                  ],
                                ),
                              ),
                              // ===================== Bottom Action Bar =====================
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: app.panelBg,
                                    boxShadow: [
                                      BoxShadow(
                                        color: app.storyShadow.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, -5),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.fromLTRB(
                                    22,
                                    16,
                                    22,
                                    MediaQuery.of(context).padding.bottom + 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _isDeleting ? null : _editStory,
                                          icon: const Icon(Icons.edit_rounded, size: 20),
                                          label: const Text('Edit Story'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: cs.primary,
                                            foregroundColor: app.headerFg,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: app.storyDeleteBg,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: IconButton(
                                          onPressed: _isDeleting ? null : _deleteStory,
                                          icon: _isDeleting
                                              ? SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    color: app.storyDeleteIcon,
                                                  ),
                                                )
                                              : Icon(Icons.delete_rounded, color: app.storyDeleteIcon, size: 24),
                                          tooltip: 'Delete Story',
                                          padding: const EdgeInsets.all(16),
                                        ),
                                      ),
                                    ],
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

/// ===================== Title Card =====================
class _StoryCardTitle extends StatelessWidget {
  final String title;
  final String description;
  final int points;
  final int totalLessons;
  final String moduleName;
  final ColorScheme cs;
  final AppColors app;

  const _StoryCardTitle({
    required this.title,
    required this.description,
    required this.points,
    required this.totalLessons,
    required this.moduleName,
    required this.cs,
    required this.app,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(0.12),
            cs.secondary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.auto_stories_rounded, color: cs.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        moduleName,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: app.storyCardBg.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: cs.onSurface.withOpacity(0.75),
                    height: 1.6,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.emoji_events_rounded,
                  value: '$points',
                  label: 'Points',
                  color: cs.primary,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.library_books_rounded,
                  value: '$totalLessons',
                  label: 'Contents',
                  color: cs.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.75),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


/// ===================== Content Block =====================
class _StoryContentBlock extends StatelessWidget {
  final int index;
  final Map<String, dynamic> block;
  final ColorScheme cs;
  final AppColors app;

  const _StoryContentBlock({
    required this.index,
    required this.block,
    required this.cs,
    required this.app,
  });

  @override
  Widget build(BuildContext context) {
    final type = block['type'] ?? '';
    Widget content;

    switch (type) {
      case 'paragraph':
        content = _buildParagraph(block);
        break;
      case 'image':
        content = _buildImage(block);
        break;
      case 'video':
        content = _buildVideo(block);
        break;
      default:
        content = const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withOpacity(0.12),
                  cs.primary.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primary.withOpacity(0.8)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: app.headerFg,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Content $index',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        _capitalize(type),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.primary.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _getIconForType(type),
                  color: cs.primary.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'paragraph':
        return Icons.article_rounded;
      case 'image':
        return Icons.image_rounded;
      case 'video':
        return Icons.play_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _capitalize(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  Widget _buildParagraph(Map<String, dynamic> block) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: app.storyContentBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: app.storyShadow.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          block['content'] ?? '',
          style: TextStyle(
            fontSize: 16,
            height: 1.7,
            color: app.storyContentText,
          ),
        ),
      );

  Widget _buildImage(Map<String, dynamic> block) {
    Widget imageWidget;
    
    if (block['base64'] != null && block['base64'].isNotEmpty) {
      final bytes = base64Decode(block['base64']);
      imageWidget = Image.memory(bytes, width: double.infinity, height: 240, fit: BoxFit.cover);
    } else if (block['url'] != null && block['url'].isNotEmpty) {
      imageWidget = Image.network(block['url'], width: double.infinity, height: 240, fit: BoxFit.cover);
    } else {
      imageWidget = Container(
        height: 240,
        decoration: BoxDecoration(color: app.chipBg),
        child: Center(
          child: Icon(Icons.image_rounded, size: 64, color: app.iconMuted),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: app.storyShadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: imageWidget,
      ),
    );
  }

  Widget _buildVideo(Map<String, dynamic> block) {
    final url = block['url'] ?? '';
    final isYouTube = YoutubePlayer.convertUrlToId(url) != null;
    // Create a unique key based on the URL to force rebuild when URL changes
    final videoKey = ValueKey('video_$url');

    Widget videoWidget;
    
    if (isYouTube) {
      videoWidget = YoutubePlayerWidget(key: videoKey, url: url);
    } else if (url.isNotEmpty) {
      videoWidget = VideoPlayerWidget(key: videoKey, path: url);
    } else {
      videoWidget = Container(
        height: 240,
        decoration: BoxDecoration(color: app.chipBg),
        child: Center(
          child: Icon(Icons.videocam_rounded, size: 64, color: app.iconMuted),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: app.storyShadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: videoWidget,
      ),
    );
  }
}

// ===================== Video Player =====================
class VideoPlayerWidget extends StatefulWidget {
  final String path;
  const VideoPlayerWidget({super.key, required this.path});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.path)
      ..initialize().then((_) => setState(() {}))
      ..addListener(() {
        if (_controller.value.isPlaying != _isPlaying) {
          setState(() => _isPlaying = _controller.value.isPlaying);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() => _controller.value.isPlaying ? _controller.pause() : _controller.play();

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppColors>()!;
    
    return _controller.value.isInitialized
        ? Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)),
              if (!_controller.value.isPlaying)
                Container(
                  decoration: BoxDecoration(
                    color: app.storyOverlay.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.play_arrow_rounded, size: 56, color: app.headerFg),
                    onPressed: _togglePlay,
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(_controller, allowScrubbing: true),
              ),
            ],
          )
        : const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
  }
}

// ===================== YouTube Player =====================
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
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(controller: _controller);
  }
}