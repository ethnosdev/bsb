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
  bool get hasLoadedSource => true;

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
  final ValueNotifier<AudioPlayContext> playContextNotifier =
      ValueNotifier<AudioPlayContext>(AudioPlayContext.chapter);

  @override
  final ValueNotifier<AudioRepeatBehavior> repeatBehaviorNotifier =
      ValueNotifier<AudioRepeatBehavior>(AudioRepeatBehavior.continueOn);

  @override
  final ValueNotifier<Reference?> activeRangeNotifier =
      ValueNotifier<Reference?>(null);

  @override
  final ValueNotifier<int?> lockedVerseNotifier = ValueNotifier<int?>(null);

  @override
  final ValueNotifier<String?> audioTabIdNotifier = ValueNotifier<String?>(
    null,
  );

  @override
  final ValueNotifier<int?> currentVerseNotifier = ValueNotifier<int?>(null);

  ChapterTimings? fakeTimings;

  @override
  ChapterTimings? get currentTimings => fakeTimings;

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
  bool nextVerseCalled = false;
  bool prevVerseCalled = false;
  bool hasNextVerseValue = true;
  bool hasPrevVerseValue = true;
  (int, int, int)? playedFromVerse;
  final List<(int, int, int?)> navigatedTabChapters = [];
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
    final title =
        (item?.extras?['chapterTitle'] as String?) ??
        item?.title ??
        'Audio Player';
    if (verse == null) return title;
    return '$title:$verse';
  }

  @override
  Future<void> playFromVerse(int bookId, int chapter, int verse) async {
    playedFromVerse = (bookId, chapter, verse);
    isPlayerVisible.value = true;
  }

  @override
  Future<void> navigateTabToChapter(
    int bookId,
    int chapter, {
    int? targetVerse,
  }) async {
    navigatedTabChapters.add((bookId, chapter, targetVerse));
    _fakeHandler.currentBookId = bookId;
    _fakeHandler.currentChapter = chapter;
    currentVerseNotifier.value = targetVerse;
    mediaItemSubject.add(
      MediaItem(
        id: 'url_${bookId}_$chapter',
        album: 'Berean Standard Bible',
        title: 'Genesis $chapter',
        extras: {'bookId': bookId, 'chapter': chapter},
      ),
    );
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
    if (fakeTimings != null) {
      currentVerseNotifier.value = fakeTimings!.verseAt(position);
    }
  }

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
  }

  @override
  Future<void> setPlayContext(AudioPlayContext context) async {
    playContextNotifier.value = context;
    if (context == AudioPlayContext.verse) {
      lockedVerseNotifier.value = currentVerseNotifier.value ?? 1;
    } else {
      lockedVerseNotifier.value = null;
    }
  }

  @override
  void setRepeatBehavior(AudioRepeatBehavior behavior) {
    repeatBehaviorNotifier.value = behavior;
  }

  @override
  Future<void> playSelection(Reference reference) async {}

  @override
  void dispose() {
    isPlayerVisible.dispose();
    playbackErrorNotifier.dispose();
    speedNotifier.dispose();
    pauseBetweenVersesEnabledNotifier.dispose();
    pauseBetweenVersesSecondsNotifier.dispose();
    versePauseStateNotifier.dispose();
    playContextNotifier.dispose();
    repeatBehaviorNotifier.dispose();
    activeRangeNotifier.dispose();
    lockedVerseNotifier.dispose();
    audioTabIdNotifier.dispose();
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

      // Verify AudioPlayerModalSheet has no legacy chrome, large card, narrator, or chapter buttons
      expect(find.byType(AudioPlayerModalSheet), findsOneWidget);
      expect(find.text('Audio Player'), findsNothing);
      expect(find.text('Go to Chapter'), findsNothing);
      expect(find.byTooltip('Collapse'), findsNothing);
      expect(find.byTooltip('Sync text with audio (Enabled)'), findsNothing);
      expect(find.text('Bob Souer'), findsNothing);
      expect(find.byIcon(Icons.headphones_rounded), findsNothing);
      expect(find.byTooltip('Previous Chapter'), findsNothing);
      expect(find.byTooltip('Next Chapter'), findsNothing);

      // Verify Previous Verse and Next Verse buttons (replacing ±10s)
      final prevVerseButton = find.descendant(
        of: find.byType(AudioPlayerModalSheet),
        matching: find.byTooltip('Previous Verse'),
      );
      final nextVerseButton = find.descendant(
        of: find.byType(AudioPlayerModalSheet),
        matching: find.byTooltip('Next Verse'),
      );
      expect(prevVerseButton, findsOneWidget);
      expect(nextVerseButton, findsOneWidget);
      expect(find.byTooltip('Rewind 10 seconds'), findsNothing);
      expect(find.byTooltip('Forward 10 seconds'), findsNothing);

      await tester.tap(prevVerseButton);
      expect(audioManager.prevVerseCalled, isTrue);

      await tester.tap(nextVerseButton);
      expect(audioManager.nextVerseCalled, isTrue);

      // Verify Speed text button is left of Previous Verse and Pause button is right of Next Verse
      final speedButton = find.byKey(const ValueKey('audio_speed_button'));
      final versePauseButton = find.byKey(
        const ValueKey('audio_verse_pause_button'),
      );
      expect(speedButton, findsOneWidget);
      expect(versePauseButton, findsOneWidget);
      expect(
        tester.getCenter(speedButton).dx,
        lessThan(tester.getCenter(prevVerseButton).dx),
      );
      expect(
        tester.getCenter(versePauseButton).dx,
        greaterThan(tester.getCenter(nextVerseButton).dx),
      );

      // Verify full reference updates in both bottom bar and expanded sheet
      audioManager.currentVerseNotifier.value = 14;
      await tester.pumpAndSettle();
      expect(find.text('Genesis 1:14'), findsNWidgets(2));

      // Verify Repeat and Context buttons open popup bottom sheets (no Range when unset,
      // and Continue after button renders without an icon; options omit subtitles)
      expect(find.text('Continue after'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('audio_repeat_chip')),
          matching: find.byIcon(Icons.arrow_right_alt),
        ),
        findsNothing,
      );
      expect(find.text('Chapter'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('audio_context_chip')));
      await tester.pumpAndSettle();
      expect(find.text('Context'), findsOneWidget);
      expect(find.text('Full chapter'), findsNothing);
      expect(find.text('Range'), findsNothing);
      expect(find.text('Verse'), findsOneWidget);
      expect(find.text('Verse 14'), findsNothing);

      await tester.tap(find.text('Verse'));
      await tester.pumpAndSettle();
      expect(audioManager.playContextNotifier.value, AudioPlayContext.verse);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('audio_context_chip')),
          matching: find.text('Verse'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('audio_repeat_chip')));
      await tester.pumpAndSettle();
      expect(find.text('Stop after'), findsOneWidget);
      expect(find.byIcon(Icons.repeat_one), findsOneWidget);
      expect(find.text('Stop after Verse 14'), findsNothing);
      expect(find.text('Repeat Verse 14'), findsNothing);
      await tester.tap(find.text('Repeat'));
      await tester.pumpAndSettle();
      expect(
        audioManager.repeatBehaviorNotifier.value,
        AudioRepeatBehavior.repeat,
      );
      expect(find.text('Repeat'), findsOneWidget);

      // Verify Speed picker (independent from verse pause)
      expect(find.text('1.0x'), findsOneWidget);
      expect(find.text('0s'), findsOneWidget);
      await tester.tap(speedButton);
      await tester.pumpAndSettle();
      expect(find.text('Playback Speed'), findsOneWidget);
      await tester.tap(find.text('1.5x'));
      await tester.pumpAndSettle();
      expect(audioManager.speedNotifier.value, 1.5);
      expect(find.text('Sleep'), findsNothing);
    },
  );

  testWidgets(
    'AudioPlayerModalSheet updates displayed verse while moving scrubber and on seek',
    (tester) async {
      audioManager.fakeTimings = const ChapterTimings(
        bookId: 1,
        chapter: 1,
        verses: [
          VerseTiming(
            verse: 1,
            start: Duration(seconds: 3),
            end: Duration(minutes: 1),
          ),
          VerseTiming(
            verse: 2,
            start: Duration(minutes: 1),
            end: Duration(minutes: 2),
          ),
          VerseTiming(
            verse: 3,
            start: Duration(minutes: 2),
            end: Duration(minutes: 3),
          ),
        ],
      );
      audioManager.currentVerseNotifier.value = 1;
      tabManager.openTab(1, 1);
      audioManager.isPlayerVisible.value = true;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AudioPlayerBottomBar),
          matching: find.text('Genesis 1:1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AudioPlayerModalSheet),
          matching: find.text('Genesis 1:1'),
        ),
        findsOneWidget,
      );

      final modalProgressBar = find.descendant(
        of: find.byType(AudioPlayerModalSheet),
        matching: find.byType(ProgressBar),
      );
      final rect = tester.getRect(modalProgressBar);
      // Drag across scrubber toward the right side (~2m30s -> Genesis 1:3)
      final gesture = await tester.startGesture(rect.center);
      await tester.pump();
      await gesture.moveTo(Offset(rect.right - 40, rect.center.dy));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(AudioPlayerModalSheet),
          matching: find.text('Genesis 1:3'),
        ),
        findsOneWidget,
      );

      // Releasing seeks and keeps Genesis 1:3 displayed
      await gesture.up();
      await tester.pumpAndSettle();
      expect(audioManager.seekPosition, isNotNull);
      expect(
        find.descendant(
          of: find.byType(AudioPlayerModalSheet),
          matching: find.text('Genesis 1:3'),
        ),
        findsOneWidget,
      );
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
    'Playback speed picker renders list options and fits narrow screens',
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
    'Pause-after-verse picker works independently from playback speed',
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

      // Change speed to 1.5x first
      await tester.tap(find.byKey(const ValueKey('audio_speed_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1.5x'));
      await tester.pumpAndSettle();
      expect(audioManager.speedNotifier.value, 1.5);

      // Open Pause After Verse picker via "0s" button
      expect(find.text('0s'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('audio_verse_pause_button')));
      await tester.pumpAndSettle();

      expect(find.text('Pause After Verse'), findsOneWidget);
      expect(find.text('Off (0s)'), findsOneWidget);
      expect(find.text('Pause duration:'), findsOneWidget);

      // Select 8s preset chip and increment to 9s
      await tester.tap(find.widgetWithText(ChoiceChip, '8s'));
      await tester.pumpAndSettle();
      expect(audioManager.pauseBetweenVersesEnabledNotifier.value, isTrue);
      expect(audioManager.pauseBetweenVersesSecondsNotifier.value, 8);
      expect(find.text('Pause for 8s'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('verse_pause_increment')));
      await tester.pumpAndSettle();
      expect(audioManager.pauseBetweenVersesSecondsNotifier.value, 9);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('9s'), findsOneWidget);
      expect(find.text('1.5x'), findsOneWidget);
      expect(audioManager.speedNotifier.value, 1.5);

      // Selecting Off (0s) turns pause off while keeping speed at 1.5x
      await tester.tap(find.byKey(const ValueKey('audio_verse_pause_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Off (0s)'));
      await tester.pumpAndSettle();
      expect(audioManager.pauseBetweenVersesEnabledNotifier.value, isFalse);
      expect(audioManager.speedNotifier.value, 1.5);
      expect(find.text('0s'), findsOneWidget);
    },
  );

  testWidgets(
    'Verse pause countdown shows in parentheses on mini player and on pause button in expanded sheet',
    (tester) async {
      tabManager.openTab(1, 1);
      audioManager.isPlayerVisible.value = true;
      audioManager.speedNotifier.value = 1.5;
      audioManager.pauseBetweenVersesEnabledNotifier.value = true;
      audioManager.pauseBetweenVersesSecondsNotifier.value = 5;
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

      expect(find.text('Next verse in 4s...'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AudioPlayerBottomBar),
          matching: find.text('Genesis 1:2 (4s)'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(AudioPlayerBottomBar),
          matching: find.text('Genesis 1:2 (4s)'),
        ),
      );
      await tester.pumpAndSettle();

      // Expanded sheet shows full reference without parentheses, countdown on Pause button,
      // and matching neutral foreground color for Speed and Pause buttons.
      expect(
        find.descendant(
          of: find.byType(AudioPlayerModalSheet),
          matching: find.text('Genesis 1:2'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('audio_verse_pause_button')),
          matching: find.text('4s'),
        ),
        findsOneWidget,
      );

      final speedBtn = tester.widget<TextButton>(
        find.byKey(const ValueKey('audio_speed_button')),
      );
      final pauseBtn = tester.widget<TextButton>(
        find.byKey(const ValueKey('audio_verse_pause_button')),
      );
      final prevBtn = tester.widget<IconButton>(
        find.descendant(
          of: find.byType(AudioPlayerModalSheet),
          matching: find.widgetWithIcon(IconButton, Icons.fast_rewind),
        ),
      );
      final expectedColor = Theme.of(
        tester.element(find.byType(AudioPlayerModalSheet)),
      ).colorScheme.onSurfaceVariant;
      expect(speedBtn.style?.foregroundColor?.resolve({}), expectedColor);
      expect(pauseBtn.style?.foregroundColor?.resolve({}), expectedColor);
      expect(prevBtn.style?.foregroundColor?.resolve({}), isNull);

      // Clearing verse pause returns mini player to plain reference and pause button to 5s
      audioManager.versePauseStateNotifier.value = VersePauseState.idle;
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AudioPlayerBottomBar),
          matching: find.text('Genesis 1:2'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('audio_verse_pause_button')),
          matching: find.text('5s'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Range context shows compact label on Context chip and dynamic description in Repeat sheet',
    (tester) async {
      tabManager.openTab(1, 1);
      audioManager.isPlayerVisible.value = true;
      audioManager.activeRangeNotifier.value = Reference(
        bookId: 45,
        chapter: 8,
        verse: 31,
        endVerse: 39,
      );
      audioManager.playContextNotifier.value = AudioPlayContext.range;
      audioManager.repeatBehaviorNotifier.value = AudioRepeatBehavior.stop;

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
      expect(find.text('Stop after'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('audio_repeat_chip')),
          matching: find.byIcon(Icons.repeat_one),
        ),
        findsNothing,
      );

      // Opening Context sheet shows Chapter, active range title without subtitle, and Verse
      await tester.tap(find.byKey(const ValueKey('audio_context_chip')));
      await tester.pumpAndSettle();
      expect(find.text('Context'), findsOneWidget);
      expect(find.text('Romans 8:31–39'), findsOneWidget);
      expect(find.text('Range'), findsNothing);
      await tester.tap(find.text('Chapter'));
      await tester.pumpAndSettle();
      expect(audioManager.playContextNotifier.value, AudioPlayContext.chapter);

      // Switch back to Range and verify Repeat sheet renders cleanly without subtitles
      await tester.tap(find.byKey(const ValueKey('audio_context_chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Romans 8:31–39'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('audio_repeat_chip')));
      await tester.pumpAndSettle();
      expect(find.text('Stop after ROM 8:31–39'), findsNothing);
      expect(find.text('Repeat ROM 8:31–39'), findsNothing);
      await tester.tap(find.text('Repeat'));
      await tester.pumpAndSettle();
      expect(
        audioManager.repeatBehaviorNotifier.value,
        AudioRepeatBehavior.repeat,
      );
    },
  );

  testWidgets(
    'Automatic sync only advances audio tab, and closing audio tab closes player',
    (tester) async {
      tabManager.openTab(1, 1); // Tab 1: Gen 1
      final tab1Id = tabManager.activeTab!.id;
      tabManager.openTab(45, 8); // Tab 2: Rom 8 (active)
      final tab2Id = tabManager.activeTab!.id;

      audioManager.audioTabIdNotifier.value = tab1Id;
      audioManager.isPlayerVisible.value = true;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Audio advances Gen 1 -> Gen 2 -> only Tab 1 advances; Tab 2 stays on Rom 8
      audioManager.onChapterChanged?.call(1, 2);
      await tester.pumpAndSettle();

      expect(tabManager.tabById(tab1Id)?.bookId, 1);
      expect(tabManager.tabById(tab1Id)?.chapter, 2);
      expect(tabManager.activeTab?.id, tab2Id);
      expect(tabManager.activeTab?.bookId, 45);
      expect(tabManager.activeTab?.chapter, 8);

      // Closing Tab 1 closes/stops the audio player automatically
      tabManager.closeTab(tab1Id);
      await tester.pumpAndSettle();

      expect(audioManager.stopCalled, isTrue);
      expect(audioManager.isPlayerVisible.value, isFalse);
      expect(find.byType(AudioPlayerBottomBar), findsNothing);
    },
  );

  testWidgets(
    'AudioPlayerBottomBar uses Previous Verse and Next Verse controls',
    (tester) async {
      tabManager.openTab(1, 1);
      audioManager.isPlayerVisible.value = true;
      audioManager.hasPrevVerseValue = true;
      audioManager.hasNextVerseValue = true;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      final prevVerseFinder = find.descendant(
        of: find.byType(AudioPlayerBottomBar),
        matching: find.byTooltip('Previous Verse'),
      );
      final nextVerseFinder = find.descendant(
        of: find.byType(AudioPlayerBottomBar),
        matching: find.byTooltip('Next Verse'),
      );
      expect(prevVerseFinder, findsOneWidget);
      expect(nextVerseFinder, findsOneWidget);
      expect(find.byTooltip('Previous Chapter'), findsNothing);
      expect(find.byTooltip('Next Chapter'), findsNothing);

      await tester.tap(prevVerseFinder);
      await tester.tap(nextVerseFinder);
      await tester.pumpAndSettle();

      expect(audioManager.prevVerseCalled, isTrue);
      expect(audioManager.nextVerseCalled, isTrue);
    },
  );

  testWidgets(
    'Navigating chapters in audio tab syncs player without Return chip, leaving other tabs untouched',
    (tester) async {
      tabManager.openTab(1, 1); // Tab 1: Gen 1
      final tab1Id = tabManager.activeTab!.id;
      audioManager.audioTabIdNotifier.value = tab1Id;
      audioManager.isPlayerVisible.value = true;
      audioManager._fakeHandler.currentBookId = 1;
      audioManager._fakeHandler.currentChapter = 1;
      audioManager.mediaItemSubject.add(
        const MediaItem(
          id: 'gen1',
          album: 'Berean Standard Bible',
          title: 'Genesis 1',
          extras: {'bookId': 1, 'chapter': 1},
        ),
      );
      audioManager.playbackStateSubject.add(
        PlaybackState(
          controls: const [MediaControl.pause],
          playing: true,
          processingState: AudioProcessingState.ready,
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      audioManager.onChapterChanged?.call(1, 1);
      await tester.pumpAndSettle();

      // Swipe in Tab 1 to Genesis 2 -> syncs player without any Return chip
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await tester.pumpAndSettle();

      expect(tabManager.activeTab?.chapter, 2);
      expect(audioManager.navigatedTabChapters, [(1, 2, null)]);
      expect(find.textContaining('Return to'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AudioPlayerBottomBar),
          matching: find.text('Genesis 2'),
        ),
        findsOneWidget,
      );

      // Pause audio, then swipe back to Genesis 1 ->
      // player cues Genesis 1 while staying paused
      audioManager.playbackStateSubject.add(
        PlaybackState(
          controls: const [MediaControl.play],
          playing: false,
          processingState: AudioProcessingState.ready,
        ),
      );
      await tester.fling(find.byType(PageView), const Offset(400, 0), 800);
      await tester.pumpAndSettle();

      expect(audioManager.navigatedTabChapters.last, (1, 1, null));
      expect(
        audioManager.playbackStateSubject.value.playing,
        isFalse,
      );
      expect(find.textContaining('Return to'), findsNothing);

      // Opening a second tab and browsing to Matthew 5 leaves Tab 1's audio untouched
      final callsBeforeTab2 = audioManager.navigatedTabChapters.length;
      tabManager.openTab(40, 5);
      await tester.pumpAndSettle();
      expect(audioManager.navigatedTabChapters.length, callsBeforeTab2);
      expect(audioManager._fakeHandler.currentBookId, 1);
      expect(audioManager._fakeHandler.currentChapter, 1);
    },
  );

  testWidgets(
    'Auto-scrolling audio verse positions verse near top of viewport',
    (tester) async {
      final db = getIt<DatabaseHelper>() as FakeDatabaseHelper;
      db.chapterLines = List.generate(
        40,
        (i) => UsfmLine(
          bookChapterVerse: 1001000 + (i + 1),
          text:
              'In verse ${i + 1}, here is plenty of text so the chapter scrolls well past the bottom of the screen. ' *
              3,
          format: (i % 2 == 0) ? ParagraphFormat.p : ParagraphFormat.m,
        ),
      );

      audioManager.isPlayerVisible.value = true;
      audioManager.currentVerseNotifier.value = 1;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChapterText(bookId: 1, chapter: 1)),
        ),
      );
      await tester.pumpAndSettle();

      // Advance audio to verse 20 (off-screen below viewport bottom)
      audioManager.currentVerseNotifier.value = 20;
      await tester.pumpAndSettle();

      final rootRenderObject = tester.renderObject(find.byType(ChapterText));
      double? verse20ScreenDy;
      void findVerse(RenderObject node) {
        if (verse20ScreenDy != null) return;
        if (node is RenderVerseNumber && node.number == '20') {
          verse20ScreenDy = node.localToGlobal(Offset.zero).dy;
          return;
        }
        node.visitChildren(findVerse);
      }

      rootRenderObject.visitChildren(findVerse);
      expect(verse20ScreenDy, isNotNull);
      // Should sit near the top (well above mid-screen at 300px on a 600px test viewport)
      expect(verse20ScreenDy!, lessThan(80.0));
    },
  );

  testWidgets(
    'Small manual drag keeping active verse on screen does not delay bottom auto-scroll or trigger Jump chip',
    (tester) async {
      final db = getIt<DatabaseHelper>() as FakeDatabaseHelper;
      db.chapterLines = List.generate(
        40,
        (i) => UsfmLine(
          bookChapterVerse: 1001000 + (i + 1),
          text:
              'In verse ${i + 1}, here is plenty of text so the chapter scrolls well past the bottom of the screen. ' *
              3,
          format: (i % 2 == 0) ? ParagraphFormat.p : ParagraphFormat.m,
        ),
      );

      audioManager.isPlayerVisible.value = true;
      audioManager.currentVerseNotifier.value = 2;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChapterText(bookId: 1, chapter: 1)),
        ),
      );
      await tester.pumpAndSettle();

      // Small manual drag that leaves verse 2 visible inside the viewport
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -10));
      await tester.pumpAndSettle();

      // Advance audio to verse 20 (at/below bottom of viewport)
      audioManager.currentVerseNotifier.value = 20;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Jump to verse 20'), findsNothing);
      await tester.pumpAndSettle();

      final rootRenderObject = tester.renderObject(find.byType(ChapterText));
      double? verse20ScreenDy;
      void findVerse(RenderObject node) {
        if (verse20ScreenDy != null) return;
        if (node is RenderVerseNumber && node.number == '20') {
          verse20ScreenDy = node.localToGlobal(Offset.zero).dy;
          return;
        }
        node.visitChildren(findVerse);
      }

      rootRenderObject.visitChildren(findVerse);
      expect(verse20ScreenDy, isNotNull);
      expect(verse20ScreenDy!, lessThan(80.0));
      expect(find.text('Jump to verse 20'), findsNothing);
    },
  );

  testWidgets(
    'Scrolling active verse off screen pauses auto-scroll and shows Jump to verse chip',
    (tester) async {
      final db = getIt<DatabaseHelper>() as FakeDatabaseHelper;
      db.chapterLines = List.generate(
        40,
        (i) => UsfmLine(
          bookChapterVerse: 1001000 + (i + 1),
          text:
              'In verse ${i + 1}, here is plenty of text so the chapter scrolls well past the bottom of the screen. ' *
              3,
          format: (i % 2 == 0) ? ParagraphFormat.p : ParagraphFormat.m,
        ),
      );

      audioManager.isPlayerVisible.value = true;
      audioManager.currentVerseNotifier.value = 1;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChapterText(bookId: 1, chapter: 1)),
        ),
      );
      await tester.pumpAndSettle();

      // Intentionally scroll way down so verse 1 is off-screen
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1200));
      await tester.pumpAndSettle();

      audioManager.currentVerseNotifier.value = 2;
      await tester.pumpAndSettle();
      expect(find.text('Jump to verse 2'), findsOneWidget);

      await tester.tap(find.text('Jump to verse 2'));
      await tester.pumpAndSettle();
      expect(find.text('Jump to verse 2'), findsNothing);
    },
  );

  testWidgets(
    'ChapterText does not rebuild on same-chapter MediaItem title updates or other-chapter verse changes',
    (tester) async {
      final db = getIt<DatabaseHelper>() as FakeDatabaseHelper;
      db.chapterLines = [
        UsfmLine(
          bookChapterVerse: 1001001,
          text: 'In the beginning God created the heavens and the earth.',
          format: ParagraphFormat.p,
        ),
        UsfmLine(
          bookChapterVerse: 1001002,
          text: 'Now the earth was formless and void.',
          format: ParagraphFormat.m,
        ),
      ];

      audioManager.isPlayerVisible.value = true;
      audioManager.currentVerseNotifier.value = 1;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChapterText(bookId: 1, chapter: 1)),
        ),
      );
      await tester.pumpAndSettle();

      final initialUsfm = tester.widget<UsfmWidget>(find.byType(UsfmWidget));

      // Same-chapter MediaItem countdown title updates should not rebuild ChapterText
      audioManager.mediaItemSubject.add(
        const MediaItem(
          id: 'test_url',
          album: 'Berean Standard Bible',
          title: 'Genesis 1:1 (4s)',
          extras: {'bookId': 1, 'chapter': 1},
        ),
      );
      await tester.pump();
      expect(
        identical(tester.widget<UsfmWidget>(find.byType(UsfmWidget)), initialUsfm),
        isTrue,
      );

      // Actual verse advance on the playing chapter rebuilds to update highlight
      audioManager.currentVerseNotifier.value = 2;
      await tester.pump();
      expect(
        identical(tester.widget<UsfmWidget>(find.byType(UsfmWidget)), initialUsfm),
        isFalse,
      );

      // Non-playing chapter ignores verse advances on another chapter
      await tester.pumpWidget(
        const MaterialApp(
          key: ValueKey('other_chapter'),
          home: Scaffold(body: ChapterText(bookId: 1, chapter: 2)),
        ),
      );
      await tester.pumpAndSettle();
      final otherChapterInitial = tester.widget<UsfmWidget>(
        find.byType(UsfmWidget),
      );

      audioManager.currentVerseNotifier.value = 3;
      audioManager.mediaItemSubject.add(
        const MediaItem(
          id: 'test_url',
          album: 'Berean Standard Bible',
          title: 'Genesis 1:3',
          extras: {'bookId': 1, 'chapter': 1},
        ),
      );
      await tester.pump();
      expect(
        identical(
          tester.widget<UsfmWidget>(find.byType(UsfmWidget)),
          otherChapterInitial,
        ),
        isTrue,
      );
    },
  );
}
