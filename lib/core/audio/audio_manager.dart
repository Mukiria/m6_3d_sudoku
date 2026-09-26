import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum SoundType { buttonClick, win, error, hint, pause, resume }

class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;
  double _volume = 1.0;
  bool _initialized = false;

  bool get isMuted => _isMuted;
  double get volume => _volume;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    // Sound effects should mix with whatever the user is already playing
    // (e.g. background music apps) rather than requesting exclusive audio
    // focus and stopping it — the platform default (`gain`) does the latter.
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
    );
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(_isMuted ? 0 : _volume);
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      _player.setVolume(0);
    } else {
      _player.setVolume(_volume);
    }
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    if (!_isMuted) {
      _player.setVolume(_volume);
    }
  }

  Future<void> play(SoundType type) async {
    if (_isMuted) return;

    try {
      final assetPath = _getAssetPath(type);
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      // Silently fail if sound file not found
      debugPrint('Failed to play sound: $e');
    }
  }

  String _getAssetPath(SoundType type) {
    switch (type) {
      case SoundType.buttonClick:
        return 'audio/click.wav';
      case SoundType.win:
        return 'audio/win.wav';
      case SoundType.error:
        return 'audio/error.wav';
      case SoundType.hint:
        return 'audio/hint.wav';
      case SoundType.pause:
        return 'audio/pause.wav';
      case SoundType.resume:
        return 'audio/resume.wav';
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
