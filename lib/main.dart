import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/pip_cursor_tracker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isNightMode = false;

  void _toggleTheme() {
    setState(() {
      _isNightMode = !_isNightMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DreamPalette(_isNightMode);

    return MaterialApp(
      title: "Pip's Dream World",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _isNightMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: palette.skyTop,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA76C91),
          brightness: _isNightMode ? Brightness.dark : Brightness.light,
          primary: const Color(0xFFA76C91),
          surface: palette.card,
        ),
        useMaterial3: true,
      ),
      home: MyHomePage(isNightMode: _isNightMode, onToggleTheme: _toggleTheme),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final bool isNightMode;
  final VoidCallback onToggleTheme;

  const MyHomePage({
    super.key,
    required this.isNightMode,
    required this.onToggleTheme,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  AudioPlayer? _gigglePlayer;
  late final AnimationController _skyAnimationController;
  late final AnimationController _pipLaughController;
  StreamSubscription<PlayerState>? _giggleStateSubscription;
  StreamSubscription<void>? _giggleCompleteSubscription;
  Completer<void>? _gigglePlaybackDone;
  bool _isGigglePlaying = false;
  int _giggleRequestId = 0;
  String _pipDialogue = 'I see you! Let’s build sweet dreams together.';
  bool _isPointerInsideApp = true;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _skyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _pipLaughController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2568),
    );
  }

  @override
  void dispose() {
    _giggleRequestId++;
    final playbackDone = _gigglePlaybackDone;
    if (playbackDone != null && !playbackDone.isCompleted) {
      playbackDone.complete();
    }
    unawaited(_giggleStateSubscription?.cancel());
    unawaited(_giggleCompleteSubscription?.cancel());
    _skyAnimationController.dispose();
    _pipLaughController.dispose();
    final gigglePlayer = _gigglePlayer;
    if (gigglePlayer != null) {
      unawaited(gigglePlayer.dispose());
    }
    super.dispose();
  }

  void _onEyeContact() {
    if (!mounted) return;
    setState(() {
      _pipDialogue = 'I see you! Let’s build sweet dreams together.';
    });
  }

  void _onPipDoubleTap() {
    if (_isMuted) return;
    unawaited(_playPipGiggle());
  }

  AudioPlayer _createGigglePlayer() {
    final player = AudioPlayer();
    _giggleStateSubscription = player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      if (state == PlayerState.playing) {
        _isGigglePlaying = true;
      } else if (_isGigglePlaying) {
        _finishPipGiggle();
      }
    });
    _giggleCompleteSubscription = player.onPlayerComplete.listen((_) {
      if (mounted) _finishPipGiggle();
    });
    return player;
  }

  void _finishPipGiggle() {
    _isGigglePlaying = false;
    final playbackDone = _gigglePlaybackDone;
    if (playbackDone != null && !playbackDone.isCompleted) {
      playbackDone.complete();
    }
    if (_pipLaughController.status != AnimationStatus.dismissed) {
      _pipLaughController.reset();
    }
  }

  Future<void> _playPipGiggle() async {
    final requestId = ++_giggleRequestId;
    final stopCurrentPlayback = _gigglePlaybackDone != null;
    final previousPlaybackDone = _gigglePlaybackDone;
    if (previousPlaybackDone != null && !previousPlaybackDone.isCompleted) {
      previousPlaybackDone.complete();
    }
    _gigglePlaybackDone = null;
    _isGigglePlaying = false;
    _pipLaughController.reset();

    final gigglePlayer = _gigglePlayer ??= _createGigglePlayer();
    final playbackDone = Completer<void>();
    _gigglePlaybackDone = playbackDone;
    try {
      if (stopCurrentPlayback) {
        await gigglePlayer.stop();
        if (!mounted || requestId != _giggleRequestId) return;
      }

      await gigglePlayer.play(AssetSource('audio/smile 2.mp3.mpeg'));
      if (!mounted || requestId != _giggleRequestId) {
        await gigglePlayer.stop();
        return;
      }

      if (!playbackDone.isCompleted) {
        _isGigglePlaying = true;
        _pipLaughController.forward(from: 0);
      }
      await playbackDone.future;
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Unable to play Pip giggle: $error');
      debugPrintStack(stackTrace: stackTrace);
    } on AudioPlayerException catch (error, stackTrace) {
      debugPrint('Unable to play Pip giggle: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (requestId == _giggleRequestId) {
        _isGigglePlaying = false;
        _gigglePlaybackDone = null;
        if (mounted &&
            _pipLaughController.status != AnimationStatus.dismissed) {
          _pipLaughController.reset();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DreamPalette(widget.isNightMode);

    return MouseRegion(
      onEnter: (_) {
        if (!_isPointerInsideApp) {
          setState(() => _isPointerInsideApp = true);
        }
      },
      onExit: (_) {
        if (_isPointerInsideApp) {
          setState(() => _isPointerInsideApp = false);
        }
      },
      child: Scaffold(
        backgroundColor: palette.skyTop,
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _skyAnimationController,
                  builder: (context, child) => CustomPaint(
                    painter: _DreamSkyPainter(
                      isNight: widget.isNightMode,
                      phase: _skyAnimationController.value,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _DreamTopBar(
                    palette: palette,
                    isNight: widget.isNightMode,
                    isMuted: _isMuted,
                    onToggleTheme: widget.onToggleTheme,
                    onToggleMute: () {
                      setState(() => _isMuted = !_isMuted);
                    },
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 48),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 980),
                              child: Column(
                                children: [
                                  _WelcomeHeading(palette: palette),
                                  const SizedBox(height: 22),
                                  _PipHero(
                                    palette: palette,
                                    dialogue: _pipDialogue,
                                    isNight: widget.isNightMode,
                                    isPointerInsideApp: _isPointerInsideApp,
                                    availableWidth: constraints.maxWidth,
                                    laughAnimation: _pipLaughController,
                                    onEyeContact: _onEyeContact,
                                    onDoubleTap: _onPipDoubleTap,
                                    onTap: () {
                                      setState(() {
                                        _pipDialogue =
                                            'Giggle! You tapped me! 💖';
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 42),
                                  _NightlightCollection(palette: palette),
                                  const SizedBox(height: 30),
                                  _SecretDreamRoom(palette: palette),
                                  const SizedBox(height: 28),
                                  Text(
                                    'made of stardust and sweet dreams',
                                    style: TextStyle(
                                      color: palette.mutedText,
                                      fontSize: 12,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DreamPalette {
  final bool isNight;

  const _DreamPalette(this.isNight);

  Color get skyTop =>
      isNight ? const Color(0xFF211D38) : const Color(0xFFFFF8EF);
  Color get skyBottom =>
      isNight ? const Color(0xFF322747) : const Color(0xFFF7EAF2);
  Color get card => isNight
      ? const Color(0xFF352D4B).withValues(alpha: 0.94)
      : const Color(0xFFFFFCF8).withValues(alpha: 0.94);
  Color get cardSoft =>
      isNight ? const Color(0xFF413653) : const Color(0xFFFFF5F0);
  Color get text => isNight ? const Color(0xFFFFF1E8) : const Color(0xFF58434C);
  Color get mutedText =>
      isNight ? const Color(0xFFD0C0D5) : const Color(0xFF9A7E88);
  Color get rose => isNight ? const Color(0xFFEBAFC8) : const Color(0xFFB66F8E);
  Color get gold => const Color(0xFFE5B96D);
  Color get border =>
      isNight ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFF1E3D5);
}

class _DreamTopBar extends StatelessWidget {
  final _DreamPalette palette;
  final bool isNight;
  final bool isMuted;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleMute;

  const _DreamTopBar({
    required this.palette,
    required this.isNight,
    required this.isMuted,
    required this.onToggleTheme,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: 0.78),
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.rose.withValues(alpha: 0.13),
                ),
                child: Icon(
                  Icons.nightlight_round,
                  color: palette.rose,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pip's Dream World",
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                    Text(
                      'a tiny place to feel at home',
                      style: TextStyle(color: palette.mutedText, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _StarCounter(palette: palette),
              const SizedBox(width: 8),
              _TopBarButton(
                tooltip: isMuted ? 'Turn sound on' : 'Turn sound off',
                icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up,
                palette: palette,
                onPressed: onToggleMute,
              ),
              const SizedBox(width: 8),
              _TopBarButton(
                tooltip: isNight
                    ? 'Switch to daydream'
                    : 'Switch to nightdream',
                icon: isNight
                    ? Icons.wb_sunny_rounded
                    : Icons.dark_mode_rounded,
                palette: palette,
                onPressed: onToggleTheme,
                accent: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarCounter extends StatelessWidget {
  final _DreamPalette palette;

  const _StarCounter({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Collected stardust',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.gold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.star_rounded, size: 19, color: palette.gold),
            const SizedBox(width: 5),
            Text(
              '0',
              style: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final _DreamPalette palette;
  final VoidCallback onPressed;
  final bool accent;

  const _TopBarButton({
    required this.tooltip,
    required this.icon,
    required this.palette,
    required this.onPressed,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: accent ? palette.rose.withValues(alpha: 0.13) : palette.cardSoft,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 19,
              color: accent ? palette.rose : palette.mutedText,
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeading extends StatelessWidget {
  final _DreamPalette palette;

  const _WelcomeHeading({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 15, color: palette.gold),
            const SizedBox(width: 8),
            Text(
              'YOUR LITTLE CORNER OF CALM',
              style: TextStyle(
                color: palette.rose,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.1,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.auto_awesome, size: 15, color: palette.gold),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'A softer place to dream',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.text,
            fontSize: 27,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Stay a little while beneath the sleepy stars.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.mutedText, fontSize: 13),
        ),
      ],
    );
  }
}

class _PipHero extends StatelessWidget {
  final _DreamPalette palette;
  final String dialogue;
  final bool isNight;
  final bool isPointerInsideApp;
  final double availableWidth;
  final Animation<double> laughAnimation;
  final VoidCallback onEyeContact;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const _PipHero({
    required this.palette,
    required this.dialogue,
    required this.isNight,
    required this.isPointerInsideApp,
    required this.availableWidth,
    required this.laughAnimation,
    required this.onEyeContact,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final pipWidth = math.min(320.0, math.max(230.0, availableWidth - 48));
    final pipHeight = pipWidth * 570 / 320;

    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.rose.withValues(alpha: 0.12),
                blurRadius: 26,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: palette.rose,
                size: 19,
              ),
              const SizedBox(width: 11),
              Flexible(
                child: Text(
                  dialogue,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: pipWidth + 22,
          height: pipHeight + 22,
          child: Center(
            child: PipCursorTracker(
              width: pipWidth,
              height: pipHeight,
              isNightMode: isNight,
              isPointerInsideApp: isPointerInsideApp,
              laughAnimation: laughAnimation,
              enableTouchFallback: true,
              enableIdleFloating: true,
              onAngleChanged: (_) {},
              onEyeContact: onEyeContact,
              onTap: onTap,
              onDoubleTap: onDoubleTap,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 14, color: palette.gold),
            const SizedBox(width: 7),
            Text(
              'move your cursor to explore together',
              style: TextStyle(
                color: palette.mutedText,
                fontSize: 11,
                letterSpacing: 0.35,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NightlightCollection extends StatelessWidget {
  final _DreamPalette palette;

  const _NightlightCollection({required this.palette});

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        'Moonbeam lantern',
        'A little light for sleepy wishes',
        'assets/images/pip_dream_lantern.png',
        Color(0xFFFFE8C5),
      ),
      (
        'Lullaby keepsake',
        'Turn the quiet into a song',
        'assets/images/pip_lullaby_box.png',
        Color(0xFFF5DDE9),
      ),
      (
        'Cloud-soft dreams',
        'A cozy cloud to drift upon',
        'assets/images/pip_avatar_cloud.png',
        Color(0xFFE8E4F5),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          eyebrow: 'LITTLE TREASURES',
          title: 'The nightlight collection',
          palette: palette,
        ),
        const SizedBox(height: 15),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 520 ? 1 : 3;
            final cardWidth = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - 28) / 3;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final item in items)
                  _NightlightCard(
                    width: cardWidth,
                    title: item.$1,
                    subtitle: item.$2,
                    imagePath: item.$3,
                    tint: item.$4,
                    palette: palette,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _NightlightCard extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final String imagePath;
  final Color tint;
  final _DreamPalette palette;

  const _NightlightCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.tint,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.rose.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Container(
              width: 88,
              height: 88,
              color: tint,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.nightlight_round, color: palette.gold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: palette.mutedText,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: palette.rose),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final _DreamPalette palette;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            color: palette.rose,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            color: palette.text,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SecretDreamRoom extends StatelessWidget {
  final _DreamPalette palette;

  const _SecretDreamRoom({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.rose.withValues(alpha: 0.14),
            palette.gold.withValues(alpha: 0.11),
            palette.card,
          ],
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: palette.rose.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.gold.withValues(alpha: 0.20),
            ),
            child: Icon(Icons.lock_rounded, color: palette.gold, size: 25),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A little mystery awaits',
                  style: TextStyle(
                    color: palette.rose,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Secret Dream Room',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A quiet little nook for the dreams you keep.',
                  style: TextStyle(
                    color: palette.mutedText,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.auto_awesome, color: palette.gold, size: 23),
        ],
      ),
    );
  }
}

class _DreamSkyPainter extends CustomPainter {
  final bool isNight;
  final double phase;

  const _DreamSkyPainter({required this.isNight, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isNight
            ? const [Color(0xFF211D38), Color(0xFF332746)]
            : const [Color(0xFFFFF8EF), Color(0xFFF8ECF3)],
      ).createShader(bounds);
    canvas.drawRect(bounds, backgroundPaint);

    _drawGlow(
      canvas,
      Offset(size.width * 0.17, size.height * 0.22),
      size.shortestSide * 0.46,
      isNight ? const Color(0xFF9D76BF) : const Color(0xFFFFDCCF),
    );
    _drawGlow(
      canvas,
      Offset(size.width * 0.83, size.height * 0.52),
      size.shortestSide * 0.48,
      isNight ? const Color(0xFF7769A8) : const Color(0xFFE5DDF5),
    );

    final starColor = isNight
        ? const Color(0xFFFFE6AE)
        : const Color(0xFFD9AB63);
    const stars = [
      (0.08, 0.16, 3.0),
      (0.29, 0.10, 2.4),
      (0.73, 0.13, 3.0),
      (0.91, 0.24, 2.0),
      (0.16, 0.51, 2.0),
      (0.86, 0.67, 3.0),
      (0.35, 0.78, 2.2),
      (0.68, 0.89, 2.4),
      (0.95, 0.91, 2.0),
    ];

    for (var i = 0; i < stars.length; i++) {
      final (x, y, radius) = stars[i];
      final sparkle = 0.68 + 0.32 * math.sin(phase * math.pi * 2 + i);
      final center = Offset(
        size.width * x,
        size.height * y + math.sin(phase * math.pi * 2 + i) * 3,
      );
      final paint = Paint()
        ..color = starColor.withValues(alpha: sparkle * 0.72)
        ..style = PaintingStyle.fill;
      canvas.drawPath(_starPath(center, radius * sparkle), paint);
    }

    final cloudPaint = Paint()
      ..color = (isNight ? const Color(0xFFB7A4CE) : Colors.white).withValues(
        alpha: isNight ? 0.07 : 0.37,
      );
    _drawCloud(
      canvas,
      Offset(size.width * 0.05, size.height * 0.38),
      0.85,
      cloudPaint,
    );
    _drawCloud(
      canvas,
      Offset(size.width * 0.88, size.height * 0.83),
      1.05,
      cloudPaint,
    );
  }

  void _drawGlow(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.34), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _drawCloud(Canvas canvas, Offset origin, double scale, Paint paint) {
    final path = Path()
      ..moveTo(origin.dx, origin.dy + 16 * scale)
      ..cubicTo(
        origin.dx - 2 * scale,
        origin.dy + 6 * scale,
        origin.dx + 10 * scale,
        origin.dy + 2 * scale,
        origin.dx + 19 * scale,
        origin.dy + 8 * scale,
      )
      ..cubicTo(
        origin.dx + 25 * scale,
        origin.dy - 4 * scale,
        origin.dx + 44 * scale,
        origin.dy - 2 * scale,
        origin.dx + 47 * scale,
        origin.dy + 10 * scale,
      )
      ..cubicTo(
        origin.dx + 62 * scale,
        origin.dy + 5 * scale,
        origin.dx + 70 * scale,
        origin.dy + 13 * scale,
        origin.dx + 68 * scale,
        origin.dy + 21 * scale,
      )
      ..lineTo(origin.dx + 6 * scale, origin.dy + 21 * scale)
      ..close();
    canvas.drawPath(path, paint);
  }

  Path _starPath(Offset center, double radius) {
    final path = Path();
    for (var point = 0; point < 10; point++) {
      final angle = -math.pi / 2 + point * math.pi / 5;
      final pointRadius = point.isEven ? radius : radius * 0.42;
      final position = Offset(
        center.dx + math.cos(angle) * pointRadius,
        center.dy + math.sin(angle) * pointRadius,
      );
      if (point == 0) {
        path.moveTo(position.dx, position.dy);
      } else {
        path.lineTo(position.dx, position.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _DreamSkyPainter oldDelegate) {
    return oldDelegate.isNight != isNight || oldDelegate.phase != phase;
  }
}
