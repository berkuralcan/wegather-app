import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../community_widgets/community_card.dart';
import '../config/text_styles.dart';
import '../global_widgets/floating_add_button.dart';
import '../l10n/app_localizations.dart';
import '../layouts/wegather_appbar.dart';
import '../providers/community_providers.dart';

/// The community feed: the posts attendees share, newest first, in a list that
/// loads a page at a time as it's scrolled. A floating "Create Post" button
/// hovers over it, and an empty feed invites the first post.
///
/// Reads are paged by [communityFeedProvider] for performance — the list is a
/// lazy [ListView.builder], so only the cards on screen are built, and the next
/// page is fetched a little before the bottom is reached so scrolling rarely
/// stalls.
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  static const double _horizontalInset = 16;

  /// How far from the bottom to start fetching the next page — about a
  /// screenful, so the page is usually in hand by the time it's needed.
  static const double _loadMoreThreshold = 600;

  /// Room under the last card for the floating button to clear it.
  static const double _bottomInset = 96;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      // The controller is a no-op while a page is already loading or the feed
      // is exhausted, so calling it on every scroll frame is safe.
      ref.read(communityFeedProvider.notifier).loadMore();
    }
  }

  void _onCreatePost() {
    // The composer refreshes the feed itself when a post lands, so there is
    // nothing to do with what comes back.
    context.pushNamed('createPost');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feed = ref.watch(communityFeedProvider);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.community_title),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            _buildFeed(context, l10n, feed),
            // The floating button, centred and spaced 20px off the bottom
            // (above the safe-area inset).
            Positioned(
              left: 0,
              right: 0,
              bottom: 20 + MediaQuery.paddingOf(context).bottom,
              child: Center(
                child: FloatingAddButton(
                  label: l10n.community_createPost,
                  onPressed: _onCreatePost,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed(
    BuildContext context,
    AppLocalizations l10n,
    CommunityFeedState feed,
  ) {
    if (feed.isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (feed.error != null) {
      return _CenteredText('${l10n.community_loadError}\n\n${feed.error}');
    }
    if (feed.isEmpty) {
      return _CenteredText(l10n.community_empty);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(communityFeedProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _controller,
        padding: const EdgeInsets.fromLTRB(
          _horizontalInset,
          16,
          _horizontalInset,
          _bottomInset,
        ),
        // One extra row for the foot spinner while the next page loads.
        itemCount: feed.posts.length + (feed.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index >= feed.posts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = feed.posts[index];
          return CommunityCard(
            post: post,
            // The post it already has goes along with the push, so the post's
            // screen opens on the post rather than on a spinner.
            onTap: () => context.pushNamed(
              'post',
              pathParameters: {'postId': post.id},
              extra: post,
            ),
            onAuthorTap: post.authorId.isEmpty
                ? null
                : () => context.pushNamed(
                    'profile',
                    pathParameters: {'profileId': post.authorId},
                  ),
          );
        },
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
