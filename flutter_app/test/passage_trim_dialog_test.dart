import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/ui/playlists/widgets/passage_trim_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

void main() {
  final sampleLines = [
    UsfmLine(
      bookChapterVerse: 43003016, // John 3:16
      text: r'\wj For God so loved the world that He gave His one and only Son,\wj*',
      format: ParagraphFormat.p,
    ),
    UsfmLine(
      bookChapterVerse: 43003017, // John 3:17
      text: r'\wj For God did not send His Son into the world to condemn the world,\wj*',
      format: ParagraphFormat.p,
    ),
  ];

  testWidgets('PassageTrimDialog displays scripture and returns result on Done', (tester) async {
    PassageTrimResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await PassageTrimDialog.show(
                  context: context,
                  reference: Reference(bookId: 43, chapter: 3, verse: 16, endVerse: 17),
                  lines: sampleLines,
                );
              },
              child: const Text('Open Trim Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Trim Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Trim Scripture Passage'), findsOneWidget);
    expect(find.text('John 3:16–17'), findsWidgets);
    expect(find.byType(UsfmWidget), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Done without trimming returns empty/untrimmed result
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.isTrimmed, isFalse);
  });

  testWidgets('PassageTrimDialog with initial trim IDs highlights trimmed state', (tester) async {
    PassageTrimResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await PassageTrimDialog.show(
                  context: context,
                  reference: Reference(bookId: 43, chapter: 3, verse: 16, endVerse: 17),
                  lines: sampleLines,
                  initialStartWordId: 43003016002, // trim starting at word index 2
                  initialEndWordId: 43003017005,
                );
              },
              child: const Text('Open Trim Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Trim Dialog'));
    await tester.pumpAndSettle();

    // In trimmed state, "(Trimmed)" badge should appear in the dialog header
    expect(find.text('Trimmed'), findsOneWidget);

    // Tapping Done preserves the trim
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.isTrimmed, isTrue);
    expect(result!.startWordId, 43003016002);
    expect(result!.endWordId, 43003017005);
  });

  testWidgets('PassageTrimDialog Reset button resets trim', (tester) async {
    PassageTrimResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await PassageTrimDialog.show(
                  context: context,
                  reference: Reference(bookId: 43, chapter: 3, verse: 16, endVerse: 17),
                  lines: sampleLines,
                  initialStartWordId: 43003016002,
                  initialEndWordId: 43003017005,
                );
              },
              child: const Text('Open Trim Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Trim Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Trimmed'), findsOneWidget);

    // Tap Reset
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    // After reset, (Trimmed) badge disappears
    expect(find.text('Trimmed'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.isTrimmed, isFalse);
  });

  testWidgets('PassageTrimDialog Cancel button dismisses without changes', (tester) async {
    PassageTrimResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await PassageTrimDialog.show(
                  context: context,
                  reference: Reference(bookId: 43, chapter: 3, verse: 16),
                  lines: sampleLines,
                  initialStartWordId: 43003016002,
                );
              },
              child: const Text('Open Trim Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Trim Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
