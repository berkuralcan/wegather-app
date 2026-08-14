import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wegather_app/calendar_widgets/wg_participant.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/activity_model.dart';
import 'package:wegather_app/providers/activities_providers.dart';

/// One activity of the schedule in full: when and where it happens, what it is
/// about, and who takes part in it.
///
/// The screen is reached by tapping a row on the calendar and is pushed inside
/// the calendar's branch, so the bottom bar stays put and the app bar's back
/// button returns to the schedule.
///
/// It reads the activity out of the schedule the calendar already loaded
/// ([activityProvider]) instead of fetching it again — text in the primary
/// (Turkish) language, like the rest of the app.
class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, required this.activityId});

  final String activityId;

  /// Padding inside each box, and the gap between the two of them.
  static const double _boxPadding = 16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activity = ref.watch(activityProvider(activityId));

    return Scaffold(
      appBar: CustomAppBar(title: l10n.activity_title),
      body: SafeArea(
        top: false,
        child: activity.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              _CenteredText('${l10n.schedule_loadError}\n\n$error'),
          data: (activity) {
            if (activity == null) return _CenteredText(l10n.activity_notFound);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(_boxPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Box(child: _Details(activity: activity)),
                  // The roster box is absent entirely when nobody is assigned.
                  if (activity.participants.isNotEmpty) ...[
                    const SizedBox(height: _boxPadding),
                    _Box(child: _Participants(activity: activity)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The shared card the two sections sit in — same fill and radius as the
/// calendar's schedule box.
class _Box extends StatelessWidget {
  const _Box({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConfig.loginPageFormBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(ActivityDetailScreen._boxPadding),
      child: child,
    );
  }
}

/// Title, time, place and description.
class _Details extends StatelessWidget {
  const _Details({required this.activity});

  final ActivityModel activity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = activity.location;
    final locationDetail = activity.locationDetail;
    final description = activity.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(activity.title, style: AppTextStyles.weGatherHeaderTextStyle),
        const SizedBox(height: 16),
        // Wrapped rather than a single row: on a narrow screen a long place
        // name drops under the time instead of being squeezed against it.
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MetaItem(
              icon: const Icon(
                Icons.access_time,
                size: 16,
                color: AppConfig.secondaryTextColor,
              ),
              child: Text(
                _formatTimeRange(activity),
                style: AppTextStyles.weGatherParagraphTextStyle.copyWith(
                  color: AppConfig.secondaryTextColor,
                ),
              ),
            ),
            if (location.isNotEmpty || locationDetail.isNotEmpty)
              _MetaItem(
                icon: SvgPicture.asset(
                  AppConfig.mapPinIcon,
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    AppConfig.secondaryTextColor,
                    BlendMode.srcIn,
                  ),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (location.isNotEmpty)
                        TextSpan(
                          text: location,
                          style: AppTextStyles.weGatherParagraphTextStyle
                              .copyWith(color: AppConfig.secondaryTextColor),
                        ),
                      if (locationDetail.isNotEmpty) ...[
                        if (location.isNotEmpty) const TextSpan(text: '  '),
                        TextSpan(
                          text: locationDetail,
                          style: AppTextStyles.weGatherParagraphTextStyle
                              .copyWith(color: AppConfig.secondaryTextColor),
                        ),
                      ],
                    ],
                  ),
                  style: AppTextStyles.weGatherPrimaryTextStyle,
                ),
              ),
          ],
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppConfig.dividerNonOpaqueColor),
          const SizedBox(height: 16),
          Text(
            l10n.activity_about,
            style: AppTextStyles.weGatherHeaderTextStyle,
          ),
          const SizedBox(height: 8),
          Text(description, style: AppTextStyles.weGatherParagraphTextStyle),
        ],
      ],
    );
  }
}

/// An icon and the piece of text it labels, sized to their content so the
/// enclosing [Wrap] can break between them.
class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.child});

  final Widget icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Flexible(child: child),
      ],
    );
  }
}

/// The activity's roster, one row per person. Tapping a row opens that person's
/// detail page, which reads them back out of this activity's snapshot.
class _Participants extends StatelessWidget {
  const _Participants({required this.activity});

  final ActivityModel activity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.activity_participants,
          style: AppTextStyles.weGatherHeaderTextStyle,
        ),
        for (final participant in activity.participants) ...[
          const SizedBox(height: 16),
          WgParticipant(
            participant: participant,
            // A snapshot written without an id can't be addressed by the
            // detail route, so that row simply doesn't open.
            onTap: participant.id.isEmpty
                ? null
                : () => context.pushNamed(
                    'participant',
                    pathParameters: {
                      'activityId': activity.id,
                      'participantId': participant.id,
                    },
                  ),
          ),
        ],
      ],
    );
  }
}

/// How long the activity runs. The day is spelled out on both ends only when it
/// spans more than one — most activities start and end on the same afternoon.
String _formatTimeRange(ActivityModel activity) {
  final time = DateFormat('HH:mm');
  final dayAndTime = DateFormat('dd/MM HH:mm');
  final spansDays = !isSameDay(activity.startDateTime, activity.endDateTime);
  final format = spansDays ? dayAndTime : time;
  return '${format.format(activity.startDateTime)} - '
      '${format.format(activity.endDateTime)}';
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
