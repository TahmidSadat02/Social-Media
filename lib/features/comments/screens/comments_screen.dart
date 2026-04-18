import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/initials.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../models/comment_model.dart';
import '../../../supabase_config.dart';
import '../controllers/comments_controller.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final String? postImageUrl;

  const CommentsScreen({super.key, required this.postId, this.postImageUrl});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentsController>().fetchComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseConfig.client.auth.currentUser;
    final currentUserId = currentUser?.id;
    final currentUserInitials = getInitials(currentUser?.email ?? 'Me');

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: (widget.postImageUrl ?? '').isEmpty,
        leadingWidth: (widget.postImageUrl ?? '').isNotEmpty ? 96 : null,
        leading: _buildLeadingWithThumbnail(context),
        title: Text('Comments', style: AppTextStyles.heading3),
      ),
      body: Consumer<CommentsController>(
        builder: (context, controller, _) {
          return Column(
            children: [
              Expanded(
                child: _buildCommentsBody(
                  context: context,
                  controller: controller,
                  currentUserId: currentUserId,
                ),
              ),
              SafeArea(
                top: false,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.replyingToUsername != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.bodySmall,
                                    children: [
                                      const TextSpan(text: 'Replying to '),
                                      TextSpan(
                                        text:
                                            '@${controller.replyingToUsername}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: controller.cancelReply,
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AvatarWidget(
                            imageUrl: null,
                            initials: currentUserInitials,
                            size: 32,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: controller.inputController,
                              focusNode: _inputFocusNode,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) {
                                controller.addComment(widget.postId);
                              },
                              style: AppTextStyles.bodyMedium,
                              decoration: InputDecoration(
                                hintText:
                                    controller.replyingToUsername == null
                                        ? 'Add a comment...'
                                        : 'Reply to @${controller.replyingToUsername}...',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.muted,
                                ),
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => controller.addComment(widget.postId),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent,
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                size: 18,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget? _buildLeadingWithThumbnail(BuildContext context) {
    if ((widget.postImageUrl ?? '').isEmpty) {
      return null;
    }

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            widget.postImageUrl!,
            width: 28,
            height: 28,
            fit: BoxFit.cover,
            errorBuilder:
                (context, _, __) => Container(
                  width: 28,
                  height: 28,
                  color: AppColors.background,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsBody({
    required BuildContext context,
    required CommentsController controller,
    required String? currentUserId,
  }) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (controller.topLevelComments.isEmpty) {
      return Center(
        child: Text(
          'No comments yet. Be the first to comment.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: controller.topLevelComments.length,
      itemBuilder: (context, index) {
        final comment = controller.topLevelComments[index];
        final isExpanded = controller.expandedReplies[comment.id] ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCommentItem(
                context: context,
                comment: comment,
                currentUserId: currentUserId,
                showReplyButton: true,
                onReplyTap: () {
                  controller.setReplyingTo(
                    comment.id,
                    comment.profile.username,
                  );
                  _inputFocusNode.requestFocus();
                },
              ),
              if (comment.replyCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 44, top: 4),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => controller.toggleReplies(comment.id),
                    child: Text(
                      isExpanded
                          ? 'Hide replies'
                          : 'View ${comment.replyCount} replies',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (isExpanded && comment.replies.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(left: 40, top: 6),
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.45),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children:
                        comment.replies
                            .map(
                              (reply) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildCommentItem(
                                  context: context,
                                  comment: reply,
                                  currentUserId: currentUserId,
                                  showReplyButton: false,
                                  replyingToUsername: comment.profile.username,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentItem({
    required BuildContext context,
    required CommentModel comment,
    required String? currentUserId,
    required bool showReplyButton,
    VoidCallback? onReplyTap,
    String? replyingToUsername,
  }) {
    final isMyComment = currentUserId == comment.userId;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvatarWidget(
          imageUrl: comment.profile.avatarUrl,
          initials: getInitials(comment.profile.fullName),
          size: 32,
          onTap: () => navigateToProfile(context, comment.profile.id),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => navigateToProfile(context, comment.profile.id),
                child: Text(
                  comment.profile.username,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              if (replyingToUsername != null)
                Text(
                  'Replying to @$replyingToUsername',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              Text(comment.content, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    TimeAgoFormatter.format(comment.createdAt),
                    style: AppTextStyles.bodySmall,
                  ),
                  if (showReplyButton) ...[
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: onReplyTap,
                      child: Text(
                        'Reply',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (isMyComment) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        context.read<CommentsController>().deleteComment(
                          comment.id,
                        );
                      },
                      child: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
