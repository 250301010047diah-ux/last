import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:runtuh/game/game.dart';
import 'package:runtuh/game/save.dart';
import 'package:runtuh/ui/main_menu.dart';

void main() {
  for (final size in const [Size(320, 568), Size(360, 640), Size(412, 915)]) {
    for (final withSave in [false, true]) {
      testWidgets('menu fits ${size.width}x${size.height} (save: $withSave)',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final game = RuntuhGame();
        if (withSave) {
          game.save.checkpoint = RunCheckpoint(
            area: 4,
            skin: 2,
            wave: 9,
            score: 5000,
            runCoins: 12,
            hp: 3,
            ultimate: 0,
            rage: 0,
            revived: false,
            levels: const {},
          );
        }
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: MainMenu(
              game: game,
              onVolume: () {},
              onHelp: () {},
              onStart: () {},
              onContinue: () {},
              onReset: () {},
            ),
          ),
        ));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel('Magitech Siege'), findsOneWidget);
        expect(find.text(withSave ? 'LANJUTKAN' : 'MULAI'), findsOneWidget);
      });
    }
  }
}
