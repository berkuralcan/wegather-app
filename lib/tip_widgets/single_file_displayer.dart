import 'package:flutter/material.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/file_widgets/wg_pdf_viewer.dart';
import 'package:wegather_app/functions/global_functions.dart';
import 'package:wegather_app/image_widgets/wg_image_viewer.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/gallery_image.dart';
import 'package:wegather_app/models/tips_model.dart';

/// The kinds of attachment a file tip can hold.
///
/// The admin panel's dropzone accepts anything for a `file` tip, so
/// [unsupported] is not dead code — it is what an author gets for uploading a
/// .docx.
enum FileKind { image, pdf, unsupported }

/// Displays a single-file tip.
///
/// Both supported kinds already have a viewer: an image opens the same
/// [WgImageViewer] a gallery tile does (pinch to zoom, no filmstrip for a set
/// of one), and a PDF opens [WgPdfViewer] to be paged through left and right.
class SingleFileDisplayer extends StatelessWidget {
  const SingleFileDisplayer({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final FileTipContent content;

  static const Set<String> _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.heic',
    '.bmp',
  };

  /// Classifies a file by the extension in its URL.
  ///
  /// The name is read out of the URL's *path*, so query strings are ignored —
  /// a Firebase Storage download URL ends in `?alt=media&token=…`, and stores
  /// the object's whole path percent-encoded into a single path segment
  /// (`/o/tips%2Fmap.pdf`), which [Uri.pathSegments] decodes back out.
  static FileKind kindOf(String url) {
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    if (segments.isEmpty) return FileKind.unsupported;
    final name = segments.last.split('/').last.toLowerCase();

    if (name.endsWith('.pdf')) return FileKind.pdf;
    if (_imageExtensions.any(name.endsWith)) return FileKind.image;
    return FileKind.unsupported;
  }

  @override
  Widget build(BuildContext context) {
    final url = content.fileUrl;
    if (url.isEmpty) {
      return _FileMessage(title: title, message: 'No file attached.');
    }

    return switch (kindOf(url)) {
      FileKind.image => WgImageViewer(
        images: [GalleryImage(url)],
        title: title,
      ),
      FileKind.pdf => WgPdfViewer(url: url, title: title),
      FileKind.unsupported => _FileMessage(
        title: title,
        message: 'This file cannot be previewed in the app.',
        url: url,
      ),
    };
  }
}

/// A plain page for the cases with nothing to render — no file, or one of a
/// kind the app cannot draw. Offers to hand the URL to the browser when there
/// is one.
class _FileMessage extends StatelessWidget {
  const _FileMessage({required this.title, required this.message, this.url});

  final String title;
  final String message;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final url = this.url;

    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.weGatherParagraphTextStyle,
                ),
                if (url != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => navigateToUrl(url),
                    child: Text(
                      'Open in browser',
                      style: AppTextStyles.weGatherColoredTextButtonStyle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
