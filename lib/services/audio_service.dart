import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum PipVoiceLine { welcome, idle, encouragement, exploration, goodbye }

class AudioService {
  AudioPlayer? _bgmPlayer;
  AudioPlayer? _lullabyPlayer;
  AudioPlayer? _sfxPlayer;
  final AudioPlayer _voicePlayer = AudioPlayer();
  final ValueNotifier<bool> voicePlaying = ValueNotifier<bool>(false);
  StreamSubscription<void>? _voiceCompleteSubscription;

  bool _isBgmEnabled = false;
  bool _isLullabyPlaying = false;
  final double _normalBgmVolume = 0.5;
  double _currentBgmVolume = 0.5;
  bool _bgmDuckedForVoice = false;
  int _volumeTransitionId = 0;
  Future<void> _volumeTransition = Future<void>.value();
  PipVoiceLine? _currentVoice;
  bool _voiceStarting = false;
  bool _welcomeVoiceStarted = false;
  final Map<PipVoiceLine, DateTime> _voiceLastPlayed = {};

  AudioService() {
    _bgmPlayer = AudioPlayer();
    _lullabyPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    _voiceCompleteSubscription = _voicePlayer.onPlayerComplete.listen((_) {
      _finishVoicePlayback();
    });
  }

  bool get isMuted => !_isBgmEnabled;
  bool get isBgmEnabled => _isBgmEnabled;
  bool get isLullabyPlaying => _isLullabyPlaying;
  PipVoiceLine? get currentVoice => _currentVoice;

  Future<void> lowerBackgroundMusicVolume() async {
    if (!_isBgmEnabled || _bgmDuckedForVoice) return;
    _bgmDuckedForVoice = true;
    await _fadeBackgroundMusicTo(_normalBgmVolume * 0.12);
  }

  Future<void> restoreBackgroundMusicVolume() async {
    if (!_bgmDuckedForVoice) return;
    _bgmDuckedForVoice = false;
    if (!_isBgmEnabled) return;
    await _fadeBackgroundMusicTo(_normalBgmVolume);
  }

  Future<void> _fadeBackgroundMusicTo(double target) {
    final transitionId = ++_volumeTransitionId;
    final start = _currentBgmVolume;
    const steps = 6;
    const stepDuration = Duration(milliseconds: 35);

    _volumeTransition = _volumeTransition.then((_) async {
      for (var step = 1; step <= steps; step++) {
        if (transitionId != _volumeTransitionId || !_isBgmEnabled) return;
        final progress = step / steps;
        final volume = start + (target - start) * progress;
        try {
          await _bgmPlayer?.setVolume(volume);
          _currentBgmVolume = volume;
        } catch (error) {
          debugPrint('Background music volume error: $error');
          return;
        }
        if (step < steps) await Future<void>.delayed(stepDuration);
      }
    });
    return _volumeTransition;
  }

  void _finishVoicePlayback() {
    _currentVoice = null;
    voicePlaying.value = false;
    restoreBackgroundMusicVolume();
  }

  Future<bool> playWelcomeVoice() async {
    if (_welcomeVoiceStarted) return false;
    final started = await playVoice(PipVoiceLine.welcome);
    if (started) _welcomeVoiceStarted = true;
    return started;
  }

  Future<bool> playVoice(PipVoiceLine line) async {
    if (isMuted || _voiceStarting) return false;
    if (_currentVoice == PipVoiceLine.welcome ||
        _currentVoice == PipVoiceLine.idle) {
      return false;
    }
    if (line == PipVoiceLine.idle && voicePlaying.value) return false;

    final lastPlayed = _voiceLastPlayed[line];
    final cooldown = switch (line) {
      PipVoiceLine.welcome => const Duration(days: 365),
      PipVoiceLine.idle => const Duration(seconds: 45),
      PipVoiceLine.encouragement => const Duration(seconds: 12),
      PipVoiceLine.exploration => const Duration(seconds: 20),
      PipVoiceLine.goodbye => const Duration(days: 365),
    };
    if (lastPlayed != null &&
        DateTime.now().difference(lastPlayed) < cooldown) {
      return false;
    }

    final asset = switch (line) {
      PipVoiceLine.welcome => 'audio/Welcome.mp3.mpeg',
      PipVoiceLine.idle => 'audio/gendle idle.mp3.mpeg',
      PipVoiceLine.encouragement => 'audio/encouragement.mp3.mpeg',
      PipVoiceLine.exploration => 'audio/explore.mp3.mpeg',
      PipVoiceLine.goodbye => 'audio/bye.mp3.mpeg',
    };

    _voiceStarting = true;
    try {
      if (voicePlaying.value) await stopVoice();
      await lowerBackgroundMusicVolume();
      await _voicePlayer.setReleaseMode(ReleaseMode.stop);
      await _voicePlayer.setVolume(1);
      _currentVoice = line;
      voicePlaying.value = true;
      await _voicePlayer.play(AssetSource(asset));
      _voiceLastPlayed[line] = DateTime.now();
      return true;
    } catch (error) {
      debugPrint('Pip voice error ($asset): $error');
      _currentVoice = null;
      voicePlaying.value = false;
      await restoreBackgroundMusicVolume();
      return false;
    } finally {
      _voiceStarting = false;
    }
  }

