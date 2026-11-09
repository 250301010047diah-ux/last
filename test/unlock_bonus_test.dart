import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:runtuh/game/data.dart';
import 'package:runtuh/game/game.dart';
import 'package:runtuh/game/save.dart';
import 'package:runtuh/game/world.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bonus unlocks everything and keeps coins unlimited after reload',
    () async {
      SharedPreferences.setMockInitialValues({});
    final game = RuntuhGame(audio: NoopAudio());
      await game.save.load();

      expect(game.isSkinUnlocked(0), isTrue);
      expect(game.isAreaUnlocked(0), isTrue);
      expect(game.isSkinUnlocked(1), isFalse);
      expect(game.isAreaUnlocked(1), isFalse);

      game.unlockEverything();
      expect(game.save.unlimitedCoins, isTrue);
      expect(game.save.totalCoins, greaterThanOrEqualTo(999999));
      expect(
        List.generate(SKINS.length, game.isSkinUnlocked),
        everyElement(isTrue),
      );
      expect(
        List.generate(AREAS.length, game.isAreaUnlocked),
        everyElement(isTrue),
      );

      final before = game.save.totalCoins;
      expect(game.spendCoins(before + 1), isTrue);
      expect(game.save.totalCoins, before);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      final reloaded = SaveStore();
      await reloaded.load();
      expect(reloaded.unlimitedCoins, isTrue);
      expect(reloaded.unlockedSkins.length, SKINS.length);
      expect(reloaded.unlockedAreas.length, AREAS.length);
      expect(reloaded.totalCoins, before);
    },
  );
}
