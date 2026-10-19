import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// [PipCursorTracker] is a high-performance, modular Flutter Web & mobile widget
/// that creates a smooth cursor-tracking and touch-interactive character animation
/// for Pip the Dream Engineer.
///
/// Features:
/// - Smooth 360° directional tracking including diagonals using 16 pre-extracted frames + center pose.
/// - Shortest-path circular angular lerp to eliminate jitter, snapping, and delay.
/// - Deadzone eye-contact: Pip looks directly forward when cursor is near the face or leaves area.
/// - Zero-ghosting: exactly one crisp frame displayed at 100% opacity.
/// - Mobile touch/drag support with automatic gentle spring-back to center.
/// - Idle breathing/floating cloud micro-animation when untouched.
class PipCursorTracker extends StatefulWidget {
  final double? width;
  final double? height;
  final bool enableTouchFallback;
  final bool enableIdleFloating;
  final bool isNightMode;
  final double deadzoneRadiusRatio;
  final ValueChanged<double>? onAngleChanged;
  final VoidCallback? onEyeContact;
  final VoidCallback? onTap;

  const PipCursorTracker({
    super.key,
    this.width,
    this.height,
    this.enableTouchFallback = true,
    this.enableIdleFloating = true,
    this.isNightMode = false,
    this.deadzoneRadiusRatio = 0.14,
    this.onAngleChanged,
    this.onEyeContact,
    this.onTap,
  });

  @override
  State<PipCursorTracker> createState() => _PipCursorTrackerState();
}

