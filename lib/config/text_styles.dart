import 'package:flutter/material.dart';
import 'package:wegather_app/config/app_config.dart';

class AppTextStyles {
  static const menuIconTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0xE0FAFAFA),
  );

  static const weGatherPrimaryTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xE0FAFAFA),
  );

  static const weGatherParagraphTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xE0FAFAFA),
    height: 1.2, // 19.2px line-height / 16px font size
  );

  static const weGatherTextButtonStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppConfig.colorTertiary,
  );

  static const weGatherColoredTextButtonStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppConfig.accentColor,
  );

  static const appBarTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 20,
    color: Color(0xE0FAFAFA),
    height: 1.2, // 24px line-height / 20px font size
    fontWeight: FontWeight.w500,
  );

  // Older ones

  static const smallTitleTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 20,
    letterSpacing: 3,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const smallDescriptionTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static const lightButtonTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );
}

class FlutterTextStyles {
  // When needed fill this with the default text styles, heading1, heading2, etc.
}
