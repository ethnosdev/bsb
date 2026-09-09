import 'dart:developer';

import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/text/annotation_disambiguation_sheet.dart';
import 'package:bsb/ui/text/chapter/chapter_manager.dart';
import 'package:bsb/ui/text/note_editor_sheet.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

class ChapterText extends StatefulWidget {
  const ChapterText({
    super.key,
    required this.bookId,
    required this.chapter,
    this.targetSection,
    this.targetVerse,
    this.onSelectionChanged,
    this.onTargetSectionScrolled,
    this.onTargetVerseScrolled,
  });

  final int bookId;
  final int chapter;
  final String? targetSection;
  final int? targetVerse;
  final void Function(ScriptureSelectionController controller)?
  onSelectionChanged;
  final VoidCallback? onTargetSectionScrolled;
  final VoidCallback? onTargetVerseScrolled;

  @override
  State<ChapterText> createState() => _ChapterTextState();
}

class _ChapterTextState extends State<ChapterText>
    with AutomaticKeepAliveClientMixin {
  final manager = ChapterManager();
  final _selectionController = ScriptureSelectionController();
  final _scrollController = ScrollController();
  String? _lastScrolledSection;
  int? _lastScrolledVerse;
  String? _activeTargetSection;
  int? _activeTargetVerse;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    manager.requestText(bookId: widget.bookId, chapter: widget.chapter);
    _selectionController.addListener(_handleSelectionChange);
    if (widget.targetSection != null) {
      _scrollToTargetSection(widget.targetSection);
    }
    if (widget.targetVerse != null) {
      _scrollToTargetVerse(widget.targetVerse);
    }
  }

  @override
  void didUpdateWidget(covariant ChapterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetSection != null &&
        (widget.targetSection != oldWidget.targetSection ||
            widget.targetSection != _lastScrolledSection)) {
      _scrollToTargetSection(widget.targetSection);
    }
    if (widget.targetVerse != null &&
        (widget.targetVerse != oldWidget.targetVerse ||
            widget.targetVerse != _lastScrolledVerse)) {
      _scrollToTargetVerse(widget.targetVerse);
    }
  }

  @override
  void dispose() {
    _selectionController.removeListener(_handleSelectionChange);
    _selectionController.dispose();
    _scrollController.dispose();
    manager.dispose();
    super.dispose();
  }

  void _handleSelectionChange() {
    if (mounted && widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(_selectionController);
    }
  }

  void _scrollToTargetSection([String? section, int attempt = 0]) {
    final target = section ?? widget.targetSection;
    if (target == null || target.isEmpty) return;
    if (target == _lastScrolledSection) return;
    if (attempt == 0 && target == _activeTargetSection) return;

    _activeTargetSection = target;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _activeTargetSection = null;
        return;
      }
      final success = _performScrollToSection(target);
      if (success) {
        _lastScrolledSection = target;
        _activeTargetSection = null;
        widget.onTargetSectionScrolled?.call();
      } else if (attempt < 15) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && widget.targetSection == target) {
            _scrollToTargetSection(target, attempt + 1);
          } else {
            _activeTargetSection = null;
          }
        });
      } else {
        _activeTargetSection = null;
      }
    });
  }

  bool _performScrollToSection(String target) {
    if (!_scrollController.hasClients) return false;
    if (!_scrollController.position.hasContentDimensions) return false;

    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return false;

    RenderPassage? passage;
    void findPassage(RenderObject ro) {
      if (passage != null) return;
      if (ro is RenderPassage) {
        passage = ro;
        return;
      }
      ro.visitChildren(findPassage);
    }
    findPassage(renderObject);

    if (passage == null || !passage!.hasSize) return false;

    RenderBox? child = passage!.firstChild;
    while (child != null) {
      if (child is RenderParagraph) {
        final text = _getParagraphText(child);
        if (_matchesHeading(text, target)) {
          final parentData = child.parentData as PassageParentData;
          final targetOffset = parentData.offset.dy;
          final maxScroll = _scrollController.position.maxScrollExtent;
          if (targetOffset > 50.0 && maxScroll <= 0.0) {
            return false;
          }
          final scrollOffset = (16.0 + targetOffset).clamp(0.0, maxScroll);
          _scrollController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
          return true;
        }
      }
      child = (child.parentData as PassageParentData).nextSibling;
    }
    return false;
  }

  void _scrollToTargetVerse([int? verse, int attempt = 0]) {
    final target = verse ?? widget.targetVerse;
    if (target == null || target <= 0) return;
    if (target == _lastScrolledVerse) return;
    if (attempt == 0 && target == _activeTargetVerse) return;

    _activeTargetVerse = target;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _activeTargetVerse = null;
        return;
      }
      final success = _performScrollToVerse(target);
      if (success) {
        _lastScrolledVerse = target;
        _activeTargetVerse = null;
        widget.onTargetVerseScrolled?.call();
      } else if (attempt < 15) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && widget.targetVerse == target) {
            _scrollToTargetVerse(target, attempt + 1);
          } else {
            _activeTargetVerse = null;
          }
        });
      } else {
        _activeTargetVerse = null;
      }
    });
  }

  bool _performScrollToVerse(int targetVerse) {
    if (!_scrollController.hasClients) return false;
    if (!_scrollController.position.hasContentDimensions) return false;

    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return false;

    RenderPassage? passage;
    void findPassage(RenderObject ro) {
      if (passage != null) return;
      if (ro is RenderPassage) {
        passage = ro;
        return;
      }
      ro.visitChildren(findPassage);
    }
    findPassage(renderObject);

    if (passage == null || !passage!.hasSize) return false;

    final targetVerseStr = targetVerse.toString();
    final expectedPackedRef =
        widget.bookId * 1000000 + widget.chapter * 1000 + targetVerse;

    RenderBox? child = passage!.firstChild;
    while (child != null) {
      if (child is RenderParagraph) {
        bool matches = false;
        void checkParagraph(RenderObject ro) {
          if (matches) return;
          if (ro is RenderVerseNumber && ro.number == targetVerseStr) {
            matches = true;
            return;
          }
          if (ro is RenderWord) {
            if (ro.id ~/ 1000 == expectedPackedRef) {
              matches = true;
              return;
            }
          }
          ro.visitChildren(checkParagraph);
        }
        checkParagraph(child);

        if (matches) {
          final parentData = child.parentData as PassageParentData;
          final targetOffset = parentData.offset.dy;
          final maxScroll = _scrollController.position.maxScrollExtent;
          if (targetOffset > 50.0 && maxScroll <= 0.0) {
            return false;
          }
          final scrollOffset = (16.0 + targetOffset).clamp(0.0, maxScroll);
          _scrollController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
          return true;
        }
      }
      child = (child.parentData as PassageParentData).nextSibling;
    }
    return false;
  }

  String _getParagraphText(RenderBox p) {
    final words = <String>[];
    void collectWords(RenderObject ro) {
      if (ro is RenderWord) {
        words.add(ro.text);
        return;
      }
      ro.visitChildren(collectWords);
    }
    collectWords(p);
    return words.join(' ');
  }

  bool _matchesHeading(String text, String target) {
    final cleanText = text
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    final cleanTarget = target
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    if (cleanText.isEmpty || cleanTarget.isEmpty) return false;
    return cleanText == cleanTarget ||
        cleanText.startsWith(cleanTarget) ||
        cleanTarget.startsWith(cleanText);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final brightness = Theme.of(context).brightness;
    final textSizeListenable = getIt.isRegistered<AppState>()
        ? getIt<AppState>().textSizeNotifier
        : ValueNotifier<double>(manager.textSize);

    return ValueListenableBuilder<double>(
      valueListenable: textSizeListenable,
      builder: (context, currentTextSize, child) {
        return ValueListenableBuilder<List<UsfmLine>>(
          valueListenable: manager.textParagraphNotifier,
          builder: (context, verseLines, child) {
            if (verseLines.isNotEmpty &&
                widget.targetSection != null &&
                _lastScrolledSection != widget.targetSection) {
              _scrollToTargetSection(widget.targetSection);
            }
            if (verseLines.isNotEmpty &&
                widget.targetVerse != null &&
                _lastScrolledVerse != widget.targetVerse) {
              _scrollToTargetVerse(widget.targetVerse);
            }
            return ValueListenableBuilder<List<Highlight>>(
              valueListenable: manager.highlightsNotifier,
              builder: (context, rawHighlights, child) {
                final highlights = rawHighlights
                    .map((h) => h.toHighlightRange(brightness))
                    .toList();
                return ValueListenableBuilder<List<NoteMarker>>(
                  valueListenable: manager.noteMarkersNotifier,
                  builder: (context, noteMarkers, child) {
                    return SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16.0,
                          top: 16.0,
                          right: 16.0,
                          bottom: screenHeight * 0.8,
                        ),
                        child: UsfmWidget(
                          verseLines: verseLines,
                          selectionController: _selectionController,
                          highlights: highlights,
                          noteMarkers: noteMarkers,
                          onFootnoteTapped: _onFootnoteTapped,
                          onNoteTapped: _onNoteTapped,
                          onAmbiguousTapped: _onAmbiguousTapped,
                          onWordTapped: (id) => log("Tapped word $id"),
                          onSelectionRequested: (wordId) {
                            ScriptureLogic.highlightVerse(
                              _selectionController,
                              verseLines,
                              wordId,
                            );
                          },
                          styleBuilder: (format) {
                            return UsfmParagraphStyle.usfmDefaults(
                              format: format == ParagraphFormat.p
                                  ? ParagraphFormat.m
                                  : format,
                              baseStyle: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(fontSize: currentTextSize),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _onAmbiguousTapped({
    required int wordId,
    required String footnoteText,
    required String noteId,
  }) async {
    final note = await manager.getNoteById(noteId);
    final ref = Reference.fromWordId(packedInt: wordId);

    if (!mounted) return;

    await AnnotationDisambiguationSheet.show(
      context: context,
      title: ref.toString(),
      notePreview: note?.content ?? '',
      footnotePreview:
          footnoteText.replaceAll(RegExp(r'\\[a-z0-9*]+'), '').trim(),
      onSelectNote: () => _onNoteTapped(noteId),
      onSelectFootnote: () => _onFootnoteTapped(footnoteText),
    );
  }

  Future<void> _onNoteTapped(String noteId) async {
    final note = await manager.getNoteById(noteId);
    if (note == null || !mounted) return;

    final ref = Reference.fromWordId(
      packedInt: note.startWordId,
      packedIntEnd: note.endWordId,
    );

    await NoteEditorSheet.show(
      context: context,
      title: ref.toString(),
      initialContent: note.content,
      isExisting: true,
      onSave: (newContent) {
        manager.saveNote(
          bookId: note.bookId,
          chapter: note.chapter,
          startWordId: note.startWordId,
          endWordId: note.endWordId,
          content: newContent,
          existingNoteId: note.id,
        );
      },
      onDelete: () {
        manager.deleteNote(note.id);
      },
    );
  }

  void _onFootnoteTapped(String footnoteText) {
    final details = formatFootnote(
      footnote: footnoteText,
      highlightColor: Theme.of(context).colorScheme.primary,
      keywords: manager.footnoteKeywords(),
      onTapKeyword: (keyword, count) async {
        if (count == 1) {
          Navigator.of(context).pop();
        }
        final text = await manager.lookupFootnoteDetails(keyword);
        if (text == null) return;
        _showDetailsDialog(keyword, text);
      },
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SelectableText.rich(
          details,
          style: TextStyle(fontSize: manager.textSize),
        ),
      ),
    );
  }

  Future<void> _showDetailsDialog(String title, List<UsfmLine> passage) async {
    final fontSize = manager.textSize;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            constraints: const BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: UsfmWidget(
                      verseLines: passage,
                      selectionController: ScriptureSelectionController(),
                      selectionColor: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.3),
                      onFootnoteTapped: _onFootnoteTapped,
                      styleBuilder: (format) {
                        return UsfmParagraphStyle.usfmDefaults(
                          format: format == ParagraphFormat.p
                              ? ParagraphFormat.m
                              : format,
                          baseStyle: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(fontSize: manager.textSize),
                        );
                      },
                      showHeadings: false,
                      showVerseNumbers: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

TextSpan formatFootnote({
  required String footnote,
  required Color highlightColor,
  required RegExp keywords,
  required void Function(String tappedKeyword, int keywordCount) onTapKeyword,
}) {
  // Make semicolon-separated content display on new lines
  final note = footnote.replaceAll('; ', ';\n');

  final List<TextSpan> spans = [];
  int start = 0;
  bool isItalic = false;

  // Match \fqa* first (without trailing spaces), then \fqa (with trailing space separator), then keywords
  final tagOrKeywordPattern = RegExp(
    r'(\\fqa\*)|(\\fqa)\s*|' + keywords.pattern,
  );
  final matches = tagOrKeywordPattern.allMatches(note);

  for (final match in matches) {
    // Add text before the match
    if (match.start > start) {
      final text = note.substring(start, match.start);
      if (text.isNotEmpty) {
        spans.add(
          TextSpan(
            text: text,
            style: isItalic
                ? const TextStyle(fontStyle: FontStyle.italic)
                : null,
          ),
        );
      }
    }

    final isFqaClose = match.group(1) != null;
    final isFqaOpen = match.group(2) != null;
    final matchedText = match.group(0)!;

    if (isFqaClose) {
      isItalic = false;
    } else if (isFqaOpen) {
      isItalic = true;
    } else {
      // Add the matched keyword as a tappable span
      spans.add(
        TextSpan(
          text: matchedText,
          style: TextStyle(
            color: highlightColor,
            fontStyle: isItalic ? FontStyle.italic : null,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              onTapKeyword(matchedText, matches.length);
            },
        ),
      );
    }

    start = match.end;
  }

  // Add remaining text after the last match
  if (start < note.length) {
    final text = note.substring(start);
    if (text.isNotEmpty) {
      spans.add(
        TextSpan(
          text: text,
          style: isItalic ? const TextStyle(fontStyle: FontStyle.italic) : null,
        ),
      );
    }
  }

  return TextSpan(children: spans);
}
