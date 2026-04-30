import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/tab_navigation_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../supabase_config.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../messages/controllers/messages_controller.dart';
import '../../search/controllers/search_controller.dart' as search_controller;
import '../controllers/profile_controller.dart';
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

  BorderRadius _tileRadius(int index, int total) {
    if (total == 0) {
      return BorderRadius.zero;
    }

    final columns = 3;
    final rows = ((total - 1) ~/ columns) + 1;
    final firstRowMaxIndex = math.min(columns, total) - 1;
    final bottomLeftIndex = (rows - 1) * columns;
    final bottomRightIndex = total - 1;

    return BorderRadius.only(
      topLeft: index == 0 ? const Radius.circular(20) : Radius.zero,
      topRight:
          index == firstRowMaxIndex ? const Radius.circular(20) : Radius.zero,
      bottomLeft:
          index == bottomLeftIndex ? const Radius.circular(20) : Radius.zero,
      bottomRight:
          index == bottomRightIndex ? const Radius.circular(20) : Radius.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser?.id;
    final isOwnProfile = widget.userId == currentUserId;
    const expandedHeaderHeight = 380.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
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
          final displayName =
              user.fullName.trim().isNotEmpty ? user.fullName : user.username;
          final photoPosts =
              profileController.userPosts
                  .where((post) => (post.imageUrl ?? '').trim().isNotEmpty)
                  .toList();

          return CustomScrollView(
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: expandedHeaderHeight,
                backgroundColor: AppColors.background,
                surfaceTintColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  '@${user.username}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  if (isOwnProfile)
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: _showSettingsSheet,
                    ),
                ],
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final topPadding = MediaQuery.of(context).padding.top;
                    final collapsedHeight = kToolbarHeight + topPadding;
                    final range = expandedHeaderHeight - collapsedHeight;
                    final currentHeight = constraints.biggest.height;
                    final blurProgress =
                        range <= 0
                            ? 1.0
                            : ((expandedHeaderHeight - currentHeight) / range)
                                .clamp(0.0, 1.0);

                    return FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      background: _ProfileCoverBackground(
                        imageUrl: user.avatarUrl,
                        blurProgress: blurProgress,
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -58),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _GlassInfoCard(
                      displayName: displayName,
                      username: user.username,
                      bio: user.bio,
                      followersCount: profileController.followersCount,
                      followingCount: profileController.followingCount,
                      postsCount: profileController.postsCount,
                      isOwnProfile: isOwnProfile,
                      isFollowedByMe: profileController.isFollowedByMe,
                      onActionTap: () {
                        if (isOwnProfile) {
                          return;
                        }
                        if (currentUserId == null) {
                          return;
                        }
                        profileController.toggleFollow(user.id, currentUserId);
                      },
                    ),
                  ),
                ),
              ),
              if (photoPosts.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                          childAspectRatio: 1,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final post = photoPosts[index];
                      final imageUrl = post.imageUrl!;

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => PhotoPostDetailScreen.carousel(
                                    posts: photoPosts,
                                    initialIndex: index,
                                  ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: _tileRadius(index, photoPosts.length),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder:
                                (_, __) => Container(color: AppColors.surface),
                            errorWidget:
                                (_, __, ___) =>
                                    Container(color: AppColors.surface),
                          ),
                        ),
                      );
                    }, childCount: photoPosts.length),
                  ),
                )
              else
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
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
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileCoverBackground extends StatelessWidget {
  final String? imageUrl;
  final double blurProgress;

  const _ProfileCoverBackground({
    required this.imageUrl,
    required this.blurProgress,
  });

  @override
  Widget build(BuildContext context) {
    final cover = (imageUrl ?? '').trim();
    final sigma = lerpDouble(0, 16, blurProgress)!;
    final overlayAlpha = lerpDouble(0.02, 0.18, blurProgress)!;
    final gradientTop = lerpDouble(0.05, 0.12, blurProgress)!;
    final gradientMid = lerpDouble(0.2, 0.38, blurProgress)!;
    final gradientBottom = lerpDouble(0.78, 0.92, blurProgress)!;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (cover.isNotEmpty)
          CachedNetworkImage(
            imageUrl: cover,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.background),
            errorWidget: (_, __, ___) => Container(color: AppColors.background),
          )
        else
          Container(color: AppColors.background),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(color: Colors.black.withValues(alpha: overlayAlpha)),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: gradientTop),
                Colors.black.withValues(alpha: gradientMid),
                AppColors.background.withValues(alpha: gradientBottom),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassInfoCard extends StatelessWidget {
  final String displayName;
  final String username;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isOwnProfile;
  final bool isFollowedByMe;
  final VoidCallback onActionTap;

  const _GlassInfoCard({
    required this.displayName,
    required this.username,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.isOwnProfile,
    required this.isFollowedByMe,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final actionLabel =
        isOwnProfile
            ? 'Edit Profile'
            : (isFollowedByMe ? 'Following' : 'Follow');

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.44),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '@$username',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if ((bio ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  bio!.trim(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatValue(
                      value: followersCount.toString(),
                      label: 'Followers',
                    ),
                  ),
                  Expanded(
                    child: _StatValue(
                      value: followingCount.toString(),
                      label: 'Following',
                    ),
                  ),
                  Expanded(
                    child: _StatValue(
                      value: postsCount.toString(),
                      label: 'Creations',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ActionButton(
                label: actionLabel,
                isOwnProfile: isOwnProfile,
                onTap: onActionTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatValue extends StatelessWidget {
  final String value;
  final String label;

  const _StatValue({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isOwnProfile;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.isOwnProfile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    final decoration =
        isOwnProfile
            ? BoxDecoration(
              color: Colors.black.withValues(alpha: 0.38),
              borderRadius: radius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            )
            : BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4D8D), Color(0xFFFF9A3C)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            );

    return DecoratedBox(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
