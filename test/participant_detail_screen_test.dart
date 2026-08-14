import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wegather_app/global_widgets/wg_avatar.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/models/activity_model.dart';
import 'package:wegather_app/models/localized_text.dart';
import 'package:wegather_app/providers/activities_providers.dart';
import 'package:wegather_app/screens/participant_detail_screen.dart';

/// The screen is plain layout over the roster snapshot, so these cover the two
/// things it decides: that it finds the right person in the activity it was
/// opened from, and what it shows when it can't.
void main() {
  ParticipantModel participant({
    String id = 'p1',
    String name = 'Jane Doe',
    String title = 'Product Manager',
    String? description = 'Lorem ipsum.',
  }) => ParticipantModel(
    id: id,
    isMultilingual: false,
    name: name,
    titles: {WgLocale.tr: title},
    descriptions: description == null ? null : {WgLocale.tr: description},
  );

  ActivityModel activity(List<ParticipantModel> participants) => ActivityModel(
    id: 'a1',
    isMultilingual: false,
    titles: {WgLocale.tr: 'Açılış Konuşması'},
    startDateTime: DateTime(2026, 5, 4, 21),
    endDateTime: DateTime(2026, 5, 4, 23),
    participants: participants,
  );

  // CustomAppBar asks `context.canPop()`, which needs a router above it.
  Widget wrap(
    List<ActivityModel> schedule, {
    List<ParticipantModel> roster = const [],
  }) => ProviderScope(
    overrides: [
      activitiesProvider.overrideWith((ref) async => schedule),
      eventParticipantsProvider.overrideWith((ref) async => roster),
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const ParticipantDetailScreen(
              activityId: 'a1',
              participantId: 'p1',
            ),
          ),
        ],
      ),
    ),
  );

  testWidgets('shows the participant, their title and their bio', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap([
        activity([participant(), participant(id: 'p2', name: 'John Smith')]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WgAvatar), findsOne);
    // Name and title each read twice: once in the card, and once as a row of
    // the About tab under it. 'About' labels both the bio and the tab.
    expect(find.text('Jane Doe'), findsExactly(2));
    expect(find.text('Product Manager'), findsExactly(2));
    expect(find.text('About'), findsExactly(2));
    expect(find.text('Lorem ipsum.'), findsOne);
    // Contact rows the roster snapshot says nothing about are left out whole,
    // label and all.
    expect(find.text('Company'), findsNothing);
    expect(find.text('Email Address'), findsNothing);
    expect(find.text('Contact Number'), findsNothing);
    expect(find.text('Social Profiles'), findsNothing);
    // The person is read out of this activity's roster, not the whole schedule.
    expect(find.text('John Smith'), findsNothing);
  });

  testWidgets('collapses the title line when the participant has none', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap([
        activity([participant(title: '')]),
      ]),
    );
    await tester.pumpAndSettle();

    // Only the card and the Full Name row are left of the name.
    expect(find.text('Jane Doe'), findsExactly(2));
    expect(find.text('Product Manager'), findsNothing);
    expect(find.text('Title'), findsNothing);
  });

  testWidgets('opens on About and swaps its content for the Event tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap([
        activity([participant()]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Personal Info'), findsOne);

    await tester.tap(find.text('Event'));
    await tester.pumpAndSettle();

    expect(find.text('Personal Info'), findsNothing);

    await tester.tap(find.text('About').last);
    await tester.pumpAndSettle();

    expect(find.text('Personal Info'), findsOne);
  });

  testWidgets('the Event tab lists the days activities and the other speakers', (
    tester,
  ) async {
    final jane = participant();
    final john = participant(id: 'p2', name: 'John Smith');
    await tester.pumpWidget(
      wrap(
        [
          activity([jane, john]),
          // Jane isn't on this one, so it stays out of her schedule even though
          // it falls on the day she is showing.
          ActivityModel(
            id: 'a2',
            isMultilingual: false,
            titles: {WgLocale.tr: 'Kapanış'},
            startDateTime: DateTime(2026, 5, 4, 23, 30),
            endDateTime: DateTime(2026, 5, 5),
            participants: [john],
          ),
        ],
        roster: [jane, john],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Event'));
    await tester.pumpAndSettle();

    expect(find.text('Event Schedule'), findsOne);
    expect(find.text('Explore Other Speakers'), findsOne);
    // The picker offers both days the schedule touches, and opens on the first.
    expect(find.text('04/05/2026'), findsOne);
    expect(find.text('05/05/2026'), findsOne);
    // The rows write the title and the start time into one `Text.rich`.
    expect(
      find.textContaining('Açılış Konuşması', findRichText: true),
      findsOne,
    );
    expect(find.textContaining('Kapanış', findRichText: true), findsNothing);
    // Everyone on the roster but the person whose page this is.
    expect(find.text('John Smith'), findsOne);
    expect(find.text('Jane Doe'), findsOne); // The card only.

    await tester.tap(find.text('05/05/2026'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing is scheduled for this day.'), findsOne);
    expect(
      find.textContaining('Açılış Konuşması', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('the Event tab says so when the participant is on nothing', (
    tester,
  ) async {
    final jane = participant();
    await tester.pumpWidget(
      wrap(
        [
          activity([jane]),
        ],
        roster: [jane],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Event'));
    await tester.pumpAndSettle();

    // Jane is the event's only roster entry, so there is nobody to explore.
    expect(
      find.text('Nobody else has been added to this event yet.'),
      findsOne,
    );
  });

  testWidgets('says so when the participant is not in the roster', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap([
        activity([participant(id: 'p2')]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('This participant is no longer part of this activity.'),
      findsOne,
    );
  });
}
