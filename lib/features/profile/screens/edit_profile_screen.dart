import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/initials.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final String initialFullName;
  final String? initialBio;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.initialFullName,
    required this.initialBio,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _bioController;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.initialFullName);
    _bioController = TextEditingController(text: widget.initialBio ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final fullName = _fullNameController.text.trim();
    final bioRaw = _bioController.text.trim();
    final bio = bioRaw.isEmpty ? null : bioRaw;

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name cannot be empty')),
      );
      return;
    }

    final profileController = context.read<ProfileController>();
    await profileController.updateProfile(
      userId: widget.userId,
      fullName: fullName,
      bio: bio,
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

    Navigator.of(context).pop(true);
  }

  Future<void> _changeProfilePhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();
    final profileController = context.read<ProfileController>();
    await profileController.updateProfileAvatar(
      userId: widget.userId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Edit Profile', style: AppTextStyles.heading3),
      ),
      body: Consumer<ProfileController>(
        builder: (context, profileController, _) {
          final user = profileController.user;
          final avatarInitials = getInitials(
            _fullNameController.text.trim().isNotEmpty
                ? _fullNameController.text.trim()
                : user?.username,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      AvatarWidget(
                        imageUrl: user?.avatarUrl,
                        initials: avatarInitials,
                        size: 92,
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed:
                            profileController.isLoading
                                ? null
                                : _changeProfilePhoto,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Change Profile Picture'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _fullNameController,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Bio',
                  hint: 'Tell people about yourself',
                  controller: _bioController,
                  maxLines: 4,
                  minLines: 3,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Save Changes',
                  isLoading: profileController.isLoading,
                  onPressed: _saveProfile,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
