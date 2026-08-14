import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../gallery_widgets/add_media_sheet.dart';
import '../gallery_widgets/gallery_viewer.dart';
import '../gallery_widgets/wg_media_grid.dart';
import '../global_widgets/floating_add_button.dart';
import '../global_widgets/wg_tab_selector.dart';
import '../l10n/app_localizations.dart';
import '../layouts/wegather_appbar.dart';
import '../models/gallery_media.dart';
import '../providers/access_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/gallery_providers.dart';
import '../reusableWidgets/liquid_snackbar.dart';
import '../services/gallery_service.dart';

/// The event's gallery: everything attendees have contributed, split into
/// photos and videos by a pill selector and grouped into a section per day.
///
/// This is the one screen in the app that writes as well as reads. The add
/// button hands a picked file to [GalleryService], which puts it in Storage
/// under the event's `userUploads` prefix and records it in Firestore; the
/// viewer behind a tile can report a piece of media for moderation.
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  /// Horizontal inset of the content, matching the app bar back arrow's glyph —
  /// the same inset the tips gallery uses.
  static const double _horizontalInset = 16;

  /// Enough room under the last row for the add button to float clear of it.
  static const double _bottomInset = 96;

  GalleryMediaType _filter = GalleryMediaType.photo;

  bool _uploading = false;

  /// Adds a photo or video to the gallery: asks where it should come from,
  /// opens that picker, and uploads what comes back.
  ///
  /// The app's own sheet goes first rather than opening a picker straight away.
  /// Partly so the camera is an option at all, and partly because the picker is
  /// a full-screen activity belonging to the OS — on Android it may well be the
  /// file browser rather than a photo grid — and this is the last point at
  /// which changing your mind costs nothing.
  Future<void> _addMedia() async {
    if (_uploading) return;
    final l10n = AppLocalizations.of(context)!;

    final event = ref.read(selectedEventProvider).valueOrNull;
    final userId = ref.read(currentUserProvider)?.uid;
    if (event == null || userId == null) {
      showLiquidSnackBar(
        context,
        l10n.gallery_uploadError,
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    final source = await showAddMediaSheet(context);
    if (source == null || !mounted) return;

    final XFile? file;
    try {
      file = await _pick(source);
    } catch (error) {
      if (mounted) _showUploadError(error);
      return;
    }
    // Null when the picker was backed out of, which is not an error.
    if (file == null || !mounted) return;

    final type = switch (source) {
      AddMediaSource.photo => GalleryMediaType.photo,
      AddMediaSource.video => GalleryMediaType.video,
      // Only a library pick is ambiguous: `mimeType` is what the platform
      // reports about the file, and when it reports nothing (iOS often doesn't)
      // the extension answers the same question.
      AddMediaSource.library =>
        (file.mimeType?.startsWith('video/') ?? false)
            ? GalleryMediaType.video
            : GalleryMediaType.inferFrom(file.path),
    };

    setState(() => _uploading = true);
    showLiquidSnackBar(
      context,
      l10n.gallery_uploading,
      icon: Icons.cloud_upload,
      iconColor: AppConfig.emphasisColor,
    );

    try {
      await ref
          .read(galleryServiceProvider)
          .upload(
            companyId: event.companyId,
            eventId: event.id,
            userId: userId,
            file: file,
            type: type,
          );
      ref.invalidate(galleryProvider);
      if (!mounted) return;
      setState(() {
        _uploading = false;
        // Show the tab the new media landed in, so it is never uploaded into a
        // filter the user isn't looking at.
        _filter = type;
      });
      showLiquidSnackBar(
        context,
        l10n.gallery_uploadSuccess,
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _showUploadError(error);
    }
  }

  /// Opens the picker [source] asks for, and resolves to what came back — or
  /// null if the user left without picking anything.
  ///
  /// A library pick offers photos and videos together, so the user isn't asked
  /// to declare which they are after when they can see both.
  Future<XFile?> _pick(AddMediaSource source) {
    final picker = ImagePicker();
    return switch (source) {
      AddMediaSource.photo => picker.pickImage(source: ImageSource.camera),
      AddMediaSource.video => picker.pickVideo(source: ImageSource.camera),
      AddMediaSource.library => picker.pickMedia(),
    };
  }

  void _showUploadError(Object error) {
    showLiquidSnackBar(
      context,
      '${AppLocalizations.of(context)!.gallery_uploadError}\n$error',
      icon: Icons.error,
      iconColor: Colors.red,
    );
  }

  /// Opens the viewer on [media], which is the whole filtered set so a swipe
  /// carries on across day boundaries.
  void _openViewer(List<GalleryMedia> media, int index) {
    // Pushed on the root navigator so the viewer covers the bottom nav bar.
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => GalleryViewer(media: media, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gallery = ref.watch(galleryProvider);
    final service = ref.watch(galleryServiceProvider);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.gallery_title),
      floatingActionButton: FloatingAddButton(
        label: l10n.gallery_add,
        onPressed: _addMedia,
        isBusy: _uploading,
      ),
      // Centred like the community feed's pill, rather than the corner a
      // circular FAB would sit in.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _horizontalInset),
              child: WgTabSelector(
                labels: [l10n.gallery_tabPhotos, l10n.gallery_tabVideos],
                selectedIndex: _filter.index,
                onSelected: (index) =>
                    setState(() => _filter = GalleryMediaType.values[index]),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: gallery.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    _CenteredText('${l10n.gallery_loadError}\n\n$error'),
                data: (media) {
                  final filtered = service.ofType(media, _filter);
                  if (filtered.isEmpty) {
                    return _CenteredText(
                      _filter == GalleryMediaType.video
                          ? l10n.gallery_emptyVideos
                          : l10n.gallery_emptyPhotos,
                    );
                  }
                  return _DaySections(
                    sections: service.groupByDay(filtered),
                    onTapMedia: (index) => _openViewer(filtered, index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The gallery itself: a date heading per day, with that day's grid under it.
///
/// The outer list is lazy, so a gallery with a hundred days in it only builds
/// the few sections on screen; each day's grid is small enough to lay out in
/// one go, which is what lets the page scroll as a single column.
class _DaySections extends StatelessWidget {
  const _DaySections({required this.sections, required this.onTapMedia});

  final List<GalleryDaySection> sections;

  /// Called with the index of the tapped media *within the filtered set*, not
  /// within its day — that is what the viewer pages through.
  final ValueChanged<int> onTapMedia;

  @override
  Widget build(BuildContext context) {
    // Where each day starts in the flat filtered list, so a tile can report its
    // position in the set the viewer is given.
    final offsets = <int>[];
    var running = 0;
    for (final section in sections) {
      offsets.add(running);
      running += section.media.length;
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: _GalleryScreenState._bottomInset),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _GalleryScreenState._horizontalInset,
                vertical: 16,
              ),
              child: Text(
                formatGalleryDay(section.day),
                style: AppTextStyles.weGatherHeaderTextStyle,
              ),
            ),
            WgMediaGrid(
              media: section.media,
              padding: const EdgeInsets.symmetric(
                horizontal: _GalleryScreenState._horizontalInset,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onTap: (localIndex) => onTapMedia(offsets[index] + localIndex),
            ),
          ],
        );
      },
    );
  }
}

class _CenteredText extends StatelessWidget {
  const _CenteredText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.weGatherParagraphTextStyle,
        ),
      ),
    );
  }
}
