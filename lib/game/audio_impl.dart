import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'world.dart';

/// A sound effect's reusable players, used round-robin.
class _SfxChannel {
  _SfxChannel(this.players);

  final List<AudioPlayer> players;
  int next = 0;
  int lastPlayedMs = 0;
}

/// Real [GameAudio] backed by the `audioplayers` package.
///
/// BGM uses a single dedicated looping player. Each SFX gets a small set of
/// players that are created once (with their source already loaded) and then
/// reused. Creating and disposing a native player for every shot/hit used to
/// churn the platform audio stack several times a second, which made the BGM
/// stutter. Both BGM and SFX opt out of exclusive audio focus
/// (`mixWithOthers` / `audioFocus: none`) so effects never pause the music.
class GameAudioImpl implements GameAudio {
  GameAudioImpl() {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  static const _bgmTracks = [
    'bgm_menu',
    'bgm_area_1',
    'bgm_area_2',
    'bgm_area_3',
    'bgm_boss',
  ];

  /// Short, frequent effects: played through Android's SoundPool
  /// (low-latency mode), which is built for exactly this.
  static const _lowLatency = {
    'shoot', 'hit', 'coin', 'click', 'select', 'jump', 'land', 'death', 'melee',
  };

  /// Effects that often overlap get more voices; everything else gets one.
  static const _voices = {'shoot': 3, 'hit': 3, 'coin': 2, 'death': 2, 'land': 2};

  /// The same effect is not restarted more often than this.
  static const _minGapMs = 45;

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final Map<String, Future<_SfxChannel?>> _channels = {};
  bool _enabled = true;
  bool _muted = false;
  bool _bgmStarted = false;
  String? _playingBgm;

  /// Master SFX volume (0..1). Each [play] call may additionally scale it.
  @override
  double sfxVolume = 0.55;

  /// Background music volume (0..1).
  @override
  double bgmVolume = 0.45;

  @override
  void setBgmVolume(double volume) {
    bgmVolume = volume.clamp(0.0, 1.0);
    unawaited(_bgmPlayer.setVolume(bgmVolume).catchError((_) {}));
  }

  @override
  void setSfxVolume(double volume) {
    sfxVolume = volume.clamp(0.0, 1.0);
  }

  AudioContext _noFocusContext() => AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: <AVAudioSessionOptions>{AVAudioSessionOptions.mixWithOthers},
        ),
      );

  @override
  void preload() {
    unawaited(_preload());
  }

  Future<void> _preload() async {
    // Gameplay sounds first so the first shots don't hitch.
    for (final name in const ['shoot', 'hit', 'jump', 'land', 'death', 'coin', 'melee']) {
      await _channel(name);
    }
    // Copy the (large) BGM files into the audio cache ahead of time, one by
    // one, so switching to e.g. the boss track later starts instantly.
    for (final track in _bgmTracks) {
      try {
        await _bgmPlayer.audioCache.load('audio/$track.mp3');
      } catch (_) {}
    }
  }

  @override
  void unlock(int index) {
    _enabled = true;
    if (!_bgmStarted) unawaited(_startBgm(_playingBgm ?? 'bgm_menu'));
  }

  @override
  void setArea(int index) {
    final track = index < 7
        ? 'bgm_area_1' // areas 1-7
        : index < 14
            ? 'bgm_area_2' // areas 8-14
            : 'bgm_area_3'; // areas 15-20
    startBgm(track);
  }

  Future<void> _startBgm(String track) async {
    if (_muted) return;
    if (_playingBgm == track) return;
    // Claim the track before awaiting so rapid back-to-back calls don't race;
    // a newer request makes this one bail out between awaits.
    _playingBgm = track;
    _bgmStarted = true;
    try {
      await _bgmPlayer.setAudioContext(_noFocusContext());
      if (_playingBgm != track) return;
      await _bgmPlayer.stop();
      if (_playingBgm != track) return;
      await _bgmPlayer.setVolume(bgmVolume);
      if (_playingBgm != track) return;
      await _bgmPlayer.play(AssetSource('audio/$track.mp3'));
    } catch (_) {
      // Audio is optional; never let a playback failure break gameplay.
      if (_playingBgm == track) {
        _playingBgm = null;
        _bgmStarted = false;
      }
    }
  }

  @override
  void startBgm(String track) => unawaited(_startBgm(track));

  /// Switch to the boss battle BGM (used when a boss/mini-boss spawns).
  @override
  void startBossBgm() => startBgm('bgm_boss');

  @override
  void stopBgm() {
    _playingBgm = null;
    unawaited(_bgmPlayer.stop().catchError((_) {}));
  }

  @override
  void pauseBgm() => unawaited(_bgmPlayer.pause().catchError((_) {}));

  @override
  void resumeBgm() {
    if (_playingBgm != null) unawaited(_bgmPlayer.resume().catchError((_) {}));
  }

  @override
  void setMuted(bool muted) {
    _muted = muted;
    if (muted) {
      pauseBgm();
    } else {
      resumeBgm();
    }
  }

  @override
  void play(String name, [double volume = 1]) {
    if (!_enabled || _muted || sfxVolume <= 0) return;
    unawaited(_playSfx(name, volume));
  }

  Future<_SfxChannel?> _channel(String name) =>
      _channels[name] ??= _createChannel(name);

  Future<_SfxChannel?> _createChannel(String name) async {
    final players = <AudioPlayer>[];
    try {
      final mode =
          _lowLatency.contains(name) ? PlayerMode.lowLatency : PlayerMode.mediaPlayer;
      for (int i = 0; i < (_voices[name] ?? 1); i++) {
        final player = AudioPlayer();
        players.add(player);
        await player.setPlayerMode(mode);
        await player.setAudioContext(_noFocusContext());
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource('audio/$name.mp3'));
      }
      return _SfxChannel(players);
    } catch (_) {
      // Missing/broken file: stay silent for this effect from now on.
      for (final p in players) {
        unawaited(p.dispose().catchError((_) {}));
      }
      return null;
    }
  }

  Future<void> _playSfx(String name, double volumeScale) async {
    final channel = await _channel(name);
    if (channel == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - channel.lastPlayedMs < _minGapMs) return;
    channel.lastPlayedMs = now;
    final player = channel.players[channel.next];
    channel.next = (channel.next + 1) % channel.players.length;
    try {
      await player.stop();
      await player.setVolume((sfxVolume * volumeScale).clamp(0.0, 1.0));
      await player.resume();
    } catch (_) {
      // Audio is optional and should never interrupt gameplay.
    }
  }

  @override
  void destroy() {
    unawaited(_bgmPlayer.dispose().catchError((_) {}));
    for (final channel in _channels.values) {
      unawaited(channel.then((c) async {
        for (final p in c?.players ?? const <AudioPlayer>[]) {
          await p.dispose();
        }
      }).catchError((_) {}));
    }
  }
}
