import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ChapterChooser extends LeafRenderObjectWidget {
  const ChapterChooser({
    super.key,
    required this.chapterCount,
    this.onChapterSelected,
  });

  final int chapterCount;

  /// Called when a chapter is selected.
  ///
  /// A null value indicates that the selection was canceled.
  final void Function(int? chapter)? onChapterSelected;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final theme = Theme.of(context);
    return _RenderChapterChooser(
      chapterCount: chapterCount,
      onChapterSelected: onChapterSelected,
      textStyle: DefaultTextStyle.of(context).style,
      gridColor: theme.colorScheme.surfaceContainerHighest,
      gridHighlightColor: theme.colorScheme.secondary,
      textColor: theme.colorScheme.onSurface,
      highlightTextColor: theme.colorScheme.onSecondary,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    final theme = Theme.of(context);
    (renderObject as _RenderChapterChooser)
      ..chapterCount = chapterCount
      ..onChapterSelected = onChapterSelected
      ..textStyle = DefaultTextStyle.of(context).style
      ..gridColor = theme.colorScheme.surfaceContainerHighest
      ..gridHighlightColor = theme.colorScheme.secondary
      ..textColor = theme.colorScheme.onSurface
      ..highlightTextColor = theme.colorScheme.onSecondary;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('chapterCount', chapterCount));
  }
}

class _RenderChapterChooser extends RenderBox {
  _RenderChapterChooser({
    required int chapterCount,
    void Function(int? chapter)? onChapterSelected,
    required TextStyle textStyle,
    required Color gridColor,
    required Color gridHighlightColor,
    required Color textColor,
    required Color highlightTextColor,
  })  : _chapterCount = chapterCount,
        _onChapterSelected = onChapterSelected,
        _textStyle = textStyle,
        _gridColor = gridColor,
        _gridHighlightColor = gridHighlightColor,
        _textColor = textColor,
        _highlightTextColor = highlightTextColor {
    _gridPaint.color = gridColor;
    _highlightPaint.color = gridHighlightColor;
  }

  final _backgroundPaint = Paint()..color = const Color(0xCC000000);
  final _gridPaint = Paint();
  final _highlightPaint = Paint();

  int? _highlightedChapter;

  int get chapterCount => _chapterCount;
  int _chapterCount;
  set chapterCount(int value) {
    if (_chapterCount == value) return;
    _chapterCount = value;
    markNeedsLayout();
  }

  void Function(int? chapter)? get onChapterSelected => _onChapterSelected;
  void Function(int? chapter)? _onChapterSelected;
  set onChapterSelected(void Function(int? chapter)? value) {
    if (_onChapterSelected == value) return;
    _onChapterSelected = value;
  }

  TextStyle get textStyle => _textStyle;
  TextStyle _textStyle;
  set textStyle(TextStyle value) {
    if (_textStyle == value) return;
    _textStyle = value;
    markNeedsPaint();
  }

  Color get gridColor => _gridColor;
  Color _gridColor;
  set gridColor(Color value) {
    if (_gridColor == value) return;
    _gridColor = value;
    _gridPaint.color = value;
    markNeedsPaint();
  }

  Color get gridHighlightColor => _gridHighlightColor;
  Color _gridHighlightColor;
  set gridHighlightColor(Color value) {
    if (_gridHighlightColor == value) return;
    _gridHighlightColor = value;
    _highlightPaint.color = value;
    markNeedsPaint();
  }

  Color get textColor => _textColor;
  Color _textColor;
  set textColor(Color value) {
    if (_textColor == value) return;
    _textColor = value;
    markNeedsPaint();
  }

