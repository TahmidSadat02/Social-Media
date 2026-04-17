import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../supabase_config.dart';
import '../../../models/post_model.dart';
import '../../../models/user_model.dart';

class FeedController extends ChangeNotifier {
  final supabase = SupabaseConfig.client;

  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _isComposing = false;
  String? _error;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isComposing => _isComposing;
  String? get error => _error;

  Future<void> loadPosts(String currentUserId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get posts with user profile info
      final response = await supabase
          .from('posts')
          .select('*, profiles(*), likes(*)')
          .order('created_at', ascending: false);

      // Check if current user has liked each post
      Set<String> likedPostIds = <String>{};
      try {
        final likesResponse = await supabase
            .from('likes')
            .select('post_id')
            .eq('user_id', currentUserId);
        likedPostIds =
            (likesResponse as List).map((e) => e['post_id'] as String).toSet();
      } catch (_) {
        // Likes data is optional for rendering posts; keep feed visible.
      }

      _posts =
          (response as List).map((post) {
            final postData = post as Map<String, dynamic>;
            postData['is_liked_by_me'] = likedPostIds.contains(post['id']);

            // Get likes count for this post
            return PostModel.fromJson(postData);
          }).toList();

      // TODO: Fetch likes count for each post (optimization)
      try {
        await _enrichPostsWithLikesCounts();
      } catch (_) {
        // Keep already loaded posts even if likes-count enrichment fails.
      }
    } catch (e) {
      _error = e.toString();
      _posts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _enrichPostsWithLikesCounts() async {
    for (int i = 0; i < _posts.length; i++) {
      try {
        final count = await supabase
            .from('likes')
            .count()
            .eq('post_id', _posts[i].id);
        _posts[i] = _posts[i].copyWith(likesCount: count);
      } catch (_) {
        // Skip likes count for this post if query fails.
      }
    }
  }

  Future<void> toggleLike(String postId, String userId) async {
    try {
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex == -1) return;

      final wasLiked = _posts[postIndex].isLikedByMe;

      // Optimistic update
      _posts[postIndex] = _posts[postIndex].copyWith(
        isLikedByMe: !wasLiked,
        likesCount: _posts[postIndex].likesCount + (wasLiked ? -1 : 1),
      );
      notifyListeners();

      if (wasLiked) {
        // Unlike
        await supabase
            .from('likes')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);
      } else {
        // Like
        await supabase.from('likes').insert({
          'id': const Uuid().v4(),
          'user_id': userId,
          'post_id': postId,
        });
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> composePost({
    required String content,
    required String userId,
  }) async {
    try {
      _isComposing = true;
      _error = null;
      notifyListeners();

      if (content.isEmpty) {
        _error = 'Post content cannot be empty';
        _isComposing = false;
        notifyListeners();
        return;
      }

      final postId = const Uuid().v4();

      await supabase.from('posts').insert({
        'id': postId,
        'user_id': userId,
        'content': content,
        'image_url': null,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Reload posts to get the new one with profile data
      // TODO: Optimize by just adding new post to list
      final userProfile =
          await supabase.from('profiles').select().eq('id', userId).single();

      final newPost = PostModel(
        id: postId,
        userId: userId,
        content: content,
        imageUrl: null,
        createdAt: DateTime.now(),
        likesCount: 0,
        isLikedByMe: false,
        profile: UserModel.fromJson(userProfile),
      );

      _posts.insert(0, newPost);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isComposing = false;
      notifyListeners();
    }
  }

  Future<bool> createPhotoPost({
    required String userId,
    required Uint8List imageBytes,
    String? caption,
  }) async {
    try {
      _isComposing = true;
      _error = null;
      notifyListeners();

      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('posts')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final imageUrl = supabase.storage.from('posts').getPublicUrl(fileName);
      final postId = const Uuid().v4();

      await supabase.from('posts').insert({
        'id': postId,
        'user_id': userId,
        'content': (caption ?? '').trim(),
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      final postResponse =
          await supabase
              .from('posts')
              .select('*, profiles(*), likes(*)')
              .eq('id', postId)
              .single();

      _posts.insert(0, PostModel.fromJson(postResponse));
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isComposing = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetState() {
    _posts = [];
    _isLoading = false;
    _isComposing = false;
    _error = null;
    notifyListeners();
  }
}
