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

    test('canFitInQr correctly identifies valid vs oversized playlists', () {
      final normalPlaylist = Playlist(
        id: 'p-normal',
        title: 'Morning Prayer',
        items: [
          PlaylistItem.reference(
            reference: Reference(bookId: 19, chapter: 23, verse: 1, endVerse: 6),
            orderIndex: 0,
          ),
          PlaylistItem.note(text: 'The Lord is my shepherd', orderIndex: 1),
        ],
      );
      expect(PlaylistShareHandler.canFitInQr(normalPlaylist), isTrue);

      final oversizedPlaylist = Playlist(
        id: 'p-huge',
        title: 'Very Large Study',
        items: [
          PlaylistItem.note(
            title: 'Point 1',
            text: List.generate(400, (i) => 'Sermon reflection line $i describing detailed theological discourse').join('\n'),
            orderIndex: 0,
          ),
          PlaylistItem.note(
            title: 'Point 2',
            text: List.generate(400, (i) => 'Additional practical application paragraph $i for personal ministry').join('\n'),
            orderIndex: 1,
          ),
        ],
      );
      expect(PlaylistShareHandler.canFitInQr(oversizedPlaylist), isFalse);
    });
  });
}
