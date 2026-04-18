import 'user_model.dart';

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String? parentId;
  final String content;
  final DateTime createdAt;
  final UserModel profile;
  final List<CommentModel> replies;

  int get replyCount => replies.length;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.parentId,
    required this.content,
    required this.createdAt,
    required this.profile,
    this.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'] ?? json['profiles'];

    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      parentId: json['parent_id'] as String?,
      content: (json['content'] as String? ?? '').trim(),
      createdAt: DateTime.parse(json['created_at'] as String),
      profile: UserModel.fromJson(profileJson as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'parent_id': parentId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'profile': profile.toJson(),
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'reply_count': replyCount,
    };
  }

  CommentModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? parentId,
    String? content,
    DateTime? createdAt,
    UserModel? profile,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      profile: profile ?? this.profile,
      replies: replies ?? this.replies,
    );
  }
}
