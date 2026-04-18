class LikeModel {
  final String id;
  final String userId;
  final String postId;

  LikeModel({required this.id, required this.userId, required this.postId});

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      postId: json['post_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'user_id': userId, 'post_id': postId};
  }
}
