import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../gallery_widgets/add_media_sheet.dart';
import '../gallery_widgets/wg_media_action_button.dart';
import '../global_widgets/floating_add_button.dart';
import '../global_widgets/wg_page_dots.dart';
import '../l10n/app_localizations.dart';
import '../layouts/wegather_appbar.dart';
import '../models/gallery_media.dart';
import '../providers/access_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';
import '../providers/profile_providers.dart';
import '../reusableWidgets/liquid_snackbar.dart';
import '../services/community_service.dart';
import '../services/media_upload_service.dart';

/// The composer: what the community feed's "Create Post" button opens.
///
/// It opens onto an empty media area that is itself the button: tapping it asks
/// where the media should come from — the camera, for a photo or a video, or the
/// device's library. The camera is deliberately not opened on arrival, because
/// the camera it would open is the OS's own full-screen one: we can't put a
/// photo/video toggle or a way through to the library on a screen that isn't
/// ours, so landing there would be a dead end for anyone who wanted either.
///
/// Picking several from the library keeps them in the order they were picked —
/// the OS picker numbers them as they're tapped — and that order is the order the
/// carousel is stored in.
///
/// Nothing is uploaded until Post: the screen holds the picked files locally, so
/// changing your mind costs nothing, and [CommunityService.createPost] then puts
/// them in Storage and writes the post in one go.
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  /// Shorter than the app's usual 96, because the media below wants the height
  /// more than the title does.
  static const double _appBarHeight = 64;

  static const double _horizontalInset = 16;

  /// The gap between the media and the caption, and the caption's own breathing
  /// room at the foot of the screen.
  static const double _gap = 16;

  /// The tallest the caption field grows before it scrolls inside itself, so a
  /// long caption can never squeeze the media off the screen.
  static const double _captionMaxHeight = 140;

  /// How near the character cap the counter starts showing. Below that it is
  /// noise — nobody writing a sentence needs to be told they have 950 characters
  /// left.
  static const int _counterFromRemaining = 100;

  /// The picked files, in the order they'll appear in the carousel.
  final List<XFile> _media = [];

  final TextEditingController _caption = TextEditingController();
  final PageController _pager = PageController();

  int _page = 0;

  /// A picker is open. Guards against a second one being asked for while the
  /// first is still on screen (a double tap, or the entry camera racing a tap).
  bool _picking = false;

  bool _posting = false;

  @override
  void dispose() {
    _caption.dispose();
    _pager.dispose();
    super.dispose();
  }

  /// Asks where the media should come from, then opens that picker.
  Future<void> _chooseSource() async {
    if (_picking || _posting) return;
    final source = await showAddMediaSheet(
      context,
      title: AppLocalizations.of(context)!.community_addMediaTitle,
    );
    if (source == null || !mounted) return;
    await _pickFrom(source);
  }

  /// Opens the picker [source] asks for and adds whatever comes back.
  ///
  /// A library pick offers photos and videos together and takes several at once;
  /// the camera, being the OS's own, hands back one file and has to be told
  /// beforehand which kind it is capturing.
  Future<void> _pickFrom(AddMediaSource source) async {
    if (_picking || _posting) return;
    final room = CommunityService.mediaMaxCount - _media.length;
    if (room <= 0) {
      _warnMediaLimit();
      return;
    }

    _picking = true;
    try {
      final picker = ImagePicker();
      final picked = switch (source) {
        AddMediaSource.photo => [
          await picker.pickImage(source: ImageSource.camera),
        ],
        AddMediaSource.video => [
          await picker.pickVideo(source: ImageSource.camera),
        ],
        // A limit of one isn't a multi-pick as far as the plugin is concerned,
        // so the last free slot is picked into without one and trimmed after.
        AddMediaSource.library => await picker.pickMultipleMedia(
          limit: room >= 2 ? room : null,
        ),
      };

      // An empty result is a picker that was backed out of, which is not an
      // error and leaves the selection as it was.
      final files = picked.whereType<XFile>().toList();
      if (files.isEmpty || !mounted) return;
      _add(files);
    } catch (_) {
      if (mounted) {
        _showMessage(
          AppLocalizations.of(context)!.community_mediaError,
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    } finally {
      _picking = false;
    }
  }

  /// Appends [files] to the selection, up to the post's limit, and moves the
  /// carousel to the first of them.
  void _add(List<XFile> files) {
    final room = CommunityService.mediaMaxCount - _media.length;
    final accepted = files.take(room).toList();
    final firstNew = _media.length;

    setState(() => _media.addAll(accepted));
    if (files.length > accepted.length) _warnMediaLimit();

    // Move to what was just added, so the carousel shows it rather than leaving
    // the user on an earlier page wondering whether the pick took. Deferred a
    // frame: the pager only has the new pages once this rebuild has landed.
    if (firstNew > 0 && accepted.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pager.hasClients) _pager.jumpToPage(firstNew);
      });
    }
  }

  void _warnMediaLimit() {
    _showMessage(
      AppLocalizations.of(
        context,
      )!.community_mediaLimit(CommunityService.mediaMaxCount),
      icon: Icons.info,
      iconColor: AppConfig.emphasisColor,
    );
  }

  /// Uploads the selection and writes the post, then returns to the feed.
  Future<void> _post() async {
    if (_posting) return;
    final l10n = AppLocalizations.of(context)!;

    if (_media.isEmpty) {
      _showMessage(
        l10n.community_mediaRequired,
        icon: Icons.info,
        iconColor: AppConfig.emphasisColor,
      );
      return;
    }

    final event = ref.read(selectedEventProvider).valueOrNull;
    final user = ref.read(currentUserProvider);
    if (event == null || user == null) {
      _showMessage(
        l10n.community_postError,
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    setState(() => _posting = true);
    _showMessage(
      l10n.community_posting,
      icon: Icons.cloud_upload,
      iconColor: AppConfig.emphasisColor,
    );

    try {
      // The author's name and avatar are stored on the post, so they're wanted
      // before the write rather than fetched by every reader afterwards.
      final profile = await ref.read(currentProfileProvider.future);
      final authorImage = profile?.profileImage;

      await ref
          .read(communityServiceProvider)
          .createPost(
            companyId: event.companyId,
            eventId: event.id,
            authorId: user.uid,
            authorName: profile?.name ?? user.displayName ?? '',
            authorImage: (authorImage == null || authorImage.isEmpty)
                ? null
                : authorImage,
            files: _media,
            caption: _caption.text.trim(),
          );

      // The new post is the newest, so a reload from the top puts it at the head
      // of the feed the user lands back on.
      await ref.read(communityFeedProvider.notifier).refresh();
      if (!mounted) return;
      _showMessage(
        l10n.community_postSuccess,
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _posting = false);
      _showMessage(
        '${l10n.community_postError}\n$error',
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }

  void _showMessage(
    String message, {
    required IconData icon,
    required Color iconColor,
  }) {
    showLiquidSnackBar(context, message, icon: icon, iconColor: iconColor);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.community_newPost,
        toolbarHeight: _appBarHeight,
        trailing: FloatingAddButton(
          label: l10n.community_post,
          iconAsset: 'assets/icons/send.svg',
          borderRadius: 8,
          isBusy: _posting,
          onPressed: _post,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // The media takes everything the caption doesn't, so it is full
            // width and nearly full height — and it is what gives way when the
            // keyboard comes up.
            Expanded(
              child: _media.isEmpty
                  ? _EmptyState(onAdd: _chooseSource)
                  : _buildCarousel(l10n),
            ),
            const SizedBox(height: _gap),
            _buildCaptionField(l10n),
            const SizedBox(height: _gap),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(AppLocalizations l10n) {
    return Stack(
      children: [
        Positioned.fill(
          child: PageView.builder(
            controller: _pager,
            itemCount: _media.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) {
              final file = _media[index];
              // Keyed by path so a preview keeps its state (a video keeps its
              // player) as items are added around it.
              return _MediaPreview(key: ValueKey(file.path), file: file);
            },
          ),
        ),
        Positioned(
          top: 8,
          right: _horizontalInset,
          child: WgMediaActionButton(
            iconPath: 'assets/icons/plus.svg',
            onPressed: _posting ? null : _chooseSource,
            semanticLabel: l10n.community_addMedia,
          ),
        ),
        if (_media.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: WgPageDots(count: _media.length, current: _page),
            ),
          ),
      ],
    );
  }

  Widget _buildCaptionField(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalInset),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _captionMaxHeight),
        child: TextField(
          controller: _caption,
          enabled: !_posting,
          maxLength: CommunityService.captionMaxLength,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: AppTextStyles.weGatherParagraphTextStyle,
          cursorColor: AppConfig.emphasisColor,
          // No fill and no border: the caption is written straight onto the
          // app's background, under the media it belongs to.
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: l10n.community_captionHint,
            hintStyle: AppTextStyles.weGatherParagraphTextStyle.copyWith(
              color: AppConfig.colorTertiary,
            ),
          ),
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) {
                if (maxLength == null ||
                    currentLength < maxLength - _counterFromRemaining) {
                  return null;
                }
                return Text(
                  '$currentLength/$maxLength',
                  style: AppTextStyles.weGatherSmallTextStyle,
                );
              },
        ),
      ),
    );
  }
}

