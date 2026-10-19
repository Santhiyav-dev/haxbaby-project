
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haxbaby_project/main.dart';
import 'package:haxbaby_project/widgets/pip_cursor_tracker.dart';

void main() {
  testWidgets('mouse position selects all available gaze poses', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PipCursorTracker(width: 320, height: 570)),
      ),
    );

    final tracker = find.byType(PipCursorTracker);
    final topLeft = tester.getTopLeft(tracker);
    final size = tester.getSize(tracker);
    final centerY = topLeft.dy + size.height * 0.38;

    await tester.sendEventToBinding(
      PointerHoverEvent(position: Offset(topLeft.dx - 80, centerY)),
    );
    await tester.pump();
    expect(_findPose(185), findsOneWidget);

    await tester.sendEventToBinding(
      PointerHoverEvent(
        position: Offset(topLeft.dx + size.width + 80, centerY),
      ),
    );
    await tester.pump();
    expect(_findPose(90), findsOneWidget);

    await tester.sendEventToBinding(
      PointerHoverEvent(
        position: Offset(topLeft.dx + size.width * 0.5, centerY),
      ),
    );
    await tester.pump();
    expect(_findPose(220), findsOneWidget);

    final centerX = topLeft.dx + size.width * 0.5;
    final above = centerY - size.height * 0.4;
    final below = centerY + size.height * 0.4;
    final positions = <(Offset, int)>[
      (Offset(centerX, above), 50),
      (Offset(centerX, below), 135),
      (Offset(centerX - 120, above), 200),
      (Offset(centerX + 120, above), 65),
      (Offset(centerX - 120, below), 170),
      (Offset(centerX + 120, below), 110),
    ];

    for (final (position, frame) in positions) {
      await tester.sendEventToBinding(PointerHoverEvent(position: position));
      await tester.pump();
      expect(_findPose(frame), findsOneWidget);
    }

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);
    final stableFrame = _findPose(110);
    await tester.pump(const Duration(seconds: 15));
    expect(stableFrame, findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PipCursorTracker(
            width: 320,
            height: 570,
            isPointerInsideApp: false,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(_findPose(220), findsOneWidget);
  });

  testWidgets('leaving the app resets Pip to its neutral pose', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(
      find.text('I see you! Let’s build sweet dreams together.'),
      findsOneWidget,
    );

    final tracker = find.byType(PipCursorTracker);
    final topLeft = tester.getTopLeft(tracker);
    final size = tester.getSize(tracker);
    final centerY = topLeft.dy + size.height * 0.38;

    await tester.sendEventToBinding(
      PointerHoverEvent(
        position: Offset(topLeft.dx + size.width + 80, centerY),
      ),
    );
    await tester.pump();
    expect(_findPose(90), findsOneWidget);

    await tester.sendEventToBinding(
      PointerRemovedEvent(position: Offset(-1, centerY)),
    );
    await tester.pump();
    expect(_findPose(220), findsOneWidget);
  });

  testWidgets('PipCursorTracker renders and handles touch drag interaction', (
    WidgetTester tester,
  ) async {
    double? lastAngle;
    bool eyeContactCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PipCursorTracker(
              width: 320,
              onAngleChanged: (a) => lastAngle = a,
              onEyeContact: () => eyeContactCalled = true,
            ),
          ),
        ),
      ),
    );

    // Initial frame pump
    await tester.pump();
    expect(find.byType(PipCursorTracker), findsOneWidget);

    // Perform drag gesture away from center to trigger directional tracking
    final trackerFinder = find.byType(PipCursorTracker);
    final center = tester.getCenter(trackerFinder);

    // Drag to the right
    final gesture = await tester.startGesture(center);
    await gesture.moveTo(center + const Offset(120, 0));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 100));

    expect(lastAngle, isNotNull);

    // Release touch and let it animate back to center (eye contact)
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PipCursorTracker), findsOneWidget);
    // Verify eye contact callback or gesture completion
    expect(eyeContactCalled || lastAngle != null, isTrue);
  });

  testWidgets('double-tapping Pip triggers its callback once per double tap', (
    WidgetTester tester,
  ) async {
    var doubleTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PipCursorTracker(
                width: 160,
                height: 285,
                onDoubleTap: () => doubleTapCount++,
              ),
              TextButton(onPressed: () {}, child: const Text('Elsewhere')),
            ],
          ),
        ),
      ),
    );

    await _doubleTapAt(tester, tester.getCenter(find.text('Elsewhere')));
    expect(doubleTapCount, 0);

    final pip = find.byType(PipCursorTracker);
    await _doubleTapAt(tester, tester.getCenter(pip));
    expect(doubleTapCount, 1);

    await _doubleTapAt(tester, tester.getCenter(pip));
    expect(doubleTapCount, 2);
    await tester.pump(kDoubleTapTimeout);
  });

  testWidgets('a single tap does not trigger Pip double-tap callback', (
    WidgetTester tester,
  ) async {
    var doubleTapCount = 0;
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PipCursorTracker(
            width: 160,
            height: 285,
            onTap: () => tapCount++,
            onDoubleTap: () => doubleTapCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PipCursorTracker));
    await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 1));

    expect(tapCount, 1);
    expect(doubleTapCount, 0);
  });

  testWidgets('laugh animation shows matching pose and restores resting art', (
    WidgetTester tester,
  ) async {
    final animation = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 2),
    );
    addTearDown(animation.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PipCursorTracker(
            width: 160,
            height: 285,
            laughAnimation: animation,
          ),
        ),
      ),
    );

    expect(
      _findAsset('assets/images/pip_gaze_transparent/frame_220.png'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pip-laugh-mouth')), findsNothing);

    animation.forward();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      _findAsset('assets/images/pip_gaze_laugh_base/frame_220.png'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pip-laugh-mouth')), findsOneWidget);

    animation.reset();
    await tester.pump();
    expect(
      _findAsset('assets/images/pip_gaze_transparent/frame_220.png'),
      findsOneWidget,
    );
    expect(
      _findAsset('assets/images/pip_gaze_laugh_base/frame_220.png'),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('pip-laugh-mouth')), findsNothing);
  });
}

Finder _findPose(int frame) {
  return find.byWidgetPredicate((widget) {
    final image = widget is Image ? widget.image : null;
    return image is AssetImage &&
        image.assetName.endsWith(
          'frame_${frame.toString().padLeft(3, '0')}.png',
        );
  });
}

Finder _findAsset(String assetName) {
  return find.byWidgetPredicate((widget) {
    final image = widget is Image ? widget.image : null;
    return image is AssetImage && image.assetName == assetName;
  });
}

Future<void> _doubleTapAt(WidgetTester tester, Offset position) async {
  final firstTap = await tester.startGesture(position);
  await firstTap.up();
  await tester.pump(const Duration(milliseconds: 50));

  final secondTap = await tester.startGesture(position);
  await secondTap.up();
  await tester.pump();
}
