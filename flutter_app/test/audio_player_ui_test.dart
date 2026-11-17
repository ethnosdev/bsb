import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/audio/audio_models.dart';
import 'package:bsb/infrastructure/audio/audio_playback_manager.dart';
import 'package:bsb/infrastructure/audio/bsb_audio_handler.dart';
import 'package:bsb/infrastructure/audio/verse_timings.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/search/bible_search_service.dart';
import 'package:bsb/ui/audio/audio_player_bottom_bar.dart';
import 'package:bsb/ui/audio/audio_player_modal_sheet.dart';
import 'package:bsb/ui/home/home.dart';
import 'package:bsb/ui/search/search_manager.dart';
import 'package:bsb/ui/search/search_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/text/chapter/chapter_text.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeDatabaseHelper implements DatabaseHelper {
  List<UsfmLine> chapterLines = const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async =>
      chapterLines;

  @override
  Future<List<UsfmLine>> getRange(Reference reference) async => [];
}

class FakeAnnotationDbHelper implements AnnotationDatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Highlight>> getHighlightsForChapter(
    int bookId,
    int chapter,
  ) async => [];

  @override
  Future<List<Note>> getNotesForChapter(int bookId, int chapter) async => [];
}

class FakeBsbAudioHandler implements BsbAudioHandler {
  @override
  int? currentBookId = 1;

  @override
  int? currentChapter = 1;

