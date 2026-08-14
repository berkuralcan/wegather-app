import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wegather_app/calendar_widgets/wg_activity.dart';
import 'package:wegather_app/calendar_widgets/wg_date_picker.dart';
import 'package:wegather_app/calendar_widgets/wg_participant.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/functions/global_functions.dart';
import 'package:wegather_app/global_widgets/wg_avatar.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/activity_model.dart';
import 'package:wegather_app/providers/activities_providers.dart';
import 'package:wegather_app/global_widgets/wg_info_row.dart';
import 'package:wegather_app/global_widgets/wg_tab_view.dart';

/// One person of an activity's roster: their photo, who they are, and their bio.
///
/// Reached by tapping a participant on the activity detail screen. The person is
/// read out of the roster snapshot the activity already embeds
/// ([participantProvider]) rather than fetched again — text in the primary
/// (Turkish) language, like the rest of the app.
class ParticipantDetailScreen extends ConsumerWidget {
  const ParticipantDetailScreen({
    super.key,
    required this.activityId,
    required this.participantId,
  });

  /// The activity whose roster the participant is read from.
  final String activityId;

  final String participantId;

  /// Padding around the page's content.
  static const double _padding = 16;

  /// Diameter of the photo at the top of the page.
  static const double _avatarSize = 80;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final participant = ref.watch(
      participantProvider((
        activityId: activityId,
        participantId: participantId,
      )),
    );

    return Scaffold(
      appBar: CustomAppBar(title: l10n.participant_title),
      body: SafeArea(
        top: false,
        child: participant.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              _CenteredText('${l10n.schedule_loadError}\n\n$error'),
          data: (participant) {
            if (participant == null) {
              return _CenteredText(l10n.participant_notFound);
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(_padding),
              child: _Profile(participant: participant),
            );
          },
        ),
      ),
    );
  }
}

/// Which half of the page the tabs are showing.
enum _ProfileTab { about, event }

/// The person's card, the tabs under it, and whichever tab is open.
class _Profile extends StatefulWidget {
  const _Profile({required this.participant});

  final ParticipantModel participant;

  @override
  State<_Profile> createState() => _ProfileState();
}

class _ProfileState extends State<_Profile> {
  _ProfileTab _tab = _ProfileTab.about;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(participant: widget.participant),
        const SizedBox(height: 16),
        WgTabView(
          labels: [l10n.participant_tabAbout, l10n.participant_tabEvent],
          selectedIndex: _tab.index,
          onSelected: (index) =>
              setState(() => _tab = _ProfileTab.values[index]),
          child: switch (_tab) {
            _ProfileTab.about => _AboutTab(participant: widget.participant),
            _ProfileTab.event => _EventTab(participant: widget.participant),
          },
        ),
      ],
    );
  }
}

/// The card the page's sections sit in — same fill and radius as the calendar's
/// schedule box and the activity detail screen's boxes.
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
      padding: const EdgeInsets.all(ParticipantDetailScreen._padding),
      child: child,
    );
  }
}

/// The photo, who the person is, and their bio.
class _Card extends StatelessWidget {
  const _Card({required this.participant});

  final ParticipantModel participant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = participant.title;
    final description = participant.description;

    return _Box(
      child: Column(
        children: [
          WgAvatar(
            imageUrl: participant.profileImage,
            size: ParticipantDetailScreen._avatarSize,
          ),
          const SizedBox(height: 8),
          Text(
            participant.name,
            style: AppTextStyles.weGatherParagraphTextStyle,
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.weGatherParagraphTextStyle.copyWith(
                color: AppConfig.colorTertiary,
              ),
            ),
          ],
          const SizedBox(height: 15),
          // The bio reads as a block of prose rather than a caption, so it and
          // its heading run flush left while the identity above them stays
          // centred under the photo.
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.participant_about,
                  style: AppTextStyles.weGatherHeaderTextStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTextStyles.weGatherParagraphTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The About tab: how to reach the person, and where to find them online.
class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.participant});

