import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/utils/initials.dart';
import '../../../core/utils/tab_navigation_service.dart';
import '../../../supabase_config.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../messages/controllers/messages_controller.dart';
import '../../search/controllers/search_controller.dart' as search_controller;
import '../controllers/profile_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'photo_post_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = SupabaseConfig.client;

  Future<void> _loadProfile() async {
    final profileController = context.read<ProfileController>();
    final authController = context.read<AuthController>();
    final currentUserId =
        authController.currentUser?.id ?? _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return;
    }

    debugPrint('Viewing profile: ${widget.userId}');
    debugPrint('Logged in as: $currentUserId');

    await profileController.loadProfile(
      viewedUserId: widget.userId,
      currentUserId: currentUserId,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
    }
  }

  Future<void> _logout() async {
    await context.read<AuthController>().logout();
    context.read<FeedController>().resetState();
    context.read<ProfileController>().resetState();
    context.read<MessagesController>().resetState();
    context.read<search_controller.SearchController>().clearSearch();
    TabNavigationService.setTabIndex(0);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.of(sheetContext).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _logout();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser?.id;
    final isOwnProfile = widget.userId == currentUserId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Profile', style: AppTextStyles.heading3),
        centerTitle: true,
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsSheet,
            ),
        ],
      ),
      body: Consumer<ProfileController>(
        builder: (context, profileController, _) {
          if (profileController.isLoading) {
            return const LoadingWidget(message: 'Loading profile...');
          }

          if (profileController.user == null) {
            return Center(
              child: Text('User not found', style: AppTextStyles.bodyMedium),
            );
          }

          final user = profileController.user!;
          final photoPosts =
              profileController.userPosts
                  .where((post) => (post.imageUrl ?? '').isNotEmpty)
                  .toList();
          final initials = getInitials(
            user.fullName.trim().isNotEmpty ? user.fullName : user.username,
          );

          return ListView(
            children: [
              // Profile header
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    AvatarWidget(
                      imageUrl: user.avatarUrl,
                      initials: initials,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(
                          user.username,
                          style: AppTextStyles.heading2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.fullName,
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        user.bio!,
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Posts',
                          value: profileController.postsCount.toString(),
                        ),
                        _StatItem(
                          label: 'Followers',
                          value: profileController.followersCount.toString(),
                        ),
                        _StatItem(
                          label: 'Following',
                          value: profileController.followingCount.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Action button
                    if (isOwnProfile)
                      AppButton(
                        label: 'Edit Profile',
                        onPressed: () {
                          // TODO: Navigate to edit profile
                        },
                      )
                    else
                      AppButton(
                        label:
                            profileController.isFollowedByMe
                                ? 'Unfollow'
                                : 'Follow',
                        onPressed: () {
                          profileController.toggleFollow(
                            user.id,
                            currentUserId!,
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Posts
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Posts', style: AppTextStyles.heading3),
              ),
              const SizedBox(height: 12),
              if (photoPosts.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: photoPosts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final post = photoPosts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => PhotoPostDetailScreen(post: post),
                          ),
                        );
                      },
                      child: Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: AppColors.surface);
                        },
                      ),
                    );
                  },
                ),
              if (photoPosts.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No photo posts yet',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.heading2),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
