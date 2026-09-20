import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/playlist_service.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/home/drawer.dart';
import 'package:bsb/ui/playlists/playlist_editor_page.dart';
import 'package:bsb/ui/playlists/playlist_presentation_page.dart';
import 'package:bsb/ui/playlists/playlists_page.dart';
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

  int getAllPlaylistsCallCount = 0;

  @override
  Future<List<Playlist>> getAllPlaylists() async {
    getAllPlaylistsCallCount++;
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
          text: 'Scripture verse text',
          format: ParagraphFormat.p,
        ),
      ];
}

void main() {
  late FakePlaylistDbHelper fakeDb;
  late PlaylistService playlistService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    final userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);
    fakeDb = FakePlaylistDbHelper();
    playlistService = PlaylistService(dbHelper: fakeDb);
    getIt.registerSingleton<AnnotationDatabaseHelper>(fakeDb);
    getIt.registerSingleton<PlaylistService>(playlistService);
    getIt.registerSingleton<DatabaseHelper>(FakeDatabaseHelper());
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('PlaylistsPage displays empty state when no playlists exist', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlaylistsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Playlists Yet'), findsOneWidget);
    expect(find.text('Create Playlist'), findsOneWidget);
  });

  testWidgets('PlaylistsPage displays saved playlists in simplified cards and navigates on tap', (tester) async {
    final playlist = Playlist(
      id: 'p1',
      title: 'Romans Road Study',
      updatedAt: DateTime(2026, 9, 19),
      items: [
        PlaylistItem.reference(
          reference: Reference(bookId: 45, chapter: 3, verse: 23),
          orderIndex: 0,
        ),
      ],
    );
    await playlistService.savePlaylist(playlist);

    await tester.pumpWidget(
      const MaterialApp(
        home: PlaylistsPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Card should have title, date as subtitle, and 3-dot menu
    expect(find.text('Romans Road Study'), findsOneWidget);
    expect(find.text('Sep 19, 2026'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Card), matching: find.byIcon(Icons.more_vert)),
      findsOneWidget,
    );

    // No reference/note count chips or explicit present button on the card
    expect(find.byIcon(Icons.menu_book), findsNothing);
    expect(find.byIcon(Icons.edit_note), findsNothing);

    // Tapping the card enters presentation mode
    await tester.tap(find.text('Romans Road Study'));
    await tester.pumpAndSettle();

    expect(find.byType(PlaylistPresentationPage), findsOneWidget);
  });

  testWidgets('PlaylistsPage orders playlists with most recently updated on top and updates updatedAt when opened', (tester) async {
    final playlistOld = Playlist(
      id: 'p1',
      title: 'Older Playlist',
      updatedAt: DateTime(2026, 1, 1),
    );
    final playlistNew = Playlist(
      id: 'p2',
      title: 'Newer Playlist',
      updatedAt: DateTime(2026, 6, 1),
    );
    await playlistService.savePlaylist(playlistOld);
    await playlistService.savePlaylist(playlistNew);

    await tester.pumpWidget(
      const MaterialApp(
        home: PlaylistsPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Newer Playlist is displayed first
    var listTiles = find.byType(ListTile);
    expect(tester.widget<Text>(find.descendant(of: listTiles.at(0), matching: find.byType(Text)).first).data, 'Newer Playlist');
    expect(tester.widget<Text>(find.descendant(of: listTiles.at(1), matching: find.byType(Text)).first).data, 'Older Playlist');

    // Tap on Older Playlist to open it (present)
    await tester.tap(find.text('Older Playlist'));
    await tester.pumpAndSettle();

    // Verify presentation mode opened
    expect(find.byType(PlaylistPresentationPage), findsOneWidget);

    // Close presentation mode to return to PlaylistsPage
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    // Verify Older Playlist is now at the top because it was opened/touched!
    listTiles = find.byType(ListTile);
    expect(tester.widget<Text>(find.descendant(of: listTiles.at(0), matching: find.byType(Text)).first).data, 'Older Playlist');
    expect(tester.widget<Text>(find.descendant(of: listTiles.at(1), matching: find.byType(Text)).first).data, 'Newer Playlist');
  });

  testWidgets('AppDrawer contains Playlists tile', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          drawer: AppDrawer(),
        ),
      ),
    );

    // Open drawer
    final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Playlists'), findsOneWidget);
  });

  testWidgets('PlaylistsPage suppresses background reloads while editor page is active', (tester) async {
    final playlist = Playlist(
      id: 'p1',
      title: 'Study 1',
      updatedAt: DateTime(2026, 1, 1),
    );
    await playlistService.savePlaylist(playlist);

    await tester.pumpWidget(
      const MaterialApp(
        home: PlaylistsPage(),
      ),
    );
    await tester.pumpAndSettle();

    final initialCount = fakeDb.getAllPlaylistsCallCount;
    expect(initialCount, greaterThan(0));

    // Open 3-dot menu on playlist card and select edit
    await tester.tap(find.descendant(of: find.byType(Card), matching: find.byIcon(Icons.more_vert)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Verify PlaylistEditorPage is open
    expect(find.byType(PlaylistEditorPage), findsOneWidget);

    final countAfterOpen = fakeDb.getAllPlaylistsCallCount;

    // Simulate saving while editor is open (e.g., typing or reordering)
    await playlistService.updatePlaylistMetadata(playlist.copyWith(title: 'Study 1 Modified'));
    await tester.pumpAndSettle();

    // getAllPlaylists should NOT have been called in PlaylistsPage because editor is open
    expect(fakeDb.getAllPlaylistsCallCount, countAfterOpen);

    // Pop the editor to return to PlaylistsPage
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    // Now returning to PlaylistsPage triggers a single reload
    expect(fakeDb.getAllPlaylistsCallCount, countAfterOpen + 1);
  });
}
