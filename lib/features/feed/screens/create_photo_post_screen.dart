import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/feed_controller.dart';

class CreatePhotoPostScreen extends StatefulWidget {
  final String imagePath;

  const CreatePhotoPostScreen({super.key, required this.imagePath});

  @override
  State<CreatePhotoPostScreen> createState() => _CreatePhotoPostScreenState();
}

class _CreatePhotoPostScreenState extends State<CreatePhotoPostScreen> {
  late final TextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _handleShare() async {
    final authController = context.read<AuthController>();
    final feedController = context.read<FeedController>();

    final user = authController.currentUser;
    if (user == null) {
      return;
    }

    final imageBytes = await File(widget.imagePath).readAsBytes();
    final createdPost = await feedController.createPhotoPost(
      userId: user.id,
      imageBytes: imageBytes,
      caption: _captionController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (createdPost != null) {
      context.read<ProfileController>().addPostLocally(createdPost);
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(feedController.error ?? 'Failed to share post')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedController>(
      builder: (context, feedController, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: Text('New Post', style: AppTextStyles.heading3),
            actions: [
              TextButton(
                onPressed: feedController.isComposing ? null : _handleShare,
                child: Text(
                  'Share',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _captionController,
                  maxLines: 1,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Add a caption (optional)',
                    hintStyle: AppTextStyles.bodySmall,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.muted),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.muted),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (feedController.isComposing)
                  const LinearProgressIndicator(minHeight: 2),
              ],
            ),
          ),
        );
      },
    );
  }
}
