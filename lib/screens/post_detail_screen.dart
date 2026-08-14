import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../community_widgets/community_author_row.dart';
import '../community_widgets/community_card.dart';
import '../community_widgets/community_media_carousel.dart';
import '../community_widgets/mention_text.dart';
import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../layouts/wegather_appbar.dart';
import '../models/community_model.dart';
import '../providers/access_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';
import '../providers/profile_providers.dart';
import '../reusableWidgets/liquid_snackbar.dart';
import '../services/community_service.dart';

/// One post on its own: the post as the feed draws it, everything said about it
/// underneath, and a field to say something yourself.
///
/// The post is streamed rather than taken as given, so its like and comment
/// tallies are right while you are looking at them — and so a post the panel has
/// deleted says so instead of sitting there. [initialPost] is the copy the feed
/// already had, drawn until the stream's first value lands, which is what stops
/// the screen opening on a spinner over something the user could already see.
///
/// Videos play here, one page at a time, which they don't do in the feed.
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId, this.initialPost});

  final String postId;

  final CommunityPost? initialPost;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  static const double _inset = 12;

  /// Indent of a comment's text, so it lines up under the author's name rather
  /// than under their photo.
  static const double _commentIndent = 28;

  final TextEditingController _comment = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _sending = false;
  bool _liking = false;

  /// A comment of ours is in flight or has just landed, so the next comment to
  /// arrive should be scrolled to. Only ours: being yanked to the bottom because
  /// somebody else commented is the opposite of helpful.
  bool _followNextComment = false;

  @override
  void dispose() {
    _comment.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Bring the feed's copy of this post up to date, so the card behind this
  /// screen doesn't still read "0 comments" when the user goes back.
  ///
  /// Only if the feed is already there to update: opened from a notification or
  /// a link there is no feed underneath, and building one just to write a post
  /// into it would fetch a page of posts nobody has asked for.
  void _syncFeed(CommunityPost post) {
    final container = ProviderScope.containerOf(context, listen: false);
    if (!container.exists(communityFeedProvider)) return;
    container.read(communityFeedProvider.notifier).replacePost(post);
  }

  void _openProfile(String userId) {
    if (userId.isEmpty) return;
    context.pushNamed('profile', pathParameters: {'profileId': userId});
  }

  Future<void> _toggleLike(CommunityPost post) async {
    if (_liking) return;
    final eventId = ref.read(selectedEventIdProvider);
    final uid = ref.read(currentUserProvider)?.uid;
    if (eventId == null || uid == null) return;

    setState(() => _liking = true);
    try {
      await ref
          .read(communityServiceProvider)
          .toggleLike(eventId, post.id, uid);
    } catch (_) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.community_likeError);
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  Future<void> _sendComment() async {
    if (_sending) return;
    final content = _comment.text.trim();
    if (content.isEmpty) return;

    final eventId = ref.read(selectedEventIdProvider);
    final user = ref.read(currentUserProvider);
    if (eventId == null || user == null) {
      _showError(AppLocalizations.of(context)!.community_commentError);
      return;
    }

    setState(() => _sending = true);
    try {
      // The author's name and photo are stored on the comment, as they are on a
      // post, so a thread draws without a lookup per line.
      final profile = await ref.read(currentProfileProvider.future);
      final image = profile?.profileImage;

      _followNextComment = true;
      await ref
          .read(communityServiceProvider)
          .addComment(
            eventId: eventId,
            postId: widget.postId,
            authorId: user.uid,
            authorName: profile?.name ?? user.displayName ?? '',
            authorImage: (image == null || image.isEmpty) ? null : image,
            content: content,
          );
      if (!mounted) return;
      // The thread updates itself from its stream; this only clears the field,
      // leaving the keyboard up for whatever they say next.
      _comment.clear();
      setState(() => _sending = false);
    } catch (_) {
      if (!mounted) return;
      _followNextComment = false;
      setState(() => _sending = false);
      _showError(AppLocalizations.of(context)!.community_commentError);
    }
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _showError(String message) {
    showLiquidSnackBar(
      context,
      message,
      icon: Icons.error,
      iconColor: Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // A post read here is a newer copy than the feed's, counts and all.
    ref.listen(communityPostProvider(widget.postId), (_, next) {
      final post = next.valueOrNull;
      if (post != null) _syncFeed(post);
    });

    ref.listen(communityCommentsProvider(widget.postId), (previous, next) {
      final before = previous?.valueOrNull?.length ?? 0;
      final after = next.valueOrNull?.length ?? 0;
      if (after > before && _followNextComment) {
        _followNextComment = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      }
    });

    final postState = ref.watch(communityPostProvider(widget.postId));
    // `hasValue` rather than a null check: the stream's own value is nullable, so
    // null once it has landed means the post is gone, while null before that just
    // means it hasn't arrived — and only the first should replace the post.
    final post = postState.hasValue ? postState.value : widget.initialPost;

    return Scaffold(
      appBar: CustomAppBar(title: l10n.community_postTitle),
      body: SafeArea(
        top: false,
        child: post == null
            ? _buildAbsent(l10n, postState)
            : Column(
                children: [
                  Expanded(child: _buildBody(l10n, post)),
                  _Composer(
                    controller: _comment,
                    isSending: _sending,
                    onSend: _sendComment,
                  ),
                ],
              ),
      ),
    );
  }

  /// What stands in for a post there is nothing to show for: still arriving, or
  /// gone from Firestore, or unreadable.
  Widget _buildAbsent(AppLocalizations l10n, AsyncValue<CommunityPost?> state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _CenteredText(
      state.hasError ? l10n.community_loadError : l10n.community_postMissing,
    );
  }

  Widget _buildBody(AppLocalizations l10n, CommunityPost post) {
    final isLiked =
        ref.watch(communityPostLikedProvider(post.id)).valueOrNull ?? false;
    final comments = ref.watch(communityCommentsProvider(widget.postId));

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(_inset),
                child: CommunityAuthorRow(
                  name: post.authorName,
                  imageUrl: post.authorImage,
                  createdAt: post.createdAt,
                  onTap: () => _openProfile(post.authorId),
                ),
              ),
              if (post.media.isNotEmpty)
                CommunityMediaCarousel(media: post.media, playVideos: true),
              if (post.caption.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(_inset, _inset, _inset, 0),
                  child: MentionText(text: post.caption),
                ),
              Padding(
                padding: const EdgeInsets.all(_inset),
                child: CommunityCounts(
                  likeCount: post.likeCount,
                  commentCount: post.commentCount,
                  isLiked: isLiked,
                  onLike: () => _toggleLike(post),
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppConfig.dividerNonOpaqueColor,
              ),
              Padding(
                padding: const EdgeInsets.all(_inset),
                child: Text(
                  l10n.community_comments,
                  style: AppTextStyles.weGatherHeading3TextStyle,
                ),
              ),
            ],
          ),
        ),
        ...switch (comments) {
          AsyncError() => [
            SliverToBoxAdapter(
              child: _CenteredText(l10n.community_commentsLoadError),
            ),
          ],
          AsyncData(:final value) when value.isEmpty => [
            SliverToBoxAdapter(
              child: _CenteredText(l10n.community_commentsEmpty),
            ),
          ],
          AsyncData(:final value) => [
            SliverList.builder(
              itemCount: value.length,
              itemBuilder: (context, index) {
                final comment = value[index];
                return _Comment(
                  comment: comment,
                  onAuthorTap: () => _openProfile(comment.authorId),
                );
              },
            ),
          ],
          _ => [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        },
        // Room under the last comment, so it clears the field below it.
        const SliverToBoxAdapter(child: SizedBox(height: _inset)),
      ],
    );
  }
}

