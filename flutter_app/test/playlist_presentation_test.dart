import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/playlist_service.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/playlists/playlist_editor_page.dart';
import 'package:bsb/ui/playlists/playlist_presentation_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePlaylistDbHelper implements AnnotationDatabaseHelper {
  final List<Playlist> _playlists = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Playlist>> getAllPlaylists() async {
    final list = List<Playlist>.from(_playlists);
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<Playlist?> getPlaylistById(String id) async {
    try {
      return _playlists.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePlaylist(Playlist playlist) async {
    _playlists.removeWhere((p) => p.id == playlist.id);
    _playlists.add(playlist);
  }

  @override
  Future<void> updatePlaylistMetadata(Playlist playlist) async {
    final index = _playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      _playlists[index] = _playlists[index].copyWith(
        title: playlist.title,
        updatedAt: playlist.updatedAt,
      );
    } else {
      _playlists.add(playlist);
    }
  }

  @override
  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> batchInsertPlaylists(List<Playlist> playlists) async {
    for (final p in playlists) {
      await savePlaylist(p);
    }
  }

  @override
  Future<void> clearAllPlaylists() async {
    _playlists.clear();
  }
}

class FakeDatabaseHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getRange(Reference reference) async => [
        UsfmLine(
          bookChapterVerse: reference.packedVerse,
          text: 'For God so loved the world that He gave His one and only Son.',
          format: ParagraphFormat.p,
        ),
      ];
}

