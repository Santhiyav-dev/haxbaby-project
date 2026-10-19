import 'dart:math' show min;

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

class LullabyLabScene extends StatefulWidget {
  final VoidCallback onNext;
  final AudioService audioService;

  const LullabyLabScene({
    super.key,
    required this.onNext,
    required this.audioService,
  });

  @override
  State<LullabyLabScene> createState() => _LullabyLabSceneState();
}

class _LullabyLabSceneState extends State<LullabyLabScene>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _dialogueDone = false;
  bool _hasPlayed = false;
  bool _starVisible = false;

  late AnimationController _noteController;

  final List<String> _pipLines = [
    "Shhh... listen! 🎵",
    "I made this little lullaby to help sleepy dreams find their way.",
    "Do you want to hear it? Tap the music box to wind it up!",
  ];

  @override
  void initState() {
    super.initState();

    _noteController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    widget.audioService.stopLullaby();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      setState(() => _isPlaying = false);
      await widget.audioService.pauseLullaby();
      _noteController.stop();
      _noteController.reset();
    } else {
      final shouldResume = widget.audioService.isLullabyPlaying == false &&
          _hasPlayed;
      setState(() {
        _isPlaying = true;
        _hasPlayed = true;
        _starVisible = true;
      });

      if (shouldResume) {
        await widget.audioService.resumeLullaby();
      } else {
        await widget.audioService.playLullaby();
      }
      _noteController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DreamState>();
    final isNight = state.isNightMode;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return StarfieldBackground(
      isNight: isNight,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 40,
            horizontal: isMobile ? 16 : 24,
          ),
          child: Column(
            children: [
              _SceneLabelInline(
                isNight: isNight,
                label: "Scene 3 · Lullaby Lab",
              ),

              const SizedBox(height: 30),

              // Music box image card
              LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: min(840, constraints.maxWidth),
                      ),
                      child: _MusicBoxCard(
                        isNight: isNight,
                        isPlaying: _isPlaying,
                        noteController: _noteController,
                        onTogglePlay: _togglePlay,
                        starVisible: _starVisible && !state.hasStar(0),
                        onStarCollected: () {
                      state.collectStar(0);
                      widget.audioService.playStarSound();
                      widget.audioService.playVoice(
                        PipVoiceLine.encouragement,
                      );

                      setState(() => _starVisible = false);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: PipColors.goldenGlow,
                          content: Text(
                            "✨ Oh! You found a little dream star! (1/3)",
                            style: GoogleFonts.nunito(
                              color: PipColors.nightBg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                        },
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Lullaby information card
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: _LullabyInfoCard(
                    isNight: isNight,
                    isPlaying: _isPlaying,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Pip dialogue
              if (!_dialogueDone)
                Center(
                  child: DialogueBubble(
                    lines: _pipLines,
                    isNight: isNight,
                    onComplete: () {
                      setState(() => _dialogueDone = true);
                    },
                  ),
                ).animate().fadeIn(delay: 300.ms),

              // Continue button
              if (_dialogueDone && _hasPlayed) ...[
                const SizedBox(height: 16),
                Center(
                  child: _NextButtonInline(
                    isNight: isNight,
                    label: "See the Nightlight Collection →",
                    onPressed: widget.onNext,
                  ),
                ).animate().fadeIn(duration: 500.ms),
              ] else if (_dialogueDone && !_hasPlayed) ...[
                const SizedBox(height: 16),
                Text(
                  "🎵 Wind up the music box to continue!",
                  textAlign: TextAlign.center,
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

// --------------------------------------------------
// MUSIC BOX IMAGE CARD
// --------------------------------------------------

class _MusicBoxCard extends StatefulWidget {
  final bool isNight;
  final bool isPlaying;
  final AnimationController noteController;
  final VoidCallback onTogglePlay;
  final bool starVisible;
  final VoidCallback onStarCollected;

  const _MusicBoxCard({
    required this.isNight,
    required this.isPlaying,
    required this.noteController,
    required this.onTogglePlay,
    required this.starVisible,
    required this.onStarCollected,
  });

  @override
  State<_MusicBoxCard> createState() => _MusicBoxCardState();
}

class _MusicBoxCardState extends State<_MusicBoxCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/music_box_1.png'), context);
  }

  @override
  void didUpdateWidget(_MusicBoxCard oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isNight
        ? PipColors.goldenGlow
        : PipColors.berryPink;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main card
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isNight
                  ? [PipColors.nightCard, const Color(0xFF1A1428)]
                  : [Colors.white, PipColors.softPink.withOpacity(0.5)],
            ),
            border: Border.all(
              color: widget.isPlaying
                  ? accentColor.withOpacity(0.9)
                  : accentColor.withOpacity(0.4),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(widget.isPlaying ? 0.4 : 0.15),
                blurRadius: widget.isPlaying ? 40 : 20,
                spreadRadius: widget.isPlaying ? 8 : 3,
              ),
            ],
          ),
          child: Column(
            children: [
              // Unicorn & Music Box Animation section
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
                child: SizedBox(
                  height: 450,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/music_box_1.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) =>
                              _MusicBoxPlaceholder(isNight: widget.isNight),
                        ),
                      ),

                      // Soft glow while playing
                      if (widget.isPlaying)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                PipColors.goldenGlow.withOpacity(0.25),
                                Colors.transparent,
                                PipColors.goldenGlow.withOpacity(0.12),
                              ],
                            ),
                          ),
                        ),

                      // Animated floating music notes
                      if (widget.isPlaying)
                        AnimatedBuilder(
                          animation: widget.noteController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _NotePainter(
                                widget.noteController.value,
                              ),
                              child: const SizedBox.expand(),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Play and pause controls
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: widget.onTogglePlay,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.5),
                              blurRadius: widget.isPlaying ? 24 : 12,
                              spreadRadius: widget.isPlaying ? 6 : 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: widget.isNight
                              ? PipColors.nightBg
                              : Colors.white,
                          size: 40,
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isPlaying ? "♪ Playing..." : "Wind the key!",
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: widget.isNight
                                  ? Colors.white
                                  : PipColors.brown,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Pip's Dream Lullaby",
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Hidden star appears after playing
        if (widget.starVisible)
          Positioned(
            top: 20,
            right: 20,
            child:
                HiddenStarWidget(
                      starIndex: 0,
                      isCollected: false,
                      onCollected: widget.onStarCollected,
                    )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .slideY(begin: 0.5, end: 0, duration: 600.ms),
          ),
      ],
    );
  }
}

