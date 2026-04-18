import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/utils/time_ago.dart';
import '../../../models/post_model.dart';

class PhotoPostDetailScreen extends StatelessWidget {
  final PostModel post;

  const PhotoPostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Post', style: AppTextStyles.heading3),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Expanded(
              child: Image.network(
                post.imageUrl!,
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
                      post.profile == null
                          ? null
                          : () => navigateToProfile(context, post.profile!.id),
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
                const SizedBox(height: 6),
                Text(
                  TimeAgoFormatter.format(post.createdAt),
                  style: AppTextStyles.bodySmall,
                ),
                if ((post.content ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(post.content!.trim(), style: AppTextStyles.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
