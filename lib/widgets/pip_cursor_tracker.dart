import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class PipCursorTracker extends StatefulWidget {
  final double? width;
  final double? height;
  final bool enableTouchFallback;
  final bool enableIdleFloating;
  final bool isNightMode;
  final bool isPointerInsideApp;
  final double deadzoneRadiusRatio;
  final Animation<double>? laughAnimation;
  final ValueChanged<double>? onAngleChanged;
  final VoidCallback? onEyeContact;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const PipCursorTracker({
    super.key,
    this.width,
    this.height,
    this.enableTouchFallback = true,
    this.enableIdleFloating = true,
    this.isNightMode = false,
    this.isPointerInsideApp = true,
    this.deadzoneRadiusRatio = 0.08,
    this.laughAnimation,
    this.onAngleChanged,
    this.onEyeContact,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<PipCursorTracker> createState() => _PipCursorTrackerState();
}

enum _GazeDirection {
  upperLeft,
  up,
  upperRight,
  left,
  center,
  right,
  lowerLeft,
  down,
  lowerRight,
}

class _PipCursorTrackerState extends State<PipCursorTracker> {
  final GlobalKey _trackerKey = GlobalKey();

  int _horizontalDirection = 0;
  int _verticalDirection = 0;
  _GazeDirection _gazeDirection = _GazeDirection.center;
  bool _isInEyeContact = false;

  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handleGlobalPointer);
    widget.laughAnimation?.addStatusListener(_handleLaughAnimationStatus);
  }

  @override
  void didUpdateWidget(covariant PipCursorTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.laughAnimation != widget.laughAnimation) {
      oldWidget.laughAnimation?.removeStatusListener(
        _handleLaughAnimationStatus,
      );
      widget.laughAnimation?.addStatusListener(_handleLaughAnimationStatus);
    }
    if (oldWidget.isPointerInsideApp && !widget.isPointerInsideApp) {
      _setNeutralGaze();
    }
  }

  void _handleLaughAnimationStatus(AnimationStatus status) {
    if (mounted) setState(() {});
  }

  void _handleGlobalPointer(PointerEvent event) {
    if (event is PointerRemovedEvent) {
      _resetGaze();
      return;
    }
    if (event is! PointerHoverEvent) return;

    final renderObject = _trackerKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return;
    }

    _handlePointer(
      renderObject.globalToLocal(event.position),
      renderObject.size,
    );
  }

  void _handlePointer(Offset position, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height * 0.38);
    final delta = position - center;
    final horizontal = _quantizeAxis(
      (delta.dx / (size.width / 2)).clamp(-1.0, 1.0),
      _horizontalDirection,
    );
    final vertical = _quantizeAxis(
      (delta.dy / (size.height / 2)).clamp(-1.0, 1.0),
      _verticalDirection,
    );
    final direction = _directionFor(horizontal, vertical);

    if (direction != _gazeDirection) {
      setState(() {
        _horizontalDirection = horizontal;
        _verticalDirection = vertical;
        _gazeDirection = direction;
      });
    }

    widget.onAngleChanged?.call(math.atan2(delta.dy, delta.dx));

    final isInEyeContact =
        delta.distance < size.width * widget.deadzoneRadiusRatio;
    if (isInEyeContact && !_isInEyeContact) {
      widget.onEyeContact?.call();
    }
    _isInEyeContact = isInEyeContact;
  }

  int _quantizeAxis(double value, int current) {
    return switch (current) {
      -1 =>
        value > 0.2
            ? 1
            : value > -0.12
            ? 0
            : -1,
      1 =>
        value < -0.2
            ? -1
            : value < 0.12
            ? 0
            : 1,
      _ =>
        value < -0.2
            ? -1
            : value > 0.2
            ? 1
            : 0,
    };
  }

  _GazeDirection _directionFor(int horizontal, int vertical) {
    return switch ((horizontal, vertical)) {
      (-1, -1) => _GazeDirection.upperLeft,
      (0, -1) => _GazeDirection.up,
      (1, -1) => _GazeDirection.upperRight,
      (-1, 0) => _GazeDirection.left,
      (0, 0) => _GazeDirection.center,
      (1, 0) => _GazeDirection.right,
      (-1, 1) => _GazeDirection.lowerLeft,
      (0, 1) => _GazeDirection.down,
      (1, 1) => _GazeDirection.lowerRight,
      _ => _GazeDirection.center,
    };
  }

  int _frameForDirection(_GazeDirection direction) {
    return switch (direction) {
      _GazeDirection.upperLeft => 200,
      _GazeDirection.up => 50,
      _GazeDirection.upperRight => 65,
      _GazeDirection.left => 185,
      _GazeDirection.center => 220,
      _GazeDirection.right => 90,
      _GazeDirection.lowerLeft => 170,
      _GazeDirection.down => 135,
      _GazeDirection.lowerRight => 110,
    };
  }

  void _resetGaze() {
    if (_gazeDirection == _GazeDirection.center &&
        _horizontalDirection == 0 &&
        _verticalDirection == 0) {
      return;
    }

    setState(() {
      _setNeutralGaze();
    });
  }

  void _setNeutralGaze() {
    _horizontalDirection = 0;
    _verticalDirection = 0;
    _gazeDirection = _GazeDirection.center;
    _isInEyeContact = false;
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _handleGlobalPointer,
    );
    widget.laughAnimation?.removeStatusListener(_handleLaughAnimationStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frameForDirection(_gazeDirection);
    final frameName = 'frame_${frame.toString().padLeft(3, '0')}.png';
    final restingImage = _pipImage(
      'assets/images/pip_gaze_transparent/$frameName',
    );
    final laughAnimation = widget.laughAnimation;
    final image = laughAnimation == null
        ? restingImage
        : AnimatedBuilder(
            animation: laughAnimation,
            child: restingImage,
            builder: (context, child) {
              final isLaughing =
                  laughAnimation.status == AnimationStatus.forward ||
                  laughAnimation.status == AnimationStatus.reverse;
              if (!isLaughing) return child!;

              return _pipLaughImage(
                assetName: 'assets/images/pip_gaze_laugh_base/$frameName',
                fallback: child,
                frame: frame,
                progress: laughAnimation.value,
              );
            },
          );

    return SizedBox(
      key: _trackerKey,
      width: widget.width ?? 320,
      height: widget.height ?? 570,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onPanUpdate: widget.enableTouchFallback
            ? (details) => _handlePointer(
                details.localPosition,
                Size(widget.width ?? 320, widget.height ?? 570),
              )
            : null,
        child: image,
      ),
    );
  }

  Widget _pipImage(String assetName) {
    return Image.asset(
      assetName,
      width: widget.width ?? 320,
      height: widget.height ?? 570,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Text(
            'Could not load Pip frames.',
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _pipLaughImage({
    required String assetName,
    required Widget fallback,
    required int frame,
    required double progress,
  }) {
    return Image.asset(
      assetName,
      key: ValueKey(assetName),
      width: widget.width ?? 320,
      height: widget.height ?? 570,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      frameBuilder: (context, image, frameNumber, wasSynchronouslyLoaded) {
        if (frameNumber == null && !wasSynchronouslyLoaded) return fallback;
        return Stack(
          fit: StackFit.expand,
          children: [
            image,
            CustomPaint(
              key: const ValueKey('pip-laugh-mouth'),
              painter: _PipLaughMouthPainter(
                frame: frame,
                progress: progress,
              ),
            ),
          ],
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Unable to load Pip laugh frame: $error');
        debugPrintStack(stackTrace: stackTrace);
        return fallback;
      },
    );
  }
}

class _PipLaughMouthPainter extends CustomPainter {
  final int frame;
  final double progress;

  const _PipLaughMouthPainter({required this.frame, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final pose = _mouthPoses[frame];
    if (pose == null) return;

    final openness = _mouthOpenness(progress);
    final scaleX = size.width / 720;
    final scaleY = size.height / 1280;
    canvas.save();
    canvas.scale(scaleX, scaleY);
    canvas.translate(pose.$1, pose.$2);
    canvas.rotate(pose.$4);

    final halfWidth = pose.$3 / 2;
    const outlineColor = Color(0xFF594036);
    final outline = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (openness < 0.025) {
      final smile = Path()
        ..moveTo(-halfWidth, 0)
        ..quadraticBezierTo(0, 12, halfWidth, 0);
      canvas.drawPath(smile, outline);
    } else {
      final openHeight = 32 * openness;
      final mouth = Path()
        ..moveTo(-halfWidth, 0)
        ..quadraticBezierTo(0, 4, halfWidth, 0)
        ..quadraticBezierTo(0, openHeight * 1.5 + 2, -halfWidth, 0)
        ..close();
      canvas.drawPath(
        mouth,
        Paint()
          ..color = outlineColor
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(mouth, outline);

      if (openness > 0.38) {
        final tongue = Path()
          ..moveTo(-halfWidth * 0.48, openHeight * 0.92)
          ..quadraticBezierTo(
            0,
            openHeight * 1.28,
            halfWidth * 0.48,
            openHeight * 0.92,
          )
          ..quadraticBezierTo(
            0,
            openHeight * 0.75,
            -halfWidth * 0.48,
            openHeight * 0.92,
          )
          ..close();
        canvas.drawPath(
          tongue,
          Paint()
            ..color = const Color(0xFFE89AA9)
            ..style = PaintingStyle.fill,
        );
      }
    }

    canvas.restore();
  }

  double _mouthOpenness(double value) {
    const stages = [0.0, 0.18, 0.82, 0.32, 1.0, 0.24, 0.0];
    final scaled = value.clamp(0.0, 1.0) * (stages.length - 1);
    final index = scaled.floor().clamp(0, stages.length - 2);
    final t = Curves.easeInOut.transform(scaled - index);
    return stages[index] + (stages[index + 1] - stages[index]) * t;
  }

  @override
  bool shouldRepaint(covariant _PipLaughMouthPainter oldDelegate) {
    return frame != oldDelegate.frame || progress != oldDelegate.progress;
  }

  static const _mouthPoses = <int, (double, double, double, double)>{
    50: (407.5, 540, 81, 0),
    65: (428.5, 522, 73, -0.04),
    90: (490, 553.5, 58, 0.08),
    110: (507.5, 602, 57, 0.08),
    135: (401, 614, 82, 0),
    170: (269.5, 602, 69, -0.06),
    185: (247, 592, 62, -0.04),
    200: (269.5, 551, 63, -0.03),
    220: (358.5, 581, 83, 0),
  };
}
