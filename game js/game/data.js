const roster = [
  {
    name: "Hutan Raksasa",
    subtitle: "Akar dunia bergetar",
    accent: "#f4b942",
    common: ["Ulat Lumut", "moss_grub_fall", "moss_grub_ground_attack", "crawl"],
    rare: ["Laba-laba Racun", "poison_spider_descend", "poison_spider_spit", "zigzag"],
    mini: ["Lebah Penjaga", "guardian_bee_hover", "guardian_bee_dive", "dive"],
    boss: ["Raja Primata", "primate_king_hover", "primate_king_slam", "primate"],
  },
  {
    name: "Goa Stalaktit",
    subtitle: "Gema dari langit-langit",
    accent: "#62d9e8",
    common: ["Kelelawar Buta", "blind_bat_dive", "blind_bat_ground_attack", "swoop"],
    rare: ["Slime Batu", "stone_slime_fall", "stone_slime_split", "split"],
    mini: ["Gargoyle Retak", "cracked_gargoyle_fall", "cracked_gargoyle_awaken", "gargoyle"],
    boss: ["Induk Laba-laba Goa", "cave_broodmother_hover", "cave_broodmother_lay_egg", "broodmother"],
  },
  {
    name: "Tebing Berangin",
    subtitle: "Bidik menembus badai",
    accent: "#9ee8ff",
    common: ["Gagak Pusaran", "spiral_crow_fly", "spiral_crow_ground_attack", "spiral"],
    rare: ["Harpy Pisau", "blade_harpy_hover", "blade_harpy_feather_burst", "feathers"],
    mini: ["Tornado Hidup", "living_tornado_spin", "living_tornado_knockback", "tornado"],
    boss: ["Naga Angin", "wind_dragon_hover", "wind_dragon_dive", "windDragon"],
  },
  {
    name: "Rawa Berkabut",
    subtitle: "Kabut menyembunyikan racun",
    accent: "#a7f46a",
    common: ["Spora Racun", "poison_spore_fall", "poison_spore_cloud", "spore"],
    rare: ["Katak Mutan", "mutant_frog_fall", "mutant_frog_leap", "frog"],
    mini: ["Bunga Lidah", "tongue_flower_hover", "tongue_flower_lash", "vine"],
    boss: ["Raja Slime Rawa", "swamp_slime_king_hover", "swamp_slime_king_split", "slimeKing"],
  },
  {
    name: "Reruntuhan Kastil",
    subtitle: "Sumpah lama terbangun",
    accent: "#83e7ff",
    common: ["Tengkorak Sumpah", "oath_skull_fall", "oath_skull_assemble", "assemble"],
    rare: ["Arwah Penasaran", "curious_spirit_phase", "curious_spirit_strike", "phase"],
    mini: ["Ksatria Zirah Terbang", "flying_knight_hover", "flying_knight_shield_attack", "shield"],
    boss: ["Lich Mahkota", "crown_lich_hover", "crown_lich_laser_cast", "lich"],
  },
  {
    name: "Gunung Berapi",
    subtitle: "Tanah sendiri ikut menyerang",
    accent: "#ff774d",
    common: ["Batu Api", "fire_rock_fall", "fire_rock_impact", "meteor"],
    rare: ["Elemental Bara", "ember_elemental_fall", "ember_elemental_explode", "bomb"],
    mini: ["Kelelawar Magma", "magma_bat_hover", "magma_bat_flame", "flame"],
    boss: ["Phoenix Abu", "ash_phoenix_hover", "ash_phoenix_egg", "phoenix"],
  },
  {
    name: "Pulau Terapung",
    subtitle: "Mesin purba kembali menyala",
    accent: "#58e5e8",
    common: ["Drone Pengintai", "scout_drone_fall", "scout_drone_shot", "drone"],
    rare: ["Golem Laser", "laser_golem_descend", "laser_golem_beam", "beam"],
    mini: ["Malaikat Batu", "stone_angel_hover", "stone_angel_dive", "angelDive"],
    boss: ["Core Mesin Kuno", "ancient_core_hover", "ancient_core_open", "ancientCore"],
  },
  {
    name: "Lautan Awan",
    subtitle: "Petir memilih mangsanya",
    accent: "#ffe16a",
    common: ["Awan Hitam", "black_cloud_drift", "black_cloud_rain", "rain"],
    rare: ["Pegasus Liar", "wild_pegasus_dive", "wild_pegasus_charge", "pegasus"],
    mini: ["Penunggang Awan", "cloud_rider_hover", "cloud_rider_lightning", "lightning"],
    boss: ["Dewa Petir", "thunder_god_hover", "thunder_god_mirage", "thunderGod"],
  },
  {
    name: "Celah Kosmik",
    subtitle: "Ruang tak lagi diam",
    accent: "#cf73ff",
    common: ["Parasit Glitch", "glitch_parasite_phase", "glitch_parasite_strike", "glitch"],
    rare: ["Mata Pelacak", "tracking_eye_hover", "tracking_eye_laser", "tracking"],
    mini: ["Cumi Void", "void_squid_hover", "void_squid_pull", "gravity"],
    boss: ["Cacing Dimensi", "rift_worm_hover", "rift_worm_meteor", "riftWorm"],
  },
  {
    name: "Singgasana Langit",
    subtitle: "Satu panah melawan kehampaan",
    accent: "#ff557d",
    common: ["Bayangan Asha", "asha_shadow_fall", "asha_shadow_shot", "shadow"],
    rare: ["Malaikat Jatuh", "fallen_angel_hover", "fallen_angel_open_wings", "fallenAngel"],
    mini: ["Gauntlet Penjaga", "guardian_gauntlet_hover", "guardian_gauntlet_slam", "gauntlet"],
    boss: ["Penguasa Langit Void", "void_sky_lord_hover", "void_sky_lord_death_ray", "voidLord"],
  },
  {
    name: "Katedral Es",
    subtitle: "Doa membeku sebelum terucap",
    accent: "#b8f4ff",
    common: ["Roh Embun", "frost_wisp_fall", "frost_wisp_burst", "spore"],
    rare: ["Serigala Es", "ice_wolf_dive", "ice_wolf_ground_bite", "frog"],
    mini: ["Seraph Beku", "frozen_seraph_hover", "frozen_seraph_spear", "lightning"],
    boss: ["Ratu Badai Es", "frost_queen_hover", "frost_queen_blizzard", "thunderGod"],
  },
  {
    name: "Jurang Jam",
    subtitle: "Setiap detik ingin membunuhmu",
    accent: "#67e8d5",
    common: ["Scarab Roda", "cog_scarab_fall", "cog_scarab_ground_spin", "spiral"],
    rare: ["Automaton Laser", "laser_automaton_descend", "laser_automaton_shot", "beam"],
    mini: ["Penjaga Waktu", "time_keeper_hover", "time_keeper_stop", "gravity"],
    boss: ["Titan Chronos", "chronos_titan_hover", "chronos_titan_rewind", "ancientCore"],
  },
  {
    name: "Laut Langit",
    subtitle: "Samudra jatuh dari atas",
    accent: "#65ddff",
    common: ["Ubur Langit", "sky_jelly_fall", "sky_jelly_shock", "rain"],
    rare: ["Penunggang Hiu", "shark_rider_dive", "shark_rider_charge", "pegasus"],
    mini: ["Leviathan Karang", "coral_leviathan_hover", "coral_leviathan_wave", "flame"],
    boss: ["Ratu Abyss", "abyss_merqueen_hover", "abyss_merqueen_trident", "broodmother"],
  },
  {
    name: "Sirkus Mimpi",
    subtitle: "Tepuk tangan datang dari kegelapan",
    accent: "#ff6ab7",
    common: ["Imp Kartu", "card_imp_fall", "card_imp_throw", "glitch"],
    rare: ["Badut Marionet", "puppet_jester_descend", "puppet_jester_kick", "zigzag"],
    mini: ["Ringmaster Mimpi", "nightmare_ringmaster_hover", "nightmare_ringmaster_hoop", "tracking"],
    boss: ["Pemakan Mimpi", "dream_eater_hover", "dream_eater_devour", "voidLord"],
  },
  {
    name: "Gurun Tulang",
    subtitle: "Fosil raksasa kembali terbang",
    accent: "#f1b85d",
    common: ["Nasrul Tulang", "bone_vulture_dive", "bone_vulture_peck", "swoop"],
    rare: ["Mumi Scarab", "scarab_mummy_fall", "scarab_mummy_swarm", "assemble"],
    mini: ["Colossus Bukit", "dune_colossus_hover", "dune_colossus_slam", "gauntlet"],
    boss: ["Kaisar Pasir", "sand_emperor_hover", "sand_emperor_storm", "windDragon"],
  },
  {
    name: "Bambu Bulan",
    subtitle: "Roh pedang menjaga purnama",
    accent: "#b594ff",
    common: ["Rubah Bulan", "moon_fox_fall", "moon_fox_flame", "glitch"],
    rare: ["Tengu Bambu", "bamboo_tengu_dive", "bamboo_tengu_fan", "feathers"],
    mini: ["Samurai Arwah", "spirit_samurai_hover", "spirit_samurai_slash", "shield"],
    boss: ["Kitsune Purnama", "lunar_kitsune_hover", "lunar_kitsune_moonfall", "thunderGod"],
  },
  {
    name: "Sarang Prisma",
    subtitle: "Cahaya pun punya taring",
    accent: "#ed9cff",
    common: ["Kutu Kristal", "crystal_mite_fall", "crystal_mite_spike", "spiral"],
    rare: ["Ngengat Prisma", "prism_moth_hover", "prism_moth_beam", "beam"],
    mini: ["Penjaga Pecahan", "shard_guardian_hover", "shard_guardian_lance", "angelDive"],
    boss: ["Induk Prisma", "prism_hive_mother_hover", "prism_hive_mother_refraction", "ancientCore"],
  },
  {
    name: "Kota Bulan Darah",
    subtitle: "Atap merah tanpa matahari",
    accent: "#ff526a",
    common: ["Gargoyle Darah", "blood_gargoyle_fall", "blood_gargoyle_claw", "gargoyle"],
    rare: ["Revenant Senapan", "rifle_revenant_hover", "rifle_revenant_shot", "tracking"],
    mini: ["Ksatria Vampir", "vampire_knight_hover", "vampire_knight_dive", "dive"],
    boss: ["Countess Merah", "crimson_countess_hover", "crimson_countess_bloodmoon", "lich"],
  },
  {
    name: "Mahkota Pohon Dunia",
    subtitle: "Akar terakhir menilai Asha",
    accent: "#a9f36a",
    common: ["Binatang Benih", "seed_beast_fall", "seed_beast_sprout", "crawl"],
    rare: ["Naga Akar", "root_drake_dive", "root_drake_thorn", "windDragon"],
    mini: ["Ent Purba", "ancient_ent_hover", "ancient_ent_rootslam", "gauntlet"],
    boss: ["Avatar Pohon Dunia", "world_tree_avatar_hover", "world_tree_avatar_starfall", "thunderGod"],
  },
  {
    name: "Ujung Waktu",
    subtitle: "Tidak ada langit setelah ini",
    accent: "#ff495f",
    common: ["Fragmen Waktu", "time_fragment_fall", "time_fragment_shatter", "glitch"],
    rare: ["Asha Masa Depan", "future_clone_hover", "future_clone_arrow", "shadow"],
    mini: ["Ksatria Paradoks", "paradox_knight_hover", "paradox_knight_split", "fallenAngel"],
    boss: ["Pemangsa Aeon", "aeon_devourer_hover", "aeon_devourer_endtime", "voidLord"],
  },
];

