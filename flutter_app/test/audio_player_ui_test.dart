import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/audio/audio_playback_manager.dart';
import 'package:bsb/infrastructure/audio/bsb_audio_handler.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/search/bible_search_service.dart';
import 'package:bsb/ui/audio/audio_player_bottom_bar.dart';
import 'package:bsb/ui/home/home.dart';
import 'package:bsb/ui/search/search_manager.dart';
import 'package:bsb/ui/search/search_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scripture/scripture.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeDatabaseHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async => [];
}

class FakeAnnotationDbHelper implements AnnotationDatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Highlight>> getHighlightsForChapter(int bookId, int chapter) async => [];

  @override
  Future<List<Note>> getNotesForChapter(int bookId, int chapter) async => [];
}

class FakeAudioPlaybackManager implements AudioPlaybackManager {
  @override
  final ValueNotifier<bool> isPlayerVisible = ValueNotifier<bool>(false);

  final BehaviorSubject<PlaybackState> playbackStateSubject =
      BehaviorSubject<PlaybackState>.seeded(
    PlaybackState(
      controls: const [MediaControl.play],
      playing: false,
      processingState: AudioProcessingState.ready,
    ),
  );

  final BehaviorSubject<MediaItem?> mediaItemSubject =
      BehaviorSubject<MediaItem?>.seeded(
    const MediaItem(
      id: 'test_url',
      album: 'Berean Standard Bible',
      title: 'Genesis 1',
      extras: {'bookId': 1, 'chapter': 1},
    ),
  );

  final BehaviorSubject<PositionData> positionDataSubject =
      BehaviorSubject<PositionData>.seeded(
    const PositionData(
      Duration(seconds: 15),
      Duration(seconds: 45),
      Duration(minutes: 3),
    ),
  );

  int? playedBookId;
  int? playedChapter;
  bool playCalled = false;
  bool pauseCalled = false;
  bool stopCalled = false;
  Duration? seekPosition;

  @override
  Stream<PlaybackState> get playbackStateStream => playbackStateSubject.stream;

  @override
  Stream<MediaItem?> get mediaItemStream => mediaItemSubject.stream;

  @override
  Stream<PositionData> get positionDataStream => positionDataSubject.stream;