  Future<void> stopVoice({PipVoiceLine? onlyIf}) async {
    if (onlyIf != null && _currentVoice != onlyIf) return;
    if (!voicePlaying.value && !_voiceStarting) return;
    try {
      await _voicePlayer.stop();
    } catch (error) {
      debugPrint('Pip voice stop error: $error');
    } finally {
      _currentVoice = null;
      voicePlaying.value = false;
      await restoreBackgroundMusicVolume();
    }
  }

  // --------------------------------------------------
  // HEADER SPEAKER TOGGLE: Baby1.mp3.mpeg
  // --------------------------------------------------

  Future<void> playBackgroundMusic() async {
    _isBgmEnabled = true;
    try {
      await _bgmPlayer?.setReleaseMode(ReleaseMode.loop);
      _currentBgmVolume = _bgmDuckedForVoice
          ? _normalBgmVolume * 0.12
          : _normalBgmVolume;
      await _bgmPlayer?.setVolume(_currentBgmVolume);

      if (!_isLullabyPlaying) {
        if (_bgmPlayer?.state == PlayerState.playing) return;
        if (_bgmPlayer?.state == PlayerState.paused) {
          await _bgmPlayer?.resume();
        } else {
          await _bgmPlayer?.play(AssetSource('audio/Baby1.mp3.mpeg'));
        }
      }
      debugPrint('Background music (Baby1.mp3.mpeg) started');
    } catch (e) {
      debugPrint('Audio error (background music): $e');
    }
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      await _bgmPlayer?.pause();
    } catch (e) {
      debugPrint('Audio error (pause background music): $e');
    }
  }

  Future<void> resumeBackgroundMusic() async {
    if (!_isBgmEnabled || _isLullabyPlaying) return;
    try {
      if (_bgmPlayer?.state == PlayerState.paused) {
        await _bgmPlayer?.resume();
      } else if (_bgmPlayer?.state != PlayerState.playing) {
        await _bgmPlayer?.play(AssetSource('audio/Baby1.mp3.mpeg'));
      }
    } catch (e) {
      debugPrint('Audio error (resume background music): $e');
    }
  }

  Future<void> stopBackgroundMusic() async {
    _isBgmEnabled = false;
    await stopVoice();
    _bgmDuckedForVoice = false;
    _volumeTransitionId++;
    try {
      await _bgmPlayer?.stop();
      _currentBgmVolume = _normalBgmVolume;
      debugPrint('Background music stopped');
    } catch (e) {
      debugPrint('Audio error (stop background music): $e');
    }
  }

  // --------------------------------------------------
  // MUSIC BOX (LULLABY LAB): Pip2.mp3.mpeg
  // --------------------------------------------------

  Future<void> playLullaby() async {
    _isLullabyPlaying = true;
    try {
      // Temporarily pause background music so Pip's lullaby plays clearly
      if (_isBgmEnabled) {
        await _bgmPlayer?.pause();
      }

      await _lullabyPlayer?.stop();
      await _lullabyPlayer?.setReleaseMode(ReleaseMode.loop);
      await _lullabyPlayer?.setVolume(0.7);
      await _lullabyPlayer?.play(AssetSource('audio/Pip2.mp3.mpeg'));
      debugPrint('Pip2 lullaby (Pip2.mp3.mpeg) started');
    } catch (e) {
      debugPrint('Audio error (lullaby): $e');
    }
  }

  Future<void> pauseLullaby() async {
    _isLullabyPlaying = false;
    try {
      await _lullabyPlayer?.pause();
      // Resume background music if header toggle is active
      if (_isBgmEnabled) {
        await resumeBackgroundMusic();
      }
    } catch (e) {
      debugPrint('Audio error (pause lullaby): $e');
    }
  }

  Future<void> resumeLullaby() async {
    _isLullabyPlaying = true;
    try {
      if (_isBgmEnabled) {
        await _bgmPlayer?.pause();
      }
      await _lullabyPlayer?.resume();
    } catch (e) {
      debugPrint('Audio error (resume lullaby): $e');
    }
  }

  Future<void> stopLullaby() async {
    _isLullabyPlaying = false;
    try {
      await _lullabyPlayer?.stop();
      // Resume background music if header toggle is active
      if (_isBgmEnabled) {
        await resumeBackgroundMusic();
      }
    } catch (e) {
      debugPrint('Audio error (stop lullaby): $e');
    }
  }

  // --------------------------------------------------
  // SOUND EFFECTS
  // --------------------------------------------------

  Future<void> playChime() async {
    try {
      await _sfxPlayer?.stop();
      await _sfxPlayer?.setVolume(0.4);
      await _sfxPlayer?.play(AssetSource('audio/pip_click.mp3'));
    } catch (e) {
      debugPrint('Audio error (chime): $e');
    }
  }

  Future<void> playStarSound() async {
    try {
      await _sfxPlayer?.stop();
      await _sfxPlayer?.setVolume(0.5);
      await _sfxPlayer?.play(AssetSource('audio/pip_click.mp3'));
    } catch (e) {
      debugPrint('Audio error (star): $e');
    }
  }

  void setMuted(bool muted) {
    if (muted) {
      stopBackgroundMusic();
    } else {
      playBackgroundMusic();
    }
  }

  void toggleMute() {
    setMuted(_isBgmEnabled);
  }

  void dispose() {
    _voiceCompleteSubscription?.cancel();
    _volumeTransitionId++;
    voicePlaying.dispose();
    _voicePlayer.dispose();
    _bgmPlayer?.dispose();
    _lullabyPlayer?.dispose();
    _sfxPlayer?.dispose();
  }
}
