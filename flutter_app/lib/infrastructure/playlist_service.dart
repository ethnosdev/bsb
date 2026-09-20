import 'package:flutter/foundation.dart';
import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/service_locator.dart';

class PlaylistService {
  final AnnotationDatabaseHelper _dbHelper;
  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  PlaylistService({AnnotationDatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? getIt<AnnotationDatabaseHelper>();

  Future<List<Playlist>> getPlaylists() async {
    return await _dbHelper.getAllPlaylists();
  }

  Future<Playlist?> getPlaylist(String id) async {
    return await _dbHelper.getPlaylistById(id);
  }

  Future<void> savePlaylist(Playlist playlist) async {
    await _dbHelper.savePlaylist(playlist);
    changeNotifier.value++;
  }

  Future<void> updatePlaylistMetadata(Playlist playlist) async {
    await _dbHelper.updatePlaylistMetadata(playlist);
    changeNotifier.value++;
  }

  Future<void> deletePlaylist(String id) async {
    await _dbHelper.deletePlaylist(id);
    changeNotifier.value++;
  }

  Future<Playlist> duplicatePlaylist(Playlist playlist) async {
    final newPlaylist = Playlist(
      title: '${playlist.title} (Copy)',
      items: playlist.items.map((i) => i.copyWith(id: null)).toList(),
    );
    await savePlaylist(newPlaylist);
    return newPlaylist;
  }

  Future<Playlist> touchPlaylist(Playlist playlist) async {
    final updated = playlist.copyWith(updatedAt: DateTime.now());
    await updatePlaylistMetadata(updated);
    return updated;
  }

  Future<void> clearAllPlaylists() async {
    await _dbHelper.clearAllPlaylists();
    changeNotifier.value++;
  }

  Future<void> batchInsertPlaylists(List<Playlist> playlists) async {
    await _dbHelper.batchInsertPlaylists(playlists);
    changeNotifier.value++;
  }
}
