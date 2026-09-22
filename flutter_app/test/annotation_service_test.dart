import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/reading_plan_models.dart';
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
  Future<List<Highlight>> getAllHighlights({String orderBy = 'updated_at DESC'}) async {
    final list = List<Highlight>.from(_highlights);
    if (orderBy.contains('start_word_id') || orderBy.contains('book_id')) {
      list.sort((a, b) {
        final bComp = a.bookId.compareTo(b.bookId);
        if (bComp != 0) return bComp;
        final cComp = a.chapter.compareTo(b.chapter);
        if (cComp != 0) return cComp;
        return a.startWordId.compareTo(b.startWordId);
      });
    } else if (orderBy.contains('ASC')) {
      list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    } else {
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return list;
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
  Future<void> updateHighlightText(String id, String text) async {
    final index = _highlights.indexWhere((h) => h.id == id);
    if (index != -1) {
      _highlights[index] = _highlights[index].copyWith(text: text);
    }
  }

  @override
  Future<void> deleteHighlight(String id) async {
    _highlights.removeWhere((h) => h.id == id);
  }

  @override
  Future<Highlight?> getHighlightById(String id) async {
    final index = _highlights.indexWhere((h) => h.id == id);
    return index != -1 ? _highlights[index] : null;
  }

  @override
  Future<void> clearAllHighlights() async {
    _highlights.clear();
  }

  @override
  Future<void> batchInsertHighlights(List<Highlight> highlights) async {
    for (final h in highlights) {
      await insertHighlight(h);
    }
  }

  @override
  Future<List<Note>> getNotesForChapter(int bookId, int chapter) async {
    return _notes
        .where((n) => n.bookId == bookId && n.chapter == chapter)
        .toList()
      ..sort((a, b) => a.startWordId.compareTo(b.startWordId));
  }

  @override
  Future<List<Note>> getAllNotes({String orderBy = 'updated_at DESC'}) async {
    final list = List<Note>.from(_notes);
    if (orderBy.contains('start_word_id') || orderBy.contains('book_id')) {
      list.sort((a, b) {
        final bComp = a.bookId.compareTo(b.bookId);
        if (bComp != 0) return bComp;
        final cComp = a.chapter.compareTo(b.chapter);
        if (cComp != 0) return cComp;
        return a.startWordId.compareTo(b.startWordId);
      });
    } else if (orderBy.contains('ASC')) {
      list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    } else {
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return list;
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
  Future<void> updateNotePassageText(String id, String text) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(passageText: text);
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
  }

  @override
  Future<void> clearAllNotes() async {
    _notes.clear();
  }

  @override
  Future<void> batchInsertNotes(List<Note> notes) async {
    for (final n in notes) {
      await insertNote(n);
    }
  }

  final List<Playlist> _playlists = [];

  @override
  Future<List<Playlist>> getAllPlaylists() async => List.from(_playlists);

  @override
  Future<Playlist?> getPlaylistById(String id) async {
    try {
      return _playlists.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePlaylist(Playlist playlist) async {
    _playlists.removeWhere((p) => p.id == playlist.id);
    _playlists.add(playlist);
  }

  @override
  Future<void> updatePlaylistMetadata(Playlist playlist) async {
    final index = _playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      _playlists[index] = _playlists[index].copyWith(
        title: playlist.title,
        updatedAt: playlist.updatedAt,
      );
    } else {
      _playlists.add(playlist);
    }
  }

  @override
  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> batchInsertPlaylists(List<Playlist> playlists) async {
    for (final p in playlists) {
      await savePlaylist(p);
    }
  }

  @override
  Future<void> clearAllPlaylists() async {
    _playlists.clear();
  }

  final List<UserPlanProgress> _readingPlans = [];

  @override
  Future<List<UserPlanProgress>> getAllPlanProgress() async => List.from(_readingPlans);

  @override
  Future<UserPlanProgress?> getPlanProgress(String planId) async {
    try {
      return _readingPlans.firstWhere((p) => p.planId == planId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserPlanProgress?> getActivePlanProgress() async {
    try {
      return _readingPlans.firstWhere((p) => p.isActive);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePlanProgress(UserPlanProgress progress) async {
    _readingPlans.removeWhere((p) => p.planId == progress.planId);
    _readingPlans.add(progress);
  }

  @override
  Future<void> setActivePlan(String planId) async {
    for (int i = 0; i < _readingPlans.length; i++) {
      if (_readingPlans[i].planId == planId) {
        _readingPlans[i] = _readingPlans[i].copyWith(isActive: true);
      } else {
        _readingPlans[i] = _readingPlans[i].copyWith(isActive: false);
      }
    }
  }

  @override
  Future<void> deletePlanProgress(String planId) async {
    _readingPlans.removeWhere((p) => p.planId == planId);
  }

  @override
  Future<void> batchInsertPlanProgress(List<UserPlanProgress> list) async {
    for (final p in list) {
      await savePlanProgress(p);
    }
  }

  @override
  Future<void> clearAllPlanProgress() async {
    _readingPlans.clear();
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

    test('getAllHighlights and deleteHighlight', () async {
      await service.addHighlight(
        bookId: 1,
        chapter: 1,
        startWordId: 10,
        endWordId: 20,
        color: HighlightColor.yellow,
      );
      await service.addHighlight(
        bookId: 43,
        chapter: 3,
        startWordId: 100,
        endWordId: 110,
        color: HighlightColor.blue,
      );

      final all = await service.getAllHighlights();
      expect(all.length, 2);

      await service.deleteHighlight(all.first.id);
      final remaining = await service.getAllHighlights();
      expect(remaining.length, 1);
    });

    test('getAllNotes returns all notes across chapters and books', () async {
      await service.saveNote(
        bookId: 1,
        chapter: 1,
        startWordId: 10,
        endWordId: 20,
        content: 'Note in Genesis',
      );
      await service.saveNote(
        bookId: 19,
        chapter: 23,
        startWordId: 50,
        endWordId: 60,
        content: 'Note in Psalms',
      );

      final allNotes = await service.getAllNotes();
      expect(allNotes.length, 2);
    });

    test('addHighlight and saveNote store text and passageText', () async {
      await service.addHighlight(
        bookId: 19,
        chapter: 32,
        startWordId: 19032002000,
        endWordId: 19032002005,
        color: HighlightColor.purple,
        text: 'Blessed is the man whose iniquity',
      );

      final highlights = await service.getAllHighlights();
      expect(highlights.first.text, 'Blessed is the man whose iniquity');

      await service.saveNote(
        bookId: 19,
        chapter: 32,
        startWordId: 19032002000,
        endWordId: 19032002005,
        content: 'Reflections on Psalm 32:2',
        passageText: 'Blessed is the man whose iniquity',
      );

      final notes = await service.getAllNotes();
      expect(notes.first.passageText, 'Blessed is the man whose iniquity');
    });
  });
}
