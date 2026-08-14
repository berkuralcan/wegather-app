import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/access_model.dart';
import '../models/community_model.dart';

/// One page of the community feed, plus what's needed to fetch the next one.
///
/// [cursor] is the raw snapshot of the last post on the page — the opaque token
/// the next [CommunityRepository.getPostsPage] call resumes from. [hasMore] is
/// false once a page comes back shorter than the requested limit, which is the
/// signal that the feed is exhausted and no further page should be requested.
class CommunityPostsPage {
  final List<CommunityPost> posts;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;

  const CommunityPostsPage({
    required this.posts,
    required this.cursor,
    required this.hasMore,
  });
}

/// The community feed in Firestore — `events/{eventId}/community/{postId}`, with
/// `likes/{uid}` and `comments/{commentId}` beneath each post.
///
/// This, with the gallery, is a collection the app *writes*. Reads inherit the
/// event's access; any user with access may post (as themselves), like, and
/// comment; only the admin panel may delete a post (see the community rules in
/// the admin panel's `firestore.rules`). The denormalized [CommunityPost.likeCount]
/// and [CommunityPost.commentCount] are kept in step here with an `increment()`
/// batched alongside the like/comment write, so a feed never has to count a
/// subcollection per tile.
class CommunityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _posts(String eventId) => _firestore
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.community);

  DocumentReference<Map<String, dynamic>> _post(
    String eventId,
    String postId,
  ) => _posts(eventId).doc(postId);

  CollectionReference<Map<String, dynamic>> _likes(
    String eventId,
    String postId,
  ) => _post(eventId, postId).collection(Collections.likes);

  CollectionReference<Map<String, dynamic>> _comments(
    String eventId,
    String postId,
  ) => _post(eventId, postId).collection(Collections.comments);

  // --- Posts ---------------------------------------------------------------

  /// The feed for an event, newest first, as a live stream.
  Stream<List<CommunityPost>> watchPosts(String eventId) {
    return _posts(eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              // The document id wins over any stale `id` in the body.
              .map(
                (doc) => CommunityPost.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  /// The feed for an event, newest first, fetched once.
  Future<List<CommunityPost>> getPosts(String eventId) async {
    final snap = await _posts(
      eventId,
    ).orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((doc) => CommunityPost.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// One post, live — what its own screen reads.
  ///
  /// Resolves to null when the document isn't there, which is what a post the
  /// panel has deleted looks like from here: the screen says so rather than
  /// sitting on a stale copy of something that no longer exists. The counts come
  /// along with it, so a like or a comment lands on screen as it is written.
  Stream<CommunityPost?> watchPost(String eventId, String postId) {
    return _post(eventId, postId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return CommunityPost.fromJson({...data, 'id': doc.id});
    });
  }

  /// One page of the feed, newest first, for infinite scroll.
  ///
  /// [startAfter] is the last document of the previous page (its raw snapshot,
  /// which is why the cursor is a [DocumentSnapshot] and not a model) — passing
  /// it makes Firestore resume from exactly where the last page ended, so a page
  /// only ever reads the [limit] documents it returns. The returned
  /// [CommunityPostsPage] carries the cursor and whether a further page exists.
  Future<CommunityPostsPage> getPostsPage({
    required String eventId,
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _posts(
      eventId,
    ).orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snap = await q.get();
    final posts = snap.docs
        .map((doc) => CommunityPost.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    return CommunityPostsPage(
      posts: posts,
      // The cursor for the next page; null when this page came back empty.
      cursor: snap.docs.isEmpty ? null : snap.docs.last,
      // A short page means the collection is exhausted — there's no next page.
      hasMore: snap.docs.length == limit,
    );
  }

  /// Create a post and return its new id.
  ///
  /// The media must already be in Storage. The server sets the timestamps and
  /// the counts, and [CommunityPost.mentionedUserIds] is derived from the
  /// caption's tokens here so a caller can't forget it — the caption is the one
  /// source of truth for who was tagged.
  Future<String> createPost({
    required String eventId,
    required String authorId,
    required String authorName,
    String? authorImage,
    required List<CommunityMedia> media,
    required String caption,
  }) async {
    final doc = await _posts(eventId).add({
      'authorId': authorId,
      'authorName': authorName,
      if (authorImage != null) 'authorImage': authorImage,
      'media': media.map((m) => m.toJson()).toList(),
      'caption': caption,
      'mentionedUserIds': Mentions.ids(caption),
      'likeCount': 0,
      'commentCount': 0,
      'isReported': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // --- Likes ---------------------------------------------------------------

  /// Whether [uid] has liked the post.
  Future<bool> hasLiked(String eventId, String postId, String uid) async {
    final snap = await _likes(eventId, postId).doc(uid).get();
    return snap.exists;
  }

  /// Live view of whether [uid] currently likes the post — for a heart that
  /// fills the moment the like lands.
  Stream<bool> watchHasLiked(String eventId, String postId, String uid) {
    return _likes(eventId, postId).doc(uid).snapshots().map((s) => s.exists);
  }

  /// Toggle [uid]'s like on a post, returning the new state (true = now liked).
  ///
  /// The like document is keyed by the uid, so it's idempotent; the current
  /// state is read first and the counter moved only when the state actually
  /// flips, so a double tap can't over-count. The like write and the count
  /// change go in one batch and can't drift.
  Future<bool> toggleLike(String eventId, String postId, String uid) async {
    final likeRef = _likes(eventId, postId).doc(uid);
    final exists = (await likeRef.get()).exists;
    final batch = _firestore.batch();
    if (exists) {
      batch.delete(likeRef);
      batch.update(_post(eventId, postId), {
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      batch.set(likeRef, {
        'userId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(_post(eventId, postId), {
        'likeCount': FieldValue.increment(1),
      });
    }
    await batch.commit();
    return !exists;
  }

  // --- Comments ------------------------------------------------------------

  /// A post's comments, oldest first (the order a thread reads in), as a stream.
  Stream<List<CommunityComment>> watchComments(String eventId, String postId) {
    return _comments(eventId, postId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    CommunityComment.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  /// Add a comment to a post and return its new id.
  ///
  /// `postId` and `eventId` are written onto the comment (the rules require it,
  /// and the panel's reported-comment query needs `eventId`), and the post's
  /// `commentCount` is bumped in the same batch. Mentions are derived from the
  /// content here, as with a post's caption.
  Future<String> addComment({
    required String eventId,
    required String postId,
    required String authorId,
    required String authorName,
    String? authorImage,
    required String content,
  }) async {
    final commentRef = _comments(eventId, postId).doc();
    final batch = _firestore.batch();
    batch.set(commentRef, {
      'postId': postId,
      'eventId': eventId,
      'authorId': authorId,
      'authorName': authorName,
      if (authorImage != null) 'authorImage': authorImage,
      'content': content,
      'mentionedUserIds': Mentions.ids(content),
      'isReported': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_post(eventId, postId), {
      'commentCount': FieldValue.increment(1),
    });
    await batch.commit();
    return commentRef.id;
  }

  /// Delete the caller's own comment and keep the post's `commentCount` honest.
  /// (Removing anyone else's comment is a moderation action, done in the panel.)
  Future<void> deleteOwnComment(
    String eventId,
    String postId,
    String commentId,
  ) async {
    final batch = _firestore.batch();
    batch.delete(_comments(eventId, postId).doc(commentId));
    batch.update(_post(eventId, postId), {
      'commentCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  // --- Reporting -----------------------------------------------------------

  /// Flag a post for moderation.
  ///
  /// [reason] is whatever the reporter typed, which may be nothing. As with the
  /// gallery, the report is a single flag rather than a counter or a list: one
  /// flag is all the panel needs to surface the post, and it's the only field
  /// shape the rules let a non-manager write.
  Future<void> reportPost(
    String eventId,
    String postId, {
    required String reportedBy,
    String? reason,
  }) {
    return _post(eventId, postId).update({
      'isReported': true,
      'reportedBy': reportedBy,
      'reportedAt': FieldValue.serverTimestamp(),
      if (reason != null && reason.trim().isNotEmpty)
        'reportReason': reason.trim(),
    });
  }

  /// Flag a comment for moderation. Same single-flag shape as [reportPost].
  Future<void> reportComment(
    String eventId,
    String postId,
    String commentId, {
    required String reportedBy,
    String? reason,
  }) {
    return _comments(eventId, postId).doc(commentId).update({
      'isReported': true,
      'reportedBy': reportedBy,
      'reportedAt': FieldValue.serverTimestamp(),
      if (reason != null && reason.trim().isNotEmpty)
        'reportReason': reason.trim(),
    });
  }
}
