import 'package:flutter/material.dart';
import 'package:wegather_app/containers/liquid_container.dart';
import 'package:wegather_app/config/text_styles.dart';

Widget buildProfileInformation(dynamic profile) {
  return LiquidContainer(
    child: Container(
      height: 400, // Increased height to make scroll effect visible
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              "Profil bilgileri burada görüntülenecek.", 
              style: AppTextStyles.lightButtonTextStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}