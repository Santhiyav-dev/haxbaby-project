import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DreamState extends ChangeNotifier {
  bool _isNightMode = true;
  bool _soundEnabled = false;
  bool _audioUnlocked = false; // true after first user interaction
  Set<int> _foundStars = {};
  bool _secretRoomUnlocked = false;
  int _currentScene = 0;
  bool _showSecretRoom = false;

  // Keys
  static const String _nightKey = 'isNightMode';
  static const String _soundKey = 'soundEnabled';
  static const String _starsKey = 'foundStars';
  static const String _secretKey = 'secretRoomUnlocked';

  DreamState() {
    _load();
  }

  // Getters
  bool get isNightMode => _isNightMode;
  bool get soundEnabled => _soundEnabled;
  bool get audioUnlocked => _audioUnlocked;
  Set<int> get foundStars => _foundStars;
  int get starsCount => _foundStars.length;
  bool get secretRoomUnlocked => _secretRoomUnlocked;
  int get currentScene => _currentScene;
  bool get showSecretRoom => _showSecretRoom;
  bool hasStar(int index) => _foundStars.contains(index);

  // Actions
  void toggleNightMode() {
    _isNightMode = !_isNightMode;
    notifyListeners();
    _save();
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    notifyListeners();
    _save();
  }

  void unlockAudio() {
    _audioUnlocked = true;
    notifyListeners();
  }

  void collectStar(int index) {
    if (!_foundStars.contains(index)) {
      _foundStars.add(index);
      notifyListeners();
      _save();
      if (_foundStars.length >= 3) {
        _secretRoomUnlocked = true;
        notifyListeners();
        _save();
      }
    }
  }

  void setScene(int scene) {
    _currentScene = scene;
    notifyListeners();
  }

  void openSecretRoom() {
    if (_secretRoomUnlocked) {
      _showSecretRoom = true;
      notifyListeners();
    }
  }

  void closeSecretRoom() {
    _showSecretRoom = false;
    notifyListeners();
  }

  void resetJourney() {
    _currentScene = 0;
    notifyListeners();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isNightMode = prefs.getBool(_nightKey) ?? true;
      _soundEnabled = prefs.getBool(_soundKey) ?? false;
      final stars = prefs.getStringList(_starsKey) ?? [];
      _foundStars = stars.map(int.parse).toSet();
      _secretRoomUnlocked = prefs.getBool(_secretKey) ?? false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_nightKey, _isNightMode);
      await prefs.setBool(_soundKey, _soundEnabled);
      await prefs.setStringList(
        _starsKey,
        _foundStars.map((s) => s.toString()).toList(),
      );
      await prefs.setBool(_secretKey, _secretRoomUnlocked);
    } catch (_) {}
  }
}
