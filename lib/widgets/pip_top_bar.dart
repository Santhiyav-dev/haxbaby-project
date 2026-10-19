import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Top bar with theme toggle, sound toggle and star counter.
class PipTopBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isNight;
  final bool soundEnabled;
  final int starsFound;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleSound;

  const PipTopBar({
    super.key,
    required this.isNight,
    required this.soundEnabled,
    required this.starsFound,
    required this.onToggleTheme,
    required this.onToggleSound,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final bg = isNight
        ? PipColors.nightCard.withOpacity(0.95)
        : Colors.white.withOpacity(0.95);
    final textColor = isNight ? Colors.white : PipColors.brown;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(
            color: isNight
                ? PipColors.goldenGlow.withOpacity(0.2)
                : PipColors.softPink.withOpacity(0.8),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Logo
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: PipColors.goldenGlow,
                    size: 22,
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2000.ms),
                  const SizedBox(width: 8),
                  Text(
                    "Pip's Dream World",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isNight ? PipColors.goldenGlow : PipColors.berryPink,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Star counter
              _StarPill(found: starsFound, isNight: isNight),
              const SizedBox(width: 10),
              // Sound toggle
              Semantics(
                label: soundEnabled ? 'Sound on' : 'Sound off',
                button: true,
                child: IconButton(
                  onPressed: onToggleSound,
                  icon: Icon(
                    soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: textColor.withOpacity(0.8),
                  ),
                  tooltip: soundEnabled ? 'Sound on' : 'Sound off',
                ),
              ),
              // Theme toggle
              Semantics(
                label: isNight ? 'Switch to day mode' : 'Switch to night mode',
                button: true,
                child: IconButton(
                  onPressed: onToggleTheme,
                  icon: Icon(
                    isNight ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                    color: isNight ? PipColors.goldenGlow : PipColors.brown,
                  ),
                  tooltip: isNight ? 'Day mode' : 'Night mode',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarPill extends StatelessWidget {
  final int found;
  final bool isNight;

  const _StarPill({required this.found, required this.isNight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isNight
            ? PipColors.goldenGlow.withOpacity(0.15)
            : PipColors.softPink.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PipColors.goldenGlow.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 3; i++)
            Icon(
              Icons.star,
              size: 14,
              color: i < found
                  ? PipColors.goldenGlow
                  : Colors.grey.withOpacity(0.35),
            ),
          const SizedBox(width: 4),
          Text(
            '$found/3',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isNight ? PipColors.goldenGlow : PipColors.brown,
            ),
          ),
        ],
      ),
    );
  }
}