/// One comment: who said it and when, with what they said under their name.
class _Comment extends StatelessWidget {
  const _Comment({required this.comment, required this.onAuthorTap});

  final CommunityComment comment;
  final VoidCallback onAuthorTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _PostDetailScreenState._inset,
        6,
        _PostDetailScreenState._inset,
        6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommunityAuthorRow(
            name: comment.authorName,
            imageUrl: comment.authorImage,
            createdAt: comment.createdAt,
            onTap: onAuthorTap,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(
              left: _PostDetailScreenState._commentIndent,
            ),
            child: MentionText(text: comment.content),
          ),
        ],
      ),
    );
  }
}

/// The field a comment is written in, pinned under the thread.
///
/// It rides above the keyboard rather than scrolling with the comments, so
/// replying never means scrolling to the bottom first.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(_PostDetailScreenState._inset),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppConfig.dividerNonOpaqueColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              // Grows with a longer comment, then scrolls inside itself rather
              // than pushing the thread off the screen.
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: controller,
                enabled: !isSending,
                maxLength: CommunityService.commentMaxLength,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.weGatherParagraphTextStyle,
                cursorColor: AppConfig.emphasisColor,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                  hintText: l10n.community_commentHint,
                  hintStyle: AppTextStyles.weGatherParagraphTextStyle.copyWith(
                    color: AppConfig.colorTertiary,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: _PostDetailScreenState._inset),
          _SendButton(isSending: isSending, onPressed: onSend),
        ],
      ),
    );
  }
}

/// The send button: the app's gradient in a circle, with a spinner in place of
/// its glyph while the comment is being written.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.isSending, required this.onPressed});

  final bool isSending;
  final VoidCallback onPressed;

  static const double _size = 36;
  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.community_commentSend,
      child: GestureDetector(
        onTap: isSending ? null : onPressed,
        child: Container(
          width: _size,
          height: _size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: AppConfig.buttonPrimaryGradient,
            shape: BoxShape.circle,
          ),
          child: isSending
              ? const SizedBox(
                  width: _iconSize,
                  height: _iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppConfig.lightIconColor,
                  ),
                )
              : SvgPicture.asset(
                  'assets/icons/send.svg',
                  width: _iconSize,
                  height: _iconSize,
                  colorFilter: const ColorFilter.mode(
                    AppConfig.lightIconColor,
                    BlendMode.srcIn,
                  ),
                ),
        ),
      ),
    );
  }
}

/// A line of explanation where content would otherwise be — an empty thread, or
/// one that couldn't be read.
class _CenteredText extends StatelessWidget {
  const _CenteredText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.weGatherParagraphTextStyle.copyWith(
            color: AppConfig.colorTertiary,
          ),
        ),
      ),
    );
  }
}
