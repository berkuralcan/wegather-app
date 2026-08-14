import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../models/community_model.dart';
import '../providers/access_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';
import '../reusableWidgets/liquid_snackbar.dart';
import 'community_author_row.dart';
import 'community_media_carousel.dart';
import 'mention_text.dart';
import 'post_options_sheet.dart';
import 'report_post_sheet.dart';

/// One post in the feed: an author header, the caption (with @mentions picked
/// out), the media, then the like and comment tallies.
///
/// The card is a summary, not the post itself: [onTap] anywhere on it — including
/// the media — opens the post on its own screen, where it can be commented on.
/// [onAuthorTap] is the one exception, taking the photo and the name through to
/// whoever wrote it instead.
///
/// Liking, though, happens here, the way it does in the apps this feed reads
/// like: a double tap anywhere on the card, or a tap on the heart. The double
/// tap only ever likes — it's a gesture people repeat, so letting the second one
/// take the like back would be a trap — while the heart toggles.
///
/// A post with several media is swipeable in place, so its later media isn't
/// reachable only by opening the post.
class CommunityCard extends ConsumerStatefulWidget {
  const CommunityCard({
    super.key,
    required this.post,
    this.onTap,
    this.onAuthorTap,
    this.captionMaxLines,
  });

  final CommunityPost post;

  /// Opens the post's own screen.
  final VoidCallback? onTap;

  /// Opens the author's profile.
  final VoidCallback? onAuthorTap;

  /// Caps the caption, which is what makes the card's height predictable — the
  /// landing screen's strip sets it so every card in the row is the same size.
  /// Null (the feed) shows the caption whole.
  final int? captionMaxLines;

  @override
  ConsumerState<CommunityCard> createState() => _CommunityCardState();
}

class _CommunityCardState extends ConsumerState<CommunityCard>
    with SingleTickerProviderStateMixin {
  /// The corner radius of the media.
  static const double _mediaRadius = 16;

  /// The heart that swells over the media on a double tap. It acknowledges the
  /// gesture rather than the result, so it plays whether or not the tap changed
  /// anything — a double tap on an already-liked post still answers.
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late final Animation<double> _burstScale = Tween<double>(begin: 0.4, end: 1)
      .animate(
        CurvedAnimation(
          parent: _burst,
          curve: const Interval(0, 0.35, curve: Curves.easeOutBack),
        ),
      );

  late final Animation<double> _burstFade = Tween<double>(begin: 1, end: 0)
      .animate(
        CurvedAnimation(
          parent: _burst,
          curve: const Interval(0.6, 1, curve: Curves.easeOut),
        ),
      );

  /// Guards a second tap landing while the first write is still in flight,
  /// which would toggle the like twice and leave the tally off by one.
  bool _isToggling = false;

  /// Reported from this card in this session. The post's own flag covers a
  /// report someone else made; this covers the one just made here, which the
  /// paged feed's copy of the post doesn't know about.
  bool _reported = false;

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  /// Write the like. [likeOnly] is the double tap's rule: never take one back.
  Future<void> _toggleLike({bool likeOnly = false}) async {
    if (_isToggling) return;

    final postId = widget.post.id;
    final uid = ref.read(currentUserProvider)?.uid;
    final eventId = ref.read(selectedEventIdProvider);
    if (uid == null || eventId == null) return;

    final liked = ref.read(communityPostLikedProvider(postId)).value ?? false;
    if (likeOnly && liked) return;

    _isToggling = true;
    try {
      final nowLiked = await ref
          .read(communityServiceProvider)
          .toggleLike(eventId, postId, uid);
      // The filled heart follows the like stream, which turns over on its own;
      // only the count beside it has to be told.
      ref
          .read(communityFeedProvider.notifier)
          .applyLike(postId, liked: nowLiked);
    } catch (_) {
      // Nothing was written, so nothing on screen has to be put back — leave
      // the heart as the stream reports it rather than interrupting the feed.
    } finally {
      _isToggling = false;
    }
  }

  void _onDoubleTap() {
    _burst.forward(from: 0);
    _toggleLike(likeOnly: true);
  }

  /// The ellipsis: what can be done with the post beyond liking it.
  Future<void> _openOptions() async {
    final option = await showPostOptionsSheet(
      context,
      isReported: widget.post.isReported || _reported,
    );
    if (option == null || !mounted) return;
    switch (option) {
      case PostOption.report:
        await _report();
    }
  }

  /// Asks for confirmation, then flags the post for moderation — the gallery's
  /// report flow, on a post instead of a photo.
  Future<void> _report() async {
    final l10n = AppLocalizations.of(context)!;
    final postId = widget.post.id;
    final eventId = ref.read(selectedEventIdProvider);
    final uid = ref.read(currentUserProvider)?.uid;

    final reason = await showReportPostSheet(context);
    if (reason == null || !mounted) return;

    if (eventId == null || uid == null) {
      showLiquidSnackBar(
        context,
        l10n.community_reportError,
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    try {
      await ref
          .read(communityServiceProvider)
          .reportPost(eventId, postId, reportedBy: uid, reason: reason);
      if (!mounted) return;
      // Nothing in the app hides a reported post, so the feed is left alone;
      // this only stops the same post being reported twice from this card.
      setState(() => _reported = true);
      showLiquidSnackBar(
        context,
        l10n.community_reportSuccess,
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
    } catch (error) {
      if (mounted) {
        showLiquidSnackBar(
          context,
          '${l10n.community_reportError}\n$error',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isLiked =
        ref.watch(communityPostLikedProvider(post.id)).value ?? false;

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: _onDoubleTap,
      behavior: HitTestBehavior.opaque,
      // Nothing is inset horizontally: the media runs the full width of the
      // card, and the header, caption and counts line up with its edges. The
      // card's own margin from the screen is the list's to give.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: CommunityAuthorRow(
              name: post.authorName,
              imageUrl: post.authorImage,
              createdAt: post.createdAt,
              onTap: widget.onAuthorTap,
            ),
          ),
          if (post.caption.trim().isNotEmpty)
            MentionText(
              text: post.caption,
              style: AppTextStyles.weGatherParagraphTextStyle,
              maxLines: widget.captionMaxLines,
            ),
          const SizedBox(height: 12),
          if (post.media.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(_mediaRadius),
              child: Stack(
                children: [
                  CommunityMediaCarousel(media: post.media),
                  Positioned.fill(child: _buildBurst()),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: CommunityCounts(
              likeCount: post.likeCount,
              commentCount: post.commentCount,
              isLiked: isLiked,
              onLike: _toggleLike,
              onMore: _openOptions,
            ),
          ),
        ],
      ),
    );
  }

  /// The double tap's heart, over the media. Ignores pointers, so it can't eat
  /// the swipe of the carousel underneath it.
  Widget _buildBurst() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _burst,
        builder: (context, child) {
          if (_burst.isDismissed) return const SizedBox.shrink();
          return Center(
            child: Opacity(
              opacity: _burstFade.value,
              child: Transform.scale(scale: _burstScale.value, child: child),
            ),
          );
        },
        child: const Icon(
          Icons.favorite,
          size: 96,
          color: Colors.white,
          // The heart lands on whatever photo happens to be under it, so it
          // carries its own contrast.
          shadows: [Shadow(color: Colors.black38, blurRadius: 16)],
        ),
      ),
    );
  }
}

