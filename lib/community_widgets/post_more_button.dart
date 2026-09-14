import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../models/community_model.dart';
import '../providers/access_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';
import '../reusableWidgets/liquid_snackbar.dart';
import 'post_options_sheet.dart';
import 'report_post_sheet.dart';

/// The ellipsis beside a post, and everything behind it: the options sheet, the
/// reason sheet, and the write that flags the post for moderation.
///
/// It carries its own flow rather than handing a callback back to whoever drew
/// it, because every place a post appears wants the same one — the card in the
/// feed, and the post on its own screen. Where it sits is the caller's to say
/// through [padding]; what it does is not.
class PostMoreButton extends ConsumerStatefulWidget {
  const PostMoreButton({
    super.key,
    required this.post,
    this.padding = const EdgeInsets.fromLTRB(12, 6, 0, 6),
  });

  final CommunityPost post;

  /// Pads the glyph out to something a thumb can find. The default is the
  /// feed card's: inwards only, so the dots stay flush with the edge of the
  /// media above them.
  final EdgeInsets padding;

  static const double _size = 18;

  @override
  ConsumerState<PostMoreButton> createState() => _PostMoreButtonState();
}

class _PostMoreButtonState extends ConsumerState<PostMoreButton> {
  /// Reported from this button in this session. The post's own flag covers a
  /// report someone else made; this covers the one just made here, which the
  /// paged feed's copy of the post doesn't know about.
  bool _reported = false;

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
      // this only stops the same post being reported twice from this button.
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
    return GestureDetector(
      onTap: _openOptions,
      // Opaque so a tap on the dots is the button's, not the tappable card's
      // underneath it.
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: widget.padding,
        child: SvgPicture.asset(
          'assets/icons/ellipsis.svg',
          width: PostMoreButton._size,
          height: PostMoreButton._size,
          colorFilter: const ColorFilter.mode(
            AppConfig.secondaryIconColor,
            BlendMode.srcIn,
          ),
          semanticsLabel: AppLocalizations.of(context)!.community_more,
        ),
      ),
    );
  }
}
