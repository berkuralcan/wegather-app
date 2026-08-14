import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegather_app/models/activity_model.dart';
import 'package:wegather_app/models/localized_text.dart';
import 'package:wegather_app/services/activities_service.dart';

/// The schedule's two risky parts: reading the panel's two document shapes
/// (mono vs multilingual, optional fields present or omitted), and deciding
/// which day an activity belongs to when it spans more than one.
void main() {
  group('ActivityModel.fromJson', () {
    test('reads a mono document, keeping omitted fields null', () {
      final activity = ActivityModel.fromJson('a1', {
        'isMultilingual': false,
        'title': 'Opening keynote',
        'startDateTime': Timestamp.fromDate(DateTime(2025, 10, 20, 21)),
        'endDateTime': Timestamp.fromDate(DateTime(2025, 10, 20, 22)),
        'location': 'Küçükçiftlik Park',
      });

      expect(activity.id, 'a1');
      expect(activity.title, 'Opening keynote');
      expect(activity.titleFor(WgLocale.en), 'Opening keynote');
      expect(activity.location, 'Küçükçiftlik Park');
      expect(activity.locationDetails, isNull);
      expect(activity.locationDetail, '');
      expect(activity.participants, isEmpty);
      expect(activity.startDateTime, DateTime(2025, 10, 20, 21));
    });

    test('reads a multilingual document per locale', () {
      final activity = ActivityModel.fromJson('a2', {
        'isMultilingual': true,
        'title': {'tr': 'Açılış konuşması', 'en': 'Opening keynote'},
        'startDateTime': Timestamp.fromDate(DateTime(2025, 10, 20, 21)),
        'endDateTime': Timestamp.fromDate(DateTime(2025, 10, 20, 22)),
        'description': {'tr': 'Ayrıntı', 'en': 'Detail'},
      });

      expect(activity.titleFor(WgLocale.tr), 'Açılış konuşması');
      expect(activity.titleFor(WgLocale.en), 'Opening keynote');
      expect(activity.descriptionFor(WgLocale.en), 'Detail');
    });

    test('falls back to the payload shape when the flag predates it', () {
      final activity = ActivityModel.fromJson('a3', {
        'title': {'tr': 'Açılış', 'en': 'Opening'},
        'startDateTime': DateTime(2025, 10, 20).millisecondsSinceEpoch,
        'endDateTime': DateTime(2025, 10, 20).millisecondsSinceEpoch,
      });

      expect(activity.isMultilingual, isTrue);
      expect(activity.titleFor(WgLocale.en), 'Opening');
    });

    test('parses the embedded participant snapshots', () {
      final activity = ActivityModel.fromJson('a4', {
        'isMultilingual': false,
        'title': 'Panel',
        'startDateTime': Timestamp.fromDate(DateTime(2025, 10, 20, 10)),
        'endDateTime': Timestamp.fromDate(DateTime(2025, 10, 20, 11)),
        'participants': [
          {
            'id': 'p1',
            'isMultilingual': false,
            'name': 'Ada Lovelace',
            'title': 'Speaker',
            'email': 'ada@example.com',
          },
        ],
      });

      expect(activity.participants, hasLength(1));
      expect(activity.participants.single.id, 'p1');
      expect(activity.participants.single.name, 'Ada Lovelace');
      expect(activity.participants.single.title, 'Speaker');
      expect(activity.participants.single.cvUrls, isNull);
    });
  });

  group('day spanning', () {
    ActivityModel activity(DateTime start, DateTime end) => ActivityModel(
      id: 'a',
      isMultilingual: false,
      titles: const {WgLocale.tr: 'Activity'},
      startDateTime: start,
      endDateTime: end,
    );

    test('an activity touches every day it runs through', () {
      final multiDay = activity(
        DateTime(2025, 10, 20, 22),
        DateTime(2025, 10, 22, 2),
      );

      expect(multiDay.touchesDay(DateTime(2025, 10, 19)), isFalse);
      expect(multiDay.touchesDay(DateTime(2025, 10, 20)), isTrue);
      expect(multiDay.touchesDay(DateTime(2025, 10, 21)), isTrue);
      expect(multiDay.touchesDay(DateTime(2025, 10, 22)), isTrue);
      expect(multiDay.touchesDay(DateTime(2025, 10, 23)), isFalse);
    });

    test('an activity ending at midnight belongs to the day it started', () {
      final overnight = activity(
        DateTime(2025, 10, 20, 21),
        DateTime(2025, 10, 21),
      );

      expect(overnight.touchesDay(DateTime(2025, 10, 20)), isTrue);
      expect(overnight.touchesDay(DateTime(2025, 10, 21)), isFalse);
    });

    test('daysBetween is inclusive of both ends', () {
      expect(
        daysBetween(DateTime(2025, 10, 20, 23), DateTime(2025, 10, 22, 1)),
        [
          DateTime(2025, 10, 20),
          DateTime(2025, 10, 21),
          DateTime(2025, 10, 22),
        ],
      );
    });
  });

  group('ActivitiesService', () {
    final service = ActivitiesService();

    ActivityModel activity(String id, DateTime start, DateTime end) =>
        ActivityModel(
          id: id,
          isMultilingual: false,
          titles: {WgLocale.tr: id},
          startDateTime: start,
          endDateTime: end,
        );

    test('scheduleDays lists each day once, in order', () {
      final days = service.scheduleDays([
        activity('b', DateTime(2025, 10, 22, 9), DateTime(2025, 10, 22, 10)),
        activity('a', DateTime(2025, 10, 20, 9), DateTime(2025, 10, 21, 10)),
        activity('c', DateTime(2025, 10, 20, 14), DateTime(2025, 10, 20, 15)),
      ]);

      expect(days, [
        DateTime(2025, 10, 20),
        DateTime(2025, 10, 21),
        DateTime(2025, 10, 22),
      ]);
    });

    test('activitiesOn keeps a multi-day activity on every day it covers', () {
      final spanning = activity(
        'spanning',
        DateTime(2025, 10, 20, 9),
        DateTime(2025, 10, 21, 10),
      );
      final second = activity(
        'second',
        DateTime(2025, 10, 21, 12),
        DateTime(2025, 10, 21, 13),
      );

      expect(service.activitiesOn([spanning, second], DateTime(2025, 10, 20)), [
        spanning,
      ]);
      expect(service.activitiesOn([spanning, second], DateTime(2025, 10, 21)), [
        spanning,
        second,
      ]);
    });
  });
}
