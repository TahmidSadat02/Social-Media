class FollowModel {
  final String id;
  final String followerId;
  final String followingId;

  FollowModel({
    required this.id,
    required this.followerId,
    required this.followingId,
  });

  factory FollowModel.fromJson(Map<String, dynamic> json) {
    return FollowModel(
      id: json['id'] as String,
      followerId: json['follower_id'] as String,
      followingId: json['following_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'follower_id': followerId, 'following_id': followingId};
  }
}
