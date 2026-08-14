import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wegather_app/community_widgets/community_card.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/models/announcement_model.dart';
import 'package:wegather_app/models/event_model.dart';
import 'package:wegather_app/models/localized_text.dart';
import 'package:wegather_app/providers/access_providers.dart';
import 'package:wegather_app/providers/announcements_providers.dart';
import 'package:wegather_app/providers/auth_providers.dart';
import 'package:wegather_app/providers/community_providers.dart';
import 'package:wegather_app/providers/profile_providers.dart';
import 'package:wegather_app/screens/announcement_detail_screen.dart';

/// The app's home tab: a greeting, and the event's latest announcement.
///
/// The module grid this tab used to show now lives behind the "Modules" tab
/// ([HomeScreen]).
class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final announcements = ref.watch(announcementsProvider);
    final event = ref.watch(selectedEventProvider);

    return Scaffold(
      body: SafeArea(
        // Scrollable since the community strip: the greeting, the banner, the
        // announcement and a row of cards no longer fit a phone's screen.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Text(
                _greeting(ref, l10n),
                style: AppTextStyles.weGatherMediumHeaderTextStyle,
              ),
              const SizedBox(height: 8),
              // The event's featured image (localised) with the slogan — or a
              // day-of-event fallback — laid over it. Only rendered once the
              // selected event resolves.
              event.when(
                loading: () => const _EventBanner(),
                error: (_, __) => const SizedBox.shrink(),
                data: (event) => event == null
                    ? const SizedBox.shrink()
                    : _EventBanner(event: event),
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                title: l10n.announcements_title,
                onSeeAll: () => context.push('/announcements'),
              ),
              const SizedBox(height: 8),
              // The newest announcement of the event — unstyled for now.
              announcements.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (list) {
                  if (list.isEmpty) return const SizedBox.shrink();
                  return _LatestAnnouncement(announcement: list.first);
                },
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                title: l10n.community_title,
                onSeeAll: () => context.push('/community'),
              ),
              const SizedBox(height: 8),
              const _CommunityUpdates(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// "Hi, {first name}" — the profile document's name, falling back to the
  /// account's display name. Only the first word is used, since names are stored
  /// whole. Empty until one resolves, so the greeting never reads "Hi, ".
  String _greeting(WidgetRef ref, AppLocalizations l10n) {
    final name =
        ref.watch(currentProfileProvider).valueOrNull?.name ??
        ref.watch(currentUserProvider)?.displayName ??
        '';
    final firstName = name.trim().split(RegExp(r'\s+')).first;
    return firstName.isEmpty ? '' : l10n.landing_greeting(firstName);
  }
}

/// A section header on the landing screen: the section's title on the left and
/// a "See All" button on the right that opens that section's full list.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.weGatherHeading3TextStyle),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            l10n.landing_seeAll,
            style: AppTextStyles.weGatherTextButtonStyle,
          ),
        ),
      ],
    );
  }
}

/// The newest community posts under the community header, as a row of cards
/// that scrolls sideways.
///
/// They are the feed's own [CommunityCard], narrowed so the next card peeks in
/// at the edge — the cue that the row scrolls — and with their captions capped,
/// so one talkative post can't set the height of the whole strip. All five are
/// built at once rather than lazily; at that count paying for the row up front
/// costs less than the machinery to avoid it.
///
/// Nothing is drawn while the posts load, or when the event has none, so the
/// section collapses to its header rather than holding empty space.
class _CommunityUpdates extends ConsumerWidget {
  const _CommunityUpdates();

  /// How much of the row's width one card takes. Under a half, so the second
  /// card is always partly in view.
  static const double _cardWidthFactor = 0.55;

  /// The gap between two cards.
  static const double _gap = 12;

  /// How much caption a card previews before ellipsising.
  static const int _captionMaxLines = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(latestCommunityPostsProvider);

