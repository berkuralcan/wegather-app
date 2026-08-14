import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/tips_model.dart';
import 'package:wegather_app/providers/tips_providers.dart';
import 'package:wegather_app/tip_widgets/tip_displayer.dart';

/// PLACEHOLDER — the "Important Tips" of the current event as a flat list.
///
/// It exists to prove the pipeline end to end (event selection -> Firestore ->
/// the shared tip model -> the existing displayers). Restyle it freely; the
/// only things worth keeping are [tipsProvider] and the tap-through to
/// [TipDisplayer].
class TipsScreen extends ConsumerWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tips = ref.watch(tipsProvider);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.tips_title),
      body: SafeArea(
        top: false,
        child: tips.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) =>
              _CenteredText('${l10n.tips_loadError}\n\n$error'),
          data: (list) {
            if (list.isEmpty) return _CenteredText(l10n.tips_empty);
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _TipTile(tip: list[index]),
            );
          },
        ),
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({required this.tip});

  final TipModel tip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (_) => TipDisplayer(tip: tip))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConfig.tipColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConfig.loginPageFormBorderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: AppConfig.lightIconColor,
                        size: 24,
                      ),
                      SizedBox(width: 16),
                      Text(
                        tip.title,
                        style: AppTextStyles.weGatherLabelTextStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppConfig.emphasisColor,
              size: 28,
            ),
          ],
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
