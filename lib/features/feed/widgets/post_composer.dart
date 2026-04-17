import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/avatar_widget.dart';

class PostComposer extends StatefulWidget {
  final String? userAvatar;
  final String userInitials;
  final VoidCallback onCancel;
  final Future<void> Function(String content) onPost;
  final bool isLoading;

  const PostComposer({
    super.key,
    required this.userAvatar,
    required this.userInitials,
    required this.onCancel,
    required this.onPost,
    required this.isLoading,
  });

  @override
  State<PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<PostComposer> {
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _handlePost() async {
    if (_contentController.text.isNotEmpty) {
      await widget.onPost(_contentController.text);
      _contentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(
                imageUrl: widget.userAvatar,
                initials: widget.userInitials,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "What's on your mind?",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            minLines: 4,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Share your thoughts...',
              hintStyle: AppTextStyles.bodySmall,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.muted),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.muted),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.isLoading ? null : widget.onCancel,
                child: Text(
                  'Cancel',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'Post',
                onPressed: _handlePost,
                isLoading: widget.isLoading,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