void main() {
  late FakePlaylistDbHelper fakePlaylistDb;
  late PlaylistService playlistService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    final userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);
    getIt.registerSingleton<DatabaseHelper>(FakeDatabaseHelper());
    fakePlaylistDb = FakePlaylistDbHelper();
    playlistService = PlaylistService(dbHelper: fakePlaylistDb);
    getIt.registerSingleton<PlaylistService>(playlistService);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('PlaylistPresentationPage renders passages and notes in continuous scroll', (tester) async {
    final playlist = Playlist(
      id: 'p-pres',
      title: 'Romans & John Study',
      items: [
        PlaylistItem.reference(
          id: 'item-1',
          reference: Reference(bookId: 43, chapter: 3, verse: 16),
          orderIndex: 0,
        ),
        PlaylistItem.note(
          id: 'item-2',
          text: 'What does everlasting life mean here?',
          orderIndex: 1,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlaylistPresentationPage(playlist: playlist),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Romans & John Study'), findsOneWidget);
    expect(find.text('John 3:16'), findsOneWidget);
    expect(find.text('What does everlasting life mean here?'), findsOneWidget);
    expect(find.byType(UsfmWidget), findsOneWidget);

    // Verify Passage title is Large text (fontSize >= 22) and left aligned
    final passageTitleText = tester.widget<Text>(find.text('John 3:16'));
    expect(passageTitleText.textAlign, equals(TextAlign.left));
    expect(passageTitleText.style?.fontSize, greaterThanOrEqualTo(22.0));
    expect(passageTitleText.style?.fontWeight, equals(FontWeight.bold));

    // Verify Note title is Large text (fontSize >= 22) and left aligned
    final noteTitleText = tester.widget<Text>(find.text('Note'));
    expect(noteTitleText.textAlign, equals(TextAlign.left));
    expect(noteTitleText.style?.fontSize, greaterThanOrEqualTo(22.0));
    expect(noteTitleText.style?.fontWeight, equals(FontWeight.bold));

    // Record initial top position of the passage title on screen
    final initialTop = tester.getTopLeft(find.text('John 3:16')).dy;

    // Test that fullscreen action button is replaced with edit button
    expect(find.byIcon(Icons.fullscreen), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    // Test fullscreen toggle via tapping text
    await tester.tap(find.byType(UsfmWidget));
    await tester.pumpAndSettle();

    bool isDistractionFree() {
      final ignorePointer = tester.widget<IgnorePointer>(find.byWidgetPredicate(
        (w) => w is IgnorePointer && w.child is AppBar,
      ));
      return ignorePointer.ignoring;
    }

    expect(isDistractionFree(), isTrue);
    // Verify text does not jump when going into fullscreen mode
    final fullscreenTop = tester.getTopLeft(find.text('John 3:16')).dy;
    expect(fullscreenTop, equals(initialTop));

    // Tap whitespace on screen to exit distraction free
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();
    expect(isDistractionFree(), isFalse);
    // Verify text position remains identical after exiting fullscreen mode
    expect(tester.getTopLeft(find.text('John 3:16')).dy, equals(initialTop));

    // Tap on scripture passage to enter full screen mode
    await tester.tap(find.byType(UsfmWidget));
    await tester.pumpAndSettle();
    expect(isDistractionFree(), isTrue);
    expect(tester.getTopLeft(find.text('John 3:16')).dy, equals(initialTop));

    // Tap on note to exit full screen mode
    await tester.tap(find.text('What does everlasting life mean here?'));
    await tester.pumpAndSettle();
    expect(isDistractionFree(), isFalse);
    expect(tester.getTopLeft(find.text('John 3:16')).dy, equals(initialTop));

    // Tap on note to enter full screen mode
    await tester.tap(find.text('What does everlasting life mean here?'));
    await tester.pumpAndSettle();
    expect(isDistractionFree(), isTrue);
    expect(tester.getTopLeft(find.text('John 3:16')).dy, equals(initialTop));

    // Tap on passage header to exit full screen mode
    await tester.tap(find.text('John 3:16'));
    await tester.pumpAndSettle();
    expect(isDistractionFree(), isFalse);
    expect(tester.getTopLeft(find.text('John 3:16')).dy, equals(initialTop));
  });

  testWidgets('Tapping edit button navigates to PlaylistEditorPage and updates presentation on return', (tester) async {
    final playlist = Playlist(
      id: 'p-edit-test',
      title: 'Original Title',
      items: [
        PlaylistItem.reference(
          id: 'item-1',
          reference: Reference(bookId: 43, chapter: 3, verse: 16),
          orderIndex: 0,
        ),
      ],
    );
    await fakePlaylistDb.savePlaylist(playlist);

    await tester.pumpWidget(
      MaterialApp(
        home: PlaylistPresentationPage(playlist: playlist),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Original Title'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    // Tap the edit button
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    // Verify PlaylistEditorPage is open
    expect(find.byType(PlaylistEditorPage), findsOneWidget);
    expect(find.text('Edit Playlist'), findsOneWidget);

    // Edit the title
    await tester.enterText(find.byType(TextField), 'Updated Title');
    await tester.pumpAndSettle();

    // Tap back button to return to PlaylistPresentationPage
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Verify we are back on PlaylistPresentationPage and title has updated
    expect(find.byType(PlaylistEditorPage), findsNothing);
    expect(find.byType(PlaylistPresentationPage), findsOneWidget);
    expect(find.text('Updated Title'), findsOneWidget);
  });

  test('stripFootnotesFromLines removes inline footnote markers and paragraph format r lines', () {
    final rawLines = [
      UsfmLine(
        bookChapterVerse: 43003016,
        text: 'For God so loved the world that He gave His one and only\\f + \\fr 3:16 \\ft Or unique\\f* Son,',
        format: ParagraphFormat.p,
      ),
      UsfmLine(
        bookChapterVerse: 43003016,
        text: 'Attached\\f + \\ft note\\f*withoutspace',
        format: ParagraphFormat.p,
      ),
      UsfmLine(
        bookChapterVerse: 43003016,
        text: 'Trailing\\f + \\ft note\\f*.',
        format: ParagraphFormat.p,
      ),
      UsfmLine(
        bookChapterVerse: 43003016,
        text: 'Parallel passage\\f + \\ft ref\\f*',
        format: ParagraphFormat.r,
      ),
    ];

    final stripped = stripFootnotesFromLines(rawLines);
    expect(stripped.length, 3);
    expect(stripped[0].text, 'For God so loved the world that He gave His one and only Son,');
    expect(stripped[1].text, 'Attached withoutspace');
    expect(stripped[2].text, 'Trailing.');
  });

  testWidgets('PlaylistPresentationPage does not render footnote markers when presenting', (tester) async {
    final fakeDb = FakeDatabaseHelperWithFootnotes();
    await getIt.reset();
    final userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);
    getIt.registerSingleton<DatabaseHelper>(fakeDb);

    final playlist = Playlist(
      id: 'p-fn',
      title: 'Passage with Footnotes',
      items: [
        PlaylistItem.reference(
          id: 'item-fn',
          reference: Reference(bookId: 43, chapter: 3, verse: 16),
          orderIndex: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlaylistPresentationPage(playlist: playlist),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(UsfmWidget), findsOneWidget);
    // Assert no FootnoteWidget is rendered
    expect(find.byType(FootnoteWidget), findsNothing);
    expect(find.text('*'), findsNothing);
  });

  testWidgets('PlaylistPresentationPage trims words and suppresses verse number when start is trimmed', (tester) async {
    final playlist = Playlist(
      id: 'p-trim',
      title: 'Trimmed Presentation',
      items: [
        PlaylistItem.reference(
          id: 'item-trim',
          reference: Reference(bookId: 43, chapter: 3, verse: 16),
          // Trim starting at word 1 ("God"), omitting word 0 ("For")
          startWordId: 43003016001,
          orderIndex: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlaylistPresentationPage(playlist: playlist),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(UsfmWidget), findsOneWidget);
    // "For" was trimmed away
    expect(
      find.byWidgetPredicate((w) => w is WordWidget && w.text == 'For'),
      findsNothing,
    );
    // "God" is present
    expect(
      find.byWidgetPredicate((w) => w is WordWidget && w.text == 'God'),
      findsOneWidget,
    );
    // Verse number is suppressed because the first word of the verse was trimmed
    expect(find.byType(VerseNumberWidget), findsNothing);
  });
}

class FakeDatabaseHelperWithFootnotes implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getRange(Reference reference) async => [
        UsfmLine(
          bookChapterVerse: reference.packedVerse,
          text: 'For God so loved the world that He gave His one and only\\f + \\fr 3:16 \\ft Or unique\\f* Son.',
          format: ParagraphFormat.p,
        ),
      ];
}
