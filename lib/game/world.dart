import 'dart:math' as math;

import 'data.dart';

double _clamp(double v, double lo, double hi) => math.max(lo, math.min(hi, v));

double _dist(double x1, double y1, double x2, double y2) =>
    math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2));

class Tuning {
  Tuning({
    this.fallSpeed = 1,
    this.spawnInterval = 0.9,
    this.playerSpeed = 285,
    this.fireRate = 2.2,
    this.enemyHpScale = 1,
    this.effectsIntensity = 1,
    this.skillCooldownScale = 1,
    this.rageDuration = 7,
  });

  double fallSpeed;
  double spawnInterval;
  double playerSpeed;
  double fireRate;
  double enemyHpScale;
  double effectsIntensity;
  double skillCooldownScale;
  double rageDuration;
}

abstract class GameAudio {
  void play(String name, [double volume = 1]);
  void setArea(int index);
  void unlock(int index);
  void setMuted(bool muted);
  void destroy();

  /// Warm up frequently used sounds and music files in the background.
  void preload();

  /// Start (or switch to) a looping background track.
  void startBgm(String track);
  void startBossBgm();
  void stopBgm();
  void pauseBgm();
  void resumeBgm();

  /// Volumes in the 0..1 range.
  double get bgmVolume;
  double get sfxVolume;
  void setBgmVolume(double volume);
  void setSfxVolume(double volume);
}

class NoopAudio implements GameAudio {
  @override
  void play(String name, [double volume = 1]) {}
  @override
  void setArea(int index) {}
  @override
  void unlock(int index) {}
  @override
  void setMuted(bool muted) {}
  @override
  void destroy() {}
  @override
  void preload() {}

  @override
  void startBgm(String track) {}
  @override
  void startBossBgm() {}
  @override
  void stopBgm() {}
  @override
  void pauseBgm() {}
  @override
  void resumeBgm() {}

  @override
  double bgmVolume = 1;
  @override
  double sfxVolume = 1;
  @override
  void setBgmVolume(double volume) => bgmVolume = volume;
  @override
  void setSfxVolume(double volume) => sfxVolume = volume;
}

class WorldCallbacks {
  WorldCallbacks({
    required this.onBanner,
    required this.onUpgrade,
    required this.onDefeat,
    required this.onVictory,
    required this.onAreaShift,
    required this.canVibrate,
    this.onWaveStart,
  });

  final void Function(String) onBanner;
  final void Function(CombatWorld) onUpgrade;
  final void Function(CombatWorld) onDefeat;
  final void Function(CombatWorld) onVictory;
  final void Function(Area) onAreaShift;
  final bool Function() canVibrate;

  /// Called after a wave (2 and up) has been set up; used for checkpoints.
  final void Function(CombatWorld)? onWaveStart;
}

class InputState {
  bool left = false;
  bool right = false;
  double moveX = 0;
  double aimX = 0;
  double aimY = -1;
  bool pointer = false;
  double? targetX;
  bool engaged = false;
}

class Player {
  Player(this.maxHp) : hp = maxHp, x = 180;

  double x;
  double jump = 0;
  double vy = 0;
  int hp;
  final int maxHp;
  double invulnerable = 0;
  double shootClock = 0;
  double shootPulse = 0;
  double move = 0;
  int facing = 1;
  bool groundShield = false;
  bool revived = false;
  String? action;
  double actionTime = 0;
  double meleeCooldown = 0;
  double skillOneCooldown = 0;
  double skillTwoCooldown = 0;

  /// Full length of the last cooldown, for the HUD's cooldown sweep.
  double meleeCooldownMax = 1;
  double skillOneCooldownMax = 1;
  double skillTwoCooldownMax = 1;
  double ultimate = 0;
  double rage = 0;
  double rageActive = 0;
}

class Enemy {
  Enemy(this.template);

  final EnemyTemplate template;
  String get kind => template.kind;
  String get name => template.name;
  String get moveAnim => template.moveAnim;
  String get attackAnim => template.attackAnim;
  String get behavior => template.behavior;
  int get size => template.size;
  String? get moveKey => template.moveKey;
  String? get attackKey => template.attackKey;
  int? get sourceArea => template.sourceArea;

  String id = (_idCounter++).toString();
  double x = 0;
  double y = 0;
  double width = 0;
  double height = 0;
  int maxHp = 0;
  int hp = 0;
  double age = 0;
  String state = 'fall';
  double hoverY = 0;
  double speed = 0;
  double groundSpeed = 0;
  double attackClock = 0;
  double attackPulse = 0;
  double hitPulse = 0;
  double slow = 0;
  double poison = 0;
  double poisonClock = 0;
  bool preview = false;
  bool dead = false;
  bool phaseTriggered = false;
  int shield = 0;
  bool egged = false;
  double reviveClock = 0;
  bool invulnerable = false;
  String? anchorForBoss;
}

class Arrow {
  double x = 0;
  double y = 0;
  double width = 14;
  double height = 42;
  double vy = 0;
  double vx = 0;
  int pierce = 0;
  bool dead = false;
}

class Projectile {
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double width = 24;
  double height = 30;
  String frame = '';
  int damage = 1;
  String source = '';
  bool dead = false;
}

class Coin {
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double age = 0;
  bool dead = false;
}

class Effect {
  Effect(
    this.type,
    this.x,
    this.y,
    this.age,
    this.duration,
    this.size, [
    this.sheetKey,
  ]);

  String type;
  double x;
  double y;
  double age;
  double duration;
  double size;
  String? sheetKey;
}

class Label {
  Label(this.text, this.x, this.y, this.age, this.duration, this.color);

