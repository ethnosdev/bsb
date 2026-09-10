import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'annotation_models.dart';

class AnnotationDatabaseHelper {
  static const _databaseName = "user_annotations.db";
  static const _databaseVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE highlights (
        id TEXT PRIMARY KEY,
        book_id INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        start_word_id INTEGER NOT NULL,
        end_word_id INTEGER NOT NULL,
        color INTEGER NOT NULL,
        text TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_highlights_book_chapter 
      ON highlights(book_id, chapter)
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        book_id INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        start_word_id INTEGER NOT NULL,
        end_word_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        passage_text TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_notes_book_chapter 
      ON notes(book_id, chapter)
    ''');
  }

  // Highlights CRUD
  Future<List<Highlight>> getHighlightsForChapter(int bookId, int chapter) async {
    final db = await database;
    final maps = await db.query(
      'highlights',
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
      orderBy: 'start_word_id ASC',
    );
    return maps.map((m) => Highlight.fromMap(m)).toList();
  }

  Future<List<Highlight>> getAllHighlights({String orderBy = 'updated_at DESC'}) async {
    final db = await database;
    final maps = await db.query(
      'highlights',
      orderBy: orderBy,
    );
    return maps.map((m) => Highlight.fromMap(m)).toList();
  }

  Future<void> insertHighlight(Highlight highlight) async {
    final db = await database;
    await db.insert(
      'highlights',
      highlight.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateHighlight(Highlight highlight) async {
    final db = await database;
    await db.update(
      'highlights',
      highlight.toMap(),
      where: 'id = ?',
      whereArgs: [highlight.id],
    );
  }

  Future<void> deleteHighlight(String id) async {
    final db = await database;
    await db.delete(
      'highlights',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Highlight?> getHighlightById(String id) async {
    final db = await database;
    final maps = await db.query(
      'highlights',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Highlight.fromMap(maps.first);
  }

  Future<void> clearAllHighlights() async {
    final db = await database;
    await db.delete('highlights');
  }

  Future<void> batchInsertHighlights(List<Highlight> highlights) async {
    if (highlights.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final h in highlights) {
      batch.insert(
        'highlights',
        h.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Notes CRUD
  Future<List<Note>> getNotesForChapter(int bookId, int chapter) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
      orderBy: 'start_word_id ASC',
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<List<Note>> getAllNotes({String orderBy = 'updated_at DESC'}) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      orderBy: orderBy,
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<Note?> getNoteById(String id) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllNotes() async {
    final db = await database;
    await db.delete('notes');
  }

  Future<void> batchInsertNotes(List<Note> notes) async {
    if (notes.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final n in notes) {
      batch.insert(
        'notes',
        n.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
