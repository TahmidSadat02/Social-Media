import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../supabase_config.dart';
import '../../../models/user_model.dart';
import '../../../models/post_model.dart';

class ProfileController extends ChangeNotifier {
  final supabase = SupabaseConfig.client;

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
          .select('*, profiles(*), likes(*)')
          .eq('user_id', viewedUserId)
          .order('created_at', ascending: false);

      _userPosts =
          (postsResponse as List).map((p) => PostModel.fromJson(p)).toList();
      _postsCount = _userPosts.length;

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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetState() {
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
}