  String text;
  double x;
  double y;
  double age;
  double duration;
  String color;
}

/// Floating "+points" popup shown when an enemy dies.
class ScorePop {
  ScorePop(this.points, this.multiplier, this.x, this.y, this.big);

  final int points;
  final int multiplier;
  final double x;
  final double y;
  final bool big;
  double age = 0;
  double get duration => big ? 1.6 : 1.0;
}

class Particle {
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double age = 0;
  double duration = 0;
}

class _Scheduled {
  _Scheduled(this.at, this.fn);
  double at;
  void Function() fn;
}

int _idCounter = 0;

class CombatWorld {
  CombatWorld({
    required this.area,
    required this.areaIndex,
    required this.stats,
    required this.relics,
    required this.skin,
    required this.tuning,
    required this.audio,
    required this.callbacks,
    this.endless = false,
  }) {
    final maxHp = 5 + (skin.buffs['maxHp']?.toInt() ?? 0);
    player = Player(maxHp);
    player.groundShield = relics.contains(0);
    previewWave();
  }

  Area area;
  final int areaIndex;
  final Map<String, int> stats;
  final List<int> relics;
  final Skin skin;
  final Tuning tuning;
  final GameAudio audio;
  final WorldCallbacks callbacks;
  final bool endless;

  double width = 360;
  double height = 640;
  double groundY = 560;
  double time = 0;
  String state = 'ready';
  int wave = 1;
  double score = 0;
  int runCoins = 0;
  int combo = 0;
  int multiplier = 1;
  String cause = 'Serangan dari langit';
  double shake = 0;
  double flash = 0;
  List<EnemyTemplate> spawnQueue = [];
  double spawnClock = 0;
  double waveEnding = 0;
  Map<String, int> levels = {};
  List<Arrow> arrows = [];
  List<Enemy> enemies = [];
  List<Projectile> projectiles = [];
  List<Coin> coins = [];
  List<Effect> effects = [];
  List<Particle> particles = [];
  List<Label> labels = [];
  List<ScorePop> scorePops = [];
  late Player player;
  final List<_Scheduled> _scheduled = [];

  /// Practice mode (theme 1 tutorial): the player can't be hurt and waves
  /// never end on their own; the game feeds enemies in step by step.
  bool tutorial = false;
  int kills = 0;

  void _schedule(double delay, void Function() fn) {
    _scheduled.add(_Scheduled(time + delay, fn));
  }

  void resize(double w, double h) {
    final oldWidth = width;
    width = w;
    height = h;
    groundY = (height * (height / width < 1.25 ? 0.84 : 0.88)).roundToDouble();
    if (oldWidth != 0) player.x = (player.x / oldWidth) * width;
    player.x = _clamp(player.x, 38, width - 38);
  }

  void previewWave() {
    final e = createEnemy(area.common, true);
    enemies = [e];
    e.x = width * 0.5;
    e.y = math.max(105, height * 0.18);
  }

  void engage() {
    if (state != 'ready') return;
    if (wave > 1) {
      // Continuing a saved run: start the saved wave from scratch.
      startWave(wave);
      return;
    }
    state = 'active';
    final preview = enemies[0];
    preview.preview = false;
    final waveEnemies = makeWave(area, wave);
    spawnQueue = waveEnemies.sublist(1);
    spawnClock = 1.3;
  }

  void beginTutorial() {
    if (state != 'ready') return;
    state = 'active';
    tutorial = true;
    enemies = [];
    spawnQueue = [];
  }

  /// Leave practice mode and start the real wave 1 with a fresh player.
  void endTutorial() {
    tutorial = false;
    enemies = [];
    arrows = [];
    projectiles = [];
    coins = [];
    spawnQueue = [];
    _scheduled.clear();
    levels = {};
    score = 0;
    runCoins = 0;
    combo = 0;
    multiplier = 1;
    kills = 0;
    player
      ..hp = player.maxHp
      ..ultimate = 0
      ..rage = 0
      ..rageActive = 0
      ..meleeCooldown = 0
      ..skillOneCooldown = 0
      ..skillTwoCooldown = 0
      ..invulnerable = 0;
    startWave(1);
  }

  /// Practice enemy already standing on the ground (for the melee lesson).
  void spawnGroundEnemy(double x) {
    final e = createEnemy(area.common);
    e.state = 'ground';
    e.invulnerable = false;
    e.x = _clamp(x, 40, width - 40);
    e.y = groundY - e.height / 2;
    enemies.add(e);
  }

  void jump() {
    if (!['ready', 'active'].contains(state) || player.jump > 0.5) return;
    player.vy = math.max(430, height * 0.68);
    audio.play('jump');
  }

  void useAction(String action) {
    if (state != 'active') return;
    if (action == 'melee') meleeAttack();
    if (action == 'skill1') skillOne();
    if (action == 'skill2') skillTwo();
    if (action == 'ultimate') castUltimate();
  }

  void setAction(String name, [double duration = 0.5]) {
    player.action = name;
    player.actionTime = duration;
  }

  void meleeAttack() {
    final p = player;
    if (p.meleeCooldown > 0 || p.jump > 10) return;
    p.meleeCooldown = math.max(0.28, 0.62 * skin.buffs['cooldown']!);
    p.meleeCooldownMax = p.meleeCooldown;
    setAction('melee_attack', 0.42);
    final damage =
        32 *
        skin.buffs['damage']! *
        skin.buffs['melee']! *
        (p.rageActive > 0 ? skin.buffs['rageDamage']! : 1);
    int hits = 0;
    for (final enemy in enemies) {
      if (enemy.dead || enemy.state != 'ground') continue;
      if ((enemy.x - p.x).abs() < 105) {
        damageEnemy(enemy, damage, true);
        hits += 1;
      }
    }
    effects.add(
      Effect(
        'arrow_impact',
        p.x + p.facing * 55,
        groundY - 28,
        0,
        0.4,
        90,
        skin.effectsKey,
      ),
    );
    audio.play('melee', 1.0);
    audio.play(hits > 0 ? 'hit' : 'shoot', 1.1);
    if (hits > 0) vibrate(24);
  }

