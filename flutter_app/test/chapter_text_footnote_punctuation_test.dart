import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/text/chapter/chapter_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeFootnoteDbHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    return [
      UsfmLine(
        bookChapterVerse: 41012011,
        text:
            r'and it is marvelous in our eyes’\f + \fr 12:11 \ft Psalm 118:22–23\f*?”',
        format: ParagraphFormat.q2,
      ),
    ];
  }

  @override
  Future<List<UsfmLine>> getVerses(int bookId, int chapter, int startVerse, int endVerse) async {
    return [
      UsfmLine(
        bookChapterVerse: 41012011,
        text:
            r'and it is marvelous in our eyes’\f + \fr 12:11 \ft Psalm 118:22–23\f*?”',
        format: ParagraphFormat.q2,
      ),
    ];
  }
}

class FakeAnnotationDbHelper implements AnnotationDatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Highlight>> getHighlightsForChapter(int bookId, int chapter) async => [];

  @override
  Future<List<Note>> getNotesForChapter(int bookId, int chapter) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserSettings userSettings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    getIt.reset();

    userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);

    getIt.registerSingleton<DatabaseHelper>(FakeFootnoteDbHelper());
    final annotationDb = FakeAnnotationDbHelper();
    getIt.registerSingleton<AnnotationDatabaseHelper>(annotationDb);
    getIt.registerSingleton<AnnotationService>(
      AnnotationService(dbHelper: annotationDb),
    );
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('ChapterText renders footnote marker immediately followed by punctuation with no space', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChapterText(
            bookId: 41,
            chapter: 12,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify FootnoteWidget exists
    expect(find.byType(FootnoteWidget), findsOneWidget);

    // Verify TextAtomWidget contains eyes’, *, and ?” together
    final atomFinder = find.ancestor(
      of: find.byType(FootnoteWidget),
      matching: find.byType(TextAtomWidget),
    );
    expect(atomFinder, findsOneWidget);

    final atom = tester.widget<TextAtomWidget>(atomFinder);
    expect(atom.children.length, equals(3));
    expect((atom.children[0] as WordWidget).text, equals('eyes’'));
    expect((atom.children[1] as FootnoteWidget).marker, equals('*'));
    expect((atom.children[2] as WordWidget).text, equals('?”'));
  });

  test('DatabaseHelper.getTextForRange does not insert space before trailing punctuation', () async {
    final db = TestDatabaseHelper([
      UsfmLine(
        bookChapterVerse: 41012011,
        text:
            r'and it is marvelous in our eyes’\f + \fr 12:11 \ft Psalm 118:22–23\f*?”',
        format: ParagraphFormat.q2,
      ),
    ]);

    final text = await db.getTextForRange(
      bookId: 41,
      chapter: 12,
      startWordId: 41012011000,
      endWordId: 41012011999,
    );

    expect(text, equals('and it is marvelous in our eyes’?”'));
  });
}

class TestDatabaseHelper extends DatabaseHelper {
  final List<UsfmLine> lines;
  TestDatabaseHelper(this.lines);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async => lines;
}
