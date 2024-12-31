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
}
