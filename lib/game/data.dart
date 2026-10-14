// Port of game js/game/data.js
import 'dart:math';

final Random rng = Random();

class EnemyTemplate {
  EnemyTemplate({
    required this.kind,
    required this.name,
    required this.moveAnim,
    required this.attackAnim,
    required this.behavior,
    required this.hp,
    required this.reward,
    required this.size,
    this.moveKey,
    this.attackKey,
    this.sourceArea,
  });

  final String kind;
  final String name;
  final String moveAnim;
  final String attackAnim;
  final String behavior;
  final int hp;
  final int reward;
  final int size;
  String? moveKey;
  String? attackKey;
  int? sourceArea;

  EnemyTemplate copy() => EnemyTemplate(
        kind: kind,
        name: name,
        moveAnim: moveAnim,
        attackAnim: attackAnim,
        behavior: behavior,
        hp: hp,
        reward: reward,
        size: size,
        moveKey: moveKey,
        attackKey: attackKey,
        sourceArea: sourceArea,
      );
}

class Area {
  Area({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.accent,
    required this.backgroundKey,
    required this.groundKey,
    required this.moveKey,
    required this.attackKey,
    required this.common,
    required this.rare,
    required this.mini,
    required this.boss,
  });

  final int id;
  final String name;
  final String subtitle;
  final String accent;
  final String backgroundKey;
  final String groundKey;
  final String moveKey;
  final String attackKey;
  final EnemyTemplate common;
  final EnemyTemplate rare;
  final EnemyTemplate mini;
  final EnemyTemplate boss;
}

class Upgrade {
  Upgrade({
    required this.id,
    required this.icon,
    required this.label,
    required this.detail,
    required this.element,
  });

  final String id;
  final String icon;
  final String label;
  final String detail;
  final bool element;
}

class Skin {
  Skin({
    required this.id,
    required this.name,
    required this.buffLabel,
    required this.moveKey,
    required this.combatKey,
    required this.effectsKey,
    required this.buffs,
  });

  final int id;
  final String name;
  final String buffLabel;
  final String moveKey;
  final String combatKey;
  final String effectsKey;
  final Map<String, double> buffs;
}