  void skillOne() {
    final p = player;
    if (p.skillOneCooldown > 0) return;
    p.skillOneCooldown =
        7 * skin.buffs['cooldown']! * tuning.skillCooldownScale;
    p.skillOneCooldownMax = p.skillOneCooldown;
    setAction('skill_one', 0.65);
    final damage = 38 * skin.buffs['damage']! * skin.buffs['skillDamage']!;
    for (int i = 0; i < 7; i += 1) {
      final x = width * (0.1 + i * 0.133);
      effects.add(
        Effect(
          'skill_one_fx',
          x,
          height * 0.58,
          i * -0.035,
          0.75,
          110,
          skin.effectsKey,
        ),
      );
    }
    for (final enemy in enemies) {
      if (!enemy.dead) damageEnemy(enemy, damage, false, true);
    }
    p.ultimate = _clamp(p.ultimate + 12 * skin.buffs['ultGain']!, 0, 100);
    audio.play('skill1', 1.0);
    audio.play('warning', 0.8);
    shake = 8;
  }

  void skillTwo() {
    final p = player;
    if (p.skillTwoCooldown > 0) return;
    p.skillTwoCooldown =
        11 * skin.buffs['cooldown']! * tuning.skillCooldownScale;
    p.skillTwoCooldownMax = p.skillTwoCooldown;
    setAction('skill_two', 0.72);
    final damage = 24 * skin.buffs['damage']! * skin.buffs['skillDamage']!;
    effects.add(
      Effect(
        'skill_two_fx',
        p.x,
        groundY,
        0,
        0.85,
        math.min(width * 0.8, 300),
        skin.effectsKey,
      ),
    );
    for (final enemy in enemies) {
      if (enemy.dead) continue;
      enemy.slow = math.max(enemy.slow, 2.5);
      damageEnemy(enemy, damage, false, true);
    }
    if (skin.buffs['healSkill'] == 1) {
      p.hp = math.min(p.maxHp, p.hp + 1);
    }
    p.ultimate = _clamp(p.ultimate + 10 * skin.buffs['ultGain']!, 0, 100);
    audio.play('skill2', 1.0);
    audio.play('upgrade', 0.9);
  }

  void castUltimate() {
    final p = player;
    if (p.ultimate < 100) return;
    p.ultimate = 0;
    setAction('ultimate', 1.05);
    effects.add(
      Effect(
        'ultimate_fx',
        width / 2,
        groundY,
        0,
        1.1,
        math.max(width * 0.92, 280),
        skin.effectsKey,
      ),
    );
    final damage = 190 * skin.buffs['damage']! * skin.buffs['skillDamage']!;
    for (final enemy in enemies) {
      if (!enemy.dead) damageEnemy(enemy, damage, true, true);
    }
    projectiles = [];
    shake = 20;
    flash = 0.14;
    audio.play('ultimate', 1.0);
    audio.play('warning', 1.5);
    vibrate([45, 25, 80]);
  }

  void addRage(double value) {
    final p = player;
    if (p.rageActive > 0) return;
    p.rage = _clamp(p.rage + value, 0, 100);
    if (p.rage >= 100) {
      p.rage = 100;
      p.rageActive = tuning.rageDuration + (relics.contains(18) ? 3 : 0);
      callbacks.onBanner('RAGE LANGIT AKTIF');
      audio.play('rage', 1.0);
      audio.play('warning', 1.2);
      vibrate([30, 20, 50]);
    }
  }

  Enemy createEnemy(EnemyTemplate template, [bool preview = false]) {
    final hpScale = tuning.enemyHpScale * (endless ? 1 + (wave - 1) * 0.08 : 1);
    final hover =
        template.kind == 'mini' ||
        template.kind == 'boss' ||
        ['phase', 'tracking', 'fallenAngel'].contains(template.behavior);
    final enemy = Enemy(template);
    enemy.x = 50 + rng.nextDouble() * math.max(10, width - 100);
    enemy.y = preview ? 110 : -template.size.toDouble();
    enemy.width = template.size.toDouble();
    enemy.height = template.size.toDouble();
    enemy.maxHp = (template.hp * hpScale).round();
    enemy.hp = enemy.maxHp;
    enemy.age = rng.nextDouble();
    enemy.state = hover ? 'hover' : 'fall';
    enemy.hoverY = template.kind == 'boss' ? height * 0.24 : height * 0.32;
    enemy.speed =
        (50 + areaIndex * 4 + rng.nextDouble() * 18) * tuning.fallSpeed;
    enemy.groundSpeed = 36 + areaIndex * 3;
    enemy.attackClock = template.kind == 'boss'
        ? 1.4
        : 1.8 + rng.nextDouble() * 1.5;
    enemy.preview = preview;
    enemy.invulnerable = template.behavior == 'gargoyle' && !hover;
    if (template.behavior == 'meteor') enemy.invulnerable = true;
    return enemy;
  }

