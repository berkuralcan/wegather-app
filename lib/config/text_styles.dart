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
    height: 1.2,
  );

  static const weGatherSmallTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0x9EFAFAFA),
    height: 1.2,
  );

  static const weGatherParagraphTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xE0FAFAFA),
    height: 1.2, // 19.2px line-height / 16px font size
  );

  static const weGatherMediumHeaderTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color(0xE0FAFAFA),
    height: 1.2,
  );

  static const weGatherHeaderTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppConfig.labelTextColor,
    height: 1.2,
  );

  /* Used for the day picker in the calendar: */

  static const weGatherSmallHeaderTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color.fromARGB(230, 250, 250, 250),
    height: 1.2,
  );

  static const weGatherSmallHeaderTextStyleUnselected = TextStyle(
    fontFamily: "Inter",
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color.fromARGB(48, 250, 250, 250),
    height: 1.2,
  );

  static const weGatherTitleTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: Color.fromARGB(228, 250, 250, 250),
    shadows: [
      Shadow(
        color: Color.fromRGBO(170, 170, 170, 0.587),
        offset: Offset(0, 0),
        blurRadius: 20,
      ),
    ],
  );

  /// Rich-text headings. Levels 1–3 are the only ones the admin panel can
  /// author. Sized between the 16px paragraph and the 20px app bar title, so an
  /// H1 opens a section without competing with the page title above it.
  static const weGatherHeading1TextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Color(0xE0FAFAFA),
    height: 1.2,
  );

  static const weGatherHeading2TextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xE0FAFAFA),
    height: 1.2,
  );

  static const weGatherHeading3TextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xE0FAFAFA),
    height: 1.2,
  );

  static const weGatherLabelTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppConfig.labelTextColor,
  );

  /// The label of a tab in a pill selector, as it reads when selected — an
  /// unselected one is the same style in [AppConfig.colorTertiary].
  static const weGatherTabTextStyle = TextStyle(
    fontFamily: "Inter",
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0xE0FAFAFA),
    height: 1.2,
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
    fontWeight: FontWeight.w600,
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
