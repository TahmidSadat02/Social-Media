import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/utils/time_ago.dart';
import '../../comments/controllers/comments_controller.dart';
import '../../comments/screens/comments_screen.dart';
import '../../../models/post_model.dart';
import 'package:provider/provider.dart';

class PhotoPostDetailScreen extends StatefulWidget {
  final List<PostModel> posts;
  final int initialIndex;

  PhotoPostDetailScreen({super.key, required PostModel post})
    : posts = [post],
      initialIndex = 0;

  const PhotoPostDetailScreen.carousel({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<PhotoPostDetailScreen> createState() => _PhotoPostDetailScreenState();
}

class _PhotoPostDetailScreenState extends State<PhotoPostDetailScreen> {
  late final List<PostModel> _posts;
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _posts = List<PostModel>.from(widget.posts);
    _currentIndex =
        _posts.isEmpty ? 0 : widget.initialIndex.clamp(0, _posts.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_posts.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Post'),
        ),
        body: Center(
          child: Text('No post available', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          _posts.length > 1
              ? '${_currentIndex + 1} of ${_posts.length}'
              : 'Post',
          style: AppTextStyles.heading3,
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _posts.length,
        onPageChanged: (index) {
          if (!mounted) {
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final post = _posts[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final dpr = MediaQuery.of(context).devicePixelRatio;
                      final cacheWidth = (constraints.maxWidth * dpr).round();
                      final cacheHeight = (constraints.maxHeight * dpr).round();

                      return CachedNetworkImage(
                        imageUrl: post.imageUrl!,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        memCacheWidth: cacheWidth > 0 ? cacheWidth : null,
                        memCacheHeight: cacheHeight > 0 ? cacheHeight : null,
                        placeholder:
                            (_, __) => Container(color: AppColors.surface),
                        errorWidget:
                            (_, __, ___) => Center(
                              child: Text(
                                'Image not found',
                                style: AppTextStyles.bodySmall,
                              ),
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
                      onTap: post.profile != null
                          ? () => navigateToProfile(context, post.profile!.id)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 44,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            post.profile?.username ?? 'Unknown',
                            style: AppTextStyles.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${post.likesCount} likes',
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
                                    postId: post.id,
                                    postImageUrl: post.imageUrl,
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
                            '${post.commentCount} comments',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      TimeAgoFormatter.format(post.createdAt),
                      style: AppTextStyles.bodySmall,
                    ),
                    if ((post.content ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        post.content!.trim(),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
