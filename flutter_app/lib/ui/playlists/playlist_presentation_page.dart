import 'dart:developer';

import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/playlists/widgets/passage_trim_helper.dart';
import 'package:bsb/ui/settings/settings_manager.dart';
import 'package:bsb/ui/settings/user_settings.dart';
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
  final Playlist playlist;
  final SettingsManager? settingsManager;

  const PlaylistPresentationPage({
    super.key,
    required this.playlist,
    this.settingsManager,
  });

  @override
  State<PlaylistPresentationPage> createState() => _PlaylistPresentationPageState();
}

class _PlaylistPresentationPageState extends State<PlaylistPresentationPage> {
  final _dbHelper = getIt<DatabaseHelper>();
  late final SettingsManager? _settingsManager;
  bool _isDistractionFree = false;

  final Map<String, List<UsfmLine>> _passageCache = {};
  final _selectionController = ScriptureSelectionController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _settingsManager = widget.settingsManager ??
        (getIt.isRegistered<UserSettings>() ? SettingsManager() : null);
    _loadPassages();
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
    _selectionController.dispose();
    if (_isDistractionFree) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  Future<void> _loadPassages() async {
    for (final item in widget.playlist.items) {
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
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentTextSize = _settingsManager?.textSize ?? 20.0;

    final isRed = getIt.isRegistered<AppState>()
        ? getIt<AppState>().wordsOfJesusInRedNotifier.value
        : false;
    final redColor = isDark ? const Color(0xFFFF8A80) : const Color(0xFFB71C1C);
    final topPadding = _maxTopInset + kToolbarHeight + 16.0;

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
                  title: Text(widget.playlist.title),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.fullscreen),
                      tooltip: 'Fullscreen mode',
                      onPressed: _toggleDistractionFree,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleDistractionFree,
          child: SafeArea(
            top: false,
            bottom: true,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : widget.playlist.items.isEmpty
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
                        itemCount: widget.playlist.items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 32),
                        itemBuilder: (context, index) {
                          final item = widget.playlist.items[index];
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
                      ),
          ),
        ),
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
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      fontSize: (textSize * 1.25).clamp(22.0, 36.0),
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleDistractionFree,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Passage Title (Left aligned, Large text)
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
              onTapWhitespace: _toggleDistractionFree,
              onWordTapped: (_) => _toggleDistractionFree(),
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
    final noteTitle = (item.noteTitle != null && item.noteTitle!.trim().isNotEmpty)
        ? item.noteTitle!.trim()
        : 'Note';
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      fontSize: (textSize * 1.25).clamp(22.0, 36.0),
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleDistractionFree,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Note Title (Left aligned, Large text)
          Text(
            noteTitle,
            textAlign: TextAlign.left,
            style: titleStyle,
          ),
          const SizedBox(height: 8),
          MarkdownBody(
            data: item.noteText ?? '',
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodyMedium?.copyWith(
                fontSize: textSize * 0.95,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
