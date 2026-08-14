import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegather_app/calendar_widgets/wg_activity.dart';
import 'package:wegather_app/calendar_widgets/wg_date_picker.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/models/activity_model.dart';
import 'package:wegather_app/providers/activities_providers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// The event schedule: a strip of the event's days on top, the activities of
/// the selected day below.
///
/// The screen owns the selected day — [WgDatePicker] only reports taps — and
/// resolves the default itself: today when the event is running, otherwise the
/// first day, so opening the calendar always lands on something.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
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
    final activities = ref.watch(activitiesProvider);
    final days = ref.watch(scheduleDaysProvider);
    final selectedDay = _resolveSelectedDay(days);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.schedule_title,
                    style: AppTextStyles.weGatherMediumHeaderTextStyle,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: SvgPicture.asset(
                      AppConfig.qrLogo,
                      width: 20,
                      height: 20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppConfig.loginPageFormBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WgDatePicker(
                          days: days,
                          selectedDay: selectedDay,
                          onDaySelected: (day) =>
                              setState(() => _selectedDay = day),
                        ),
                        const SizedBox(height: 29),
                        Expanded(
                          child: activities.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, _) => _CenteredText(
                              '${l10n.schedule_loadError}\n\n$error',
                            ),
                            data: (list) => _DaySchedule(
                              activities: list,
                              day: selectedDay,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The activities of a single day, or the reason there are none.
class _DaySchedule extends ConsumerWidget {
  const _DaySchedule({required this.activities, required this.day});

  final List<ActivityModel> activities;
  final DateTime? day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedDay = day;
    if (activities.isEmpty || selectedDay == null) {
      return _CenteredText(l10n.schedule_empty);
    }

    final ofDay = ref
        .watch(activitiesServiceProvider)
        .activitiesOn(activities, selectedDay);
    if (ofDay.isEmpty) return _CenteredText(l10n.schedule_emptyDay);

    return ListView.separated(
      padding: EdgeInsets.zero,
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

class _CenteredText extends StatelessWidget {
  const _CenteredText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.weGatherParagraphTextStyle,
        ),
      ),
    );
  }
}
