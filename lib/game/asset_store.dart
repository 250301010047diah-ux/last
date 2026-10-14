import 'atlas.dart';
import 'asset_manifest.dart';
import 'data.dart';

class AssetStore {
  final Map<String, Sheet> items = {};
  final Map<String, Future<Sheet>> _loading = {};

  String _base(String key) {
    final base = assetManifest[key];
    if (base == null) throw Exception('Aset $key tidak ditemukan');
    return base;
  }

  Future<Sheet> load(String key, [bool withFrames = true]) {
    if (items.containsKey(key)) return Future.value(items[key]!);
    if (_loading.containsKey(key)) return _loading[key]!;
    final task = loadSheet(_base(key), withFrames);
    _loading[key] = task;
    task.then((sheet) {
      items[key] = sheet;
      _loading.remove(key);
    }).catchError((_) {
      _loading.remove(key);
    });
    return task;
  }

  Future<void> loadGlobal() => Future.wait([
        load("ASHA_MOVE_SHEET"),
        load("ASHA_COMBAT_SHEET"),
        load("PROJECTILE_ATLAS"),
        load("HUD_ICON_ATLAS"),
        load("ARROW_EFFECTS_A"),
        load("ARROW_EFFECTS_B"),
        load("ENEMY_DEATH_EFFECTS"),
        load("DANGER_EFFECTS"),
        load("BOSS_PORTRAIT_ATLAS"),
      ]);

  Future<void> loadArea(Area area) => Future.wait([
        load(area.backgroundKey, false),
        load(area.groundKey),
        load(area.moveKey),
        load(area.attackKey),
      ]);

  Future<void> loadSkin(Skin skin) => Future.wait([
        load(skin.moveKey),
        load(skin.combatKey),
        load(skin.effectsKey),
      ]);

  Sheet? get(String key) => items[key];
}
