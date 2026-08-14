import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/community_model.dart';
import '../services/community_service.dart';
import 'access_providers.dart';
import 'auth_providers.dart';

final communityServiceProvider = Provider<CommunityService>(
  (ref) => CommunityService(),
);

/// The state of the community feed as the screen reads it: the posts loaded so
/// far, whether the first page or a further page is in flight, whether there's
/// more to load, and any error.
@immutable
class CommunityFeedState {
  final List<CommunityPost> posts;

  /// The first page is loading — the screen shows a full-screen spinner.
  final bool isLoadingInitial;

  /// A further page is loading — the screen shows a spinner at the list's foot.
  final bool isLoadingMore;

  /// Whether another page exists. False once a short page comes back.
  final bool hasMore;

  /// Set when the *first* page failed; page-more failures are swallowed so a
  /// hiccup deep in the feed doesn't blank what's already on screen.
  final Object? error;

  const CommunityFeedState({
    this.posts = const [],
    this.isLoadingInitial = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  bool get isEmpty => posts.isEmpty && !isLoadingInitial && error == null;

  CommunityFeedState copyWith({
    List<CommunityPost>? posts,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
  }) {
    return CommunityFeedState(
      posts: posts ?? this.posts,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Drives the paged community feed for the selected event.
///
/// Rebuilds (and reloads from the top) whenever the selected event changes.
/// `autoDispose`, like the gallery: `/community` is pushed on the root
/// navigator, so leaving the screen drops the feed and re-entering fetches a
/// fresh first page — which matters here because other attendees are posting
/// while the app is open.
class CommunityFeedController extends AutoDisposeNotifier<CommunityFeedState> {
  /// The raw snapshot of the last post loaded — the cursor the next page
  /// resumes from. Held here rather than in the state because it's plumbing the
  /// UI never reads.
  DocumentSnapshot<Map<String, dynamic>>? _cursor;

  @override
  CommunityFeedState build() {
    final eventId = ref.watch(selectedEventIdProvider);
    _cursor = null;
    // The first page can't be awaited from a synchronous build, so it's kicked
    // off here; the state starts in its loading form and this fills it in.
    Future.microtask(() => _loadInitial(eventId));
    return const CommunityFeedState();
  }

  Future<void> _loadInitial(String? eventId) async {
    if (eventId == null) {
      state = const CommunityFeedState(isLoadingInitial: false, hasMore: false);
      return;
    }
    try {
      final page = await ref
          .read(communityServiceProvider)
          .getFeedPage(eventId: eventId);
      _cursor = page.cursor;
      state = CommunityFeedState(
        posts: page.posts,
        isLoadingInitial: false,
        hasMore: page.hasMore,
      );
    } catch (error) {
      state = CommunityFeedState(
        isLoadingInitial: false,
        hasMore: false,
        error: error,
      );
    }
  }

  /// Load the next page. Called as the list nears its end; a no-op while a page
  /// is already loading, when the feed is exhausted, or before the first page
  /// has landed, so overscrolling can't fire a stack of duplicate fetches.
  Future<void> loadMore() async {
    final current = state;
    if (current.isLoadingInitial || current.isLoadingMore || !current.hasMore) {
      return;
    }
    final eventId = ref.read(selectedEventIdProvider);
    if (eventId == null) return;

    state = current.copyWith(isLoadingMore: true);
    try {
      final page = await ref
          .read(communityServiceProvider)
          .getFeedPage(eventId: eventId, startAfter: _cursor);
      _cursor = page.cursor ?? _cursor;
      state = state.copyWith(
        posts: [...state.posts, ...page.posts],
        isLoadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (_) {
      // Keep what's on screen; just stop the foot spinner so a later scroll
      // can retry the same page.
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Reload from the top — for pull-to-refresh.
  Future<void> refresh() async {
    _cursor = null;
    state = const CommunityFeedState();
    await _loadInitial(ref.read(selectedEventIdProvider));
  }

  /// Move a loaded post's like tally after the signed-in user liked or unliked
  /// it from its card.
  ///
  /// Whether the heart is filled comes from [communityPostLikedProvider], which
  /// is live; the count next to it does not, so it's nudged here. [liked] is the
  /// state the toggle actually landed on, so a tap that failed never moves it.
  void applyLike(String postId, {required bool liked}) {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;
    final post = state.posts[index];
    final posts = [...state.posts];
    // Clamped because the stored count is the server's: an unlike of a post
    // whose count is already 0 (stale read) must not show -1.
    final count = (post.likeCount + (liked ? 1 : -1)).clamp(0, 1 << 30);
    posts[index] = post.withLikeCount(count);
    state = state.copyWith(posts: posts);
  }

  /// Swap a loaded post for a newer copy of itself, leaving the rest of the feed
  /// and its paging alone.
  ///
  /// The post's own screen streams the post it is showing, so a like or a comment
  /// made there arrives here as an updated [CommunityPost] — this is what stops
  /// the card underneath from still reading "0 comments" when the user comes
  /// back. A post that isn't loaded is ignored rather than inserted, since where
  /// it belongs in the paged feed is not for this to decide.
  void replacePost(CommunityPost post) {
    final index = state.posts.indexWhere((p) => p.id == post.id);
    if (index < 0) return;
    final posts = [...state.posts];
    posts[index] = post;
    state = state.copyWith(posts: posts);
  }
}

final communityFeedProvider =
    AutoDisposeNotifierProvider<CommunityFeedController, CommunityFeedState>(
      CommunityFeedController.new,
    );

/// The newest handful of posts for the landing screen's strip, empty while no
/// event is selected.
///
/// Deliberately separate from [communityFeedProvider]: the landing tab lives in
/// the shell's indexed stack and so is never disposed, and holding a listener on
/// the paged feed from there would stop `/community` refetching its first page
/// each time it is opened. This is one small read instead.
final latestCommunityPostsProvider =
    FutureProvider.autoDispose<List<CommunityPost>>((ref) async {
      final eventId = ref.watch(selectedEventIdProvider);
      if (eventId == null) return const [];
      return ref
          .watch(communityServiceProvider)
          .getLatestPosts(eventId: eventId);
    });

/// One post, live, for its own screen — null once it no longer exists.
final communityPostProvider = StreamProvider.autoDispose
    .family<CommunityPost?, String>((ref, postId) {
      final eventId = ref.watch(selectedEventIdProvider);
      if (eventId == null) return Stream.value(null);
      return ref.watch(communityServiceProvider).watchPost(eventId, postId);
    });

/// A post's comments, oldest first — the order a thread reads in.
final communityCommentsProvider = StreamProvider.autoDispose
    .family<List<CommunityComment>, String>((ref, postId) {
      final eventId = ref.watch(selectedEventIdProvider);
      if (eventId == null) return Stream.value(const []);
      return ref.watch(communityServiceProvider).watchComments(eventId, postId);
    });

/// Whether the signed-in user likes a post. False while signed out, which the
/// router doesn't allow to be seen.
final communityPostLikedProvider = StreamProvider.autoDispose
    .family<bool, String>((ref, postId) {
      final eventId = ref.watch(selectedEventIdProvider);
      final uid = ref.watch(currentUserProvider)?.uid;
      if (eventId == null || uid == null) return Stream.value(false);
      return ref
          .watch(communityServiceProvider)
          .watchHasLiked(eventId, postId, uid);
    });