/// The bar under a post: the like and comment tallies on one side, the ellipsis
/// that opens the post's options on the other.
///
/// A liked post gets the solid heart rather than the outline recoloured — at 18
/// points a tint alone reads as an icon in a slightly different colour, while a
/// filled heart reads as a state.
class CommunityCounts extends StatelessWidget {
  const CommunityCounts({
    super.key,
    required this.likeCount,
    required this.commentCount,
    this.isLiked = false,
    this.onLike,
    this.onMore,
  });

  final int likeCount;
  final int commentCount;

  /// Whether the signed-in user likes this post — fills the heart.
  final bool isLiked;

  /// Toggles the like. Null leaves the heart as a tally.
  final VoidCallback? onLike;

  /// Opens the post's options. Null leaves the ellipsis off altogether.
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        _CountItem(
          asset: isLiked
              ? 'assets/icons/heart-filled.svg'
              : 'assets/icons/heart.svg',
          count: likeCount,
          color: isLiked ? AppConfig.emphasisColor : AppConfig.lightIconColor,
          onTap: onLike,
        ),
        const SizedBox(width: 20),
        _CountItem(asset: 'assets/icons/comment.svg', count: commentCount),
        if (onMore != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: onMore,
            // The glyph is three small dots, so the tap target is padded out to
            // something a thumb can find — inwards only, so the dots stay flush
            // with the edge of the media above them.
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 0, 6),
              child: SvgPicture.asset(
                'assets/icons/ellipsis.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  AppConfig.lightIconColor,
                  BlendMode.srcIn,
                ),
                semanticsLabel: l10n.community_more,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CountItem extends StatelessWidget {
  const _CountItem({
    required this.asset,
    required this.count,
    this.color = AppConfig.lightIconColor,
    this.onTap,
  });

  final String asset;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            asset,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(width: 6),
          Text('$count', style: AppTextStyles.weGatherSmallTextStyle),
        ],
      ),
    );
  }
}