function enemyFrom(row, kind, areaIndex) {
  const hpBase = { common: 26, rare: 58, mini: 330, boss: 1150 }[kind];
  const reward = { common: 1, rare: 3, mini: 15, boss: 55 }[kind];
  const size = { common: 62, rare: 78, mini: 112, boss: 176 }[kind];
  return {
    kind,
    name: row[0],
    moveAnim: row[1],
    attackAnim: row[2],
    behavior: row[3],
    hp: Math.round(hpBase * (1 + areaIndex * 0.18)),
    reward,
    size,
  };
}

export const AREAS = roster.map((area, index) => {
  const moveKey = `ENEMY_AREA_${index + 1}_MOVE`;
  const attackKey = `ENEMY_AREA_${index + 1}_ATTACK`;
  const decorate = (enemy) => ({ ...enemy, moveKey, attackKey, sourceArea: index });
  return {
    id: index + 1,
    name: area.name,
    subtitle: area.subtitle,
    accent: area.accent,
    backgroundKey: `BG_AREA_${index + 1}`,
    groundKey: `GROUND_AREA_${index + 1}`,
    moveKey,
    attackKey,
    common: decorate(enemyFrom(area.common, "common", index)),
    rare: decorate(enemyFrom(area.rare, "rare", index)),
    mini: decorate(enemyFrom(area.mini, "mini", index)),
    boss: decorate(enemyFrom(area.boss, "boss", index)),
  };
});

