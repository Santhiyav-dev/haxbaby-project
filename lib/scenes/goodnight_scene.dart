import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/dream_state.dart';
import '../theme/app_theme.dart';
import '../widgets/starfield_background.dart';

class GoodnightScene extends StatefulWidget {
  final VoidCallback onReplay;
  const GoodnightScene({super.key, required this.onReplay});

  @override
  State<GoodnightScene> createState() => _GoodnightSceneState();
}

class _GoodnightSceneState extends State<GoodnightScene>
    with SingleTickerProviderStateMixin {
  late AnimationController _dimController;
  bool _showCredits = false;

  @override
  void initState() {
    super.initState();
    _dimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
  }

  @override
  void dispose() {
    _dimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DreamState>();
    final isNight = state.isNightMode;

    return StarfieldBackground(
      isNight: true,
      child: _showCredits
          ? _CreditsPanel(
              isNight: isNight,
              onBack: () => setState(() => _showCredits = false),
            )
          : _GoodnightContent(
              dimController: _dimController,
              onReplay: widget.onReplay,
              onCredits: () => setState(() => _showCredits = true),
              isNight: isNight,
            ),
    );
  }
}

class _GoodnightContent extends StatelessWidget {
  final AnimationController dimController;
  final VoidCallback onReplay;
  final VoidCallback onCredits;
  final bool isNight;

  const _GoodnightContent({
    required this.dimController,
    required this.onReplay,
    required this.onCredits,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sleeping Pip
            _SleepingPip().animate().fadeIn(delay: 400.ms, duration: 1000.ms),

            const SizedBox(height: 40),

            // Messages from Pip
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  ...[
                    ("We made some lovely dreams together, didn't we? 🌙", 0),
                    ("Thank you for visiting my little world.", 350),
                    ("Sleep well, little dreamer.", 700),
                    ("I'll keep the stars glowing. ✨", 1050),
                  ].map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child:
                          Text(
                            '"${e.$1}"',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(
                            delay: Duration(milliseconds: 600 + e.$2),
                            duration: 800.ms,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Final tagline
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        PipColors.goldenGlow.withOpacity(0.15),
                        PipColors.berryPink.withOpacity(0.15),
                      ],
                    ),
                    border: Border.all(
                      color: PipColors.goldenGlow.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '"Every dream leaves a little light behind."',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: PipColors.goldenGlow,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
                .animate()
                .fadeIn(delay: 2200.ms, duration: 1000.ms)
                .scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: 50),

            // Action buttons
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                _ActionButton(
                  label: "Replay Journey",
                  icon: Icons.replay_rounded,
                  color: PipColors.goldenGlow,
                  textColor: PipColors.nightBg,
                  onPressed: onReplay,
                  delay: 2800,
                ),
                _ActionButton(
                  label: "Credits",
                  icon: Icons.favorite_rounded,
                  color: PipColors.berryPink,
                  textColor: Colors.white,
                  onPressed: onCredits,
                  delay: 3000,
                ),
              ],
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _SleepingPip extends StatelessWidget {
  const _SleepingPip();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow behind Pip
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: PipColors.goldenGlow.withOpacity(0.2),
                blurRadius: 80,
                spreadRadius: 30,
              ),
            ],
          ),
        ),
        // Pip avatar (now tucked in)
        Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PipColors.nightCard,
                border: Border.all(
                  color: PipColors.goldenGlow.withOpacity(0.4),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/pip_avatar_cloud.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: PipColors.nightCard,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('💀', style: TextStyle(fontSize: 56)),
                          Text(
                            'zzz',
                            style: GoogleFonts.nunito(
                              color: PipColors.lavender,
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.03, 1.03),
              duration: 2500.ms,
              curve: Curves.easeInOut,
            ),

        // Sleeping z's
        ...['z', 'z', 'z'].asMap().entries.map(
          (e) => Positioned(
            top: 20 - e.key * 18.0,
            right: 20 + e.key * 14.0,
            child:
                Text(
                      e.value,
                      style: GoogleFonts.nunito(
                        fontSize: 18 - e.key * 4.0,
                        color: PipColors.lavender.withOpacity(
                          0.7 - e.key * 0.15,
                        ),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                    .animate(delay: Duration(milliseconds: e.key * 400))
                    .then()
                    .moveY(begin: 0, end: -8, duration: 1500.ms)
                    .fadeOut(delay: 1000.ms, duration: 500.ms)
                    .then()
                    .moveY(begin: 0, end: -8, duration: 1500.ms)
                    .fadeOut(delay: 1000.ms, duration: 500.ms),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;
  final int delay;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onPressed,
    required this.delay,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedScale(
            scale: _hovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton.icon(
              onPressed: widget.onPressed,
              icon: Icon(widget.icon, size: 20),
              label: Text(
                widget.label,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: widget.textColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: _hovered ? 14 : 6,
                shadowColor: widget.color.withOpacity(0.5),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: widget.delay),
          duration: 600.ms,
        )
        .scale(begin: const Offset(0.8, 0.8));
  }
}

class _CreditsPanel extends StatelessWidget {
  final bool isNight;
  final VoidCallback onBack;

  const _CreditsPanel({required this.isNight, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final credits = [
      _CreditItem(
        "Pip Artwork",
        "Official haX.baby Pip asset pack\nhttps://hax.baby/baby/assets/\nPip belongs to haX.baby and is used as provided.",
        Icons.image_rounded,
        PipColors.goldenGlow,
        url: "https://hax.baby/baby/assets/",
      ),
      _CreditItem(
        "Story, Design & Code",
        "Santhiya and Chandru.\nThe origin story is original, not official Pip canon.",
        Icons.code_rounded,
        PipColors.berryPink,
      ),
      _CreditItem(
        "Fonts",
        "Nunito — Google Fonts, OFL",
        Icons.text_fields_rounded,
        PipColors.lavender,
      ),
      _CreditItem(
        "Flutter Packages",
        "flutter_animate · google_fonts · audioplayers · confetti · shared_preferences · url_launcher · provider",
        Icons.widgets_rounded,
        PipColors.mintGlow,
      ),
      _CreditItem(
        "AI Assistance",
        "Antigravity AI was used for planning and code help.\nAll code is reviewed and understood by the team.",
        Icons.smart_toy_rounded,
        PipColors.peach,
      ),
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: PipColors.goldenGlow,
                    ),
                    Text(
                      "Credits",
                      style: GoogleFonts.nunito(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: PipColors.goldenGlow,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                ...credits.map(
                  (c) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: PipColors.nightCard.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: c.color.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.color.withOpacity(0.15),
                          ),
                          child: Icon(c.icon, color: c.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.title,
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: c.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.body,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.75),
                                  height: 1.5,
                                ),
                              ),
                              if (c.url != null) ...[
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () async {
                                    final uri = Uri.parse(c.url!);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                  child: Text(
                                    "Open link →",
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: c.color,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  "Made with 💜 for haXbaby Hackathon",
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreditItem {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final String? url;

  const _CreditItem(this.title, this.body, this.icon, this.color, {this.url});
}
