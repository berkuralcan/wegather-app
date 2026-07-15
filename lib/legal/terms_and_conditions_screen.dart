import 'package:flutter/material.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';

/// A static Terms and Services page.
///
/// The content below is placeholder (Lorem Ipsum) copy — replace the sections
/// in [_termsSections] with the real legal text when it is available.
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CustomAppBar(title: l10n.terms_title),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _termsSections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            final section = _termsSections[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.title, style: AppTextStyles.smallTitleTextStyle),
                const SizedBox(height: 8),
                Text(
                  section.body,
                  style: AppTextStyles.weGatherPrimaryTextStyle,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TermsSection {
  const _TermsSection(this.title, this.body);

  final String title;
  final String body;
}

const List<_TermsSection> _termsSections = [
  _TermsSection(
    '1. Introduction',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod '
        'tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim '
        'veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex '
        'ea commodo consequat.',
  ),
  _TermsSection(
    '2. Use of the Service',
    'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum '
        'dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non '
        'proident, sunt in culpa qui officia deserunt mollit anim id est '
        'laborum.',
  ),
  _TermsSection(
    '3. Accounts and Security',
    'Sed ut perspiciatis unde omnis iste natus error sit voluptatem '
        'accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae '
        'ab illo inventore veritatis et quasi architecto beatae vitae dicta '
        'sunt explicabo.',
  ),
  _TermsSection(
    '4. Privacy',
    'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut '
        'fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem '
        'sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor '
        'sit amet.',
  ),
  _TermsSection(
    '5. Limitation of Liability',
    'At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis '
        'praesentium voluptatum deleniti atque corrupti quos dolores et quas '
        'molestias excepturi sint occaecati cupiditate non provident.',
  ),
  _TermsSection(
    '6. Changes to These Terms',
    'Et harum quidem rerum facilis est et expedita distinctio. Nam libero '
        'tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo '
        'minus id quod maxime placeat facere possimus, omnis voluptas assumenda '
        'est, omnis dolor repellendus.',
  ),
  _TermsSection(
    '7. Contact',
    'Temporibus autem quibusdam et aut officiis debitis aut rerum '
        'necessitatibus saepe eveniet ut et voluptates repudiandae sint et '
        'molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente '
        'delectus.',
  ),
];