  Color get highlightTextColor => _highlightTextColor;
  Color _highlightTextColor;
  set highlightTextColor(Color value) {
    if (_highlightTextColor == value) return;
    _highlightTextColor = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  Size _gridSize = Size.zero;
  Size _tileSize = Size.zero;
  int _rows = 0;
  int _columns = 0;
  static const _desiredTileWidth = 40.0;
  static const _desiredTileHeight = 40.0;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    _rows = (chapterCount / 10).ceil();
    _columns = chapterCount < 10 ? chapterCount : 10;
    final maxGridWidth = constraints.maxWidth * 0.9;
    final gridWidth = min(maxGridWidth, _columns * _desiredTileWidth);
    final tileWidth = gridWidth / _columns;
    final maxGridHeight = constraints.maxHeight * 0.9;
    final gridHeight = min(maxGridHeight, _rows * _desiredTileHeight);
    final tileHeight = gridHeight / _rows;
    final tileSide = min(tileWidth, tileHeight);
    _gridSize = Size(tileSide * _columns, tileSide * _rows);
    _tileSize = Size(tileSide, tileSide);

    final parentSize = Size(constraints.maxWidth, constraints.maxHeight);
    return constraints.constrain(parentSize);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  int? _getChapterAtPosition(Offset position) {
    final gridOffset = Offset(
      (size.width - _gridSize.width) / 2,
      (size.height - _gridSize.height) / 2,
    );

    final localPosition = position - gridOffset;
    if (!(Offset.zero & _gridSize).contains(localPosition)) {
      return null;
    }

    final col = (localPosition.dx / _tileSize.width).floor();
    final row = (localPosition.dy / _tileSize.height).floor();
    final chapter = row * _columns + col + 1;

    if (chapter <= chapterCount && chapter > 0) {
      return chapter;
    }
    return null;
  }

  void _updateHighlightedChapter(Offset position) {
    final newHighlight = _getChapterAtPosition(position);
    if (newHighlight != _highlightedChapter) {
      _highlightedChapter = newHighlight;
      markNeedsPaint();
    }
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent || event is PointerHoverEvent || event is PointerMoveEvent) {
      _updateHighlightedChapter(event.localPosition);
    } else if (event is PointerUpEvent) {
      final chapter = _getChapterAtPosition(event.localPosition);
      print('chapter: $chapter');
      onChapterSelected?.call(chapter);
      _highlightedChapter = null;
      markNeedsPaint();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => size.width;

  @override
  double computeMaxIntrinsicWidth(double height) => size.width;

  @override
  double computeMinIntrinsicHeight(double width) => size.height;

  @override
  double computeMaxIntrinsicHeight(double width) => size.height;

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.save();
    context.canvas.translate(offset.dx, offset.dy);

    // paint the fullscreen translucent dark background
    context.canvas.drawRect(Offset.zero & size, _backgroundPaint);

    // paint the grid background
    final gridOffset = Offset(
      (size.width - _gridSize.width) / 2,
      (size.height - _gridSize.height) / 2,
    );
    context.canvas.save();
    context.canvas.translate(gridOffset.dx, gridOffset.dy);
    final gridRect = Offset.zero & _gridSize;
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(gridRect, const Radius.circular(8)),
      _gridPaint,
    );

    // paint the grid items
    for (var row = 0; row < _rows; row++) {
      for (var col = 0; col < _columns; col++) {
        final index = row * _columns + col + 1;
        if (index <= chapterCount) {
          context.canvas.save();
          context.canvas.translate(
            col * _tileSize.width,
            row * _tileSize.height,
          );

          // Draw highlight if this is the highlighted chapter
          if (_highlightedChapter == index) {
            context.canvas.drawRRect(
              RRect.fromRectAndRadius(Offset.zero & _tileSize, const Radius.circular(4)),
              _highlightPaint,
            );
          }

          final textPainter = TextPainter(
            text: TextSpan(
              text: index.toString(),
              style: textStyle.copyWith(
                color: _highlightedChapter == index ? highlightTextColor : textColor,
              ),
            ),
            textDirection: TextDirection.ltr,
          );

          textPainter.layout();
          textPainter.paint(
            context.canvas,
            Offset(
              (_tileSize.width - textPainter.width) / 2,
              (_tileSize.height - textPainter.height) / 2,
            ),
          );
          context.canvas.restore();
        }
      }
    }
    context.canvas.restore();

    context.canvas.restore();
  }
}
