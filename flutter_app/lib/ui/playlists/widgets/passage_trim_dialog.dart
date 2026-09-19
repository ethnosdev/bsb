import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/ui/playlists/playlist_presentation_page.dart';
import 'package:bsb/ui/playlists/widgets/passage_trim_helper.dart';
import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

class PassageTrimResult {
  final int? startWordId;
  final int? endWordId;
  final Reference? adjustedReference;

  const PassageTrimResult({
    this.startWordId,
    this.endWordId,
    this.adjustedReference,
  });

  bool get isTrimmed => startWordId != null || endWordId != null;
}

/// A dedicated popup dialog providing ample vertical space for trimming a scripture passage
/// by dragging word selection handles.
class PassageTrimDialog extends StatefulWidget {
  final Reference reference;
  final List<UsfmLine> lines;
  final int? initialStartWordId;
  final int? initialEndWordId;

  const PassageTrimDialog({
    super.key,
    required this.reference,
    required this.lines,
    this.initialStartWordId,
    this.initialEndWordId,
  });

  static Future<PassageTrimResult?> show({
    required BuildContext context,
    required Reference reference,
    required List<UsfmLine> lines,
    int? initialStartWordId,
    int? initialEndWordId,
  }) {
    return showDialog<PassageTrimResult>(
      context: context,
      builder: (ctx) => PassageTrimDialog(
        reference: reference,
        lines: lines,
        initialStartWordId: initialStartWordId,
        initialEndWordId: initialEndWordId,
      ),
    );
  }

  @override
  State<PassageTrimDialog> createState() => _PassageTrimDialogState();
}

class _PassageTrimDialogState extends State<PassageTrimDialog> {
  late final List<ScriptureWordInfo> _allWords;
  late final List<UsfmLine> _cleanLines;
  late final ScriptureSelectionController _controller;

  late int _minWordId;
  late int _maxWordId;
  late int _currentStart;
  late int _currentEnd;
  late Reference _adjustedRef;

  @override
  void initState() {
    super.initState();
    _cleanLines = stripFootnotesFromLines(widget.lines);
    _allWords = extractWordsFromLines(widget.lines);

    if (_allWords.isNotEmpty) {
      _minWordId = _allWords.first.wordId;
      _maxWordId = _allWords.last.wordId;
      _currentStart = widget.initialStartWordId ?? _minWordId;
      _currentEnd = widget.initialEndWordId ?? _maxWordId;
    } else {
      _minWordId = 0;
      _maxWordId = 0;
      _currentStart = 0;
      _currentEnd = 0;
    }

    _adjustedRef = computeAdjustedReference(
      originalReference: widget.reference,
      startWordId: _currentStart,
      endWordId: _currentEnd,
      allWords: _allWords,
    );

    _controller = ScriptureSelectionController();
    if (_allWords.isNotEmpty) {
      _controller.selectRange(_currentStart, _currentEnd);
    }
    _controller.addListener(_handleSelectionChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleSelectionChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleSelectionChange() {
    if (_controller.hasSelection) {
      final start = _controller.startId!;
      final end = _controller.endId!;
      if (start != _currentStart || end != _currentEnd) {
        setState(() {
          _currentStart = start;
          _currentEnd = end;
          _adjustedRef = computeAdjustedReference(
            originalReference: widget.reference,
            startWordId: _currentStart,
            endWordId: _currentEnd,
            allWords: _allWords,
          );
        });
      }
    } else {
      // Avoid accidental deselection when touching text inside trim mode
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_controller.hasSelection && _allWords.isNotEmpty) {
          _controller.selectRange(_currentStart, _currentEnd);
        }
      });
    }
  }

  bool get _isTrimmed =>
      _allWords.isNotEmpty &&
      (_currentStart != _minWordId || _currentEnd != _maxWordId);

  void _resetTrim() {
    if (_allWords.isNotEmpty) {
      _controller.selectRange(_minWordId, _maxWordId);
    }
  }

  void _applyTrim() {
    if (!_isTrimmed) {
      Navigator.of(context).pop(const PassageTrimResult());
    } else {
      Navigator.of(context).pop(
        PassageTrimResult(
          startWordId: _currentStart,
          endWordId: _currentEnd,
          adjustedReference: _adjustedRef,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = (screenSize.width * 0.88).clamp(320.0, 720.0);
    final dialogHeight = (screenSize.height * 0.85).clamp(420.0, 800.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
          minWidth: 320,
          minHeight: 400,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.content_cut, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trim Scripture Passage',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _adjustedRef.toString(),
                              key: const ValueKey('trim_adjusted_ref'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_isTrimmed) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Trimmed',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Instructions
              Text(
                'Drag the start and end handles to set non-verse boundaries. Moving handles past an entire verse adjusts the scripture reference.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),

              // Interactive Scripture View with Selection Handles
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: UsfmWidget(
                        verseLines: _cleanLines,
                        selectionController: _controller,
                        showSelectionHandles: true,
                        showHeadings: false,
                        showVerseNumbers: true,
                        styleBuilder: (format) => UsfmParagraphStyle.usfmDefaults(
                          format: format == ParagraphFormat.p
                              ? ParagraphFormat.m
                              : format,
                          baseStyle: theme.textTheme.bodyLarge!.copyWith(
                            fontSize: 18.0,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  TextButton.icon(
                    key: const ValueKey('trim_reset_button'),
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Reset'),
                    onPressed: _allWords.isNotEmpty ? _resetTrim : null,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('trim_done_button'),
                    onPressed: _applyTrim,
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