// --------------------------------------------------
// FLOATING MUSIC NOTES
// --------------------------------------------------

class _NotePainter extends CustomPainter {
  final double t;

  const _NotePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const notes = ['♪', '♫', '♩', '♬'];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 8; i++) {
      final phase = (t + i / 8) % 1.0;
      final x = (0.1 + (i % 4) * 0.22) * size.width;
      final y = size.height * (1 - phase * 1.2);
      final opacity = (1 - phase).clamp(0.0, 1.0) * 0.8;

      if (opacity <= 0) continue;

      textPainter.text = TextSpan(
        text: notes[i % notes.length],
        style: TextStyle(
          fontSize: 22,
          color: PipColors.goldenGlow.withOpacity(opacity),
        ),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(_NotePainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

// --------------------------------------------------
// FALLBACK IMAGE PLACEHOLDER
// --------------------------------------------------

class _MusicBoxPlaceholder extends StatelessWidget {
  final bool isNight;

  const _MusicBoxPlaceholder({required this.isNight});

  @override
  Widget build(BuildContext context) {
    final color = isNight ? PipColors.goldenGlow : PipColors.berryPink;

    return Container(
      color: isNight ? PipColors.nightCard : PipColors.softPink,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_rounded,
              size: 80,
              color: color.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            Text(
              "Pip's Music Box",
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// LULLABY INFORMATION CARD
// --------------------------------------------------

class _LullabyInfoCard extends StatelessWidget {
  final bool isNight;
  final bool isPlaying;

  const _LullabyInfoCard({required this.isNight, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    final accentColor = isNight ? PipColors.goldenGlow : PipColors.berryPink;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isNight
            ? PipColors.nightCard.withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNight
              ? PipColors.lavender.withOpacity(0.3)
              : PipColors.softPink.withOpacity(0.8),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note_rounded, color: accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "About this Lullaby",
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            "Pip composed this gentle melody after discovering that dreams "
            "travel best when guided by a soft, familiar sound. It loops "
            "slowly, like a lullaby should — never in a hurry, always warm.",
            style: GoogleFonts.nunito(
              fontSize: 15,
              height: 1.6,
              color: isNight
                  ? Colors.white70
                  : PipColors.brown.withOpacity(0.8),
            ),
          ),

          if (isPlaying) ...[
            const SizedBox(height: 12),
            Text(
              "✨ Pip says: Listen carefully — there might be a little "
              "star hiding in the music!",
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: accentColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// --------------------------------------------------
// SCENE LABEL
// --------------------------------------------------

class _SceneLabelInline extends StatelessWidget {
  final bool isNight;
  final String label;

  const _SceneLabelInline({required this.isNight, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isNight
            ? PipColors.goldenGlow.withOpacity(0.15)
            : PipColors.berryPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: isNight ? PipColors.goldenGlow : PipColors.berryPink,
          letterSpacing: 0.5,
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
}

// --------------------------------------------------
// NEXT BUTTON
// --------------------------------------------------

class _NextButtonInline extends StatefulWidget {
  final bool isNight;
  final String label;
  final VoidCallback onPressed;

  const _NextButtonInline({
    required this.isNight,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_NextButtonInline> createState() => _NextButtonInlineState();
}

class _NextButtonInlineState extends State<_NextButtonInline> {
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
            elevation: _hovered ? 12 : 6,
            shadowColor: accentColor.withOpacity(0.5),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