  @override
  Future<void> playOrToggleChapter(int bookId, int chapter) async {
    playedBookId = bookId;
    playedChapter = chapter;
    isPlayerVisible.value = true;
    mediaItemSubject.add(
      MediaItem(
        id: 'url_$bookId$chapter',
        album: 'Berean Standard Bible',
        title: 'Genesis $chapter',
        extras: {'bookId': bookId, 'chapter': chapter},
      ),
    );
    playbackStateSubject.add(
      PlaybackState(
        controls: const [MediaControl.pause],
        playing: true,
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  @override
  Future<void> play() async {
    playCalled = true;
    isPlayerVisible.value = true;
    playbackStateSubject.add(
      playbackStateSubject.value.copyWith(playing: true),
    );
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    playbackStateSubject.add(
      playbackStateSubject.value.copyWith(playing: false),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    seekPosition = position;
  }

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  @override
  Future<void> closePlayer() async {
    stopCalled = true;
    isPlayerVisible.value = false;
  }

  @override
  bool hasNextChapter(int? bookId, int? chapter) => true;

  @override
  bool hasPreviousChapter(int? bookId, int? chapter) => true;

  @override
  void dispose() {
    isPlayerVisible.dispose();
    playbackStateSubject.close();
    mediaItemSubject.close();
    positionDataSubject.close();
  }

  @override
  BsbAudioHandler get audioHandler => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserSettings userSettings;
  late TabManager tabManager;
  late FakeAudioPlaybackManager audioManager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    getIt.reset();

    userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);

    final dbHelper = FakeDatabaseHelper();
    getIt.registerSingleton<DatabaseHelper>(dbHelper);

    final searchService = BibleSearchService(dbHelper: dbHelper);
    getIt.registerSingleton<BibleSearchService>(searchService);
    final searchManager = SearchManager(
      searchService: searchService,
      userSettings: userSettings,
    );
    getIt.registerSingleton<SearchManager>(searchManager);

    final annotationDb = FakeAnnotationDbHelper();
    getIt.registerSingleton<AnnotationDatabaseHelper>(annotationDb);
    getIt.registerSingleton<AnnotationService>(
      AnnotationService(dbHelper: annotationDb),
    );

    tabManager = TabManager();
    await tabManager.init();
    getIt.registerSingleton<TabManager>(tabManager);

    audioManager = FakeAudioPlaybackManager();
    getIt.registerSingleton<AudioPlaybackManager>(audioManager);
  });

  tearDown(() {
    audioManager.dispose();
    getIt.reset();
  });

  testWidgets('three-dot menu is shown on text page with Search and Play icons, and Plus is visible', (tester) async {
    tabManager.openTab(1, 1); // GEN 1 (text page)

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // The Plus icon must be visible
    expect(find.byIcon(Icons.add), findsOneWidget);

    // The three-dot icon must be visible
    final moreVertButton = find.byIcon(Icons.more_vert);
    expect(moreVertButton, findsOneWidget);

    // Tap the three dots to open the popup menu
    await tester.tap(moreVertButton);
    await tester.pumpAndSettle();

    // Verify Search and Play options with their respective icons exist
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Play Audio'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('selecting Search from three-dot menu navigates to SearchPage', (tester) async {
    tabManager.openTab(1, 1);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Open three-dot menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap Search
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    // Should navigate to SearchPage
    expect(find.byType(SearchPage), findsOneWidget);
  });

  testWidgets('selecting Play Audio from three-dot menu displays AudioPlayerBottomBar', (tester) async {
    tabManager.openTab(1, 1);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Initially audio player is not visible
    expect(find.byType(AudioPlayerBottomBar), findsNothing);

    // Open three-dot menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap Play Audio
    await tester.tap(find.text('Play Audio'));
    await tester.pumpAndSettle();

    // Verify audioManager received the play request
    expect(audioManager.playedBookId, 1);
    expect(audioManager.playedChapter, 1);

    // Verify AudioPlayerBottomBar is shown
    expect(find.byType(AudioPlayerBottomBar), findsOneWidget);
    expect(find.byType(ProgressBar), findsOneWidget);
    expect(find.text('Genesis 1'), findsOneWidget);
  });

  testWidgets('AudioPlayerBottomBar close button closes the player', (tester) async {
    tabManager.openTab(1, 1);
    audioManager.isPlayerVisible.value = true;

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AudioPlayerBottomBar), findsOneWidget);

    // Find and tap close button on the player
    final closePlayerButton = find.byTooltip('Close Player');
    expect(closePlayerButton, findsOneWidget);
    await tester.tap(closePlayerButton);
    await tester.pumpAndSettle();

    expect(audioManager.stopCalled, isTrue);
    expect(audioManager.isPlayerVisible.value, isFalse);
    expect(find.byType(AudioPlayerBottomBar), findsNothing);
  });

  testWidgets('AudioPlayerBottomBar is hidden when entering distraction free mode and restored when exiting', (tester) async {
    tabManager.openTab(1, 1);
    audioManager.isPlayerVisible.value = true;

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Player bar is visible initially
    expect(find.byType(AudioPlayerBottomBar), findsOneWidget);

    // Enter distraction free mode from 3-dot menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Distraction free'));
    await tester.pumpAndSettle();

    // Player bar is now hidden!
    expect(find.byType(AudioPlayerBottomBar), findsNothing);

    // Exit distraction free mode via exit button
    await tester.tap(find.byIcon(Icons.fullscreen_exit));
    await tester.pumpAndSettle();

    // Player bar is restored!
    expect(find.byType(AudioPlayerBottomBar), findsOneWidget);
  });
}
