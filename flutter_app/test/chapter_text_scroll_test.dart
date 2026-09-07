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

class FakeChapterScrollDbHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    return [
      UsfmLine(
        bookChapterVerse: 1001001,
        text: 'In the beginning God created the heavens and the earth.',
        format: ParagraphFormat.p,
      ),
      UsfmLine(
        bookChapterVerse: 1001002,
        text: 'Now the earth was formless and void, and darkness was over the surface of the deep.',
        format: ParagraphFormat.p,
      ),
      UsfmLine(
        bookChapterVerse: 1001003,
        text: 'And God said, “Let there be light,” and there was light.',
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

    getIt.registerSingleton<DatabaseHelper>(FakeChapterScrollDbHelper());

    final annotationDb = FakeAnnotationDbHelper();
    getIt.registerSingleton<AnnotationDatabaseHelper>(annotationDb);
    getIt.registerSingleton<AnnotationService>(
      AnnotationService(dbHelper: annotationDb),
    );
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('ChapterText renders and mounts with targetVerse without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChapterText(
            bookId: 1,
            chapter: 1,
            targetVerse: 3,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChapterText), findsOneWidget);
    expect(find.byType(UsfmWidget), findsOneWidget);
    expect(find.byType(SelectableScripture), findsOneWidget);
  });
}