const List<List<dynamic>> _roster = [
  ["Hutan Raksasa", "Akar dunia bergetar", "#f4b942",
    ["Ulat Lumut", "moss_grub_fall", "moss_grub_ground_attack", "crawl"],
    ["Laba-laba Racun", "poison_spider_descend", "poison_spider_spit", "zigzag"],
    ["Lebah Penjaga", "guardian_bee_hover", "guardian_bee_dive", "dive"],
    ["Raja Primata", "primate_king_hover", "primate_king_slam", "primate"]],
  ["Goa Stalaktit", "Gema dari langit-langit", "#62d9e8",
    ["Kelelawar Buta", "blind_bat_dive", "blind_bat_ground_attack", "swoop"],
    ["Slime Batu", "stone_slime_fall", "stone_slime_split", "split"],
    ["Gargoyle Retak", "cracked_gargoyle_fall", "cracked_gargoyle_awaken", "gargoyle"],
    ["Induk Laba-laba Goa", "cave_broodmother_hover", "cave_broodmother_lay_egg", "broodmother"]],
  ["Tebing Berangin", "Bidik menembus badai", "#9ee8ff",
    ["Gagak Pusaran", "spiral_crow_fly", "spiral_crow_ground_attack", "spiral"],
    ["Harpy Pisau", "blade_harpy_hover", "blade_harpy_feather_burst", "feathers"],
    ["Tornado Hidup", "living_tornado_spin", "living_tornado_knockback", "tornado"],
    ["Naga Angin", "wind_dragon_hover", "wind_dragon_dive", "windDragon"]],
  ["Rawa Berkabut", "Kabut menyembunyikan racun", "#a7f46a",
    ["Spora Racun", "poison_spore_fall", "poison_spore_cloud", "spore"],
    ["Katak Mutan", "mutant_frog_fall", "mutant_frog_leap", "frog"],
    ["Bunga Lidah", "tongue_flower_hover", "tongue_flower_lash", "vine"],
    ["Raja Slime Rawa", "swamp_slime_king_hover", "swamp_slime_king_split", "slimeKing"]],
  ["Reruntuhan Kastil", "Sumpah lama terbangun", "#83e7ff",
    ["Tengkorak Sumpah", "oath_skull_fall", "oath_skull_assemble", "assemble"],
    ["Arwah Penasaran", "curious_spirit_phase", "curious_spirit_strike", "phase"],
    ["Ksatria Zirah Terbang", "flying_knight_hover", "flying_knight_shield_attack", "shield"],
    ["Lich Mahkota", "crown_lich_hover", "crown_lich_laser_cast", "lich"]],
  ["Gunung Berapi", "Tanah sendiri ikut menyerang", "#ff774d",
    ["Batu Api", "fire_rock_fall", "fire_rock_impact", "meteor"],
    ["Elemental Bara", "ember_elemental_fall", "ember_elemental_explode", "bomb"],
    ["Kelelawar Magma", "magma_bat_hover", "magma_bat_flame", "flame"],
    ["Phoenix Abu", "ash_phoenix_hover", "ash_phoenix_egg", "phoenix"]],
  ["Pulau Terapung", "Mesin purba kembali menyala", "#58e5e8",
    ["Drone Pengintai", "scout_drone_fall", "scout_drone_shot", "drone"],
    ["Golem Laser", "laser_golem_descend", "laser_golem_beam", "beam"],
    ["Malaikat Batu", "stone_angel_hover", "stone_angel_dive", "angelDive"],
    ["Core Mesin Kuno", "ancient_core_hover", "ancient_core_open", "ancientCore"]],
  ["Lautan Awan", "Petir memilih mangsanya", "#ffe16a",
    ["Awan Hitam", "black_cloud_drift", "black_cloud_rain", "rain"],
    ["Pegasus Liar", "wild_pegasus_dive", "wild_pegasus_charge", "pegasus"],
    ["Penunggang Awan", "cloud_rider_hover", "cloud_rider_lightning", "lightning"],
    ["Dewa Petir", "thunder_god_hover", "thunder_god_mirage", "thunderGod"]],
  ["Celah Kosmik", "Ruang tak lagi diam", "#cf73ff",
    ["Parasit Glitch", "glitch_parasite_phase", "glitch_parasite_strike", "glitch"],
    ["Mata Pelacak", "tracking_eye_hover", "tracking_eye_laser", "tracking"],
    ["Cumi Void", "void_squid_hover", "void_squid_pull", "gravity"],
    ["Cacing Dimensi", "rift_worm_hover", "rift_worm_meteor", "riftWorm"]],
  ["Singgasana Langit", "Satu panah melawan kehampaan", "#ff557d",
    ["Bayangan Asha", "asha_shadow_fall", "asha_shadow_shot", "shadow"],
    ["Malaikat Jatuh", "fallen_angel_hover", "fallen_angel_open_wings", "fallenAngel"],
    ["Gauntlet Penjaga", "guardian_gauntlet_hover", "guardian_gauntlet_slam", "gauntlet"],
    ["Penguasa Langit Void", "void_sky_lord_hover", "void_sky_lord_death_ray", "voidLord"]],
  ["Katedral Es", "Doa membeku sebelum terucap", "#b8f4ff",
    ["Roh Embun", "frost_wisp_fall", "frost_wisp_burst", "spore"],
    ["Serigala Es", "ice_wolf_dive", "ice_wolf_ground_bite", "frog"],
    ["Seraph Beku", "frozen_seraph_hover", "frozen_seraph_spear", "lightning"],
    ["Ratu Badai Es", "frost_queen_hover", "frost_queen_blizzard", "thunderGod"]],
  ["Jurang Jam", "Setiap detik ingin membunuhmu", "#67e8d5",
    ["Scarab Roda", "cog_scarab_fall", "cog_scarab_ground_spin", "spiral"],
    ["Automaton Laser", "laser_automaton_descend", "laser_automaton_shot", "beam"],
    ["Penjaga Waktu", "time_keeper_hover", "time_keeper_stop", "gravity"],
    ["Titan Chronos", "chronos_titan_hover", "chronos_titan_rewind", "ancientCore"]],
  ["Laut Langit", "Samudra jatuh dari atas", "#65ddff",
    ["Ubur Langit", "sky_jelly_fall", "sky_jelly_shock", "rain"],
    ["Penunggang Hiu", "shark_rider_dive", "shark_rider_charge", "pegasus"],
    ["Leviathan Karang", "coral_leviathan_hover", "coral_leviathan_wave", "flame"],
    ["Ratu Abyss", "abyss_merqueen_hover", "abyss_merqueen_trident", "broodmother"]],
  ["Sirkus Mimpi", "Tepuk tangan datang dari kegelapan", "#ff6ab7",
    ["Imp Kartu", "card_imp_fall", "card_imp_throw", "glitch"],
    ["Badut Marionet", "puppet_jester_descend", "puppet_jester_kick", "zigzag"],
    ["Ringmaster Mimpi", "nightmare_ringmaster_hover", "nightmare_ringmaster_hoop", "tracking"],
    ["Pemakan Mimpi", "dream_eater_hover", "dream_eater_devour", "voidLord"]],
  ["Gurun Tulang", "Fosil raksasa kembali terbang", "#f1b85d",
    ["Nasrul Tulang", "bone_vulture_dive", "bone_vulture_peck", "swoop"],
    ["Mumi Scarab", "scarab_mummy_fall", "scarab_mummy_swarm", "assemble"],
    ["Colossus Bukit", "dune_colossus_hover", "dune_colossus_slam", "gauntlet"],
    ["Kaisar Pasir", "sand_emperor_hover", "sand_emperor_storm", "windDragon"]],
  ["Bambu Bulan", "Roh pedang menjaga purnama", "#b594ff",
    ["Rubah Bulan", "moon_fox_fall", "moon_fox_flame", "glitch"],
    ["Tengu Bambu", "bamboo_tengu_dive", "bamboo_tengu_fan", "feathers"],
    ["Samurai Arwah", "spirit_samurai_hover", "spirit_samurai_slash", "shield"],
    ["Kitsune Purnama", "lunar_kitsune_hover", "lunar_kitsune_moonfall", "thunderGod"]],
  ["Sarang Prisma", "Cahaya pun punya taring", "#ed9cff",
    ["Kutu Kristal", "crystal_mite_fall", "crystal_mite_spike", "spiral"],
    ["Ngengat Prisma", "prism_moth_hover", "prism_moth_beam", "beam"],
    ["Penjaga Pecahan", "shard_guardian_hover", "shard_guardian_lance", "angelDive"],
    ["Induk Prisma", "prism_hive_mother_hover", "prism_hive_mother_refraction", "ancientCore"]],
  ["Kota Bulan Darah", "Atap merah tanpa matahari", "#ff526a",
    ["Gargoyle Darah", "blood_gargoyle_fall", "blood_gargoyle_claw", "gargoyle"],
    ["Revenant Senapan", "rifle_revenant_hover", "rifle_revenant_shot", "tracking"],
    ["Ksatria Vampir", "vampire_knight_hover", "vampire_knight_dive", "dive"],
    ["Countess Merah", "crimson_countess_hover", "crimson_countess_bloodmoon", "lich"]],
  ["Mahkota Pohon Dunia", "Akar terakhir menilai Asha", "#a9f36a",
    ["Binatang Benih", "seed_beast_fall", "seed_beast_sprout", "crawl"],
    ["Naga Akar", "root_drake_dive", "root_drake_thorn", "windDragon"],
    ["Ent Purba", "ancient_ent_hover", "ancient_ent_rootslam", "gauntlet"],
    ["Avatar Pohon Dunia", "world_tree_avatar_hover", "world_tree_avatar_starfall", "thunderGod"]],
  ["Ujung Waktu", "Tidak ada langit setelah ini", "#ff495f",
    ["Fragmen Waktu", "time_fragment_fall", "time_fragment_shatter", "glitch"],
    ["Asha Masa Depan", "future_clone_hover", "future_clone_arrow", "shadow"],
    ["Ksatria Paradoks", "paradox_knight_hover", "paradox_knight_split", "fallenAngel"],
    ["Pemangsa Aeon", "aeon_devourer_hover", "aeon_devourer_endtime", "voidLord"]],
];