  void startWave(int wave) {
    this.wave = wave;
    if (endless && wave > 1 && wave % 10 == 1) {
      area = AREAS[rng.nextInt(AREAS.length)];
      // areaIndex stays for tuning scaling consistency in this port
      callbacks.onAreaShift(area);
    }
    state = 'active';
    enemies = [];
    arrows = [];
    projectiles = [];
    waveEnding = 0;
    spawnQueue = endless ? makeEndlessWave(wave) : makeWave(area, wave);
    spawnClock = 0.25;
    if ((!endless && wave == 15) || (endless && wave % 10 == 0)) {
      // The boss banner switches the music to bgm_boss (see RuntuhGame).
      audio.play('warning', 1.2);
      callbacks.onBanner('BOSS · ${area.boss.name}');
    } else if (wave == 10) {
      audio.play('warning', 1.0);
      callbacks.onBanner('MINI-BOSS · ${area.mini.name}');
    } else {
      audio.play('wave_start', 1.0);
      callbacks.onBanner('WAVE $wave');
    }
    callbacks.onWaveStart?.call(this);
  }

  List<EnemyTemplate> makeEndlessWave(int wave) {
    if (wave % 10 == 0) {
      final a = AREAS[rng.nextInt(AREAS.length)];
      return [a.boss];
    }
    final count = math.min(15, 3 + (wave * 0.42).ceil());
    return List.generate(count, (_) {
      final a = AREAS[rng.nextInt(AREAS.length)];
      return rng.nextDouble() < math.min(0.5, 0.12 + wave * 0.015)
          ? a.rare
          : a.common;
    });
  }

  void resumeAfterUpgrade(String id) {
    applyUpgrade(id);
    startWave(wave + 1);
  }

  void applyUpgrade(String id) {
    levels[id] = (levels[id] ?? 0) + 1;
    if (id == 'heal') {
      player.hp = math.min(player.maxHp, player.hp + 2);
    }
    audio.play('upgrade');
  }

  void playerDamage(double amount, String cause, [bool groundHit = false]) {
    if (tutorial || player.invulnerable > 0 || state != 'active') return;
    if (groundHit && player.groundShield) {
      player.groundShield = false;
      callbacks.onBanner('AKAR MENAHAN BENTURAN');
      audio.play('hit');
      return;
    }
    player.hp -= amount.round();
    player.invulnerable = 1.15;
    combo = 0;
    multiplier = 1;
    this.cause = cause;
    shake = 10 * tuning.effectsIntensity;
    flash = 0.18;
    audio.play('hurt');
    vibrate([35, 20, 45]);
    if (player.hp <= 0) {
      if ((relics.contains(5) || skin.buffs['revive'] == 1) &&
          !player.revived) {
        player.revived = true;
        player.hp = 1;
        player.invulnerable = 2;
        callbacks.onBanner('BARA KEDUA');
      } else {
        state = 'defeat';
        callbacks.onDefeat(this);
      }
    }
  }

  void vibrate(dynamic pattern) {
    if (!callbacks.canVibrate()) return;
    // Haptics handled by platform layer; no-op here.
  }

  void shoot([double aimX = 0, double aimY = -1]) {
    final count = levels['double'] != null ? 2 : 1;
    final offsets = count == 2 ? [-9.0, 9.0] : [0.0];
    for (final offset in offsets) {
      final arrow = Arrow();
      arrow.x = player.x + offset;
      arrow.y = groundY - player.jump - math.min(68.0, height * 0.1);
      final speed = math.max(520.0, height * 0.9);
      arrow.vx = aimX * speed;
      arrow.vy = aimY * speed;
      arrow.pierce =
          (levels['pierce'] ?? 0) + (skin.buffs['pierce']?.toInt() ?? 0);
      arrows.add(arrow);
    }
    player.shootPulse = 0.24;
    audio.play('shoot', 0.75);
  }

  void spawnEnemy() {
    final template = spawnQueue.removeAt(0);
    final enemy = createEnemy(template);
    if (template.kind == 'boss') {
      enemy.y = -enemy.height;
      if (template.behavior == 'ancientCore') {
        int anchors = 0;
        for (int i = 0; i < 3; i += 1) {
          final anchor = createEnemy(area.rare);
          anchor.anchorForBoss = enemy.id;
          anchor.x = width * (0.25 + i * 0.25);
          anchor.y = height * (0.42 + (i % 2) * 0.08);
          anchor.state = 'hover';
          anchor.hoverY = anchor.y;
          enemies.add(anchor);
          anchors += 1;
        }
        enemy.shield = anchors;
      }
    }
    enemies.add(enemy);
  }

  void update(double dt, InputState input) {
    time += dt;
    flash = math.max(0, flash - dt);
    shake = math.max(0, shake - dt * 22);
    _processScheduled();
    updateEffects(dt);
    if (state != 'active') return;

    updatePlayer(dt, input);
    if (spawnQueue.isNotEmpty) {
      spawnClock -= dt;
      if (spawnClock <= 0) {
        spawnEnemy();
        final density = wave > 10 ? 0.82 : 1.0;
        spawnClock =
            tuning.spawnInterval * density * (0.75 + rng.nextDouble() * 0.5);
      }
    }
    updateArrows(dt);
    updateEnemies(dt);
    updateProjectiles(dt);
    updateCoins(dt);
    resolveCollisions();
    enemies = enemies.where((e) => !e.dead).toList();
    arrows = arrows
        .where(
          (a) =>
              !a.dead &&
              a.y > -80 &&
              a.y < height + 80 &&
              a.x > -80 &&
              a.x < width + 80,
        )
        .toList();
    projectiles = projectiles
        .where(
          (p) =>
              !p.dead &&
              p.y < height + 80 &&
              p.y > -80 &&
              p.x > -80 &&
              p.x < width + 80,
        )
        .toList();

    if (tutorial) return;
    if (spawnQueue.isEmpty && enemies.isEmpty && waveEnding == 0) {
      waveEnding = 1.1;
    }
    if (waveEnding != 0) {
      waveEnding -= dt;
      if (waveEnding <= 0) finishWave();
    }
  }