export const UPGRADES = [
  { id: "double", icon: "double_arrow", label: "Panah Ganda", detail: "Tembakkan panah kedua", element: false },
  { id: "pierce", icon: "pierce", label: "Tembus", detail: "+1 musuh tertembus", element: false },
  { id: "crit", icon: "critical", label: "Mata Elang", detail: "+12% peluang kritis", element: false },
  { id: "magnet", icon: "magnet", label: "Tarikan Koin", detail: "Jangkauan koin membesar", element: false },
  { id: "heal", icon: "heart", label: "Napas Kedua", detail: "Pulihkan 2 hati", element: false },
  { id: "frost", icon: "frost", label: "Frost Slow", detail: "Panah memperlambat jatuh", element: true },
  { id: "fire", icon: "fire", label: "Ledakan Bara", detail: "Hit meledak di sekitar", element: true },
  { id: "lightning", icon: "lightning", label: "Petir Rantai", detail: "Damage melompat ke target lain", element: true },
  { id: "poison", icon: "poison", label: "Racun Bertumpuk", detail: "Damage berlanjut setelah hit", element: true },
];

export const RELICS = [
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

export function makeWave(area, wave) {
  if (wave === 15) return [area.boss];
  if (wave === 10) return [area.common, area.common, area.mini];
  if (wave === 5) return [area.common, area.rare, area.rare];
  const act = Math.ceil(wave / 5);
  const count = Math.min(14, 2 + act + Math.ceil(wave * 0.58));
  const enemies = [];
  for (let i = 0; i < count; i += 1) {
    const rareChance = wave >= 3 ? Math.min(0.55, 0.09 + wave * 0.025) : 0;
    if (wave > 10 && i === count - 1 && Math.random() < 0.42) enemies.push(area.mini);
    else enemies.push(Math.random() < rareChance ? area.rare : area.common);
  }
  return enemies;
}

const skinNames = [
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

export const SKINS = skinNames.map(([name, buffLabel], index) => {
  const number = String(index + 1).padStart(2, "0");
  const tier = index / 19;
  return {
    id: index,
    name,
    buffLabel,
    moveKey: `SKIN_${number}_MOVE`,
    combatKey: `SKIN_${number}_COMBAT`,
    effectsKey: `SKIN_${number}_EFFECTS`,
    buffs: {
      damage: 1 + tier * 0.8 + (index === 1 ? 0.08 : 0),
      fireRate: 1 + tier * 0.5 + (index === 3 ? 0.12 : index === 9 ? 0.22 : 0),
      moveSpeed: 1 + tier * 0.35 + (index === 5 ? 0.18 : 0),
      maxHp: Math.floor(tier * 3) + ([2, 6, 16].includes(index) ? index === 16 ? 3 : index === 6 ? 2 : 1 : 0),
      cooldown: Math.max(0.55, 1 - tier * 0.35 - (index === 11 ? 0.18 : 0)),
      skillDamage: 1 + tier * 0.65 + (index === 13 ? 0.35 : 0),
      melee: 1 + tier * 0.8 + (index === 17 ? 1.2 : 0),
      ultGain: 1 + tier * 0.65 + (index === 14 ? 0.45 : 0),
      rageDamage: 1.5 + tier * 0.35 + (index === 15 ? 0.5 : 0),
      pierce: index >= 10 ? 1 : 0,
      revive: [8, 19].includes(index),
      healSkill: [12, 16, 19].includes(index),
      poison: [7, 19].includes(index),
    },
  };
});

export function upgradeChoices(levels) {
  const elementCount = ["frost", "fire", "lightning", "poison"].filter((id) => levels[id]).length;
  const pool = UPGRADES.filter((upgrade) => !upgrade.element || levels[upgrade.id] || elementCount < 3);
  const copy = [...pool];
  const choices = [];
  while (choices.length < 3 && copy.length) {
    choices.push(copy.splice(Math.floor(Math.random() * copy.length), 1)[0]);
  }
  return choices;
}

export const DEFAULT_SAVE = {
  version: 2,
  unlockedArea: 1,
  coins: 0,
  bestScore: 0,
  stats: { damage: 0, fireRate: 0, moveSpeed: 0 },
  relics: [],
  endlessUnlocked: false,
  selectedSkin: null,
};
