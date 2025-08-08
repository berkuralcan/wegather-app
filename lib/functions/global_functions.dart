import 'package:url_launcher/url_launcher.dart';

Future<void> navigateToUrl(String url) async{
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.inAppBrowserView, browserConfiguration: const BrowserConfiguration(showTitle: true));
}

void navigateToSocialMedia(String platform, String url){
  switch(platform){
    case "linkedin":
      final uri = "https://www.linkedin.com/in/$url";
      navigateToUrl(uri);
      break;
    case "twitter":
      final uri = "https://x.com/$url";
      navigateToUrl(uri);
      break;
    case "instagram":
      final uri = "https://www.instagram.com/$url";
      navigateToUrl(uri);
      break;
    case "facebook":
      final uri = "https://www.facebook.com/$url";
      navigateToUrl(uri);
      break;
  }
}