import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wegather_app/community_widgets/community_media_carousel.dart';
import 'package:wegather_app/l10n/app_localizations.dart';
import 'package:wegather_app/models/community_model.dart';
import 'package:wegather_app/models/gallery_media.dart';
import 'package:wegather_app/providers/community_providers.dart';
import 'package:wegather_app/screens/post_detail_screen.dart';

/// The screen is layout over three streams, so these cover what it decides: how
/// a thread reads, what stands in for one that is empty or for a post that has
/// been taken down, and that the author's name leads to their profile.
void main() {
  const postId = 'post-1';

  CommunityPost post({
    String caption = 'Lorem ipsum.',
    List<CommunityMedia> media = const [],
    int likeCount = 3,
    int commentCount = 1,
  }) => CommunityPost(
    id: postId,
    authorId: 'u1',
    authorName: 'Jane Doe',
    media: media,
    caption: caption,
    mentionedUserIds: const [],
    likeCount: likeCount,
    commentCount: commentCount,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    updatedAt: null,
    isReported: false,
  );

  CommunityComment comment({
    String id = 'c1',
    String authorName = 'John Smith',
    String content = 'Nicely put.',
  }) => CommunityComment(
    id: id,
    postId: postId,
    eventId: 'e1',
    authorId: 'u2',
    authorName: authorName,
    content: content,
    mentionedUserIds: const [],
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    isReported: false,
  );

  // CustomAppBar asks `context.canPop()`, and the screen pushes profiles by
  // route name, so both need a router above them.
  Widget wrap({
    required CommunityPost? loadedPost,
    List<CommunityComment> comments = const [],
  }) => ProviderScope(
    overrides: [
      communityPostProvider(
        postId,
      ).overrideWith((ref) => Stream.value(loadedPost)),
      communityCommentsProvider(
        postId,
      ).overrideWith((ref) => Stream.value(comments)),
      communityPostLikedProvider(
        postId,
      ).overrideWith((ref) => Stream.value(false)),
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const PostDetailScreen(postId: postId),
          ),
          GoRoute(
            path: '/profile/:profileId',
            name: 'profile',
            builder: (_, state) => Scaffold(
              body: Text('profile:${state.pathParameters['profileId']}'),
            ),
          ),
        ],
      ),
    ),
  );

  testWidgets('shows the post above its comments', (tester) async {
    await tester.pumpWidget(
      wrap(
        loadedPost: post(),
        comments: [
          comment(),
          comment(id: 'c2', content: 'Agreed.'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // A caption and a comment are drawn as spans, mentions picked out, so both
    // are found inside a RichText rather than as a Text of their own.
    expect(find.text('Lorem ipsum.', findRichText: true), findsOne);
    expect(find.text('Nicely put.', findRichText: true), findsOne);
    expect(find.text('Agreed.', findRichText: true), findsOne);
    // The like and comment tallies come off the post, not off the thread.
    expect(find.text('3'), findsOne);
    expect(find.text('1'), findsOne);
    // The author of the post and the author of each comment.
    expect(find.text('Jane Doe'), findsOne);
    expect(find.text('John Smith'), findsExactly(2));
  });

  testWidgets('says so when nobody has commented yet', (tester) async {
    await tester.pumpWidget(wrap(loadedPost: post(commentCount: 0)));
    await tester.pumpAndSettle();

    expect(find.text('No comments yet. Start the conversation.'), findsOne);
  });

  testWidgets('says so when the post is gone', (tester) async {
    await tester.pumpWidget(wrap(loadedPost: null));
    await tester.pumpAndSettle();

    expect(find.text('This post is no longer available.'), findsOne);
    // Nothing to comment on, so there is nothing to comment with either.
    expect(find.text('Add a comment…'), findsNothing);
  });

  testWidgets('carries a carousel for a post with several media', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        loadedPost: post(
          media: const [
            CommunityMedia(
              url: 'https://x/1.jpg',
              type: GalleryMediaType.photo,
            ),
            CommunityMedia(
              url: 'https://x/2.jpg',
              type: GalleryMediaType.photo,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CommunityMediaCarousel), findsOne);
    expect(find.text('1/2'), findsOne);
  });

  testWidgets('opens the profile of whoever is tapped', (tester) async {
    await tester.pumpWidget(wrap(loadedPost: post(), comments: [comment()]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jane Doe'));
    await tester.pumpAndSettle();
    expect(find.text('profile:u1'), findsOne);
  });
}
