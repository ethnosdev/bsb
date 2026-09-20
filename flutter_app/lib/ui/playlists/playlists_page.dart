import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/playlist_service.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/playlists/playlist_editor_page.dart';
import 'package:bsb/ui/playlists/playlist_presentation_page.dart';
import 'package:bsb/ui/playlists/playlist_share_handler.dart';
import 'package:bsb/ui/playlists/widgets/playlist_qr_dialog.dart';
import 'package:flutter/material.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final _playlistService = getIt<PlaylistService>();
  late final PlaylistShareHandler _shareHandler;
  List<Playlist> _playlists = [];
  bool _isLoading = true;
  bool _isEditorOrPresentationOpen = false;

  @override
  void initState() {
    super.initState();
    _shareHandler = PlaylistShareHandler(playlistService: _playlistService);
    _playlistService.changeNotifier.addListener(_loadPlaylists);
    _loadPlaylists();
  }

  @override
  void dispose() {
    _playlistService.changeNotifier.removeListener(_loadPlaylists);
    _shareHandler.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    if (_isEditorOrPresentationOpen) return;
    final list = await _playlistService.getPlaylists();
    if (mounted) {
      setState(() {
        _playlists = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _createPlaylist() async {
    final titleController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Playlist'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Playlist Title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            if (titleController.text.trim().isNotEmpty) {
              Navigator.of(ctx).pop(true);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created == true && mounted) {
      final newPlaylist = Playlist(
        title: titleController.text.trim(),
      );
      await _playlistService.savePlaylist(newPlaylist);

      if (mounted) {
        _isEditorOrPresentationOpen = true;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistEditorPage(playlist: newPlaylist),
          ),
        );
        _isEditorOrPresentationOpen = false;
        if (mounted) _loadPlaylists();
      }
    }
  }

  Future<void> _openEditor(Playlist playlist) async {
    final touched = await _playlistService.touchPlaylist(playlist);
    if (mounted) {
      _isEditorOrPresentationOpen = true;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistEditorPage(playlist: touched),
        ),
      );
      _isEditorOrPresentationOpen = false;
      if (mounted) _loadPlaylists();
    }
  }

  Future<void> _present(Playlist playlist) async {
    final touched = await _playlistService.touchPlaylist(playlist);
    if (mounted) {
      _isEditorOrPresentationOpen = true;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistPresentationPage(playlist: touched),
        ),
      );
      _isEditorOrPresentationOpen = false;
      if (mounted) _loadPlaylists();
    }
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _playlistService.deletePlaylist(playlist.id);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'import_file') {
                _shareHandler.importPlaylistFromFile(context);
              } else if (val == 'import_clipboard') {
                _shareHandler.importFromClipboard(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import_file',
                child: ListTile(
                  leading: Icon(Icons.file_open_outlined),
                  title: Text('Import from File'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import_clipboard',
                child: ListTile(
                  leading: Icon(Icons.paste_outlined),
                  title: Text('Import from Clipboard'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _playlists.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.playlist_play_rounded,
                          size: 72,
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Playlists Yet',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A playlist is an ordered collection of passages and notes for leading a study or reading topically.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create Playlist'),
                          onPressed: _createPlaylist,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        title: Text(
                          playlist.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          _formatDate(playlist.updatedAt),
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (val) {
                            if (val == 'present') {
                              _present(playlist);
                            } else if (val == 'edit') {
                              _openEditor(playlist);
                            } else if (val == 'duplicate') {
                              _playlistService.duplicatePlaylist(playlist);
                            } else if (val == 'share_file') {
                              _shareHandler.exportPlaylistFile(context, playlist);
                            } else if (val == 'share_link') {
                              _shareHandler.copyShareLink(context, playlist);
                            } else if (val == 'qr') {
                              PlaylistQrDialog.show(context, playlist);
                            } else if (val == 'delete') {
                              _deletePlaylist(playlist);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'present',
                              child: ListTile(
                                leading: Icon(Icons.play_circle_outline),
                                title: Text('Present'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Edit'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'duplicate',
                              child: ListTile(
                                leading: Icon(Icons.copy_outlined),
                                title: Text('Duplicate'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'share_file',
                              child: ListTile(
                                leading: Icon(Icons.share_outlined),
                                title: Text('Share File (.bsbplaylist)'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'share_link',
                              child: ListTile(
                                leading: Icon(Icons.link_outlined),
                                title: Text('Copy Share Link'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'qr',
                              child: ListTile(
                                leading: Icon(Icons.qr_code_outlined),
                                title: Text('Share by QR Code'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('Delete'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _present(playlist),
                      ),
                    );
                  },
                ),
      floatingActionButton: _playlists.isNotEmpty
          ? FloatingActionButton(
              onPressed: _createPlaylist,
              tooltip: 'New Playlist',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