  final ParticipantModel participant;

  @override
  Widget build(BuildContext context) {
    final title = participant.title;
    final company = participant.company;
    final email = participant.email;
    final phone = participant.phone;
    final socials = participant.socials;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal Info', style: AppTextStyles.weGatherHeaderTextStyle),
        // Every row below is optional on the model, so each one collapses
        // entirely — rather than showing a placeholder — when unset.
        if (participant.name.isNotEmpty) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: 'Full Name', information: participant.name),
        ],
        if (title.isNotEmpty) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: 'Title', information: title),
        ],
        if (company != null && company.isNotEmpty) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: 'Company', information: company),
        ],
        if (email != null && email.isNotEmpty) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: 'Email Address', information: email),
        ],
        if (phone != null && phone.isNotEmpty) ...[
          const SizedBox(height: 16),
          WgInfoRow(title: 'Contact Number', information: phone),
        ],
        // `socials` is null unless the panel gave at least one link, so the
        // whole section — divider, heading and rows alike — collapses when
        // the participant has none.
        if (socials != null) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppConfig.dividerNonOpaqueColor),
          const SizedBox(height: 16),
          Text('Social Profiles', style: AppTextStyles.weGatherHeaderTextStyle),
          if (socials.linkedin != null) ...[
            const SizedBox(height: 16),
            WgInfoRow(
              title: 'LinkedIn',
              information: socials.linkedin!,
              icon: 'linkedin',
              onTap: () => navigateToUrl(socials.linkedin!),
            ),
          ],
          if (socials.instagram != null) ...[
            const SizedBox(height: 16),
            WgInfoRow(
              title: 'Instagram',
              information: socials.instagram!,
              icon: 'instagram',
              onTap: () => navigateToUrl(socials.instagram!),
            ),
          ],
          if (socials.website != null) ...[
            const SizedBox(height: 16),
            WgInfoRow(
              title: 'Website',
              information: socials.website!,
              icon: 'website',
              onTap: () => navigateToUrl(socials.website!),
            ),
          ],
          if (socials.portfolio != null) ...[
            const SizedBox(height: 16),
            WgInfoRow(
              title: 'Portfolio',
              information: socials.portfolio!,
              icon: 'portfolio',
              onTap: () => navigateToUrl(socials.portfolio!),
            ),
          ],
        ],
      ],
    );
  }
}

/// The Event tab: when this person is on, and who else is on the bill.
class _EventTab extends StatelessWidget {
  const _EventTab({required this.participant});

  final ParticipantModel participant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Box(child: _Schedule(participant: participant)),
        const SizedBox(height: ParticipantDetailScreen._padding),
        _Box(child: _OtherSpeakers(participant: participant)),
      ],
    );
  }
}

/// The person's own schedule — the calendar screen's date picker and day list,
/// over the activities they are assigned to rather than the whole event's.
///
/// The picker still offers every day of the event, so the days this person is
/// *not* on read as empty rather than vanishing from the strip. The screen owns
/// the selection and resolves the default the same way the calendar does.
class _Schedule extends ConsumerStatefulWidget {
  const _Schedule({required this.participant});

  final ParticipantModel participant;

