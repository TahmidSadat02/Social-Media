import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/initials.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/loading_widget.dart';
import '../controllers/messages_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() async {
    final authController = context.read<AuthController>();
    final messagesController = context.read<MessagesController>();

    if (authController.isAuthenticated) {
      setState(() => _isLoading = true);
      final conversations = await messagesController.loadConversations(
        authController.currentUser!.id,
      );
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Messages', style: AppTextStyles.heading3),
        centerTitle: true,
      ),
      body: Consumer<AuthController>(
        builder: (context, authController, _) {
          if (!authController.isAuthenticated) {
            return Center(
              child: Text('Please log in', style: AppTextStyles.bodyMedium),
            );
          }

          if (_isLoading) {
            return const LoadingWidget(message: 'Loading conversations...');
          }

          if (_conversations.isEmpty) {
            return Center(
              child: Text(
                'No conversations yet',
                style: AppTextStyles.bodySmall,
              ),
            );
          }

          return ListView.builder(
            itemCount: _conversations.length,
            itemBuilder: (context, index) {
              final conversation = _conversations[index];
              final user = conversation['user'];
              final lastMessage = conversation['last_message'] as String;
              final lastMessageAt = conversation['last_message_at'] as String;
              final initials = getInitials(user.fullName ?? user.username);

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => ChatScreen(
                            otherUserId: conversation['user_id'],
                            otherUserName: user.username,
                          ),
                    ),
                  );
                },
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 1),
                  child: Row(
                    children: [
                      AvatarWidget(
                        imageUrl: user.avatarUrl,
                        initials: initials,
                        size: 50,
                        onTap: () {
                          navigateToProfile(
                            context,
                            conversation['user_id'] as String,
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                navigateToProfile(
                                  context,
                                  conversation['user_id'] as String,
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 44,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    user.username,
                                    style: AppTextStyles.bodyLarge,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastMessage,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        TimeAgoFormatter.format(DateTime.parse(lastMessageAt)),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
