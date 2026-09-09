import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ZoomWrapper extends StatefulWidget {
  const ZoomWrapper({
    super.key,
    required this.initialScale,
    this.minScale = 8.0,
    this.maxScale = 30.0,
    this.getInitialScale,
    this.onZoomStart,
    required this.onScaleChanged,
    required this.builder,
  });

  final double initialScale;
  final double minScale;
  final double maxScale;
  final double Function()? getInitialScale;
  final void Function(Offset focalPoint)? onZoomStart;
  final ValueChanged<double> onScaleChanged;
  final Widget Function(BuildContext context, double scale) builder;

  @override
  State<ZoomWrapper> createState() => _ZoomWrapperState();
}

class _ZoomWrapperState extends State<ZoomWrapper> {
  // The visual scale multiplier applied via Transform.scale during a pinch
  // gesture. Resets to 1.0 after each gesture ends.
  double _visualScale = 1.0;

  // The alignment for the Transform.scale, calculated from the gesture's focal point.
  Alignment _transformAlignment = Alignment.center;

  // The absolute scale at the start of the current gesture.
  double _gestureStartAbsoluteScale = 1.0;

  double get _currentInitialScale =>
      widget.getInitialScale?.call() ?? widget.initialScale;

  Map<Type, GestureRecognizerFactory<GestureRecognizer>> get _zoomGesture {
    return {
      CustomScaleGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<CustomScaleGestureRecognizer>(
        () => CustomScaleGestureRecognizer(),
        (CustomScaleGestureRecognizer instance) {
          instance
            ..onStart = (details) {
              widget.onZoomStart?.call(details.localFocalPoint);
              _gestureStartAbsoluteScale = _currentInitialScale;
              _updateTransformAlignment(details.localFocalPoint);
            }
            ..onUpdate = (details) {
              setState(() {
                _visualScale = details.scale.clamp(
                  widget.minScale / _gestureStartAbsoluteScale,
                  widget.maxScale / _gestureStartAbsoluteScale,
                );
              });
            }
            ..onEnd = (details) {
              final newAbsoluteScale =
                  (_gestureStartAbsoluteScale * _visualScale).clamp(
                widget.minScale,
                widget.maxScale,
              );
              // Only persist if the scale actually changed
              if ((_visualScale - 1.0).abs() > 0.01) {
                widget.onScaleChanged(newAbsoluteScale.roundToDouble());
              }
              setState(() {
                _visualScale = 1.0;
              });
            };
        },
      ),
    };
  }

  void _updateTransformAlignment(Offset localFocalPoint) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    setState(() {
      _transformAlignment = _calculateAlignment(
        renderBox.size,
        localFocalPoint,
      );
    });
  }

  Alignment _calculateAlignment(Size widgetSize, Offset focalPoint) {
    final dx = focalPoint.dx.clamp(0.0, widgetSize.width);
    final dy = focalPoint.dy.clamp(0.0, widgetSize.height);
    return Alignment(
      (dx / widgetSize.width) * 2 - 1,
      (dy / widgetSize.height) * 2 - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: _zoomGesture,
      behavior: HitTestBehavior.translucent,
      child: Transform.scale(
        scale: _visualScale,
        alignment: _transformAlignment,
        child: widget.builder(context, _currentInitialScale),
      ),
    );
  }
}

/// Custom recognizer that listens only for scaling (pinch) gestures.
class CustomScaleGestureRecognizer extends ScaleGestureRecognizer {
  CustomScaleGestureRecognizer({super.debugOwner});

  int _pointerCount = 0;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _pointerCount++;
  }

  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointerCount--;
    }
  }

  @override
  void rejectGesture(int pointer) {
    if (_pointerCount >= 2) {
      acceptGesture(pointer);
    } else {
      super.rejectGesture(pointer);
    }
  }
}
