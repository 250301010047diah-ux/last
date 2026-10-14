import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:runtuh/game/data.dart';
import 'package:runtuh/game/save.dart';
import 'package:runtuh/game/world.dart';

CombatWorld _world(Area area, {int areaIndex = 0}) {
  final w = CombatWorld(
    area: area,
    areaIndex: areaIndex,
    stats: const {},
    relics: const [],
    skin: SKINS[0],
    tuning: Tuning(),
    audio: NoopAudio(),
    callbacks: WorldCallbacks(
      onBanner: (_) {},
      onUpgrade: (_) {},
      onDefeat: (_) {},
      onVictory: (_) {},
      onAreaShift: (_) {},
      canVibrate: () => false,
    ),
  );
  w.resize(360, 640);
  return w;
}

void main() {
  test('data tables are complete', () {
    expect(AREAS.length, 20);
    expect(SKINS.length, 20);
  });

  test('special waves use mini-boss and boss', () {
    final area = AREAS[0];
    expect(makeWave(area, 15), [area.boss]);
    expect(makeWave(area, 10).last, area.mini);
  });

  test('upgradeChoices returns three distinct upgrades', () {
    final choices = upgradeChoices({});
    expect(choices.length, 3);
    expect(choices.map((u) => u.id).toSet().length, 3);
  });

  test('checkpoint survives a JSON round trip', () {
    final cp = RunCheckpoint(
      area: 3,
      skin: 5,
      wave: 7,
      score: 1234,
      runCoins: 40,
      hp: 3,
      ultimate: 55,
      rage: 20,
      revived: true,
      levels: {'double': 1, 'fire': 2},
      pendingUpgrade: true,
    );
    final back = RunCheckpoint.fromJson(jsonDecode(jsonEncode(cp.toJson())))!;
    expect(back.area, 3);
    expect(back.wave, 7);
    expect(back.score, 1234);
    expect(back.levels, {'double': 1, 'fire': 2});
    expect(back.pendingUpgrade, isTrue);
    expect(RunCheckpoint.fromJson('garbage'), isNull);
  });

  test('a resumed run starts its saved wave, including the boss wave', () {
    final area = AREAS[0];
    final w = _world(area);
    w.wave = 15;
    w.engage();
    expect(w.state, 'active');
    expect(w.spawnQueue, [area.boss]);
    expect(w.enemies, isEmpty);
  });

  test('enemies spawning mid-update do not crash the loop', () {
    // Area 2's boss is the broodmother, which hatches enemies while
    // updateEnemies is iterating.
    final area = AREAS[1];
    final w = _world(area, areaIndex: 1);
    w.engage();
    final boss = w.createEnemy(area.boss);
    boss.state = 'hover';
    boss.y = boss.hoverY;
    boss.attackClock = 0;
    w.enemies.add(boss);
    final before = w.enemies.length;
    w.updateEnemies(1 / 60);
    expect(w.enemies.length, greaterThan(before));
  });
}
