import 'package:bsb/ui/shared/zoom_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ZoomWrapper renders child with initial scale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomWrapper(
            initialScale: 20.0,
            onScaleChanged: (_) {},
            builder: (context, scale) {
              return Text('Scale: $scale');
            },
          ),
        ),
      ),
    );

    expect(find.text('Scale: 20.0'), findsOneWidget);
  });

  testWidgets('ZoomWrapper respects getInitialScale dynamic callback', (tester) async {
    double currentScale = 18.0;
    late StateSetter setScaleState;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setScaleState = setState;
              return ZoomWrapper(
                initialScale: 20.0,
                getInitialScale: () => currentScale,
                onScaleChanged: (_) {},
                builder: (context, scale) {
                  return Text('Scale: $scale');
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Scale: 18.0'), findsOneWidget);

    setScaleState(() {
      currentScale = 22.0;
    });
    await tester.pump();

    expect(find.text('Scale: 22.0'), findsOneWidget);
  });

  testWidgets('ZoomWrapper detects pinch-to-zoom gesture and fires onScaleChanged', (tester) async {
    double? newScale;
    Offset? zoomStartPoint;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: ZoomWrapper(
                initialScale: 20.0,
                minScale: 8.0,
                maxScale: 30.0,
                onZoomStart: (point) {
                  zoomStartPoint = point;
                },
                onScaleChanged: (scale) {
                  newScale = scale;
                },
                builder: (context, scale) {
                  return Container(
                    color: Colors.blue,
                    child: Text('Content scale: $scale'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final gesture1 = await tester.startGesture(const Offset(350, 300), pointer: 1);
    final gesture2 = await tester.startGesture(const Offset(450, 300), pointer: 2);
    await tester.pump();

    expect(zoomStartPoint, isNotNull);

    await gesture1.moveBy(const Offset(-80, 0));
    await gesture2.moveBy(const Offset(80, 0));
    await tester.pump();

    await gesture1.up();
    await gesture2.up();
    await tester.pumpAndSettle();

    expect(newScale, isNotNull);
    // Since it's magnified significantly from 20.0, it should hit maxScale 30.0
    expect(newScale, equals(30.0));
  });

  testWidgets('ZoomWrapper detects pinch-in (zoom out) and clamps to minScale', (tester) async {
    double? newScale;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: ZoomWrapper(
                initialScale: 20.0,
                minScale: 8.0,
                maxScale: 30.0,
                onScaleChanged: (scale) {
                  newScale = scale;
                },
                builder: (context, scale) {
                  return Container(
                    color: Colors.green,
                    child: Text('Content scale: $scale'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final gesture1 = await tester.startGesture(const Offset(300, 300), pointer: 1);
    final gesture2 = await tester.startGesture(const Offset(500, 300), pointer: 2);
    await tester.pump();

    // Pinch inward
    await gesture1.moveBy(const Offset(90, 0));
    await gesture2.moveBy(const Offset(-90, 0));
    await tester.pump();

    await gesture1.up();
    await gesture2.up();
    await tester.pumpAndSettle();

    expect(newScale, isNotNull);
    expect(newScale, equals(8.0));
  });

  testWidgets('ZoomWrapper single finger drag does not trigger onScaleChanged', (tester) async {
    double? newScale;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomWrapper(
            initialScale: 20.0,
            onScaleChanged: (scale) {
              newScale = scale;
            },
            builder: (context, scale) {
              return ListView(
                children: List.generate(
                  50,
                  (i) => ListTile(title: Text('Item $i')),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.drag(find.text('Item 0'), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(newScale, isNull);
  });
}
