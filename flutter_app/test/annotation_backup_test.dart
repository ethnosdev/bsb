import 'package:flutter_test/flutter_test.dart';
import 'package:bsb/infrastructure/annotation_backup.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';

import 'annotation_service_test.dart';

void main() {
  group('AnnotationBackup Model & Serialization', () {
    final sampleHighlight = Highlight(
      id: 'h1',
      bookId: 19,
      chapter: 32,
      startWordId: 19032001000,
      endWordId: 19032001005,
      color: HighlightColor.yellow,
      text: 'Blessed is he whose transgression is forgiven',
      createdAt: DateTime.parse('2026-09-01T10:00:00.000Z'),
      updatedAt: DateTime.parse('2026-09-01T10:30:00.000Z'),
    );

    final sampleNote = Note(
      id: 'n1',
      bookId: 43,
      chapter: 3,
      startWordId: 43003016001,
      endWordId: 43003016010,
      content: 'A pivotal verse on God\'s unconditional love.',
      passageText: 'For God so loved the world',
      createdAt: DateTime.parse('2026-09-02T12:00:00.000Z'),
      updatedAt: DateTime.parse('2026-09-02T12:15:00.000Z'),
    );

    test('serializes to Map and JSON and deserializes correctly', () {
      final backup = AnnotationBackup(
        exportedAt: DateTime.parse('2026-09-10T15:00:00.000Z'),
        highlights: [sampleHighlight],
        notes: [sampleNote],
      );

      final jsonString = backup.toJson();
      expect(jsonString, contains('"version": 1'));
      expect(jsonString, contains('"app": "bsb"'));
      expect(jsonString, contains('Blessed is he whose transgression is forgiven'));
      expect(jsonString, contains('A pivotal verse on God\'s unconditional love.'));

      final restored = AnnotationBackup.fromJson(jsonString);
      expect(restored.version, equals(1));
      expect(restored.app, equals('bsb'));
      expect(restored.highlights.length, equals(1));
      expect(restored.highlights.first.id, equals('h1'));
      expect(restored.highlights.first.text, equals('Blessed is he whose transgression is forgiven'));
      expect(restored.highlights.first.color, equals(HighlightColor.yellow));

      expect(restored.notes.length, equals(1));
      expect(restored.notes.first.id, equals('n1'));
      expect(restored.notes.first.content, equals('A pivotal verse on God\'s unconditional love.'));
      expect(restored.notes.first.passageText, equals('For God so loved the world'));
    });

    test('handles dates stored as milliseconds since epoch or ISO string', () {
      final map = {
        'version': 1,
        'app': 'bsb',
        'exported_at': 1725980400000, // epoch ms
        'highlights': [
          {
            'id': 'h_epoch',
            'book_id': 1,
            'chapter': 1,
            'start_word_id': 1001001000,
            'end_word_id': 1001001003,
            'color': 'green',
            'text': 'In the beginning',
            'created_at': 1725900000000,
            'updated_at': '2026-09-09T14:00:00.000Z', // ISO string
          }
        ],
        'notes': [
          {
            'id': 'n_epoch',
            'book_id': 1,
            'chapter': 1,
            'start_word_id': 1001001000,
            'end_word_id': 1001001003,
            'content': 'Creation',
            'passage_text': 'In the beginning',
            'created_at': '2026-09-09T13:00:00.000Z',
            'updated_at': 1725900500000,
          }
        ],
      };

      final backup = AnnotationBackup.fromMap(map);
      expect(backup.highlights.length, equals(1));
      expect(backup.highlights.first.color, equals(HighlightColor.green));
      expect(backup.notes.length, equals(1));
      expect(backup.notes.first.content, equals('Creation'));
    });

    test('throws FormatException on malformed JSON', () {
      expect(() => AnnotationBackup.fromJson('["not", "a", "map"]'), throwsFormatException);
      expect(() => AnnotationBackup.fromJson('{invalid_json'), throwsA(isA<FormatException>()));
    });

    test('generates clean Markdown export', () {
      final backup = AnnotationBackup(
        exportedAt: DateTime(2026, 9, 10),
        highlights: [sampleHighlight],
        notes: [sampleNote],
      );

      final md = backup.toMarkdown();
      expect(md, contains('# BSB Highlights & Notes'));
      expect(md, contains('Exported on September 10, 2026'));
      expect(md, contains('## Highlights (1)'));
      expect(md, contains('Psalm 32:1 (yellow)'));
      expect(md, contains('> Blessed is he whose transgression is forgiven'));
      expect(md, contains('## Notes (1)'));
      expect(md, contains('John 3:16'));
      expect(md, contains('> For God so loved the world'));
      expect(md, contains('A pivotal verse on God\'s unconditional love.'));
    });
  });

  group('AnnotationService Backup & Restore', () {
    late FakeAnnotationDbHelper fakeDb;
    late AnnotationService service;

    setUp(() {
      fakeDb = FakeAnnotationDbHelper();
      service = AnnotationService(dbHelper: fakeDb);
    });

    test('createBackup fetches all highlights and notes', () async {
      await service.addHighlight(
        bookId: 19,
        chapter: 32,
        startWordId: 19032001000,
        endWordId: 19032001005,
        color: HighlightColor.yellow,
        text: 'Blessed is he',
      );
      await service.saveNote(
        bookId: 43,
        chapter: 3,
        startWordId: 43003016001,
        endWordId: 43003016010,
        content: 'Love verse',
        passageText: 'For God so loved',
      );

      final backup = await service.createBackup();
      expect(backup.highlights.length, equals(1));
      expect(backup.notes.length, equals(1));
      expect(backup.highlights.first.text, equals('Blessed is he'));
      expect(backup.notes.first.content, equals('Love verse'));
    });

    test('restoreBackup with replace mode replaces existing annotations', () async {
      // Existing data
      await service.addHighlight(
        bookId: 1,
        chapter: 1,
        startWordId: 1001001000,
        endWordId: 1001001002,
        color: HighlightColor.blue,
        text: 'Old highlight',
      );
      await service.saveNote(
        bookId: 1,
        chapter: 1,
        startWordId: 1001001000,
        endWordId: 1001001002,
        content: 'Old note',
      );

      // Backup with different data
      final backup = AnnotationBackup(
        exportedAt: DateTime.now(),
        highlights: [
          Highlight(
            id: 'h_new',
            bookId: 2,
            chapter: 1,
            startWordId: 2001001000,
            endWordId: 2001001005,
            color: HighlightColor.pink,
            text: 'New highlight',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        notes: [
          Note(
            id: 'n_new',
            bookId: 2,
            chapter: 1,
            startWordId: 2001001000,
            endWordId: 2001001005,
            content: 'New note',
            passageText: 'New passage',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      final result = await service.restoreBackup(backup, mode: AnnotationImportMode.replace);
      expect(result.highlightsImported, equals(1));
      expect(result.notesImported, equals(1));

      final allHighlights = await service.getAllHighlights();
      final allNotes = await service.getAllNotes();

      expect(allHighlights.length, equals(1));
      expect(allHighlights.first.id, equals('h_new'));
      expect(allNotes.length, equals(1));
      expect(allNotes.first.id, equals('n_new'));
    });

    test('restoreBackup with merge mode merges items and respects updatedAt', () async {
      final baseDate = DateTime(2026, 9, 1);
      final newerDate = DateTime(2026, 9, 5);
      final olderDate = DateTime(2026, 8, 25);

      // Existing highlight: updatedAt = Sept 1
      final hExisting = Highlight(
        id: 'h_merge_1',
        bookId: 19,
        chapter: 1,
        startWordId: 19001001000,
        endWordId: 19001001005,
        color: HighlightColor.yellow,
        text: 'Existing highlight',
        createdAt: baseDate,
        updatedAt: baseDate,
      );
      await fakeDb.insertHighlight(hExisting);

      // Existing note: updatedAt = Sept 5 (newer than backup's older version)
      final nExisting = Note(
        id: 'n_merge_keep',
        bookId: 19,
        chapter: 1,
        startWordId: 19001001000,
        endWordId: 19001001005,
        content: 'Local newer note content',
        createdAt: baseDate,
        updatedAt: newerDate,
      );
      await fakeDb.insertNote(nExisting);

      // Backup contains:
      // 1. h_merge_1 updated with newerDate
      // 2. h_new_item brand new highlight
      // 3. n_merge_keep with olderDate (should not overwrite local newer)
      // 4. n_new_item brand new note
      final backup = AnnotationBackup(
        exportedAt: DateTime.now(),
        highlights: [
          hExisting.copyWith(
            text: 'Updated in backup',
            updatedAt: newerDate,
          ),
          Highlight(
            id: 'h_new_item',
            bookId: 20,
            chapter: 1,
            startWordId: 20001001000,
            endWordId: 20001001005,
            color: HighlightColor.purple,
            text: 'Brand new highlight',
            createdAt: baseDate,
            updatedAt: baseDate,
          ),
        ],
        notes: [
          nExisting.copyWith(
            content: 'Old backup note content',
            updatedAt: olderDate,
          ),
          Note(
            id: 'n_new_item',
            bookId: 20,
            chapter: 1,
            startWordId: 20001001000,
            endWordId: 20001001005,
            content: 'Brand new note',
            passageText: 'Proverbs passage',
            createdAt: baseDate,
            updatedAt: baseDate,
          ),
        ],
      );

      final result = await service.restoreBackup(backup, mode: AnnotationImportMode.merge);
      expect(result.highlightsImported, equals(2)); // updated existing + added new
      expect(result.notesImported, equals(1)); // only added new note (skipped older)

      final allHighlights = await service.getAllHighlights();
      final allNotes = await service.getAllNotes();

      expect(allHighlights.length, equals(2));
      final updatedH = allHighlights.firstWhere((h) => h.id == 'h_merge_1');
      expect(updatedH.text, equals('Updated in backup'));

      expect(allNotes.length, equals(2));
      final preservedN = allNotes.firstWhere((n) => n.id == 'n_merge_keep');
      expect(preservedN.content, equals('Local newer note content'));
    });
  });
}
