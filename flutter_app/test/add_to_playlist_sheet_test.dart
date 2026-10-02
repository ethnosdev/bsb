import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/playlist_service.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/playlists/widgets/add_to_playlist_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bsb/infrastructure/database.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

class FakeDatabaseHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getRange(Reference reference) async => [
        UsfmLine(
          bookChapterVerse: reference.packedVerse,
          text: 'The Lord is my shepherd',
          format: ParagraphFormat.p,
        ),
      ];
}

class FakeAnnotationDbHelper implements AnnotationDatabaseHelper {
  final List<Playlist> playlists = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Playlist>> getAllPlaylists() async => List.from(playlists);

  @override
  Future<void> savePlaylist(Playlist playlist) async {
    playlists.removeWhere((p) => p.id == playlist.id);
    playlists.add(playlist);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAnnotationDbHelper dbHelper;
  late PlaylistService playlistService;

  setUp(() {
    getIt.reset();
    dbHelper = FakeAnnotationDbHelper();
    playlistService = PlaylistService(dbHelper: dbHelper);
    getIt.registerSingleton<PlaylistService>(playlistService);
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('AddToPlaylistSheet displays reference and empty state when no playlists', (tester) async {
    final ref = Reference(bookId: 19, chapter: 23, verse: 1, endVerse: 3);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToPlaylistSheet.show(
                context: context,
                reference: ref,
                playlistService: playlistService,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Add to Playlist'), findsOneWidget);
    expect(find.text('Psalm 23:1–3'), findsOneWidget);
    expect(find.text('Create New Playlist'), findsOneWidget);
    expect(find.text('No playlists yet'), findsOneWidget);
  });

  testWidgets('AddToPlaylistSheet lists existing playlists sorted by updatedAt with passage counts', (tester) async {
    final older = Playlist(
      id: 'p1',
      title: 'Older Playlist',
      updatedAt: DateTime(2025, 1, 1),
      items: [
        PlaylistItem.reference(
          reference: Reference(bookId: 1, chapter: 1, verse: 1),
          orderIndex: 0,
        ),
      ],
    );
    final newer = Playlist(
      id: 'p2',
      title: 'Newer Playlist',
      updatedAt: DateTime(2025, 6, 1),
      items: [
        PlaylistItem.reference(
          reference: Reference(bookId: 1, chapter: 1, verse: 1),
          orderIndex: 0,
        ),
        PlaylistItem.reference(
          reference: Reference(bookId: 1, chapter: 1, verse: 2),
          orderIndex: 1,
        ),
      ],
    );
    await playlistService.savePlaylist(older);
    await playlistService.savePlaylist(newer);

    final ref = Reference(bookId: 19, chapter: 23, verse: 4);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToPlaylistSheet.show(
                context: context,
                reference: ref,
                playlistService: playlistService,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Newer Playlist'), findsOneWidget);
    expect(find.text('2 passages'), findsOneWidget);
    expect(find.text('Older Playlist'), findsOneWidget);
    expect(find.text('1 passage'), findsOneWidget);

    // Newer should appear above older in the list
    final newerOffset = tester.getTopLeft(find.text('Newer Playlist')).dy;
    final olderOffset = tester.getTopLeft(find.text('Older Playlist')).dy;
    expect(newerOffset, lessThan(olderOffset));
  });

  testWidgets('Tapping playlist adds reference and appends with correct orderIndex', (tester) async {
    final existing = Playlist(
      id: 'p1',
      title: 'Study',
      items: [
        PlaylistItem.reference(
          reference: Reference(bookId: 1, chapter: 1, verse: 1),
          orderIndex: 0,
        ),
      ],
    );
    await playlistService.savePlaylist(existing);

    final ref = Reference(bookId: 43, chapter: 3, verse: 16);
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await AddToPlaylistSheet.show(
                  context: context,
                  reference: ref,
                  playlistService: playlistService,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Study'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text('Added to "Study"'), findsOneWidget);

    final playlists = await playlistService.getPlaylists();
    final p = playlists.firstWhere((p) => p.id == 'p1');
    expect(p.items.length, 2);
    expect(p.items[0].reference, equals(Reference(bookId: 1, chapter: 1, verse: 1)));
    expect(p.items[1].reference, equals(ref));
    expect(p.items[1].orderIndex, 1);
  });

  testWidgets('Creating new playlist inline and canceling reverts back to button', (tester) async {
    final ref = Reference(bookId: 19, chapter: 23, verse: 4);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToPlaylistSheet.show(
                context: context,
                reference: ref,
                playlistService: playlistService,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Tap Create New Playlist
    await tester.tap(find.text('Create New Playlist'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('Cancel'), findsOneWidget);

    // Tap cancel
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Create New Playlist'), findsOneWidget);
  });

  testWidgets('Submitting new playlist via keyboard onSubmitted creates playlist', (tester) async {
    final ref = Reference(bookId: 19, chapter: 23, verse: 1, endVerse: 6);
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await AddToPlaylistSheet.show(
                  context: context,
                  reference: ref,
                  playlistService: playlistService,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create New Playlist'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'All of Psalm 23');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text('Added to "All of Psalm 23"'), findsOneWidget);

    final playlists = await playlistService.getPlaylists();
    expect(playlists.length, 1);
    expect(playlists.first.title, 'All of Psalm 23');
    expect(playlists.first.items.length, 1);
    expect(playlists.first.items.first.reference, equals(ref));
  });

  testWidgets('Adding a partial verse displays Trimmed badge, snippet, and saves startWordId and endWordId', (tester) async {
    final fakeDb = FakeDatabaseHelper();
    getIt.registerSingleton<DatabaseHelper>(fakeDb);

    final ref = Reference(bookId: 19, chapter: 23, verse: 1);
    // 'The Lord is my shepherd' has 5 words: offsets 0..4 (19023001000..19023001004)
    // Partial selection: words 1..3 ('Lord is my')
    const startWordId = 19023001001;
    const endWordId = 19023001003;
    const selectedText = 'Lord is my';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToPlaylistSheet.show(
                context: context,
                reference: ref,
                startWordId: startWordId,
                endWordId: endWordId,
                selectedText: selectedText,
                playlistService: playlistService,
                dbHelper: fakeDb,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify Trimmed badge and snippet are shown in sheet
    expect(find.text('Trimmed'), findsOneWidget);
    expect(find.text('"Lord is my"'), findsOneWidget);

    // Create a new playlist
    await tester.tap(find.text('Create New Playlist'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Partial Psalm');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final playlists = await playlistService.getPlaylists();
    expect(playlists.length, 1);
    final item = playlists.first.items.first;
    expect(item.reference, equals(ref));
    expect(item.isTrimmed, isTrue);
    expect(item.startWordId, startWordId);
    expect(item.endWordId, endWordId);
  });

  testWidgets('Adding a full verse does not mark item as trimmed', (tester) async {
    final fakeDb = FakeDatabaseHelper();
    getIt.registerSingleton<DatabaseHelper>(fakeDb);

    final ref = Reference(bookId: 19, chapter: 23, verse: 1);
    // Entire verse: offsets 0..4 (19023001000..19023001004)
    const startWordId = 19023001000;
    const endWordId = 19023001004;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddToPlaylistSheet.show(
                context: context,
                reference: ref,
                startWordId: startWordId,
                endWordId: endWordId,
                playlistService: playlistService,
                dbHelper: fakeDb,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Should NOT show Trimmed badge
    expect(find.text('Trimmed'), findsNothing);

    // Create new playlist
    await tester.tap(find.text('Create New Playlist'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Full Psalm Verse');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final playlists = await playlistService.getPlaylists();
    expect(playlists.length, 1);
    final item = playlists.first.items.first;
    expect(item.reference, equals(ref));
    expect(item.isTrimmed, isFalse);
    expect(item.startWordId, isNull);
    expect(item.endWordId, isNull);
  });
}
