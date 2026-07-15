import 'package:flutter/material.dart';
import 'package:wegather_app/text_widgets/wg_text_displayer.dart';

/// KVKK (Turkish personal data protection) notice.
///
/// The [_kvkkText] below is placeholder copy — replace it with the real
/// KVKK text when it is available.
class KvkkScreen extends StatelessWidget {
  const KvkkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WgTextDisplayer(title: 'KVKK', body: _kvkkText);
  }
}

const String _kvkkText =
    'A detailed paragraph about the user’s background. Lorem ipsum dolor '
    'sit amet. There should be a word/character limit. A detailed paragraph '
    'about the user’s background. Lorem ipsum dolor sit amet.\n\n'
    'There should be a word/character limit. A detailed paragraph about the '
    'user’s background. Lorem ipsum dolor sit amet.\n\n'
    'There should be a word/character limit. A detailed paragraph about the '
    'user’s background. Lorem ipsum dolor sit amet.\n\n'
    'There should be a word/character limit. A detailed paragraph about the '
    'user’s background. Lorem ipsum dolor sit amet.\n\n'
    'There should be a word/character limit. A detailed paragraph about the '
    'user’s background. Lorem ipsum dolor sit amet. There should be a '
    'word/character limit. A detailed paragraph about the user’s '
    'background. Lorem ipsum dolor sit amet.\n\n'
    'There should be a word/character limit.';
