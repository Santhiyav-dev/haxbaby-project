import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/dream_state.dart';
import '../theme/app_theme.dart';
import '../widgets/starfield_background.dart';

class OriginStoryScene extends StatefulWidget {
  final VoidCallback onNext;
  const OriginStoryScene({super.key, required this.onNext});

  @override
  State<OriginStoryScene> createState() => _OriginStorySceneState();
}

class _OriginStorySceneState extends State<OriginStoryScene> {
  final PageController _pageController = PageController();
  int _currentBeat = 0;

  final List<_StoryBeat> _beats = [
    _StoryBeat(
      emoji: "⭐",
      title: "A Little Star Falls",
      body:
          "One quiet night, while Pip was sweeping the nursery steps, something "
          "small and warm fell from the sky. It landed right at Pip's feet — "
          "a little star that had lost its way home.",
      pipSays: "I found a little star that had lost its way.",
      accentColor: PipColors.goldenGlow,
    ),
    _StoryBeat(
      emoji: "🔍",
      title: "A Curious Glow",
      body:
          "Pip picked the star up very carefully. It sat in both hands — "
          "heavy and warm and glowing the softest gold. "
          "Pip had never seen anything like it. It looked... lonely.",
      pipSays: "It looked so lonely... so I decided to help.",
      accentColor: PipColors.starYellow,
    ),
    _StoryBeat(
      emoji: "💡",
      title: "The Big Idea",
      body:
          "Pip stayed up all night, turning the star over and over, "
          "watching how its glow changed. That's when the idea arrived — "
          "not with a bang, but as a quiet little thought.",
      pipSays: "Then I had an idea!",
      accentColor: PipColors.peach,
    ),
    _StoryBeat(
      emoji: "🎵",
      title: "The First Lullaby",
      body:
          "Pip discovered that when the star's glow passed through the music box, "
          "it made a sound — a warm, looping melody that felt like a hug. "
          "The very first lullaby. The one you just heard.",
      pipSays: "What if I could turn its little glow into dreams?",
      accentColor: PipColors.lavender,
    ),
    _StoryBeat(
      emoji: "🌙",
      title: "Lights for the Dreamers",
      body:
          "Next, Pip noticed that some dreamers were afraid of the dark. "
          "So Pip split the star's glow into five colours — "
          "one for every kind of night — and made the nightlight collection.",
      pipSays: "I made these little lights for dreamers afraid of the dark.",
      accentColor: PipColors.mintGlow,
    ),
    _StoryBeat(
      emoji: "📦",
      title: "The First Delivery",
      body:
          "With the lullaby and the lights ready, Pip loaded up the cloud "
          "and set out on the very first dream delivery route. "
          "It took twice as long as it should have, because Pip kept stopping to look at the stars.",
      pipSays: "And that's how my dream-making adventure began!",
      accentColor: PipColors.berryPink,
    ),
    _StoryBeat(
      emoji: "✨",
      title: "Every Light Matters",
      body:
          "And so Pip learned the most important thing of all: "
          "you don't need to be big or bright or famous "
          "to make a difference. Sometimes a tiny glow "
          "is exactly enough.",
      pipSays: "Even the smallest light can make a difference.",
      accentColor: PipColors.goldenGlow,
      isFinal: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
    setState(() => _currentBeat = index);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DreamState>();
    final isNight = state.isNightMode;
    final size = MediaQuery.of(context).size;

    // Smaller spacing/card on short or narrow screens so text fits.
    final compact = size.height < 760 || size.width < 480;
    final gap = compact ? 12.0 : 20.0;

    return StarfieldBackground(
      isNight: isNight,
      child: Column(
        children: [
          SizedBox(height: gap),

          // Label
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isNight
                    ? PipColors.goldenGlow.withOpacity(0.15)
                    : PipColors.berryPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Scene 6 · Pip's Origin Story",
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isNight ? PipColors.goldenGlow : PipColors.berryPink,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),

          SizedBox(height: gap),

          // Story progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < _beats.length; i++)
                GestureDetector(
                  onTap: () => _goTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: i == _currentBeat ? 24 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: i <= _currentBeat
                          ? (isNight
                                ? PipColors.goldenGlow
                                : PipColors.berryPink)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: gap),

          // Story pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentBeat = i),
              itemCount: _beats.length,
              itemBuilder: (context, index) {
                // FIX: each page scrolls if the card is taller than the
                // available space, and the card stays centred when it fits.
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final minH = constraints.maxHeight > 16
                        ? constraints.maxHeight - 16
                        : 0.0;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minH),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: _StoryCard(
                              beat: _beats[index],
                              isNight: isNight,
                              isCurrent: index == _currentBeat,
                              compact: compact,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Navigation (Wrap so it never overflows on narrow screens)
          Padding(
            padding: EdgeInsets.symmetric(vertical: gap, horizontal: 20),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                if (_currentBeat > 0)
                  _NavButton(
                    label: "← Previous",
                    isNight: isNight,
                    isPrimary: false,
                    onPressed: () => _goTo(_currentBeat - 1),
                  ),
                if (_currentBeat < _beats.length - 1)
                  _NavButton(
                    label: "Next →",
                    isNight: isNight,
                    isPrimary: true,
                    onPressed: () => _goTo(_currentBeat + 1),
                  ),
                if (_beats[_currentBeat].isFinal)
                  _NavButton(
                    label: "Continue the Journey →",
                    isNight: isNight,
                    isPrimary: true,
                    onPressed: widget.onNext,
                  ),
              ],
            ),
          ),

          SizedBox(height: compact ? 4 : 20),
        ],
      ),
    );
  }
}

