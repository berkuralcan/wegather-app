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

  /// The label of the tab that shows the user's own details on the profile screen
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profile_tabAbout;

  /// The label of the tab that shows the user's posts on the profile screen
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get profile_tabPosts;

  /// Shown on the profile screen's Posts tab while the user has no posts
  ///
  /// In en, this message translates to:
  /// **'Nothing has been posted yet.'**
  String get profile_postsEmpty;

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

  /// The label of the retry button on error states
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get common_retry;

  /// The label of the log out button
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get common_logout;

  /// The title of the event selection screen
  ///
  /// In en, this message translates to:
  /// **'Select Event'**
  String get events_title;

  /// Shown on the event selection screen when the user has no accessible events
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to any events yet. Please contact your event organizer.'**
  String get events_noAccess;

  /// Shown when loading the user's events fails
  ///
  /// In en, this message translates to:
  /// **'Your events couldn\'t be loaded. Please check your connection and try again.'**
  String get events_loadError;

  /// The title of the important tips screen
  ///
  /// In en, this message translates to:
  /// **'Important Information'**
  String get tips_title;

  /// Shown when the selected event has no tips
  ///
  /// In en, this message translates to:
  /// **'No information has been added for this event yet.'**
  String get tips_empty;

  /// Shown when loading the event's tips fails
  ///
  /// In en, this message translates to:
  /// **'This information couldn\'t be loaded. Please try again.'**
  String get tips_loadError;

  /// The title of the announcements screen
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements_title;

  /// Shown when the selected event has no announcements
  ///
  /// In en, this message translates to:
  /// **'No announcements have been posted for this event yet.'**
  String get announcements_empty;

  /// Shown when loading the event's announcements fails
  ///
  /// In en, this message translates to:
  /// **'Announcements couldn\'t be loaded. Please try again.'**
  String get announcements_loadError;

  /// Button on an announcement that opens its link in the browser
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get announcement_openLink;

  /// The title of the documents screen
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents_title;

  /// Shown when the selected event has no documents
  ///
  /// In en, this message translates to:
  /// **'No documents have been shared for this event yet.'**
  String get documents_empty;

  /// Shown when loading the event's documents fails
  ///
  /// In en, this message translates to:
  /// **'Documents couldn\'t be loaded. Please try again.'**
  String get documents_loadError;

  /// Button on a document that opens the file
  ///
  /// In en, this message translates to:
  /// **'Open document'**
  String get document_open;

  /// The header of the calendar screen (the bottom nav label is menu_calendar)
  ///
  /// In en, this message translates to:
  /// **'Event Schedule'**
  String get schedule_title;

  /// Shown on the calendar screen when the event has no activities at all
  ///
  /// In en, this message translates to:
  /// **'No activities have been scheduled for this event yet.'**
  String get schedule_empty;

  /// Shown on the calendar screen when the selected day has no activities
  ///
  /// In en, this message translates to:
  /// **'Nothing is scheduled for this day.'**
  String get schedule_emptyDay;

  /// Shown when loading the event's schedule fails
  ///
  /// In en, this message translates to:
  /// **'The schedule couldn\'t be loaded. Please try again.'**
  String get schedule_loadError;

  /// The title of the activity detail screen
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get activity_title;

  /// The heading above an activity's description on its detail screen
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get activity_about;

  /// The heading of the participants box on the activity detail screen
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get activity_participants;

  /// Shown on the activity detail screen when the activity isn't in the loaded schedule
  ///
  /// In en, this message translates to:
  /// **'This activity is no longer part of the schedule.'**
  String get activity_notFound;

  /// The title of the participant detail screen
  ///
  /// In en, this message translates to:
  /// **'Participant Details'**
  String get participant_title;

  /// The heading above a participant's bio on their detail screen
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get participant_about;

  /// Shown on the participant detail screen when the participant isn't in the activity's roster
  ///
  /// In en, this message translates to:
  /// **'This participant is no longer part of this activity.'**
  String get participant_notFound;

  /// The label of the tab that shows a participant's own details on their detail screen
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get participant_tabAbout;

  /// The label of the tab that shows a participant's part in the event on their detail screen
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get participant_tabEvent;

  /// The heading of the box listing the activities a participant takes part in, on the Event tab of their detail screen
  ///
  /// In en, this message translates to:
  /// **'Event Schedule'**
  String get participant_eventSchedule;

  /// Shown in place of a participant's schedule when they are assigned to no activity at all
  ///
  /// In en, this message translates to:
  /// **'This participant isn\'t taking part in any activity yet.'**
  String get participant_noActivities;

  /// The heading of the box listing the event's other roster members, on the Event tab of a participant's detail screen
  ///
  /// In en, this message translates to:
  /// **'Explore Other Speakers'**
  String get participant_otherSpeakers;

  /// Shown in place of the other speakers when the participant is the event's only roster member
  ///
  /// In en, this message translates to:
  /// **'Nobody else has been added to this event yet.'**
  String get participant_noOtherSpeakers;

  /// The title of the event gallery screen
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery_title;

  /// The label of the pill selector tab showing the gallery's photos
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get gallery_tabPhotos;

  /// The label of the pill selector tab showing the gallery's videos
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get gallery_tabVideos;

  /// Shown when the gallery's Photos tab has nothing in it
  ///
  /// In en, this message translates to:
  /// **'No photos have been shared yet. Be the first to add one.'**
  String get gallery_emptyPhotos;

  /// Shown when the gallery's Videos tab has nothing in it
  ///
  /// In en, this message translates to:
  /// **'No videos have been shared yet. Be the first to add one.'**
  String get gallery_emptyVideos;

  /// Shown when loading the event gallery fails
  ///
  /// In en, this message translates to:
  /// **'The gallery couldn\'t be loaded. Please try again.'**
  String get gallery_loadError;

  /// The label of the button that adds media to the gallery
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get gallery_add;

  /// Shown while a picked photo or video is being uploaded to the gallery
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get gallery_uploading;

  /// Shown when an upload to the gallery finishes
  ///
  /// In en, this message translates to:
  /// **'Added to the gallery.'**
  String get gallery_uploadSuccess;

  /// Shown when an upload to the gallery fails
  ///
  /// In en, this message translates to:
  /// **'Your upload couldn\'t be completed. Please try again.'**
  String get gallery_uploadError;

  /// The label of the back button over a photo or video in the gallery viewer
  ///
  /// In en, this message translates to:
  /// **'Back to the gallery'**
  String get gallery_back;

  /// The label of the share button over a photo or video in the gallery viewer
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get gallery_share;

  /// The label of the report button over a photo or video in the gallery viewer
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get gallery_report;

  /// Shown when preparing a photo or video for the share sheet fails
  ///
  /// In en, this message translates to:
  /// **'This couldn\'t be shared. Please try again.'**
  String get gallery_shareError;

  /// The heading of the sheet that confirms reporting a photo or video
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to report this media?'**
  String get gallery_reportTitle;

  /// The explanation under the heading of the report sheet
  ///
  /// In en, this message translates to:
  /// **'The event team will review it. You can add a note about what\'s wrong with it.'**
  String get gallery_reportDescription;

  /// The placeholder of the optional note field on the report sheet
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this? (optional)'**
  String get gallery_reportReasonHint;

  /// The button that confirms reporting a photo or video
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get gallery_reportConfirm;

  /// The button that closes the report sheet without reporting
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get gallery_reportCancel;

  /// Shown when a photo or video has been reported
  ///
  /// In en, this message translates to:
  /// **'Thanks — this has been reported.'**
  String get gallery_reportSuccess;

  /// Shown when reporting a photo or video fails
  ///
  /// In en, this message translates to:
  /// **'This couldn\'t be reported. Please try again.'**
  String get gallery_reportError;

  /// The heading of the sheet that asks where a photo or video should come from
  ///
  /// In en, this message translates to:
  /// **'Add to the gallery'**
  String get gallery_addTitle;

  /// The option that opens the camera to take a photo for the gallery
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get gallery_addTakePhoto;

  /// The option that opens the camera to record a video for the gallery
  ///
  /// In en, this message translates to:
  /// **'Record a video'**
  String get gallery_addRecordVideo;

  /// The option that opens the device's library to pick a photo or video for the gallery
  ///
  /// In en, this message translates to:
  /// **'Choose from your gallery'**
  String get gallery_addChooseExisting;

  /// The button that closes the add sheet without adding anything
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get gallery_addCancel;

  /// The greeting at the top of the landing (home) screen, with the user's first name
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String landing_greeting(String name);

  /// The call to action under the latest announcement on the landing screen
  ///
  /// In en, this message translates to:
  /// **'Read Now'**
  String get landing_readNow;

  /// The button next to a section header on the landing screen that opens that section's full list
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get landing_seeAll;

  /// The title of the community updates section and screen
  ///
  /// In en, this message translates to:
  /// **'Community Updates'**
  String get community_title;

  /// Shown on the community screen when the event has no posts yet
  ///
  /// In en, this message translates to:
  /// **'No posts yet, be the first to create one!'**
  String get community_empty;

  /// The label of the button that opens the create-post flow on the community screen
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get community_createPost;

  /// Shown when loading the community feed fails
  ///
  /// In en, this message translates to:
  /// **'The community feed couldn\'t be loaded. Please try again.'**
  String get community_loadError;

  /// The title of the screen where a post is composed
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get community_newPost;

  /// The button that shares the composed post to the community feed
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get community_post;

  /// The placeholder of the caption field on the create-post screen
  ///
  /// In en, this message translates to:
  /// **'Write a caption…'**
  String get community_captionHint;

  /// The heading of the sheet that asks where a post's photo or video should come from
  ///
  /// In en, this message translates to:
  /// **'Add to your post'**
  String get community_addMediaTitle;

  /// The button on the empty create-post screen that opens the add-media sheet
  ///
  /// In en, this message translates to:
  /// **'Add photos or videos'**
  String get community_addMedia;

  /// Shown on the create-post screen before any media has been chosen
  ///
  /// In en, this message translates to:
  /// **'Take a photo or video, or choose some from your library. Pick several and they\'ll appear in the order you picked them.'**
  String get community_mediaEmpty;

  /// Shown when the post button is used before any media has been chosen
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo or video to post.'**
  String get community_mediaRequired;

  /// Shown when the user picks more media than one post can hold
  ///
  /// In en, this message translates to:
  /// **'A post holds up to {count} photos and videos.'**
  String community_mediaLimit(int count);

  /// Shown when the camera or the library picker fails on the create-post screen
  ///
  /// In en, this message translates to:
  /// **'That couldn\'t be added. Please try again.'**
  String get community_mediaError;

  /// Shown while a composed post's media is uploading
  ///
  /// In en, this message translates to:
  /// **'Sharing your post…'**
  String get community_posting;

  /// Shown when a post has been added to the community feed
  ///
  /// In en, this message translates to:
  /// **'Your post has been shared.'**
  String get community_postSuccess;

  /// Shown when creating a post fails
  ///
  /// In en, this message translates to:
  /// **'Your post couldn\'t be shared. Please try again.'**
  String get community_postError;

  /// The title of the screen showing a single post and its comments
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get community_postTitle;

  /// Shown on the post screen when the post has been removed
  ///
  /// In en, this message translates to:
  /// **'This post is no longer available.'**
  String get community_postMissing;

  /// The heading above a post's comments
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get community_comments;

  /// Shown in place of a post's comments when it has none
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Start the conversation.'**
  String get community_commentsEmpty;

  /// Shown when loading a post's comments fails
  ///
  /// In en, this message translates to:
  /// **'The comments couldn\'t be loaded. Please try again.'**
  String get community_commentsLoadError;

  /// The placeholder of the comment field under a post
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get community_commentHint;

  /// The label of the button that posts a written comment
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get community_commentSend;

  /// Shown when adding a comment fails
  ///
  /// In en, this message translates to:
  /// **'Your comment couldn\'t be added. Please try again.'**
  String get community_commentError;

  /// Shown when liking or unliking a post fails
  ///
  /// In en, this message translates to:
  /// **'Your like couldn\'t be saved. Please try again.'**
  String get community_likeError;

  /// The accessibility label of the ellipsis button on a community post that opens its options
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get community_more;

  /// The heading of the sheet behind a post's ellipsis
  ///
  /// In en, this message translates to:
  /// **'Post options'**
  String get community_options;

  /// The option in a post's sheet that flags it for the event team
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get community_report;

  /// Shown in place of the report option for a post that has already been flagged
  ///
  /// In en, this message translates to:
  /// **'Already reported'**
  String get community_reportedAlready;

  /// The button that closes a community sheet without doing anything
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get community_cancel;

  /// The heading of the sheet that confirms reporting a post
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to report this post?'**
  String get community_reportTitle;

  /// Explains what reporting a post does
  ///
  /// In en, this message translates to:
  /// **'The event team will review it. You can add a note about what\'s wrong with it.'**
  String get community_reportDescription;

  /// The placeholder of the optional note on the report-post sheet
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this? (optional)'**
  String get community_reportReasonHint;

  /// The button that confirms reporting a post
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get community_reportConfirm;

  /// Shown when a post has been reported
  ///
  /// In en, this message translates to:
  /// **'Thanks — this has been reported.'**
  String get community_reportSuccess;

  /// Shown when reporting a post fails
  ///
  /// In en, this message translates to:
  /// **'This couldn\'t be reported. Please try again.'**
  String get community_reportError;

  /// Fallback banner text over the event's featured image when the event has no slogan. {day} is a locale-formatted day-of-event token (an English ordinal like "2nd"; a plain number in Turkish).
  ///
  /// In en, this message translates to:
  /// **'Enjoy the {day} day of {eventName}'**
  String landing_enjoyDay(String day, String eventName);
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
