import 'package:flutter/material.dart';
import 'package:wegather_app/containers/circular_liquid_button.dart';
import 'package:wegather_app/functions/global_functions.dart';

Widget buildSocialMediaButtons(dynamic socialMedia) {
  final socialMediaConfig = [
    {
      'key': 'instagram',
      'platform': 'instagram',
      'icon': 'assets/icons/instagram.png',
      'getValue': () => socialMedia?.instagram?.toString(),
      "iconWidth": 22.51,
      "iconHeight": 22.51,
    },
    {
      'key': 'facebook',
      'platform': 'facebook',
      'icon': 'assets/icons/facebook.png',
      'getValue': () => socialMedia?.facebook?.toString(),
      "iconWidth": 12.5,
      "iconHeight": 26.26,
    },
    {
      'key': 'twitter',
      'platform': 'twitter',
      'icon': 'assets/icons/twitter.png',
      'getValue': () => socialMedia?.twitter?.toString(),
      "iconWidth": 36.21,
      "iconHeight": 25.01,
    },
    {
      'key': 'linkedIn',
      'platform': 'linkedin',
      'icon': 'assets/icons/linkedin.png',
      'getValue': () => socialMedia?.linkedIn?.toString(),
      "iconWidth": 25.99,
      "iconHeight": 25.9,
    },
  ];

  List<Widget> buttons = [];

  for (var config in socialMediaConfig) {
    final getValue = config['getValue'] as String? Function();
    final value = getValue();

    if (value != null && value.isNotEmpty) {
      buttons.add(
        CircularLiquidButton(
          onTap: () {
            navigateToSocialMedia(config['platform']! as String, value);
          },
          child: Image.asset(config['icon']! as String, width: config['iconWidth'] as double, height: config['iconHeight'] as double),
        ),
      );
    }
  }

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: buttons
        .map(
          (button) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: button,
          ),
        )
        .toList(),
  );
}
