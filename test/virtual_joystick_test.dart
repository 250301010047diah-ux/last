import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:runtuh/game/data.dart';
import 'package:runtuh/game/world.dart';
import 'package:runtuh/ui/virtual_joystick.dart';

void main() {
  testWidgets('two sticks respond independently and reset on release', (tester) async {
    Offset movement = Offset.zero;
    Offset aim = Offset.zero;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            VirtualJoystick(
              label: 'Gerak',
              color: Colors.cyan,
              onChanged: (value) => movement = value,
            ),
            VirtualJoystick(
              label: 'Bidik',
              color: Colors.orange,
              onChanged: (value) => aim = value,
            ),
          ],
        ),
      ),
    ));

    final sticks = find.byType(VirtualJoystick);
    final left = await tester.startGesture(tester.getCenter(sticks.at(0)), pointer: 1);
    final right = await tester.startGesture(tester.getCenter(sticks.at(1)), pointer: 2);
    await left.moveBy(const Offset(-40, 0));
    await right.moveBy(const Offset(35, -20));
    await tester.pump();
    expect(movement.dx, lessThan(-0.9));
    expect(aim.dx, greaterThan(0.5));
    expect(aim.dy, lessThan(-0.3));

    await left.up();
    await tester.pump();
    expect(movement, Offset.zero);
    expect(aim, isNot(Offset.zero));
    await right.up();
    await tester.pump();
    expect(aim, Offset.zero);
    expect(tester.takeException(), isNull);
  });

  test('arrows follow aim while neutral shooting remains upward', () {
    final world = CombatWorld(
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
    );
    world.shoot();
    expect(world.arrows.last.vx, 0);
    expect(world.arrows.last.vy, lessThan(0));

    world.shoot(1, 0);
    final aimed = world.arrows.last;
    final initialX = aimed.x;
    expect(aimed.vx, greaterThan(0));
    expect(aimed.vy, 0);
    world.updateArrows(0.1);
    expect(aimed.x, greaterThan(initialX));
  });
}
