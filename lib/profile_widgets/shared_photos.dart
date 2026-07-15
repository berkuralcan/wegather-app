import 'package:flutter/material.dart';
import 'package:wegather_app/config/text_styles.dart';

Widget buildSharedPhotos(dynamic profile) {
  return Container(
    child: SizedBox(
      height: 400, // Increased height to make scroll effect visible
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              "Paylaşılanlar modülü burada olacak.", 
              style: AppTextStyles.lightButtonTextStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}