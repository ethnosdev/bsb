import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/playlist_service.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PlaylistShareHandler {
  final PlaylistService? _playlistService;
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;

  PlaylistShareHandler({PlaylistService? playlistService})
      : _playlistService = playlistService ??
            (getIt.isRegistered<PlaylistService>()
                ? getIt<PlaylistService>()
                : null);

  static Rect? _getSharePositionOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    return null;
  }

  static String sanitizeFileName(String title) {
    return title.replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_');
  }

  // --- Compression & URL Encoding ---

  static String encodePlaylistToUrl(Playlist playlist) {
    final jsonStr = playlist.toJson();
    final bytes = utf8.encode(jsonStr);
    final compressed = zlib.encode(bytes);
    final base64Str = base64Url.encode(compressed);
    return 'bsb://playlist?data=$base64Str';
  }

  static Playlist? decodePlaylistFromUrl(String urlOrData) {
    try {
      String data = urlOrData.trim();
      final regex = RegExp(r'bsb://playlist\?data=([A-Za-z0-9_\-]+)');
      final match = regex.firstMatch(data);
      if (match != null) {
        data = match.group(1)!;
      } else if (data.startsWith('bsb://playlist')) {
        final uri = Uri.parse(data);
        data = uri.queryParameters['data'] ?? '';
      } else if (data.contains('data=')) {
        final dataMatch = RegExp(r'data=([A-Za-z0-9_\-]+)').firstMatch(data);
        if (dataMatch != null) {
          data = dataMatch.group(1)!;
        } else {
          final uri = Uri.tryParse(data);
          if (uri != null && uri.queryParameters.containsKey('data')) {
            data = uri.queryParameters['data']!;
          }
        }
      }

      if (data.isEmpty) return null;

      // Normalize base64Url padding
      var normalized = data.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }

      final compressed = base64.decode(normalized);
      final decompressed = zlib.decode(compressed);
      final jsonStr = utf8.decode(decompressed);
      return Playlist.fromJson(jsonStr);
    } catch (_) {
      // Fallback: Check if it is direct JSON
      try {
        return Playlist.fromJson(urlOrData);
      } catch (_) {
        return null;
      }
    }
  }

  // --- Export File ---

  Future<void> exportPlaylistFile(BuildContext context, Playlist playlist) async {
    final safeTitle = sanitizeFileName(playlist.title);
    final fileName = '$safeTitle.bsbplaylist';
    final jsonContent = playlist.toJson(pretty: true);

    final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;

    if (isDesktop) {
      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Export Playlist',
        fileName: fileName,
        bytes: utf8.encode(jsonContent),
        type: FileType.custom,
        allowedExtensions: ['bsbplaylist', 'json'],
      );

      if (savedUri != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved playlist to $fileName')),
        );
      }
    } else {
      final origin = _getSharePositionOrigin(context);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(jsonContent);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          subject: playlist.title,
          sharePositionOrigin: origin,
        ),
      );
    }
  }

  // --- Copy Share Code ---

  Future<void> copyShareCode(BuildContext context, Playlist playlist) async {
    final code = encodePlaylistToUrl(playlist);
    final text = 'BSB Playlist: ${playlist.title}\n'
        'To import in the BSB app, copy this message and select "Import from Clipboard" in the Playlists menu:\n'
        '$code';
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist share code copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @Deprecated('Use copyShareCode instead')
  Future<void> copyShareLink(BuildContext context, Playlist playlist) =>
      copyShareCode(context, playlist);

  // --- Import File ---

  Future<void> importPlaylistFromFile(BuildContext context) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['bsbplaylist', 'json'],
    );

    if (file == null) return;

    String content;
    try {
      final bytes = await file.readAsBytes();
      content = utf8.decode(bytes);
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Unable to read file: $e');
      }
      return;
    }

    Playlist playlist;
    try {
      playlist = Playlist.fromJson(content);
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'The file is not a valid BSB playlist.');
      }
      return;
    }

    if (!context.mounted) return;
    await _showImportConfirmationDialog(context, playlist);
  }

  // --- Import From Clipboard ---

  Future<void> importFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';

    if (text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty.')),
        );
      }
      return;
    }

    final playlist = decodePlaylistFromUrl(text);
    if (playlist == null) {
      if (context.mounted) {
        _showErrorDialog(
          context,
          'No valid BSB playlist link or data was found in your clipboard.',
        );
      }
      return;
    }

    if (!context.mounted) return;
    await _showImportConfirmationDialog(context, playlist);
  }

  // --- App Links (Deep link & File Association listener) ---

  void initDeepLinks(BuildContext context) async {
    _appLinks = AppLinks();

    // Check initial link on app start
    try {
      final initialUri = await _appLinks?.getInitialLink();
      if (initialUri != null && context.mounted) {
        _handleIncomingUri(context, initialUri);
      }
    } catch (_) {}

    // Listen to stream while running
    _sub?.cancel();
    _sub = _appLinks?.uriLinkStream.listen((uri) {
      if (context.mounted) {
        _handleIncomingUri(context, uri);
      }
    });
  }

  void dispose() {
    _sub?.cancel();
  }

  void _handleIncomingUri(BuildContext context, Uri uri) async {
    if (uri.scheme == 'bsb' && uri.host == 'playlist') {
      await handlePlaylistUri(context, uri);
    } else if (uri.isScheme('file') || uri.isScheme('content')) {
      await handleFileUri(context, uri);
    }
  }

  Future<void> handlePlaylistUri(BuildContext context, Uri uri) async {
    final playlist = decodePlaylistFromUrl(uri.toString());
    if (playlist != null && context.mounted) {
      await _showImportConfirmationDialog(context, playlist);
    }
  }

  Future<void> handleFileUri(BuildContext context, Uri uri) async {
    try {
      final file = File(uri.toFilePath());
      if (await file.exists()) {
        final content = await file.readAsString();
        final playlist = Playlist.fromJson(content);
        if (context.mounted) {
          await _showImportConfirmationDialog(context, playlist);
        }
      }
    } catch (_) {}
  }

  // --- Dialogs ---

  Future<void> _showImportConfirmationDialog(
    BuildContext context,
    Playlist playlist,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              playlist.title,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contains ${playlist.passageCount} passage${playlist.passageCount == 1 ? '' : 's'} and ${playlist.noteCount} note${playlist.noteCount == 1 ? '' : 's'}.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            const Text('Would you like to import this playlist into your collection?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed == true && _playlistService != null) {
      await _playlistService.savePlaylist(playlist);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported "${playlist.title}" successfully!'),
          ),
        );
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
