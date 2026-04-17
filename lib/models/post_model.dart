import 'user_model.dart';

class PostModel {
  final String id;
  final String userId;
  final String? content;
  final String? imageUrl;
  final DateTime createdAt;
  final int likesCount;
  final bool isLikedByMe;
  final UserModel? profile;

  PostModel({
    required this.id,
    required this.userId,
    this.content,
    this.imageUrl,
    required this.createdAt,
    this.likesCount = 0,
    this.isLikedByMe = false,
    this.profile,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'] ?? json['profiles'];
    final likesJson = json['likes'];
    final likesCountFromRelation =
        likesJson is List
            ? likesJson.length
            : (json['likes_count'] as num?)?.toInt();

    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      likesCount: likesCountFromRelation ?? 0,
      isLikedByMe: json['is_liked_by_me'] as bool? ?? false,
      profile:
          profileJson != null
              ? UserModel.fromJson(profileJson as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'likes_count': likesCount,
      'is_liked_by_me': isLikedByMe,
      if (profile != null) 'profile': profile!.toJson(),
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
    int? likesCount,
    bool? isLikedByMe,
    UserModel? profile,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      profile: profile ?? this.profile,
    );
  }
}
