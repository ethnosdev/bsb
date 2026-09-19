import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/home/book_chooser.dart';
import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:bsb/ui/home/list_book_chooser.dart';
import 'package:bsb/ui/playlists/widgets/passage_range_picker_dialog.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeDatabaseHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getRange(Reference reference) async => [
        UsfmLine(
          bookChapterVerse: reference.packedVerse,
          text: 'Passage snippet for $reference',
          format: ParagraphFormat.p,
        ),
      ];
}

void main() {
  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<DatabaseHelper>(FakeDatabaseHelper());
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('PassageRangePickerDialog starts empty with Book and Ch:Vs buttons without close X', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PassageRangePickerDialog.show(context),
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Select Scripture Passage'), findsOneWidget);
    // Header does NOT have close X button
    expect(find.byIcon(Icons.close), findsNothing);

    expect(find.byKey(const ValueKey('passage_book_button')), findsOneWidget);
    expect(find.text('Book'), findsOneWidget);

    expect(find.byKey(const ValueKey('passage_start_chapter_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('passage_start_verse_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('passage_end_chapter_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('passage_end_verse_button')), findsOneWidget);
    expect(find.text(':'), findsNWidgets(2)); // two colons

    // Start chapter, verse and end buttons are disabled initially
    final startChBtn = tester.widget<OutlinedButton>(find.byKey(const ValueKey('passage_start_chapter_button')));
    expect(startChBtn.onPressed, isNull);

    final startVsBtn = tester.widget<OutlinedButton>(find.byKey(const ValueKey('passage_start_verse_button')));
    expect(startVsBtn.onPressed, isNull);

    final addBtn = tester.widget<FilledButton>(find.byKey(const ValueKey('add_to_playlist_button')));
    expect(addBtn.onPressed, isNull);
  });

  testWidgets('Selecting a book defaults start and end to 1:1', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PassageRangePickerDialog.show(context),
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // 1. Tap Book button
    await tester.tap(find.byKey(const ValueKey('passage_book_button')));
    await tester.pumpAndSettle();

    // Tap John
    await tester.tap(find.text('John'));
    await tester.pumpAndSettle();

    // As soon as book is selected, start chapter/verse and end chapter/verse default to 1:1
    expect(find.text('John'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(4));
    expect(find.text('John 1:1'), findsWidgets);

    // Add to Playlist is immediately enabled for John 1:1
    final addBtn = tester.widget<FilledButton>(find.byKey(const ValueKey('add_to_playlist_button')));
    expect(addBtn.onPressed, isNotNull);
  });

  testWidgets('Start > End pushes End forward, and End < Start pulls Start backward', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PassageRangePickerDialog.show(
                context,
                initialReference: Reference(bookId: 43, chapter: 3, verse: 16),
              ),
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Starts at John 3:16 – 3:16
    expect(find.text('John'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(2));
    expect(find.text('16'), findsNWidgets(2));

    // 1. Change End verse to 18 -> Range becomes John 3:16–18
    await tester.tap(find.byKey(const ValueKey('passage_end_verse_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('keypad_1')));
    await tester.tap(find.byKey(const ValueKey('keypad_8')));
    await tester.pumpAndSettle();

    expect(find.text('John 3:16–18'), findsWidgets);

    // 2. Change Start verse to 10 (which is <= end verse 18) -> End verse should stay 18
    await tester.tap(find.byKey(const ValueKey('passage_start_verse_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('keypad_1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('keypad_0')));
    await tester.pumpAndSettle();

    expect(find.text('10'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('John 3:10–18'), findsWidgets);

    // 3. Change Start verse to 20 (which is > end verse 18) -> End range should match start (becomes 20)
    await tester.tap(find.byKey(const ValueKey('passage_start_verse_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('keypad_2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('keypad_0')));
    await tester.pumpAndSettle();

    expect(find.text('20'), findsNWidgets(2));
    expect(find.text('John 3:20'), findsWidgets); // same start & end => single verse!

    // 4. Change End verse to 5 (which is < current start 20) -> Start range should match end (becomes 5)
    await tester.tap(find.byKey(const ValueKey('passage_end_verse_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('keypad_5')));
    await tester.pumpAndSettle();

    expect(find.text('5'), findsNWidgets(2));
    expect(find.text('John 3:5'), findsWidgets);
  });

  testWidgets('Clearing end range is done simply by setting end verse to match start verse', (tester) async {
    Reference? selectedRef;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await PassageRangePickerDialog.show(
                  context,
                  initialReference: Reference(
                    bookId: 43,
                    chapter: 3,
                    verse: 16,
                    endVerse: 18,
                  ),
                );
                selectedRef = result?.reference;
              },
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    expect(find.text('John 3:16–18'), findsWidgets);

    // Set end verse back to 16
    await tester.tap(find.byKey(const ValueKey('passage_end_verse_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('keypad_1')));
    await tester.tap(find.byKey(const ValueKey('keypad_6')));
    await tester.pumpAndSettle();

    // Now start is 16 and end is 16 -> John 3:16 (single verse!)
    expect(find.text('John 3:16'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('add_to_playlist_button')));
    await tester.pumpAndSettle();

    expect(selectedRef, isNotNull);
    expect(selectedRef!.toString(), 'John 3:16');
    expect(selectedRef!.endVerse, isNull);
    expect(selectedRef!.endChapter, isNull);
  });

  testWidgets('Cross-chapter verse range selection works with End Chapter and End Verse', (tester) async {
    Reference? selectedRef;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await PassageRangePickerDialog.show(
                  context,
                  initialReference: Reference(bookId: 42, chapter: 23, verse: 50),
                );
                selectedRef = result?.reference;
              },
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Luke'), findsOneWidget);
    expect(find.text('23'), findsNWidgets(2));
    expect(find.text('50'), findsNWidgets(2));

    // Tap End Chapter button -> Pick 24
    await tester.tap(find.byKey(const ValueKey('passage_end_chapter_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('keypad_2')));
    await tester.tap(find.byKey(const ValueKey('keypad_4')));
    await tester.pumpAndSettle();

    expect(find.text('24'), findsOneWidget);

    // Tap End Verse button -> Pick 12
    await tester.tap(find.byKey(const ValueKey('passage_end_verse_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('keypad_1')));
    await tester.tap(find.byKey(const ValueKey('keypad_2')));
    await tester.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
    expect(find.text('Luke 23:50–24:12'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('add_to_playlist_button')));
    await tester.pumpAndSettle();

    expect(selectedRef, isNotNull);
    expect(selectedRef!.toString(), 'Luke 23:50–24:12');
  });

  testWidgets('PassageRangePickerDialog uses ListBookChooser when user prefers list', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final userSettings = UserSettings();
    await userSettings.init();
    await userSettings.setBookChooserStyle(BookChooserStyle.list);
    getIt.registerSingleton<UserSettings>(userSettings);
    final appState = AppState();
    await appState.init();
    getIt.registerSingleton<AppState>(appState);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PassageRangePickerDialog.show(context),
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Tap Book button
    await tester.tap(find.byKey(const ValueKey('passage_book_button')));
    await tester.pumpAndSettle();

    expect(find.byType(ListBookChooser), findsOneWidget);
    expect(find.byType(BookChooser), findsNothing);
  });

  testWidgets('PassageRangePickerDialog uses GridChapterChooser and GridVerseChooser when preferred', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final userSettings = UserSettings();
    await userSettings.init();
    await userSettings.setChapterChooserStyle(ChapterChooserStyle.grid);
    await userSettings.setVerseChooserStyle(VerseChooserStyle.grid);
    getIt.registerSingleton<UserSettings>(userSettings);
    final appState = AppState();
    await appState.init();
    getIt.registerSingleton<AppState>(appState);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PassageRangePickerDialog.show(
                context,
                initialReference: Reference(bookId: 43, chapter: 3, verse: 16),
              ),
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Tap Start Chapter -> Should open GridChapterChooser
    await tester.tap(find.byKey(const ValueKey('passage_start_chapter_button')));
    await tester.pumpAndSettle();

    expect(find.byType(GridChapterChooser), findsOneWidget);
    expect(find.byType(NumericKeypadChooser), findsNothing);

    final gridFinder = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_ChapterGridWidget',
    );
    expect(gridFinder, findsOneWidget);
    final topLeft = tester.getTopLeft(gridFinder);
    await tester.tapAt(topLeft + const Offset(10, 10)); // selects chapter 1
    await tester.pumpAndSettle();

    // Tap Start Verse -> Should open GridVerseChooser
    await tester.tap(find.byKey(const ValueKey('passage_start_verse_button')));
    await tester.pumpAndSettle();

    expect(find.byType(GridVerseChooser), findsOneWidget);
    expect(find.byType(KeypadVerseChooser), findsNothing);
  });

  testWidgets('PassageRangePickerDialog delete button has normal icon color and invokes onDelete', (tester) async {
    bool deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PassageRangePickerDialog.show(
                context,
                initialReference: Reference(bookId: 43, chapter: 3, verse: 16),
                onDelete: () {
                  deleted = true;
                },
              ),
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    final deleteIcon = tester.widget<Icon>(find.byIcon(Icons.delete_outline));
    // Normal icon color: color property is null so it takes Theme icon color (not forced red)
    expect(deleteIcon.color, isNull);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete Passage'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });

  group('cleanPassagePreview', () {
    test('strips footnotes and words of jesus markers from USFM lines', () {
      final lines = [
        UsfmLine(
          bookChapterVerse: 43001039,
          text:
              r'\wj  “Come and see,”\wj* He replied. So they went and saw where He was staying, and spent that day with Him. It was about the tenth hour.\f + \fr 1:39 \ft That is, about four in the afternoon\f*',
          format: ParagraphFormat.p,
        ),
      ];

      final clean = cleanPassagePreview(lines);
      expect(
        clean,
        equals(
          '“Come and see,” He replied. So they went and saw where He was staying, and spent that day with Him. It was about the tenth hour.',
        ),
      );
    });

    test('excludes section headings and blank breaks', () {
      final lines = [
        UsfmLine(
          bookChapterVerse: 43001042,
          text:
              r'Andrew brought him to Jesus, who looked at him and said, \wj “You are Simon son of John. You will be called Cephas”\wj* (which is translated as Peter).',
          format: ParagraphFormat.p,
        ),
        UsfmLine(
          bookChapterVerse: 43001042,
          text: 'Jesus Calls Philip and Nathanael',
          format: ParagraphFormat.s1,
        ),
      ];

      final clean = cleanPassagePreview(lines);
      expect(
        clean,
        equals(
          'Andrew brought him to Jesus, who looked at him and said, “You are Simon son of John. You will be called Cephas” (which is translated as Peter).',
        ),
      );
    });
  });

  testWidgets('Preview box in PassageRangePickerDialog strips footnotes and words of jesus markers', (tester) async {
    final customDb = _TestUsfmDatabaseHelper();
    await getIt.reset();
    getIt.registerSingleton<DatabaseHelper>(customDb);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PassageRangePickerDialog.show(
                context,
                initialReference: Reference(bookId: 43, chapter: 1, verse: 39),
              ),
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Verify preview text does not contain \wj, \wj*, or footnote contents
    expect(find.byKey(const ValueKey('preview_text')), findsOneWidget);
    final previewTextWidget = tester.widget<Text>(find.byKey(const ValueKey('preview_text')));
    final previewString = previewTextWidget.data!;

    expect(previewString, isNot(contains(r'\wj')));
    expect(previewString, isNot(contains(r'\f')));
    expect(previewString, isNot(contains('about four in the afternoon')));
    expect(
      previewString,
      '“Come and see,” He replied. So they went and saw where He was staying, and spent that day with Him. It was about the tenth hour.',
    );
  });
}

class _TestUsfmDatabaseHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getRange(Reference reference) async => [
        UsfmLine(
          bookChapterVerse: reference.packedVerse,
          text:
              r'\wj  “Come and see,”\wj* He replied. So they went and saw where He was staying, and spent that day with Him. It was about the tenth hour.\f + \fr 1:39 \ft That is, about four in the afternoon\f*',
          format: ParagraphFormat.p,
        ),
      ];
}
