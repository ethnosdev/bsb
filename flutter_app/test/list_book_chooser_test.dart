import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:bsb/ui/home/list_book_chooser.dart';
import 'package:flutter/material.dart';
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
  group('ListBookChooser Widget Tests', () {
    testWidgets('renders books from both testaments without section labels', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          ListBookChooser(onSelected: (_, _, [_]) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Labels should not be present
      expect(find.text('Old Testament'), findsNothing);
      expect(find.text('New Testament'), findsNothing);

      // Verify books from both testaments appear
      expect(find.text('Genesis'), findsOneWidget);
      expect(find.text('Matthew'), findsOneWidget);
    });

    testWidgets('Old Testament and New Testament lists scroll independently', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          ListBookChooser(onSelected: (_, _, [_]) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Initially top books are visible
      expect(find.text('Genesis'), findsOneWidget);
      expect(find.text('Matthew'), findsOneWidget);

      // Books near bottom of OT (e.g. Malachi) and NT (e.g. Revelation) are not yet in view
      expect(find.text('Malachi'), findsNothing);
      expect(find.text('Revelation'), findsNothing);

      // Scroll the Old Testament list (on the left)
      final otListFinder = find.byKey(const PageStorageKey('list_book_chooser_old_testament'));
      await tester.drag(otListFinder, const Offset(0, -600));
      await tester.pumpAndSettle();

      // OT list has moved down; NT list on the right was not affected and still shows Matthew
      expect(find.text('Matthew'), findsOneWidget);
      expect(find.text('Revelation'), findsNothing);

      // Now scroll the New Testament list (on the right)
      final ntListFinder = find.byKey(const PageStorageKey('list_book_chooser_new_testament'));
      await tester.drag(ntListFinder, const Offset(0, -600));
      await tester.pumpAndSettle();

      // Revelation should now be visible or scrolled into view
      final ntScrollable = find.descendant(of: ntListFinder, matching: find.byType(Scrollable));
      await tester.scrollUntilVisible(find.text('Revelation'), 200, scrollable: ntScrollable);
      expect(find.text('Revelation'), findsOneWidget);
    });

    testWidgets('tapping a single-chapter book directly selects chapter 1', (tester) async {
      int? selectedBookId;
      int? selectedChapter;

      await tester.pumpWidget(
        createTestApp(
          ListBookChooser(
            onSelected: (bookId, chapter, [section]) {
              selectedBookId = bookId;
              selectedChapter = chapter;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Obadiah (book 31) in Old Testament
      final otListFinder = find.byKey(const PageStorageKey('list_book_chooser_old_testament'));
      final otScrollable = find.descendant(of: otListFinder, matching: find.byType(Scrollable));
      await tester.scrollUntilVisible(find.text('Obadiah'), 200, scrollable: otScrollable);
      await tester.tap(find.text('Obadiah'));
      await tester.pumpAndSettle();

      expect(selectedBookId, equals(31));
      expect(selectedChapter, equals(1));
      expect(find.byType(ChapterChooser), findsNothing);
    });

    testWidgets('tapping a multi-chapter book opens ChapterChooser and selecting chapter navigates', (tester) async {
      int? selectedBookId;
      int? selectedChapter;

      await tester.pumpWidget(
        createTestApp(
          ListBookChooser(
            onSelected: (bookId, chapter, [section]) {
              selectedBookId = bookId;
              selectedChapter = chapter;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Genesis (multi-chapter book)
      await tester.tap(find.text('Genesis'));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterChooser), findsOneWidget);

      // Tap 6 -> Genesis has 50 chapters, so 6 is unambiguous and auto-navigates
      await tester.tap(find.byKey(const ValueKey('keypad_6')));
      await tester.pumpAndSettle();

      expect(selectedBookId, equals(1));
      expect(selectedChapter, equals(6));
      expect(find.byType(ChapterChooser), findsNothing);
    });

    testWidgets('tapping outside/barrier dismisses ChapterChooser', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          ListBookChooser(onSelected: (_, _, [_]) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Genesis to open ChapterChooser
      await tester.tap(find.text('Genesis'));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterChooser), findsOneWidget);

      // Tap the modal barrier outside the chooser dialog (e.g. top-left corner)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterChooser), findsNothing);
      expect(find.text('Genesis'), findsOneWidget);
    });
  });
}
