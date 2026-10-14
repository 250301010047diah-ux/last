import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:runtuh/game/data.dart';
import 'package:runtuh/game/game.dart';
import 'package:runtuh/game/world.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('arrows render in every colour variant without throwing', () {
    final game = RuntuhGame()..onGameResize(Vector2(360, 640));
    final w = CombatWorld(
      area: AREAS[0],
      areaIndex: 0,
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
    )..resize(360, 640);
    game.combat = w;
    game.phase = GamePhase.playing;
    w.shoot();
    w.time = 1.37;

    for (final level in [null, 'fire', 'frost', 'lightning', 'poison', 'rage']) {
      w.levels = {if (level != null && level != 'rage') level: 1};
      w.player.rageActive = level == 'rage' ? 3 : 0;
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      recorder.endRecording().dispose();
    }
  });
}
