import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wegather_app/calendar_widgets/wg_participant.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/models/activity_model.dart';
import 'package:wegather_app/models/localized_text.dart';
import 'package:wegather_app/providers/activities_providers.dart';
import 'package:wegather_app/screens/activity_detail_screen.dart';

/// The detail screen is mostly layout, so these cover the two decisions it does
/// make: which sections appear at all, and how a time range is written.
void main() {
  ActivityModel activity({
    String? description,
    List<ParticipantModel> participants = const [],
    DateTime? end,
  }) => ActivityModel(
    id: 'a1',
    isMultilingual: false,
    titles: {WgLocale.tr: 'Açılış Konuşması'},
    startDateTime: DateTime(2026, 5, 4, 21),
    endDateTime: end ?? DateTime(2026, 5, 4, 23),
    locations: {WgLocale.tr: 'Küçükçiftlik Park'},
    descriptions: description == null ? null : {WgLocale.tr: description},
    participants: participants,
  );

  ParticipantModel participant(String name, {String title = ''}) =>
      ParticipantModel(
        id: name,
        isMultilingual: false,
        name: name,
        titles: {WgLocale.tr: title},
      );

  // CustomAppBar asks `context.canPop()`, which needs a router above it.
  Widget wrap(ActivityModel model) => ProviderScope(
    overrides: [
      activitiesProvider.overrideWith((ref) async => [model]),
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
            builder: (_, _) => const ActivityDetailScreen(activityId: 'a1'),
          ),
        ],
      ),
    ),
  );

  testWidgets('shows the activity, its time and its place', (tester) async {
    await tester.pumpWidget(wrap(activity(description: 'Lorem ipsum.')));
    await tester.pumpAndSettle();

    expect(find.text('Açılış Konuşması'), findsOne);
    expect(find.text('21:00 - 23:00'), findsOne);
    expect(find.text('Küçükçiftlik Park'), findsOne);
    expect(find.text('About'), findsOne);
    expect(find.text('Lorem ipsum.'), findsOne);
  });

  testWidgets('drops the About section when there is no description', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(activity()));
    await tester.pumpAndSettle();

    expect(find.text('About'), findsNothing);
  });

  testWidgets('drops the participants box when nobody is assigned', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(activity(description: 'Lorem ipsum.')));
    await tester.pumpAndSettle();

    expect(find.text('Participants'), findsNothing);
    expect(find.byType(WgParticipant), findsNothing);
  });

  testWidgets('lists the participants when there are some', (tester) async {
    await tester.pumpWidget(
      wrap(
        activity(
          participants: [
            participant('Jane Doe', title: 'Product Manager'),
            participant('John Smith'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Participants'), findsOne);
    expect(find.byType(WgParticipant), findsNWidgets(2));
    expect(find.text('Jane Doe'), findsOne);
    expect(find.text('Product Manager'), findsOne);
    // No title on the second one, so its second line collapses.
    expect(find.text('John Smith'), findsOne);
  });

  testWidgets('spells out the days when the activity spans more than one', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(activity(end: DateTime(2026, 5, 5, 2))));
    await tester.pumpAndSettle();

    expect(find.text('04/05 21:00 - 05/05 02:00'), findsOne);
  });

  testWidgets('says so when the activity is not in the schedule', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [activitiesProvider.overrideWith((ref) async => [])],
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
                builder: (_, _) => const ActivityDetailScreen(activityId: 'a1'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('This activity is no longer part of the schedule.'),
      findsOne,
    );
  });
}
