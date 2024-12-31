import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Unified Standard Format Markers
enum UsfmMarker {
  /// chapter
  c,

  /// verse
  v,
}

/// One text line of USFM content
class UsfmLine {
  const UsfmLine(this.marker, this.text);
  final UsfmMarker marker;
  final String text;
}

/// Text layout for Unified Standard Format Markers
class UsfmLayout extends LeafRenderObjectWidget {
  const UsfmLayout({super.key, required this.lines});

  /// The lines will be rendered in order
  final List<UsfmLine> lines;

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
    properties.add(IterableProperty<UsfmLine>('lines', lines));
  }
}

class RenderUsfmLayout extends RenderBox {
  RenderUsfmLayout({
    required List<UsfmLine> lines,
  }) : _lines = lines;

  List<UsfmLine> get lines => _lines;
  List<UsfmLine> _lines;
  set lines(List<UsfmLine> value) {
    if (_lines == value) return;
    _lines = value;
    markNeedsLayout();
  }
}