  void _processScheduled() {
    if (_scheduled.isEmpty) return;
    final due = <_Scheduled>[];
    for (final s in _scheduled) {
      if (time >= s.at) due.add(s);
    }
    if (due.isNotEmpty) {
      _scheduled.removeWhere((s) => due.contains(s));
      for (final s in due) {
        s.fn();
      }
    }
  }

  void updatePlayer(double dt, InputState input) {
    final p = player;
    final rageSpeed = p.rageActive > 0 ? 1.25 : 1;
    final baseSpeed =
        tuning.playerSpeed *
        (1 + (stats['moveSpeed'] ?? 0) * 0.08) *
        skin.buffs['moveSpeed']! *
        rageSpeed;
    double direction = (input.right ? 1 : 0) - (input.left ? 1 : 0);
    if (direction == 0) direction = input.moveX;
    if (direction == 0 && input.pointer && input.targetX != null) {
      final target = input.targetX!;
      final delta = target - p.x;
      direction = delta.abs() < 3 ? 0 : delta.sign;
      p.x += _clamp(delta, -baseSpeed * dt, baseSpeed * dt);
    } else {
      p.x += direction * baseSpeed * dt;
    }
    p.x = _clamp(p.x, 35, width - 35);
    p.move = direction;
    if (direction != 0) p.facing = direction.sign.toInt();
    if (p.jump > 0 || p.vy > 0) {
      p.jump += p.vy * dt;
      p.vy -= math.max(980, height * 1.55) * dt;
      if (p.jump <= 0) {
        p.jump = 0;
        p.vy = 0;
      }
    }
    p.invulnerable = math.max(0, p.invulnerable - dt);
    p.shootPulse = math.max(0, p.shootPulse - dt);
    p.actionTime = math.max(0, p.actionTime - dt);
    if (p.actionTime <= 0) p.action = null;
    p.meleeCooldown = math.max(0, p.meleeCooldown - dt);
    p.skillOneCooldown = math.max(0, p.skillOneCooldown - dt);
    p.skillTwoCooldown = math.max(0, p.skillTwoCooldown - dt);
    if (p.rageActive > 0) {
      p.rageActive = math.max(0, p.rageActive - dt);
      p.rage = math.max(
        0,
        p.rage -
            dt *
                (100 /
                    math.max(
                      1,
                      tuning.rageDuration + (relics.contains(18) ? 3 : 0),
                    )),
      );
    } else if (p.rage >= 100) {
      p.rage = 0;
    }
    p.shootClock -= dt;
    final fireRate =
        tuning.fireRate *
        (1 + (stats['fireRate'] ?? 0) * 0.09) *
        skin.buffs['fireRate']! *
        (p.rageActive > 0 ? 1.5 : 1);
    if (p.shootClock <= 0) {
      shoot(input.aimX, input.aimY);
      p.shootClock = 1 / fireRate;
    }
  }

  void updateArrows(double dt) {
    final wind = areaIndex == 2 && !relics.contains(2)
        ? math.sin(time * 1.7) * 24
        : 0;
    for (final arrow in arrows) {
      arrow.y += arrow.vy * dt;
      arrow.x += (arrow.vx + wind) * dt;
    }
  }

