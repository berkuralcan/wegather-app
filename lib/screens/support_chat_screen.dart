import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../layouts/wegather_appbar.dart';
import '../models/support_model.dart';
import '../providers/access_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/support_providers.dart';
import '../reusableWidgets/liquid_snackbar.dart';
import '../services/support_service.dart';
import '../support_widgets/support_status_chip.dart';

/// One support conversation: what has been said, and a field to say more.
///
/// Both the request and its messages are streamed, so an admin's reply arrives
/// while the screen is open and a thread the admin resolves says so without a
/// refresh. [initialRequest] is the copy the list already had, drawn until the
/// stream's first value lands — the same trick the post screen uses to avoid
/// opening on a spinner over something the user could already see.
///
/// This is a single-language conversation by design: no localised side-by-side
/// anything, just plain text between two people.
class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({
    super.key,
    required this.requestId,
    this.initialRequest,
  });

  final String requestId;
  final SupportRequest? initialRequest;

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  /// The gutter the thread and its composer keep from the edge, matching the
  /// post screen so a conversation looks the same wherever it happens.
  static const double _inset = 16;

  final TextEditingController _message = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _sending = false;

  /// How many messages were on screen at the last build. A thread that has grown
  /// scrolls to the newest line; a rebuild that didn't add one (a status change,
  /// say) leaves the user where they were reading.
  int _lastCount = 0;

  @override
  void dispose() {
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _showError(String message) {
    showLiquidSnackBar(
      context,
      message,
      icon: Icons.error,
      iconColor: Colors.red,
    );
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send(SupportRequest request) async {
    if (_sending) return;
    final content = _message.text.trim();
    if (content.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final eventId = ref.read(selectedEventIdProvider);
    final user = ref.read(currentUserProvider);
    if (eventId == null || user == null) {
      _showError(l10n.support_sendError);
      return;
    }

    setState(() => _sending = true);
    // Cleared up front so the thread reads as sent; put back if the write fails,
    // which is kinder than making someone retype a long message.
    _message.clear();
    try {
      final profile = await ref.read(currentProfileProvider.future);
      await ref
          .read(supportServiceProvider)
          .sendMessage(
            eventId: eventId,
            requestId: request.id,
            senderId: user.uid,
            senderName: profile?.name ?? user.displayName ?? '',
            message: content,
            // The status as it stands: sending into a resolved thread reopens it.
            currentStatus: request.status,
          );
    } catch (_) {
      if (!mounted) return;
      _message.text = content;
      _showError(l10n.support_sendError);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final requestState = ref.watch(supportRequestProvider(widget.requestId));
    // The streamed copy wins; the list's copy stands in until it lands.
    final request = requestState.valueOrNull ?? widget.initialRequest;

    return Scaffold(
      appBar: CustomAppBar(title: l10n.support_title),
      body: SafeArea(
        top: false,
        child: request == null
            ? _buildAbsent(l10n, requestState)
            : _buildBody(l10n, request),
      ),
    );
  }

  /// What stands in for a request there is nothing to show for: still arriving,
  /// or gone from Firestore.
  Widget _buildAbsent(
    AppLocalizations l10n,
    AsyncValue<SupportRequest?> state,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _CenteredText(
      state.hasError ? l10n.support_loadError : l10n.support_requestMissing,
    );
  }

  Widget _buildBody(AppLocalizations l10n, SupportRequest request) {
    final messages = ref.watch(supportMessagesProvider(widget.requestId));
    final list = messages.valueOrNull ?? const <SupportMessage>[];

    if (list.length != _lastCount) {
      _lastCount = list.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }

    return Column(
      children: [
        _SubjectHeader(request: request),
        Expanded(
          child: messages.isLoading && list.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
              ? _CenteredText(l10n.support_chatEmpty)
              : ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.all(_inset),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _MessageBubble(message: list[index]),
                ),
        ),
        // A resolved thread is not locked — saying so, right where the user is
        // about to type, is better than a disabled field they can't explain.
        if (request.isResolved)
          Padding(
            padding: const EdgeInsets.fromLTRB(_inset, 0, _inset, 8),
            child: Text(
              l10n.support_resolvedNotice,
              textAlign: TextAlign.center,
              style: AppTextStyles.weGatherSmallTextStyle,
            ),
          ),
        _Composer(
          controller: _message,
          isSending: _sending,
          onSend: () => _send(request),
        ),
      ],
    );
  }
}

/// The subject of the request, kept above the thread: a conversation that has
/// run for a while shouldn't make the user scroll back to remember what they
/// asked about.
class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({required this.request});

  final SupportRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_SupportChatScreenState._inset),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppConfig.dividerNonOpaqueColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.subject,
            style: AppTextStyles.weGatherSmallHeaderTextStyle,
          ),
          const SizedBox(height: 8),
          SupportStatusChip(request: request),
        ],
      ),
    );
  }
}

