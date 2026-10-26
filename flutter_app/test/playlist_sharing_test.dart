import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/ui/playlists/playlist_share_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Playlist Sharing & URL Compression', () {
    test('encodes playlist to bsb:// URL and decodes accurately', () {
      final original = Playlist(
        id: 'p-share-1',
        title: 'Passion Week',
        items: [
          PlaylistItem.reference(
            id: 'item-1',
            reference: Reference(
              bookId: 42, // Luke
              chapter: 23,
              verse: 50,
              endChapter: 24,
              endVerse: 12,
            ),
            orderIndex: 0,
          ),
          PlaylistItem.note(
            id: 'item-2',
            text: 'Notice the reaction of the disciples.',
            orderIndex: 1,
          ),
          PlaylistItem.reference(
            id: 'item-3',
            reference: Reference(bookId: 43, chapter: 20, verse: 1, endVerse: 18),
            orderIndex: 2,
          ),
        ],
      );

      final url = PlaylistShareHandler.encodePlaylistToUrl(original);
      expect(url, startsWith('bsb://playlist?data='));

      final decoded = PlaylistShareHandler.decodePlaylistFromUrl(url);
      expect(decoded, isNotNull);
      expect(decoded!.id, original.id);
      expect(decoded.title, original.title);
      expect(decoded.items.length, 3);
      expect(decoded.items[0].reference?.toString(), 'Luke 23:50–24:12');
      expect(decoded.items[1].noteText, 'Notice the reaction of the disciples.');
      expect(decoded.items[2].reference?.toString(), 'John 20:1–18');
    });

    test('decodes direct JSON fallback', () {
      final original = Playlist(
        id: 'p-json',
        title: 'Simple Study',
        items: [
          PlaylistItem.note(id: 'n1', text: 'Simple note', orderIndex: 0),
        ],
      );

      final jsonStr = original.toJson();
      final decoded = PlaylistShareHandler.decodePlaylistFromUrl(jsonStr);
      expect(decoded, isNotNull);
      expect(decoded!.title, 'Simple Study');
      expect(decoded.items.first.noteText, 'Simple note');
    });

    test('returns null on invalid input', () {
      expect(PlaylistShareHandler.decodePlaylistFromUrl(''), isNull);
      expect(PlaylistShareHandler.decodePlaylistFromUrl('not a playlist'), isNull);
      expect(PlaylistShareHandler.decodePlaylistFromUrl('bsb://playlist?data=invalid'), isNull);
    });

    test('decodes playlist from instructional text message', () {
      final original = Playlist(
        id: 'p-inst-1',
        title: 'Faith and Works',
        items: [
          PlaylistItem.note(id: 'n1', text: 'James 2 reflection', orderIndex: 0),
        ],
      );
      final code = PlaylistShareHandler.encodePlaylistToUrl(original);
      final message = 'BSB Playlist: ${original.title}\n'
          'To import in the BSB app, copy this message and select "Import from Clipboard" in the Playlists menu:\n'
          '$code';

      final decoded = PlaylistShareHandler.decodePlaylistFromUrl(message);
      expect(decoded, isNotNull);
      expect(decoded!.title, 'Faith and Works');
      expect(decoded.items.first.noteText, 'James 2 reflection');
    });
  });
}
