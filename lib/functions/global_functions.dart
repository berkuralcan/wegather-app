import 'package:url_launcher/url_launcher.dart';

/// Whether [url] already says which protocol to open it with.
final _scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://');

Future<void> navigateToUrl(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(
    uri,
    mode: LaunchMode.inAppBrowserView,
    browserConfiguration: const BrowserConfiguration(showTitle: true),
  );
}

/// Opens [url] outside the app, so an address a native app claims — an
/// Instagram or LinkedIn profile — opens there rather than in the in-app
/// browser, falling back to the browser when that app isn't installed.
Future<void> navigateToApp(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Opens a site whose address may have been entered without a scheme
/// ("wegather.app") as readily as one with it.
Future<void> navigateToWebsite(String url) =>
    navigateToUrl(_scheme.hasMatch(url) ? url : 'https://$url');

/// Starts a blank message to [email] in whichever mail app the device uses.
Future<void> navigateToEmail(String email) async {
  await launchUrl(Uri(scheme: 'mailto', path: email));
}

/// The address of [handle] on [platform]. Handles are stored bare ("wegather"),
/// but a profile that was filled in with a whole URL, or with the leading `@`,
/// is understood too.
String socialMediaUrl(String platform, String handle) {
  if (_scheme.hasMatch(handle)) return handle;
  final name = handle.startsWith('@') ? handle.substring(1) : handle;
  switch (platform) {
    case "linkedin":
      return "https://www.linkedin.com/in/$name";
    case "twitter":
      return "https://x.com/$name";
    case "instagram":
      return "https://www.instagram.com/$name";
    case "facebook":
      return "https://www.facebook.com/$name";
  }
  return name;
}

/// Opens [handle]'s profile on [platform], in that network's app when it is
/// installed.
void navigateToSocialMedia(String platform, String handle) {
  navigateToApp(socialMediaUrl(platform, handle));
}