/// One message, on its own side of the thread: the participant's to the right in
/// the app's gradient, the support team's to the left on the flat fill.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final SupportMessage message;

  /// Time alone for today's messages; day and time once that's ambiguous.
  String _formatWhen(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final materialL10n = MaterialLocalizations.of(context);
    final today = DateTime.now();
    final sameDay =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final time = materialL10n.formatTimeOfDay(TimeOfDay.fromDateTime(date));
    return sameDay ? time : '${materialL10n.formatShortDate(date)} $time';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fromSupport = message.isFromSupport;
    final when = _formatWhen(context, message.createdAt);

    return Row(
      mainAxisAlignment: fromSupport
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: fromSupport
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  // The team's replies are the flat fill so the user's own
                  // messages stay the coloured ones — the arrangement every
                  // chat uses, and the one that makes a glance tell you who
                  // spoke last.
                  gradient: fromSupport ? null : AppConfig.buttonPrimaryGradient,
                  color: fromSupport ? AppConfig.tipColor : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(fromSupport ? 4 : 16),
                    bottomRight: Radius.circular(fromSupport ? 16 : 4),
                  ),
                ),
                child: Text(
                  message.message,
                  style: AppTextStyles.weGatherPrimaryTextStyle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                // Admin replies are attributed to the support team, never to the
                // individual who typed them.
                when.isEmpty
                    ? (fromSupport ? l10n.support_teamName : l10n.support_you)
                    : '${fromSupport ? l10n.support_teamName : l10n.support_you} · $when',
                style: AppTextStyles.weGatherSmallTextStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The message field and its send button — the community composer's shape, so
/// writing a message feels the same wherever the app asks for one.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(_SupportChatScreenState._inset),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppConfig.dividerNonOpaqueColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              // Grows with a longer message, then scrolls inside itself rather
              // than pushing the thread off the screen.
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: controller,
                enabled: !isSending,
                maxLength: SupportService.messageMaxLength,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.weGatherParagraphTextStyle,
                cursorColor: AppConfig.emphasisColor,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                  hintText: l10n.support_chatHint,
                  hintStyle: AppTextStyles.weGatherParagraphTextStyle.copyWith(
                    color: AppConfig.colorTertiary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: _SupportChatScreenState._inset),
          _SendButton(isSending: isSending, onPressed: onSend),
        ],
      ),
    );
  }
}

/// The send button: the app's gradient in a circle, with a spinner in place of
/// its glyph while the message is being written.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.isSending, required this.onPressed});

  final bool isSending;
  final VoidCallback onPressed;

  static const double _size = 36;
  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.support_chatSend,
      child: GestureDetector(
        onTap: isSending ? null : onPressed,
        child: Container(
          width: _size,
          height: _size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: AppConfig.buttonPrimaryGradient,
            shape: BoxShape.circle,
          ),
          child: isSending
              ? const SizedBox(
                  width: _iconSize,
                  height: _iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppConfig.lightIconColor,
                  ),
                )
              : SvgPicture.asset(
                  'assets/icons/send.svg',
                  width: _iconSize,
                  height: _iconSize,
                  colorFilter: const ColorFilter.mode(
                    AppConfig.lightIconColor,
                    BlendMode.srcIn,
                  ),
                ),
        ),
      ),
    );
  }
}

class _CenteredText extends StatelessWidget {
  const _CenteredText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.weGatherParagraphTextStyle,
        ),
      ),
    );
  }
}
