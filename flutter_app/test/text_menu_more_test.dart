import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/playlist_service.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/text/chapter/chapter_text.dart';
import 'package:bsb/ui/text/text_screen.dart';
import 'package:bsb/ui/playlists/widgets/add_to_playlist_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeDatabaseHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async => [];
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
  Future<List<Playlist>> getAllPlaylists() async => List.from(playlists);

  @override
  Future<void> savePlaylist(Playlist playlist) async {
    playlists.removeWhere((p) => p.id == playlist.id);
    playlists.add(playlist);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserSettings userSettings;
  late TabManager tabManager;
  late FakeAnnotationDbHelper annotationDb;
  late PlaylistService playlistService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    getIt.reset();

    userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);

    final dbHelper = FakeDatabaseHelper();
    getIt.registerSingleton<DatabaseHelper>(dbHelper);

    annotationDb = FakeAnnotationDbHelper();
    getIt.registerSingleton<AnnotationDatabaseHelper>(annotationDb);
    getIt.registerSingleton<AnnotationService>(
      AnnotationService(dbHelper: annotationDb),
    );

    playlistService = PlaylistService(dbHelper: annotationDb);
    getIt.registerSingleton<PlaylistService>(playlistService);

    tabManager = TabManager();
    await tabManager.init();
    getIt.registerSingleton<TabManager>(tabManager);

    getIt.registerSingleton<AppState>(AppState());
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('BottomNavigationBar shows More instead of Compare', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextScreen(
            bookId: 19, // Psalm
            chapter: 23,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify BottomNavigationBar has 'More' item with more_horiz icon, and NOT 'Compare'
    expect(find.text('More'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    expect(find.text('Compare'), findsNothing);
  });

  testWidgets('Tapping More opens overflow menu with Compare and Cross Reference', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextScreen(
            bookId: 19, // Psalm
            chapter: 23,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger selection callback on ChapterText
    final chapterTextFinder = find.byType(ChapterText).first;
    expect(chapterTextFinder, findsOneWidget);
    final chapterText = tester.widget<ChapterText>(chapterTextFinder);

    // Psalm 23:4 packed wordId = 19023004001
    const packedWordId = 19023004001;
    final controller = ScriptureSelectionController();
    controller.selectWord(packedWordId);

    chapterText.onSelectionChanged!(controller);
    await tester.pumpAndSettle();

    // Tap More in bottom bar
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    // Verify popup menu shows Compare, Cross Reference, and Add to Playlist
    expect(find.text('Compare'), findsOneWidget);
    expect(find.text('Cross Reference'), findsOneWidget);
    expect(find.text('Add to Playlist'), findsOneWidget);

    // Tap outside (barrier) to dismiss menu
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Menu is dismissed, but selection is NOT cleared because user cancelled
    expect(find.text('Cross Reference'), findsNothing);
    expect(controller.hasSelection, isTrue);
  });

  testWidgets('Selecting Compare clears the selection', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextScreen(
            bookId: 19, // Psalm
            chapter: 23,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chapterTextFinder = find.byType(ChapterText).first;
    final chapterText = tester.widget<ChapterText>(chapterTextFinder);

    const packedWordId = 19023004001;
    final controller = ScriptureSelectionController();
    controller.selectWord(packedWordId);

    chapterText.onSelectionChanged!(controller);
    await tester.pumpAndSettle();

    // Tap More in bottom bar
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    // Tap Compare
    await tester.tap(find.text('Compare'));
    await tester.pumpAndSettle();

    // Controller should now have selection cleared
    expect(controller.hasSelection, isFalse);
  });

  testWidgets('Selecting Cross Reference clears the selection', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextScreen(
            bookId: 19, // Psalm
            chapter: 23,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chapterTextFinder = find.byType(ChapterText).first;
    final chapterText = tester.widget<ChapterText>(chapterTextFinder);

    const packedWordId = 19023004001;
    final controller = ScriptureSelectionController();
    controller.selectWord(packedWordId);

    chapterText.onSelectionChanged!(controller);
    await tester.pumpAndSettle();

    // Tap More in bottom bar
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    // Tap Cross Reference
    await tester.tap(find.text('Cross Reference'));
    await tester.pumpAndSettle();

    // Controller should now have selection cleared
    expect(controller.hasSelection, isFalse);
  });

  testWidgets('Dismissing Add to Playlist sheet retains selection', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextScreen(
            bookId: 19, // Psalm
            chapter: 23,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chapterTextFinder = find.byType(ChapterText).first;
    final chapterText = tester.widget<ChapterText>(chapterTextFinder);

    const packedWordId = 19023004001;
    final controller = ScriptureSelectionController();
    controller.selectWord(packedWordId);

    chapterText.onSelectionChanged!(controller);
    await tester.pumpAndSettle();

    // Tap More in bottom bar
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    // Tap Add to Playlist
    await tester.tap(find.text('Add to Playlist'));
    await tester.pumpAndSettle();

    // Verify AddToPlaylistSheet is displayed
    expect(find.byType(AddToPlaylistSheet), findsOneWidget);
    expect(find.text('Psalm 23:4'), findsOneWidget);

    // Tap outside to dismiss bottom sheet
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(AddToPlaylistSheet), findsNothing);
    // Selection retained
    expect(controller.hasSelection, isTrue);
  });

  testWidgets('Selecting existing playlist in AddToPlaylistSheet adds verse, shows SnackBar, and clears selection', (tester) async {
    final existingPlaylist = Playlist(
      id: 'p1',
      title: 'Comfort Verses',
      items: [],
    );
    await playlistService.savePlaylist(existingPlaylist);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextScreen(
            bookId: 19, // Psalm
            chapter: 23,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chapterTextFinder = find.byType(ChapterText).first;
    final chapterText = tester.widget<ChapterText>(chapterTextFinder);

    const packedWordId = 19023004001;
    final controller = ScriptureSelectionController();
    controller.selectWord(packedWordId);

    chapterText.onSelectionChanged!(controller);
    await tester.pumpAndSettle();

    // Tap More -> Add to Playlist
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to Playlist'));
    await tester.pumpAndSettle();

    // Verify existing playlist is visible
    expect(find.text('Comfort Verses'), findsOneWidget);

    // Tap existing playlist
    await tester.tap(find.text('Comfort Verses'));
    await tester.pumpAndSettle();

    // Bottom sheet is dismissed and selection is cleared
    expect(find.byType(AddToPlaylistSheet), findsNothing);
    expect(controller.hasSelection, isFalse);

    // Verify SnackBar shown
    expect(find.text('Added to "Comfort Verses"'), findsOneWidget);

    // Verify playlist item was saved
    final updatedList = await playlistService.getPlaylists();
    final updated = updatedList.firstWhere((p) => p.id == 'p1');
    expect(updated.items.length, 1);
    expect(updated.items.first.reference, equals(Reference(bookId: 19, chapter: 23, verse: 4)));
    expect(updated.items.first.isTrimmed, isTrue);
    expect(updated.items.first.startWordId, packedWordId);
    expect(updated.items.first.endWordId, packedWordId);
  });

  testWidgets('Creating new playlist in AddToPlaylistSheet adds verse and clears selection', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextScreen(
            bookId: 19, // Psalm
            chapter: 23,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chapterTextFinder = find.byType(ChapterText).first;
    final chapterText = tester.widget<ChapterText>(chapterTextFinder);

    const packedWordId = 19023004001;
    final controller = ScriptureSelectionController();
    controller.selectWord(packedWordId);

    chapterText.onSelectionChanged!(controller);
    await tester.pumpAndSettle();

    // Tap More -> Add to Playlist
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to Playlist'));
    await tester.pumpAndSettle();

    // Tap Create New Playlist
    await tester.tap(find.text('Create New Playlist'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'My Daily Verses');
    await tester.pumpAndSettle();

    // Tap Create
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Selection cleared
    expect(controller.hasSelection, isFalse);
    expect(find.text('Added to "My Daily Verses"'), findsOneWidget);

    // Verify playlist in db
    final playlists = await playlistService.getPlaylists();
    expect(playlists.length, 1);
    expect(playlists.first.title, 'My Daily Verses');
    expect(playlists.first.items.length, 1);
    expect(playlists.first.items.first.reference, equals(Reference(bookId: 19, chapter: 23, verse: 4)));
    expect(playlists.first.items.first.isTrimmed, isTrue);
    expect(playlists.first.items.first.startWordId, packedWordId);
    expect(playlists.first.items.first.endWordId, packedWordId);
  });

  testWidgets('Selecting a range of verses adds multi-verse reference to playlist', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextScreen(
            bookId: 19, // Psalm
            chapter: 23,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chapterTextFinder = find.byType(ChapterText).first;
    final chapterText = tester.widget<ChapterText>(chapterTextFinder);

    // Select from Psalm 23:1 to Psalm 23:3
    const startWordId = 19023001001;
    const endWordId = 19023003008;
    final controller = ScriptureSelectionController();
    controller.selectRange(startWordId, endWordId);

    chapterText.onSelectionChanged!(controller);
    await tester.pumpAndSettle();

    // Tap More -> Add to Playlist
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to Playlist'));
    await tester.pumpAndSettle();

    // Sheet displays the verse range
    expect(find.text('Psalm 23:1–3'), findsOneWidget);

    // Create new playlist with range
    await tester.tap(find.text('Create New Playlist'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Shepherd Psalm');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(controller.hasSelection, isFalse);

    final playlists = await playlistService.getPlaylists();
    expect(playlists.first.title, 'Shepherd Psalm');
    final item = playlists.first.items.first;
    expect(item.reference, equals(Reference(bookId: 19, chapter: 23, verse: 1, endVerse: 3)));
    expect(item.reference.toString(), 'Psalm 23:1–3');
    expect(item.isTrimmed, isTrue);
    expect(item.startWordId, startWordId);
    expect(item.endWordId, endWordId);
  });
}

