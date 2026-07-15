import 'package:flutter/material.dart';
import 'package:wegather_app/config/text_styles.dart';

Widget buildTaggedPhotos(dynamic profile) {
  return Container(
    child: SizedBox(
      height: 400, // Increased height to make scroll effect visible
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              "Kullanıcının etiketlenmiş paylaşımları burada olacak.", 
              style: AppTextStyles.lightButtonTextStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}