    return posts.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (posts) {
        if (posts.isEmpty) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth * _cardWidthFactor;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Cards differ in height (a post can have no caption at all), so
              // they hang from the top rather than centring on the tallest.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: _gap,
                children: [
                  for (final post in posts)
                    SizedBox(
                      width: cardWidth,
                      child: CommunityCard(
                        post: post,
                        captionMaxLines: _captionMaxLines,
                        // The post it already has goes along with the push, so
                        // its screen opens on the post rather than a spinner.
                        onTap: () => context.pushNamed(
                          'post',
                          pathParameters: {'postId': post.id},
                          extra: post,
                        ),
                        onAuthorTap: post.authorId.isEmpty
                            ? null
                            : () => context.pushNamed(
                                'profile',
                                pathParameters: {'profileId': post.authorId},
                              ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// The banner beneath the greeting: the event's localised featured image, with
/// a caption laid over it. The caption is the event's slogan when it has one;
/// otherwise a "day of the event" line ("Enjoy the 2nd day of {event}"). Passed
/// no [event] (the loading state), it renders just the tinted frame.
class _EventBanner extends StatelessWidget {
  const _EventBanner({this.event});

  final EventModel? event;

  // The image sits full-width in the screen's 16px padding, 170px tall, with an
  // 8px radius. The caption is bottom-left, 25px from the bottom, and never
  // wider than ~60% of the image so it wraps like the design.
  static const double _height = 180;
  static const double _radius = 8;
  static const double _captionBottom = 25;
  static const double _captionLeft = 16;
  static const double _captionWidthFactor = 0.6;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final wgLocale = WgLocale.fromJson(locale.languageCode);
    final imageUrl = event?.eventFeaturedImgFor(wgLocale) ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            children: [
              // A base fill shows through when the event has no featured image.
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppConfig.primaryFillColor,
                  image: imageUrl.isEmpty
                      ? null
                      : DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              // The legibility tint over the image.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppConfig.imageOverlayGradient,
                ),
              ),
              if (event != null)
                Positioned(
                  left: _captionLeft,
                  bottom: _captionBottom,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * _captionWidthFactor,
                    ),
                    child: Text(
                      _caption(context, event!, locale, wgLocale),
                      style: AppTextStyles.weGatherTitleTextStyle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The slogan when the event has one (falling back across languages), else the
  /// localised day-of-event line.
  String _caption(
    BuildContext context,
    EventModel event,
    Locale locale,
    WgLocale wgLocale,
  ) {
    if (event.hasSlogan) return event.eventSloganFor(wgLocale);

    final l10n = AppLocalizations.of(context)!;
    final day = _eventDayNumber(event, DateTime.now());
    // English needs an ordinal ("2nd"); Turkish uses a plain number and the
    // template supplies the trailing dot ("2. günün").
    final dayToken = locale.languageCode == 'tr'
        ? '$day'
        : _englishOrdinal(day);
    return l10n.landing_enjoyDay(dayToken, event.titleFor(wgLocale));
  }

  /// Which day of the event [now] falls on: day 1 is [EventModel.eventStartDate],
  /// clamped into the event's own start–end span so a visit before it opens reads
  /// as day 1 and one after it ends as the final day.
  int _eventDayNumber(EventModel event, DateTime now) {
    final start = DateUtils.dateOnly(event.eventStartDate);
    final end = DateUtils.dateOnly(event.eventEndDate);
    final today = DateUtils.dateOnly(now);
    final totalDays = end.difference(start).inDays + 1;
    final day = today.difference(start).inDays + 1;
    if (day < 1) return 1;
    if (totalDays >= 1 && day > totalDays) return totalDays;
    return day;
  }

  /// English ordinal for a positive day number: 1 -> "1st", 2 -> "2nd",
  /// 11 -> "11th", 21 -> "21st".
  String _englishOrdinal(int n) {
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}

/// The newest announcement, as a tappable card: up to three lines of its
/// content, then a "Read Now" call to action and the announcement's date. The
/// whole card opens the [AnnouncementDetailScreen], not just the call to action.
class _LatestAnnouncement extends StatelessWidget {
  const _LatestAnnouncement({required this.announcement});

  final AnnouncementModel announcement;

  /// The dot between "Read Now" and the date.
  static const double _dotSize = 4;

  /// The gap around the dot, and between the content and the footer row.
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = announcement.createdAt;

    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcement: announcement),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppConfig.primaryFillColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                announcement.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.weGatherPrimaryTextStyle.copyWith(
                  height: 1.3,
                ),
              ),
              const SizedBox(height: _gap),
              Row(
                spacing: _gap,
                children: [
                  Text(
                    l10n.landing_readNow,
                    style: AppTextStyles.weGatherTextButtonStyle,
                  ),
                  if (date != null) ...[
                    Container(
                      width: _dotSize,
                      height: _dotSize,
                      decoration: const BoxDecoration(
                        color: AppConfig.dividerNonOpaqueColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      _formatDate(context, date),
                      style: AppTextStyles.weGatherTextButtonStyle,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The announcement's date in the reader's language: "February 23, 2026" in
  /// English, "23 Şubat 2026" in Turkish. The locale's own month-day-year
  /// pattern handles both orders.
  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMMd(locale).format(date);
  }
}