  void updateEnemies(double dt) {
    final p = player;
    // Iterate a snapshot: broodmother hatches and slime-king splits add to
    // [enemies] mid-loop, which would otherwise throw a
    // ConcurrentModificationError.
    for (final enemy in List.of(enemies)) {
      enemy.age += dt;
      enemy.hitPulse = math.max(0, enemy.hitPulse - dt);
      enemy.attackPulse = math.max(0, enemy.attackPulse - dt);
      enemy.slow = math.max(0, enemy.slow - dt);
      final slowFactor = enemy.slow > 0 ? 0.58 : 1;

      if (enemy.poison > 0) {
        enemy.poisonClock -= dt;
        if (enemy.poisonClock <= 0) {
          enemy.poisonClock = 0.45;
          damageEnemy(enemy, 2 * enemy.poison, false, true);
        }
      }

      if (enemy.egged) {
        enemy.reviveClock -= dt;
        if (enemy.reviveClock <= 0 && enemy.hp > 0) {
          enemy.egged = false;
          enemy.state = 'hover';
          enemy.y = height * 0.24;
          enemy.hp = math.max(enemy.hp, (enemy.maxHp * 0.42).round());
          callbacks.onBanner('PHOENIX BANGKIT');
        }
        continue;
      }

      if (enemy.state == 'fall') {
        double lateral = 0;
        if (['zigzag', 'spiral', 'glitch'].contains(enemy.behavior)) {
          lateral =
              math.sin(enemy.age * (enemy.behavior == 'glitch' ? 9 : 4.2)) * 55;
        }
        if (enemy.behavior == 'swoop') {
          lateral = math.sin(enemy.age * 3.4) * 38;
        }
        enemy.x += lateral * dt;
        enemy.y += enemy.speed * slowFactor * dt;
        if (enemy.y + enemy.height * 0.42 >= groundY) landEnemy(enemy);
      } else if (enemy.state == 'hover') {
        final enterSpeed = math.max(90, height * 0.16);
        if (enemy.y < enemy.hoverY) {
          enemy.y = math.min(enemy.hoverY, enemy.y + enterSpeed * dt);
        }
        enemy.x +=
            math.sin(enemy.age * (enemy.kind == 'boss' ? 0.9 : 1.7)) *
            (enemy.kind == 'boss' ? 32 : 22) *
            dt;
        enemy.x = _clamp(
          enemy.x,
          enemy.width * 0.45,
          width - enemy.width * 0.45,
        );
        if (enemy.behavior == 'gravity') {
          final pull = (enemy.x - p.x).sign * 26;
          p.x += pull * dt;
        }
        enemy.attackClock -= dt;
        if (enemy.attackClock <= 0) enemyAttack(enemy);
      } else if (enemy.state == 'ground') {
        final direction = (p.x - enemy.x).sign == 0 ? 1 : (p.x - enemy.x).sign;
        enemy.x += direction * enemy.groundSpeed * slowFactor * dt;
        enemy.x = _clamp(enemy.x, 25, width - 25);
        enemy.attackClock -= dt;
        if ((p.x - enemy.x).abs() < (enemy.width + 42) * 0.42 &&
            p.jump < 28 &&
            enemy.attackClock <= 0) {
          enemy.attackPulse = 0.4;
          enemy.attackClock = 1.25;
          playerDamage(
            enemy.kind == 'rare' ? 2 : 1,
            '${enemy.name} menyerang dari tanah',
            true,
          );
        }
      }

      if (enemy.behavior == 'phase') {
        enemy.invulnerable = math.sin(enemy.age * 2.4) < -0.2;
      }
      if (enemy.behavior == 'fallenAngel') {
        enemy.invulnerable = enemy.attackPulse <= 0;
      }
      if (enemy.behavior == 'slimeKing' &&
          !enemy.phaseTriggered &&
          enemy.hp < enemy.maxHp * 0.3) {
        enemy.phaseTriggered = true;
        enemy.state = 'ground';
        enemy.y = groundY - enemy.height / 2;
        for (int i = 0; i < 2; i += 1) {
          final split = createEnemy(area.common);
          split.state = 'ground';
          split.x = _clamp(enemy.x + (i == 0 ? -55 : 55), 30, width - 30);
          split.y = groundY - split.height / 2;
          enemies.add(split);
        }
        callbacks.onBanner('RAJA SLIME PECAH');
      }
    }
  }

  void landEnemy(Enemy enemy) {
    enemy.y = groundY - enemy.height / 2;
    if (enemy.behavior == 'meteor') {
      effects.add(Effect('fire_explosion', enemy.x, groundY, 0, 0.55, 110));
      if ((player.x - enemy.x).abs() < 80 && player.jump < 34) {
        playerDamage(2, 'Batu Api menghantam tanah', true);
      }
      enemy.dead = true;
      shake = 12;
      audio.play('land', 1.2);
      return;
    }
    enemy.state = 'ground';
    enemy.invulnerable = false;
    enemy.attackClock = 0.55;
    combo = 0;
    multiplier = 1;
    effects.add(Effect('landing', enemy.x, groundY, 0, 0.45, 90));
    audio.play('land', enemy.kind == 'rare' ? 1.1 : 0.7);
    shake = math.max(shake, 4);
  }

  void enemyAttack(Enemy enemy) {
    enemy.attackPulse = enemy.kind == 'boss' ? 0.75 : 0.48;
    enemy.attackClock =
        (enemy.kind == 'boss' ? 1.45 : 2.05) + rng.nextDouble() * 0.85;
    final aimed = math.atan2(groundY - enemy.y, player.x - enemy.x);
    const projectileSet = [
      'thorn_fruit',
      'spider_egg',
      'blade_feather',
      'venom_glob',
      'cyan_orb',
      'fireball',
      'cyan_orb',
      'lightning_javelin',
      'meteor',
      'void_orb',
    ];
    final projectileName =
        projectileSet[(enemy.sourceArea ?? areaIndex) % projectileSet.length];
    final speed = 140 + areaIndex * 8;
    final count = enemy.kind == 'boss'
        ? (enemy.hp < enemy.maxHp * 0.5 ? 5 : 3)
        : 1;
    if (['lich', 'beam', 'tracking', 'voidLord'].contains(enemy.behavior)) {
      final ex = player.x;
      effects.add(Effect('laser', ex, groundY, 0, 0.65, height));
      audio.play('warning');
      _schedule(0.52, () {
        if (state == 'active' && (player.x - ex).abs() < 28) {
          playerDamage(
            enemy.kind == 'boss' ? 2 : 1,
            '${enemy.name} menembakkan laser',
          );
        }
      });
      return;
    }
    if ([
          'primate',
          'windDragon',
          'angelDive',
          'gauntlet',
        ].contains(enemy.behavior) &&
        rng.nextDouble() < 0.45) {
      final targetX = player.x;
      effects.add(Effect('dive', targetX, groundY, 0, 0.7, 95));
      audio.play('warning');
      _schedule(0.58, () {
        if (state == 'active' &&
            (player.x - targetX).abs() < 62 &&
            player.jump < 42) {
          playerDamage(2, '${enemy.name} menghantam tanah', true);
          shake = 13;
        }
      });
      return;
    }
    if (enemy.behavior == 'broodmother') {
      final hatch = createEnemy(area.common);
      hatch.x = enemy.x;
      hatch.y = enemy.y + 20;
      enemies.add(hatch);
      return;
    }
    if (enemy.behavior == 'thunderGod') {
      final lanes = [
        for (final lane in [0.2, 0.5, 0.8]) width * lane,
      ];
      for (final laneX in lanes) {
        effects.add(Effect('laser', laneX, groundY, 0, 0.55, height));
      }
      audio.play('warning');
      _schedule(0.45, () {
        if (state == 'active' &&
            lanes.any((laneX) => (player.x - laneX).abs() < 28)) {
          playerDamage(
            enemy.kind == 'boss' ? 2 : 1,
            '${enemy.name} memanggil petir',
          );
        }
      });
      return;
    }
    for (int i = 0; i < count; i += 1) {
      final spread = (i - (count - 1) / 2) * 0.18;
      final proj = Projectile();
      proj.x = enemy.x;
      proj.y = enemy.y + enemy.height * 0.25;
      proj.vx = math.cos(aimed + spread) * speed;
      proj.vy = math.sin(aimed + spread) * speed;
      proj.width = enemy.kind == 'boss' ? 34 : 24;
      proj.height = enemy.kind == 'boss' ? 42 : 30;
      proj.frame = projectileName;
      proj.damage = enemy.kind == 'boss' ? 2 : 1;
      proj.source = enemy.name;
      projectiles.add(proj);
    }
  }

