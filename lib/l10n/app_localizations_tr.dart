// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get helloWorld => 'Merhaba Dünya!';

  @override
  String get title => 'WeGather - Toplanmanın Yeni Yolu';

  @override
  String get login_emailAddress => 'E-posta Adresi';

  @override
  String get login_password => 'Şifre';

  @override
  String get login_login => 'Giriş Yap';

  @override
  String get login_invalidCredentials => 'Kullanıcı adı veya şifre hatalı';

  @override
  String get login_loading => 'Giriş yapılıyor...';

  @override
  String get login_networkError =>
      'Ağ hatası oluştu. Lütfen daha sonra tekrar deneyin.';

  @override
  String get homeIcon_my_profile => 'Profilim';

  @override
  String get homeIcon_my_qr_code => 'QR Kodum';

  @override
  String get homeIcon_event_program => 'Etkinlik Programı';

  @override
  String get homeIcon_flight_info => 'Uçuş Bilgilerim';

  @override
  String get homeIcon_transportation => 'Ulaşım';

  @override
  String get homeIcon_stay_info => 'Konaklama';

  @override
  String get homeIcon_documents => 'Dokümanlar';

  @override
  String get homeIcon_announcements => 'Duyurular';

  @override
  String get homeIcon_support => 'Destek';

  @override
  String get profile_title => 'Profil';

  @override
  String get profile_change_profile_photo => 'Profil Fotoğrafını Değiştir';

  @override
  String get profile_take_photo => 'Yeni Fotoğraf Çek';

  @override
  String get profile_choose_from_gallery => 'Galeriden Seç';
}
