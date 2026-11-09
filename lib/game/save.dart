import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

int _int(dynamic v, int fallback) => v is num ? v.toInt() : fallback;
double _double(dynamic v, double fallback) =>
    v is num ? v.toDouble() : fallback;

/// Snapshot of a run taken at the start of a wave (or when the upgrade
/// screen opens), so a run can be continued after the app is killed.
class RunCheckpoint {
  RunCheckpoint({
    required this.area,
    required this.skin,
    required this.wave,
    required this.score,
    required this.runCoins,
    required this.hp,
    required this.ultimate,
    required this.rage,
    required this.revived,
    required this.levels,
    this.pendingUpgrade = false,
  });

  final int area;
  final int skin;
  final int wave;
  final double score;
  final int runCoins;
  final int hp;
  final double ultimate;
  final double rage;
  final bool revived;
  final Map<String, int> levels;

  /// True when the player left while the upgrade screen was open; [wave] is
  /// then the wave that was just cleared.
  final bool pendingUpgrade;

  Map<String, dynamic> toJson() => {
    'area': area,
    'skin': skin,
    'wave': wave,
    'score': score,
    'runCoins': runCoins,
    'hp': hp,
    'ultimate': ultimate,
    'rage': rage,
    'revived': revived,
    'levels': levels,
    'pendingUpgrade': pendingUpgrade,
  };

  static RunCheckpoint? fromJson(dynamic m) {
    if (m is! Map) return null;
    final levels = <String, int>{};
    final rawLevels = m['levels'];
    if (rawLevels is Map) {
      rawLevels.forEach((k, v) {
        if (k is String && v is num) levels[k] = v.toInt();
      });
    }
    final wave = _int(m['wave'], 0);
    if (wave < 1) return null;
    return RunCheckpoint(
      area: _int(m['area'], 0),
      skin: _int(m['skin'], 0),
      wave: wave,
      score: _double(m['score'], 0),
      runCoins: _int(m['runCoins'], 0),
      hp: _int(m['hp'], 1),
      ultimate: _double(m['ultimate'], 0),
      rage: _double(m['rage'], 0),
      revived: m['revived'] == true,
      levels: levels,
      pendingUpgrade: m['pendingUpgrade'] == true,
    );
  }
}

/// Persistent player data. Everything lives under one JSON key so each save
/// is a single atomic write.
class SaveStore {
  static const _key = 'runtuh_save_v1';

  SharedPreferences? _prefs;

  bool tutorialSeen = false;
  int selectedSkin = 0;
  int selectedTheme = 0;
  double bgmVolume = 0.45;
  double sfxVolume = 0.55;
  int bestScore = 0;
  int totalCoins = 0;
  bool unlimitedCoins = false;
  final Set<int> unlockedSkins = {0};
  final Set<int> unlockedAreas = {0};
  RunCheckpoint? checkpoint;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_key);
      if (raw == null) return;
      final m = jsonDecode(raw);
      if (m is! Map) return;
      tutorialSeen = m['tutorialSeen'] == true;
      selectedSkin = _int(m['selectedSkin'], 0);
      selectedTheme = _int(m['selectedTheme'], 0);
      bgmVolume = _double(m['bgmVolume'], bgmVolume).clamp(0.0, 1.0);
      sfxVolume = _double(m['sfxVolume'], sfxVolume).clamp(0.0, 1.0);
      bestScore = _int(m['bestScore'], 0);
      totalCoins = _int(m['totalCoins'], 0);
      unlimitedCoins = m['unlimitedCoins'] == true;
      unlockedSkins.addAll(
        (m['unlockedSkins'] as List? ?? const []).whereType<num>().map(
          (value) => value.toInt(),
        ),
      );
      unlockedAreas.addAll(
        (m['unlockedAreas'] as List? ?? const []).whereType<num>().map(
          (value) => value.toInt(),
        ),
      );
      checkpoint = RunCheckpoint.fromJson(m['checkpoint']);
    } catch (_) {
      // Corrupt or unavailable storage: start with defaults.
    }
  }

  void save() {
    final prefs = _prefs;
    if (prefs == null) return;
    final data = jsonEncode({
      'tutorialSeen': tutorialSeen,
      'selectedSkin': selectedSkin,
      'selectedTheme': selectedTheme,
      'bgmVolume': bgmVolume,
      'sfxVolume': sfxVolume,
      'bestScore': bestScore,
      'totalCoins': totalCoins,
      'unlimitedCoins': unlimitedCoins,
      'unlockedSkins': unlockedSkins.toList(),
      'unlockedAreas': unlockedAreas.toList(),
      'checkpoint': checkpoint?.toJson(),
    });
    unawaited(prefs.setString(_key, data).catchError((_) => false));
  }

  /// Wipe progress (scores, coins, run, selections, tutorial) but keep the
  /// player's volume settings.
  void resetProgress() {
    tutorialSeen = false;
    selectedSkin = 0;
    selectedTheme = 0;
    bestScore = 0;
    totalCoins = 0;
    unlimitedCoins = false;
    unlockedSkins
      ..clear()
      ..add(0);
    unlockedAreas
      ..clear()
      ..add(0);
    checkpoint = null;
    save();
  }
}
