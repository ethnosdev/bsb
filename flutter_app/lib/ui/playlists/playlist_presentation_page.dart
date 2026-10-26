import 'dart:developer';

import 'package:bsb/app_state.dart';
import 'package:bsb/core/font_scale.dart';
import 'package:bsb/core/theme.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/playlist_service.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/playlists/playlist_editor_page.dart';
import 'package:bsb/ui/playlists/widgets/passage_trim_helper.dart';
import 'package:bsb/ui/shared/zoom_wrapper.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

/// Strips footnote markup and footnote lines from USFM lines so that footnote
/// markers are not rendered during presentation.
List<UsfmLine> stripFootnotesFromLines(List<UsfmLine> lines) {
  final footnoteRegex =
      RegExp(r'\\[fx]e?\s*[+-]?\s*.*?(?:\\[fx]e?\*|$)', dotAll: true);

  return lines
      .where((line) => line.format != ParagraphFormat.r)
      .map((line) {
        final strippedText = line.text.replaceAllMapped(footnoteRegex, (match) {
          if (match.end < match.input.length &&
              RegExp(r'[a-zA-Z]').hasMatch(match.input[match.end])) {
            return ' ';
          }
          return '';
        });
        return UsfmLine(
          bookChapterVerse: line.bookChapterVerse,
          text: strippedText,
          format: line.format,
        );
      })
      .where((line) => line.format == ParagraphFormat.b || line.text.trim().isNotEmpty)
      .toList();
}

class PlaylistPresentationPage extends StatefulWidget {
  final Playlist? playlist;
  final String? playlistId;
  final AppState? appState;
  final bool embedded;
  final bool isDistractionFree;
  final VoidCallback? onToggleDistractionFree;

  const PlaylistPresentationPage({
    super.key,
    this.playlist,
    this.playlistId,
    this.appState,
    this.embedded = false,
    this.isDistractionFree = false,
    this.onToggleDistractionFree,
  }) : assert(playlist != null || playlistId != null);

  @override
  State<PlaylistPresentationPage> createState() => _PlaylistPresentationPageState();
}

class _PlaylistPresentationPageState extends State<PlaylistPresentationPage> {
  final _dbHelper = getIt<DatabaseHelper>();
  late final AppState? _appState;
  Playlist? _playlist;
  bool _isDistractionFree = false;

