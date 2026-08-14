// The configuration file for the app. Change the values here for white-labeling.

import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = "WeGather";
  static const String backgroundImage =
      "assets/images/app-default-background.jpg";
  static const LinearGradient appBackgroundGradient = LinearGradient(
    colors: [Color(0xFF0034A1), Color(0x00000000), Color(0xE6000000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const String appLogo = "assets/images/app-default-logo.png";
  static const String noProfileImage = "assets/images/no-profile-image.png";
  static const String cameraIcon = "assets/icons/profile_camera.png";
  static const String companyName = "WeGather";
  static const String defaultEventName = "WeGather Event";

  /* Set Login Page Details Here */

  static const Color loginPageFormBorderColor = Color.fromARGB(
    16,
    150,
    150,
    150,
  );
  static const Color loginPageFormBgColor = Color.fromARGB(32, 150, 150, 150);

  /* Text Colors */

  static const Color labelTextColor = Color.fromARGB(235, 250, 250, 250);
  static const Color secondaryTextColor = Color.fromARGB(174, 250, 250, 250);
  static const Color colorTertiary = Color(0x7AFAFAFA);
  static const Color accentColor = Color(0xFFB5E4FF);
  static const Color emphasisColor = Color(0xFF4DB9FB);
  static const Color textColorPrimary = Color(0xE0FAFAFA);

  /* Icon Colors */

  static const Color lightIconColor = Color.fromARGB(245, 255, 255, 255);
  static const Color menuIconColor = Color(0xFFB5E4FF);

  /* Decor Colors */

  static const Color dividerNonOpaqueColor = Color(0x14C7C7C7);

  /// The fill behind a group of controls, such as the track a pill selector's
  /// tabs sit in.
  static const Color primaryFillColor = Color(0x52969696);

  /* Colors that will be used for tips, and large tappable menu areas. */

  static const Color tipColor = Color.fromARGB(32, 150, 150, 150);

  static const LinearGradient menuIconBackgroundColor = LinearGradient(
    colors: [Color(0xFF4D8AF7), Color(0xFF50A7DD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient appDarkBackgroundGradient = LinearGradient(
    colors: [Color(0xFF09245D), Color(0xFF0034A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonPrimaryGradient = LinearGradient(
    colors: [Color(0xFF6FA3FF), Color(0xFF4DB9FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// [buttonPrimaryGradient] at 30% opacity, laid left to right: the fill of a
  /// control that is active without being a button in its own right, like the
  /// selected tab of a pill selector.
  static const LinearGradient activeButtonFillGradient = LinearGradient(
    colors: [Color(0x4D6FA3FF), Color(0x4D4DB9FB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient buttonEmphasisGradient = LinearGradient(
    colors: [Color(0xFF2CADE3), Color(0xFF4DB9FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bottomNavBarSelectedIconColor = LinearGradient(
    colors: [Color(0xFF6B8FD3), Color(0xFF6B8FD3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fadedBackgroundGradient = LinearGradient(
    colors: [
      Color.fromRGBO(111, 163, 255, 0.16),
      Color.fromRGBO(77, 185, 251, 0.16),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// A flat primary-blue tint laid over the event's featured image so light
  /// captions stay legible on top of it. Both stops are the same colour
  /// (`rgba(0, 135, 219, 0.40)`), so it reads as a solid overlay rather than a
  /// fade — modelled as a gradient to drop straight into a `BoxDecoration`.
  static const LinearGradient imageOverlayGradient = LinearGradient(
    colors: [Color(0x660087DB), Color(0x660087DB)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  // TODO - Remove this.
  // Icons that may change from app to app.

  static const String qrLogo = "assets/icons/qr-code.svg";
  static const String mapPinIcon = "assets/icons/map-pin.svg";
}
