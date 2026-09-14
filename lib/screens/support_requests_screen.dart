import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../layouts/wegather_appbar.dart';
import '../models/support_model.dart';
import '../providers/support_providers.dart';
import '../reusableWidgets/primary_button.dart';
import '../support_widgets/new_request_sheet.dart';
import '../support_widgets/support_request_tile.dart';

/// The participant's own support requests — what the Contact tile opens.
///
/// Threads the support team hasn't answered yet come first, then the most
/// recently active, with resolved ones at the bottom: the same order the admin
/// panel works its queue in, so both sides agree about what is outstanding.
///
/// Everything here is live. A reply landing while the list is open moves the
/// thread and changes its status chip without a refresh, which is the whole
/// reason this screen streams rather than fetches.
class SupportRequestsScreen extends ConsumerWidget {
  const SupportRequestsScreen({super.key});

  /// The gutter the list keeps from the edge, matching the documents and tips
  /// screens so the module looks like the rest of the app.
  static const double _inset = 16;

  /// Order for the user's own list: waiting on support first, then answered,
  /// then resolved; most recently active within each group.
  ///
  /// The query already returns them by `lastMessageAt`; this adds the grouping
  /// a Firestore `orderBy` can't express, and keeps a request whose server
  /// timestamp hasn't resolved yet (it reads as null for an instant after
  /// sending) from jumping to the bottom of the list.
  static List<SupportRequest> _ordered(List<SupportRequest> requests) {
    int rank(SupportRequest r) {
      if (r.isResolved) return 2;
      return r.isAwaitingSupport ? 0 : 1;
    }

    final sorted = [...requests];
    sorted.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      final aAt = a.lastMessageAt ?? a.createdAt;
      final bAt = b.lastMessageAt ?? b.createdAt;
      // A request still waiting on its server timestamp is the one just sent,
      // so it belongs at the top of its group rather than the bottom.
      if (aAt == null && bAt == null) return 0;
      if (aAt == null) return -1;
      if (bAt == null) return 1;
      return bAt.compareTo(aAt);
    });
    return sorted;
  }

  Future<void> _openComposer(BuildContext context) async {
    final requestId = await NewRequestSheet.show(context);
    if (requestId == null || !context.mounted) return;
    // Straight into the thread that was just opened: the user wrote a message,
    // so the conversation is what they expect to land in, not the list.
    context.pushNamed('supportRequest', pathParameters: {'requestId': requestId});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final requests = ref.watch(supportRequestsProvider);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.support_title),
      body: SafeArea(
        top: false,
        child: requests.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) => _CenteredText(l10n.support_loadError),
          data: (list) {
            if (list.isEmpty) return _SupportEmptyState(onCreate: () => _openComposer(context));

            final ordered = _ordered(list);
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(_inset, 8, _inset, _inset),
              itemCount: ordered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = ordered[index];
                return SupportRequestTile(
                  request: request,
                  onTap: () => context.pushNamed(
                    'supportRequest',
                    pathParameters: {'requestId': request.id},
                    extra: request,
                  ),
                );
              },
            );
          },
        ),
      ),
      // Hidden while the empty state is up: it offers the same action in the
      // middle of the screen, and two buttons for one thing reads as two things.
      floatingActionButton: requests.valueOrNull?.isEmpty ?? true
          ? null
          : _NewRequestButton(onPressed: () => _openComposer(context)),
    );
  }
}

/// What the screen shows before the user has ever asked anything: an explanation
/// and the one action worth taking.
class _SupportEmptyState extends StatelessWidget {
  const _SupportEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: AppConfig.fadedBackgroundGradient,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/icons/default/modules/contact.png',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.support_emptyTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.weGatherMediumHeaderTextStyle,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.support_empty,
              textAlign: TextAlign.center,
              style: AppTextStyles.weGatherParagraphTextStyle.copyWith(
                color: AppConfig.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: l10n.support_newRequest,
                onPressed: onCreate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The floating "New request" action over a populated list: the app's primary
/// gradient in a circle. The empty state uses [PrimaryButton] instead, since
/// there it is a labelled call to action rather than a corner affordance.
class _NewRequestButton extends StatelessWidget {
  const _NewRequestButton({required this.onPressed});

  final VoidCallback onPressed;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      button: true,
      label: l10n.support_newRequest,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: _size,
          height: _size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: AppConfig.buttonPrimaryGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add,
            color: AppConfig.lightIconColor,
            size: 26,
          ),
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
