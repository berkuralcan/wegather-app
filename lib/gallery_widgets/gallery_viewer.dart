import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../image_widgets/wg_zoomable_image.dart';
import '../l10n/app_localizations.dart';
import '../models/gallery_media.dart';
import '../providers/access_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/gallery_providers.dart';
import '../reusableWidgets/liquid_snackbar.dart';
import '../services/gallery_service.dart';
import 'report_media_sheet.dart';
import 'wg_media_action_button.dart';
import 'wg_video_player.dart';

/// The event gallery's full-screen viewer: one photo or video at a time, with
/// the day it was uploaded and the actions for it floating over the top of it.
///
/// Swipe left and right to move through the set, pinch or double-tap to zoom a
/// photo, tap a video to play or pause it. The three actions are back (out of
/// the viewer), share (the platform's own share sheet, over the media file
/// itself) and report (which flags the media for the admin panel to moderate).
///
/// This is the tips gallery's viewer with a different chrome: the zooming, the
/// decode sizes and the neighbour precaching are the shared [WgZoomableImage],
/// so a photo behaves identically in both.
class GalleryViewer extends ConsumerStatefulWidget {
  const GalleryViewer({super.key, required this.media, this.initialIndex = 0});

  /// The set to page through — normally one filter's worth of the gallery, in
  /// the order the grid shows it.
  final List<GalleryMedia> media;

  final int initialIndex;

  @override
  ConsumerState<GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends ConsumerState<GalleryViewer> {
  late final PageController _pageController;

  late int _index;

  /// True while the current photo is zoomed in. Paging is suspended then, so a
  /// horizontal drag pans the zoomed photo instead of flipping to the next one.
  bool _zoomed = false;

  /// True while the file behind the share button is being fetched.
  bool _sharing = false;

  /// The ids reported in this session, so the button can show it stuck without
  /// waiting for the gallery to be refetched.
  final Set<String> _reported = {};

  static const double _horizontalPadding = 16;

  /// The header's glyphs. Back is the app bar's own arrow, so leaving the
  /// viewer looks the same as leaving any other screen.
  static const String _backIcon = 'assets/icons/back.svg';
  static const String _shareIcon = 'assets/icons/share.svg';
  static const String _reportIcon = 'assets/icons/report.svg';

  GalleryMedia get _current => widget.media[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.media.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheNeighbours();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _index = index;
      // A new page always starts unzoomed, so paging must be re-enabled even if
      // the previous one was left zoomed in.
      _zoomed = false;
    });
    _precacheNeighbours();
  }

  /// Warms the photos on either side so a swipe lands on a drawn photo instead
  /// of a spinner. Only the immediate neighbours, and only photos — a video
  /// starts streaming when its page is built, and pulling one down early would
  /// spend a lot of bandwidth on something most users swipe past.
  void _precacheNeighbours() {
    for (final offset in const [-1, 1]) {
      final neighbour = _index + offset;
      if (neighbour < 0 || neighbour >= widget.media.length) continue;
      final media = widget.media[neighbour];
      if (media.isVideo) continue;
      precacheImage(CachedNetworkImageProvider(media.mediaUrl), context);
    }
  }

  /// Hands the media file to the platform's share sheet.
  ///
  /// The file is downloaded first (from the cache when it is already there, as
  /// it is for anything already drawn on screen) so what gets shared is the
  /// photo or video itself rather than a Firebase URL that only signed-in app
  /// users could open.
  Future<void> _share() async {
    if (_sharing) return;
    final l10n = AppLocalizations.of(context)!;
    final media = _current;

    setState(() => _sharing = true);
    try {
      final file = await DefaultCacheManager().getSingleFile(media.mediaUrl);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          // iPads and Macs anchor the sheet to whatever it was opened from.
          sharePositionOrigin: _shareOrigin(),
        ),
      );
    } catch (error) {
      if (mounted) {
        showLiquidSnackBar(
          context,
          '${l10n.gallery_shareError}\n$error',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// Where the share sheet should point on the platforms that care.
  Rect? _shareOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Asks for confirmation, then flags the media for moderation.
  Future<void> _report() async {
    final l10n = AppLocalizations.of(context)!;
    final media = _current;
    final eventId = ref.read(selectedEventIdProvider);
    final userId = ref.read(currentUserProvider)?.uid;

    final reason = await showReportMediaSheet(context);
    if (reason == null || !mounted) return;

    if (eventId == null || userId == null) {
      showLiquidSnackBar(
        context,
        l10n.gallery_reportError,
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    try {
      await ref
          .read(galleryServiceProvider)
          .report(
            eventId: eventId,
            mediaId: media.id,
            userId: userId,
            reason: reason,
          );
      // The flag is part of what the grid was built from, so the gallery is
      // refetched behind the viewer.
      ref.invalidate(galleryProvider);
      if (!mounted) return;
      setState(() => _reported.add(media.id));
      showLiquidSnackBar(
        context,
        l10n.gallery_reportSuccess,
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
    } catch (error) {
      if (mounted) {
        showLiquidSnackBar(
          context,
          '${l10n.gallery_reportError}\n$error',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Transparent, so the global background gradient from main.dart shows
    // through around a photo that doesn't fill the screen.
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              physics: _zoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemCount: widget.media.length,
              itemBuilder: (context, index) => _MediaPage(
                media: widget.media[index],
                isActive: index == _index,
                onZoomChanged: (zoomed) {
                  if (index != _index || zoomed == _zoomed) return;
                  setState(() => _zoomed = zoomed);
                },
              ),
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildHeader(context)),
        ],
      ),
    );
  }

  /// The bar of actions over the media: back on the left, share and report on
  /// the right, and the day the media was uploaded centred between them.
  ///
  /// A [Stack] rather than a row of three: the title is centred on the screen,
  /// not on the space left over between two groups of buttons of different
  /// widths, so it stays put as the buttons come and go.
  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uploadedAt = _current.uploadedAt;
    final isReported = _current.isReported || _reported.contains(_current.id);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _horizontalPadding,
          vertical: 8,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (uploadedAt != null)
              Text(
                formatGalleryDay(uploadedAt),
                style: AppTextStyles.weGatherHeaderTextStyle,
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                WgMediaActionButton(
                  iconPath: _backIcon,
                  semanticLabel: l10n.gallery_back,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Row(
                  children: [
                    WgMediaActionButton(
                      iconPath: _shareIcon,
                      semanticLabel: l10n.gallery_share,
                      onPressed: _sharing ? null : _share,
                      child: _sharing
                          ? const SizedBox(
                              width: WgMediaActionButton.iconSize,
                              height: WgMediaActionButton.iconSize,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppConfig.lightIconColor,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: WgMediaActionButton.gap),
                    WgMediaActionButton(
                      iconPath: _reportIcon,
                      semanticLabel: l10n.gallery_report,
                      // Reporting the same media twice adds nothing, so the
                      // button goes inert once it has been used.
                      onPressed: isReported ? null : _report,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One page of the viewer: a zoomable photo, or a video with its own controls.
class _MediaPage extends StatelessWidget {
  const _MediaPage({
    required this.media,
    required this.isActive,
    required this.onZoomChanged,
  });

  final GalleryMedia media;
  final bool isActive;
  final ValueChanged<bool> onZoomChanged;

  @override
  Widget build(BuildContext context) {
    if (media.isVideo) {
      return WgVideoPlayer(
        url: media.mediaUrl,
        posterUrl: media.thumbUrl,
        isActive: isActive,
      );
    }
    return WgZoomableImage(
      imageUrl: media.mediaUrl,
      isActive: isActive,
      onZoomChanged: onZoomChanged,
    );
  }
}
