import 'dart:ui';
import 'package:bsb/infrastructure/verse_line.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Text layout for chapter of scripture
class ScriptureLayout extends LeafRenderObjectWidget {
  const ScriptureLayout({super.key, required this.lines});

  /// The lines will be rendered in order
  final List<VerseLine> lines;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderUsfmLayout(lines: lines);
  }

  @override
  void updateRenderObject(BuildContext context, RenderUsfmLayout renderObject) {
    renderObject.lines = lines;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<VerseLine>('lines', lines));
  }
}

class RenderUsfmLayout extends RenderBox {
  RenderUsfmLayout({
    required List<VerseLine> lines,
  }) : _lines = lines;

  List<VerseLine> get lines => _lines;
  List<VerseLine> _lines;
  set lines(List<VerseLine> value) {
    if (_lines == value) return;
    _lines = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    _parseText();
    final desiredWidth = constraints.maxWidth;
    const desiredHeight = 1000.0; // temp value
    final desiredSize = Size(desiredWidth, desiredHeight);
    return constraints.constrain(desiredSize);
  }

  List<_Word>? _chunks;

  // Take the words from `lines` and put them in one-word unstyled chunks.
  void _parseText() {
    if (_chunks != null) return;
    _chunks = [];
    for (final line in _lines) {
      final text = line.text;
      final words = text.split(RegExp(r'(?<= )'));
      for (final word in words) {
        _chunks!.add(_Word(word: word));
      }
    }

    TextPainter painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: const TextSpan(
        text: 'Hello World',
        style: TextStyle(
          fontSize: 20.0,
          color: Color(0xFF000000),
        ),
      ),
    );

    painter.layout(maxWidth: constraints.maxWidth);
    final metrics = painter.computeLineMetrics();
    for (final LineMetrics metric in metrics) {
      print('Text on line: ${painter.getPositionForOffset(Offset(0, metric.baseline)).offset}');
    }
  }

  // Take the one-word chunks and create styled paragraphs that are measured.
  void _measureWords() {}

  // Take the styled paragraphs and give them an offset to paint at.
  void _layout() {}

  // TODO: this should be the width of the longest word.
  @override
  double computeMinIntrinsicWidth(double height) => 10.0;

  // TODO: this should be the width of the longest line.
  @override
  double computeMaxIntrinsicWidth(double height) => 1000.0;

  // TODO: this should be the measured height given the width constraint.
  @override
  double computeMinIntrinsicHeight(double width) => 10.0;

  // TODO: same as minIntrinsicHeight.
  @override
  double computeMaxIntrinsicHeight(double width) => 1000.0;
}

class _Line {
  // index of the first word in the line (inclusive)
  final int start;

  // index of the last word in the line (exclusive)
  final int end;

  _Line({
    required this.start,
    required this.end,
  });
}

class _Word {
  final String word;
  Paragraph? paragraph;

  _Word({
    required this.word,
    this.paragraph,
  });
}
