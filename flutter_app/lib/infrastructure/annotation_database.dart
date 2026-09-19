import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'annotation_models.dart';
import 'playlist_models.dart';

class AnnotationDatabaseHelper {
  static const _databaseName = "user_annotations.db";
  static const _databaseVersion = 4;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    await _createPlaylistTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPlaylistTables(db);
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE playlist_items ADD COLUMN note_title TEXT');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE playlist_items ADD COLUMN start_word_id INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE playlist_items ADD COLUMN end_word_id INTEGER');
      } catch (_) {}
    }
  }

  Future<void> _createPlaylistTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlists (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlist_items (
        id TEXT PRIMARY KEY,
        playlist_id TEXT NOT NULL,
        type TEXT NOT NULL,
        book_id INTEGER,
        chapter INTEGER,
        verse INTEGER,
        end_chapter INTEGER,
        end_verse INTEGER,
        start_word_id INTEGER,
        end_word_id INTEGER,
        note_title TEXT,
        note_text TEXT,
        order_index INTEGER NOT NULL,
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_playlist_items_order 
      ON playlist_items(playlist_id, order_index)
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

  // Playlists CRUD
  Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    final playlistMaps = await db.query(
      'playlists',
      orderBy: 'updated_at DESC',
    );
    if (playlistMaps.isEmpty) return [];

    final itemMaps = await db.query(
      'playlist_items',
      orderBy: 'order_index ASC',
    );

    final itemsByPlaylist = <String, List<PlaylistItem>>{};
    for (final m in itemMaps) {
      final pid = m['playlist_id'] as String;
      itemsByPlaylist.putIfAbsent(pid, () => []).add(PlaylistItem.fromMap(m));
    }

    return playlistMaps.map((m) {
      final id = m['id'] as String;
      return Playlist.fromMap(m, itemsByPlaylist[id] ?? []);
    }).toList();
  }

  Future<Playlist?> getPlaylistById(String id) async {
    final db = await database;
    final maps = await db.query(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;

    final itemMaps = await db.query(
      'playlist_items',
      where: 'playlist_id = ?',
      whereArgs: [id],
      orderBy: 'order_index ASC',
    );
    final items = itemMaps.map((m) => PlaylistItem.fromMap(m)).toList();
    return Playlist.fromMap(maps.first, items);
  }

  Future<void> savePlaylist(Playlist playlist) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'playlists',
        playlist.toMap(includeItems: false),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        'playlist_items',
        where: 'playlist_id = ?',
        whereArgs: [playlist.id],
      );

      final batch = txn.batch();
      for (int i = 0; i < playlist.items.length; i++) {
        final item = playlist.items[i];
        final itemMap = item.toMap();
        itemMap['playlist_id'] = playlist.id;
        itemMap['order_index'] = i;
        batch.insert(
          'playlist_items',
          itemMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> deletePlaylist(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'playlist_items',
        where: 'playlist_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'playlists',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> batchInsertPlaylists(List<Playlist> playlists) async {
    for (final p in playlists) {
      await savePlaylist(p);
    }
  }

  Future<void> clearAllPlaylists() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('playlist_items');
      await txn.delete('playlists');
    });
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
