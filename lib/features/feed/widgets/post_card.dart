import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/initials.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/utils/time_ago.dart';
import '../../comments/controllers/comments_controller.dart';
import '../../comments/screens/comments_screen.dart';
import '../../../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLikeTap;
  final VoidCallback? onProfileTap;
  final bool isLikedByMe;
  final String? currentUserId;
  final VoidCallback? onDeleteTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onLikeTap,
    this.onProfileTap,
    required this.isLikedByMe,
    this.currentUserId,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(
      post.profile?.fullName ?? post.profile?.username,
    );

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar and username
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: AvatarWidget(
                    imageUrl: post.profile?.avatarUrl,
                    initials: initials,
                    size: 40,
                    onTap: onProfileTap,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onProfileTap,
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
                    Text(
                      TimeAgoFormatter.format(post.createdAt),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              // Delete button (only for post author)
              if (currentUserId != null && currentUserId == post.userId)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete' && onDeleteTap != null) {
                      showDialog(
                        context: context,
                        builder:
                            (dialogContext) => AlertDialog(
                              title: const Text('Delete Post'),
                              content: const Text(
                                'Are you sure you want to delete this post? This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    onDeleteTap?.call();
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                      );
                    }
                  },
                  itemBuilder:
                      (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Post content
          if ((post.content ?? '').trim().isNotEmpty)
            Text(
              post.content!.trim(),
              style: AppTextStyles.bodyMedium,
              maxLines: null,
            ),
          // Post image if exists
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: AppColors.background,
                    child: const Center(child: Text('Image not found')),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Engagement metrics
          Row(
            children: [
              GestureDetector(
                onTap: onLikeTap,
                child: Row(
                  children: [
                    Icon(
                      isLikedByMe ? Icons.favorite : Icons.favorite_border,
                      color: isLikedByMe ? AppColors.error : AppColors.muted,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.likesCount.toString(),
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
                              postId: post.id,
                              postImageUrl: post.imageUrl,
                            ),
                          ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.mode_comment_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.commentCount.toString(),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
