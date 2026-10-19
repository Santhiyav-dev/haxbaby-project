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

class NightlightCollectionScene extends StatefulWidget {
  final VoidCallback onNext;
  final AudioService audioService;
  const NightlightCollectionScene({
    super.key,
    required this.onNext,
    required this.audioService,
  });

  @override
  State<NightlightCollectionScene> createState() =>
      _NightlightCollectionSceneState();
}

class _NightlightCollectionSceneState extends State<NightlightCollectionScene> {
  int _selectedLight = 0;
  bool _dialogueDone = false;

  final List<_NightLight> _lights = [
    _NightLight(
      emoji: '🌙',
      name: 'Silver Moon',
      color: const Color(0xFFB8D4FF),
      glow: const Color(0xFF6699FF),
      description:
          "A gentle silver glow for dreamers who like to count the stars. "
          "It hums very softly, just above the level of silence.",
    ),
    _NightLight(
      emoji: '⭐',
      name: 'Golden Dream',
      color: const Color(0xFFFFE566),
      glow: const Color(0xFFFFC96B),
      description:
          "Pip's favourite. The warmest glow in the collection — "
          "the one Pip made first, using that little fallen star.",
      hasStar: true,
    ),
    _NightLight(
      emoji: '🌿',
      name: 'Meadow Mist',
      color: const Color(0xFF7FDBCA),
      glow: const Color(0xFF44BBAA),
      description:
          "A cool mint light for adventurous dreamers. "
          "Pip says it smells faintly of damp grass and the start of a story.",
    ),
    _NightLight(
      emoji: '🌸',
      name: 'Petal Blush',
      color: const Color(0xFFFFB4D1),
      glow: const Color(0xFFFF6699),
      description:
          "The softest light, made for the little ones. "
          "Pip tested it on a tiny cloud rabbit and it fell asleep immediately.",
    ),
    _NightLight(
      emoji: '🔮',
      name: 'Dream Iris',
      color: const Color(0xFFCCA8E8),
      glow: const Color(0xFF9933CC),
      description:
          "A deep violet for the most vivid dreamers. "
          "Pip is a little afraid of this one — it makes the dreams too interesting.",
    ),
  ];

  final List<String> _pipLines = [
    "Sometimes even dreams need a tiny light. 🌙",
    "I made these little nightlights for dreamers afraid of the dark.",
    "Which little light would you choose?",
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DreamState>();
    final isNight = state.isNightMode;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final selectedLight = _lights[_selectedLight];

    return StarfieldBackground(
      isNight: isNight,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            children: [
              _SceneLabel(
                isNight: isNight,
                label: "Scene 4 · Nightlight Collection",
              ),
              const SizedBox(height: 30),

              // Main lantern display
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _LanternDisplay(
                    light: selectedLight,
                    isNight: isNight,
                    starHidden: selectedLight.hasStar && !state.hasStar(1),
                    onStarCollected: () {
                      state.collectStar(1);
                      widget.audioService.playStarSound();
                      widget.audioService.playVoice(PipVoiceLine.encouragement);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: PipColors.goldenGlow,
                          content: Text(
                            "✨ One more tiny mystery solved! (2/3)",
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
              ),

              const SizedBox(height: 28),

              // Light selector row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _lights.length; i++)
                      _LightButton(
                        light: _lights[i],
                        isSelected: i == _selectedLight,
                        isNight: isNight,
                        onTap: () {
                          setState(() => _selectedLight = i);
                          widget.audioService.playChime();
                        },
                      ),
                  ],
                ),
              ),

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

              if (_dialogueDone) ...[
                const SizedBox(height: 16),
                Center(
                  child: _NextButton(
                    isNight: isNight,
                    label: "See Dream Delivery Routes →",
                    onPressed: widget.onNext,
                  ),
                ).animate().fadeIn(duration: 500.ms),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _NightLight {
  final String emoji;
  final String name;
  final Color color;
  final Color glow;
  final String description;
  final bool hasStar;

  const _NightLight({
    required this.emoji,
    required this.name,
    required this.color,
    required this.glow,
    required this.description,
    this.hasStar = false,
  });
}

class _LanternDisplay extends StatelessWidget {
  final _NightLight light;
  final bool isNight;
  final bool starHidden;
  final VoidCallback onStarCollected;

  const _LanternDisplay({
    required this.light,
    required this.isNight,
    required this.starHidden,
    required this.onStarCollected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isNight
                  ? [PipColors.nightCard, PipColors.nightBg]
                  : [Colors.white, PipColors.cream],
            ),
            border: Border.all(color: light.glow.withOpacity(0.7), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: light.glow.withOpacity(0.4),
                blurRadius: 50,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: light.glow.withOpacity(0.2),
                blurRadius: 100,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              // Lantern image with color tint
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                child: SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/pip_dream_lantern.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _LanternPlaceholder(light: light),
                      ),
                      // Animated color overlay
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        color: light.glow.withOpacity(0.3),
                      ),
                      // Glow pulse in centre
                      Center(
                        child:
                            AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: light.glow.withOpacity(0.25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: light.glow.withOpacity(0.5),
                                        blurRadius: 60,
                                        spreadRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      light.emoji,
                                      style: const TextStyle(fontSize: 52),
                                    ),
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                  begin: const Offset(0.9, 0.9),
                                  end: const Offset(1.1, 1.1),
                                  duration: 2000.ms,
                                ),
                      ),
                    ],
                  ),
                ),
              ),

              // Description card
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        key: ValueKey(light.name),
                        light.name,
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: light.glow,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        key: ValueKey(light.description),
                        light.description,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          height: 1.6,
                          color: isNight
                              ? Colors.white.withOpacity(0.8)
                              : PipColors.brown.withOpacity(0.8),
                        ),
                      ),
                    ),
                    if (light.hasStar && !starHidden) ...[
                      const SizedBox(height: 8),
                      Text(
                        "✨ You found the golden dream light!",
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: PipColors.goldenGlow,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Hidden star 2 — only on golden glow light
        if (starHidden)
          Positioned(
            top: 20,
            right: 20,
            child: HiddenStarWidget(
              starIndex: 1,
              isCollected: false,
              onCollected: onStarCollected,
            ),
          ),
      ],
    );
  }
}

class _LanternPlaceholder extends StatelessWidget {
  final _NightLight light;
  const _LanternPlaceholder({required this.light});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      color: light.color.withOpacity(0.3),
      child: Center(
        child: Text(light.emoji, style: const TextStyle(fontSize: 100)),
      ),
    );
  }
}

class _LightButton extends StatefulWidget {
  final _NightLight light;
  final bool isSelected;
  final bool isNight;
  final VoidCallback onTap;

  const _LightButton({
    required this.light,
    required this.isSelected,
    required this.isNight,
    required this.onTap,
  });

  @override
  State<_LightButton> createState() => _LightButtonState();
}

class _LightButtonState extends State<_LightButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? widget.light.glow.withOpacity(0.3)
                : (widget.isNight
                      ? PipColors.nightCard
                      : Colors.white.withOpacity(0.8)),
            border: Border.all(
              color: isActive ? widget.light.glow : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: widget.light.glow.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              widget.light.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
      ),
    );
  }
}

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
            elevation: _hovered ? 12 : 6,
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
