// The configuration file for the app. Change the values here for white-labeling.

import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = "WeGather";
  static const String backgroundImage = "assets/images/app-default-background.jpg";
  static const LinearGradient appBackgroundGradient = LinearGradient(
    colors: [
      Color(0xFF0034A1), 
      Color(0x00000000),
      Color(0xE6000000),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const String appLogo = "assets/images/app-default-logo.png";
  static const String noProfileImage = "assets/images/no-profile-image.png";
  static const String cameraIcon = "assets/icons/profile_camera.png";
  static const String companyName = "WeGather";
  static const String defaultEventName = "WeGather Event";

  /* Set Login Page Details Here */

  static const Color loginPageFormBorderColor = Color.fromARGB(16, 150, 150, 150);
  static const Color loginPageFormBgColor = Color.fromARGB(32, 150, 150, 150);
  static const Color colorTertiary = Color(0x7AFAFAFA);
  static const Color accentColor = Color(0xFFB5E4FF);

  static const Color menuIconColor = Color(0xFFB5E4FF);
  static const LinearGradient menuIconBackgroundColor = LinearGradient(
    colors: [
      Color(0xFF4D8AF7),
      Color(0xFF50A7DD),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );


  static const LinearGradient buttonPrimaryGradient = LinearGradient(
    colors: [
      Color(0xFF6FA3FF),
      Color(0xFF4DB9FB),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bottomNavBarSelectedIconColor = LinearGradient(
    colors: [
      Color(0xFF6B8FD3),
      Color(0xFF6B8FD3),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

}