EnemyTemplate _enemyFrom(List<String> row, String kind, int areaIndex) {
  const hpBase = {"common": 26, "rare": 58, "mini": 330, "boss": 1150};
  const reward = {"common": 1, "rare": 3, "mini": 15, "boss": 55};
  const size = {"common": 62, "rare": 78, "mini": 112, "boss": 176};
  return EnemyTemplate(
    kind: kind,
    name: row[0],
    moveAnim: row[1],
    attackAnim: row[2],
    behavior: row[3],
    hp: (hpBase[kind]! * (1 + areaIndex * 0.18)).round(),
    reward: reward[kind]!,
    size: size[kind]!,
  );
}

List<Area> _buildAreas() {
  final areas = <Area>[];
  for (int index = 0; index < _roster.length; index++) {
    final area = _roster[index];
    final moveKey = "ENEMY_AREA_${index + 1}_MOVE";
    final attackKey = "ENEMY_AREA_${index + 1}_ATTACK";
    EnemyTemplate decorate(EnemyTemplate enemy) {
      enemy.moveKey = moveKey;
      enemy.attackKey = attackKey;
      enemy.sourceArea = index;
      return enemy;
    }
    areas.add(Area(
      id: index + 1,
      name: area[0] as String,
      subtitle: area[1] as String,
      accent: area[2] as String,
      backgroundKey: "BG_AREA_${index + 1}",
      groundKey: "GROUND_AREA_${index + 1}",
      moveKey: moveKey,
      attackKey: attackKey,
      common: decorate(_enemyFrom(area[3] as List<String>, "common", index)),
      rare: decorate(_enemyFrom(area[4] as List<String>, "rare", index)),
      mini: decorate(_enemyFrom(area[5] as List<String>, "mini", index)),
      boss: decorate(_enemyFrom(area[6] as List<String>, "boss", index)),
    ));
  }
  return areas;
}

