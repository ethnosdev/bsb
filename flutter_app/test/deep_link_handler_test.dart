import 'package:bsb/infrastructure/deep_link_handler.dart';
import 'package:bsb/ui/playlists/playlist_share_handler.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockTabManager extends Fake implements TabManager {
  int? lastBookId;
  int? lastChapter;
  String? lastSectionHeading;
  int? lastTargetVerse;
  int openTabCallCount = 0;

  @override
  void openTab(
    int bookId,
    int chapter, [
    String? sectionHeading,
    int? targetVerse,
  ]) {
    lastBookId = bookId;
    lastChapter = chapter;
    lastSectionHeading = sectionHeading;
    lastTargetVerse = targetVerse;
    openTabCallCount++;
  }
}

class MockPlaylistShareHandler extends Fake implements PlaylistShareHandler {
  Uri? lastPlaylistUri;
  Uri? lastFileUri;

  @override
  Future<void> handlePlaylistUri(BuildContext context, Uri uri) async {
    lastPlaylistUri = uri;
  }

  @override
  Future<void> handleFileUri(BuildContext context, Uri uri) async {
    lastFileUri = uri;
  }
}

void main() {
  late MockTabManager mockTabManager;
  late MockPlaylistShareHandler mockPlaylistShareHandler;
  late DeepLinkHandler handler;

  setUp(() {
    mockTabManager = MockTabManager();
    mockPlaylistShareHandler = MockPlaylistShareHandler();
    handler = DeepLinkHandler(
      playlistShareHandler: mockPlaylistShareHandler,
      tabManager: mockTabManager,
    );
  });

  Widget buildTestApp() {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const Scaffold(body: Text('SubPage')),
                    ),
                  );
                },
                child: const Text('Open SubPage'),
              ),
            ),
          );
        },
      ),
    );
  }

  group('DeepLinkHandler - Bible deep links', () {
    testWidgets('opens chapter without verse (bsb://bible/43/3)', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final context = tester.element(find.text('Open SubPage'));

      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/43/3'));

      expect(mockTabManager.openTabCallCount, 1);
      expect(mockTabManager.lastBookId, 43);
      expect(mockTabManager.lastChapter, 3);
      expect(mockTabManager.lastTargetVerse, isNull);
    });

    testWidgets('opens chapter with verse (bsb://bible/43/3/16)', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final context = tester.element(find.text('Open SubPage'));

      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/43/3/16'));

      expect(mockTabManager.openTabCallCount, 1);
      expect(mockTabManager.lastBookId, 43);
      expect(mockTabManager.lastChapter, 3);
      expect(mockTabManager.lastTargetVerse, 16);
    });

    testWidgets('handles trailing slashes gracefully', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final context = tester.element(find.text('Open SubPage'));

      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/43/3/'));
      expect(mockTabManager.openTabCallCount, 1);
      expect(mockTabManager.lastBookId, 43);
      expect(mockTabManager.lastChapter, 3);
      expect(mockTabManager.lastTargetVerse, isNull);

      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/43/3/16/'));
      expect(mockTabManager.openTabCallCount, 2);
      expect(mockTabManager.lastBookId, 43);
      expect(mockTabManager.lastChapter, 3);
      expect(mockTabManager.lastTargetVerse, 16);
    });

    testWidgets('handles Genesis 1:1 and Revelation 22:21 boundaries', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final context = tester.element(find.text('Open SubPage'));

      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/1/1/1'));
      expect(mockTabManager.lastBookId, 1);
      expect(mockTabManager.lastChapter, 1);
      expect(mockTabManager.lastTargetVerse, 1);

      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/66/22/21'));
      expect(mockTabManager.lastBookId, 66);
      expect(mockTabManager.lastChapter, 22);
      expect(mockTabManager.lastTargetVerse, 21);
    });

    testWidgets('dismisses open subpages back to root when opening link', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Push a subpage
      await tester.tap(find.text('Open SubPage'));
      await tester.pumpAndSettle();
      expect(find.text('SubPage'), findsOneWidget);

      final context = tester.element(find.text('SubPage'));
      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/19/23'));
      await tester.pumpAndSettle();

      // SubPage should be popped, back to root
      expect(find.text('SubPage'), findsNothing);
      expect(find.text('Open SubPage'), findsOneWidget);
      expect(mockTabManager.openTabCallCount, 1);
      expect(mockTabManager.lastBookId, 19);
      expect(mockTabManager.lastChapter, 23);
    });

    testWidgets('shows SnackBar and does not open tab for invalid book ID', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final context = tester.element(find.text('Open SubPage'));

      // 0 is invalid
      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/0/1'));
      await tester.pump();
      expect(mockTabManager.openTabCallCount, 0);
      expect(find.text('Invalid Bible link'), findsOneWidget);

      await tester.pumpAndSettle();

      // 67 is invalid
      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/67/1'));
      await tester.pump();
      expect(mockTabManager.openTabCallCount, 0);
      expect(find.text('Invalid Bible link'), findsOneWidget);

      await tester.pumpAndSettle();

      // Non-numeric book
      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/John/3/16'));
      await tester.pump();
      expect(mockTabManager.openTabCallCount, 0);
      expect(find.text('Invalid Bible link'), findsOneWidget);
    });

    testWidgets('shows SnackBar and does not open tab for invalid chapter', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final context = tester.element(find.text('Open SubPage'));

      // Chapter 0
      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/43/0'));
      await tester.pump();
      expect(mockTabManager.openTabCallCount, 0);
      expect(find.text('Invalid Bible link'), findsOneWidget);

      await tester.pumpAndSettle();

      // Jude only has 1 chapter
      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/65/2'));
      await tester.pump();
      expect(mockTabManager.openTabCallCount, 0);
      expect(find.text('Invalid Bible link'), findsOneWidget);

      await tester.pumpAndSettle();

      // Psalms has 150 chapters, 151 is invalid
      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/19/151'));
      await tester.pump();
      expect(mockTabManager.openTabCallCount, 0);
      expect(find.text('Invalid Bible link'), findsOneWidget);
    });

    testWidgets('shows SnackBar and does not open tab for invalid verse', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final context = tester.element(find.text('Open SubPage'));

      // Verse 0
      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/43/3/0'));
      await tester.pump();
      expect(mockTabManager.openTabCallCount, 0);
      expect(find.text('Invalid Bible link'), findsOneWidget);

      await tester.pumpAndSettle();

      // John 3 has 36 verses, 37 is invalid
      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/43/3/37'));
      await tester.pump();
      expect(mockTabManager.openTabCallCount, 0);
      expect(find.text('Invalid Bible link'), findsOneWidget);
    });

    testWidgets('shows SnackBar and does not open tab for malformed path', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final context = tester.element(find.text('Open SubPage'));

      // Missing chapter
      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/43'));
      await tester.pump();
      expect(mockTabManager.openTabCallCount, 0);
      expect(find.text('Invalid Bible link'), findsOneWidget);

      await tester.pumpAndSettle();

      // Extra path segments
      await handler.handleIncomingUri(context, Uri.parse('bsb://bible/43/3/16/extra'));
      await tester.pump();
      expect(mockTabManager.openTabCallCount, 0);
      expect(find.text('Invalid Bible link'), findsOneWidget);
    });
  });

  group('DeepLinkHandler - Playlist delegation', () {
    testWidgets('delegates bsb://playlist to playlistShareHandler', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final context = tester.element(find.text('Open SubPage'));

      final uri = Uri.parse('bsb://playlist?data=abc123');
      await handler.handleIncomingUri(context, uri);

      expect(mockPlaylistShareHandler.lastPlaylistUri, uri);
    });

    testWidgets('delegates file:// to playlistShareHandler', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final context = tester.element(find.text('Open SubPage'));

      final uri = Uri.parse('file:///path/to/my_playlist.bsbplaylist');
      await handler.handleIncomingUri(context, uri);

      expect(mockPlaylistShareHandler.lastFileUri, uri);
    });
  });
}
