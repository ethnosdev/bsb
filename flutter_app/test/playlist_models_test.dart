import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Playlist Models', () {
    test('serializes and deserializes PlaylistItem reference', () {
      final ref = Reference(
        bookId: 45, // Romans
        chapter: 8,
        verse: 28,
        endVerse: 30,
      );
      final item = PlaylistItem.reference(
        id: 'item-1',
        reference: ref,
        orderIndex: 0,
      );

      final map = item.toMap();
      expect(map['id'], 'item-1');
      expect(map['type'], 'reference');
      expect(map['book_id'], 45);
      expect(map['chapter'], 8);
      expect(map['verse'], 28);
      expect(map['end_verse'], 30);

      final fromMap = PlaylistItem.fromMap(map);
      expect(fromMap.id, 'item-1');
      expect(fromMap.isReference, isTrue);
      expect(fromMap.reference?.toString(), 'Romans 8:28–30');
    });

    test('serializes and deserializes PlaylistItem cross-chapter reference', () {
      final ref = Reference(
        bookId: 42, // Luke
        chapter: 23,
        verse: 50,
        endChapter: 24,
        endVerse: 12,
      );
      final item = PlaylistItem.reference(
        id: 'item-cross',
        reference: ref,
        orderIndex: 1,
      );

      final map = item.toMap();
      expect(map['end_chapter'], 24);
      expect(map['end_verse'], 12);

      final fromMap = PlaylistItem.fromMap(map);
      expect(fromMap.reference?.toString(), 'Luke 23:50–24:12');
    });

    test('serializes and deserializes PlaylistItem note', () {
      final item = PlaylistItem.note(
        id: 'note-1',
        text: 'Discussion prompt: What is justification?',
        orderIndex: 2,
      );

      final map = item.toMap();
      expect(map['type'], 'note');
      expect(map['note_text'], 'Discussion prompt: What is justification?');

      final fromMap = PlaylistItem.fromMap(map);
      expect(fromMap.isNote, isTrue);
      expect(fromMap.noteText, 'Discussion prompt: What is justification?');
    });

    test('serializes and deserializes complete Playlist to/from JSON', () {
      final playlist = Playlist(
        id: 'p-1',
        title: 'Romans Road Study',
        createdAt: DateTime(2026, 9, 18, 10, 0),
        updatedAt: DateTime(2026, 9, 18, 12, 0),
        items: [
          PlaylistItem.reference(
            id: 'item-1',
            reference: Reference(bookId: 45, chapter: 3, verse: 23),
            orderIndex: 0,
          ),
          PlaylistItem.note(
            id: 'note-1',
            text: 'All have sinned',
            orderIndex: 1,
          ),
          PlaylistItem.reference(
            id: 'item-2',
            reference: Reference(bookId: 45, chapter: 6, verse: 23),
            orderIndex: 2,
          ),
        ],
      );

      expect(playlist.passageCount, 2);
      expect(playlist.noteCount, 1);

      final jsonStr = playlist.toJson(pretty: true);
      final fromJson = Playlist.fromJson(jsonStr);

      expect(fromJson.id, 'p-1');
      expect(fromJson.title, 'Romans Road Study');
      expect(fromJson.items.length, 3);
      expect(fromJson.items[0].reference?.toString(), 'Romans 3:23');
      expect(fromJson.items[1].noteText, 'All have sinned');
      expect(fromJson.items[2].reference?.toString(), 'Romans 6:23');
    });
  });
}
