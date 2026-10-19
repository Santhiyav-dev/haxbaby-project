import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/dream_state.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogue_bubble.dart';
import '../widgets/starfield_background.dart';
import '../services/audio_service.dart';

class MeetPipScene extends StatefulWidget {
  final VoidCallback onNext;
  final AudioService audioService;
  const MeetPipScene({
    super.key,
    required this.onNext,
    required this.audioService,
  });

  @override
  State<MeetPipScene> createState() => _MeetPipSceneState();
}

class _MeetPipSceneState extends State<MeetPipScene>
    with SingleTickerProviderStateMixin {
  Offset _cursorOffset = Offset.zero;
  bool _pipReacting = false;
  bool _dialogueDone = false;
  bool _isVoicePlaying = false;
  bool _mouthOpen = false;
  Timer? _mouthTimer;
  late final AnimationController _speakingController;

  static const List<int> _mouthIntervalsMs = [180, 220, 200, 170, 230, 190];
  int _mouthIntervalIndex = 0;

  final List<String> _pipLines = [
    "I'm still learning how to make the perfect dream... 🌙",
    "Sometimes my ideas float away before I can catch them!",
    "But every little experiment teaches me something new. ✨",
    "Let me show you my first creation!",
  ];

  @override
  void initState() {
    super.initState();
    _speakingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    widget.audioService.voicePlaying.addListener(_handleVoiceStateChanged);
    _syncVoiceState();
  }

  void _handleVoiceStateChanged() {
    _syncVoiceState();
  }

  void _syncVoiceState() {
    final isExplorationPlaying =
        widget.audioService.voicePlaying.value &&
        widget.audioService.currentVoice == PipVoiceLine.exploration;
    if (_isVoicePlaying == isExplorationPlaying) return;

    _isVoicePlaying = isExplorationPlaying;
    if (_isVoicePlaying) {
      _mouthOpen = false;
      _mouthIntervalIndex = 0;
      _speakingController.repeat();
      _scheduleMouthToggle();
    } else {
      _mouthTimer?.cancel();
      _mouthOpen = false;
      _speakingController.animateTo(
        0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) setState(() {});
  }

  void _scheduleMouthToggle() {
    _mouthTimer?.cancel();
    if (!_isVoicePlaying || !mounted) return;
    final delay =
        _mouthIntervalsMs[_mouthIntervalIndex++ % _mouthIntervalsMs.length];
    _mouthTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted || !_isVoicePlaying) return;
      setState(() => _mouthOpen = !_mouthOpen);
      _scheduleMouthToggle();
    });
  }

  @override
  void dispose() {
    widget.audioService.voicePlaying.removeListener(_handleVoiceStateChanged);
    _mouthTimer?.cancel();
    _speakingController.dispose();
    widget.audioService.stopVoice(onlyIf: PipVoiceLine.exploration);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DreamState>();
    final isNight = state.isNightMode;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return StarfieldBackground(
      isNight: isNight,
      child: MouseRegion(
        onHover: (e) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            setState(() => _cursorOffset = box.globalToLocal(e.position));
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                // Scene label
                _SceneLabel(isNight: isNight, label: "Scene 2 · Meet Pip"),
                const SizedBox(height: 30),

                // Main card
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: isMobile
                        ? Column(
                            children: [
                              _PipPortraitCard(
                                isNight: isNight,
                                cursorOffset: _cursorOffset,
                                isReacting: _pipReacting,
                                isTalking: _isVoicePlaying,
                                mouthOpen: _mouthOpen,
                                speakingController: _speakingController,
                                onTap: _triggerReaction,
                                size: size,
                              ),
                              const SizedBox(height: 24),
                              _PipInfoCard(isNight: isNight),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _PipPortraitCard(
                                  isNight: isNight,
                                  cursorOffset: _cursorOffset,
                                  isReacting: _pipReacting,
                                  isTalking: _isVoicePlaying,
                                  mouthOpen: _mouthOpen,
                                  speakingController: _speakingController,
                                  onTap: _triggerReaction,
                                  size: size,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(child: _PipInfoCard(isNight: isNight)),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // Dialogue
                if (!_dialogueDone)
                  DialogueBubble(
                    lines: _pipLines,
                    isNight: isNight,
                    onComplete: () => setState(() => _dialogueDone = true),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                if (_dialogueDone) ...[
                  const SizedBox(height: 16),
                  _NextButton(
                        isNight: isNight,
                        label: "See the Lullaby Lab →",
                        onPressed: widget.onNext,
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(begin: const Offset(0.8, 0.8)),
                ],

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _triggerReaction() {
    setState(() => _pipReacting = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _pipReacting = false);
    });
  }
}

class _PipPortraitCard extends StatefulWidget {
  final bool isNight;
  final Offset cursorOffset;
  final bool isReacting;
  final bool isTalking;
  final bool mouthOpen;
  final AnimationController speakingController;
  final VoidCallback onTap;
  final Size size;

  const _PipPortraitCard({
    required this.isNight,
    required this.cursorOffset,
    required this.isReacting,
    required this.isTalking,
    required this.mouthOpen,
    required this.speakingController,
    required this.onTap,
    required this.size,
  });

  @override
  State<_PipPortraitCard> createState() => _PipPortraitCardState();
}

class _PipPortraitCardState extends State<_PipPortraitCard> {
  @override
  Widget build(BuildContext context) {
    // Compute subtle eye-following tilt based on cursor
    final screenW = widget.size.width;
    final screenH = widget.size.height;
    final relX = (widget.cursorOffset.dx / screenW - 0.5) * 0.08;
    final relY = (widget.cursorOffset.dy / screenH - 0.5) * 0.06;

    return GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: widget.isNight
                    ? [PipColors.nightCard, PipColors.nightMid]
                    : [PipColors.softPink, PipColors.cream],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isNight
                      ? PipColors.goldenGlow.withOpacity(0.25)
                      : PipColors.berryPink.withOpacity(0.2),
                  blurRadius: widget.isReacting ? 40 : 20,
                  spreadRadius: widget.isReacting ? 8 : 4,
                ),
              ],
              border: Border.all(
                color: widget.isNight
                    ? PipColors.goldenGlow.withOpacity(0.4)
                    : PipColors.berryPink.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: widget.speakingController,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      widget.isTalking
                          ? (widget.mouthOpen
                                ? 'assets/images/pip_talk_open.jpg'
                                : 'assets/images/pip_smile_wave.jpg')
                          : (widget.isReacting
                                ? 'assets/images/pip_talk_open.jpg'
                                : 'assets/images/pip_smile_wave.jpg'),
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _PortraitPlaceholder(
                            isNight: widget.isNight,
                            isReacting: widget.isTalking
                                ? widget.mouthOpen
                                : widget.isReacting,
                          ),
                    ),
                  ),
                  builder: (context, child) {
                    final phase = widget.speakingController.value * 2 * math.pi;
                    final isSpeaking = widget.isTalking;
                    final floatY = isSpeaking ? -math.sin(phase) * 2.5 : 0.0;
                    final swayX = isSpeaking ? math.sin(phase) * 1.2 : 0.0;
                    final swayAngle = isSpeaking
                        ? math.sin(phase) * 0.006
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(swayX, floatY),
                      child: Transform(
                        transform: Matrix4.identity()
                          ..rotateY(relX)
                          ..rotateX(-relY)
                          ..rotateZ(swayAngle),
                        alignment: Alignment.center,
                        child: child,
                      ),
                    );
                  },
                ),
                if (widget.isReacting) ...[
                  const SizedBox(height: 10),
                  Text(
                        "💫 Hehe! You poked me!",
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: widget.isNight
                              ? PipColors.goldenGlow
                              : PipColors.berryPink,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .then()
                      .fadeOut(delay: 600.ms),
                ],
                const SizedBox(height: 8),
                Text(
                  "tap Pip for a reaction!",
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: (widget.isNight ? Colors.white : PipColors.brown)
                        .withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 700.ms)
        .slideX(begin: -0.2, end: 0, duration: 600.ms);
  }
}

class _PortraitPlaceholder extends StatelessWidget {
  final bool isNight;
  final bool isReacting;
  const _PortraitPlaceholder({required this.isNight, required this.isReacting});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      color: isNight ? PipColors.nightCard : PipColors.softPink,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isReacting ? '😲' : '💀',
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 10),
            Text(
              'Pip',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isNight ? PipColors.goldenGlow : PipColors.berryPink,
              ),
            ),
            Text(
              'Junior Dream Engineer',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: isNight ? PipColors.lavender : PipColors.brown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PipInfoCard extends StatelessWidget {
  final bool isNight;
  const _PipInfoCard({required this.isNight});

  @override
  Widget build(BuildContext context) {
    final cardColor = isNight ? PipColors.nightCard : Colors.white;
    final textColor = isNight ? Colors.white : PipColors.brown;
    final accentColor = isNight ? PipColors.goldenGlow : PipColors.berryPink;

    final facts = [
      ("🌙", "Job", "Junior Dream Engineer at the Midnight Nursery"),
      ("💀", "Look", "Cute skull face, always friendly — never scary"),
      ("🎵", "Hobby", "Building lullabies and experimenting with dream lights"),
      ("✨", "Fave thing", "Discovering that little glows can make big dreams"),
      ("🌟", "Secret", "Still learning the perfect recipe for a perfect dream"),
    ];

    return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.15),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
            border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "✨ Meet Pip",
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Sleepy · Curious · Gentle · A little clumsy\nDelighted by little things · Not a fan of silence",
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: textColor.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              ...facts.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      f.$1 == '💀'
                          ? SizedBox(
                              width: 26,
                              height: 26,
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/pip_icon.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text(
                                        f.$1,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                ),
                              ),
                            )
                          : SizedBox(
                              width: 26,
                              height: 26,
                              child: Center(
                                child: Text(
                                  f.$1,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.$2,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              f.$3,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: textColor.withOpacity(0.85),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 400.ms, duration: 700.ms)
        .slideX(begin: 0.2, end: 0, duration: 600.ms);
  }
}

// Reusable widgets
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
            shadowColor: accentColor.withOpacity(0.5),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
