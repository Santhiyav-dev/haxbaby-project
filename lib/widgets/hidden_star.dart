import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// A floating, sparkly star widget that can be hidden and revealed.
class HiddenStarWidget extends StatefulWidget {
  final int starIndex;
  final VoidCallback onCollected;
  final bool isCollected;

  const HiddenStarWidget({
    super.key,
    required this.starIndex,
    required this.onCollected,
    required this.isCollected,
  });

  @override
  State<HiddenStarWidget> createState() => _HiddenStarWidgetState();
}

class _HiddenStarWidgetState extends State<HiddenStarWidget> {
  bool _sparkleVisible = false;
  bool _collected = false;

  @override
  void initState() {
    super.initState();
    _collected = widget.isCollected;
  }

  @override
  Widget build(BuildContext context) {
    if (_collected || widget.isCollected) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _sparkleVisible = true;
          _collected = true;
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          widget.onCollected();
        });
      },
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PipColors.goldenGlow.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: PipColors.goldenGlow.withOpacity(0.6),
                    blurRadius: 14,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.star,
              color: PipColors.goldenGlow,
              size: 28,
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1800.ms, color: Colors.white)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.1, 1.1),
                  duration: 900.ms,
                )
                .then()
                .scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(0.9, 0.9),
                  duration: 900.ms,
                ),
            if (_sparkleVisible)
              ..._buildSparkles(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSparkles() {
    return [
      for (int i = 0; i < 6; i++)
        Positioned(
          top: (i % 3) * 14.0,
          left: (i % 2) * 14.0,
          child: const Icon(
            Icons.auto_awesome,
            color: PipColors.starYellow,
            size: 10,
          )
              .animate()
              .scale(duration: 400.ms)
              .fadeOut(delay: 300.ms),
        ),
    ];
  }
}

// ─── Star Counter HUD ────────────────────────────────────────────────────────

class StarCounterHUD extends StatelessWidget {
  final int found;
  final int total;
  final bool isNight;

  const StarCounterHUD({
    super.key,
    required this.found,
    required this.total,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isNight
            ? PipColors.nightCard.withOpacity(0.9)
            : PipColors.cream.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PipColors.goldenGlow.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PipColors.goldenGlow.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < total; i++) ...[
            Icon(
              Icons.star,
              size: 18,
              color: i < found ? PipColors.goldenGlow : Colors.grey.withOpacity(0.4),
            )
                .animate(target: i < found ? 1.0 : 0.0)
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0)),
            if (i < total - 1) const SizedBox(width: 4),
          ],
          const SizedBox(width: 8),
          Text(
            '$found of $total',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isNight ? PipColors.goldenGlow : PipColors.brown,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}
