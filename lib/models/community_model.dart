import 'package:cloud_firestore/cloud_firestore.dart';
import 'gallery_media.dart';

/// The community feed — the app's Instagram-like feature.
///
/// A user creates a [CommunityPost] (one or more photos/videos plus a caption),
/// and other users like and comment on it. This is the app's feature end to end:
/// the app authors everything here, and the admin panel only moderates (lists
/// posts, surfaces reported ones, deletes) — the mirror of the gallery.
///
/// Because it's a short-lived, single-company event feature rather than a public
/// network, it's kept deliberately simple, but still avoids the "everything on
/// one document" trap:
///
///   * likes and comments are NOT arrays on the post — they live in
///     subcollections (`community/{postId}/likes/{uid}`,
///     `community/{postId}/comments/{commentId}`), so a lively post can't grow
///     toward the 1 MB document limit and concurrent writes can't clobber each
///     other. A like is keyed by the liker's uid, which makes it idempotent —
///     the same double-tap writes the same document — mirroring the composite-id
///     junctions in the access model.
///   * a post carries denormalized [likeCount]/[commentCount] so a feed draws
///     without counting a subcollection per tile; [CommunityRepository] keeps
///     them in step with an `increment()` in the same batch as the like/comment.
///
/// Everything lives under an event and inherits its access —
/// `events/{eventId}/community/...`.
///
/// Mentions: captions and comments can tag other users. A tag is stored inline
/// in the text as `@[Display Name](uid)` rather than as fragile character
/// offsets, and [Mentions] turns it back into name/link spans for rendering.
/// [mentionedUserIds] is the flat list of tagged uids, denormalized off the
/// tokens so a query like "posts that mention me" needs no caption parsing.
///
/// Kept in sync with the admin panel's `types/community.ts` — the two shapes
/// must agree, since the app writes what the panel reads.

/// One media item in a post's carousel. Reuses the gallery's photo/video split
/// and its poster-frame convention ([thumbUrl] set only for videos).
class CommunityMedia {
  final String url;
  final GalleryMediaType type;
  final String? thumbUrl;

  const CommunityMedia({required this.url, required this.type, this.thumbUrl});

  bool get isVideo => type == GalleryMediaType.video;

  /// What to load when drawing this item small: a video's poster frame if one
  /// was stored, otherwise the file itself.
  String get thumb => thumbUrl ?? url;

  factory CommunityMedia.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String? ?? '';
    final thumbUrl = json['thumbUrl'] as String?;
    return CommunityMedia(
      url: url,
      type:
          GalleryMediaType.fromJson(json['type'] as String?) ??
          GalleryMediaType.inferFrom(url),
      thumbUrl: (thumbUrl == null || thumbUrl.isEmpty) ? null : thumbUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'type': type.jsonValue,
    if (thumbUrl != null) 'thumbUrl': thumbUrl,
  };
}

/// A single post in the community feed.
class CommunityPost {
  final String id;

  /// The uid of the author, and their display name/avatar denormalized at post
  /// time. The name is stored because a company admin can't read other users'
  /// `users/{uid}` documents, so a moderator would otherwise have no name to
  /// show; a later rename doesn't rewrite old posts, which is fine for a
  /// short-lived feed.
  final String authorId;
  final String authorName;
  final String? authorImage;

  /// One or more media items, drawn as a carousel in order.
  final List<CommunityMedia> media;

  /// Raw caption, with mentions stored inline as `@[name](uid)` tokens.
  final String caption;

  /// The uids tagged in the caption, denormalized off the tokens for querying.
  final List<String> mentionedUserIds;

  final int likeCount;
  final int commentCount;

  /// Null only between a local write and the server resolving its timestamp.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Whether someone has reported this post. Nothing in the app hides reported
  /// posts — it's a flag for the admin panel to moderate on.
  final bool isReported;

  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorImage,
    required this.media,
    required this.caption,
    required this.mentionedUserIds,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.updatedAt,
    required this.isReported,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final media = (json['media'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CommunityMedia.fromJson)
        .toList();

    return CommunityPost(
      id: json['id'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorImage: json['authorImage'] as String?,
      media: media,
      caption: json['caption'] as String? ?? '',
      mentionedUserIds: (json['mentionedUserIds'] as List<dynamic>? ?? [])
          .cast<String>(),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      isReported: json['isReported'] as bool? ?? false,
    );
  }

  /// The same post with a different like tally.
  ///
  /// The count is denormalized onto the post, so a like made on a card that came
  /// from a paged read has to be reflected locally — refetching the page to move
  /// one number would throw away the feed's paging.
  CommunityPost withLikeCount(int count) => CommunityPost(
    id: id,
    authorId: authorId,
    authorName: authorName,
    authorImage: authorImage,
    media: media,
    caption: caption,
    mentionedUserIds: mentionedUserIds,
    likeCount: count,
    commentCount: commentCount,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isReported: isReported,
  );

  /// The Firestore shape written on create. [createdAt]/[updatedAt], the counts
  /// and the report flag are set by the repository (server timestamps, zeroed
  /// counts, `isReported: false`), so they're deliberately not here.
  Map<String, dynamic> toJson() => {
    'authorId': authorId,
    'authorName': authorName,
    if (authorImage != null) 'authorImage': authorImage,
    'media': media.map((m) => m.toJson()).toList(),
    'caption': caption,
    'mentionedUserIds': mentionedUserIds,
  };
}

/// A single comment on a post.
class CommunityComment {
  final String id;