final List<Area> AREAS = _buildAreas();

final List<Upgrade> UPGRADES = [
  Upgrade(id: "double", icon: "double_arrow", label: "Panah Ganda", detail: "Tembakkan panah kedua", element: false),
  Upgrade(id: "pierce", icon: "pierce", label: "Tembus", detail: "+1 musuh tertembus", element: false),
  Upgrade(id: "crit", icon: "critical", label: "Mata Elang", detail: "+12% peluang kritis", element: false),
  Upgrade(id: "magnet", icon: "magnet", label: "Tarikan Koin", detail: "Jangkauan koin membesar", element: false),
  Upgrade(id: "heal", icon: "heart", label: "Napas Kedua", detail: "Pulihkan 2 hati", element: false),
  Upgrade(id: "frost", icon: "frost", label: "Frost Slow", detail: "Panah memperlambat jatuh", element: true),
  Upgrade(id: "fire", icon: "fire", label: "Ledakan Bara", detail: "Hit meledak di sekitar", element: true),
  Upgrade(id: "lightning", icon: "lightning", label: "Petir Rantai", detail: "Damage melompat ke target lain", element: true),
  Upgrade(id: "poison", icon: "poison", label: "Racun Bertumpuk", detail: "Damage berlanjut setelah hit", element: true),
];

final List<List<String>> RELICS = [
  ["Akar Penahan", "Benturan darat pertama ditahan"],
  ["Mata Jaring", "Bayangan jatuh muncul lebih awal"],
  ["Bulu Arus", "Panah menolak angin"],
  ["Inti Lentur", "Efek lambat berkurang"],
  ["Rune Retak", "Damage perisai meningkat"],
  ["Bara Kedua", "Bangkit sekali dengan satu hati"],
  ["Magnet Purba", "Tarikan koin lebih luas"],
  ["Mata Badai", "Kritis memicu petir kecil"],
  ["Kompas Void", "Portal memberi warning lebih lama"],
  ["Mahkota Langit", "Rage terisi lebih cepat"],
  ["Rosario Es", "Skill memperlambat lebih lama"],
  ["Pegas Retak", "Cooldown skill berkurang"],
  ["Mutiara Langit", "Maksimum hati bertambah"],
  ["Tiket Mimpi", "Combo tidak putus sekali"],
  ["Taring Fosil", "Melee memberi damage ekstra"],
  ["Topeng Purnama", "Lompatan memberi kebal singkat"],
  ["Inti Prisma", "Panah memantul satu kali"],
  ["Cawan Merah", "Kill darat memulihkan sedikit HP"],
  ["Benih Bintang", "Rage bertahan lebih lama"],
  ["Jarum Aeon", "Ultimate terisi lebih cepat"],
];

List<EnemyTemplate> makeWave(Area area, int wave) {
  if (wave == 15) return [area.boss];
  if (wave == 10) return [area.common, area.common, area.mini];
  if (wave == 5) return [area.common, area.rare, area.rare];
  final act = (wave / 5).ceil();
  final count = (2 + act + (wave * 0.58).ceil()).clamp(0, 14);
  final enemies = <EnemyTemplate>[];
  for (int i = 0; i < count; i += 1) {
    final rareChance = wave >= 3 ? (0.09 + wave * 0.025).clamp(0, 0.55) : 0.0;
    if (wave > 10 && i == count - 1 && rng.nextDouble() < 0.42) {
      enemies.add(area.mini);
    } else {
      enemies.add(rng.nextDouble() < rareChance ? area.rare : area.common);
    }
  }
  return enemies;
}

