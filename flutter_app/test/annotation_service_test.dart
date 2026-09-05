import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAnnotationDbHelper implements AnnotationDatabaseHelper {
  final List<Highlight> _highlights = [];
  final List<Note> _notes = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Highlight>> getHighlightsForChapter(int bookId, int chapter) async {
    return _highlights
        .where((h) => h.bookId == bookId && h.chapter == chapter)
        .toList()
      ..sort((a, b) => a.startWordId.compareTo(b.startWordId));
  }

  @override
  Future<void> insertHighlight(Highlight highlight) async {
    _highlights.removeWhere((h) => h.id == highlight.id);
    _highlights.add(highlight);
  }

  @override
  Future<void> updateHighlight(Highlight highlight) async {
    final index = _highlights.indexWhere((h) => h.id == highlight.id);
    if (index != -1) {
      _highlights[index] = highlight;
    }
  }

  @override
  Future<void> deleteHighlight(String id) async {
    _highlights.removeWhere((h) => h.id == id);
  }

  @override
  Future<List<Note>> getNotesForChapter(int bookId, int chapter) async {
    return _notes
        .where((n) => n.bookId == bookId && n.chapter == chapter)
        .toList()
      ..sort((a, b) => a.startWordId.compareTo(b.startWordId));
  }

  @override
  Future<Note?> getNoteById(String id) async {
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertNote(Note note) async {
    _notes.removeWhere((n) => n.id == note.id);
    _notes.add(note);
  }

  @override
  Future<void> updateNote(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
  }
}

void main() {
  late FakeAnnotationDbHelper fakeDb;
  late AnnotationService service;

  setUp(() {
    fakeDb = FakeAnnotationDbHelper();
    service = AnnotationService(dbHelper: fakeDb);
  });

  group('Highlight Overlap Logic', () {
    test('merges highlights of the same color', () async {
      await service.addHighlight(
        bookId: 1,
        chapter: 1,
        startWordId: 10,
        endWordId: 20,
        color: HighlightColor.yellow,
      );

      // Add adjacent / overlapping same color (15 to 30)
      await service.addHighlight(
        bookId: 1,
        chapter: 1,
        startWordId: 15,
        endWordId: 30,
        color: HighlightColor.yellow,
      );

      final highlights = await service.getHighlights(1, 1);
      expect(highlights.length, 1);
      expect(highlights.first.startWordId, 10);
      expect(highlights.first.endWordId, 30);
      expect(highlights.first.color, HighlightColor.yellow);
    });

    test('splits existing highlight when new color is placed in the middle', () async {
      await service.addHighlight(
        bookId: 1,
        chapter: 1,
        startWordId: 10,
        endWordId: 30,
        color: HighlightColor.yellow,
      );

      // Highlight words 15 to 20 in green
      await service.addHighlight(
        bookId: 1,
        chapter: 1,
        startWordId: 15,
        endWordId: 20,
        color: HighlightColor.green,
      );

      final highlights = await service.getHighlights(1, 1);
      expect(highlights.length, 3);
      // Yellow left part: 10..14
      expect(highlights[0].startWordId, 10);
      expect(highlights[0].endWordId, 14);
      expect(highlights[0].color, HighlightColor.yellow);

      // Green middle: 15..20
      expect(highlights[1].startWordId, 15);
      expect(highlights[1].endWordId, 20);
      expect(highlights[1].color, HighlightColor.green);

      // Yellow right part: 21..30
      expect(highlights[2].startWordId, 21);
      expect(highlights[2].endWordId, 30);
      expect(highlights[2].color, HighlightColor.yellow);
    });

    test('trims right tail of existing highlight when new color overlaps right', () async {
      await service.addHighlight(
        bookId: 1,
        chapter: 1,
        startWordId: 10,
        endWordId: 20,
        color: HighlightColor.yellow,
      );

      await service.addHighlight(
        bookId: 1,
        chapter: 1,
        startWordId: 18,
        endWordId: 25,
        color: HighlightColor.blue,
      );

      final highlights = await service.getHighlights(1, 1);
      expect(highlights.length, 2);
      expect(highlights[0].startWordId, 10);
      expect(highlights[0].endWordId, 17);
      expect(highlights[0].color, HighlightColor.yellow);

      expect(highlights[1].startWordId, 18);
      expect(highlights[1].endWordId, 25);
      expect(highlights[1].color, HighlightColor.blue);
    });

    test('clears highlights in range', () async {
      await service.addHighlight(
        bookId: 1,
        chapter: 1,
        startWordId: 10,
        endWordId: 30,
        color: HighlightColor.yellow,
      );

      await service.clearHighlightsInRange(
        bookId: 1,
        chapter: 1,
        startWordId: 15,
        endWordId: 25,
      );

      final highlights = await service.getHighlights(1, 1);
      expect(highlights.length, 2);
      expect(highlights[0].startWordId, 10);
      expect(highlights[0].endWordId, 14);
      expect(highlights[1].startWordId, 26);
      expect(highlights[1].endWordId, 30);
    });
  });

  group('Note CRUD', () {
    test('creates, updates, and deletes note', () async {
      await service.saveNote(
        bookId: 1,
        chapter: 1,
        startWordId: 10,
        endWordId: 20,
        content: 'First note',
      );

      var notes = await service.getNotes(1, 1);
      expect(notes.length, 1);
      expect(notes.first.content, 'First note');

      final noteId = notes.first.id;
      await service.saveNote(
        bookId: 1,
        chapter: 1,
        startWordId: 10,
        endWordId: 20,
        content: 'Updated note',
        existingNoteId: noteId,
      );

      notes = await service.getNotes(1, 1);
      expect(notes.length, 1);
      expect(notes.first.content, 'Updated note');

      // Empty content deletes note
      await service.saveNote(
        bookId: 1,
        chapter: 1,
        startWordId: 10,
        endWordId: 20,
        content: '',
        existingNoteId: noteId,
      );

      notes = await service.getNotes(1, 1);
      expect(notes, isEmpty);
    });
  });
}
