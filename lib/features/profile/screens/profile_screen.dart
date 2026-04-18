import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
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
import 'edit_profile_screen.dart';
import 'photo_post_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = SupabaseConfig.client;
  final ImagePicker _imagePicker = ImagePicker();

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

  Future<void> _openEditProfile() async {
    final profileController = context.read<ProfileController>();
    final user = profileController.user;
    if (user == null) {
      return;
    }

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (_) => EditProfileScreen(
              userId: user.id,
              initialFullName: user.fullName,
              initialBio: user.bio,
            ),
      ),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      await _loadProfile();
    }
  }

  Future<void> _changeProfilePicture() async {
    final profileController = context.read<ProfileController>();
    final user = profileController.user;
    if (user == null) {
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();
    await profileController.updateProfileAvatar(
      userId: user.id,
      imageBytes: bytes,
    );

    if (!mounted) {
      return;
    }

    if (profileController.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(profileController.error!)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile picture updated successfully')),
    );
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
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _openEditProfile();
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
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const SizedBox.shrink(),
        centerTitle: true,
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
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
              child: Text(
                'User not found',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
            );
          }

          final user = profileController.user!;
          final photoPosts =
              profileController.userPosts
                  .where((post) => (post.imageUrl ?? '').trim().isNotEmpty)
                  .toList();
          final initials = getInitials(
            user.fullName.trim().isNotEmpty ? user.fullName : user.username,
          );
          final topSectionHeight = MediaQuery.of(context).size.height * 0.5;

          return Stack(
            children: [
              Positioned.fill(
                child: _ProfileBackgroundImage(imageUrl: user.avatarUrl),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.12),
                        Colors.black.withValues(alpha: 0.3),
                        AppColors.background.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: topSectionHeight)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: _FrostedProfileCard(
                        userFullName: user.fullName,
                        username: user.username,
                        bio: user.bio,
                        avatarUrl: user.avatarUrl,
                        initials: initials,
                        postsCount: profileController.postsCount,
                        followersCount: profileController.followersCount,
                        followingCount: profileController.followingCount,
                        isOwnProfile: isOwnProfile,
                        isFollowedByMe: profileController.isFollowedByMe,
                        onEditAvatar:
                            profileController.isLoading
                                ? null
                                : _changeProfilePicture,
                        onActionPressed: () {
                          if (isOwnProfile) {
                            _openEditProfile();
                            return;
                          }
                          if (currentUserId == null) {
                            return;
                          }
                          profileController.toggleFollow(
                            user.id,
                            currentUserId,
                          );
                        },
                      ),
                    ),
                  ),
                  if (photoPosts.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final post = photoPosts[index];
                          final imageUrl = post.imageUrl ?? '';
                          return GestureDetector(
                            onTap: () {
                              if (post.id.isEmpty) {
                                return;
                              }

                              final safePost =
                                  post.profile == null &&
                                          profileController.user != null
                                      ? post.copyWith(
                                        profile: profileController.user,
                                      )
                                      : post;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          PhotoPostDetailScreen(post: safePost),
                                ),
                              );
                            },
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (_, __) =>
                                      Container(color: AppColors.surface),
                              errorWidget:
                                  (_, __, ___) =>
                                      Container(color: AppColors.surface),
                            ),
                          );
                        }, childCount: photoPosts.length),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                              childAspectRatio: 1,
                            ),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No photo posts yet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileBackgroundImage extends StatelessWidget {
  final String? imageUrl;

  const _ProfileBackgroundImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final avatar = imageUrl?.trim() ?? '';
    if (avatar.isEmpty) {
      return Container(color: AppColors.background);
    }

    return CachedNetworkImage(
      imageUrl: avatar,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppColors.background),
      errorWidget: (_, __, ___) => Container(color: AppColors.background),
    );
  }
}

class _FrostedProfileCard extends StatelessWidget {
  final String userFullName;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final String initials;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isOwnProfile;
  final bool isFollowedByMe;
  final VoidCallback? onEditAvatar;
  final VoidCallback onActionPressed;

  const _FrostedProfileCard({
    required this.userFullName,
    required this.username,
    required this.bio,
    required this.avatarUrl,
    required this.initials,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.isOwnProfile,
    required this.isFollowedByMe,
    required this.onEditAvatar,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AvatarWidget(
                        imageUrl: avatarUrl,
                        initials: initials,
                        size: 72,
                      ),
                      if (isOwnProfile)
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: onEditAvatar,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 14,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userFullName.trim().isNotEmpty
                              ? userFullName
                              : username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '@$username',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if ((bio ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  bio!.trim(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _GlassStatItem(
                      label: 'Followers',
                      value: followersCount.toString(),
                    ),
                  ),
                  Expanded(
                    child: _GlassStatItem(
                      label: 'Following',
                      value: followingCount.toString(),
                    ),
                  ),
                  Expanded(
                    child: _GlassStatItem(
                      label: 'Posts',
                      value: postsCount.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label:
                      isOwnProfile
                          ? 'Edit Profile'
                          : (isFollowedByMe ? 'Unfollow' : 'Follow'),
                  onPressed: onActionPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassStatItem extends StatelessWidget {
  final String label;
  final String value;

  const _GlassStatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
