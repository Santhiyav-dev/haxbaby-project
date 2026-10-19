import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// Full-screen animated starfield painter for the night scenes.
class StarfieldBackground extends StatefulWidget {
  final bool isNight;
  final Widget child;

  const StarfieldBackground({
    super.key,
    required this.isNight,
    required this.child,
  });

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Star> _stars = [];
  final _random = Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _generateStars();
  }

  void _generateStars() {
    for (int i = 0; i < 80; i++) {
      _stars.add(
        _Star(
          x: _random.nextDouble(),
          y: _random.nextDouble() * 0.7,
          size: _random.nextDouble() * 3 + 1,
          twinkleOffset: _random.nextDouble(),
          opacity: _random.nextDouble() * 0.5 + 0.3,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: _buildBackground(),
      child: Stack(
        children: [
          // Stars layer (night only)
          if (widget.isNight)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _StarPainter(_stars, _controller.value),
                  child: const SizedBox.expand(),
                );
              },
            ),
          // Cloud / mist layer
          ..._buildClouds(),
          // Content
          widget.child,
        ],
      ),
    );
  }

  BoxDecoration _buildBackground() {
    if (widget.isNight) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF171323), PipColors.nightBg, PipColors.nightMid],
          stops: [0.0, 0.6, 1.0],
        ),
      );
    } else {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFE5FA), Color(0xFFFFF1F5), PipColors.cream],
          stops: [0.0, 0.5, 1.0],
        ),
      );
    }
  }

  List<Widget> _buildClouds() {
    if (!widget.isNight) return [];
    return [
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: 120,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, PipColors.nightMid.withOpacity(0.4)],
            ),
          ),
        ),
      ),
    ];
  }
}

class _Star {
  final double x, y, size, twinkleOffset, opacity;
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleOffset,
    required this.opacity,
  });
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double animValue;

  const _StarPainter(this.stars, this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final twinkle = (sin((animValue + star.twinkleOffset) * pi * 2) + 1) / 2;
      final alpha = (star.opacity * (0.5 + twinkle * 0.5)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Colors.white.withOpacity(alpha)
        ..style = PaintingStyle.fill;

      final cx = star.x * size.width;
      final cy = star.y * size.height;
      final r = star.size * (0.8 + twinkle * 0.4);

      canvas.drawCircle(Offset(cx, cy), r, paint);

      // Tiny cross sparkle for larger stars
      if (star.size > 2.5) {
        final sparkPaint = Paint()
          ..color = Colors.white.withOpacity(alpha * 0.6)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(cx - r * 2, cy),
          Offset(cx + r * 2, cy),
          sparkPaint,
        );
        canvas.drawLine(
          Offset(cx, cy - r * 2),
          Offset(cx, cy + r * 2),
          sparkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.animValue != animValue;
}

/// A floating cloud-like oval that bobs gently.
class FloatingCloud extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double delay;

  const FloatingCloud({
    super.key,
    this.width = 200,
    this.height = 80,
    required this.color,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: (delay * 1000).round()))
        .then()
        .moveY(begin: 0, end: -12, duration: 2000.ms, curve: Curves.easeInOut)
        .then()
        .moveY(begin: -12, end: 0, duration: 2000.ms, curve: Curves.easeInOut);
  }
}
