import 'package:flutter/material.dart';
import 'package:wegather_app/auth_services.dart';
import 'package:wegather_app/config/text_styles.dart';

Widget buildProfileInformation(dynamic profile) {
  return Container(
    child: SizedBox(
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
          const SizedBox(height: 24),
          // TODO: Temporary logout button
          ElevatedButton.icon(
            onPressed: () => AuthService().signOut(),
            icon: const Icon(Icons.logout),
            label: const Text("Çıkış Yap"),
          ),
        ],
      ),
    ),
  );
}
