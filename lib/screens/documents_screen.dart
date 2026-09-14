import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/global_widgets/wg_menu_tile.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/document_model.dart';
import 'package:wegather_app/providers/documents_providers.dart';
import 'package:wegather_app/screens/document_detail_screen.dart';

/// The documents of the current event as a flat list — the same layout as the
/// "Important Tips" screen (icon + name + chevron), tapping through to the
/// [DocumentDetailScreen]. Every row shows the same document icon used on the
/// home menu.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final documents = ref.watch(documentsProvider);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.documents_title),
      body: SafeArea(
        top: false,
        child: documents.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) =>
              _CenteredText('${l10n.documents_loadError}\n\n$error'),
          data: (list) {
            if (list.isEmpty) return _CenteredText(l10n.documents_empty);
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _DocumentTile(document: list[index]),
            );
          },
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document});

  final DocumentModel document;

  /// The document icon used on the home menu — reused here so every row carries
  /// the same glyph.
  static const String _iconPath = 'assets/icons/default/modules/documents.png';

  @override
  Widget build(BuildContext context) {
    return WgMenuTile(
      icon: Image.asset(
        _iconPath,
        width: WgMenuTile.iconSize,
        height: WgMenuTile.iconSize,
      ),
      label: document.fileName,
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => DocumentDetailScreen(document: document),
        ),
      ),
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
