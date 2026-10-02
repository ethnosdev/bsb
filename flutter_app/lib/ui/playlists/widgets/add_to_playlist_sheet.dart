import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/playlist_service.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/playlists/widgets/passage_trim_helper.dart';
import 'package:flutter/material.dart';

class AddToPlaylistSheet extends StatefulWidget {
  final Reference reference;
  final int? startWordId;
  final int? endWordId;
  final String? selectedText;
  final bool? isTrimmed;
  final PlaylistService? playlistService;
  final DatabaseHelper? dbHelper;

  const AddToPlaylistSheet({
    super.key,
    required this.reference,
    this.startWordId,
    this.endWordId,
    this.selectedText,
    this.isTrimmed,
    this.playlistService,
    this.dbHelper,
  });

  static Future<bool?> show({
    required BuildContext context,
    required Reference reference,
    int? startWordId,
    int? endWordId,
    String? selectedText,
    bool? isTrimmed,
    PlaylistService? playlistService,
    DatabaseHelper? dbHelper,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      constraints: BoxConstraints(
        maxWidth: 600,
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (context) => AddToPlaylistSheet(
        reference: reference,
        startWordId: startWordId,
        endWordId: endWordId,
        selectedText: selectedText,
        isTrimmed: isTrimmed,
        playlistService: playlistService,
        dbHelper: dbHelper,
      ),
    );
  }

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  PlaylistService? _playlistService;
  final TextEditingController _newPlaylistController = TextEditingController();
  List<Playlist> _playlists = [];
  bool _isLoading = true;
  bool _isCreating = false;
  late bool _isTrimmed;

  @override
  void initState() {
    super.initState();
    _isTrimmed = widget.isTrimmed ??
        (widget.startWordId != null || widget.endWordId != null);

    if (widget.playlistService != null) {
      _playlistService = widget.playlistService;
    } else if (getIt.isRegistered<PlaylistService>()) {
      _playlistService = getIt<PlaylistService>();
    } else if (getIt.isRegistered<AnnotationDatabaseHelper>()) {
      _playlistService = PlaylistService(
        dbHelper: getIt<AnnotationDatabaseHelper>(),
      );
    }
    _loadPlaylists();
    _checkTrimStatus();
  }

  @override
  void dispose() {
    _newPlaylistController.dispose();
    super.dispose();
  }

  Future<void> _checkTrimStatus() async {
    if (widget.isTrimmed != null) {
      return;
    }
    if (widget.startWordId == null && widget.endWordId == null) {
      if (mounted) setState(() => _isTrimmed = false);
      return;
    }

    try {
      final db = widget.dbHelper ??
          (getIt.isRegistered<DatabaseHelper>()
              ? getIt<DatabaseHelper>()
              : null);
      if (db != null) {
        final lines = await db.getRange(widget.reference);
        final words = extractWordsFromLines(lines);
        if (words.isNotEmpty) {
          final minWordId = words.first.wordId;
          final maxWordId = words.last.wordId;
          final trimmed = (widget.startWordId != null &&
                  widget.startWordId != minWordId) ||
              (widget.endWordId != null && widget.endWordId != maxWordId);
          if (mounted) {
            setState(() {
              _isTrimmed = trimmed;
            });
          }
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isTrimmed = widget.startWordId != null || widget.endWordId != null;
      });
    }
  }

  Future<void> _loadPlaylists() async {
    if (_playlistService == null) {
      if (mounted) {
        setState(() {
          _playlists = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final list = await _playlistService!.getPlaylists();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (mounted) {
        setState(() {
          _playlists = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _playlists = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToPlaylist(Playlist playlist) async {
    if (_playlistService == null) return;

    final newItem = PlaylistItem.reference(
      reference: widget.reference,
      startWordId: _isTrimmed ? widget.startWordId : null,
      endWordId: _isTrimmed ? widget.endWordId : null,
      orderIndex: playlist.items.length,
    );
    final updatedPlaylist = playlist.copyWith(
      items: [...playlist.items, newItem],
      updatedAt: DateTime.now(),
    );
    await _playlistService!.savePlaylist(updatedPlaylist);

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Added to "${playlist.title}"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _createAndAddToPlaylist() async {
    final title = _newPlaylistController.text.trim();
    if (title.isEmpty) return;

    final newPlaylist = Playlist(
      title: title,
      items: [
        PlaylistItem.reference(
          reference: widget.reference,
          startWordId: _isTrimmed ? widget.startWordId : null,
          endWordId: _isTrimmed ? widget.endWordId : null,
          orderIndex: 0,
        ),
      ],
    );

    if (_playlistService != null) {
      await _playlistService!.savePlaylist(newPlaylist);
    }

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Added to "$title"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset + 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.playlist_add, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add to Playlist',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              widget.reference.toString(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (_isTrimmed) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
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
                        if (_isTrimmed &&
                            widget.selectedText != null &&
                            widget.selectedText!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '"${widget.selectedText!.trim()}"',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_isCreating)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newPlaylistController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Playlist title',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _createAndAddToPlaylist(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Cancel',
                      onPressed: () {
                        setState(() {
                          _isCreating = false;
                          _newPlaylistController.clear();
                        });
                      },
                    ),
                    FilledButton(
                      onPressed: _createAndAddToPlaylist,
                      child: const Text('Create'),
                    ),
                  ],
                ),
              )
            else
              ListTile(
                leading: Icon(Icons.add, color: theme.colorScheme.primary),
                title: Text(
                  'Create New Playlist',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _isCreating = true;
                  });
                },
              ),
            const Divider(height: 1),
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _playlists.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'No playlists yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = _playlists[index];
                            final passageCount = playlist.passageCount;
                            return ListTile(
                              leading:
                                  const Icon(Icons.playlist_play_rounded),
                              title: Text(
                                playlist.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                passageCount == 1
                                    ? '1 passage'
                                    : '$passageCount passages',
                              ),
                              onTap: () => _addToPlaylist(playlist),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
