import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/dream_state.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogue_bubble.dart';
import '../widgets/starfield_background.dart';
import '../widgets/hidden_star.dart';
import '../services/audio_service.dart';

class DeliveryRoutesScene extends StatefulWidget {
  final VoidCallback onNext;
  final AudioService audioService;
  const DeliveryRoutesScene({
    super.key,
    required this.onNext,
    required this.audioService,
  });

  @override
  State<DeliveryRoutesScene> createState() => _DeliveryRoutesSceneState();
}

class _DeliveryRoutesSceneState extends State<DeliveryRoutesScene>
    with SingleTickerProviderStateMixin {
  int? _activeDestination;
  bool _dialogueDone = false;
  bool _isAnimating = false;
  double _pipProgress = 0.0;
  late AnimationController _routeController;
  Set<int> _visited = {};

  final List<_Destination> _destinations = [
    _Destination(
      name: "Sleepy Suburb",
      emoji: "🏘️",
      dream: "Pip delivers a cosy dream of autumn afternoons, warm soup and old blankets.",
      position: const Offset(0.15, 0.65),
    ),
    _Destination(
      name: "Cloud Forest",
      emoji: "🌲",
      dream: "A dream of wandering through silver trees where the leaves hum lullabies.",
      position: const Offset(0.38, 0.25),
    ),
    _Destination(
      name: "Starfall Bay",
      emoji: "🌊",
      dream: "This dreamer gets waves of deep blue, bioluminescent fish and gentle tides.",
      position: const Offset(0.68, 0.55),
      hasStar: true,
    ),
    _Destination(
      name: "The Tiny Tower",
      emoji: "🏰",
      dream:
          "A grand adventure dream — but Pip made sure the dragon is friendly.",
      position: const Offset(0.55, 0.72),
    ),
    _Destination(
      name: "Meadow's Edge",
      emoji: "🌸",
      dream:
          "Soft meadows, butterfly conversations and a warm golden afternoon.",
      position: const Offset(0.82, 0.28),
    ),
  ];

  final List<String> _pipLines = [
    "Oh crumbs! These dreams won't deliver themselves! 📦",
    "Every little dream needs a place to go.",
    "Come on, let's find their way home!",
  ];

  @override
  void initState() {
    super.initState();
    _routeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _routeController.addListener(() {
      setState(() => _pipProgress = _routeController.value);
    });
  }

  @override
  void dispose() {
    _routeController.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    if (_isAnimating) return;
    setState(() {
      _activeDestination = index;
      _isAnimating = true;
      _pipProgress = 0.0;
    });
    _routeController.forward(from: 0).then((_) {
      setState(() {
        _isAnimating = false;
        _visited.add(index);
      });
      widget.audioService.playChime();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DreamState>();
    final isNight = state.isNightMode;
    final size = MediaQuery.of(context).size;

    return StarfieldBackground(
      isNight: isNight,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            children: [
              _SceneLabel(
                isNight: isNight,
                label: "Scene 5 · Dream Delivery Routes",
              ),
              const SizedBox(height: 30),

              // Map area
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: _DreamMap(
                    destinations: _destinations,
                    activeDestination: _activeDestination,
                    pipProgress: _pipProgress,
                    isNight: isNight,
                    visited: _visited,
                    onDestinationTap: _selectDestination,
                    starHidden:
                        _activeDestination == 2 &&
                        !_isAnimating &&
                        _visited.contains(2) &&
                        !state.hasStar(2),
                    onStarCollected: () {
                      state.collectStar(2);
                      widget.audioService.playStarSound();
                      widget.audioService.playVoice(PipVoiceLine.encouragement);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: PipColors.goldenGlow,
                          content: Text(
                            "🌟 All three stars found! The Secret Dream Room awaits!",
                            style: GoogleFonts.nunito(
                              color: PipColors.nightBg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Dream description card
              if (_activeDestination != null && !_isAnimating)
                Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: _DreamCard(
                          destination: _destinations[_activeDestination!],
                          isNight: isNight,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, duration: 400.ms),

              const SizedBox(height: 28),

              // Dialogue
              if (!_dialogueDone)
                Center(
                  child: DialogueBubble(
                    lines: _pipLines,
                    isNight: isNight,
                    onComplete: () => setState(() => _dialogueDone = true),
                  ),
                ).animate().fadeIn(delay: 300.ms),

              if (_dialogueDone && _visited.length >= 3) ...[
                const SizedBox(height: 16),
                Center(
                  child: _NextButton(
                    isNight: isNight,
                    label: "Hear Pip's Origin Story →",
                    onPressed: widget.onNext,
                  ),
                ).animate().fadeIn(duration: 500.ms),
              ] else if (_dialogueDone) ...[
                const SizedBox(height: 12),
                Text(
                  "Tap a destination to deliver a dream! (${_visited.length}/3 delivered)",
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: isNight
                        ? PipColors.lavender
                        : PipColors.brown.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ).animate().fadeIn(),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destination {
  final String name;
  final String emoji;
  final String dream;
  final Offset position; // normalized 0..1
  final bool hasStar;

  const _Destination({
    required this.name,
    required this.emoji,
    required this.dream,
    required this.position,
    this.hasStar = false,
  });
}

class _DreamMap extends StatelessWidget {
  final List<_Destination> destinations;
  final int? activeDestination;
  final double pipProgress;
  final bool isNight;
  final Set<int> visited;
  final void Function(int) onDestinationTap;
  final bool starHidden;
  final VoidCallback onStarCollected;

  const _DreamMap({
    required this.destinations,
    required this.activeDestination,
    required this.pipProgress,
    required this.isNight,
    required this.visited,
    required this.onDestinationTap,
    required this.starHidden,
    required this.onStarCollected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isNight
              ? [const Color(0xFF1A1428), PipColors.nightCard]
              : [const Color(0xFFE8F4FD), const Color(0xFFF0F8E8)],
        ),
        border: Border.all(
          color: isNight
              ? PipColors.goldenGlow.withOpacity(0.3)
              : PipColors.berryPink.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isNight
                ? PipColors.goldenGlow.withOpacity(0.1)
                : PipColors.berryPink.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            // Pip starts from bottom-left
            final pipStart = Offset(0.05 * w, 0.85 * h);

            return Stack(
              children: [
                // Map background painter
                CustomPaint(
                  painter: _MapPainter(
                    destinations: destinations,
                    activeDestination: activeDestination,
                    pipProgress: pipProgress,
                    isNight: isNight,
                    visited: visited,
                    pipStart: pipStart,
                  ),
                  child: const SizedBox.expand(),
                ),

                // Destination tap targets
                for (int i = 0; i < destinations.length; i++)
                  Positioned(
                    left: destinations[i].position.dx * w - 30,
                    top: destinations[i].position.dy * h - 30,
                    child: _DestinationPin(
                      destination: destinations[i],
                      isNight: isNight,
                      isActive: activeDestination == i,
                      isVisited: visited.contains(i),
                      onTap: () => onDestinationTap(i),
                    ),
                  ),

                // Pip avatar
                if (activeDestination != null)
                  _PipDeliveryAvatar(
                    start: pipStart,
                    end: Offset(
                      destinations[activeDestination!].position.dx * w,
                      destinations[activeDestination!].position.dy * h,
                    ),
                    progress: pipProgress,
                    isNight: isNight,
                  ),

                // Hidden star 3
                if (starHidden && activeDestination == 2)
                  Positioned(
                    left: destinations[2].position.dx * w + 10,
                    top: destinations[2].position.dy * h - 40,
                    child: HiddenStarWidget(
                      starIndex: 2,
                      isCollected: false,
                      onCollected: onStarCollected,
                    ),
                  ),

                // Pip start indicator
                Positioned(
                  left: pipStart.dx - 18,
                  top: pipStart.dy - 18,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isNight ? PipColors.nightCard : Colors.white,
                      border: Border.all(color: PipColors.goldenGlow, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: PipColors.goldenGlow.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/pip_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('💀', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final List<_Destination> destinations;
  final int? activeDestination;
  final double pipProgress;
  final bool isNight;
  final Set<int> visited;
  final Offset pipStart;

  const _MapPainter({
    required this.destinations,
    required this.activeDestination,
    required this.pipProgress,
    required this.isNight,
    required this.visited,
    required this.pipStart,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle rooftop grid
    final roofPaint = Paint()
      ..color = (isNight ? Colors.white : PipColors.brown).withOpacity(0.06)
      ..style = PaintingStyle.fill;

    final random = Random(99);
    for (int i = 0; i < 12; i++) {
      final x = random.nextDouble() * size.width;
      final y = size.height * 0.5 + random.nextDouble() * size.height * 0.5;
      final w = 30 + random.nextDouble() * 40;
      canvas.drawRect(Rect.fromLTWH(x, y, w, 22), roofPaint);
      // Tiny roof
      final path = Path()
        ..moveTo(x - 4, y)
        ..lineTo(x + w / 2, y - 14)
        ..lineTo(x + w + 4, y)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = (isNight ? Colors.white : PipColors.brown).withOpacity(
            0.08,
          ),
      );
    }

    // Draw routes (dotted paths)
    for (int i = 0; i < destinations.length; i++) {
      final dest = destinations[i];
      final end = Offset(
        dest.position.dx * size.width,
        dest.position.dy * size.height,
      );

      final isActive = activeDestination == i;
      final isVisited = visited.contains(i);

      if (isActive || isVisited) {
        final routePaint = Paint()
          ..color = isActive
              ? PipColors.goldenGlow.withOpacity(isActive ? 0.9 : 0.4)
              : dest.hasStar
              ? PipColors.goldenGlow.withOpacity(0.5)
              : PipColors.lavender.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 3.0 : 2.0
          ..strokeCap = StrokeCap.round;

        if (isActive) {
          // Animated partial route
          final animPath = Path()..moveTo(pipStart.dx, pipStart.dy);
          final x = pipStart.dx + (end.dx - pipStart.dx) * pipProgress;
          final y = pipStart.dy + (end.dy - pipStart.dy) * pipProgress;
          animPath.lineTo(x, y);
          canvas.drawPath(animPath, routePaint);
        } else {
          // Dashed full route
          _drawDashedLine(canvas, pipStart, end, routePaint);
        }
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = sqrt(dx * dx + dy * dy);
    final dashLen = 8.0;
    final gapLen = 6.0;
    final steps = dist / (dashLen + gapLen);

    for (int i = 0; i < steps; i++) {
      final t0 = i * (dashLen + gapLen) / dist;
      final t1 = (i * (dashLen + gapLen) + dashLen) / dist;
      canvas.drawLine(
        Offset(start.dx + dx * t0, start.dy + dy * t0),
        Offset(start.dx + dx * t1.clamp(0, 1), start.dy + dy * t1.clamp(0, 1)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.pipProgress != pipProgress ||
      old.activeDestination != activeDestination ||
      old.visited != visited;
}

class _DestinationPin extends StatefulWidget {
  final _Destination destination;
  final bool isNight;
  final bool isActive;
  final bool isVisited;
  final VoidCallback onTap;

  const _DestinationPin({
    required this.destination,
    required this.isNight,
    required this.isActive,
    required this.isVisited,
    required this.onTap,
  });

  @override
  State<_DestinationPin> createState() => _DestinationPinState();
}

class _DestinationPinState extends State<_DestinationPin> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive || _hovered;
    final accentColor = widget.destination.hasStar
        ? PipColors.goldenGlow
        : PipColors.lavender;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || widget.isVisited
                ? accentColor.withOpacity(0.25)
                : (widget.isNight ? PipColors.nightCard : Colors.white)
                      .withOpacity(0.8),
            border: Border.all(
              color: isActive ? accentColor : accentColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              widget.destination.emoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),
        ),
      ),
    );
  }
}

class _PipDeliveryAvatar extends StatelessWidget {
  final Offset start;
  final Offset end;
  final double progress;
  final bool isNight;

  const _PipDeliveryAvatar({
    required this.start,
    required this.end,
    required this.progress,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    final x = start.dx + (end.dx - start.dx) * progress;
    final y = start.dy + (end.dy - start.dy) * progress;

    return Positioned(
      left: x - 20,
      top: y - 20,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isNight ? PipColors.nightCard : Colors.white,
          border: Border.all(color: PipColors.goldenGlow, width: 2),
          boxShadow: [
            BoxShadow(
              color: PipColors.goldenGlow.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Center(child: Text('☁️', style: TextStyle(fontSize: 20))),
      ),
    );
  }
}

class _DreamCard extends StatelessWidget {
  final _Destination destination;
  final bool isNight;

  const _DreamCard({required this.destination, required this.isNight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isNight
            ? PipColors.nightCard.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: destination.hasStar
              ? PipColors.goldenGlow.withOpacity(0.5)
              : PipColors.lavender.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PipColors.goldenGlow.withOpacity(0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(destination.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: destination.hasStar
                          ? PipColors.goldenGlow
                          : (isNight ? Colors.white : PipColors.berryPink),
                    ),
                  ),
                  Text(
                    "Dream Delivery ✓",
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: isNight
                          ? PipColors.lavender
                          : PipColors.brown.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            destination.dream,
            style: GoogleFonts.nunito(
              fontSize: 14,
              height: 1.6,
              color: isNight
                  ? Colors.white70
                  : PipColors.brown.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable label and button
class _SceneLabel extends StatelessWidget {
  final bool isNight;
  final String label;
  const _SceneLabel({required this.isNight, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isNight
            ? PipColors.goldenGlow.withOpacity(0.15)
            : PipColors.berryPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isNight ? PipColors.goldenGlow : PipColors.berryPink,
          letterSpacing: 0.5,
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
}

class _NextButton extends StatefulWidget {
  final bool isNight;
  final String label;
  final VoidCallback onPressed;
  const _NextButton({
    required this.isNight,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isNight
        ? PipColors.goldenGlow
        : PipColors.berryPink;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: widget.isNight ? PipColors.nightBg : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
