import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/playlist_service.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePlaylistDbHelper implements AnnotationDatabaseHelper {
  final List<Playlist> _playlists = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Playlist>> getAllPlaylists() async {
    return List.from(_playlists);
  }

  @override
  Future<Playlist?> getPlaylistById(String id) async {
    final match = _playlists.where((p) => p.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<void> savePlaylist(Playlist playlist) async {
    _playlists.removeWhere((p) => p.id == playlist.id);
    _playlists.add(playlist);
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
}

void main() {
  late FakePlaylistDbHelper fakeDb;
  late PlaylistService service;

  setUp(() {
    fakeDb = FakePlaylistDbHelper();
    service = PlaylistService(dbHelper: fakeDb);
  });

  group('PlaylistService', () {
    test('starts empty and saves a playlist', () async {
      final initial = await service.getPlaylists();
      expect(initial, isEmpty);

      final p = Playlist(
        id: 'p1',
        title: 'Gospel Study',
        items: [
          PlaylistItem.reference(
            id: 'item-1',
            reference: Reference(bookId: 43, chapter: 3, verse: 16),
            orderIndex: 0,
          ),
        ],
      );

      bool notified = false;
      service.changeNotifier.addListener(() => notified = true);

      await service.savePlaylist(p);
      expect(notified, isTrue);

      final after = await service.getPlaylists();
      expect(after.length, 1);
      expect(after.first.title, 'Gospel Study');
      expect(after.first.items.first.reference?.toString(), 'John 3:16');
    });

    test('duplicates a playlist', () async {
      final p = Playlist(
        id: 'p1',
        title: 'Original Study',
        items: [
          PlaylistItem.note(id: 'n1', text: 'Intro prompt', orderIndex: 0),
        ],
      );
      await service.savePlaylist(p);

      final copy = await service.duplicatePlaylist(p);
      expect(copy.id, isNot(equals('p1')));
      expect(copy.title, 'Original Study (Copy)');
      expect(copy.items.length, 1);
      expect(copy.items.first.noteText, 'Intro prompt');

      final all = await service.getPlaylists();
      expect(all.length, 2);
    });

    test('deletes a playlist', () async {
      final p = Playlist(id: 'p1', title: 'To Delete');
      await service.savePlaylist(p);

      await service.deletePlaylist('p1');
      final all = await service.getPlaylists();
      expect(all, isEmpty);
    });

    test('touchPlaylist updates updatedAt and notifies listeners', () async {
      final oldTime = DateTime(2026, 1, 1);
      final p1 = Playlist(id: 'p1', title: 'A', updatedAt: oldTime);
      await service.savePlaylist(p1);

      bool notified = false;
      service.changeNotifier.addListener(() => notified = true);

      final touched = await service.touchPlaylist(p1);
      expect(notified, isTrue);
      expect(touched.updatedAt.isAfter(oldTime), isTrue);

      final reloaded = await service.getPlaylist('p1');
      expect(reloaded?.updatedAt, touched.updatedAt);
    });
  });
}
