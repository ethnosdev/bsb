import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/playlist_service.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/section_heading.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/home/home.dart';
import 'package:bsb/ui/playlists/playlist_editor_page.dart';
import 'package:bsb/ui/playlists/playlist_presentation_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/chapter_chip.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/text/text_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeDatabaseHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async => [
        UsfmLine(
          bookChapterVerse: bookId * 1000000 + chapter * 1000 + 1,
          text: 'Chapter text line.',
          format: ParagraphFormat.p,
        ),
      ];

  @override
  Future<List<UsfmLine>> getRange(Reference reference) async => [
        UsfmLine(
          bookChapterVerse: reference.packedVerse,
          text: 'Passage verse line.',
          format: ParagraphFormat.p,
        ),
      ];

  @override
  Future<List<SectionHeading>> getSectionHeadings(int bookId) async => [];
}

class FakeAnnotationDbHelper implements AnnotationDatabaseHelper {
  final List<Playlist> playlists = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Highlight>> getHighlightsForChapter(int bookId, int chapter) async => [];

  @override
  Future<List<Note>> getNotesForChapter(int bookId, int chapter) async => [];

  @override
  Future<List<Playlist>> getAllPlaylists() async => playlists;

  @override
  Future<Playlist?> getPlaylistById(String id) async {
    try {
      return playlists.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePlaylist(Playlist playlist) async {
    playlists.removeWhere((p) => p.id == playlist.id);
    playlists.add(playlist);
  }

  @override
  Future<void> updatePlaylistMetadata(Playlist playlist) async {
    final index = playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      playlists[index] = playlists[index].copyWith(
        title: playlist.title,
        updatedAt: playlist.updatedAt,
      );
    } else {
      playlists.add(playlist);
    }
  }

  @override
  Future<void> deletePlaylist(String id) async {
    playlists.removeWhere((p) => p.id == id);
  }
}

void main() {
  late UserSettings userSettings;
  late TabManager tabManager;
  late FakeAnnotationDbHelper fakeAnnotationDb;
  late PlaylistService playlistService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();

    userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);

    tabManager = TabManager();
    await tabManager.init();
    getIt.registerSingleton<TabManager>(tabManager);

    fakeAnnotationDb = FakeAnnotationDbHelper();
    playlistService = PlaylistService(dbHelper: fakeAnnotationDb);
    getIt.registerSingleton<PlaylistService>(playlistService);
    getIt.registerSingleton<DatabaseHelper>(FakeDatabaseHelper());
    getIt.registerSingleton<AnnotationService>(
      AnnotationService(dbHelper: fakeAnnotationDb),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('Opening a playlist tab displays the playlist presentation on HomePage', (tester) async {
    final playlist = Playlist(
      id: 'pl-1',
      title: 'Grace & Truth',
      items: [
        PlaylistItem.reference(
          reference: Reference(bookId: 43, chapter: 1, verse: 14),
          orderIndex: 0,
        ),
      ],
    );
    await playlistService.savePlaylist(playlist);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Initially no tabs, so book chooser is shown
    expect(find.byType(TextScreen), findsNothing);
    expect(find.byType(PlaylistPresentationPage), findsNothing);

    // Open playlist tab
    tabManager.openPlaylistTab('pl-1', 'Grace & Truth');
    await tester.pumpAndSettle();

    // Should display ChapterChip with playlist title (no icon)
    expect(find.byType(ChapterChip), findsOneWidget);
    expect(find.text('Grace & Truth'), findsOneWidget);

    // Should display PlaylistPresentationPage embedded, not TextScreen
    expect(find.byType(PlaylistPresentationPage), findsOneWidget);
    expect(find.byType(TextScreen), findsNothing);
  });

  testWidgets('Tapping the active playlist tab chip opens PlaylistEditorPage', (tester) async {
    final playlist = Playlist(
      id: 'pl-1',
      title: 'Grace & Truth',
      items: [],
    );
    await playlistService.savePlaylist(playlist);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    tabManager.openPlaylistTab('pl-1', 'Grace & Truth');
    await tester.pumpAndSettle();

    // Tap active playlist chip
    await tester.tap(find.text('Grace & Truth'));
    await tester.pumpAndSettle();

    // PlaylistEditorPage should be opened
    expect(find.byType(PlaylistEditorPage), findsOneWidget);

    // Popping editor returns to HomePage presentation view
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.byType(PlaylistPresentationPage), findsOneWidget);
    expect(find.byType(PlaylistEditorPage), findsNothing);
  });

  testWidgets('Overflow menu shows Edit Playlist and Search when playlist tab is active', (tester) async {
    final playlist = Playlist(
      id: 'pl-1',
      title: 'Study 1',
      items: [],
    );
    await playlistService.savePlaylist(playlist);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    tabManager.openPlaylistTab('pl-1', 'Study 1');
    await tester.pumpAndSettle();

    // Open overflow menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Edit Playlist'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Play Audio'), findsNothing);

    // Tapping Edit Playlist opens PlaylistEditorPage
    await tester.tap(find.text('Edit Playlist'));
    await tester.pumpAndSettle();

    expect(find.byType(PlaylistEditorPage), findsOneWidget);
  });

  testWidgets('Can switch between chapter tab and playlist tab seamlessly', (tester) async {
    final playlist = Playlist(
      id: 'pl-1',
      title: 'Sermon on Mount',
      items: [],
    );
    await playlistService.savePlaylist(playlist);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    tabManager.openTab(43, 1); // JHN 1
    tabManager.openPlaylistTab('pl-1', 'Sermon on Mount');
    await tester.pumpAndSettle();

    // Active tab is playlist
    expect(find.byType(PlaylistPresentationPage), findsOneWidget);
    expect(find.byType(TextScreen), findsNothing);

    // Switch to JHN 1 tab
    await tester.tap(find.text('JHN 1'));
    await tester.pumpAndSettle();

    // Active tab is now scripture chapter
    expect(find.byType(TextScreen), findsOneWidget);
    expect(find.byType(PlaylistPresentationPage), findsNothing);
  });
}
