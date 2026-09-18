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

class FakeChapterHeaderDbHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    return [
      UsfmLine(
        bookChapterVerse: bookId * 1000000 + chapter * 1000 + 1,
        text: 'Test verse content.',
        format: ParagraphFormat.p,
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

    getIt.registerSingleton<DatabaseHelper>(FakeChapterHeaderDbHelper());

    final annotationDb = FakeAnnotationDbHelper();
    getIt.registerSingleton<AnnotationDatabaseHelper>(annotationDb);
    getIt.registerSingleton<AnnotationService>(
      AnnotationService(dbHelper: annotationDb),
    );
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('displays book name and chapter number at the top of chapter text (e.g. Genesis 1)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChapterText(
            bookId: 1,
            chapter: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final headerFinder = find.byKey(const ValueKey('chapter_header_1_1'));
    expect(headerFinder, findsOneWidget);

    final textWidget = tester.widget<Text>(headerFinder);
    expect(textWidget.data, equals('Genesis 1'));
    expect(textWidget.textAlign, equals(TextAlign.center));
    expect(textWidget.style?.fontWeight, equals(FontWeight.bold));

    // Verify it is positioned above UsfmWidget
    final headerRect = tester.getRect(headerFinder);
    final usfmRect = tester.getRect(find.byType(UsfmWidget));
    expect(headerRect.bottom, lessThan(usfmRect.top));
  });

  testWidgets('displays Psalm (not Psalms) for book 19 (e.g. Psalm 119)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChapterText(
            bookId: 19,
            chapter: 119,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final headerFinder = find.byKey(const ValueKey('chapter_header_19_119'));
    expect(headerFinder, findsOneWidget);

    final textWidget = tester.widget<Text>(headerFinder);
    expect(textWidget.data, equals('Psalm 119'));
    expect(find.text('Psalms 119'), findsNothing);
  });

  testWidgets('displays single-chapter books with chapter number 1 (e.g. Obadiah 1, Jude 1)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChapterText(
            bookId: 31, // Obadiah
            chapter: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final obadiahHeader = find.byKey(const ValueKey('chapter_header_31_1'));
    expect(obadiahHeader, findsOneWidget);
    expect(tester.widget<Text>(obadiahHeader).data, equals('Obadiah 1'));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChapterText(
            bookId: 65, // Jude
            chapter: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final judeHeader = find.byKey(const ValueKey('chapter_header_65_1'));
    expect(judeHeader, findsOneWidget);
    expect(tester.widget<Text>(judeHeader).data, equals('Jude 1'));
  });
}
