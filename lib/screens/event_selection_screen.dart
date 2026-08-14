import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/event_model.dart';
import 'package:wegather_app/providers/access_providers.dart';
import 'package:wegather_app/providers/auth_providers.dart';

/// Lets a user pick which of their events to open.
///
/// The router sends users here whenever no event is selected. Users with access
/// to exactly one event never see it — that event is auto-selected. Users with
/// access to none land here on the empty state, which is also the "your account
/// isn't set up yet" screen.
class EventSelectionScreen extends ConsumerWidget {
  const EventSelectionScreen({super.key});

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
  ) async {
    await ref.read(selectedEventProvider.notifier).select(event);
    if (context.mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final events = ref.watch(accessibleEventsProvider);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.events_title),
      body: SafeArea(
        top: false,
        child: events.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _Message(
            text: l10n.events_loadError,
            actionLabel: l10n.common_retry,
            onAction: () => ref.invalidate(accessibleEventsProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return _Message(
                text: l10n.events_noAccess,
                actionLabel: l10n.common_logout,
                onAction: () => ref.read(authServiceProvider).signOut(),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _EventCard(
                event: list[index],
                onTap: () => _select(context, ref, list[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

  final EventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConfig.loginPageFormBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConfig.loginPageFormBorderColor),
        ),
        child: Row(
          children: [
            if (event.eventLogo.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  event.eventLogo,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: AppTextStyles.appBarTextStyle),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.weGatherPrimaryTextStyle,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppConfig.colorTertiary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

/// A centred message with one action — used for the empty and error states.
class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.weGatherParagraphTextStyle,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: AppTextStyles.weGatherColoredTextButtonStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
