import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/dream_state.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogue_bubble.dart';
import '../widgets/starfield_background.dart';
import '../services/audio_service.dart';

class WelcomeScene extends StatefulWidget {
  final VoidCallback onEnter;
  final AudioService audioService;
  const WelcomeScene({
    super.key,
    required this.onEnter,
    required this.audioService,
  });

  @override
  State<WelcomeScene> createState() => _WelcomeSceneState();
}

class _WelcomeSceneState extends State<WelcomeScene>
    with TickerProviderStateMixin {
  bool _dialogueDone = false;
  bool _showButton = false;
  bool _hasStartedWelcomeVoice = false;
  bool _welcomeRequestPending = false;
  bool _lastSoundEnabled = false;

  late AnimationController _floatController;
  late AnimationController _waveController;

  bool _isTalking = false;
  bool _mouthOpen = false;
  Timer? _talkTimer;
  Timer? _idleTimer;
  DateTime? _lastCursorHook;
  int _rhythmStep = 0;

  // Natural speech cadence delays in milliseconds (160ms - 240ms)
  static const List<int> _speechDelays = [170, 230, 160, 240, 190, 210];

  // Waving greeting state
  bool _isWaving = true;
  Timer? _waveStopTimer;

  final List<String> _pipLines = [
    "Oh! Someone's awake! ✨",
    "Welcome to the Midnight Nursery!",
    "I'm Pip — your friendly neighbourhood Dream Engineer.",
    "I build the dreams you fall asleep inside.",
    "Umm... would you like to see what I've been dreaming up?",
  ];

  @override
  void initState() {
    super.initState();

    // Floating / bouncing vertical animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Smooth greeting wave animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _startWaving(duration: const Duration(milliseconds: 4000));
    widget.audioService.voicePlaying.addListener(_onVoicePlaybackChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tryWelcomeVoice();
    });
    _resetIdleTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache both reference images to ensure instant, flicker-free animation
    precacheImage(
      const AssetImage('assets/images/pip_smile_wave.jpg'),
      context,
    );
    precacheImage(const AssetImage('assets/images/pip_talk_open.jpg'), context);

    final soundEnabled = context.read<DreamState>().soundEnabled;
    if (soundEnabled && !_lastSoundEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryWelcomeVoice();
      });
    }
    _lastSoundEnabled = soundEnabled;
  }

  @override
  void dispose() {
    _floatController.dispose();
    _waveController.dispose();
    _talkTimer?.cancel();
    _idleTimer?.cancel();
    widget.audioService.voicePlaying.removeListener(_onVoicePlaybackChanged);
    widget.audioService.stopVoice(onlyIf: PipVoiceLine.welcome);
    widget.audioService.stopVoice(onlyIf: PipVoiceLine.idle);
    _waveStopTimer?.cancel();
    super.dispose();
  }

  void _scheduleNextMouthStep() {
    _talkTimer?.cancel();
    if (!_isTalking || !mounted) {
      if (_mouthOpen) {
        setState(() => _mouthOpen = false);
      }
      return;
    }

    final delay = _speechDelays[_rhythmStep % _speechDelays.length];
    _rhythmStep++;

    _talkTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        _mouthOpen = !_mouthOpen;
      });
      _scheduleNextMouthStep();
    });
  }

  void _onVoicePlaybackChanged() {
    if (!mounted) return;
    final talking = widget.audioService.voicePlaying.value;
    setState(() {
      _isTalking = talking;
      if (!talking) _mouthOpen = false;
    });
    _talkTimer?.cancel();
    if (talking) {
      _scheduleNextMouthStep();
    } else {
      _resetIdleTimer();
    }
  }

  Future<void> _tryWelcomeVoice() async {
    final state = context.read<DreamState>();
    if (!state.soundEnabled ||
        _hasStartedWelcomeVoice ||
        _welcomeRequestPending) {
      return;
    }
    _welcomeRequestPending = true;
    try {
      final started = await widget.audioService.playWelcomeVoice();
      if (started && mounted) _hasStartedWelcomeVoice = true;
    } finally {
      _welcomeRequestPending = false;
    }
  }

  void _onCursorInteraction() {
    _resetIdleTimer();
    final now = DateTime.now();
    if (_lastCursorHook != null &&
        now.difference(_lastCursorHook!) < const Duration(seconds: 3)) {
      return;
    }
    _lastCursorHook = now;
    // TODO: Connect a dedicated cursor-interaction recording when supplied.
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 25), () {
      if (!mounted || !context.read<DreamState>().soundEnabled) return;
      if (!widget.audioService.voicePlaying.value) {
        widget.audioService.playVoice(PipVoiceLine.idle);
      }
    });
  }

  void _startWaving({Duration duration = const Duration(milliseconds: 3500)}) {
    _waveStopTimer?.cancel();
    setState(() {
      _isWaving = true;
    });
    _waveController.repeat();

    _waveStopTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() {
        _isWaving = false;
      });
      _waveController.animateTo(0, duration: const Duration(milliseconds: 300));
    });
  }

  void _handlePipTap() {
    _onCursorInteraction();
    _tryWelcomeVoice();
    _startWaving(duration: const Duration(milliseconds: 2800));
  }

  void _onDialogueLineChange(int index) {
    _resetIdleTimer();
    _startWaving(duration: const Duration(milliseconds: 2200));
  }

  void _onDialogueComplete() {
    setState(() {
      _dialogueDone = true;
      _showButton = true;
      _isWaving = false;
    });
    _waveStopTimer?.cancel();
    _waveController.animateTo(0, duration: const Duration(milliseconds: 300));
  }

  Future<void> _handleEnter() async {
    final state = context.read<DreamState>();
    state.unlockAudio();
    await widget.audioService.stopVoice(onlyIf: PipVoiceLine.welcome);
    widget.onEnter();
  }

  @override
  Widget build(BuildContext context) {
    final dreamState = context.watch<DreamState>();
    final isNight = dreamState.isNightMode;
    if (dreamState.soundEnabled && !_hasStartedWelcomeVoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryWelcomeVoice();
      });
    }
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Listener(
      onPointerDown: (_) => _resetIdleTimer(),
      child: MouseRegion(
        onHover: (_) => _resetIdleTimer(),
        child: StarfieldBackground(
          isNight: isNight,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),

                  // Moon / Sun decoration
                  _MoonDecoration(isNight: isNight),

                  const SizedBox(height: 20),

                  // Animated Pip on Cloud with mouth talking & waving hand
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _floatController,
                      _waveController,
                    ]),
                    builder: (context, child) {
                      final floatOffset = _floatController.value * 14 - 7;
                      return Transform.translate(
                        offset: Offset(0, floatOffset),
                        child: child,
                      );
                    },
                    child: _PipOnCloud(
                      isNight: isNight,
                      isMobile: isMobile,
                      isTalking: _isTalking,
                      mouthOpen: _mouthOpen,
                      isWaving: _isWaving,
                      waveValue: _waveController.value,
                      onTap: _handlePipTap,
                      onCursorEnter: _onCursorInteraction,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                        "✨ Pip's Dream World ✨",
                        style: GoogleFonts.nunito(
                          fontSize: isMobile ? 26 : 38,
                          fontWeight: FontWeight.w800,
                          color: isNight
                              ? PipColors.goldenGlow
                              : PipColors.berryPink,
                          shadows: [
                            Shadow(
                              color: isNight
                                  ? PipColors.goldenGlow.withOpacity(0.5)
                                  : PipColors.berryPink.withOpacity(0.3),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 800.ms)
                      .slideY(begin: 0.3, end: 0, duration: 600.ms),

                  const SizedBox(height: 8),

                  Text(
                    "A tiny universe of lullabies, nightlights & delivered dreams",
                    style: GoogleFonts.nunito(
                      fontSize: isMobile ? 14 : 16,
                      color: isNight
                          ? PipColors.lavender
                          : PipColors.brown.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

                  const SizedBox(height: 40),

                  // Dialogue Bubble with line change listener
                  if (!_dialogueDone)
                    DialogueBubble(
                          lines: _pipLines,
                          isNight: isNight,
                          onLineChange: _onDialogueLineChange,
                          onComplete: _onDialogueComplete,
                        )
                        .animate()
                        .fadeIn(delay: 800.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0, duration: 500.ms),

                  // Enter button
                  if (_showButton) ...[
                    const SizedBox(height: 32),
                    _EnterButton(isNight: isNight, onPressed: _handleEnter)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                        ),
                  ],

                  const SizedBox(height: 80),

                  // Floating stars decoration
                  _FloatingStarRow(isNight: isNight),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoonDecoration extends StatelessWidget {
  final bool isNight;
  const _MoonDecoration({required this.isNight});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: isNight
          ? Container(
                  key: const ValueKey('moon'),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFF3CC),
                    boxShadow: [
                      BoxShadow(
                        color: PipColors.goldenGlow.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: PipColors.goldenGlow.withOpacity(0.2),
                        blurRadius: 80,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.nightlight_round,
                    color: Color(0xFFDDB44A),
                    size: 50,
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn()
          : Container(
                  key: const ValueKey('sun'),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF9800)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wb_sunny_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(),
    );
  }
}

class _PipOnCloud extends StatelessWidget {
  final bool isNight;
  final bool isMobile;
  final bool isTalking;
  final bool mouthOpen;
  final bool isWaving;
  final double waveValue;
  final VoidCallback onTap;
  final VoidCallback onCursorEnter;

  const _PipOnCloud({
    required this.isNight,
    required this.isMobile,
    required this.isTalking,
    required this.mouthOpen,
    required this.isWaving,
    required this.waveValue,
    required this.onTap,
    required this.onCursorEnter,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = isMobile ? 150.0 : 190.0;
    // Gentle greeting wave tilt around Pip's base
    final waveAngle = isWaving ? sin(waveValue * 2 * pi) * 0.055 : 0.0;

    return MouseRegion(
      onEnter: (_) => onCursorEnter(),
      child: GestureDetector(
        onTap: onTap,
        child: Transform.rotate(
          angle: waveAngle,
          alignment: const Alignment(0.1, 0.9),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cloud beneath pip
              Container(
                width: avatarSize + 60,
                height: 55,
                margin: EdgeInsets.only(top: isMobile ? 120 : 145),
                decoration: BoxDecoration(
                  color: isNight
                      ? Colors.white.withOpacity(0.12)
                      : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: isNight
                          ? PipColors.lavender.withOpacity(0.3)
                          : PipColors.softPink.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              // Pip avatar circle
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isNight
                        ? [PipColors.nightCard, PipColors.nightBg]
                        : [PipColors.softPink, PipColors.cream],
                  ),
                  border: Border.all(
                    color: isNight
                        ? PipColors.goldenGlow.withOpacity(0.55)
                        : PipColors.berryPink.withOpacity(0.45),
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isNight
                          ? PipColors.goldenGlow.withOpacity(0.25)
                          : PipColors.berryPink.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Normal smiling and waving expression (Image 2)
                      Image.asset(
                        'assets/images/pip_smile_wave.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _PipPlaceholder(isNight: isNight),
                      ),

                      // Talking open-mouth expression (Image 1)
                      if (isTalking && mouthOpen)
                        Image.asset(
                          'assets/images/pip_talk_open.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PipPlaceholder extends StatelessWidget {
  final bool isNight;
  const _PipPlaceholder({required this.isNight});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isNight ? PipColors.nightCard : PipColors.softPink,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/pip_icon.png',
              width: 60,
              height: 60,
              errorBuilder: (context, error, stackTrace) =>
                  const Text('💀', style: TextStyle(fontSize: 60)),
            ),
            const SizedBox(height: 4),
            Text(
              'Pip',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isNight ? PipColors.goldenGlow : PipColors.berryPink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnterButton extends StatelessWidget {
  final bool isNight;
  final VoidCallback onPressed;

  const _EnterButton({required this.isNight, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: PipColors.goldenGlow,
        foregroundColor: PipColors.nightBg,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
        shadowColor: PipColors.goldenGlow.withOpacity(0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Enter Midnight Nursery",
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 20),
        ],
      ),
    );
  }
}

class _FloatingStarRow extends StatelessWidget {
  final bool isNight;
  const _FloatingStarRow({required this.isNight});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _star(16, 0.4),
        const SizedBox(width: 24),
        _star(24, 0.7),
        const SizedBox(width: 24),
        _star(18, 0.5),
        const SizedBox(width: 24),
        _star(28, 0.9),
        const SizedBox(width: 24),
        _star(14, 0.4),
      ],
    );
  }

  Widget _star(double size, double opacity) {
    return Icon(
      Icons.star_rounded,
      size: size,
      color: (isNight ? PipColors.goldenGlow : PipColors.berryPink).withOpacity(
        opacity,
      ),
    );
  }
}
