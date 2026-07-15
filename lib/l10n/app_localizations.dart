import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// A standard hello world message
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// The title of the app
  ///
  /// In en, this message translates to:
  /// **'WeGather - The best way to gather'**
  String get title;

  /// The label of the username field
  ///
  /// In en, this message translates to:
  /// **'E-Mail Address'**
  String get login_emailAddress;

  /// The label of the password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get login_password;

  /// The label of the login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_login;

  /// The error message for invalid username or password
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get login_invalidCredentials;

  /// The loading message
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get login_loading;

  /// The error message for network error
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again later.'**
  String get login_networkError;

  /// No description provided for @menu_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get menu_home;

  /// No description provided for @menu_calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get menu_calendar;

  /// No description provided for @menu_modules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get menu_modules;

  /// No description provided for @menu_user.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get menu_user;

  /// No description provided for @homeIcon_my_profile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get homeIcon_my_profile;

  /// No description provided for @homeIcon_information.
  ///
  /// In en, this message translates to:
  /// **'Important Information'**
  String get homeIcon_information;

  /// No description provided for @homeIcon_rules.
  ///
  /// In en, this message translates to:
  /// **'Event Rules'**
  String get homeIcon_rules;

  /// No description provided for @homeIcon_hotel.
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get homeIcon_hotel;

  /// No description provided for @homeIcon_flights.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get homeIcon_flights;

  /// No description provided for @homeIcon_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get homeIcon_gallery;

  /// No description provided for @homeIcon_security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get homeIcon_security;

  /// No description provided for @homeIcon_shake_to_win.
  ///
  /// In en, this message translates to:
  /// **'Shake to Win'**
  String get homeIcon_shake_to_win;

  /// No description provided for @homeIcon_contests.
  ///
  /// In en, this message translates to:
  /// **'Contest'**
  String get homeIcon_contests;

  /// No description provided for @homeIcon_contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get homeIcon_contact;

  /// No description provided for @homeIcon_my_qr_code.
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get homeIcon_my_qr_code;

  /// No description provided for @homeIcon_event_program.
  ///
  /// In en, this message translates to:
  /// **'Event Program'**
  String get homeIcon_event_program;

  /// No description provided for @homeIcon_flight_info.
  ///
  /// In en, this message translates to:
  /// **'Flight Info'**
  String get homeIcon_flight_info;

  /// No description provided for @homeIcon_transportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get homeIcon_transportation;

  /// No description provided for @homeIcon_stay_info.
  ///
  /// In en, this message translates to:
  /// **'Stay Information'**
  String get homeIcon_stay_info;

  /// No description provided for @homeIcon_documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get homeIcon_documents;

  /// No description provided for @homeIcon_announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get homeIcon_announcements;

  /// No description provided for @homeIcon_support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get homeIcon_support;

  /// No description provided for @profile_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_title;

  /// No description provided for @profile_change_profile_photo.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get profile_change_profile_photo;

  /// No description provided for @profile_take_photo.
  ///
  /// In en, this message translates to:
  /// **'Take a New Photo'**
  String get profile_take_photo;

  /// No description provided for @profile_choose_from_gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get profile_choose_from_gallery;

  /// The forgot password link on the login screen
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get login_forgotPassword;

  /// The text before the Terms and Services link on the login screen
  ///
  /// In en, this message translates to:
  /// **'You agree to '**
  String get login_terms_prefix;

  /// The Terms and Services link on the login screen
  ///
  /// In en, this message translates to:
  /// **'Terms and Services'**
  String get login_terms_link;

  /// The text after the Terms and Services link on the login screen
  ///
  /// In en, this message translates to:
  /// **' by signing in.'**
  String get login_terms_suffix;

  /// The title of the reset password screen
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword_title;

  /// The description on the reset password screen
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a link to reset your password.'**
  String get resetPassword_description;

  /// The label of the send reset link button
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get resetPassword_send;

  /// The success message after a reset email is sent
  ///
  /// In en, this message translates to:
  /// **'A password reset link has been sent to your email.'**
  String get resetPassword_success;

  /// The error message when no account exists for the email
  ///
  /// In en, this message translates to:
  /// **'No account found with this email address.'**
  String get resetPassword_userNotFound;

  /// The error message for an invalid email address
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get resetPassword_invalidEmail;

  /// The error message when the email field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address.'**
  String get resetPassword_emptyEmail;

  /// A generic error message for the reset password screen
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get resetPassword_genericError;

  /// The title of the terms and services screen
  ///
  /// In en, this message translates to:
  /// **'Terms and Services'**
  String get terms_title;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