class _PipCursorTrackerState extends State<PipCursorTracker>
    with SingleTickerProviderStateMixin {
  // 17 frames total: 0 = center, 1..16 = dir_0 .. dir_15
  static const int totalDirectionalFrames = 16;
  
  late Ticker _ticker;
  double _currentAngle = 0.0;
  double _targetAngle = 0.0;
  double _currentDeadzoneFactor = 1.0; // 1.0 = at center (direct eye contact), 0.0 = looking directionally
  double _targetDeadzoneFactor = 1.0;

  bool _isInteracting = false;
  Offset _cursorPos = Offset.zero;
  int _activeFrameIndex = 0; // 0 is center, 1..16 are dir_0..dir_15

  // Idle floating animation
  double _idleTime = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAllFrames();
  }

  static const List<int> videoFrameIndices = [
    15, 30, 45, 60, 75, 90, 105, 120,
    135, 150, 165, 180, 195, 210, 225, 239
  ];

  void _precacheAllFrames() {
    precacheImage(const AssetImage('assets/images/pip/center.png'), context);
    for (final frameNumber in videoFrameIndices) {
      final name = frameNumber.toString().padLeft(3, '0');
      precacheImage(
        AssetImage('assets/images/pip_video_frames/frame_$name.png'),
        context,
      );
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Calculates shortest-path circular angular lerp to prevent 360° wraps or flips
  double _lerpAngle(double current, double target, double t) {
    double diff = (target - current) % (2.0 * math.pi);
    if (diff > math.pi) diff -= 2.0 * math.pi;
    if (diff < -math.pi) diff += 2.0 * math.pi;
    return current + diff * t;
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    setState(() {
      // Advance idle floating clock
      _idleTime += 0.02;

      // 1. Smoothly interpolate angle with fast 60fps response (t = 0.22, ~35ms latency)
      _currentAngle = _lerpAngle(_currentAngle, _targetAngle, 0.22);

      // 2. Smoothly interpolate deadzone factor
      _currentDeadzoneFactor += (_targetDeadzoneFactor - _currentDeadzoneFactor) * 0.20;

      // 3. Determine active frame
      if (_currentDeadzoneFactor > 0.65) {
        // Direct eye contact (center frame)
        if (_activeFrameIndex != 0) {
          _activeFrameIndex = 0;
          widget.onEyeContact?.call();
        }
      } else {
        // Directional frame mapping
        // Angle 0 is East (Right), pi/2 is South (Down), pi is West (Left), -pi/2 is North (Up)
        double normalized = (_currentAngle % (2.0 * math.pi) + 2.0 * math.pi) % (2.0 * math.pi);
        int dirIndex = ((normalized / (2.0 * math.pi)) * totalDirectionalFrames).round() % totalDirectionalFrames;
        int newIndex = dirIndex + 1; // 1-indexed in children stack
        if (_activeFrameIndex != newIndex) {
          _activeFrameIndex = newIndex;
          widget.onAngleChanged?.call(_currentAngle);
        }
      }
    });
  }

  void _updateTargetFromPosition(Offset localPos, Size size) {
    // Face center in Pip portrait coordinate space (roughly 50% horizontally, 41% vertically)
    final faceCenter = Offset(size.width * 0.50, size.height * 0.41);
    final delta = localPos - faceCenter;
    final distance = delta.distance;

    final deadzoneThreshold = math.min(size.width, size.height) * widget.deadzoneRadiusRatio;

    if (distance <= deadzoneThreshold) {
      // In deadzone: make eye contact
      _targetDeadzoneFactor = 1.0;
    } else {
      // Outside deadzone: track direction
      _targetDeadzoneFactor = 0.0;
      _targetAngle = math.atan2(delta.dy, delta.dx);
    }
  }

  void _onPointerHover(PointerHoverEvent event, Size size) {
    _isInteracting = true;
    _cursorPos = event.localPosition;
    _updateTargetFromPosition(_cursorPos, size);
  }

  void _onPointerExit(PointerExitEvent event) {
    _isInteracting = false;
    _targetDeadzoneFactor = 1.0; // Return to direct eye contact
  }

  void _onPanStart(DragStartDetails details, Size size) {
    _isInteracting = true;
    _cursorPos = details.localPosition;
    _updateTargetFromPosition(_cursorPos, size);
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    _cursorPos = details.localPosition;
    _updateTargetFromPosition(_cursorPos, size);
  }

  void _onPanEnd(DragEndDetails details) {
    _isInteracting = false;
    _targetDeadzoneFactor = 1.0; // Return to center when touch is released
  }

  @override
  Widget build(BuildContext context) {
    final defaultWidth = widget.width ?? 340.0;

    // Idle vertical floating bobbing offset
    final floatOffsetY = widget.enableIdleFloating && !_isInteracting
        ? math.sin(_idleTime) * 3.5
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final renderWidth = math.min(defaultWidth, constraints.maxWidth);
        final renderHeight = widget.height ?? (renderWidth * (1024.0 / 682.0));
        final targetSize = Size(renderWidth, renderHeight);

        return Center(
          child: MouseRegion(
            onHover: (e) => _onPointerHover(e, targetSize),
            onExit: _onPointerExit,
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onTap,
              onPanStart: widget.enableTouchFallback ? (d) => _onPanStart(d, targetSize) : null,
              onPanUpdate: widget.enableTouchFallback ? (d) => _onPanUpdate(d, targetSize) : null,
              onPanEnd: widget.enableTouchFallback ? _onPanEnd : null,
              child: Transform.translate(
                offset: Offset(0, floatOffsetY),
                child: Container(
                  width: renderWidth,
                  height: renderHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isNightMode
                            ? const Color(0xFF0D0818).withValues(alpha: 0.55)
                            : const Color(0xFF8B5E3C).withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                      if (widget.isNightMode)
                        BoxShadow(
                          color: const Color(0xFFFFC96B).withValues(alpha: 0.12),
                          blurRadius: 36,
                          spreadRadius: -4,
                        ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Zero-Ghosting crisp frame switcher (IndexedStack keeps decoded textures alive and flips in 1 GPU tick)
                      IndexedStack(
                        index: _activeFrameIndex,
                        children: [
                          // Index 0: Center Neutral Pose
                          Image.asset(
                            'assets/images/pip/center.png',
                            width: renderWidth,
                            height: renderHeight,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                          ),
                          // Index 1..16: sampled video poses
                          for (final frameNumber in videoFrameIndices)
                            Image.asset(
                              'assets/images/pip_video_frames/frame_${frameNumber.toString().padLeft(3, "0")}.png',
                              width: renderWidth,
                              height: renderHeight,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                            ),
                        ],
                      ),

                      // Subtle interactive glowing aura when eye contact is made
                      if (_currentDeadzoneFactor > 0.5)
                        IgnorePointer(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: (_currentDeadzoneFactor - 0.5) * 1.5,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(0.0, -0.20),
                                  radius: 0.40,
                                  colors: [
                                    const Color(0xFFFFE082).withValues(alpha: 0.15),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
