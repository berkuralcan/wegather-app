import 'package:flutter/material.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';

/// A reusable, scrollable plain-text page.
///
/// Shows [title] in the app bar and [body] as a paragraph beneath it. Use it
/// for any read-only text screen (KVKK, Terms, About, privacy notices, etc.).
/// Separate paragraphs in [body] with blank lines (`\n\n`).
class WgTextDisplayer extends StatelessWidget {
  const WgTextDisplayer({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(body, style: AppTextStyles.weGatherParagraphTextStyle),
        ),
      ),
    );
  }
}