  void updateProjectiles(double dt) {
    for (final proj in projectiles) {
      proj.x += proj.vx * dt;
      proj.y += proj.vy * dt;
      final px = player.x;
      final py = groundY - player.jump - 48;
      if (_dist(proj.x, proj.y, px, py) < 24 && player.invulnerable <= 0) {
        proj.dead = true;
        playerDamage(proj.damage.toDouble(), '${proj.source} mengenai Asha');
      }
    }
  }

  void resolveCollisions() {
    for (final arrow in arrows) {
      if (arrow.dead) continue;
      for (final enemy in enemies) {
        if (enemy.dead || enemy.preview) continue;
        if ((arrow.x - enemy.x).abs() > enemy.width * 0.42) continue;
        if ((arrow.y - enemy.y).abs() > enemy.height * 0.45) continue;
        final critChance = 0.08 + (levels['crit'] ?? 0) * 0.12;
        final critical = rng.nextDouble() < critChance;
        var damage =
            (10 + (stats['damage'] ?? 0) * 2.4) *
            skin.buffs['damage']! *
            (critical ? 2 : 1) *
            (player.rageActive > 0 ? skin.buffs['rageDamage']! : 1);
        if (enemy.kind == 'boss') damage *= 0.85;
        if (enemy.behavior == 'tornado') enemy.y -= 22;
        damageEnemy(enemy, damage, critical);
        if (levels['frost'] != null) enemy.slow = 0.7 + levels['frost']! * 0.16;
        if (levels['poison'] != null || skin.buffs['poison'] == 1) {
          enemy.poison = math.min(4, (levels['poison'] ?? 0) + 1).toDouble();
          enemy.poisonClock = 0.25;
        }
        if (levels['fire'] != null) {
          areaDamage(
            enemy,
            damage * (0.24 + levels['fire']! * 0.08),
            78,
            enemy,
          );
        }
        if (levels['lightning'] != null) {
          chainDamage(enemy, damage * (0.28 + levels['lightning']! * 0.07));
        }
        if (arrow.pierce > 0) {
          arrow.pierce -= 1;
          effects.add(Effect('pierce_flash', enemy.x, enemy.y, 0, 0.32, 58));
        } else {
          arrow.dead = true;
        }
        break;
      }
    }
  }

  void damageEnemy(
    Enemy enemy,
    double amount,
    bool critical, [
    bool dot = false,
  ]) {
    if (enemy.dead || enemy.invulnerable) {
      if (!dot) {
        effects.add(Effect('shield', enemy.x, enemy.y, 0, 0.35, enemy.width));
      }
      return;
    }
    if (enemy.kind == 'boss' &&
        enemy.behavior == 'ancientCore' &&
        enemy.shield > 0) {
      effects.add(Effect('shield', enemy.x, enemy.y, 0, 0.35, enemy.width));
      return;
    }
    enemy.hp -= amount.round();
    enemy.hitPulse = 0.12;
    addRage(math.min(5, amount * 0.045));
    player.ultimate = _clamp(
      player.ultimate + math.min(3.5, amount * 0.025) * skin.buffs['ultGain']!,
      0,
      100,
    );
    if (!dot) {
      final type = levels['frost'] != null
          ? 'frost_burst'
          : levels['poison'] != null
          ? 'poison_splash'
          : 'arrow_impact';
      effects.add(
        Effect(
          type,
          enemy.x,
          enemy.y,
          0,
          0.45,
          critical ? 82 : 58,
          type == 'arrow_impact' ? skin.effectsKey : null,
        ),
      );
      labels.add(
        Label(
          '${amount.round()}${critical ? '!' : ''}',
          enemy.x,
          enemy.y,
          0,
          0.55,
          critical ? '#fff0a0' : '#ffffff',
        ),
      );
      audio.play('hit', critical ? 1.25 : 0.65);
    }
    if (enemy.hp <= 0) killEnemy(enemy);
  }

  void areaDamage(Enemy origin, double amount, double radius, Enemy ignore) {
    effects.add(
      Effect('fire_explosion', origin.x, origin.y, 0, 0.5, radius * 1.4),
    );
    for (final enemy in enemies) {
      if (enemy == ignore || enemy.dead) continue;
      if (_dist(origin.x, origin.y, enemy.x, enemy.y) < radius) {
        damageEnemy(enemy, amount, false, true);
      }
    }
  }