/// The media area before anything has been picked: the whole of it is the
/// button, so the first tap anywhere on the empty frame opens the sheet.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  /// Diameter of the circle the plus sits in, and the glyph inside it.
  static const double _affordanceSize = 72;
  static const double _glyphSize = 32;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      button: true,
      label: l10n.community_addMedia,
      child: GestureDetector(
        onTap: onAdd,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: _affordanceSize,
                  height: _affordanceSize,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppConfig.fadedBackgroundGradient,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/plus.svg',
                    width: _glyphSize,
                    height: _glyphSize,
                    colorFilter: const ColorFilter.mode(
                      AppConfig.menuIconColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.community_addMedia,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.weGatherLabelTextStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.community_mediaEmpty,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.weGatherSmallTextStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One picked file, drawn from the device rather than the network — nothing has
/// been uploaded yet at this point.
///
/// Photos and videos are both fitted rather than cropped, so what is on screen is
/// what was picked; the feed's own cover crop comes later.
class _MediaPreview extends StatelessWidget {
  const _MediaPreview({super.key, required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    if (mediaTypeOf(file) == GalleryMediaType.video) {
      return _LocalVideoPreview(path: file.path);
    }
    return Image.file(
      File(file.path),
      fit: BoxFit.contain,
      width: double.infinity,
      errorBuilder: (context, _, _) => const _PreviewFailed(),
    );
  }
}

/// A picked video, playable in place: its first frame until it is tapped.
///
/// Deliberately not [WgVideoPlayer], which plays a URL — there is no URL yet.
class _LocalVideoPreview extends StatefulWidget {
  const _LocalVideoPreview({required this.path});

  final String path;

  @override
  State<_LocalVideoPreview> createState() => _LocalVideoPreviewState();
}

class _LocalVideoPreviewState extends State<_LocalVideoPreview> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final controller = VideoPlayerController.file(File(widget.path));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const _PreviewFailed();

    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),
              // Only the badge follows playback, the way the gallery's player
              // does it — the frame itself doesn't need rebuilding.
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, _) => value.isPlaying
                    ? const SizedBox.shrink()
                    : const Icon(
                        Icons.play_circle_outline,
                        size: 56,
                        color: AppConfig.lightIconColor,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stands in for a file the device turned out not to be able to draw.
class _PreviewFailed extends StatelessWidget {
  const _PreviewFailed();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 48,
        color: AppConfig.colorTertiary,
      ),
    );
  }
}
