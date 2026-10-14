import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

import 'asset_store.dart';
import 'atlas.dart';
import 'audio_impl.dart';
import 'data.dart';
import 'save.dart';
import 'world.dart';

enum GamePhase { loading, title, ready, playing, upgrade, gameover, victory }

Color _hex(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse(h.length == 6 ? 'ff$h' : h, radix: 16));
}

class RuntuhGame extends FlameGame
    with PanDetector, TapDetector {
  RuntuhGame({GameAudio? audio}) : audio = audio ?? GameAudioImpl();

  final AssetStore store = AssetStore();
  final Tuning tuning = Tuning();
  final GameAudio audio;
  final SaveStore save = SaveStore();

  GamePhase phase = GamePhase.loading;
  CombatWorld? combat;
  int selectedSkin = 0;
  int selectedTheme = 0;
  /// Gameplay pause (pause menu). Kept separate from Flame's own [paused],
  /// which stops the engine loop and is toggled by app lifecycle changes.
  bool gamePaused = false;
  double _menuTime = 0;
  int activeArea = 0;
  String banner = '';
  double bannerTimer = 0;

  final InputState input = InputState();
  List<Upgrade> upgradeChoicesList = [];

  static const double worldWidth = 360;
  static const double worldHeight = 640;

  /// Map a widget-space coordinate (device px relative to the GameWidget) into
  /// the fixed 360x640 world space, mirroring the letterboxed scale used when
  /// drawing.
  double toWorldX(double x) {
    final size = canvasSize;
    if (size.x == 0 || size.y == 0) return x;
    final s = _fitScale(size);
    final ox = (size.x - worldWidth * s) / 2;
    return (x - ox) / s;
  }

  double _fitScale(Vector2 size) =>
      (size.x / worldWidth < size.y / worldHeight ? size.x / worldWidth : size.y / worldHeight);

  void Function()? notifyUi;

  /// Asks the UI to show the tutorial popup (start of a run in theme 1).
  void Function()? onShowTutorial;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await save.load();
    selectedSkin = save.selectedSkin.clamp(0, SKINS.length - 1);
    selectedTheme = save.selectedTheme.clamp(0, AREAS.length - 1);
    audio.setBgmVolume(save.bgmVolume);
    audio.setSfxVolume(save.sfxVolume);
    await store.loadGlobal();
    // Preload every skin's move sheet and every area's background once, so the
    // main-menu skin/theme selectors switch instantly from cache instead of
    // decoding a sprite sheet on every change.
    await Future.wait([
      for (final s in SKINS) store.load(s.moveKey),
      for (final a in AREAS) store.load(a.backgroundKey, false),
    ]);
    phase = GamePhase.title;
    audio.startBgm('bgm_menu');
    audio.preload();
    notifyUi?.call();
  }

  void selectSkin(int index) {
    selectedSkin = index.clamp(0, SKINS.length - 1);
    store.load(SKINS[selectedSkin].moveKey);
    save.selectedSkin = selectedSkin;
    save.save();
    notifyUi?.call();
  }

  void selectTheme(int index) {
    selectedTheme = index.clamp(0, AREAS.length - 1);
    store.load(AREAS[selectedTheme].backgroundKey, false);
    save.selectedTheme = selectedTheme;
    save.save();
    notifyUi?.call();
  }

  // ---- Settings & progress ----
  bool get tutorialSeen => save.tutorialSeen;

  void completeTutorial() {
    if (save.tutorialSeen) return;
    save.tutorialSeen = true;
    save.save();
  }

  void setBgmVolume(double volume) {
    audio.setBgmVolume(volume);
    save.bgmVolume = audio.bgmVolume;
    save.save();
  }

  void setSfxVolume(double volume) {
    audio.setSfxVolume(volume);
    save.sfxVolume = audio.sfxVolume;
    save.save();
  }

  RunCheckpoint? get checkpoint => save.checkpoint;

  void resetProgress() {
    save.resetProgress();
    selectedSkin = 0;
    selectedTheme = 0;
    notifyUi?.call();
  }

  void _saveCheckpoint(CombatWorld w, {bool pendingUpgrade = false}) {
    save.checkpoint = RunCheckpoint(
      area: w.areaIndex,
      skin: w.skin.id,
      wave: w.wave,
      score: w.score,
      runCoins: w.runCoins,
      hp: w.player.hp,
      ultimate: w.player.ultimate,
      rage: w.player.rageActive > 0 ? 0 : w.player.rage,
      revived: w.player.revived,
      levels: Map.of(w.levels),
      pendingUpgrade: pendingUpgrade,
    );
    save.bestScore = math.max(save.bestScore, w.score.round());
    save.save();
  }

  /// Bank score and coins of a finished (or abandoned) run.
  void _bankRun(double score, int coins) {
    save.bestScore = math.max(save.bestScore, score.round());
    save.totalCoins += coins;
    save.checkpoint = null;
    save.save();
  }

  /// App went to background (or is being closed): pause the run and make
  /// sure everything is on disk.
  void onAppBackground() {
    if (phase == GamePhase.playing && !gamePaused) {
      pauseGame(silent: true);
    } else {
      audio.pauseBgm();
    }
    save.save();
  }

  void onAppForeground() {
    if (!gamePaused) audio.resumeBgm();
  }

  void pauseGame({bool silent = false}) {
    if (phase == GamePhase.playing) {
      gamePaused = true;
      if (!silent) audio.play('pause');
      audio.pauseBgm();
      notifyUi?.call();
    }
  }

  void resumeGame() {
    gamePaused = false;
    audio.play('resume');
    audio.resumeBgm();
    notifyUi?.call();
  }

  void quitToMenu() {
    gamePaused = false;
    tutorialPending = false;
    tutorialStep = -1;
    combat = null;
    phase = GamePhase.title;
    audio.startBgm('bgm_menu');
    notifyUi?.call();
  }

  void _setPhase(GamePhase p) {
    phase = p;
    notifyUi?.call();
  }

  /// Continue the run stored in the save (after a quit or a crash/kill).
  void continueRun() {
    final cp = save.checkpoint;
    if (cp == null) return;
    selectedSkin = cp.skin.clamp(0, SKINS.length - 1);
    startArea(cp.area.clamp(0, AREAS.length - 1), false, resume: cp);
  }

  Future<void> startArea(int index, bool endless,
      {RunCheckpoint? resume}) async {
    // Ignore repeated taps on MULAI/ULANGI/LANJUT while assets load.
    if (phase == GamePhase.loading) return;
    // Starting fresh abandons any saved run; keep what it had earned.
    final old = save.checkpoint;
    if (resume == null && old != null) _bankRun(old.score, old.runCoins);
    tutorialPending = false;
    tutorialStep = -1;
    _setPhase(GamePhase.loading);
    activeArea = index;
    final area = AREAS[index];
    final skin = SKINS[selectedSkin];
    try {
      await Future.wait([
        store.loadArea(area),
        store.loadSkin(skin),
      ]);
    } catch (_) {
      // Don't leave the player stuck on the loading spinner.
      quitToMenu();
      return;
    }
    combat = CombatWorld(
      area: area,
      areaIndex: index,
      stats: const {},
      relics: const [],
      skin: skin,
      tuning: tuning,
      audio: audio,
      endless: endless,
      callbacks: WorldCallbacks(
        onBanner: (msg) {
          banner = msg;
          bannerTimer = 2;
          if (msg.toUpperCase().contains('BOSS')) {
            audio.startBossBgm();
          } else if (msg.startsWith('WAVE')) {
            // Back to the area track after a mini-boss wave.
            audio.setArea(index);
          }
          notifyUi?.call();
        },
        onUpgrade: (w) {
          upgradeChoicesList = upgradeChoices(w.levels);
          _saveCheckpoint(w, pendingUpgrade: true);
          _setPhase(GamePhase.upgrade);
        },
        onDefeat: (w) {
          audio.play('lose');
          _bankRun(w.score, w.runCoins);
          _setPhase(GamePhase.gameover);
        },
        onVictory: (w) {
          audio.play('win');
          _bankRun(w.score, w.runCoins);
          _setPhase(GamePhase.victory);
        },
        onWaveStart: _saveCheckpoint,
        onAreaShift: (a) {
          banner = a.name;
          bannerTimer = 2;
          notifyUi?.call();
        },
        canVibrate: () => false,
      ),
    );
    final w = combat!;
    w.resize(360, 640);
    audio.setArea(index);
    if (resume != null) {
      w.wave = resume.wave;
      w.score = resume.score;
      w.runCoins = resume.runCoins;
      w.levels = Map.of(resume.levels);
      w.player.hp = resume.hp.clamp(1, w.player.maxHp);
      w.player.ultimate = resume.ultimate.clamp(0, 100);
      w.player.rage = resume.rage.clamp(0, 99);
      w.player.revived = resume.revived;
      if (resume.pendingUpgrade) {
        w.state = 'upgrade';
        upgradeChoicesList = upgradeChoices(w.levels);
        _setPhase(GamePhase.upgrade);
        return;
      }
    }
    // Theme 1 is the starter area: every fresh run there begins with the
    // interactive practice. Other areas show the tutorial popup only to
    // players who have never seen it.
    tutorialPending = resume == null && index == 0;
    _setPhase(GamePhase.ready);
    if (resume == null && index != 0 && !save.tutorialSeen) {
      onShowTutorial?.call();
    }
  }

  void chooseUpgrade(String id) {
    combat?.resumeAfterUpgrade(id);
    _setPhase(GamePhase.playing);
  }

  void restart() {
    startArea(activeArea, false);
  }

  // ---- Interactive tutorial (theme 1) ----

  /// Title and instruction for each practice step.
  static const List<List<String>> tutorialSteps = [
    ['Bergerak', 'Geser jari ke kiri dan ke kanan di layar untuk bergerak.'],
    ['Lompat', 'Ketuk layar atau tekan tombol Lompat.'],
    ['Menembak', 'Panah menembak otomatis ke atas. Berdiri di bawah monster dan jatuhkan 3 monster!'],
    ['Melee', 'Monster yang sudah mendarat tidak bisa dipanah. Dekati lalu tekan Melee!'],
    ['Skill 1', 'Tekan Skill1 untuk menghantam semua monster di layar.'],
    ['Skill 2', 'Tekan Skill2 untuk memperlambat semua monster.'],
    ['Ultimate', 'Bar ULT sudah penuh! Tekan Ulti untuk serangan pamungkas.'],
  ];

  /// Action button each step asks for (highlighted in the HUD).
  static const List<String?> tutorialButtons = [
    null, 'Lompat', null, 'Melee', 'Skill1', 'Skill2', 'Ulti'
  ];

  /// Theme 1 was started fresh; the first tap begins the practice.
  bool tutorialPending = false;

  /// Current practice step, or -1 when no practice is running.
  int tutorialStep = -1;
  bool get inTutorial => tutorialStep >= 0;

  /// Counts down while the "Bagus!" confirmation of a finished step shows.
  double _stepDoneTimer = 0;
  bool get tutorialStepCompleted => _stepDoneTimer > 0;

  double _lastX = 0;
  double _movedLeft = 0;
  double _movedRight = 0;
  int _killsAtStep = 0;

  /// 0..1 progress of the current step, for steps that have one.
  double get tutorialProgress {
    final w = combat;
    if (!inTutorial || w == null) return 0;
    if (tutorialStepCompleted) return 1;
    switch (tutorialStep) {
      case 0:
        return ((math.min(_movedLeft, 50) + math.min(_movedRight, 50)) / 100);
      case 2:
        return ((w.kills - _killsAtStep) / 3).clamp(0, 1).toDouble();
      default:
        return 0;
    }
  }

  void engage() {
    final w = combat;
    if (w == null) return;
    if (tutorialPending) {
      tutorialPending = false;
      w.beginTutorial();
      _beginTutorialStep(0);
    } else {
      w.engage();
    }
    _setPhase(GamePhase.playing);
  }

  void _beginTutorialStep(int step) {
    final w = combat!;
    final p = w.player;
    tutorialStep = step;
    _stepDoneTimer = 0;
    _killsAtStep = w.kills;
    _lastX = p.x;
    _movedLeft = 0;
    _movedRight = 0;
    final common = w.area.common;
    switch (step) {
      case 2:
        w.spawnQueue = [common, common, common];
        w.spawnClock = 0.4;
        break;
      case 3:
        w.spawnGroundEnemy(p.x < w.width / 2 ? w.width - 70 : 70);
        break;
      case 4:
        p.skillOneCooldown = 0;
        w.spawnQueue = [common, common];
        w.spawnClock = 0.2;
        break;
      case 5:
        p.skillTwoCooldown = 0;
        w.spawnQueue = [common, common];
        w.spawnClock = 0.2;
        break;
      case 6:
        p.ultimate = 100;
        w.spawnQueue = [common, common, common];
        w.spawnClock = 0.2;
        break;
    }
    notifyUi?.call();
  }

  void _updateTutorial(double dt) {
    final w = combat!;
    final p = w.player;
    if (_stepDoneTimer > 0) {
      _stepDoneTimer -= dt;
      if (_stepDoneTimer <= 0) {
        final next = tutorialStep + 1;
        if (next >= tutorialSteps.length) {
          finishTutorial();
        } else {
          _beginTutorialStep(next);
        }
      }
      return;
    }
    final alive = w.enemies.where((e) => !e.dead);
    bool done = false;
    switch (tutorialStep) {
      case 0:
        final dx = p.x - _lastX;
        if (dx < 0) _movedLeft -= dx;
        if (dx > 0) _movedRight += dx;
        _lastX = p.x;
        done = _movedLeft >= 50 && _movedRight >= 50;
        break;
      case 1:
        done = p.jump > 15;
        break;
      case 2:
        final killed = w.kills - _killsAtStep;
        done = killed >= 3;
        // Keep the lesson going if monsters escaped to the ground.
        if (!done && w.spawnQueue.isEmpty && alive.every((e) => e.state == 'ground')) {
          w.spawnQueue = List.filled(3 - killed, w.area.common);
          w.spawnClock = 0.6;
        }
        break;
      case 3:
        done = w.kills > _killsAtStep;
        if (!done && !alive.any((e) => e.state == 'ground')) {
          w.spawnGroundEnemy(p.x < w.width / 2 ? w.width - 70 : 70);
        }
        break;
      case 4:
        done = p.skillOneCooldown > 0;
        break;
      case 5:
        done = p.skillTwoCooldown > 0;
        break;
      case 6:
        done = p.ultimate < 50;
        break;
    }
    if (done) {
      _stepDoneTimer = 1.1;
      audio.play('upgrade');
      notifyUi?.call();
    }
  }

  /// End (or skip) the practice and start the real wave 1.
  void finishTutorial() {
    if (!inTutorial) return;
    tutorialStep = -1;
    _stepDoneTimer = 0;
    save.tutorialSeen = true;
    save.save();
    combat?.endTutorial();
    notifyUi?.call();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gamePaused) return;
    _menuTime += dt;
    if (bannerTimer > 0) {
      bannerTimer -= dt;
      if (bannerTimer <= 0) {
        bannerTimer = 0;
        banner = '';
        notifyUi?.call();
      }
    }
    if (phase == GamePhase.playing && combat != null) {
      combat!.update(dt, input);
      if (inTutorial) _updateTutorial(dt);
    }
  }

  // ---- Input ----
  @override
  void onPanStart(DragStartInfo info) {
    _handlePointer(info.eventPosition.widget.x);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    _handlePointer(info.eventPosition.widget.x);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    input.pointer = false;
    input.targetX = null;
  }

  void _handlePointer(double x) {
    if (gamePaused) return;
    final wx = toWorldX(x);
    if (phase == GamePhase.ready) {
      engage();
      return;
    }
    if (phase == GamePhase.playing) {
      input.pointer = true;
      input.targetX = wx.clamp(35, worldWidth - 35);
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (gamePaused) return;
    if (phase == GamePhase.ready) {
      engage();
      return;
    }
    if (phase == GamePhase.playing) {
      combat?.jump();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final size = canvasSize;
    canvas.save();
    if (size.x > 0 && size.y > 0) {
      final s = _fitScale(size);
      final ox = (size.x - worldWidth * s) / 2;
      final oy = (size.y - worldHeight * s) / 2;
      canvas.translate(ox, oy);
      canvas.scale(s, s);
    }
    if (phase == GamePhase.title) {
      _renderMenu(canvas);
    } else if (combat == null) {
      canvas.drawRect(
          Rect.fromLTWH(0, 0, worldWidth, worldHeight),
          Paint()..color = const Color(0xff101018));
    } else {
      _renderWorld(canvas, combat!);
    }
    canvas.restore();
  }

  void _renderMenu(ui.Canvas canvas) {
    // The title screen always uses the first area's art so it looks the same
    // whichever theme is selected.
    final area = AREAS[0];
    final bg = store.get(area.backgroundKey);
    if (bg != null) {
      drawCover(canvas, bg, worldWidth, worldHeight);
    } else {
      canvas.drawRect(Rect.fromLTWH(0, 0, worldWidth, worldHeight),
          Paint()..color = const Color(0xff101018));
    }
    // Light tint; the menu overlay adds its own top/bottom gradient for text.
    canvas.drawRect(
        Rect.fromLTWH(0, 0, worldWidth, worldHeight),
        Paint()..color = const Color.fromRGBO(0, 0, 0, 0.15));
    final skin = SKINS[selectedSkin];
    final sheet = store.get(skin.moveKey);
    if (sheet != null) {
      sheet.drawAnim(canvas, 'idle_aim_up', _menuTime, worldWidth / 2,
          worldHeight * 0.58, 135);
    }
  }

  void _renderWorld(ui.Canvas canvas, CombatWorld w) {
    canvas.save();
    if (w.shake > 0.5) {
      final s = w.shake;
      canvas.translate(
        (w.time * 53 % 1 - 0.5) * s,
        (w.time * 91 % 1 - 0.5) * s,
      );
    }

    // Background
    final bg = store.get(w.area.backgroundKey);
    if (bg != null) {
      canvas.drawImageRect(
        bg.image,
        Rect.fromLTWH(0, 0, bg.image.width.toDouble(), bg.image.height.toDouble()),
        Rect.fromLTWH(0, 0, w.width, w.height),
        Paint(),
      );
    } else {
      canvas.drawRect(Rect.fromLTWH(0, 0, w.width, w.height),
          Paint()..color = _hex(w.area.accent).withValues(alpha: 0.25));
    }

    // Ground
    final ground = store.get(w.area.groundKey);
    if (ground != null) {
      canvas.drawImageRect(
        ground.image,
        Rect.fromLTWH(0, 0, ground.image.width.toDouble(), ground.image.height.toDouble()),
        Rect.fromLTWH(0, w.groundY, w.width, w.height - w.groundY),
        Paint(),
      );
    } else {
      canvas.drawRect(Rect.fromLTWH(0, w.groundY, w.width, w.height - w.groundY),
          Paint()..color = const Color(0xff2a2030));
    }

    // Enemies
    for (final e in w.enemies) {
      _drawEnemy(canvas, w, e);
    }

    // Player
    _drawPlayer(canvas, w);

    // Arrows
    _drawArrows(canvas, w);

    // Projectiles
    for (final p in w.projectiles) {
      canvas.drawCircle(Offset(p.x, p.y), 9,
          Paint()..color = const Color(0xff9b5de5));
    }

    // Coins
    for (final c in w.coins) {
      canvas.drawCircle(Offset(c.x, c.y), 5,
          Paint()..color = const Color(0xffffe16a));
    }

    // Effects
    for (final ef in w.effects) {
      _drawEffect(canvas, w, ef);
    }

    // Damage labels (with a dark outline so they read on any background).
    for (final l in w.labels) {
      final fade = (1 - l.age / l.duration).clamp(0.0, 1.0);
      for (final outline in [true, false]) {
        final tp = TextPainter(
          text: TextSpan(
            text: l.text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              foreground: outline
                  ? (Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..color = const Color(0xff120a1e).withValues(alpha: fade))
                  : (Paint()..color = _hex(l.color).withValues(alpha: fade)),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(l.x - tp.width / 2, l.y - tp.height / 2));
      }
    }

    _drawScorePops(canvas, w);

    canvas.restore();

    // Flash
    if (w.flash > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w.width, w.height),
        Paint()..color = const Color(0xffff3344).withValues(alpha: w.flash * 1.6),
      );
    }
  }

  /// Laid-out text for each score popup: [outline, fill, combo tag?].
  final Expando<List<TextPainter>> _popPainters = Expando();

  List<TextPainter> _scorePopPainters(ScorePop s) {
    final cached = _popPainters[s];
    if (cached != null) return cached;
    final size = s.big ? 30.0 : 19.0;
    final text = '+${s.points}';
    TextPainter make(String t, TextStyle style) =>
        TextPainter(text: TextSpan(text: t, style: style), textDirection: TextDirection.ltr)
          ..layout();
    final painters = [
      make(
        text,
        TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s.big ? 5 : 4
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xff2a1300),
        ),
      ),
      make(
        text,
        TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          foreground: Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, -size * 0.6),
              Offset(0, size * 0.6),
              const [Color(0xfffff6c2), Color(0xffffc93c), Color(0xffff8a1f)],
              const [0, 0.5, 1],
            ),
        ),
      ),
      if (s.multiplier > 1)
        make(
          'COMBO ×${s.multiplier}',
          const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Color(0xff7ff3ff),
            shadows: [Shadow(color: Color(0xff001a2e), blurRadius: 3)],
          ),
        ),
    ];
    _popPainters[s] = painters;
    return painters;
  }

  /// "+points" popups: pop in with overshoot, rise, sparkle and fade.
  void _drawScorePops(ui.Canvas canvas, CombatWorld w) {
    for (final s in w.scorePops) {
      final t = (s.age / s.duration).clamp(0.0, 1.0);
      final scale = t < 0.12
          ? 0.4 + (t / 0.12) * 0.9
          : t < 0.24
              ? 1.3 - ((t - 0.12) / 0.12) * 0.3
              : 1.0;
      final alpha = t > 0.65 ? 1 - (t - 0.65) / 0.35 : 1.0;
      final x = s.x;
      final y = s.y - Curves.easeOut.transform(t) * (s.big ? 60 : 42);

      // Sparkle burst.
      if (t < 0.4) {
        final k = t / 0.4;
        final sparkle = Paint()
          ..blendMode = BlendMode.plus
          ..color = const Color(0xffffd36a).withValues(alpha: 1 - k);
        final rays = s.big ? 10 : 7;
        for (int i = 0; i < rays; i++) {
          final ang = i / rays * math.pi * 2 + 0.3;
          final r = 8 + k * (s.big ? 70 : 38);
          final px = x + math.cos(ang) * r;
          final py = y + math.sin(ang) * r * 0.75;
          final d = (s.big ? 4.0 : 3.0) * (1 - k * 0.6);
          canvas.drawPath(
              Path()
                ..moveTo(px, py - d)
                ..lineTo(px + d * 0.6, py)
                ..lineTo(px, py + d)
                ..lineTo(px - d * 0.6, py)
                ..close(),
              sparkle);
        }
      }

      final painters = _scorePopPainters(s);
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(scale, scale);
      canvas.saveLayer(
          null, Paint()..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0)));
      final main = painters[1];
      final origin = Offset(-main.width / 2, -main.height / 2);
      painters[0].paint(canvas, origin);
      main.paint(canvas, origin);
      if (painters.length > 2) {
        final tag = painters[2];
        tag.paint(canvas, Offset(-tag.width / 2, main.height / 2 - 2));
      }
      canvas.restore();
      canvas.restore();
    }
  }

  /// Colour of the player's bolts: element upgrades tint them, rage overrides.
  Color _arrowColor(CombatWorld w) {
    if (w.player.rageActive > 0) return const Color(0xffff4d6d);
    final l = w.levels;
    if (l['fire'] != null) return const Color(0xffff8a2e);
    if (l['frost'] != null) return const Color(0xff7fe7ff);
    if (l['lightning'] != null) return const Color(0xffffe45c);
    if (l['poison'] != null) return const Color(0xff8cff6a);
    return const Color(0xff5ee7ff);
  }

  /// Magitech energy bolts: fading trail, glow, crystal head, fletching,
  /// orbiting rune motes and shed sparks, plus a muzzle flash at the bow.
  void _drawArrows(ui.Canvas canvas, CombatWorld w) {
    final color = _arrowColor(w);
    final core = Color.lerp(color, Colors.white, 0.7)!;
    final t = w.time;

    final p = w.player;
    if (p.shootPulse > 0) {
      final k = 1 - p.shootPulse / 0.24; // 0 → 1 over the flash
      final bow = Offset(p.x, w.groundY - p.jump - math.min(68.0, w.height * 0.1));
      canvas.drawCircle(
          bow,
          4 + k * 16,
          Paint()
            ..color = color.withValues(alpha: (1 - k) * 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 * (1 - k) + 0.5);
      canvas.drawCircle(
          bow,
          7 * (1 - k),
          Paint()
            ..color = core.withValues(alpha: 1 - k)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    if (w.arrows.isEmpty) return;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final corePaint = Paint()..color = core;
    final headPaint = Paint()..color = Colors.white;
    final edgePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    final finPaint = Paint()..color = color.withValues(alpha: 0.9);
    final sparkPaint = Paint()..blendMode = BlendMode.plus;

    for (final a in w.arrows) {
      final x = a.x;
      final y = a.y;
      // Stable per-arrow phase so neighbouring bolts don't animate in sync.
      final seed = (a.hashCode % 97) / 97 * math.pi * 2;

      // Energy trail.
      final trail = Path()
        ..moveTo(x - 4.5, y + 8)
        ..lineTo(x + 4.5, y + 8)
        ..lineTo(x, y + 78)
        ..close();
      canvas.drawPath(
          trail,
          Paint()
            ..blendMode = BlendMode.plus
            ..shader = ui.Gradient.linear(Offset(x, y + 8), Offset(x, y + 78),
                [color.withValues(alpha: 0.75), color.withValues(alpha: 0)]));

      // Glow around shaft and head.
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x - 5, y - 26, 10, 46), const Radius.circular(5)),
          glowPaint);

      // Shaft.
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x - 1.6, y - 14, 3.2, 34), const Radius.circular(1.6)),
          corePaint);

      // Fletching.
      final fins = Path()
        ..moveTo(x - 1.5, y + 10)
        ..lineTo(x - 7, y + 20)
        ..lineTo(x - 6, y + 24)
        ..lineTo(x - 1.5, y + 18)
        ..close()
        ..moveTo(x + 1.5, y + 10)
        ..lineTo(x + 7, y + 20)
        ..lineTo(x + 6, y + 24)
        ..lineTo(x + 1.5, y + 18)
        ..close();
      canvas.drawPath(fins, finPaint);

      // Crystal head.
      final head = Path()
        ..moveTo(x, y - 28)
        ..lineTo(x - 6.5, y - 14)
        ..lineTo(x, y - 17)
        ..lineTo(x + 6.5, y - 14)
        ..close();
      canvas.drawPath(head, headPaint);
      canvas.drawPath(head, edgePaint);

      // Rune motes orbiting the head.
      for (int i = 0; i < 2; i++) {
        final ang = t * 14 + seed + i * math.pi;
        final front = math.sin(ang) > 0;
        sparkPaint.color =
            (front ? core : color).withValues(alpha: front ? 1 : 0.6);
        canvas.drawCircle(
            Offset(x + math.cos(ang) * 8, y - 14 + math.sin(ang) * 3),
            front ? 1.8 : 1.2,
            sparkPaint);
      }

      // Sparks shed along the trail.
      for (int k = 0; k < 3; k++) {
        final phase = (t * 3 + seed + k / 3) % 1;
        sparkPaint.color = core.withValues(alpha: 1 - phase);
        canvas.drawCircle(
            Offset(x + math.sin(seed * 5 + k * 2.1 + t * 9) * (2 + phase * 6),
                y + 22 + phase * 50),
            1.6 * (1 - phase) + 0.4,
            sparkPaint);
      }
    }
  }

  void _drawEnemy(ui.Canvas canvas, CombatWorld w, Enemy e) {
    final moveSheet = store.get(e.moveKey!);
    final attackSheet = store.get(e.attackKey!);
    Sheet? sheet;
    String? anim;
    if (e.attackPulse > 0 && attackSheet?.anim(e.attackAnim) != null) {
      sheet = attackSheet;
      anim = e.attackAnim;
    } else if (moveSheet?.anim(e.moveAnim) != null) {
      sheet = moveSheet;
      anim = e.moveAnim;
    }
    if (sheet != null && anim != null) {
      final flip = e.x > w.player.x;
      sheet.drawAnim(canvas, anim, w.time, e.x, e.y, e.width, flip: flip);
    } else {
      canvas.drawCircle(Offset(e.x, e.y), e.width * 0.4,
          Paint()..color = const Color(0xff8844aa));
    }
    if (e.hitPulse > 0) {
      canvas.drawCircle(Offset(e.x, e.y), e.width * 0.5,
          Paint()..color = const Color(0xffffffff).withValues(alpha: e.hitPulse * 4));
    }
  }

  void _drawPlayer(ui.Canvas canvas, CombatWorld w) {
    final p = w.player;
    final skinMove = store.get(w.skin.moveKey);
    final skinCombat = store.get(w.skin.combatKey);
    String anim = 'idle_aim_up';
    if (p.action != null && skinCombat?.anim(p.action!) != null) {
      skinCombat!.drawAnim(canvas, p.action!, w.time, p.x,
           w.groundY - p.jump, 130, flip: p.facing < 0);
      return;
    } else if (p.jump > 0) {
      anim = 'jump_up';
    } else if (p.shootPulse > 0) {
      anim = 'shoot_up';
    } else if (p.move != 0) {
      anim = 'run_aim_up';
    }
    skinMove?.drawAnim(canvas, anim, w.time, p.x,
        w.groundY - p.jump, 130, flip: p.facing < 0);
    if (p.invulnerable > 0 && (w.time * 10).floor().isEven) {
      canvas.drawCircle(Offset(p.x, w.groundY - p.jump - 40), 60,
          Paint()..color = const Color(0xffffffff).withValues(alpha: 0.18));
    }
  }

  void _drawEffect(ui.Canvas canvas, CombatWorld w, Effect ef) {
    if (ef.sheetKey != null) {
      final sheet = store.get(ef.sheetKey!);
      if (sheet?.anim(ef.type) != null) {
        sheet!.drawAnim(canvas, ef.type, w.time + ef.age, ef.x, ef.y,
             ef.size);
        return;
      }
    }
    // Simple fallback shapes for effect types without a dedicated sheet.
    final t = ef.age / ef.duration;
    switch (ef.type) {
      case 'fire_explosion':
      case 'landing':
      case 'common_death':
      case 'rare_death':
      case 'miniboss_death':
      case 'boss_finisher':
        canvas.drawCircle(
          Offset(ef.x, ef.y),
          ef.size * (0.4 + t * 0.6),
          Paint()..color = const Color(0xffff8844).withValues(alpha: 1 - t),
        );
        break;
      case 'laser':
        canvas.drawRect(
          Rect.fromLTWH(ef.x - 6, 0, 12, ef.size),
          Paint()..color = const Color(0xff66ccff).withValues(alpha: 1 - t),
        );
        break;
      case 'shield':
        canvas.drawCircle(
          Offset(ef.x, ef.y),
          ef.size * 0.5,
          Paint()
            ..color = const Color(0xffaaddff).withValues(alpha: (1 - t) * 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        break;
      case 'dive':
        canvas.drawCircle(
          Offset(ef.x, ef.y),
          ef.size * (0.3 + t * 0.7),
          Paint()..color = const Color(0xffffffff).withValues(alpha: 1 - t),
        );
        break;
    }
  }
}
