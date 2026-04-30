import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../supabase_config.dart';
import '../../../models/user_model.dart';
import '../../../models/post_model.dart';

class ProfileController extends ChangeNotifier {
  final supabase = SupabaseConfig.client;
  RealtimeChannel? _postsChannel;

  String? _viewedUserId;
  String? _currentUserId;

  UserModel? _user;
  List<PostModel> _userPosts = [];
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;
  bool _isFollowedByMe = false;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  List<PostModel> get userPosts => _userPosts;
  int get followersCount => _followersCount;
  int get followingCount => _followingCount;
  int get postsCount => _postsCount;
  bool get isFollowedByMe => _isFollowedByMe;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get viewedUserId => _viewedUserId;
  String? get currentUserId => _currentUserId;

  Future<void> loadProfile({
    required String viewedUserId,
    required String currentUserId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      _unsubscribePostsRealtime();
      _viewedUserId = viewedUserId;
      _currentUserId = currentUserId;
      notifyListeners();

      // Load user profile
      final userResponse =
          await supabase
              .from('profiles')
              .select()
              .eq('id', viewedUserId)
              .single();

      _user = UserModel.fromJson(userResponse);

      // Load user posts
      final postsResponse = await supabase
          .from('posts')
          .select('*, profiles(*), likes(count)')
          .eq('user_id', viewedUserId)
          .order('created_at', ascending: false);

      _userPosts =
          (postsResponse as List).map((p) => PostModel.fromJson(p)).toList();
      _postsCount = _userPosts.length;
      _subscribeToPostsRealtime(viewedUserId);

      // Load followers count
      final followersResponse = await supabase
          .from('follows')
          .count()
          .eq('following_id', viewedUserId);
      _followersCount = followersResponse;

      // Load following count
      final followingResponse = await supabase
          .from('follows')
          .count()
          .eq('follower_id', viewedUserId);
      _followingCount = followingResponse;

      // Check if current user follows this user
      _isFollowedByMe = false;
      if (currentUserId != viewedUserId) {
        final followResponse = await supabase
            .from('follows')
            .select()
            .eq('follower_id', currentUserId)
            .eq('following_id', viewedUserId);

        _isFollowedByMe = (followResponse as List).isNotEmpty;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToPostsRealtime(String viewedUserId) {
    _postsChannel =
        supabase
            .channel('profile-posts-$viewedUserId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'posts',
              callback: (payload) {
                if (_viewedUserId != viewedUserId) {
                  return;
                }

                if (payload.eventType == PostgresChangeEvent.insert) {
                  final newRecord = payload.newRecord;
                  final newUserId = (newRecord['user_id'] ?? '').toString();
                  if (newUserId != viewedUserId) {
                    return;
                  }

                  final id = (newRecord['id'] ?? '').toString();
                  if (id.isEmpty || _userPosts.any((p) => p.id == id)) {
                    return;
                  }

                  final createdAtRaw =
                      (newRecord['created_at'] ??
                              DateTime.now().toIso8601String())
                          .toString();
                  final createdAt =
                      DateTime.tryParse(createdAtRaw) ?? DateTime.now();

                  _userPosts.insert(
                    0,
                    PostModel(
                      id: id,
                      userId: (newRecord['user_id'] ?? viewedUserId).toString(),
                      content: newRecord['content'] as String?,
                      imageUrl: newRecord['image_url'] as String?,
                      createdAt: createdAt,
                      likesCount: 0,
                      commentCount: 0,
                      isLikedByMe: false,
                      profile: _user,
                    ),
                  );
                  _postsCount = _userPosts.length;
                  notifyListeners();
                  return;
                }

                if (payload.eventType == PostgresChangeEvent.update) {
                  final newRecord = payload.newRecord;
                  final updatedId = (newRecord['id'] ?? '').toString();
                  final updatedUserId = (newRecord['user_id'] ?? '').toString();
                  if (updatedId.isEmpty || updatedUserId != viewedUserId) {
                    return;
                  }

                  final index = _userPosts.indexWhere((p) => p.id == updatedId);
                  if (index == -1) {
                    return;
                  }

                  final createdAtRaw =
                      (newRecord['created_at'] ??
                              _userPosts[index].createdAt.toIso8601String())
                          .toString();
                  final createdAt =
                      DateTime.tryParse(createdAtRaw) ??
                      _userPosts[index].createdAt;

                  _userPosts[index] = _userPosts[index].copyWith(
                    content: newRecord['content'] as String?,
                    imageUrl: newRecord['image_url'] as String?,
                    createdAt: createdAt,
                  );
                  notifyListeners();
                  return;
                }

                if (payload.eventType == PostgresChangeEvent.delete) {
                  final oldRecord = payload.oldRecord;
                  final id = (oldRecord['id'] ?? '').toString();
                  if (id.isEmpty) {
                    return;
                  }

                  removePostLocally(id);
                }
              },
            )
            .subscribe();
  }

  void _unsubscribePostsRealtime() {
    _postsChannel?.unsubscribe();
    _postsChannel = null;
  }

  Future<void> toggleFollow(String targetUserId, String currentUserId) async {
    try {
      if (_isFollowedByMe) {
        // Unfollow
        await supabase
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', targetUserId);

        _isFollowedByMe = false;
        _followersCount--;
      } else {
        // Follow
        await supabase.from('follows').insert({
          'id': const Uuid().v4(),
          'follower_id': currentUserId,
          'following_id': targetUserId,
        });

        _isFollowedByMe = true;
        _followersCount++;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String? bio,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await supabase
          .from('profiles')
          .update({'full_name': fullName, 'bio': bio})
          .eq('id', userId);

      _user = _user?.copyWith(fullName: fullName, bio: bio);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfileAvatar({
    required String userId,
    required Uint8List imageBytes,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('posts')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final avatarUrl = supabase.storage.from('posts').getPublicUrl(fileName);

      await supabase
          .from('profiles')
          .update({'avatar_url': avatarUrl})
          .eq('id', userId);

      _user = _user?.copyWith(avatarUrl: avatarUrl);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final postIndex = _userPosts.indexWhere((p) => p.id == postId);
      if (postIndex == -1) return;
      final post = _userPosts[postIndex];

      if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
        try {
          final uri = Uri.parse(post.imageUrl!);
          final fileName =
              uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
          if (fileName.isNotEmpty) {
            await supabase.storage.from('posts').remove([fileName]);
          }
        } catch (_) {
          // Keep going even if storage cleanup fails.
        }
      }

      await supabase.from('posts').delete().eq('id', postId);

      removePostLocally(postId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void addPostLocally(PostModel post) {
    if (_viewedUserId != post.userId) {
      return;
    }

    if (_userPosts.any((p) => p.id == post.id)) {
      return;
    }

    _userPosts.insert(
      0,
      post.profile == null ? post.copyWith(profile: _user) : post,
    );
    _postsCount = _userPosts.length;
    notifyListeners();
  }

  void removePostLocally(String postId) {
    final before = _userPosts.length;
    _userPosts.removeWhere((p) => p.id == postId);
    if (_userPosts.length == before) {
      return;
    }

    _postsCount = _userPosts.length;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetState() {
    _unsubscribePostsRealtime();
    _viewedUserId = null;
    _currentUserId = null;
    _user = null;
    _userPosts = [];
    _followersCount = 0;
    _followingCount = 0;
    _postsCount = 0;
    _isFollowedByMe = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _unsubscribePostsRealtime();
    super.dispose();
  }
}
