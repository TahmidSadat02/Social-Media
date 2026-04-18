import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/utils/time_ago.dart';
import '../../../models/post_model.dart';
import '../../../supabase_config.dart';
import '../../comments/controllers/comments_controller.dart';
import '../../comments/screens/comments_screen.dart';

class PhotoCarouselScreen extends StatefulWidget {
  final List<PostModel> posts;
  final int initialIndex;

  const PhotoCarouselScreen({
    super.key,
    required this.posts,
    this.initialIndex = 0,
  });

  @override
  State<PhotoCarouselScreen> createState() => _PhotoCarouselScreenState();
}

class _PhotoCarouselScreenState extends State<PhotoCarouselScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.posts.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          '${_currentIndex + 1} of ${widget.posts.length}',
          style: AppTextStyles.heading3,
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          final post = widget.posts[index];
          return _PostDetailPage(post: post);
        },
      ),
    );
  }
}

class _PostDetailPage extends StatefulWidget {
  final PostModel post;

  const _PostDetailPage({required this.post});

  @override
  State<_PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<_PostDetailPage> {
  final supabase = SupabaseConfig.client;
  late int _commentCount;
  RealtimeChannel? _commentsChannel;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.post.commentCount;
    _subscribeToComments();
  }

  void _subscribeToComments() {
    _commentsChannel = supabase.channel(
      'comments:post_id=eq.${widget.post.id}',
    );

    _commentsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'comments',
      callback: (payload) {
        if (mounted) {
          final eventType = payload.eventType;
          if (eventType == PostgresChangeEvent.insert) {
            final postId = (payload.newRecord['post_id'] ?? '').toString();
            if (postId == widget.post.id) {
              setState(() {
                _commentCount++;
              });
            }
          } else if (eventType == PostgresChangeEvent.delete) {
            final postId = (payload.oldRecord['post_id'] ?? '').toString();
            if (postId == widget.post.id) {
              setState(() {
                if (_commentCount > 0) {
                  _commentCount--;
                }
              });
            }
          }
        }
      },
    );

    _commentsChannel!.subscribe();
  }

  void _unsubscribeFromComments() {
    _commentsChannel?.unsubscribe();
    supabase.realtime.removeChannel(_commentsChannel!);
  }

  @override
  void dispose() {
    _unsubscribeFromComments();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.post.imageUrl?.trim() ?? '';
    final caption = widget.post.content?.trim() ?? '';
    final profile = widget.post.profile;

    return Builder(
      builder: (context) {
        try {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (imageUrl.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            'Image not found',
                            style: AppTextStyles.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap:
                            profile == null
                                ? null
                                : () {
                                  Navigator.pop(context);
                                  navigateToProfile(context, profile.id);
                                },
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 44,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              profile?.username ?? 'Unknown',
                              style: AppTextStyles.bodyLarge,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.post.likesCount} likes',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ChangeNotifierProvider(
                                    create: (_) => CommentsController(),
                                    child: CommentsScreen(
                                      postId: widget.post.id,
                                      postImageUrl: widget.post.imageUrl,
                                    ),
                                  ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.mode_comment_outlined,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_commentCount comments',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        TimeAgoFormatter.format(widget.post.createdAt),
                        style: AppTextStyles.bodySmall,
                      ),
                      if (caption.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(caption, style: AppTextStyles.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        } catch (_) {
          return Center(
            child: Text('Unable to load post', style: AppTextStyles.bodyMedium),
          );
        }
      },
    );
  }
}