  final Map<String, List<UsfmLine>> _passageCache = {};
  final _selectionController = ScriptureSelectionController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
    _appState = widget.appState ??
        (getIt.isRegistered<AppState>() ? getIt<AppState>() : null);
    if (getIt.isRegistered<PlaylistService>()) {
      getIt<PlaylistService>().changeNotifier.addListener(_onPlaylistServiceChanged);
    }
    _initPlaylist();
  }

  Future<void> _initPlaylist() async {
    if (widget.playlist != null) {
      _playlist = widget.playlist;
      await _loadPassages();
    } else if (widget.playlistId != null && getIt.isRegistered<PlaylistService>()) {
      final p = await getIt<PlaylistService>().getPlaylist(widget.playlistId!);
      if (mounted) {
        setState(() {
          _playlist = p;
        });
        if (p != null) {
          await _loadPassages();
        } else {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _onPlaylistServiceChanged() async {
    final id = _playlist?.id ?? widget.playlistId ?? widget.playlist?.id;
    if (id != null && getIt.isRegistered<PlaylistService>()) {
      final updated = await getIt<PlaylistService>().getPlaylist(id);
      if (updated != null && mounted) {
        setState(() {
          _playlist = updated;
          _passageCache.clear();
          _isLoading = true;
        });
        await _loadPassages();
      }
    }
  }

  @override
  void didUpdateWidget(covariant PlaylistPresentationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playlist != oldWidget.playlist ||
        widget.playlistId != oldWidget.playlistId) {
      _passageCache.clear();
      _isLoading = true;
      _initPlaylist();
    }
  }

  double _maxTopInset = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final topInset = MediaQuery.paddingOf(context).top;
    if (topInset > _maxTopInset) {
      _maxTopInset = topInset;
    }
  }

  @override
  void dispose() {
    if (getIt.isRegistered<PlaylistService>()) {
      getIt<PlaylistService>().changeNotifier.removeListener(_onPlaylistServiceChanged);
    }
    _selectionController.dispose();
    if (!widget.embedded && _isDistractionFree) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  Future<void> _loadPassages() async {
    final currentPlaylist = _playlist;
    if (currentPlaylist == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    for (final item in currentPlaylist.items) {
      if (item.isReference && item.reference != null) {
        try {
          final lines = await _dbHelper.getRange(item.reference!);
          final trimmedLines = trimPassageLines(lines, item.startWordId, item.endWordId);
          _passageCache[item.id] = stripFootnotesFromLines(trimmedLines);
        } catch (e) {
          log('Error loading passage for ${item.reference}: $e');
        }
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openEditor() async {
    if (_playlist == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistEditorPage(playlist: _playlist!),
      ),
    );
    if (!mounted) return;
    if (getIt.isRegistered<PlaylistService>()) {
      final updated = await getIt<PlaylistService>().getPlaylist(_playlist!.id);
      if (updated != null && mounted) {
        setState(() {
          _playlist = updated;
          _passageCache.clear();
          _isLoading = true;
        });
        await _loadPassages();
      }
    }
  }

  void _toggleDistractionFree() {
    setState(() {
      _isDistractionFree = !_isDistractionFree;
    });
    if (_isDistractionFree) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _exitDistractionFree() {
    setState(() {
      _isDistractionFree = false;
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _openInBibleTab(Reference ref) {
    if (getIt.isRegistered<TabManager>()) {
      getIt<TabManager>().openTab(
        ref.bookId,
        ref.chapter,
        null,
        ref.verse,
      );
      if (!widget.embedded) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = _appState;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultRed =
        isDark ? const Color(0xFFFF8A80) : const Color(0xFFB71C1C);
    final redColor = theme.extension<ScriptureTheme>()?.wordsOfJesusColor ??
        (appState?.getWordsOfJesusColor(theme.brightness) ?? defaultRed);
    final topPadding = _maxTopInset + kToolbarHeight + 16.0;
    final double baseTextSize =
        appState?.textSizeNotifier.value ?? FontScale.defaultBaseSize;
    final bool defaultIsRed =
        appState?.wordsOfJesusInRedNotifier.value ?? false;

    Widget buildContent(double currentTextSize, bool isRed) {
      if (_isLoading || _playlist == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = _playlist!.items;
      return items.isEmpty
          ? Center(
              child: Text(
                'No passages or notes in this playlist yet.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: topPadding,
                bottom: 40,
              ),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 32),
              itemBuilder: (context, index) {
                final item = items[index];
                if (item.isReference) {
                  return _buildPassageView(
                    context: context,
                    item: item,
                    textSize: currentTextSize,
                    isRed: isRed,
                    redColor: redColor,
                  );
                } else {
                  return _buildNoteView(context, item, currentTextSize);
                }
              },
            );
    }

    Widget contentBody;
    if (appState != null) {
      contentBody = ValueListenableBuilder<double>(
        valueListenable: appState.textSizeNotifier,
        builder: (context, currentSize, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: appState.wordsOfJesusInRedNotifier,
            builder: (context, isRed, _) {
              return ZoomWrapper(
                initialScale: currentSize,
                minScale: FontScale.minBaseSize,
                maxScale: FontScale.maxBaseSize,
                onScaleChanged: (newScale) {
                  appState.setTextSize(newScale);
                },
                builder: (context, scale) => buildContent(scale, isRed),
              );
            },
          );
        },
      );
    } else {
      contentBody = buildContent(baseTextSize, defaultIsRed);
    }

    final bodyContent = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.embedded
          ? widget.onToggleDistractionFree
          : _toggleDistractionFree,
      child: SafeArea(
        top: false,
        bottom: true,
        child: contentBody,
      ),
    );

    if (widget.embedded) {
      return bodyContent;
    }

    return PopScope(
      canPop: !_isDistractionFree,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isDistractionFree) {
          _exitDistractionFree();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AnimatedSlide(
            offset: _isDistractionFree ? const Offset(0, -1) : Offset.zero,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: _isDistractionFree ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: _isDistractionFree,
                child: AppBar(
                  title: Text(_playlist?.title ?? ''),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit playlist',
                      onPressed: _openEditor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: bodyContent,
      ),
    );
  }

  Widget _buildPassageView({
    required BuildContext context,
    required PlaylistItem item,
    required double textSize,
    required bool isRed,
    required Color redColor,
  }) {
    final theme = Theme.of(context);
    final ref = item.reference!;
    final lines = _passageCache[item.id] ?? [];
    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: textSize,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );

    final VoidCallback? toggleDistraction = widget.embedded
        ? widget.onToggleDistractionFree
        : _toggleDistractionFree;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: toggleDistraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Passage Title (Left aligned)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  ref.toString(),
                  textAlign: TextAlign.left,
                  style: titleStyle,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                tooltip: 'Open in Bible Reader tab',
                onPressed: () => _openInBibleTab(ref),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Scripture Text
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Unable to load scripture for $ref',
                style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            )
          else
            UsfmWidget(
              verseLines: lines,
              selectionController: _selectionController,
              showSelectionHandles: false,
              showHeadings: false,
              showVerseNumbers: true,
              onTapWhitespace: toggleDistraction,
              onWordTapped: (_) => toggleDistraction?.call(),
              styleBuilder: (format) {
                final base = UsfmParagraphStyle.usfmDefaults(
                  format: format == ParagraphFormat.p ? ParagraphFormat.m : format,
                  baseStyle: theme.textTheme.bodyMedium!.copyWith(
                    fontSize: textSize,
                    height: 1.5,
                  ),
                );
                if (isRed) {
                  return base.copyWith(
                    wordsOfJesusStyle: base.textStyle.copyWith(color: redColor),
                  );
                }
                return base;
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNoteView(BuildContext context, PlaylistItem item, double textSize) {
    final theme = Theme.of(context);
    final hasTitle = item.noteTitle != null && item.noteTitle!.trim().isNotEmpty;
    final noteTitle = hasTitle ? item.noteTitle!.trim() : null;
    final noteColor = theme.colorScheme.primary;
    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: textSize,
      fontWeight: FontWeight.bold,
      color: noteColor,
    );

    final VoidCallback? toggleDistraction = widget.embedded
        ? widget.onToggleDistractionFree
        : _toggleDistractionFree;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: toggleDistraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Note Title (Left aligned)
          if (noteTitle != null) ...[
            Text(
              noteTitle,
              textAlign: TextAlign.left,
              style: titleStyle,
            ),
            const SizedBox(height: 8),
          ],
          MarkdownBody(
            data: item.noteText ?? '',
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodyMedium?.copyWith(
                fontSize: textSize * 0.95,
                height: 1.5,
                color: noteColor,
              ),
              pPadding: EdgeInsets.zero,
              h1: theme.textTheme.headlineLarge?.copyWith(color: noteColor),
              h2: theme.textTheme.headlineMedium?.copyWith(color: noteColor),
              h3: theme.textTheme.headlineSmall?.copyWith(color: noteColor),
              h4: theme.textTheme.titleLarge?.copyWith(color: noteColor),
              h5: theme.textTheme.titleMedium?.copyWith(color: noteColor),
              h6: theme.textTheme.titleSmall?.copyWith(color: noteColor),
              em: TextStyle(color: noteColor, fontStyle: FontStyle.italic),
              strong: TextStyle(color: noteColor, fontWeight: FontWeight.bold),
              blockquote: theme.textTheme.bodyMedium?.copyWith(
                fontSize: textSize * 0.95,
                color: noteColor,
              ),
              listBullet: theme.textTheme.bodyMedium?.copyWith(
                color: noteColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
