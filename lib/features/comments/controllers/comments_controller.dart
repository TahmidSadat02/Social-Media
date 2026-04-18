import 'package:flutter/material.dart';

import '../../../models/comment_model.dart';
import '../../../supabase_config.dart';

class CommentsController extends ChangeNotifier {
	final supabase = SupabaseConfig.client;

	List<CommentModel> topLevelComments = [];
	Map<String, bool> expandedReplies = {};
	String? replyingToCommentId;
	String? replyingToUsername;
	bool isLoading = false;
	final TextEditingController inputController = TextEditingController();

	String? _activePostId;

	Future<void> fetchComments(String postId) async {
		_activePostId = postId;

		try {
			isLoading = true;
			notifyListeners();

			final response = await supabase
					.from('comments')
					.select('*, profiles(*)')
					.eq('post_id', postId)
					.order('created_at', ascending: true);

			final allComments =
					(response as List)
							.map((row) => CommentModel.fromJson(row as Map<String, dynamic>))
							.toList();

			final topLevel =
					allComments.where((comment) => comment.parentId == null).toList();
			final topLevelIds = topLevel.map((comment) => comment.id).toSet();

			final Map<String, List<CommentModel>> repliesByParent = {};
			for (final comment in allComments) {
				final parentId = comment.parentId;
				if (parentId == null) {
					continue;
				}

				if (!topLevelIds.contains(parentId)) {
					continue;
				}

				repliesByParent.putIfAbsent(parentId, () => []).add(comment);
			}

			topLevelComments =
					topLevel.map((comment) {
						final replies = repliesByParent[comment.id] ?? <CommentModel>[];
						replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
						return comment.copyWith(replies: replies);
					}).toList();

			expandedReplies.removeWhere(
				(commentId, _) => !topLevelIds.contains(commentId),
			);
		} finally {
			isLoading = false;
			notifyListeners();
		}
	}

	Future<void> addComment(String postId) async {
		final content = inputController.text.trim();
		if (content.isEmpty) {
			return;
		}

		final currentUserId = supabase.auth.currentUser?.id;
		if (currentUserId == null) {
			return;
		}

		final parentId = replyingToCommentId;

		if (parentId != null) {
			final parentComment =
					await supabase
							.from('comments')
							.select('id, post_id, parent_id')
							.eq('id', parentId)
							.eq('post_id', postId)
							.maybeSingle();

			if (parentComment == null || parentComment['parent_id'] != null) {
				cancelReply();
				return;
			}
		}

		await supabase.from('comments').insert({
			'post_id': postId,
			'user_id': currentUserId,
			'parent_id': parentId,
			'content': content,
		});

		inputController.clear();
		cancelReply();
		await fetchComments(postId);
	}

	Future<void> deleteComment(String commentId) async {
		await supabase.from('comments').delete().eq('id', commentId);

		final postId = _activePostId;
		if (postId != null) {
			await fetchComments(postId);
		}
	}

	void setReplyingTo(String commentId, String username) {
		replyingToCommentId = commentId;
		replyingToUsername = username;
		notifyListeners();
	}

	void cancelReply() {
		replyingToCommentId = null;
		replyingToUsername = null;
		notifyListeners();
	}

	void toggleReplies(String commentId) {
		final current = expandedReplies[commentId] ?? false;
		expandedReplies[commentId] = !current;
		notifyListeners();
	}

	@override
	void dispose() {
		inputController.dispose();
		super.dispose();
	}
}
