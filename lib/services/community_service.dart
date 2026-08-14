import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../models/community_model.dart';
import '../repositories/community_repository.dart';
import 'media_upload_service.dart';

/// Business logic around an event's community feed: paging through it, and the
/// authoring actions (post, like, comment, report) the app performs on it.
///
/// The screen talks to this rather than the repository directly, matching the
/// gallery. Reads are paged for the infinite-scroll feed; the write methods are
/// thin pass-throughs today, with room to grow (validation, media upload) the
/// way [GalleryService] did.
class CommunityService {
  final CommunityRepository _repository = CommunityRepository();
  final MediaUploadService _uploader = MediaUploadService();

  /// How many posts a page of the feed holds. Small enough that the first
  /// screenful lands fast, large enough that scrolling rarely waits on a fetch.
  static const int pageSize = 10;

  /// How many posts the landing screen's strip previews.
  static const int latestCount = 5;

  /// The longest a caption may be. Enforced here as well as in the composer's
  /// field, so the limit is one number rather than a UI detail.
  static const int captionMaxLength = 1000;

  /// How many photos and videos one post's carousel may hold.
  static const int mediaMaxCount = 10;

  /// The longest a comment may be — shorter than a caption, because a comment is
  /// a reply rather than the thing being replied to.
  static const int commentMaxLength = 500;

  /// One page of the feed, newest first. [startAfter] is the cursor from the
  /// previous page ([CommunityPostsPage.cursor]); omit it for the first page.
  Future<CommunityPostsPage> getFeedPage({
    required String eventId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    if (eventId.isEmpty) {
      throw ArgumentError('Event ID cannot be empty');
    }
    return _repository.getPostsPage(
      eventId: eventId,
      limit: pageSize,
      startAfter: startAfter,
    );
  }

  /// The newest [limit] posts, for a preview of the feed rather than the feed
  /// itself — the landing screen's strip. No cursor comes back with them,
  /// because there is nothing to page: whoever wants more opens `/community`.
  Future<List<CommunityPost>> getLatestPosts({
    required String eventId,
    int limit = latestCount,
  }) async {
    if (eventId.isEmpty) {
      throw ArgumentError('Event ID cannot be empty');
    }
    final page = await _repository.getPostsPage(eventId: eventId, limit: limit);
    return page.posts;
  }

  /// Uploads a composed post's media and writes the post, returning its id.
  ///
  /// [files] are uploaded in the order they were picked, which is the order the
  /// carousel draws them in — one after another rather than all at once, because
  /// a phone on event wifi uploading ten clips in parallel finishes no sooner
  /// and is far likelier to have one of them time out.
  ///
  /// The caption is stored as the composer wrote it, mention tokens and all; the
  /// repository derives `mentionedUserIds` from it.
  Future<String> createPost({
    required String companyId,
    required String eventId,
    required String authorId,
    required String authorName,
    String? authorImage,
    required List<XFile> files,
    required String caption,
  }) async {
    if (companyId.isEmpty || eventId.isEmpty || authorId.isEmpty) {
      throw ArgumentError('Company ID, event ID and author cannot be empty');
    }
    if (files.isEmpty) {
      throw ArgumentError('A post needs at least one photo or video');
    }
    if (files.length > mediaMaxCount) {
      throw ArgumentError('A post holds at most $mediaMaxCount items');
    }
    if (caption.length > captionMaxLength) {
      throw ArgumentError(
        'A caption holds at most $captionMaxLength characters',
      );
    }

    final media = <CommunityMedia>[];
    for (final file in files) {
      final type = mediaTypeOf(file);
      final uploaded = await _uploader.upload(
        companyId: companyId,
        eventId: eventId,
        file: file,
        type: type,
      );
      media.add(
        CommunityMedia(
          url: uploaded.url,
          type: type,
          thumbUrl: uploaded.thumbUrl,
        ),
      );
    }

    return _repository.createPost(
      eventId: eventId,
      authorId: authorId,
      authorName: authorName,
      authorImage: authorImage,
      media: media,
      caption: caption,
    );
  }

  /// One post, live — null once it no longer exists.
  Stream<CommunityPost?> watchPost(String eventId, String postId) =>
      _repository.watchPost(eventId, postId);

  /// Whether [uid] currently likes the post — a one-shot check for the first
  /// paint. [watchHasLiked] is the live version.
  Future<bool> hasLiked(String eventId, String postId, String uid) =>
      _repository.hasLiked(eventId, postId, uid);

  /// Live view of whether [uid] likes the post, for a heart that fills as soon
  /// as the like lands.
  Stream<bool> watchHasLiked(String eventId, String postId, String uid) =>
      _repository.watchHasLiked(eventId, postId, uid);

  /// Toggle [uid]'s like on a post; returns the new state (true = now liked).
  Future<bool> toggleLike(String eventId, String postId, String uid) =>
      _repository.toggleLike(eventId, postId, uid);

  /// A post's comments, oldest first, as a live stream.
  Stream<List<CommunityComment>> watchComments(String eventId, String postId) =>
      _repository.watchComments(eventId, postId);

  /// Add a comment to a post and return its new id.
  ///
  /// The text is stored as it was typed, mention tokens and all; the repository
  /// derives the mentioned uids from it and keeps the post's `commentCount` in
  /// step. Empty comments are refused here rather than left to the rules.
  Future<String> addComment({
    required String eventId,
    required String postId,
    required String authorId,
    required String authorName,
    String? authorImage,
    required String content,
  }) {
    if (eventId.isEmpty || postId.isEmpty || authorId.isEmpty) {
      throw ArgumentError('Event ID, post ID and author cannot be empty');
    }
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('A comment cannot be empty');
    }
    if (trimmed.length > commentMaxLength) {
      throw ArgumentError(
        'A comment holds at most $commentMaxLength characters',
      );
    }
    return _repository.addComment(
      eventId: eventId,
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorImage: authorImage,
      content: trimmed,
    );
  }

  /// Delete the caller's own comment. Removing anyone else's is a moderation
  /// action, done in the admin panel.
  Future<void> deleteOwnComment(
    String eventId,
    String postId,
    String commentId,
  ) {
    if (eventId.isEmpty || postId.isEmpty || commentId.isEmpty) {
      throw ArgumentError('Ids cannot be empty');
    }
    return _repository.deleteOwnComment(eventId, postId, commentId);
  }

  /// Report a post for the admin panel to moderate.
  Future<void> reportPost(
    String eventId,
    String postId, {
    required String reportedBy,
    String? reason,
  }) {
    if (eventId.isEmpty || postId.isEmpty || reportedBy.isEmpty) {
      throw ArgumentError('Event ID, post ID and reporter cannot be empty');
    }
    return _repository.reportPost(
      eventId,
      postId,
      reportedBy: reportedBy,
      reason: reason,
    );
  }

  /// Report a comment for the admin panel to moderate.
  Future<void> reportComment(
    String eventId,
    String postId,
    String commentId, {
    required String reportedBy,
    String? reason,
  }) {
    if (eventId.isEmpty ||
        postId.isEmpty ||
        commentId.isEmpty ||
        reportedBy.isEmpty) {
      throw ArgumentError('Ids and reporter cannot be empty');
    }
    return _repository.reportComment(
      eventId,
      postId,
      commentId,
      reportedBy: reportedBy,
      reason: reason,
    );
  }
}