  void chainDamage(Enemy origin, double amount) {
    Enemy? target;
    double best = 150;
    for (final enemy in enemies) {
      if (enemy == origin || enemy.dead) continue;
      final gap = _dist(origin.x, origin.y, enemy.x, enemy.y);
      if (gap < best) {
        best = gap;
        target = enemy;
      }
    }
    if (target != null) {
      effects.add(
        Effect(
          'chain_lightning',
          (origin.x + target.x) / 2,
          (origin.y + target.y) / 2,
          0,
          0.3,
          best,
        ),
      );
      damageEnemy(target, amount, false, true);
    }
  }

  void killEnemy(Enemy enemy) {
    if (enemy.behavior == 'phoenix' && !enemy.egged && !enemy.phaseTriggered) {
      enemy.phaseTriggered = true;
      enemy.egged = true;
      enemy.hp = (enemy.maxHp * 0.26).round();
      enemy.y = groundY - enemy.height * 0.3;
      enemy.reviveClock = 5;
      enemy.attackPulse = 1;
      callbacks.onBanner('HANCURKAN TELUR PHOENIX');
      return;
    }
    enemy.dead = true;
    kills += 1;
    if (enemy.anchorForBoss != null) {
      final boss = enemies.firstWhere(
        (e) => e.id == enemy.anchorForBoss,
        orElse: () => enemy,
      );
      if (boss != enemy) boss.shield = math.max(0, boss.shield - 1);
    }
    final airborne = enemy.state != 'ground' && !enemy.egged;
    if (airborne) {
      combo += 1;
      multiplier = math.min(5, 1 + (combo / 4).floor());
    } else {
      combo = 0;
      multiplier = 1;
    }
    final base = {
      'common': 90,
      'rare': 220,
      'mini': 1200,
      'boss': 5500,
    }[enemy.kind]!;
    score += base * multiplier;
    if (!tutorial) {
      scorePops.add(
        ScorePop(
          base * multiplier,
          multiplier,
          enemy.x,
          enemy.y - enemy.height * 0.35,
          enemy.kind == 'mini' || enemy.kind == 'boss',
        ),
      );
    }
    addRage(
      {'common': 6, 'rare': 12, 'mini': 24, 'boss': 45}[enemy.kind]!.toDouble(),
    );
    player.ultimate = _clamp(
      player.ultimate +
          {'common': 4, 'rare': 8, 'mini': 18, 'boss': 35}[enemy.kind]! *
              skin.buffs['ultGain']!,
      0,
      100,
    );
    if ((skin.id >= 16 || relics.contains(17)) &&
        enemy.state == 'ground' &&
        rng.nextDouble() < 0.2) {
      player.hp = math.min(player.maxHp, player.hp + 1);
    }
    final coinCount = math.min(8, enemy.template.reward);
    for (int i = 0; i < coinCount; i += 1) {
      final coin = Coin();
      coin.x = enemy.x + (rng.nextDouble() - 0.5) * 35;
      coin.y = enemy.y;
      coin.vx = (rng.nextDouble() - 0.5) * 80;
      coin.vy = -60 - rng.nextDouble() * 60;
      coins.add(coin);
    }
    final effectType = {
      'common': 'common_death',
      'rare': 'rare_death',
      'mini': 'miniboss_death',
      'boss': 'boss_finisher',
    }[enemy.kind]!;
    effects.add(
      Effect(
        effectType,
        enemy.x,
        enemy.y,
        0,
        enemy.kind == 'boss' ? 0.8 : 0.5,
        enemy.width * 1.35,
      ),
    );
    audio.play('death', enemy.kind == 'boss' ? 1.4 : 0.7);
    if (enemy.kind == 'boss') {
      audio.play('explosion', 1.0);
      shake = 18;
      vibrate([45, 30, 70]);
    }
  }

  void updateCoins(double dt) {
    final radius =
        70 + (levels['magnet'] ?? 0) * 42 + (relics.contains(6) ? 55 : 0);
    for (final coin in coins) {
      coin.age += dt;
      coin.vy += 190 * dt;
      coin.x += coin.vx * dt;
      coin.y += coin.vy * dt;
      coin.vx *= 0.98;
      if (coin.y > groundY - 8) {
        coin.y = groundY - 8;
        coin.vy *= -0.25;
      }
      final px = player.x;
      final py = groundY - player.jump - 30;
      final gap = _dist(coin.x, coin.y, px, py);
      if (gap < radius) {
        coin.x += (px - coin.x) * math.min(1, dt * 7);
        coin.y += (py - coin.y) * math.min(1, dt * 7);
      }
      if (gap < 20) {
        coin.dead = true;
        runCoins += 1;
        audio.play('coin', multiplier / 5);
      }
    }
    coins = coins.where((c) => !c.dead && c.age < 12).toList();
  }

  void updateEffects(double dt) {
    for (final e in effects) {
      e.age += dt;
    }
    for (final p in particles) {
      p.age += dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }
    for (final l in labels) {
      l.age += dt;
      l.y -= 32 * dt;
    }
    for (final s in scorePops) {
      s.age += dt;
    }
    scorePops = scorePops.where((s) => s.age < s.duration).toList();
    effects = effects.where((e) => e.age < e.duration).toList();
    particles = particles.where((p) => p.age < p.duration).toList();
    labels = labels.where((l) => l.age < l.duration).toList();
  }

  void finishWave() {
    waveEnding = 0;
    if (endless) {
      if (wave % 5 == 0) {
        state = 'upgrade';
        callbacks.onUpgrade(this);
      } else {
        startWave(wave + 1);
      }
      return;
    }
    if (wave == 15) {
      state = 'victory';
      callbacks.onVictory(this);
      return;
    }
    if (wave == 5 || wave == 10) {
      state = 'upgrade';
      callbacks.onUpgrade(this);
      return;
    }
    startWave(wave + 1);
  }
}
