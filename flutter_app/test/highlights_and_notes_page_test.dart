import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/annotations/highlights_and_notes_page.dart';
import 'package:bsb/ui/home/drawer.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/text/note_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAnnotationDbHelper implements AnnotationDatabaseHelper {
  final List<Highlight> _highlights = [];
  final List<Note> _notes = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Highlight>> getAllHighlights({String orderBy = 'updated_at DESC'}) async {
    final list = List<Highlight>.from(_highlights);
    if (orderBy.contains('start_word_id') || orderBy.contains('book_id')) {
      list.sort((a, b) {
        final bComp = a.bookId.compareTo(b.bookId);
        if (bComp != 0) return bComp;
        final cComp = a.chapter.compareTo(b.chapter);
        if (cComp != 0) return cComp;
        return a.startWordId.compareTo(b.startWordId);
      });
    } else if (orderBy.contains('ASC')) {
      list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    } else {
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return list;
  }

  @override
  Future<List<Note>> getAllNotes({String orderBy = 'updated_at DESC'}) async {
    final list = List<Note>.from(_notes);
    if (orderBy.contains('start_word_id') || orderBy.contains('book_id')) {
      list.sort((a, b) {
        final bComp = a.bookId.compareTo(b.bookId);
        if (bComp != 0) return bComp;
        final cComp = a.chapter.compareTo(b.chapter);
        if (cComp != 0) return cComp;
        return a.startWordId.compareTo(b.startWordId);
      });
    } else if (orderBy.contains('ASC')) {
      list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    } else {
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return list;
  }

  @override
  Future<void> insertHighlight(Highlight highlight) async {
    _highlights.removeWhere((h) => h.id == highlight.id);
    _highlights.add(highlight);
  }

  @override
  Future<void> updateHighlight(Highlight highlight) async {
    final idx = _highlights.indexWhere((h) => h.id == highlight.id);
    if (idx != -1) {
      _highlights[idx] = highlight;
    }
  }

  @override
  Future<void> deleteHighlight(String id) async {
    _highlights.removeWhere((h) => h.id == id);
  }

  @override
  Future<Highlight?> getHighlightById(String id) async {
    try {
      return _highlights.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearAllHighlights() async {
    _highlights.clear();
  }

  @override
  Future<void> batchInsertHighlights(List<Highlight> highlights) async {
    for (final h in highlights) {
      await insertHighlight(h);
    }
  }

  @override
  Future<void> insertNote(Note note) async {
    _notes.removeWhere((n) => n.id == note.id);
    _notes.add(note);
  }

  @override
  Future<void> updateNote(Note note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      _notes[idx] = note;
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
  }

  @override
  Future<void> clearAllNotes() async {
    _notes.clear();
  }

  @override
  Future<void> batchInsertNotes(List<Note> notes) async {
    for (final n in notes) {
      await insertNote(n);
    }
  }

  @override
  Future<Note?> getNoteById(String id) async {
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }
}

class FakeDatabaseHelper implements DatabaseHelper {
  final Map<int, String> verseTexts = {};
  final Map<String, String> rangeTexts = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String?> getVerseText(int reference) async {
    return verseTexts[reference];
  }

  @override
  Future<String?> getTextForRange({
    required int bookId,
    required int chapter,
    required int startWordId,
    required int endWordId,
  }) async {
    final key = '${startWordId}_$endWordId';
    return rangeTexts[key];
  }
}

class TrackingTabManager extends TabManager {
  int? openedBookId;
  int? openedChapter;
  int? openedVerse;

  @override
  Future<void> openTab(int bookId, int chapter, [String? title, int? targetVerse]) async {
    openedBookId = bookId;
    openedChapter = chapter;
    openedVerse = targetVerse;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAnnotationDbHelper fakeAnnotationDb;
  late AnnotationService annotationService;
  late FakeDatabaseHelper fakeDbHelper;
  late TrackingTabManager trackingTabManager;
  late UserSettings userSettings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();

    userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);

    fakeAnnotationDb = FakeAnnotationDbHelper();
    annotationService = AnnotationService(dbHelper: fakeAnnotationDb);
    getIt.registerSingleton<AnnotationDatabaseHelper>(fakeAnnotationDb);
    getIt.registerSingleton<AnnotationService>(annotationService);

    fakeDbHelper = FakeDatabaseHelper();
    fakeDbHelper.verseTexts[1001001] = 'In the beginning God created the heavens and the earth.';
    fakeDbHelper.verseTexts[43003016] = 'For God so loved the world that He gave His one and only Son.';
    getIt.registerSingleton<DatabaseHelper>(fakeDbHelper);

    trackingTabManager = TrackingTabManager();
    getIt.registerSingleton<TabManager>(trackingTabManager);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildTestableApp({int initialTabIndex = 0}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HighlightsAndNotesPage(
                      initialTabIndex: initialTabIndex,
                    ),
                  ),
                );
              },
              child: const Text('Open Page'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openPage(WidgetTester tester, {int initialTabIndex = 0}) async {
    await tester.pumpWidget(buildTestableApp(initialTabIndex: initialTabIndex));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();
  }

  testWidgets('AppDrawer contains Highlights & Notes option and navigates to page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const AppDrawer(),
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('Open Drawer'),
            ),
          ),
        ),
      ),
    );

    // Open the drawer
    await tester.tap(find.text('Open Drawer'));
    await tester.pumpAndSettle();

    // Verify 'Highlights & Notes' list tile exists
    final tileFinder = find.text('Highlights & Notes');
    expect(tileFinder, findsOneWidget);

    // Tap 'Highlights & Notes'
    await tester.tap(tileFinder);
    await tester.pumpAndSettle();

    // Verify we navigated to HighlightsAndNotesPage
    expect(find.byType(HighlightsAndNotesPage), findsOneWidget);
    expect(find.text('Highlights'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });

  testWidgets('Highlights tab displays empty state when no highlights exist', (tester) async {
    await openPage(tester);

    expect(find.text('No highlights yet'), findsOneWidget);
    expect(find.textContaining('Long press a verse in the Bible reader'), findsOneWidget);
  });

  testWidgets('Highlights tab displays highlights with snippets and navigates on tap', (tester) async {
    // Add a highlight in Genesis 1:1 (book 1, ch 1, v 1, words 1..5)
    final h1 = Highlight(
      id: 'h1',
      bookId: 1,
      chapter: 1,
      startWordId: 1001001001,
      endWordId: 1001001005,
      color: HighlightColor.yellow,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );
    await fakeAnnotationDb.insertHighlight(h1);

    await openPage(tester);

    // Verify highlight is rendered
    expect(find.text('Genesis 1:1'), findsOneWidget);
    expect(find.text('In the beginning God created the heavens and the earth.'), findsOneWidget);
    expect(find.text('Highlights (1)'), findsOneWidget);

    // Tap highlight card
    await tester.tap(find.text('Genesis 1:1'));
    await tester.pumpAndSettle();

    // Verify TabManager was invoked with target verse and page popped back to root
    expect(trackingTabManager.openedBookId, 1);
    expect(trackingTabManager.openedChapter, 1);
    expect(trackingTabManager.openedVerse, 1);
    expect(find.text('Open Page'), findsOneWidget);
    expect(find.byType(HighlightsAndNotesPage), findsNothing);
  });

  testWidgets('Highlights can be deleted with confirmation', (tester) async {
    final h1 = Highlight(
      id: 'h1',
      bookId: 1,
      chapter: 1,
      startWordId: 1001001001,
      endWordId: 1001001005,
      color: HighlightColor.yellow,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await fakeAnnotationDb.insertHighlight(h1);

    await openPage(tester);

    expect(find.text('Genesis 1:1'), findsOneWidget);

    // Tap delete icon button
    await tester.tap(find.byTooltip('Delete highlight'));
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Delete Highlight'), findsOneWidget);

    // Cancel deletion
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Genesis 1:1'), findsOneWidget);

    // Tap delete again and confirm
    await tester.tap(find.byTooltip('Delete highlight'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Verify item is removed and empty state shown
    expect(find.text('No highlights yet'), findsOneWidget);
    expect(find.text('Highlights'), findsOneWidget);
  });

  testWidgets('Notes tab displays empty state when no notes exist', (tester) async {
    await openPage(tester, initialTabIndex: 1);

    expect(find.text('No notes yet'), findsOneWidget);
    expect(find.textContaining('Select a verse and tap the Note option'), findsOneWidget);
  });

  testWidgets('Notes tab displays note, allows editing and deleting', (tester) async {
    final note1 = Note(
      id: 'n1',
      bookId: 43,
      chapter: 3,
      startWordId: 43003016001,
      endWordId: 43003016010,
      content: 'Key verse for God\'s love',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await fakeAnnotationDb.insertNote(note1);

    await openPage(tester, initialTabIndex: 1);

    expect(find.text('John 3:16'), findsOneWidget);
    expect(find.text('Key verse for God\'s love'), findsOneWidget);
    expect(find.text('For God so loved the world that He gave His one and only Son.'), findsOneWidget);
    expect(find.text('Notes (1)'), findsOneWidget);

    // Edit note
    await tester.tap(find.byTooltip('Edit note'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditorSheet), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Updated insight on John 3:16');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify updated text is reflected
    expect(find.text('Updated insight on John 3:16'), findsOneWidget);

    // Delete note
    await tester.tap(find.byTooltip('Delete note'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Note'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No notes yet'), findsOneWidget);
  });

  testWidgets('Notes tab navigates to verse on card tap and pops page', (tester) async {
    final note1 = Note(
      id: 'n1',
      bookId: 43,
      chapter: 3,
      startWordId: 43003016001,
      endWordId: 43003016010,
      content: 'Key verse for God\'s love',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await fakeAnnotationDb.insertNote(note1);

    await openPage(tester, initialTabIndex: 1);

    // Tap card to navigate
    await tester.tap(find.text('Key verse for God\'s love'));
    await tester.pumpAndSettle();

    expect(trackingTabManager.openedBookId, 43);
    expect(trackingTabManager.openedChapter, 3);
    expect(trackingTabManager.openedVerse, 16);
    expect(find.text('Open Page'), findsOneWidget);
    expect(find.byType(HighlightsAndNotesPage), findsNothing);
  });

  testWidgets('Search filters highlights and notes', (tester) async {
    final h1 = Highlight(
      id: 'h1',
      bookId: 1,
      chapter: 1,
      startWordId: 1001001001,
      endWordId: 1001001005,
      color: HighlightColor.yellow,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final note1 = Note(
      id: 'n1',
      bookId: 43,
      chapter: 3,
      startWordId: 43003016001,
      endWordId: 43003016010,
      content: 'Amazing love',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await fakeAnnotationDb.insertHighlight(h1);
    await fakeAnnotationDb.insertNote(note1);

    await openPage(tester);

    expect(find.text('Genesis 1:1'), findsOneWidget);

    // Open search
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    // Enter search term matching nothing
    await tester.enterText(find.byType(TextField), 'nonexistent');
    await tester.pumpAndSettle();

    expect(find.text('Genesis 1:1'), findsNothing);
    expect(find.text('No matching highlights'), findsOneWidget);

    // Enter search term matching snippet 'heavens'
    await tester.enterText(find.byType(TextField), 'heavens');
    await tester.pumpAndSettle();

    expect(find.text('Genesis 1:1'), findsOneWidget);

    // Switch to Notes tab
    await tester.tap(find.text('Notes (1)'));
    await tester.pumpAndSettle();

    // Notes tab with search term 'heavens' has no match
    expect(find.text('No matching notes'), findsOneWidget);

    // Search for 'amazing'
    await tester.enterText(find.byType(TextField), 'amazing');
    await tester.pumpAndSettle();

    expect(find.text('John 3:16'), findsOneWidget);
    expect(find.text('Amazing love'), findsOneWidget);

    // Close search
    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();

    expect(find.text('John 3:16'), findsOneWidget);
  });

  testWidgets('Biblical order is default and selecting another sort order is remembered', (tester) async {
    // h1: Revelation 1:1 (book 66, created today)
    final h1 = Highlight(
      id: 'h1',
      bookId: 66,
      chapter: 1,
      startWordId: 66001001001,
      endWordId: 66001001005,
      color: HighlightColor.blue,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    // h2: Genesis 1:1 (book 1, created 2 days ago)
    final h2 = Highlight(
      id: 'h2',
      bookId: 1,
      chapter: 1,
      startWordId: 1001001001,
      endWordId: 1001001005,
      color: HighlightColor.yellow,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    await fakeAnnotationDb.insertHighlight(h1);
    await fakeAnnotationDb.insertHighlight(h2);

    // 1. Initial open: no saved preference, default should be Biblical order
    expect(userSettings.annotationSortOrder, isNull);
    await openPage(tester);

    // In Biblical order: Genesis 1:1 (book 1) comes before Revelation 1:1 (book 66)
    var firstCard = find.byType(Card).first;
    expect(find.descendant(of: firstCard, matching: find.text('Genesis 1:1')), findsOneWidget);

    // 2. Select 'Newest first' from sort menu
    await tester.tap(find.byTooltip('Sort by'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Newest first'));
    await tester.pumpAndSettle();

    // Now Revelation 1:1 (created today) should be first
    firstCard = find.byType(Card).first;
    expect(find.descendant(of: firstCard, matching: find.text('Revelation 1:1')), findsOneWidget);

    // Verify preference was saved in userSettings
    expect(userSettings.annotationSortOrder, 'newest');

    // 3. Pop page and reopen: verify remembered sort order is 'Newest first'
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Reopen page
    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();

    firstCard = find.byType(Card).first;
    expect(find.descendant(of: firstCard, matching: find.text('Revelation 1:1')), findsOneWidget);

    // 4. Switch back to 'Biblical order' and verify saved
    await tester.tap(find.byTooltip('Sort by'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Biblical order'));
    await tester.pumpAndSettle();

    firstCard = find.byType(Card).first;
    expect(find.descendant(of: firstCard, matching: find.text('Genesis 1:1')), findsOneWidget);
    expect(userSettings.annotationSortOrder, 'biblical');
  });

  testWidgets('Preview displays only the highlighted text for partial-verse highlights', (tester) async {
    // Psalm 32:2 (book 19, ch 32, v 2)
    // Highlight 1: words 0..5
    final h1 = Highlight(
      id: 'h1',
      bookId: 19,
      chapter: 32,
      startWordId: 19032002000,
      endWordId: 19032002005,
      color: HighlightColor.purple,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    // Highlight 2: words 6..19
    final h2 = Highlight(
      id: 'h2',
      bookId: 19,
      chapter: 32,
      startWordId: 19032002006,
      endWordId: 19032002019,
      color: HighlightColor.yellow,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await fakeAnnotationDb.insertHighlight(h1);
    await fakeAnnotationDb.insertHighlight(h2);

    fakeDbHelper.rangeTexts['19032002000_19032002005'] = 'Blessed is the man whose iniquity';
    fakeDbHelper.rangeTexts['19032002006_19032002019'] =
        'the LORD does not count against him, in whose spirit there is no deceit.';
    fakeDbHelper.verseTexts[19032002] =
        'Blessed is the man whose iniquity the LORD does not count against him, in whose spirit there is no deceit.';

    await openPage(tester);

    // Both cards have title 'Psalm 32:2'
    expect(find.text('Psalm 32:2'), findsNWidgets(2));

    // But each card displays only its specific highlighted words
    expect(find.text('Blessed is the man whose iniquity'), findsOneWidget);
    expect(
      find.text('the LORD does not count against him, in whose spirit there is no deceit.'),
      findsOneWidget,
    );
  });

  testWidgets('Stored text on Highlight and passageText on Note render directly', (tester) async {
    final h1 = Highlight(
      id: 'h_stored',
      bookId: 19,
      chapter: 32,
      startWordId: 19032002000,
      endWordId: 19032002005,
      color: HighlightColor.pink,
      text: 'Blessed is the man',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final n1 = Note(
      id: 'n_stored',
      bookId: 43,
      chapter: 3,
      startWordId: 43003016001,
      endWordId: 43003016010,
      content: 'Personal reflection',
      passageText: 'For God so loved the world',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await fakeAnnotationDb.insertHighlight(h1);
    await fakeAnnotationDb.insertNote(n1);

    await openPage(tester);

    // Highlight shows stored text directly
    expect(find.text('Blessed is the man'), findsOneWidget);

    // Switch to Notes tab
    await tester.tap(find.text('Notes (1)'));
    await tester.pumpAndSettle();

    // Note shows user content and stored passageText directly
    expect(find.text('Personal reflection'), findsOneWidget);
    expect(find.text('For God so loved the world'), findsOneWidget);
  });

  testWidgets('Overflow menu displays Export and Import options', (tester) async {
    await openPage(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Export backup (JSON)'), findsOneWidget);
    expect(find.text('Export as Markdown (.md)'), findsOneWidget);
    expect(find.text('Import backup (JSON)'), findsOneWidget);
  });
}