  @override
  final BehaviorSubject<MediaItem?> mediaItem =
      BehaviorSubject<MediaItem?>.seeded(
        const MediaItem(
          id: 'test_url',
          album: 'Berean Standard Bible',
          title: 'Genesis 1',
          extras: {'bookId': 1, 'chapter': 1},
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAudioPlaybackManager implements AudioPlaybackManager {
  @override
  final ValueNotifier<bool> isPlayerVisible = ValueNotifier<bool>(false);

  @override
  final ValueNotifier<String?> playbackErrorNotifier = ValueNotifier<String?>(
    null,
  );

  @override
  final ValueNotifier<double> speedNotifier = ValueNotifier<double>(1.0);

  @override
  final ValueNotifier<bool> pauseBetweenVersesEnabledNotifier =
      ValueNotifier<bool>(false);

  @override
  final ValueNotifier<int> pauseBetweenVersesSecondsNotifier =
      ValueNotifier<int>(kDefaultVersePauseSeconds);

  @override
  final ValueNotifier<VersePauseState> versePauseStateNotifier =
      ValueNotifier<VersePauseState>(VersePauseState.idle);

  @override
  final ValueNotifier<AudioPlayMode> playModeNotifier =
      ValueNotifier<AudioPlayMode>(AudioPlayMode.continuous);

  @override
  final ValueNotifier<Reference?> repeatPassageNotifier =
      ValueNotifier<Reference?>(null);

  @override
  final ValueNotifier<SleepTimerOption> sleepTimerOptionNotifier =
      ValueNotifier<SleepTimerOption>(SleepTimerOption.off);

  @override
  final ValueNotifier<Duration?> sleepTimerRemainingNotifier =
      ValueNotifier<Duration?>(null);

  @override
  final ValueNotifier<bool> syncTextNotifier = ValueNotifier<bool>(true);

  @override
  final ValueNotifier<int?> currentVerseNotifier = ValueNotifier<int?>(null);

  @override
  ChapterTimings? get currentTimings => null;

  @override
  void Function(int bookId, int chapter)? onChapterChanged;

  @override
  final UserSettings? userSettings = null;

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
  bool forward10Called = false;
  bool backward10Called = false;
  bool nextVerseCalled = false;
  bool prevVerseCalled = false;
  bool hasNextVerseValue = true;
  bool hasPrevVerseValue = true;
  (int, int, int)? playedFromVerse;
  Duration? seekPosition;

  final _fakeHandler = FakeBsbAudioHandler();

  @override
  BsbAudioHandler get audioHandler => _fakeHandler;

  @override
  Stream<PlaybackState> get playbackStateStream => playbackStateSubject.stream;

  @override
  Stream<MediaItem?> get mediaItemStream => mediaItemSubject.stream;

  @override
  Stream<PositionData> get positionDataStream => positionDataSubject.stream;

  @override
  String formatDisplayTitle(MediaItem? item, int? verse) {
    final title = item?.title ?? 'Audio Player';
    if (verse == null) return title;
    return '$title:$verse';
  }

  @override
  Future<void> playFromVerse(int bookId, int chapter, int verse) async {
    playedFromVerse = (bookId, chapter, verse);
    isPlayerVisible.value = true;
  }

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
  Future<void> seekForward10() async {
    forward10Called = true;
  }

  @override
  Future<void> seekBackward10() async {
    backward10Called = true;
  }

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  @override
  Future<void> skipToNextVerse() async {
    nextVerseCalled = true;
  }

  @override
  Future<void> skipToPreviousVerse() async {
    prevVerseCalled = true;
  }

  @override
  bool hasNextVerse(Duration position) => hasNextVerseValue;

  @override
  bool hasPreviousVerse(Duration position) => hasPrevVerseValue;

  @override
  Future<void> closePlayer() async {
    stopCalled = true;
    isPlayerVisible.value = false;
  }

  @override
  Future<void> setSpeed(double speed) async {
    speedNotifier.value = speed;
    pauseBetweenVersesEnabledNotifier.value = false;
  }

  @override
  Future<void> setPauseBetweenVerses({
    required bool enabled,
    int? seconds,
  }) async {
    if (seconds != null) {
      pauseBetweenVersesSecondsNotifier.value = seconds.clamp(
        kMinVersePauseSeconds,
        kMaxVersePauseSeconds,
      );
    }
    pauseBetweenVersesEnabledNotifier.value = enabled;
    if (enabled) {
      speedNotifier.value = 1.0;
    }
  }

  @override
  void setPlayMode(AudioPlayMode mode) {
    playModeNotifier.value = mode;
  }

  @override
  Future<void> setRepeatPassage(
    Reference passage, {
    bool playImmediately = true,
    bool forceRestart = false,
  }) async {
    repeatPassageNotifier.value = passage;
    playModeNotifier.value = AudioPlayMode.repeatPassage;
  }

  @override
  Future<void> playSelection(Reference reference) async {}

  @override
  void cyclePlayMode() {
    final nextMode = switch (playModeNotifier.value) {
      AudioPlayMode.continuous => AudioPlayMode.repeatChapter,
      AudioPlayMode.repeatChapter => AudioPlayMode.stopAfterChapter,
      AudioPlayMode.stopAfterChapter => AudioPlayMode.repeatVerse,
      AudioPlayMode.repeatVerse =>
        repeatPassageNotifier.value != null
            ? AudioPlayMode.repeatPassage
            : AudioPlayMode.continuous,
      AudioPlayMode.repeatPassage => AudioPlayMode.continuous,
    };
    setPlayMode(nextMode);
  }

  @override
  void setSleepTimer(SleepTimerOption option) {
    sleepTimerOptionNotifier.value = option;
  }

  @override
  void setSyncText(bool sync) {
    syncTextNotifier.value = sync;
  }

  @override
  bool hasNextChapter(int? bookId, int? chapter) => true;

  @override
  bool hasPreviousChapter(int? bookId, int? chapter) => true;

  @override
  void dispose() {
    isPlayerVisible.dispose();
    playbackErrorNotifier.dispose();
    speedNotifier.dispose();
    pauseBetweenVersesEnabledNotifier.dispose();
    pauseBetweenVersesSecondsNotifier.dispose();
    versePauseStateNotifier.dispose();
    playModeNotifier.dispose();
    repeatPassageNotifier.dispose();
    sleepTimerOptionNotifier.dispose();
    sleepTimerRemainingNotifier.dispose();
    syncTextNotifier.dispose();
    currentVerseNotifier.dispose();
    playbackStateSubject.close();
    mediaItemSubject.close();
    positionDataSubject.close();
  }
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

  testWidgets(
    'three-dot menu is shown on text page with Search and Play icons, and Plus is visible',
    (tester) async {
      tabManager.openTab(1, 1); // GEN 1 (text page)

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
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
    },
  );

  testWidgets('selecting Search from three-dot menu navigates to SearchPage', (
    tester,
  ) async {
    tabManager.openTab(1, 1);

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
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

  testWidgets(
    'selecting Play Audio from three-dot menu displays AudioPlayerBottomBar',
    (tester) async {
      tabManager.openTab(1, 1);

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
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
      expect(
        find.descendant(
          of: find.byType(AudioPlayerBottomBar),
          matching: find.text('Genesis 1'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('AudioPlayerBottomBar close button closes the player', (
    tester,
  ) async {
    tabManager.openTab(1, 1);
    audioManager.isPlayerVisible.value = true;

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
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

  testWidgets(
    'AudioPlayerBottomBar is hidden when entering distraction free mode and restored when exiting',
    (tester) async {
      tabManager.openTab(1, 1);
      audioManager.isPlayerVisible.value = true;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Player bar is visible initially
      expect(find.byType(AudioPlayerBottomBar), findsOneWidget);

      // Enter distraction free mode by tapping the text screen
      await tester.tapAt(const Offset(200, 300));
      await tester.pumpAndSettle();

      // Player bar is now hidden!
      expect(find.byType(AudioPlayerBottomBar), findsNothing);

      // Exit distraction free mode via tapping the text screen
      await tester.tapAt(const Offset(200, 300));
      await tester.pumpAndSettle();

      // Player bar is restored!
      expect(find.byType(AudioPlayerBottomBar), findsOneWidget);
    },
  );

  testWidgets(
    'tapping mini player expands AudioPlayerModalSheet with controls',
    (tester) async {
      tabManager.openTab(1, 1);
      audioManager.isPlayerVisible.value = true;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Tap on the mini player title area to open modal sheet
      final miniPlayerTitle = find.descendant(
        of: find.byType(AudioPlayerBottomBar),
        matching: find.text('Genesis 1'),
      );
      await tester.tap(miniPlayerTitle);
      await tester.pumpAndSettle();

      // Verify AudioPlayerModalSheet is displayed
      expect(find.byType(AudioPlayerModalSheet), findsOneWidget);
      expect(find.text('Audio Player'), findsOneWidget);
      expect(find.text('Bob Souer'), findsOneWidget);

      // Verify Previous Verse and Next Verse buttons (replacing ±10s)
      final prevVerseButton = find.byTooltip('Previous Verse');
      final nextVerseButton = find.byTooltip('Next Verse');
      expect(prevVerseButton, findsOneWidget);
      expect(nextVerseButton, findsOneWidget);
      expect(find.byTooltip('Rewind 10 seconds'), findsNothing);
      expect(find.byTooltip('Forward 10 seconds'), findsNothing);

      await tester.tap(prevVerseButton);
      expect(audioManager.prevVerseCalled, isTrue);

      await tester.tap(nextVerseButton);
      expect(audioManager.nextVerseCalled, isTrue);

      // Verify live verse reference updates in both bottom bar and expanded sheet
      audioManager.currentVerseNotifier.value = 14;
      await tester.pumpAndSettle();
      expect(find.text('Genesis 1:14'), findsNWidgets(2));

      // Verify Play Mode button opens Repeat Mode popup list instead of cycling
      expect(find.text('Continuous'), findsOneWidget);
      await tester.tap(find.text('Continuous'));
      await tester.pumpAndSettle();
      expect(find.text('Repeat Mode'), findsOneWidget);
      expect(find.text('Repeat Chapter'), findsOneWidget);
      expect(find.text('1 Chapter'), findsOneWidget);
      expect(find.text('Repeat Verse'), findsOneWidget);
      expect(find.text('Repeat Passage'), findsOneWidget);

      await tester.tap(find.text('Repeat Verse'));
      await tester.pumpAndSettle();
      expect(audioManager.playModeNotifier.value, AudioPlayMode.repeatVerse);
      expect(find.text('Repeat Verse'), findsOneWidget);

      // Verify Speed picker
      expect(find.text('1.0x'), findsOneWidget);
      await tester.tap(find.text('1.0x'));
      await tester.pumpAndSettle();
      expect(find.text('Playback Speed'), findsOneWidget);
      await tester.tap(find.text('1.5x'));
      await tester.pumpAndSettle();
      expect(audioManager.speedNotifier.value, 1.5);

      // Verify Sleep timer picker
      expect(find.text('Sleep'), findsOneWidget);
      await tester.tap(find.text('Sleep'));
      await tester.pumpAndSettle();
      expect(find.text('Sleep Timer'), findsOneWidget);
      await tester.tap(find.text('15 minutes'));
      await tester.pumpAndSettle();
      expect(
        audioManager.sleepTimerOptionNotifier.value,
        SleepTimerOption.fifteenMinutes,
      );

      // Verify sync text toggle
      expect(audioManager.syncTextNotifier.value, isTrue);
      final syncButton = find.byTooltip('Sync text with audio (Enabled)');
      expect(syncButton, findsOneWidget);
      await tester.tap(syncButton);
      await tester.pumpAndSettle();
      expect(audioManager.syncTextNotifier.value, isFalse);

      // Collapse sheet
      await tester.tap(find.byTooltip('Collapse'));
      await tester.pumpAndSettle();
      expect(find.byType(AudioPlayerModalSheet), findsNothing);
    },
  );

  testWidgets('audioManager onChapterChanged updates active tab in HomePage', (
    tester,
  ) async {
    tabManager.openTab(1, 1); // Gen 1

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(tabManager.activeTab?.bookId, 1);
    expect(tabManager.activeTab?.chapter, 1);

    // Trigger onChapterChanged callback (simulating chapter advance in audio)
    audioManager.onChapterChanged?.call(1, 2);
    await tester.pumpAndSettle();

    // Verify active tab updated to Gen 2
    expect(tabManager.activeTab?.bookId, 1);
    expect(tabManager.activeTab?.chapter, 2);
  });

  testWidgets(
    'Playback speed picker renders list options like sleep timer and fits narrow screens',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      tabManager.openTab(1, 1);
      audioManager.isPlayerVisible.value = true;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Tap on the mini player title area to open modal sheet
      final miniPlayerTitle = find.descendant(
        of: find.byType(AudioPlayerBottomBar),
        matching: find.text('Genesis 1'),
      );
      await tester.tap(miniPlayerTitle);
      await tester.pumpAndSettle();

      // Open speed picker
      await tester.tap(find.text('1.0x'));
      await tester.pumpAndSettle();

      expect(find.text('Playback Speed'), findsOneWidget);
      expect(find.text('1.0x (Normal)'), findsOneWidget);
      expect(find.text('0.75x'), findsOneWidget);
      expect(find.text('2.0x'), findsOneWidget);

      // Verify radio icon is checked for 1.0
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

      // Select 2.0x
      await tester.tap(find.text('2.0x'));
      await tester.pumpAndSettle();

      expect(audioManager.speedNotifier.value, 2.0);
    },
  );

  testWidgets(
    'ChapterText highlights current audio verse only when chapter matches and player is visible',
    (tester) async {
      final db = getIt<DatabaseHelper>() as FakeDatabaseHelper;
      db.chapterLines = [
        UsfmLine(
          bookChapterVerse: 1001001,
          text: 'In the beginning',
          format: ParagraphFormat.p,
        ),
        UsfmLine(
          bookChapterVerse: 1001002,
          text: 'Now the earth was formless',
          format: ParagraphFormat.p,
        ),
      ];

      audioManager.isPlayerVisible.value = true;
      audioManager.currentVerseNotifier.value = 2;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChapterText(bookId: 1, chapter: 1)),
        ),
      );
      await tester.pumpAndSettle();

      UsfmWidget usfm = tester.widget<UsfmWidget>(find.byType(UsfmWidget));
      expect(usfm.highlights.length, 1);
      expect(usfm.highlights.first.startId, 1001002000);
      expect(usfm.highlights.first.endId, 1001002999);

      // Hidden during announcement (currentVerse == null)
      audioManager.currentVerseNotifier.value = null;
      await tester.pumpAndSettle();
      usfm = tester.widget<UsfmWidget>(find.byType(UsfmWidget));
      expect(usfm.highlights, isEmpty);

      // Hidden when player is closed
      audioManager.currentVerseNotifier.value = 2;
      audioManager.isPlayerVisible.value = false;
      await tester.pumpAndSettle();
      usfm = tester.widget<UsfmWidget>(find.byType(UsfmWidget));
      expect(usfm.highlights, isEmpty);

      // Hidden when displayed chapter does not match loaded audio chapter
      audioManager.isPlayerVisible.value = true;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChapterText(bookId: 1, chapter: 2)),
        ),
      );
      await tester.pumpAndSettle();
      usfm = tester.widget<UsfmWidget>(find.byType(UsfmWidget));
      expect(usfm.highlights, isEmpty);
    },
  );

  testWidgets(
    'Speed picker inline pause-between-verses updates seconds and chip label',
    (tester) async {
      tabManager.openTab(1, 1);
      audioManager.isPlayerVisible.value = true;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AudioPlayerBottomBar),
          matching: find.text('Genesis 1'),
        ),
      );
      await tester.pumpAndSettle();

      // Open Speed picker
      await tester.tap(find.text('1.0x'));
      await tester.pumpAndSettle();

      expect(find.text('1.0x (with 5 second pause)'), findsOneWidget);
      await tester.tap(find.text('1.0x (with 5 second pause)'));
      await tester.pumpAndSettle();

      expect(audioManager.pauseBetweenVersesEnabledNotifier.value, isTrue);
      expect(audioManager.pauseBetweenVersesSecondsNotifier.value, 5);
      expect(find.text('Pause duration:'), findsOneWidget);

      // Select 8s preset chip and increment to 9s
      await tester.tap(find.widgetWithText(ChoiceChip, '8s'));
      await tester.pumpAndSettle();
      expect(audioManager.pauseBetweenVersesSecondsNotifier.value, 8);
      expect(find.text('1.0x (with 8 second pause)'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('verse_pause_increment')));
      await tester.pumpAndSettle();
      expect(audioManager.pauseBetweenVersesSecondsNotifier.value, 9);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('1.0x (9s)'), findsOneWidget);

      // Switching back to standard speed turns pause off
      await tester.tap(find.text('1.0x (9s)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1.5x'));
      await tester.pumpAndSettle();
      expect(audioManager.pauseBetweenVersesEnabledNotifier.value, isFalse);
      expect(audioManager.speedNotifier.value, 1.5);
    },
  );

  testWidgets(
    'Countdown status text appears in mini player and expanded sheet during verse pause',
    (tester) async {
      tabManager.openTab(1, 1);
      audioManager.isPlayerVisible.value = true;
      audioManager.currentVerseNotifier.value = 2;
      audioManager.versePauseStateNotifier.value = const VersePauseState(
        isPaused: true,
        remainingSeconds: 4,
        totalSeconds: 5,
        nextBookId: 1,
        nextChapter: 1,
        nextVerse: 2,
      );

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AudioPlayerBottomBar),
          matching: find.text('Next verse in 4s...'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(AudioPlayerBottomBar),
          matching: find.text('Genesis 1:2'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AudioPlayerModalSheet),
          matching: find.text('Next verse in 4s...'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Repeat Passage shows compact range on chip and opens PassageRangePickerDialog on edit',
    (tester) async {
      tabManager.openTab(1, 1);
      audioManager.isPlayerVisible.value = true;
      audioManager.repeatPassageNotifier.value = Reference(
        bookId: 45,
        chapter: 8,
        verse: 31,
        endVerse: 39,
      );
      audioManager.playModeNotifier.value = AudioPlayMode.repeatPassage;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AudioPlayerBottomBar),
          matching: find.text('Genesis 1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ROM 8:31–39'), findsOneWidget);
      await tester.tap(find.text('ROM 8:31–39'));
      await tester.pumpAndSettle();

      expect(find.text('Repeat Mode'), findsOneWidget);
      expect(find.text('Romans 8:31–39'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('edit_repeat_passage_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Scripture Passage'), findsOneWidget);
      expect(find.text('Repeat Passage'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );
}
