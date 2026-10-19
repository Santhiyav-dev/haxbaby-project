import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../state/dream_state.dart';
import '../theme/app_theme.dart';
import '../widgets/starfield_background.dart';

class SecretDreamRoomScene extends StatefulWidget {
  final VoidCallback onContinue;
  const SecretDreamRoomScene({super.key, required this.onContinue});

  @override
  State<SecretDreamRoomScene> createState() => _SecretDreamRoomSceneState();
}

class _SecretDreamRoomSceneState extends State<SecretDreamRoomScene>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 6),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Start confetti after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DreamState>();
    final isNight = state.isNightMode;

    return Stack(
      children: [
        // Background
        StarfieldBackground(
          isNight: true, // always night in secret room
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: [
                  // Stars confetti
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < 3; i++)
                          Icon(
                            Icons.star,
                            color: PipColors.goldenGlow,
                            size: 36,
                          )
                              .animate(delay: Duration(milliseconds: i * 150))
                              .scale(
                                duration: 600.ms,
                                curve: Curves.elasticOut,
                                begin: const Offset(0, 0),
                                end: const Offset(1, 1),
                              )
                              .shimmer(duration: 2000.ms, color: Colors.white),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Title
                  Text(
                    "✨ Secret Dream Room ✨",
                    style: GoogleFonts.nunito(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: PipColors.goldenGlow,
                      shadows: [
                        Shadow(
                          color: PipColors.goldenGlow.withOpacity(0.6),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 800.ms)
                      .scale(begin: const Offset(0.7, 0.7)),

                  const SizedBox(height: 40),

                  // Main content card
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: _SecretRoomCard(glowController: _glowController),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Message from Pip
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: _PipSecretMessage(),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Continue button
                  ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PipColors.goldenGlow,
                      foregroundColor: PipColors.nightBg,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36),
                      ),
                      elevation: 12,
                      shadowColor: PipColors.goldenGlow.withOpacity(0.6),
                    ),
                    child: Text(
                      "Continue the Journey →",
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1200.ms, duration: 600.ms)
                      .scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),

        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.07,
            numberOfParticles: 25,
            gravity: 0.08,
            colors: [
              PipColors.goldenGlow,
              PipColors.berryPink,
              PipColors.lavender,
              PipColors.mintGlow,
              PipColors.starYellow,
              Colors.white,
            ],
            child: const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _SecretRoomCard extends StatelessWidget {
  final AnimationController glowController;
  const _SecretRoomCard({required this.glowController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowController,
      builder: (context, child) {
        final glow = 0.3 + glowController.value * 0.4;

        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A1F4A),
                Color(0xFF1A1228),
              ],
            ),
            border: Border.all(
              color: PipColors.goldenGlow.withOpacity(glow),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: PipColors.goldenGlow.withOpacity(glow * 0.6),
                blurRadius: 60,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: PipColors.berryPink.withOpacity(glow * 0.3),
                blurRadius: 100,
                spreadRadius: 20,
              ),
            ],
          ),
          child: child!,
        );
      },
      child: Column(
        children: [
          // Three golden stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PipColors.goldenGlow.withOpacity(0.2),
                          border: Border.all(
                            color: PipColors.goldenGlow.withOpacity(0.7),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: PipColors.goldenGlow.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.star,
                            color: PipColors.goldenGlow,
                            size: 36,
                          ),
                        ),
                      )
                          .animate(delay: Duration(milliseconds: i * 200))
                          .scale(
                            duration: 800.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(0.3, 0.3),
                          )
                          .shimmer(delay: Duration(milliseconds: i * 300)),
                      const SizedBox(height: 8),
                      Text(
                        ["Star 1", "Star 2", "Star 3"][i],
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: PipColors.goldenGlow.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 28),

          Text(
            "All Three Dream Stars ✓",
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: PipColors.goldenGlow,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "You discovered every little star Pip hid across the Dream World. "
            "The Lullaby Lab star. The Golden Nightlight star. "
            "The Starfall Bay star. Pip is so proud.",
            style: GoogleFonts.nunito(
              fontSize: 15,
              height: 1.7,
              color: Colors.white.withOpacity(0.85),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 800.ms);
  }
}

class _PipSecretMessage extends StatelessWidget {
  const _PipSecretMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: PipColors.nightCard.withOpacity(0.8),
        border: Border.all(
          color: PipColors.berryPink.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('💀', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Text(
                "A Message from Pip",
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: PipColors.goldenGlow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            "You found every little star!",
            "I was saving this tiny secret just for you.",
            "Thank you for helping me put the light back into my dreams.",
          ].asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '"${e.value}"',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 700 + e.key * 200),
                        duration: 500.ms,
                      ),
                ),
              ),
        ],
      ),
    ).animate().fadeIn(delay: 900.ms, duration: 600.ms);
  }
}
