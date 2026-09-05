import 'package:bsb/infrastructure/section_heading.dart';
import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.light(useMaterial3: true),
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('ChapterChooser Widget Tests', () {
    testWidgets('displays book name from bookId or bookName', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const ChapterChooser(
            bookId: 1,
            chapterCount: 50,
          ),
        ),
      );

      expect(find.text('Genesis'), findsOneWidget);
      expect(find.text('Chapter (1–50)'), findsOneWidget);

      await tester.pumpWidget(
        createTestApp(
          const ChapterChooser(
            bookName: 'Exodus',
            chapterCount: 40,
          ),
        ),
      );

      expect(find.text('Exodus'), findsOneWidget);
      expect(find.text('Chapter (1–40)'), findsOneWidget);
    });

    testWidgets('initial key states for 4-chapter book (e.g. Ruth)',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const ChapterChooser(
            bookName: 'Ruth',
            chapterCount: 4,
          ),
        ),
      );

      // Keys 1..4 should be enabled
      for (var d = 1; d <= 4; d++) {
        final button = tester.widget<FilledButton>(
          find.byKey(ValueKey('keypad_$d')),
        );
        expect(button.onPressed, isNotNull, reason: 'Key $d should be enabled');
      }

      // Keys 5..9 and 0 should be disabled
      for (var d = 5; d <= 9; d++) {
        final button = tester.widget<FilledButton>(
          find.byKey(ValueKey('keypad_$d')),
        );
        expect(button.onPressed, isNull, reason: 'Key $d should be disabled');
      }
      final zeroButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('keypad_0')),
      );
      expect(zeroButton.onPressed, isNull, reason: 'Key 0 should be disabled');

      // Delete and Go should be disabled
      final deleteButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('keypad_delete')),
      );
      expect(deleteButton.onPressed, isNull);

      final goButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('keypad_go')),
      );
      expect(goButton.onPressed, isNull);
    });

    testWidgets('auto-navigates when digit fully disambiguates', (tester) async {
      int? selectedChapter;
      await tester.pumpWidget(
        createTestApp(
          ChapterChooser(
            bookName: 'Genesis',
            chapterCount: 50,
            onChapterSelected: (c) => selectedChapter = c,
          ),
        ),
      );

      // Tapping 6 in Genesis immediately navigates to 6 because 60 > 50
      await tester.tap(find.byKey(const ValueKey('keypad_6')));
      await tester.pumpAndSettle();

      expect(selectedChapter, equals(6));
    });

    testWidgets(
        'typing prefix disables invalid keys and allows multi-digit disambiguation',
        (tester) async {
      int? selectedChapter;
      await tester.pumpWidget(
        createTestApp(
          ChapterChooser(
            bookName: 'Genesis',
            chapterCount: 50,
            onChapterSelected: (c) => selectedChapter = c,
          ),
        ),
      );

      // Tap 5 (Genesis has 50 chapters: 5 and 50 both start with 5)
      await tester.tap(find.byKey(const ValueKey('keypad_5')));
      await tester.pumpAndSettle();

      // Has not navigated yet
      expect(selectedChapter, isNull);
      expect(find.text('Chapter 5'), findsOneWidget);

      // Key 0 should be enabled (for chapter 50)
      final zeroButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('keypad_0')),
      );
      expect(zeroButton.onPressed, isNotNull);

      // Keys 1..9 should be disabled (51..59 are invalid)
      for (var d = 1; d <= 9; d++) {
        final button = tester.widget<FilledButton>(
          find.byKey(ValueKey('keypad_$d')),
        );
        expect(button.onPressed, isNull,
            reason: 'Key $d should be disabled after typing 5 in Genesis');
      }

      // Go and Delete should now be enabled
      final goButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('keypad_go')),
      );
      expect(goButton.onPressed, isNotNull);

      final deleteButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('keypad_delete')),
      );
      expect(deleteButton.onPressed, isNotNull);

      // Tap 0 -> immediately disambiguates to chapter 50
      await tester.tap(find.byKey(const ValueKey('keypad_0')));
      await tester.pumpAndSettle();

      expect(selectedChapter, equals(50));
    });

    testWidgets('Go button navigates to chapter before it is fully disambiguated',
        (tester) async {
      int? selectedChapter;
      await tester.pumpWidget(
        createTestApp(
          ChapterChooser(
            bookName: 'Genesis',
            chapterCount: 50,
            onChapterSelected: (c) => selectedChapter = c,
          ),
        ),
      );

      // Tap 1 -> ambiguous (could be 1, 10-19)
      await tester.tap(find.byKey(const ValueKey('keypad_1')));
      await tester.pumpAndSettle();

      expect(selectedChapter, isNull);
      expect(find.text('Chapter 1'), findsOneWidget);

      // Tap Go button
      await tester.tap(find.byKey(const ValueKey('keypad_go')));
      await tester.pumpAndSettle();

      expect(selectedChapter, equals(1));
    });

    testWidgets('Delete button deletes typed digits', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const ChapterChooser(
            bookName: 'Genesis',
            chapterCount: 50,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('keypad_5')));
      await tester.pumpAndSettle();
      expect(find.text('Chapter 5'), findsOneWidget);

      // Tap Delete
      await tester.tap(find.byKey(const ValueKey('keypad_delete')));
      await tester.pumpAndSettle();

      expect(find.text('Chapter (1–50)'), findsOneWidget);

      // Keys 1-9 should be re-enabled
      for (var d = 1; d <= 9; d++) {
        final button = tester.widget<FilledButton>(
          find.byKey(ValueKey('keypad_$d')),
        );
        expect(button.onPressed, isNotNull);
      }
    });

    testWidgets('3-digit book (Psalms 150 chapters)', (tester) async {
      int? selectedChapter;
      await tester.pumpWidget(
        createTestApp(
          ChapterChooser(
            bookId: 19,
            chapterCount: 150,
            onChapterSelected: (c) => selectedChapter = c,
          ),
        ),
      );

      expect(find.text('Psalm'), findsOneWidget);

      // Tap 1 -> ambiguous (1, 10-19, 100-150)
      await tester.tap(find.byKey(const ValueKey('keypad_1')));
      await tester.pumpAndSettle();
      expect(selectedChapter, isNull);

      // Tap 6 -> "16" has only one match (16, since 160 > 150)
      await tester.tap(find.byKey(const ValueKey('keypad_6')));
      await tester.pumpAndSettle();

      expect(selectedChapter, equals(16));
    });

    testWidgets('Psalms reaching chapter 150 via 1 -> 5 -> 0', (tester) async {
      int? selectedChapter;
      await tester.pumpWidget(
        createTestApp(
          ChapterChooser(
            bookId: 19,
            chapterCount: 150,
            onChapterSelected: (c) => selectedChapter = c,
          ),
        ),
      );

      // Tap 1
      await tester.tap(find.byKey(const ValueKey('keypad_1')));
      await tester.pumpAndSettle();

      // Tap 5 -> "15" (ambiguous: 15 or 150)
      await tester.tap(find.byKey(const ValueKey('keypad_5')));
      await tester.pumpAndSettle();
      expect(selectedChapter, isNull);

      // Only 0 should be enabled (150 <= 150, 151 > 150)
      final zeroBtn = tester.widget<FilledButton>(
        find.byKey(const ValueKey('keypad_0')),
      );
      expect(zeroBtn.onPressed, isNotNull);

      for (var d = 1; d <= 9; d++) {
        final btn = tester.widget<FilledButton>(
          find.byKey(ValueKey('keypad_$d')),
        );
        expect(btn.onPressed, isNull);
      }

      // Tap 0 -> disambiguates to 150
      await tester.tap(find.byKey(const ValueKey('keypad_0')));
      await tester.pumpAndSettle();

      expect(selectedChapter, equals(150));
    });

    testWidgets('tapping background barrier dismisses with null',
        (tester) async {
      int? selectedChapter = 999;
      await tester.pumpWidget(
        createTestApp(
          ChapterChooser(
            bookId: 1,
            chapterCount: 50,
            onChapterSelected: (c) => selectedChapter = c,
          ),
        ),
      );

      // Tap on outer barrier (e.g. top-left corner)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(selectedChapter, isNull);
    });

    testWidgets('keyboard key events work', (tester) async {
      int? selectedChapter;
      await tester.pumpWidget(
        createTestApp(
          ChapterChooser(
            bookId: 1,
            chapterCount: 50,
            onChapterSelected: (c) => selectedChapter = c,
          ),
        ),
      );

      // Press key '8' -> disambiguates to 8 in Genesis
      await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
      await tester.pumpAndSettle();

      expect(selectedChapter, equals(8));
    });

    testWidgets(
        'Section Headings button opens dialog and selecting heading triggers onSectionSelected',
        (tester) async {
      int? selectedChapter;
      String? selectedHeading;

      final testHeadings = [
        const SectionHeading(
          bookId: 1,
          chapter: 1,
          verse: 1,
          text: 'The Creation',
          format: 's1',
        ),
        const SectionHeading(
          bookId: 1,
          chapter: 3,
          verse: 1,
          text: "The Serpent's Deception",
          format: 's1',
        ),
      ];

      await tester.pumpWidget(
        createTestApp(
          ChapterChooser(
            bookId: 1,
            chapterCount: 50,
            headingsLoader: (bookId) async => testHeadings,
            onChapterSelected: (c) => selectedChapter = c,
            onSectionSelected: (c, h) {
              selectedChapter = c;
              selectedHeading = h;
            },
          ),
        ),
      );

      expect(find.byKey(const ValueKey('keypad_sections')), findsOneWidget);
      final iconCenter =
          tester.getCenter(find.byKey(const ValueKey('keypad_sections')));
      final bookCenter = tester.getCenter(find.text('Genesis'));
      expect(iconCenter.dx, lessThan(bookCenter.dx));
      expect((iconCenter.dy - bookCenter.dy).abs(), lessThan(15));

      // Tap Section Headings button
      await tester.tap(find.byKey(const ValueKey('keypad_sections')));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Genesis Sections'), findsOneWidget);
      expect(find.text('The Creation'), findsOneWidget);
      expect(find.text('1:1'), findsOneWidget);
      expect(find.text("The Serpent's Deception"), findsOneWidget);
      expect(find.text('3:1'), findsOneWidget);

      // Tap the second section heading
      await tester.tap(find.text("The Serpent's Deception"));
      await tester.pumpAndSettle();

      expect(selectedChapter, equals(3));
      expect(selectedHeading, equals("The Serpent's Deception"));
    });

    testWidgets('Section Headings dialog handles empty state and dismissal',
        (tester) async {
      int? selectedChapter;
      String? selectedHeading;

      await tester.pumpWidget(
        createTestApp(
          ChapterChooser(
            bookId: 1,
            chapterCount: 50,
            headingsLoader: (bookId) async => [],
            onChapterSelected: (c) => selectedChapter = c,
            onSectionSelected: (c, h) {
              selectedChapter = c;
              selectedHeading = h;
            },
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.byKey(const ValueKey('keypad_sections')));
      await tester.pumpAndSettle();

      expect(find.text('No section headings found'), findsOneWidget);

      // Dismiss dialog by tapping barrier (e.g. top-left corner)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // No section or chapter selected
      expect(selectedChapter, isNull);
      expect(selectedHeading, isNull);

      // Chapter chooser keypad is still active
      expect(find.byKey(const ValueKey('keypad_sections')), findsOneWidget);
    });
  });
}
