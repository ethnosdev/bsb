import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';

import '../ui/playlists/playlist_share_handler.dart';
import '../ui/tabs/tab_manager.dart';
import 'service_locator.dart';
import 'verse_counts.dart';

class DeepLinkHandler {
  DeepLinkHandler({
    AppLinks? appLinks,
    PlaylistShareHandler? playlistShareHandler,
    TabManager? tabManager,
  })  : _appLinks = appLinks ?? AppLinks(),
        _playlistShareHandler = playlistShareHandler ?? PlaylistShareHandler(),
        _tabManager = tabManager ?? getIt<TabManager>();

  final AppLinks _appLinks;
  final PlaylistShareHandler _playlistShareHandler;
  final TabManager _tabManager;
  StreamSubscription<Uri>? _sub;

  /// Initializes listening to incoming deep links.
  void init(BuildContext context) async {
    // Check initial link on app start
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null && context.mounted) {
        handleIncomingUri(context, initialUri);
      }
    } catch (e) {
      debugPrint('DeepLinkHandler: Error retrieving initial link: $e');
    }

    // Listen to incoming links while running
    _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen((uri) {
      if (context.mounted) {
        handleIncomingUri(context, uri);
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  /// Routes an incoming URI to the appropriate handler.
  Future<void> handleIncomingUri(BuildContext context, Uri uri) async {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();

    if (scheme == 'bsb') {
      if (host == 'bible') {
        _handleBibleUri(context, uri);
        return;
      }
      if (host == 'playlist') {
        await _playlistShareHandler.handlePlaylistUri(context, uri);
        return;
      }
    } else if (uri.isScheme('file') || uri.isScheme('content')) {
      await _playlistShareHandler.handleFileUri(context, uri);
      return;
    }
  }

  void _handleBibleUri(BuildContext context, Uri uri) {
    if (!context.mounted) return;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2 || segments.length > 3) {
      _showInvalidLinkError(context);
      return;
    }

    final bookId = int.tryParse(segments[0]);
    final chapter = int.tryParse(segments[1]);
    final verse = segments.length == 3 ? int.tryParse(segments[2]) : null;

    if (bookId == null || chapter == null || (segments.length == 3 && verse == null)) {
      _showInvalidLinkError(context);
      return;
    }

    // Validate book ID (1..66)
    if (bookId < 1 || bookId > 66) {
      _showInvalidLinkError(context);
      return;
    }

    // Validate chapter count for this book
    final maxChapters = bookIdToChapterCountMap[bookId] ?? 0;
    if (chapter < 1 || chapter > maxChapters) {
      _showInvalidLinkError(context);
      return;
    }

    // Validate verse count if verse was provided
    if (verse != null) {
      final maxVerses = chapterVerseCounts[bookId]?[chapter - 1] ?? 0;
      if (verse < 1 || verse > maxVerses) {
        _showInvalidLinkError(context);
        return;
      }
    }

    // Dismiss any open modal sheets, dialogs, or subpages back to root
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);

    // Open or switch to chapter tab, and scroll to verse
    _tabManager.openTab(bookId, chapter, null, verse);
  }

  void _showInvalidLinkError(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Invalid Bible link')),
    );
  }
}
