import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:runtuh/ui/action_button.dart';

void main() {
  testWidgets('action buttons render every state and fire on tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            ActionButton(
                label: 'MELEE', icon: Icons.flare, color: Colors.orange, onTap: () => taps++),
            const ActionButton(
                label: 'SKILL1',
                icon: Icons.bolt,
                color: Colors.yellow,
                onTap: _noop,
                cooldown: 3.4,
                cooldownMax: 7),
            const ActionButton(
                label: 'ULTI', icon: Icons.whatshot, color: Colors.pink, onTap: _noop, charge: 1),
            const ActionButton(
                label: 'LOMPAT',
                icon: Icons.arrow_upward,
                color: Colors.cyan,
                onTap: _noop,
                enabled: false,
                highlight: true),
          ],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('4'), findsOneWidget); // 3.4 s left rounds up
    expect(find.text('SIAP!'), findsOneWidget); // full ultimate
    await tester.tap(find.text('MELEE'));
    expect(taps, 1);
  });
}

void _noop() {}
