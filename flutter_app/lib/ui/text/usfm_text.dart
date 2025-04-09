import 'dart:ui';

import 'package:database_builder/database_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef TextParagraphs = List<(TextSpan, TextType, Format?)>;

class UsfmText extends LeafRenderObjectWidget {
  const UsfmText({
    super.key,
    required this.paragraphs,
    required this.paragraphSpacing,
    this.bottomSpace = 300,
  });

  /// The paragraphs will be rendered in order
  final TextParagraphs paragraphs;
  final double paragraphSpacing;
  final double bottomSpace;

  @override
  RenderUsfmText createRenderObject(BuildContext context) {
    return RenderUsfmText(
      paragraphs: paragraphs,
      paragraphSpacing: paragraphSpacing,
      bottomSpace: bottomSpace,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderUsfmText renderObject) {
    renderObject
      ..paragraphs = paragraphs
      ..paragraphSpacing = paragraphSpacing
      ..bottomSpace = bottomSpace;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextParagraphs>('paragraphs', paragraphs));
    properties.add(DoubleProperty('paragraphSpacing', paragraphSpacing));
    properties.add(DoubleProperty('bottomSpace', bottomSpace));
  }
}

class RenderUsfmText extends RenderBox {
  RenderUsfmText({
    required TextParagraphs paragraphs,
    required double paragraphSpacing,
    required double bottomSpace,
  })  : _paragraphs = paragraphs,
        _paragraphSpacing = paragraphSpacing,
        _bottomSpace = bottomSpace;

  /// The paragraphs will be rendered in order
  TextParagraphs get paragraphs => _paragraphs;
  TextParagraphs _paragraphs;
  set paragraphs(TextParagraphs value) {
    if (_paragraphs == value) return;
    _paragraphs = value;
    markNeedsLayout();
  }

  /// The space between paragraphs
  double get paragraphSpacing => _paragraphSpacing;
  double _paragraphSpacing;
  set paragraphSpacing(double value) {
    if (_paragraphSpacing == value) return;
    _paragraphSpacing = value;
    // TODO: don't need to remeasure all of the words
    markNeedsLayout();
  }

  /// The space between the bottom of the last paragraph and the bottom of the widget
  double get bottomSpace => _bottomSpace;
  double _bottomSpace;
  set bottomSpace(double value) {
    if (_bottomSpace == value) return;
    _bottomSpace = value;
    // TODO: don't need to remeasure all of the words
    markNeedsLayout();
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    // Break the text into chunks at every space.
    final chunks = _breakTextIntoChunks(paragraphs);
    // There should be no newline characters in the text.
    // Measure every chunk.
    // Measure the width of a space.
    // The desired width is the min of the width of the longest paragraph and the constraint width.
    // The desired height is the sum of the heights of the paragraphs plus the
    //   space between the paragraphs and the bottom space.
    final desiredWidth = TODO;
    final desiredHeight = TODO;
    return Size(desiredWidth, desiredHeight);
  }

  List<ChunkedParagraph> _breakTextIntoChunks(TextParagraphs paragraphs) {
    // TODO: implement _breakTextIntoChunks
    return [];
  }

  // TODO: set this to the width of the longest chunk.
  @override
  double computeMinIntrinsicWidth(double height) => TODO;

  // TODO: set this to the width of the longest paragraph.
  @override
  double computeMaxIntrinsicWidth(double height) => TODO;

  // TODO: calculate the desired height at this width.
  @override
  double computeMinIntrinsicHeight(double width) => TODO;

  // TODO: calculate the desired height at this width.
  @override
  double computeMaxIntrinsicHeight(double width) => TODO;

  @override
  void paint(PaintingContext context, Offset offset) {
    // TODO: implement paint
  }
}

class ChunkedParagraph {
  ChunkedParagraph(this.chunks, this.type, this.format);
  final List<Paragraph> chunks;
  final TextType type;
  final Format? format;
}