final List<List<String>> _skinNames = [
  ["Penjaga Akar", "Seimbang · akar menahan 1 hit"],
  ["Pemburu Bara", "+8% damage"],
  ["Paladin Embun", "+1 hati · slow kuat"],
  ["Valkyrie Badai", "+12% fire rate"],
  ["Bayangan Void", "+10% critical"],
  ["Penari Angin", "+18% move speed"],
  ["Benteng Batu", "+2 hati · melee kuat"],
  ["Ratu Racun", "Panah memberi racun"],
  ["Pewaris Phoenix", "Bangkit sekali"],
  ["Pemanah Surya", "+22% fire rate"],
  ["Penembus Bulan", "+1 pierce"],
  ["Mekanis Arcana", "Cooldown -18%"],
  ["Seraph Awan", "Skill 2 memulihkan HP"],
  ["Penyihir Rune", "Skill damage +35%"],
  ["Naga Langit", "Ultimate terisi +45%"],
  ["Pemburu Darah", "Rage +50% damage"],
  ["Saint Gading", "+3 hati · regenerasi"],
  ["Reaper Senja", "Melee +120% damage"],
  ["Mahkota Celestial", "+45% semua stat"],
  ["Permaisuri Void", "+80% semua stat · overpowered"],
];

Map<String, double> _skinBuffs(int index) {
  final tier = index / 19;
  final buffs = <String, double>{
    "damage": 1 + tier * 0.8 + (index == 1 ? 0.08 : 0),
    "fireRate": 1 + tier * 0.5 + (index == 3 ? 0.12 : index == 9 ? 0.22 : 0),
    "moveSpeed": 1 + tier * 0.35 + (index == 5 ? 0.18 : 0),
    "maxHp": (tier * 3).floorToDouble() + ([2, 6, 16].contains(index) ? (index == 16 ? 3 : index == 6 ? 2 : 1) : 0),
    "cooldown": (1 - tier * 0.35 - (index == 11 ? 0.18 : 0)).clamp(0.55, 1.5),
    "skillDamage": 1 + tier * 0.65 + (index == 13 ? 0.35 : 0),
    "melee": 1 + tier * 0.8 + (index == 17 ? 1.2 : 0),
    "ultGain": 1 + tier * 0.65 + (index == 14 ? 0.45 : 0),
    "rageDamage": 1.5 + tier * 0.35 + (index == 15 ? 0.5 : 0),
    "pierce": index >= 10 ? 1 : 0,
  };
  // revive / healSkill / poison are boolean-style flags stored as 1.0
  if ([8, 19].contains(index)) buffs["revive"] = 1;
  if ([12, 16, 19].contains(index)) buffs["healSkill"] = 1;
  if ([7, 19].contains(index)) buffs["poison"] = 1;
  return buffs;
}

final List<Skin> SKINS = _skinNames.asMap().entries.map((entry) {
  final index = entry.key;
  final name = entry.value[0];
  final buffLabel = entry.value[1];
  final number = (index + 1).toString().padLeft(2, "0");
  return Skin(
    id: index,
    name: name,
    buffLabel: buffLabel,
    moveKey: "SKIN_${number}_MOVE",
    combatKey: "SKIN_${number}_COMBAT",
    effectsKey: "SKIN_${number}_EFFECTS",
    buffs: _skinBuffs(index),
  );
}).toList();

List<Upgrade> upgradeChoices(Map<String, int> levels) {
  final elementCount = ["frost", "fire", "lightning", "poison"]
      .where((id) => (levels[id] ?? 0) > 0)
      .length;
  final pool = UPGRADES.where((u) => !u.element || (levels[u.id] ?? 0) > 0 || elementCount < 3).toList();
  final copy = [...pool];
  final choices = <Upgrade>[];
  while (choices.length < 3 && copy.isNotEmpty) {
    choices.add(copy.removeAt(rng.nextInt(copy.length)));
  }
  return choices;
}

class SaveData {
  SaveData({
    this.version = 2,
    this.unlockedArea = 1,
    this.coins = 0,
    this.bestScore = 0,
    this.stats = const {"damage": 0, "fireRate": 0, "moveSpeed": 0},
    this.relics = const [],
    this.endlessUnlocked = false,
    this.selectedSkin,
  });

  final int version;
  final int unlockedArea;
  final int coins;
  final int bestScore;
  final Map<String, int> stats;
  final List<int> relics;
  final bool endlessUnlocked;
  final int? selectedSkin;
}

final SaveData DEFAULT_SAVE = SaveData();

final List<String> bossPortraits = [
  "primate_king", "cave_broodmother", "wind_dragon", "swamp_slime_king",
  "crown_lich", "ash_phoenix", "ancient_core", "thunder_god", "rift_worm",
  "void_sky_lord",
];
