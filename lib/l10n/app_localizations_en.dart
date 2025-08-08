// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World!';

  @override
  String get title => 'WeGather - The best way to gather';

  @override
  String get login_emailAddress => 'E-Mail Address';

  @override
  String get login_password => 'Password';

  @override
  String get login_login => 'Login';

  @override
  String get login_invalidCredentials => 'Invalid username or password';

  @override
  String get login_loading => 'Logging in...';

  @override
  String get login_networkError => 'Network error. Please try again later.';

  @override
  String get homeIcon_my_profile => 'My Profile';

  @override
  String get homeIcon_my_qr_code => 'My QR Code';

  @override
  String get homeIcon_event_program => 'Event Program';

  @override
  String get homeIcon_flight_info => 'Flight Info';

  @override
  String get homeIcon_transportation => 'Transportation';

  @override
  String get homeIcon_stay_info => 'Stay Information';

  @override
  String get homeIcon_documents => 'Documents';

  @override
  String get homeIcon_announcements => 'Announcements';

  @override
  String get homeIcon_support => 'Support';

  @override
  String get profile_title => 'Profile';
}
