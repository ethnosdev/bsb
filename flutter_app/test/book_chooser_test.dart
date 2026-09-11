import 'package:bsb/ui/home/book_chooser.dart';
import 'package:bsb/ui/home/chapter_chooser.dart';
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
  group('BookChooser Responsive Book Names Tests', () {
    testWidgets('shows abbreviated book names on narrow screens (< 800)', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          BookChooser(onSelected: (_, _, [_]) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Should find abbreviated names
      expect(find.text('Gen'), findsOneWidget);
      expect(find.text('Exo'), findsOneWidget);
      expect(find.text('Deut'), findsOneWidget);
      expect(find.text('1Sam'), findsOneWidget);
      expect(find.text('1Co'), findsOneWidget);
      expect(find.text('1Th'), findsOneWidget);
      expect(find.text('Rev'), findsOneWidget);

      // Should NOT find full names
      expect(find.text('Genesis'), findsNothing);
      expect(find.text('Exodus'), findsNothing);
      expect(find.text('Deuteronomy'), findsNothing);
      expect(find.text('1 Samuel'), findsNothing);
      expect(find.text('1 Corinthians'), findsNothing);
      expect(find.text('1 Thessalonians'), findsNothing);
      expect(find.text('Revelation'), findsNothing);
    });

    testWidgets('shows full book names on wide screens (>= 800)', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          BookChooser(onSelected: (_, _, [_]) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Should find full names
      expect(find.text('Genesis'), findsOneWidget);
      expect(find.text('Exodus'), findsOneWidget);
      expect(find.text('Deuteronomy'), findsOneWidget);
      expect(find.text('1 Samuel'), findsOneWidget);
      expect(find.text('1 Corinthians'), findsOneWidget);
      expect(find.text('1 Thessalonians'), findsOneWidget);
      expect(find.text('Revelation'), findsOneWidget);

      // Should NOT find abbreviated names
      expect(find.text('Gen'), findsNothing);
      expect(find.text('Exo'), findsNothing);
      expect(find.text('Deut'), findsNothing);
      expect(find.text('1Sam'), findsNothing);
      expect(find.text('1Co'), findsNothing);
      expect(find.text('1Th'), findsNothing);
      expect(find.text('Rev'), findsNothing);
    });

    testWidgets('dynamically updates book names when screen size changes across 800 breakpoint', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          BookChooser(onSelected: (_, _, [_]) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Initially narrow (< 800): abbreviations
      expect(find.text('Gen'), findsOneWidget);
      expect(find.text('Genesis'), findsNothing);

      // Resize to wide screen (>= 800)
      tester.view.physicalSize = const Size(900, 800);
      await tester.pumpAndSettle();

      // Now wide: full names
      expect(find.text('Genesis'), findsOneWidget);
      expect(find.text('Gen'), findsNothing);

      // Resize back to narrow (< 800)
      tester.view.physicalSize = const Size(700, 800);
      await tester.pumpAndSettle();

      expect(find.text('Gen'), findsOneWidget);
      expect(find.text('Genesis'), findsNothing);
    });

    testWidgets('respects custom wideScreenBreakpoint', (tester) async {
      // Screen width is 700. With breakpoint 750, it should still be abbreviated.
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          BookChooser(
            wideScreenBreakpoint: 750,
            onSelected: (_, _, [_]) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gen'), findsOneWidget);
      expect(find.text('Genesis'), findsNothing);

      // Screen width is 550. With breakpoint 500, it should use full names.
      await tester.pumpWidget(
        createTestApp(
          BookChooser(
            wideScreenBreakpoint: 500,
            onSelected: (_, _, [_]) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Genesis'), findsOneWidget);
      expect(find.text('Gen'), findsNothing);
    });

    testWidgets('tapping a single-chapter book directly selects chapter 1', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int? selectedBookId;
      int? selectedChapter;

      await tester.pumpWidget(
        createTestApp(
          BookChooser(
            onSelected: (bookId, chapter, [section]) {
              selectedBookId = bookId;
              selectedChapter = chapter;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Obadiah (book 31) has 1 chapter
      await tester.tap(find.text('Obadiah'));
      await tester.pumpAndSettle();

      expect(selectedBookId, equals(31));
      expect(selectedChapter, equals(1));
      expect(find.byType(ChapterChooser), findsNothing);
    });

    testWidgets('tapping a multi-chapter book opens ChapterChooser', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          BookChooser(onSelected: (_, _, [_]) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Genesis has 50 chapters
      await tester.tap(find.text('Genesis'));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterChooser), findsOneWidget);
    });

    testWidgets('swiping up selects chapter 1 directly', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int? selectedBookId;
      int? selectedChapter;

      await tester.pumpWidget(
        createTestApp(
          BookChooser(
            onSelected: (bookId, chapter, [section]) {
              selectedBookId = bookId;
              selectedChapter = chapter;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swipe up on Exodus (book 2)
      await tester.fling(find.text('Exodus'), const Offset(0, -300), 1000);
      await tester.pumpAndSettle();

      expect(selectedBookId, equals(2));
      expect(selectedChapter, equals(1));
    });

    testWidgets('swiping down selects last chapter directly', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int? selectedBookId;
      int? selectedChapter;

      await tester.pumpWidget(
        createTestApp(
          BookChooser(
            onSelected: (bookId, chapter, [section]) {
              selectedBookId = bookId;
              selectedChapter = chapter;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swipe down on Exodus (book 2, 40 chapters)
      await tester.fling(find.text('Exodus'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(selectedBookId, equals(2));
      expect(selectedChapter, equals(40));
    });

    testWidgets('uses subtle outlineVariant border in light mode and black in dark mode', (tester) async {
      final lightTheme = ThemeData.light(useMaterial3: true);
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: BookChooser(onSelected: (_, _, [_]) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Container of first BookItem
      final containerFinder = find.descendant(
        of: find.byType(BookItem).first,
        matching: find.byType(Container),
      );
      final containerWidget = tester.widget<Container>(containerFinder);
      final boxDecoration = containerWidget.decoration as BoxDecoration;
      final border = boxDecoration.border as Border;

      expect(border.top.color, equals(lightTheme.colorScheme.outlineVariant));

      // Now switch to dark mode
      final darkTheme = ThemeData.dark(useMaterial3: true);
      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: BookChooser(onSelected: (_, _, [_]) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final darkContainerFinder = find.descendant(
        of: find.byType(BookItem).first,
        matching: find.byType(Container),
      );
      final darkContainerWidget = tester.widget<Container>(darkContainerFinder);
      final darkBoxDecoration = darkContainerWidget.decoration as BoxDecoration;
      final darkBorder = darkBoxDecoration.border as Border;

      expect(darkBorder.top.color, equals(Colors.black));
    });
  });
}