  /// The parent post's id and the owning event's id, denormalized onto every
  /// comment. [eventId] is what lets the panel find all reported comments across
  /// an event's posts in one collection-group query; [postId] links a reported
  /// comment back to its post.
  final String postId;
  final String eventId;

  final String authorId;
  final String authorName;
  final String? authorImage;

  /// Raw comment text, with mentions stored inline as `@[name](uid)` tokens.
  final String content;
  final List<String> mentionedUserIds;

  final DateTime? createdAt;
  final bool isReported;

  const CommunityComment({
    required this.id,
    required this.postId,
    required this.eventId,
    required this.authorId,
    required this.authorName,
    this.authorImage,
    required this.content,
    required this.mentionedUserIds,
    required this.createdAt,
    required this.isReported,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorImage: json['authorImage'] as String?,
      content: json['content'] as String? ?? '',
      mentionedUserIds: (json['mentionedUserIds'] as List<dynamic>? ?? [])
          .cast<String>(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      isReported: json['isReported'] as bool? ?? false,
    );
  }

  /// The Firestore shape written on create. `createdAt` and `isReported` are set
  /// by the repository, so they're not here.
  Map<String, dynamic> toJson() => {
    'postId': postId,
    'eventId': eventId,
    'authorId': authorId,
    'authorName': authorName,
    if (authorImage != null) 'authorImage': authorImage,
    'content': content,
    'mentionedUserIds': mentionedUserIds,
  };
}

/// A like on a post. The document id is always the liker's uid, which is what
/// makes a like idempotent.
class CommunityLike {
  final String userId;
  final DateTime? createdAt;

  const CommunityLike({required this.userId, required this.createdAt});

  factory CommunityLike.fromJson(Map<String, dynamic> json) => CommunityLike(
    userId: json['userId'] as String? ?? '',
    createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
  );
}

/// One resolved span of a caption or comment: either literal [text] or a
/// [mention] of a user.
class MentionSpan {
  /// Literal text; null for a mention span.
  final String? text;

  /// The mentioned user's display name; null for a text span.
  final String? name;

  /// The mentioned user's uid; null for a text span.
  final String? uid;

  const MentionSpan.text(this.text) : name = null, uid = null;
  const MentionSpan.mention(this.name, this.uid) : text = null;

  bool get isMention => uid != null;
}

/// Reads and writes the inline `@[name](uid)` mention format. This is the one
/// place the token format is defined on the app side; it must match the admin
/// panel's `types/community.ts`. Names are assumed not to contain `]` — [build]
/// strips it — which keeps the pattern a simple non-greedy match.
class Mentions {
  const Mentions._();

  static final RegExp _pattern = RegExp(r'@\[([^\]]+)\]\(([^)]+)\)');

  /// Build the inline token for one mention.
  static String build(String name, String uid) =>
      '@[${name.replaceAll(']', '')}]($uid)';

  /// Split [text] into literal and mention spans for rendering.
  static List<MentionSpan> render(String text) {
    final spans = <MentionSpan>[];
    var last = 0;
    for (final match in _pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(MentionSpan.text(text.substring(last, match.start)));
      }
      spans.add(MentionSpan.mention(match.group(1)!, match.group(2)!));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(MentionSpan.text(text.substring(last)));
    }
    return spans;
  }

  /// The uids mentioned in [text], de-duplicated, in first-seen order.
  static List<String> ids(String text) {
    final ids = <String>[];
    for (final match in _pattern.allMatches(text)) {
      final uid = match.group(2)!;
      if (!ids.contains(uid)) ids.add(uid);
    }
    return ids;
  }

  /// [text] with mention tokens flattened to `@name`, for plain previews.
  static String plain(String text) =>
      text.replaceAllMapped(_pattern, (m) => '@${m.group(1)}');
}
