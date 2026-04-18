import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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
  late int _likesCount;
  late bool _isLikedByMe;
  RealtimeChannel? _commentsChannel;
  RealtimeChannel? _likesChannel;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.post.commentCount;
    _likesCount = widget.post.likesCount;
    _isLikedByMe = widget.post.isLikedByMe;
    _subscribeToComments();
    _subscribeToLikes();
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

  void _subscribeToLikes() {
    _likesChannel = supabase.channel(
      'likes:post_id=eq.${widget.post.id}',
    );

    _likesChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'likes',
      callback: (payload) {
        if (mounted) {
          final eventType = payload.eventType;
          final postId = (payload.newRecord['post_id'] ??
                  payload.oldRecord['post_id'] ??
                  '')
              .toString();
          if (postId != widget.post.id) {
            return;
          }

          final currentUserId = supabase.auth.currentUser?.id;
          final likeUserId = (payload.newRecord['user_id'] ??
                  payload.oldRecord['user_id'] ??
                  '')
              .toString();

          if (eventType == PostgresChangeEvent.insert) {
            setState(() {
              _likesCount++;
              if (currentUserId == likeUserId) {
                _isLikedByMe = true;
              }
            });
          } else if (eventType == PostgresChangeEvent.delete) {
            setState(() {
              if (_likesCount > 0) {
                _likesCount--;
              }
              if (currentUserId == likeUserId) {
                _isLikedByMe = false;
              }
            });
          }
        }
      },
    );

    _likesChannel!.subscribe();
  }

  void _unsubscribeFromLikes() {
    _likesChannel?.unsubscribe();
    supabase.realtime.removeChannel(_likesChannel!);
  }

  Future<void> _toggleLike() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return;
    }

    try {
      final wasLiked = _isLikedByMe;

      // Optimistic update
      setState(() {
        _isLikedByMe = !wasLiked;
        _likesCount += wasLiked ? -1 : 1;
      });

      if (wasLiked) {
        // Unlike
        await supabase
            .from('likes')
            .delete()
            .eq('user_id', currentUserId)
            .eq('post_id', widget.post.id);
      } else {
        // Like
        await supabase.from('likes').insert({
          'id': const Uuid().v4(),
          'user_id': currentUserId,
          'post_id': widget.post.id,
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isLikedByMe = !_isLikedByMe;
        _likesCount += _isLikedByMe ? 1 : -1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _unsubscribeFromComments();
    _unsubscribeFromLikes();
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
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _toggleLike,
                            child: Row(
                              children: [
                                Icon(
                                  _isLikedByMe
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _isLikedByMe
                                      ? AppColors.error
                                      : AppColors.muted,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_likesCount likes',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
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
                        ],
                      ),
                      const SizedBox(height: 8),
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
