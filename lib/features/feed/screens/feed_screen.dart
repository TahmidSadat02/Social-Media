import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/widgets/loading_widget.dart';
import '../controllers/feed_controller.dart';
import '../widgets/post_card.dart';
import '../../auth/controllers/auth_controller.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthController>();
      final feedController = context.read<FeedController>();
      if (authController.isAuthenticated) {
        feedController.loadPosts(authController.currentUser!.id);
      }
    });
  }

  void _refreshFeed() async {
    final authController = context.read<AuthController>();
    final feedController = context.read<FeedController>();
    if (authController.isAuthenticated) {
      await feedController.loadPosts(authController.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('PixoGram', style: AppTextStyles.heading3),
        centerTitle: true,
      ),
      body: Consumer2<AuthController, FeedController>(
        builder: (context, authController, feedController, _) {
          if (!authController.isAuthenticated) {
            return Center(
              child: Text('Please log in', style: AppTextStyles.bodyMedium),
            );
          }

          if (feedController.isLoading && feedController.posts.isEmpty) {
            return const LoadingWidget(message: 'Loading posts...');
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshFeed(),
            color: AppColors.accent,
            child: ListView.builder(
              itemCount: feedController.posts.length,
              itemBuilder: (context, index) {
                // Posts
                final post = feedController.posts[index];

                return PostCard(
                  post: post,
                  isLikedByMe: post.isLikedByMe,
                  onLikeTap: () {
                    feedController.toggleLike(
                      post.id,
                      authController.currentUser!.id,
                    );
                  },
                  onProfileTap: () {
                    navigateToProfile(context, post.userId);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
