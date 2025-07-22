import 'package:flutter/widgets.dart';

class SnappyScrollPhysics extends ScrollPhysics {
  const SnappyScrollPhysics({super.parent});

  @override
  SnappyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappyScrollPhysics(parent: buildParent(ancestor)!);
  }

  @override
  SpringDescription get spring {
    return SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: 300));
  }
}
