import 'package:flutter/widgets.dart';

class SnappyScrollPhysics extends ScrollPhysics {
  const SnappyScrollPhysics({super.parent});

  @override
  SnappyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappyScrollPhysics(parent: buildParent(ancestor)!);
  }

  @override
  SpringDescription get spring {
    return const SpringDescription(
      mass: 100,
      stiffness: 100,
      damping: 1.0,
    );
  }
}