  @override
  ConsumerState<_Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends ConsumerState<_Schedule> {
  /// Null until the user picks a day; [_resolveSelectedDay] fills in the
  /// default while the schedule is still loading and the day list is empty.
  DateTime? _selectedDay;

  /// The day to show out of [days] — the user's pick while it is still one of
  /// them, today if the event is running, otherwise the first day.
  DateTime? _resolveSelectedDay(List<DateTime> days) {
    if (days.isEmpty) return null;
    final selected = _selectedDay;
    if (selected != null && days.any((day) => isSameDay(day, selected))) {
      return selected;
    }
    final today = startOfDay(DateTime.now());
    return days.firstWhere((day) => day == today, orElse: () => days.first);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = ref.watch(scheduleDaysProvider);
    final selectedDay = _resolveSelectedDay(days);
    final activities = ref.watch(
      participantActivitiesProvider(widget.participant.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.participant_eventSchedule,
          style: AppTextStyles.weGatherHeading2TextStyle,
        ),
        const SizedBox(height: 16),
        WgDatePicker(
          days: days,
          selectedDay: selectedDay,
          onDaySelected: (day) => setState(() => _selectedDay = day),
        ),
        const SizedBox(height: 29),
        activities.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              _CenteredText('${l10n.schedule_loadError}\n\n$error'),
          data: (list) => _DaySchedule(activities: list, day: selectedDay),
        ),
      ],
    );
  }
}

/// The person's activities on a single day, or the reason there are none.
///
/// The calendar gives its list the rest of the screen to scroll in; here it is
/// one section of a page that scrolls as a whole, so the list takes the height
/// of its rows and leaves the scrolling to the page.
class _DaySchedule extends ConsumerWidget {
  const _DaySchedule({required this.activities, required this.day});

  final List<ActivityModel> activities;
  final DateTime? day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedDay = day;
    if (activities.isEmpty) return _EmptyText(l10n.participant_noActivities);
    if (selectedDay == null) return _EmptyText(l10n.schedule_empty);

    final ofDay = ref
        .watch(activitiesServiceProvider)
        .activitiesOn(activities, selectedDay);
    if (ofDay.isEmpty) return _EmptyText(l10n.schedule_emptyDay);

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ofDay.length,
      separatorBuilder: (_, _) => const SizedBox(height: 25),
      itemBuilder: (context, index) {
        final activity = ofDay[index];
        return WgActivity(
          activity: activity,
          onTap: () => context.pushNamed(
            'activity',
            pathParameters: {'activityId': activity.id},
          ),
        );
      },
    );
  }
}

/// The rest of the event's roster, in the same rows the activity detail screen
/// lists an activity's participants with.
///
/// This is the one place the roster collection itself is read: the person being
/// looked at is only in it once, while the activities embed whichever slice of
/// it they were assigned.
class _OtherSpeakers extends ConsumerWidget {
  const _OtherSpeakers({required this.participant});

  final ParticipantModel participant;

  /// Opens [other]'s page. The route hangs off an activity, so it is the first
  /// one they take part in that carries them — a roster entry not yet assigned
  /// to anything has no page to open, and its row simply doesn't respond.
  VoidCallback? _open(
    BuildContext context,
    List<ActivityModel> schedule,
    ParticipantModel other,
  ) {
    if (other.id.isEmpty) return null;
    final host = schedule.cast<ActivityModel?>().firstWhere(
      (a) => a!.participants.any((p) => p.id == other.id),
      orElse: () => null,
    );
    if (host == null) return null;
    return () => context.pushNamed(
      'participant',
      pathParameters: {'activityId': host.id, 'participantId': other.id},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final roster = ref.watch(eventParticipantsProvider);
    final schedule = ref.watch(activitiesProvider).valueOrNull ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.participant_otherSpeakers,
          style: AppTextStyles.weGatherHeading2TextStyle,
        ),
        roster.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _CenteredText('${l10n.schedule_loadError}\n\n$error'),
          ),
          data: (people) {
            final others = people.where((p) => p.id != participant.id).toList();
            if (others.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _EmptyText(l10n.participant_noOtherSpeakers),
              );
            }
            return Column(
              children: [
                for (final other in others) ...[
                  const SizedBox(height: 16),
                  WgParticipant(
                    participant: other,
                    onTap: _open(context, schedule, other),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// What a section says when it has nothing to list. Quieter and smaller than
/// the content it stands in for, and flush left with the heading above it —
/// it reads as a note about the section, not as a message about the page.
class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.weGatherPrimaryTextStyle.copyWith(
        color: AppConfig.colorTertiary,
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
