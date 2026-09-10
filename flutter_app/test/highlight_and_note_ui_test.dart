import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/ui/text/annotation_disambiguation_sheet.dart';
import 'package:bsb/ui/text/highlight_palette_sheet.dart';
import 'package:bsb/ui/text/note_editor_sheet.dart';
import 'package:bsb/ui/text/note_viewer_sheet.dart';
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

  group('NoteViewerSheet', () {
    testWidgets('opens in view mode displaying note content and edit pencil icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteViewerSheet(
              title: 'Psalm 32:2',
              passageText: 'Blessed is the man...',
              content: 'This is my personal note.',
              onSave: (_) {},
            ),
          ),
        ),
      );

      // Verify title, passage text, and content are displayed
      expect(find.text('Psalm 32:2'), findsOneWidget);
      expect(find.text('Blessed is the man...'), findsOneWidget);
      expect(find.text('This is my personal note.'), findsOneWidget);

      // Verify pencil icon is present
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // Verify NOT in edit mode (no TextField, no Cancel or Save buttons)
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('tapping pencil icon switches to edit mode and allows saving', (tester) async {
      String? savedText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteViewerSheet(
              title: 'Psalm 32:2',
              content: 'Initial note',
              onSave: (val) => savedText = val,
            ),
          ),
        ),
      );

      // Tap pencil icon
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Now in edit mode: TextField, Cancel, and Save buttons are visible
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Edit text and save
      await tester.enterText(find.byType(TextField), 'Modified note content');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedText, 'Modified note content');
      // Returned to view mode displaying the updated text
      expect(find.text('Modified note content'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('tapping cancel in edit mode reverts to view mode without saving', (tester) async {
      String? savedText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteViewerSheet(
              title: 'Psalm 32:2',
              content: 'Original note',
              onSave: (val) => savedText = val,
            ),
          ),
        ),
      );

      // Tap pencil to edit
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Enter new text but hit Cancel
      await tester.enterText(find.byType(TextField), 'Discarded text');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(savedText, isNull);
      expect(find.text('Original note'), findsOneWidget);
      expect(find.text('Discarded text'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
