import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/playlist_service.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/playlists/playlist_presentation_page.dart';
import 'package:bsb/ui/playlists/playlist_share_handler.dart';
import 'package:bsb/ui/playlists/widgets/passage_range_picker_dialog.dart';
import 'package:bsb/ui/playlists/widgets/passage_trim_helper.dart';
import 'package:bsb/ui/playlists/widgets/playlist_note_editor_dialog.dart';
import 'package:bsb/ui/playlists/widgets/playlist_qr_dialog.dart';
import 'package:flutter/material.dart';

class PlaylistEditorPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistEditorPage({super.key, required this.playlist});

  @override
  State<PlaylistEditorPage> createState() => _PlaylistEditorPageState();
}

class _PlaylistEditorPageState extends State<PlaylistEditorPage> {
  late final TextEditingController _titleController;
  final _playlistService = getIt<PlaylistService>();
  final _dbHelper = getIt<DatabaseHelper>();
  late final PlaylistShareHandler _shareHandler;

  late List<PlaylistItem> _items;
  final Map<String, String> _snippetCache = {};

  @override
  void initState() {
    super.initState();
    _shareHandler = PlaylistShareHandler(playlistService: _playlistService);
    _titleController = TextEditingController(text: widget.playlist.title);
    _items = List.from(widget.playlist.items);
    _loadSnippets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadSnippets() async {
    for (final item in _items) {
      if (item.isReference && item.reference != null && !_snippetCache.containsKey(item.id)) {
        try {
          final lines = await _dbHelper.getRange(item.reference!);
          final trimmed = trimPassageLines(lines, item.startWordId, item.endWordId);
          final text = cleanPassagePreview(trimmed);
          _snippetCache[item.id] = text;
        } catch (_) {}
      }
    }
    if (mounted) setState(() {});
  }

  Playlist _buildPlaylist() {
    return widget.playlist.copyWith(
      title: _titleController.text.trim().isEmpty ? 'Untitled Playlist' : _titleController.text.trim(),
      updatedAt: DateTime.now(),
      items: _items,
    );
  }

  Future<void> _savePlaylist() async {
    final updated = _buildPlaylist();
    await _playlistService.savePlaylist(updated);
  }

  void _onReorderItem(int oldIndex, int newIndex) {
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      // Re-index
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(orderIndex: i);
      }
    });
    _savePlaylist();
  }

  Future<void> _addPassage() async {
    final result = await PassageRangePickerDialog.show(context);
    if (result != null) {
      final newItem = PlaylistItem.reference(
        reference: result.reference,
        startWordId: result.startWordId,
        endWordId: result.endWordId,
        orderIndex: _items.length,
      );
      setState(() {
        _items.add(newItem);
      });
      _loadSnippets();
      await _savePlaylist();
    }
  }

  Future<void> _editPassage(PlaylistItem item, int index) async {
    final result = await PassageRangePickerDialog.show(
      context,
      initialReference: item.reference,
      initialStartWordId: item.startWordId,
      initialEndWordId: item.endWordId,
      onDelete: () {
        _deleteItemWithoutConfirm(index);
      },
    );
    if (result != null) {
      setState(() {
        _items[index] = item.copyWith(
          reference: result.reference,
          startWordId: result.startWordId,
          endWordId: result.endWordId,
        );
        _snippetCache.remove(item.id);
      });
      _loadSnippets();
      await _savePlaylist();
    }
  }

  Future<void> _addNote() async {
    final result = await PlaylistNoteEditorDialog.show(context);
    if (result != null && result.text.isNotEmpty) {
      final newItem = PlaylistItem.note(
        noteTitle: result.title,
        text: result.text,
        orderIndex: _items.length,
      );
      setState(() {
        _items.add(newItem);
      });
      await _savePlaylist();
    }
  }

  Future<void> _editNote(PlaylistItem item, int index) async {
    final result = await PlaylistNoteEditorDialog.show(
      context,
      initialTitle: item.noteTitle,
      initialText: item.noteText,
      isEditing: true,
    );
    if (result != null) {
      if (result.isDeleted) {
        _deleteItemWithoutConfirm(index);
      } else {
        setState(() {
          _items[index] = item.copyWith(
            noteTitle: result.title,
            noteText: result.text,
          );
        });
        await _savePlaylist();
      }
    }
  }

  void _deleteItemWithoutConfirm(int index) {
    setState(() {
      _items.removeAt(index);
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(orderIndex: i);
      }
    });
    _savePlaylist();
  }

  void _present() {
    _savePlaylist();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistPresentationPage(playlist: _buildPlaylist()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Playlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_fill_rounded),
            tooltip: 'Present',
            color: theme.colorScheme.primary,
            onPressed: _present,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              final playlist = _buildPlaylist();
              if (val == 'share') {
                _shareHandler.exportPlaylistFile(context, playlist);
              } else if (val == 'link') {
                _shareHandler.copyShareLink(context, playlist);
              } else if (val == 'qr') {
                PlaylistQrDialog.show(context, playlist);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share File (.bsbplaylist)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'link',
                child: ListTile(
                  leading: Icon(Icons.link),
                  title: Text('Copy Share Link'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'qr',
                child: ListTile(
                  leading: Icon(Icons.qr_code),
                  title: Text('Share by QR Code'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Title Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: TextField(
              controller: _titleController,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Playlist Title',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _savePlaylist(),
            ),
          ),

          // Items List
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.playlist_add_rounded, size: 54, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No items in this playlist yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add scripture passages and notes using the buttons below.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: _items.length,
                    onReorderItem: _onReorderItem,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(item.id),
                        index: index,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: item.isReference
                              ? _buildPassageTile(item, index)
                              : _buildNoteTile(item, index),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Bar for Adding Items
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Passage'),
                      onPressed: _addPassage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Add Note'),
                      onPressed: _addNote,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassageTile(PlaylistItem item, int index) {
    final theme = Theme.of(context);
    final snippet = _snippetCache[item.id] ?? '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(Icons.menu_book, color: theme.colorScheme.onPrimaryContainer, size: 20),
      ),
      title: Row(
        children: [
          Text(
            item.reference.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (item.isTrimmed) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Trimmed',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: snippet.isNotEmpty
          ? Text(
              snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            )
          : null,
      onTap: () => _editPassage(item, index),
    );
  }

  Widget _buildNoteTile(PlaylistItem item, int index) {
    final theme = Theme.of(context);
    final title = (item.noteTitle != null && item.noteTitle!.trim().isNotEmpty)
        ? item.noteTitle!.trim()
        : 'Note';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(Icons.note_alt_outlined, color: theme.colorScheme.onSecondaryContainer, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        item.noteText ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      onTap: () => _editNote(item, index),
    );
  }
}
