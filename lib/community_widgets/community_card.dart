import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../models/community_model.dart';
import '../providers/access_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';
import 'community_author_row.dart';
import 'community_media_carousel.dart';
import 'mention_text.dart';
import 'post_more_button.dart';

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
  /// landing screen's strip sets it so every card in the row is the same size,
  /// and a post with no caption still holds the capped space. Null (the feed)
  /// shows the caption whole.
  final int? captionMaxLines;

  /// The corner radius of the media. Public so a post drawn outside the feed —
  /// the post's own screen — rounds its media the same way.
  static const double mediaRadius = 16;

  @override
  ConsumerState<CommunityCard> createState() => _CommunityCardState();
}

class _CommunityCardState extends ConsumerState<CommunityCard>
    with SingleTickerProviderStateMixin {
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
          // A capped caption holds its slot even when the post has none, so a
          // card without a caption doesn't ride up out of line with the rest of
          // the strip. Uncapped (the feed), an absent caption takes no space.
          if (post.caption.trim().isNotEmpty || widget.captionMaxLines != null)
            MentionText(
              text: post.caption,
              style: AppTextStyles.weGatherParagraphTextStyle,
              maxLines: widget.captionMaxLines,
            ),
          const SizedBox(height: 12),
          if (post.media.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(CommunityCard.mediaRadius),
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
              trailing: PostMoreButton(post: post),
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

/// The bar under a post: the like and comment tallies on one side, whatever the
/// caller puts at the other end — the feed card's [PostMoreButton], or nothing
/// at all where the post's options are reachable elsewhere.
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
    this.trailing,
  });

  final int likeCount;
  final int commentCount;

  /// Whether the signed-in user likes this post — fills the heart.
  final bool isLiked;

  /// Toggles the like. Null leaves the heart as a tally.
  final VoidCallback? onLike;

  /// Sits at the far end of the bar. Null leaves the tallies on their own.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
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
        if (trailing != null) ...[const Spacer(), trailing!],
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
