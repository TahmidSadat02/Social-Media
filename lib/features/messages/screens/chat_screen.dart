import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/initials.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../controllers/messages_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthController>();
      final messagesController = context.read<MessagesController>();

      if (authController.isAuthenticated) {
        messagesController.loadMessages(
          currentUserId: authController.currentUser!.id,
          otherUserId: widget.otherUserId,
        );

        // Subscribe to real-time messages
        messagesController.subscribeToMessages(
          authController.currentUser!.id,
          widget.otherUserId,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(
    MessagesController messagesController,
    AuthController authController,
  ) async {
    if (_messageController.text.isNotEmpty) {
      await messagesController.sendMessage(
        currentUserId: authController.currentUser!.id,
        receiverId: widget.otherUserId,
        content: _messageController.text,
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: InkWell(
          onTap: () => navigateToProfile(context, widget.otherUserId),
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.otherUserName, style: AppTextStyles.heading3),
            ),
          ),
        ),
      ),
      body: Consumer2<AuthController, MessagesController>(
        builder: (context, authController, messagesController, _) {
          if (!authController.isAuthenticated) {
            return Center(
              child: Text('Please log in', style: AppTextStyles.bodyMedium),
            );
          }

          if (messagesController.isLoading) {
            return const LoadingWidget(message: 'Loading messages...');
          }

          final currentUserId = authController.currentUser!.id;
          final otherUser =
              messagesController.conversationUsers[widget.otherUserId];

          return Column(
            children: [
              Expanded(
                child:
                    messagesController.messages.isEmpty
                        ? Center(
                          child: Text(
                            'No messages yet. Say hello!',
                            style: AppTextStyles.bodySmall,
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: messagesController.messages.length,
                          itemBuilder: (context, index) {
                            final message = messagesController.messages[index];
                            final isMe = message.senderId == currentUserId;

                            return _MessageBubble(
                              message: message.content,
                              isMe: isMe,
                              otherUserAvatarUrl: otherUser?.avatarUrl,
                              otherUserInitials: getInitials(
                                otherUser?.fullName ?? otherUser?.username,
                              ),
                              onOtherAvatarTap:
                                  isMe
                                      ? null
                                      : () => navigateToProfile(
                                        context,
                                        widget.otherUserId,
                                      ),
                            );
                          },
                        ),
              ),
              // Message input
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        minLines: 1,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: AppTextStyles.bodySmall,
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: AppColors.muted,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: AppColors.muted,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: AppColors.accent,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap:
                          messagesController.isSending
                              ? null
                              : () => _sendMessage(
                                messagesController,
                                authController,
                              ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                        child: Icon(
                          Icons.send,
                          color: AppColors.background,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String? otherUserAvatarUrl;
  final String otherUserInitials;
  final VoidCallback? onOtherAvatarTap;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.otherUserAvatarUrl,
    required this.otherUserInitials,
    this.onOtherAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? AppColors.accent : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isMe ? AppColors.background : AppColors.text,
        ),
      ),
    );

    if (isMe) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: AvatarWidget(
                imageUrl: otherUserAvatarUrl,
                initials: otherUserInitials,
                size: 36,
                onTap: onOtherAvatarTap,
              ),
            ),
          ),
          const SizedBox(width: 8),
          bubble,
        ],
      ),
    );
  }
}
