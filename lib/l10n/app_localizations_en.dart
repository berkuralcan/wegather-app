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
  String get menu_home => 'Home';

  @override
  String get menu_calendar => 'Calendar';

  @override
  String get menu_modules => 'Modules';

  @override
  String get menu_user => 'Profile';

  @override
  String get homeIcon_my_profile => 'My Profile';

  @override
  String get homeIcon_information => 'Important Information';

  @override
  String get homeIcon_rules => 'Event Rules';

  @override
  String get homeIcon_hotel => 'Accommodation';

  @override
  String get homeIcon_flights => 'Flights';

  @override
  String get homeIcon_gallery => 'Gallery';

  @override
  String get homeIcon_security => 'Security';

  @override
  String get homeIcon_shake_to_win => 'Shake to Win';

  @override
  String get homeIcon_contests => 'Contest';

  @override
  String get homeIcon_contact => 'Contact';

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

  @override
  String get profile_change_profile_photo => 'Change Profile Photo';

  @override
  String get profile_take_photo => 'Take a New Photo';

  @override
  String get profile_choose_from_gallery => 'Choose from Gallery';

  @override
  String get login_forgotPassword => 'Forgot Password?';

  @override
  String get login_terms_prefix => 'You agree to ';

  @override
  String get login_terms_link => 'Terms and Services';

  @override
  String get login_terms_suffix => ' by signing in.';

  @override
  String get resetPassword_title => 'Reset Password';

  @override
  String get resetPassword_description =>
      'Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get resetPassword_send => 'Send Reset Link';

  @override
  String get resetPassword_success =>
      'A password reset link has been sent to your email.';

  @override
  String get resetPassword_userNotFound =>
      'No account found with this email address.';

  @override
  String get resetPassword_invalidEmail => 'Invalid email address.';

  @override
  String get resetPassword_emptyEmail => 'Please enter your email address.';

  @override
  String get resetPassword_genericError =>
      'Something went wrong. Please try again.';

  @override
  String get terms_title => 'Terms and Services';
}