class _StoryBeat {
  final String emoji;
  final String title;
  final String body;
  final String pipSays;
  final Color accentColor;
  final bool isFinal;

  const _StoryBeat({
    required this.emoji,
    required this.title,
    required this.body,
    required this.pipSays,
    required this.accentColor,
    this.isFinal = false,
  });
}

class _StoryCard extends StatelessWidget {
  final _StoryBeat beat;
  final bool isNight;
  final bool isCurrent;
  final bool compact;

  const _StoryCard({
    required this.beat,
    required this.isNight,
    required this.isCurrent,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isNight ? Colors.white : PipColors.brown;
    final pad = compact ? 20.0 : 32.0;
    final emojiBox = compact ? 70.0 : 90.0;
    final emojiSize = compact ? 34.0 : 44.0;
    final titleSize = compact ? 22.0 : 26.0;
    final bodySize = compact ? 15.0 : 16.0;
    final gapS = compact ? 12.0 : 16.0;
    final gapL = compact ? 16.0 : 24.0;

    return AnimatedOpacity(
      opacity: isCurrent ? 1.0 : 0.6,
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isNight
                ? [PipColors.nightCard, PipColors.nightMid]
                : [Colors.white, PipColors.softPink.withOpacity(0.3)],
          ),
          border: Border.all(
            color: beat.accentColor.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: beat.accentColor.withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji hero
            Container(
                  width: emojiBox,
                  height: emojiBox,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: beat.accentColor.withOpacity(0.15),
                    border: Border.all(
                      color: beat.accentColor.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      beat.emoji,
                      style: TextStyle(fontSize: emojiSize),
                    ),
                  ),
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(),

            SizedBox(height: gapS + 4),

            // Title
            Text(
              beat.title,
              style: GoogleFonts.nunito(
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                color: beat.accentColor,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

            SizedBox(height: gapS),

            // Body text (under 150 words)
            Text(
              beat.body,
              style: GoogleFonts.nunito(
                fontSize: bodySize,
                height: 1.7,
                color: textColor.withOpacity(0.85),
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 350.ms, duration: 500.ms),

            SizedBox(height: gapL),

            // Pip's quote bubble
            Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 20,
                    vertical: compact ? 10 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: beat.accentColor.withOpacity(isNight ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: beat.accentColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/pip_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Text('💀', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '"${beat.pipSays}"',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: beat.accentColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 500.ms, duration: 500.ms)
                .slideY(begin: 0.2, end: 0, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final String label;
  final bool isNight;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _NavButton({
    required this.label,
    required this.isNight,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isNight
        ? PipColors.goldenGlow
        : PipColors.berryPink;

    if (widget.isPrimary) {
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
              foregroundColor: widget.isNight
                  ? PipColors.nightBg
                  : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
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

    return TextButton(
      onPressed: widget.onPressed,
      child: Text(
        widget.label,
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: accentColor.withOpacity(0.8),
        ),
      ),
    );
  }
}
