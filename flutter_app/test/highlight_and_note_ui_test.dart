import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/ui/text/annotation_disambiguation_sheet.dart';
import 'package:bsb/ui/text/highlight_palette_sheet.dart';
import 'package:bsb/ui/text/note_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HighlightPaletteSheet', () {
    testWidgets('triggers onColorSelected when color circle is tapped', (tester) async {
      HighlightColor? selectedColor;
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightPaletteSheet(
              onColorSelected: (c) => selectedColor = c,
              onClear: () => cleared = true,
            ),
          ),
        ),
      );

      // Find first color circle
      final colorFinder = find.byType(InkWell).first;
      await tester.tap(colorFinder);
      await tester.pumpAndSettle();

      expect(selectedColor, isNotNull);
      expect(cleared, isFalse);
    });

    testWidgets('triggers onClear when reset button is tapped', (tester) async {
      HighlightColor? selectedColor;
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightPaletteSheet(
              onColorSelected: (c) => selectedColor = c,
              onClear: () => cleared = true,
            ),
          ),
        ),
      );

      final resetIconFinder = find.byIcon(Icons.format_color_reset);
      expect(resetIconFinder, findsOneWidget);

      await tester.tap(resetIconFinder);
      await tester.pumpAndSettle();

      expect(cleared, isTrue);
      expect(selectedColor, isNull);
    });
  });

  group('NoteEditorSheet', () {
    testWidgets('displays title and saves edited content', (tester) async {
      String? savedText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteEditorSheet(
              title: 'Genesis 1:1',
              passageText: 'In the beginning...',
              initialContent: 'My original thought',
              onSave: (text) => savedText = text,
            ),
          ),
        ),
      );

      expect(find.text('Genesis 1:1'), findsOneWidget);
      expect(find.text('In the beginning...'), findsOneWidget);
      expect(find.text('My original thought'), findsOneWidget);

      // Enter new text
      await tester.enterText(find.byType(TextField), 'Updated note content');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedText, 'Updated note content');
    });

    testWidgets('shows delete icon for existing notes and triggers onDelete', (tester) async {
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteEditorSheet(
              title: 'Genesis 1:1',
              initialContent: 'Existing note',
              isExisting: true,
              onSave: (_) {},
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

        final deleteIcon = find.byIcon(Icons.delete_outline);
      expect(deleteIcon, findsOneWidget);

      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });
  });

  group('AnnotationDisambiguationSheet', () {
    testWidgets('displays title and handles note selection', (tester) async {
      bool noteSelected = false;
      bool footnoteSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnotationDisambiguationSheet(
              title: 'Genesis 1:1',
              notePreview: 'My personal study note',
              footnotePreview: 'Hebrew Elohim is plural',
              onSelectNote: () => noteSelected = true,
              onSelectFootnote: () => footnoteSelected = true,
            ),
          ),
        ),
      );

      expect(find.text('Genesis 1:1'), findsOneWidget);
      expect(find.text('My personal study note'), findsOneWidget);
      expect(find.text('Hebrew Elohim is plural'), findsOneWidget);

      await tester.tap(find.text('My Note'));
      await tester.pumpAndSettle();

      expect(noteSelected, isTrue);
      expect(footnoteSelected, isFalse);
    });

    testWidgets('handles footnote selection', (tester) async {
      bool noteSelected = false;
      bool footnoteSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnotationDisambiguationSheet(
              title: 'Genesis 1:1',
              notePreview: 'Note content',
              footnotePreview: 'Footnote content',
              onSelectNote: () => noteSelected = true,
              onSelectFootnote: () => footnoteSelected = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Translation Footnote'));
      await tester.pumpAndSettle();

      expect(noteSelected, isFalse);
      expect(footnoteSelected, isTrue);
    });
  });
}
