import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../supabase_config.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';

class MessagesController extends ChangeNotifier {
  final supabase = SupabaseConfig.client;

  List<MessageModel> _messages = [];
  final Map<String, UserModel> _conversationUsers = {};
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  List<MessageModel> get messages => _messages;
  Map<String, UserModel> get conversationUsers => _conversationUsers;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  // Load messages between two users
  Future<void> loadMessages({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load the other user's profile
      final userResponse =
          await supabase
              .from('profiles')
              .select()
              .eq('id', otherUserId)
              .single();

      _conversationUsers[otherUserId] = UserModel.fromJson(userResponse);

      // Load messages between users (both directions)
      final messagesResponse = await supabase
          .from('messages')
          .select()
          .or(
            'and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)',
          )
          .order('created_at', ascending: true);

      _messages =
          (messagesResponse as List)
              .map((m) => MessageModel.fromJson(m))
              .toList();

      // Mark messages as read
      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('receiver_id', currentUserId)
          .eq('sender_id', otherUserId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String currentUserId,
    required String receiverId,
    required String content,
  }) async {
    try {
      _isSending = true;
      _error = null;
      notifyListeners();

      if (content.isEmpty) {
        _error = 'Message cannot be empty';
        _isSending = false;
        notifyListeners();
        return;
      }

      final messageId = const Uuid().v4();

      await supabase.from('messages').insert({
        'id': messageId,
        'sender_id': currentUserId,
        'receiver_id': receiverId,
        'content': content,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      final newMessage = MessageModel(
        id: messageId,
        senderId: currentUserId,
        receiverId: receiverId,
        content: content,
        isRead: false,
        createdAt: DateTime.now(),
      );

      _messages.add(newMessage);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // Get conversations list (latest message from each user)
  Future<List<Map<String, dynamic>>> loadConversations(
    String currentUserId,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get all unique users the current user has messaged
      final messagesResponse = await supabase
          .from('messages')
          .select('sender_id, receiver_id, content, created_at')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('created_at', ascending: false);

      // Group by conversation partner
      final Map<String, Map<String, dynamic>> conversations = {};

      for (final msg in messagesResponse as List) {
        final partnerId =
            msg['sender_id'] == currentUserId
                ? msg['receiver_id']
                : msg['sender_id'];

        if (!conversations.containsKey(partnerId)) {
          conversations[partnerId] = msg;
        }
      }

      // Load user profiles for each conversation
      for (final partnerId in conversations.keys) {
        if (!_conversationUsers.containsKey(partnerId)) {
          final userResponse =
              await supabase
                  .from('profiles')
                  .select()
                  .eq('id', partnerId)
                  .single();

          _conversationUsers[partnerId] = UserModel.fromJson(userResponse);
        }
      }

      final result =
          conversations.entries.map((entry) {
            return {
              'user_id': entry.key,
              'user': _conversationUsers[entry.key],
              'last_message': entry.value['content'],
              'last_message_at': entry.value['created_at'],
            };
          }).toList();

      return result;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void subscribeToMessages(String currentUserId, String otherUserId) {
    // TODO: Implement real-time message subscriptions using Supabase Realtime
    // This will listen for new messages and update the UI automatically
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetState() {
    _messages = [];
    _conversationUsers.clear();
    _isLoading = false;
    _isSending = false;
    _error = null;
    notifyListeners();
  }
}
