import 'package:flutter/material.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/document_model.dart';
import 'package:wegather_app/models/tips_model.dart';
import 'package:wegather_app/reusableWidgets/primary_button.dart';
import 'package:wegather_app/tip_widgets/single_file_displayer.dart';

/// The detail view of a single document: the file name (in the app bar), the
/// optional description, and an "Open document" button.
///
/// Opening reuses [SingleFileDisplayer] — the exact behaviour of a "file" tip —
/// so images open in the image viewer, PDFs in the PDF viewer, and anything else
/// offers to open in the browser. A document is, after all, a file tip with a
/// name and a description.
class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({super.key, required this.document});

  final DocumentModel document;

  void _open(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => SingleFileDisplayer(
          title: document.fileName,
          content: FileTipContent(document.fileUrl),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CustomAppBar(title: document.fileName),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (document.hasDescription) ...[
                Text(
                  document.description,
                  style: AppTextStyles.weGatherParagraphTextStyle,
                ),
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: l10n.document_open,
                  onPressed: () => _open(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
