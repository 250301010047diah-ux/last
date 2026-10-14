import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:runtuh/game/data.dart';
import 'package:runtuh/game/game.dart';
import 'package:runtuh/game/world.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('theme 1 practice walks through every step into the real wave 1', () {
    final audio = NoopAudio();
    final game = RuntuhGame(audio: audio)..onGameResize(Vector2(360, 640));
    final w = CombatWorld(
      area: AREAS[0],
      areaIndex: 0,
      stats: const {},
      relics: const [],
      skin: SKINS[0],
      tuning: Tuning(),
      audio: audio,
      callbacks: WorldCallbacks(
        onBanner: (_) {},
        onUpgrade: (_) {},
        onDefeat: (_) {},
        onVictory: (_) {},
        onAreaShift: (_) {},
        canVibrate: () => false,
      ),
    )..resize(360, 640);
    game.combat = w;
    game.phase = GamePhase.ready;
    game.tutorialPending = true;

    void tick([double seconds = 1 / 60]) {
      for (double t = 0; t < seconds; t += 1 / 60) {
        game.update(1 / 60);
      }
    }

    void finishStep(int expected) {
      expect(game.tutorialStep, expected);
      tick();
      expect(game.tutorialStepCompleted, isTrue, reason: 'step $expected');
      tick(1.3);
    }

    game.engage();
    expect(game.inTutorial, isTrue);
    expect(w.tutorial, isTrue);
    expect(w.enemies, isEmpty);

    // 0: move both ways.
    w.player.x -= 60;
    tick();
    w.player.x += 120;
    finishStep(0);

    // 1: jump.
    w.jump();
    tick(0.1);
    finishStep(1);

    // 2: three kills (the player can't be hurt meanwhile).
    final hp = w.player.hp;
    w.kills += 3;
    finishStep(2);
    expect(w.player.hp, hp);

    // 3: a monster is waiting on the ground for the melee lesson.
    expect(w.enemies.any((e) => e.state == 'ground'), isTrue);
    w.kills += 1;
    finishStep(3);

    // 4-6: skills and ultimate.
    w.useAction('skill1');
    finishStep(4);
    w.useAction('skill2');
    finishStep(5);
    expect(w.player.ultimate, 100);
    w.useAction('ultimate');
    finishStep(6);

    expect(game.inTutorial, isFalse);
    expect(w.tutorial, isFalse);
    expect(w.wave, 1);
    expect(w.state, 'active');
    expect(w.spawnQueue, isNotEmpty);
    expect(w.score, 0);
    expect(w.player.hp, w.player.maxHp);
  });
}
