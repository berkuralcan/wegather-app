import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pdfx/pdfx.dart';
import '../config/text_styles.dart';
import '../functions/global_functions.dart';
import '../layouts/wegather_appbar.dart';

/// Full-screen PDF viewer: one page at a time, swipe left and right to move
/// through the document.
///
/// Universal — it takes a plain URL, so it is not tied to tips. The document is
/// fetched through [DefaultCacheManager], the same disk cache
/// `cached_network_image` uses, so reopening a PDF does not re-download it.
class WgPdfViewer extends StatefulWidget {
  const WgPdfViewer({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  State<WgPdfViewer> createState() => _WgPdfViewerState();
}

class _WgPdfViewerState extends State<WgPdfViewer> {
  late final PdfController _controller;

  @override
  void initState() {
    super.initState();
    // The controller takes a future, so the download and the parse are one
    // unit of work as far as its loading state is concerned — no separate
    // "downloading" state to render.
    _controller = PdfController(document: _openDocument());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<PdfDocument> _openDocument() async {
    final file = await DefaultCacheManager().getSingleFile(widget.url);
    // Opened from disk rather than as bytes so a large document is not held in
    // memory in its entirety on top of the rendered pages.
    return PdfDocument.openFile(file.path);
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold and app bar are transparent, so the global background gradient
    // from main.dart shows through behind the pages.
    return Scaffold(
      appBar: CustomAppBar(title: widget.title ?? ''),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PdfView(
                controller: _controller,
                // One page per swipe, left and right.
                scrollDirection: Axis.horizontal,
                pageSnapping: true,
                // Both the download and the native parse land here. Logged
                // rather than swallowed: a failure is far more often a broken
                // URL or a plugin that never made it into the binary than a
                // genuinely corrupt PDF, and those look identical on screen.
                onDocumentError: (error) =>
                    debugPrint('WgPdfViewer: ${widget.url} failed — $error'),
                builders: PdfViewBuilders<DefaultBuilderOptions>(
                  options: const DefaultBuilderOptions(),
                  documentLoaderBuilder: (_) => const _Spinner(),
                  pageLoaderBuilder: (_) => const _Spinner(),
                  errorBuilder: (_, error) =>
                      _PdfError(url: widget.url, error: error),
                ),
              ),
            ),
            _buildPageNumber(),
          ],
        ),
      ),
    );
  }

  /// "3 / 12" beneath the page. Sits where the image viewer's filmstrip does,
  /// and like the filmstrip it is left out when there is nothing to move
  /// between.
  Widget _buildPageNumber() => PdfPageNumber(
    controller: _controller,
    builder: (_, state, page, pagesCount) {
      if (state != PdfLoadingState.success || (pagesCount ?? 0) < 2) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          '$page / $pagesCount',
          style: AppTextStyles.weGatherPrimaryTextStyle,
        ),
      );
    },
  );
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

/// Shown when the document cannot be fetched or parsed. Offers the URL as a
/// way out, since the browser may still manage what the renderer could not.
class _PdfError extends StatelessWidget {
  const _PdfError({required this.url, this.error});

  final String url;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This document could not be opened.',
              textAlign: TextAlign.center,
              style: AppTextStyles.weGatherParagraphTextStyle,
            ),
            // Only while developing — the cause is useful to whoever is
            // building the app and meaningless to an attendee.
            if (kDebugMode && error != null) ...[
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: AppTextStyles.weGatherTextButtonStyle,
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => navigateToUrl(url),
              child: Text(
                'Open in browser',
                style: AppTextStyles.weGatherColoredTextButtonStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
