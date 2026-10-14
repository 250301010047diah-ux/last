import { AREAS, makeWave } from "./data.js";

const clamp = (value, min, max) => Math.max(min, Math.min(max, value));
const distance = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);

export class CombatWorld {
  constructor({ area, areaIndex, stats, relics, skin, tuning, audio, haptics, callbacks, endless = false }) {
    this.area = area;
    this.areaIndex = areaIndex;
    this.stats = stats;
    this.relics = relics;
    this.skin = skin;
    this.tuning = tuning;
    this.audio = audio;
    this.haptics = haptics;
    this.callbacks = callbacks;
    this.endless = endless;
    this.width = 360;
    this.height = 640;
    this.groundY = 560;
    this.time = 0;
    this.state = "ready";
    this.wave = 1;
    this.score = 0;
    this.runCoins = 0;
    this.combo = 0;
    this.multiplier = 1;
    this.cause = "Serangan dari langit";
    this.shake = 0;
    this.flash = 0;
    this.spawnQueue = [];
    this.spawnClock = 0;
    this.waveEnding = 0;
    this.levels = {};
    this.arrows = [];
    this.enemies = [];
    this.projectiles = [];
    this.coins = [];
    this.effects = [];
    this.particles = [];
    this.labels = [];
    const maxHp = 5 + skin.buffs.maxHp;
    this.player = {
      x: this.width / 2,
      jump: 0,
      vy: 0,
      hp: maxHp,
      maxHp,
      invulnerable: 0,
      shootClock: 0,
      shootPulse: 0,
      move: 0,
      facing: 1,
      groundShield: relics.includes(0),
      revived: false,
      action: null,
      actionTime: 0,
      meleeCooldown: 0,
      skillOneCooldown: 0,
      skillTwoCooldown: 0,
      ultimate: 0,
      rage: 0,
      rageActive: 0,
    };
    this.previewWave();
  }

  resize(width, height) {
    const oldWidth = this.width;
    this.width = width;
    this.height = height;
    this.groundY = Math.round(height * (height / width < 1.25 ? 0.84 : 0.88));
    if (oldWidth) this.player.x = (this.player.x / oldWidth) * width;
    this.player.x = clamp(this.player.x, 38, width - 38);
  }

  previewWave() {
    this.enemies = [this.createEnemy(this.area.common, true)];
    this.enemies[0].x = this.width * 0.5;
    this.enemies[0].y = Math.max(105, this.height * 0.18);
  }

  engage() {
    if (this.state !== "ready") return;
    this.state = "active";
    const preview = this.enemies[0];
    preview.preview = false;
    const waveEnemies = makeWave(this.area, this.wave);
    this.spawnQueue = waveEnemies.slice(1);
    this.spawnClock = 1.3;
  }

  jump() {
    if (!["ready", "active"].includes(this.state) || this.player.jump > 0.5) return;
    this.player.vy = Math.max(430, this.height * 0.68);
    this.audio.play("jump");
  }

  useAction(action) {
    if (this.state !== "active") return;
    if (action === "melee") this.meleeAttack();
    if (action === "skill1") this.skillOne();
    if (action === "skill2") this.skillTwo();
    if (action === "ultimate") this.castUltimate();
  }

  setAction(name, duration = 0.5) {
    this.player.action = name;
    this.player.actionTime = duration;
  }

  meleeAttack() {
    const player = this.player;
    if (player.meleeCooldown > 0 || player.jump > 10) return;
    player.meleeCooldown = Math.max(0.28, 0.62 * this.skin.buffs.cooldown);
    this.setAction("melee_attack", 0.42);
    const damage = 32 * this.skin.buffs.damage * this.skin.buffs.melee * (player.rageActive > 0 ? this.skin.buffs.rageDamage : 1);
    let hits = 0;
    for (const enemy of this.enemies) {
      if (enemy.dead || enemy.state !== "ground") continue;
      if (Math.abs(enemy.x - player.x) < 105) {
        this.damageEnemy(enemy, damage, true);
        hits += 1;
      }
    }
    this.effects.push({ type: "arrow_impact", sheetKey: this.skin.effectsKey, x: player.x + player.facing * 55, y: this.groundY - 28, age: 0, duration: 0.4, size: 90 });
    this.audio.play(hits ? "hit" : "shoot", 1.1);
    if (hits) this.vibrate(24);
  }

  skillOne() {
    const player = this.player;
    if (player.skillOneCooldown > 0) return;
    player.skillOneCooldown = 7 * this.skin.buffs.cooldown * this.tuning.skillCooldownScale;
    this.setAction("skill_one", 0.65);
    const damage = 38 * this.skin.buffs.damage * this.skin.buffs.skillDamage;
    for (let i = 0; i < 7; i += 1) {
      const x = this.width * (0.1 + i * 0.133);
      this.effects.push({ type: "skill_one_fx", sheetKey: this.skin.effectsKey, x, y: this.height * 0.58, age: i * -0.035, duration: 0.75, size: 110 });
    }
    for (const enemy of this.enemies) if (!enemy.dead) this.damageEnemy(enemy, damage, false, true);
    player.ultimate = Math.min(100, player.ultimate + 12 * this.skin.buffs.ultGain);
    this.audio.play("warning", 0.8);
    this.shake = 8;
  }

  skillTwo() {
    const player = this.player;
    if (player.skillTwoCooldown > 0) return;
    player.skillTwoCooldown = 11 * this.skin.buffs.cooldown * this.tuning.skillCooldownScale;
    this.setAction("skill_two", 0.72);
    const damage = 24 * this.skin.buffs.damage * this.skin.buffs.skillDamage;
    this.effects.push({ type: "skill_two_fx", sheetKey: this.skin.effectsKey, x: player.x, y: this.groundY, age: 0, duration: 0.85, size: Math.min(this.width * 0.8, 300) });
    for (const enemy of this.enemies) {
      if (enemy.dead) continue;
      enemy.slow = Math.max(enemy.slow, 2.5);
      this.damageEnemy(enemy, damage, false, true);
    }
    if (this.skin.buffs.healSkill) player.hp = Math.min(player.maxHp, player.hp + 1);
    player.ultimate = Math.min(100, player.ultimate + 10 * this.skin.buffs.ultGain);
    this.audio.play("upgrade", 0.9);
  }

  castUltimate() {
    const player = this.player;
    if (player.ultimate < 100) return;
    player.ultimate = 0;
    this.setAction("ultimate", 1.05);
    this.effects.push({ type: "ultimate_fx", sheetKey: this.skin.effectsKey, x: this.width / 2, y: this.groundY, age: 0, duration: 1.1, size: Math.max(this.width * 0.92, 280) });
    const damage = 190 * this.skin.buffs.damage * this.skin.buffs.skillDamage;
    for (const enemy of this.enemies) if (!enemy.dead) this.damageEnemy(enemy, damage, true, true);
    this.projectiles = [];
    this.shake = 20;
    this.flash = 0.14;
    this.audio.play("warning", 1.5);
    this.vibrate([45, 25, 80]);
  }

  addRage(value) {
    const player = this.player;
    if (player.rageActive > 0) return;
    player.rage = Math.min(100, player.rage + value);
    if (player.rage >= 100) {
      player.rage = 100;
      player.rageActive = this.tuning.rageDuration + (this.relics.includes(18) ? 3 : 0);
      this.callbacks.onBanner("RAGE LANGIT AKTIF");
      this.audio.play("warning", 1.2);
      this.vibrate([30, 20, 50]);
    }
  }

  createEnemy(template, preview = false) {
    const hpScale = this.tuning.enemyHpScale * (this.endless ? 1 + (this.wave - 1) * 0.08 : 1);
    const hover = template.kind === "mini" || template.kind === "boss" || ["phase", "tracking", "fallenAngel"].includes(template.behavior);
    const enemy = {
      ...template,
      id: crypto.randomUUID?.() || `${Date.now()}-${Math.random()}`,
      x: 50 + Math.random() * Math.max(10, this.width - 100),
      y: preview ? 110 : -template.size,
      width: template.size,
      height: template.size,
      maxHp: Math.round(template.hp * hpScale),
      hp: Math.round(template.hp * hpScale),
      age: Math.random(),
      state: hover ? "hover" : "fall",
      hoverY: template.kind === "boss" ? this.height * 0.24 : this.height * 0.32,
      speed: (50 + this.areaIndex * 4 + Math.random() * 18) * this.tuning.fallSpeed,
      groundSpeed: 36 + this.areaIndex * 3,
      attackClock: template.kind === "boss" ? 1.4 : 1.8 + Math.random() * 1.5,
      attackPulse: 0,
      hitPulse: 0,
      slow: 0,
      poison: 0,
      poisonClock: 0,
      preview,
      dead: false,
      phaseTriggered: false,
      shield: template.behavior === "ancientCore" ? 3 : 0,
      egged: false,
      reviveClock: 0,
      invulnerable: template.behavior === "gargoyle" && !hover,
    };
    if (template.behavior === "meteor") enemy.invulnerable = true;
    return enemy;
  }

  startWave(wave) {
    this.wave = wave;
    if (this.endless && wave > 1 && wave % 10 === 1) {
      this.area = AREAS[Math.floor(Math.random() * AREAS.length)];
      this.areaIndex = this.area.id - 1;
      this.callbacks.onAreaShift(this.area);
    }
    this.state = "active";
    this.enemies = [];
    this.arrows = [];
    this.projectiles = [];
    this.waveEnding = 0;
    this.spawnQueue = this.endless ? this.makeEndlessWave(wave) : makeWave(this.area, wave);
    this.spawnClock = 0.25;
    if ((!this.endless && wave === 15) || (this.endless && wave % 10 === 0)) {
      this.audio.play("warning", 1.2);
      this.callbacks.onBanner(`BOSS · ${this.area.boss.name}`);
    } else if (wave === 10) {
      this.callbacks.onBanner(`MINI-BOSS · ${this.area.mini.name}`);
    } else {
      this.callbacks.onBanner(`WAVE ${wave}`);
    }
  }

  makeEndlessWave(wave) {
    if (wave % 10 === 0) {
      const area = AREAS[Math.floor(Math.random() * AREAS.length)];
      return [area.boss];
    }
    const count = Math.min(15, 3 + Math.ceil(wave * 0.42));
    return Array.from({ length: count }, () => {
      const area = AREAS[Math.floor(Math.random() * AREAS.length)];
      return Math.random() < Math.min(0.5, 0.12 + wave * 0.015) ? area.rare : area.common;
    });
  }

  resumeAfterUpgrade(id) {
    this.applyUpgrade(id);
    this.startWave(this.wave + 1);
  }

  applyUpgrade(id) {
    this.levels[id] = (this.levels[id] || 0) + 1;
    if (id === "heal") this.player.hp = Math.min(this.player.maxHp, this.player.hp + 2);
    this.audio.play("upgrade");
  }

  playerDamage(amount, cause, groundHit = false) {
    if (this.player.invulnerable > 0 || this.state !== "active") return;
    if (groundHit && this.player.groundShield) {
      this.player.groundShield = false;
      this.callbacks.onBanner("AKAR MENAHAN BENTURAN");
      this.audio.play("hit");
      return;
    }
    this.player.hp -= amount;
    this.player.invulnerable = 1.15;
    this.combo = 0;
    this.multiplier = 1;
    this.cause = cause;
    this.shake = 10 * this.tuning.effectsIntensity;
    this.flash = 0.18;
    this.audio.play("hurt");
    this.vibrate([35, 20, 45]);
    if (this.player.hp <= 0) {
      if ((this.relics.includes(5) || this.skin.buffs.revive) && !this.player.revived) {
        this.player.revived = true;
        this.player.hp = 1;
        this.player.invulnerable = 2;
        this.callbacks.onBanner("BARA KEDUA");
      } else {
        this.state = "defeat";
        this.callbacks.onDefeat(this);
      }
    }
  }

  vibrate(pattern) {
    if (!this.callbacks.canVibrate()) return;
    try { void this.haptics.vibrate(pattern); } catch { /* unsupported */ }
  }

  shoot() {
    const count = this.levels.double ? 2 : 1;
    const offsets = count === 2 ? [-9, 9] : [0];
    for (const offset of offsets) {
      this.arrows.push({
        x: this.player.x + offset,
        y: this.groundY - this.player.jump - Math.min(68, this.height * 0.1),
        width: 14,
        height: 42,
        vy: -Math.max(520, this.height * 0.9),
        pierce: (this.levels.pierce || 0) + this.skin.buffs.pierce,
        dead: false,
      });
    }
    this.player.shootPulse = 0.24;
    this.audio.play("shoot", 0.75);
  }

  spawnEnemy() {
    const template = this.spawnQueue.shift();
    if (!template) return;
    const enemy = this.createEnemy(template);
    if (template.kind === "boss") {
      enemy.y = -enemy.height;
      if (enemy.behavior === "ancientCore") {
        for (let i = 0; i < 3; i += 1) {
          const anchor = this.createEnemy(this.area.rare);
          anchor.anchorForBoss = enemy.id;
          anchor.x = this.width * (0.25 + i * 0.25);
          anchor.y = this.height * (0.42 + (i % 2) * 0.08);
          anchor.state = "hover";
          anchor.hoverY = anchor.y;
          this.enemies.push(anchor);
        }
      }
    }
    this.enemies.push(enemy);
  }

  update(dt, input) {
    this.time += dt;
    this.flash = Math.max(0, this.flash - dt);
    this.shake = Math.max(0, this.shake - dt * 22);
    this.updateEffects(dt);
    if (this.state !== "active") return;

    this.updatePlayer(dt, input);
    if (this.spawnQueue.length) {
      this.spawnClock -= dt;
      if (this.spawnClock <= 0) {
        this.spawnEnemy();
        const density = this.wave > 10 ? 0.82 : 1;
        this.spawnClock = this.tuning.spawnInterval * density * (0.75 + Math.random() * 0.5);
      }
    }
    this.updateArrows(dt);
    this.updateEnemies(dt);
    this.updateProjectiles(dt);
    this.updateCoins(dt);
    this.resolveCollisions();
    this.enemies = this.enemies.filter((enemy) => !enemy.dead);
    this.arrows = this.arrows.filter((arrow) => !arrow.dead && arrow.y > -80);
    this.projectiles = this.projectiles.filter((projectile) => !projectile.dead && projectile.y < this.height + 80 && projectile.y > -80 && projectile.x > -80 && projectile.x < this.width + 80);

    if (!this.spawnQueue.length && !this.enemies.length && !this.waveEnding) this.waveEnding = 1.1;
    if (this.waveEnding) {
      this.waveEnding -= dt;
      if (this.waveEnding <= 0) this.finishWave();
    }
  }

  updatePlayer(dt, input) {
    const player = this.player;
    const rageSpeed = player.rageActive > 0 ? 1.25 : 1;
    const baseSpeed = this.tuning.playerSpeed * (1 + this.stats.moveSpeed * 0.08) * this.skin.buffs.moveSpeed * rageSpeed;
    let direction = Number(input.right) - Number(input.left);
    const rect = this.callbacks.getCanvasRect();
    if (input.pointer && input.targetX !== null && rect.width) {
      const target = ((input.targetX - rect.left) / rect.width) * this.width;
      const delta = target - player.x;
      direction = Math.abs(delta) < 3 ? 0 : Math.sign(delta);
      player.x += clamp(delta, -baseSpeed * dt, baseSpeed * dt);
    } else {
      player.x += direction * baseSpeed * dt;
    }
    player.x = clamp(player.x, 35, this.width - 35);
    player.move = direction;
    if (direction) player.facing = direction;
    if (player.jump > 0 || player.vy > 0) {
      player.jump += player.vy * dt;
      player.vy -= Math.max(980, this.height * 1.55) * dt;
      if (player.jump <= 0) { player.jump = 0; player.vy = 0; }
    }
    player.invulnerable = Math.max(0, player.invulnerable - dt);
    player.shootPulse = Math.max(0, player.shootPulse - dt);
    player.actionTime = Math.max(0, player.actionTime - dt);
    if (player.actionTime <= 0) player.action = null;
    player.meleeCooldown = Math.max(0, player.meleeCooldown - dt);
    player.skillOneCooldown = Math.max(0, player.skillOneCooldown - dt);
    player.skillTwoCooldown = Math.max(0, player.skillTwoCooldown - dt);
    if (player.rageActive > 0) {
      player.rageActive = Math.max(0, player.rageActive - dt);
      player.rage = Math.max(0, player.rage - dt * (100 / Math.max(1, this.tuning.rageDuration + (this.relics.includes(18) ? 3 : 0))));
    } else if (player.rage >= 100) player.rage = 0;
    player.shootClock -= dt;
    const fireRate = this.tuning.fireRate * (1 + this.stats.fireRate * 0.09) * this.skin.buffs.fireRate * (player.rageActive > 0 ? 1.5 : 1);
    if (player.shootClock <= 0) {
      this.shoot();
      player.shootClock = 1 / fireRate;
    }
  }

  updateArrows(dt) {
    const wind = this.areaIndex === 2 && !this.relics.includes(2) ? Math.sin(this.time * 1.7) * 24 : 0;
    for (const arrow of this.arrows) {
      arrow.y += arrow.vy * dt;
      arrow.x += wind * dt;
    }
  }

  updateEnemies(dt) {
    const player = this.player;
    for (const enemy of this.enemies) {
      enemy.age += dt;
      enemy.hitPulse = Math.max(0, enemy.hitPulse - dt);
      enemy.attackPulse = Math.max(0, enemy.attackPulse - dt);
      enemy.slow = Math.max(0, enemy.slow - dt);
      const slowFactor = enemy.slow > 0 ? 0.58 : 1;

      if (enemy.poison > 0) {
        enemy.poisonClock -= dt;
        if (enemy.poisonClock <= 0) {
          enemy.poisonClock = 0.45;
          this.damageEnemy(enemy, 2 * enemy.poison, false, true);
        }
      }

      if (enemy.egged) {
        enemy.reviveClock -= dt;
        if (enemy.reviveClock <= 0 && enemy.hp > 0) {
          enemy.egged = false;
          enemy.state = "hover";
          enemy.y = this.height * 0.24;
          enemy.hp = Math.max(enemy.hp, enemy.maxHp * 0.42);
          this.callbacks.onBanner("PHOENIX BANGKIT");
        }
        continue;
      }

      if (enemy.state === "fall") {
        let lateral = 0;
        if (["zigzag", "spiral", "glitch"].includes(enemy.behavior)) lateral = Math.sin(enemy.age * (enemy.behavior === "glitch" ? 9 : 4.2)) * 55;
        if (enemy.behavior === "swoop") lateral = Math.sin(enemy.age * 3.4) * 38;
        enemy.x += lateral * dt;
        enemy.y += enemy.speed * slowFactor * dt;
        if (enemy.y + enemy.height * 0.42 >= this.groundY) this.landEnemy(enemy);
      } else if (enemy.state === "hover") {
        const enterSpeed = Math.max(90, this.height * 0.16);
        if (enemy.y < enemy.hoverY) enemy.y = Math.min(enemy.hoverY, enemy.y + enterSpeed * dt);
        enemy.x += Math.sin(enemy.age * (enemy.kind === "boss" ? 0.9 : 1.7)) * (enemy.kind === "boss" ? 32 : 22) * dt;
        enemy.x = clamp(enemy.x, enemy.width * 0.45, this.width - enemy.width * 0.45);
        if (enemy.behavior === "gravity") {
          const pull = Math.sign(enemy.x - player.x) * 26;
          player.x += pull * dt;
        }
        enemy.attackClock -= dt;
        if (enemy.attackClock <= 0) this.enemyAttack(enemy);
      } else if (enemy.state === "ground") {
        const direction = Math.sign(player.x - enemy.x) || 1;
        enemy.x += direction * enemy.groundSpeed * slowFactor * dt;
        enemy.x = clamp(enemy.x, 25, this.width - 25);
        enemy.attackClock -= dt;
        if (Math.abs(player.x - enemy.x) < (enemy.width + 42) * 0.42 && player.jump < 28 && enemy.attackClock <= 0) {
          enemy.attackPulse = 0.4;
          enemy.attackClock = 1.25;
          this.playerDamage(enemy.kind === "rare" ? 2 : 1, `${enemy.name} menyerang dari tanah`, true);
        }
      }

      if (enemy.behavior === "phase") enemy.invulnerable = Math.sin(enemy.age * 2.4) < -0.2;
      if (enemy.behavior === "fallenAngel") enemy.invulnerable = enemy.attackPulse <= 0;
      if (enemy.behavior === "slimeKing" && !enemy.phaseTriggered && enemy.hp < enemy.maxHp * 0.3) {
        enemy.phaseTriggered = true;
        enemy.state = "ground";
        enemy.y = this.groundY - enemy.height / 2;
        for (let i = 0; i < 2; i += 1) {
          const split = this.createEnemy(this.area.common);
          split.state = "ground";
          split.x = clamp(enemy.x + (i ? 55 : -55), 30, this.width - 30);
          split.y = this.groundY - split.height / 2;
          this.enemies.push(split);
        }
        this.callbacks.onBanner("RAJA SLIME PECAH");
      }
    }
  }

  landEnemy(enemy) {
    enemy.y = this.groundY - enemy.height / 2;
    if (enemy.behavior === "meteor") {
      this.effects.push({ type: "fire_explosion", x: enemy.x, y: this.groundY, age: 0, duration: 0.55, size: 110 });
      if (Math.abs(this.player.x - enemy.x) < 80 && this.player.jump < 34) this.playerDamage(2, "Batu Api menghantam tanah", true);
      enemy.dead = true;
      this.shake = 12;
      this.audio.play("land", 1.2);
      return;
    }
    enemy.state = "ground";
    enemy.invulnerable = false;
    enemy.attackClock = 0.55;
    this.combo = 0;
    this.multiplier = 1;
    this.effects.push({ type: "landing", x: enemy.x, y: this.groundY, age: 0, duration: 0.45, size: 90 });
    this.audio.play("land", enemy.kind === "rare" ? 1.1 : 0.7);
    this.shake = Math.max(this.shake, 4);
  }

  enemyAttack(enemy) {
    enemy.attackPulse = enemy.kind === "boss" ? 0.75 : 0.48;
    enemy.attackClock = (enemy.kind === "boss" ? 1.45 : 2.05) + Math.random() * 0.85;
    const aimed = Math.atan2(this.groundY - enemy.y, this.player.x - enemy.x);
    const projectileSet = ["thorn_fruit", "spider_egg", "blade_feather", "venom_glob", "cyan_orb", "fireball", "cyan_orb", "lightning_javelin", "meteor", "void_orb"];
    const projectileName = projectileSet[(enemy.sourceArea ?? this.areaIndex) % projectileSet.length];
    const speed = 140 + this.areaIndex * 8;
    const count = enemy.kind === "boss" ? (enemy.hp < enemy.maxHp * 0.5 ? 5 : 3) : 1;
    if (["lich", "beam", "tracking", "voidLord"].includes(enemy.behavior)) {
      this.effects.push({ type: "laser", x: this.player.x, y: this.groundY, age: 0, duration: 0.65, size: this.height });
      this.audio.play("warning");
      window.setTimeout(() => {
        if (this.state === "active" && Math.abs(this.player.x - this.effects.at(-1)?.x) < 28) this.playerDamage(enemy.kind === "boss" ? 2 : 1, `${enemy.name} menembakkan laser`);
      }, 520);
      return;
    }
    if (["primate", "windDragon", "angelDive", "gauntlet"].includes(enemy.behavior) && Math.random() < 0.45) {
      const targetX = this.player.x;
      this.effects.push({ type: "dive", x: targetX, y: this.groundY, age: 0, duration: 0.7, size: 95 });
      this.audio.play("warning");
      window.setTimeout(() => {
        if (this.state === "active" && Math.abs(this.player.x - targetX) < 62 && this.player.jump < 42) this.playerDamage(2, `${enemy.name} menghantam tanah`, true);
        this.shake = 13;
      }, 580);
      return;
    }
    if (enemy.behavior === "broodmother") {
      const hatch = this.createEnemy(this.area.common);
      hatch.x = enemy.x;
      hatch.y = enemy.y + 20;
      this.enemies.push(hatch);
      return;
    }
    if (enemy.behavior === "thunderGod") {
      for (const lane of [0.2, 0.5, 0.8]) {
        const laneX = this.width * lane;
        this.effects.push({ type: "laser", x: laneX, y: this.groundY, age: 0, duration: 0.55, size: this.height });
      }
      this.audio.play("warning");
      return;
    }
    for (let i = 0; i < count; i += 1) {
      const spread = (i - (count - 1) / 2) * 0.18;
      this.projectiles.push({
        x: enemy.x,
        y: enemy.y + enemy.height * 0.25,
        vx: Math.cos(aimed + spread) * speed,
        vy: Math.sin(aimed + spread) * speed,
        width: enemy.kind === "boss" ? 34 : 24,
        height: enemy.kind === "boss" ? 42 : 30,
        frame: projectileName,
        damage: enemy.kind === "boss" ? 2 : 1,
        source: enemy.name,
        dead: false,
      });
    }
  }

  updateProjectiles(dt) {
    for (const projectile of this.projectiles) {
      projectile.x += projectile.vx * dt;
      projectile.y += projectile.vy * dt;
      const playerPoint = { x: this.player.x, y: this.groundY - this.player.jump - 48 };
      if (distance(projectile, playerPoint) < 24 && this.player.invulnerable <= 0) {
        projectile.dead = true;
        this.playerDamage(projectile.damage, `${projectile.source} mengenai Asha`);
      }
    }
  }

  resolveCollisions() {
    for (const arrow of this.arrows) {
      if (arrow.dead) continue;
      for (const enemy of this.enemies) {
        if (enemy.dead || enemy.preview) continue;
        if (Math.abs(arrow.x - enemy.x) > enemy.width * 0.42 || Math.abs(arrow.y - enemy.y) > enemy.height * 0.45) continue;
        const critChance = 0.08 + (this.levels.crit || 0) * 0.12;
        const critical = Math.random() < critChance;
        let damage = (10 + this.stats.damage * 2.4) * this.skin.buffs.damage * (critical ? 2 : 1) * (this.player.rageActive > 0 ? this.skin.buffs.rageDamage : 1);
        if (enemy.kind === "boss") damage *= 0.85;
        if (enemy.behavior === "tornado") enemy.y -= 22;
        this.damageEnemy(enemy, damage, critical);
        if (this.levels.frost) enemy.slow = 0.7 + this.levels.frost * 0.16;
        if (this.levels.poison || this.skin.buffs.poison) { enemy.poison = Math.min(4, (this.levels.poison || 0) + 1); enemy.poisonClock = 0.25; }
        if (this.levels.fire) this.areaDamage(enemy, damage * (0.24 + this.levels.fire * 0.08), 78, enemy);
        if (this.levels.lightning) this.chainDamage(enemy, damage * (0.28 + this.levels.lightning * 0.07));
        if (arrow.pierce > 0) {
          arrow.pierce -= 1;
          this.effects.push({ type: "pierce_flash", x: enemy.x, y: enemy.y, age: 0, duration: 0.32, size: 58 });
        } else arrow.dead = true;
        break;
      }
    }
  }

  damageEnemy(enemy, amount, critical = false, dot = false) {
    if (enemy.dead || enemy.invulnerable) {
      if (!dot) this.effects.push({ type: "shield", x: enemy.x, y: enemy.y, age: 0, duration: 0.35, size: enemy.width });
      return;
    }
    if (enemy.kind === "boss" && enemy.behavior === "ancientCore" && enemy.shield > 0) {
      this.effects.push({ type: "shield", x: enemy.x, y: enemy.y, age: 0, duration: 0.35, size: enemy.width });
      return;
    }
    enemy.hp -= amount;
    enemy.hitPulse = 0.12;
    this.addRage(Math.min(5, amount * 0.045));
    this.player.ultimate = Math.min(100, this.player.ultimate + Math.min(3.5, amount * 0.025) * this.skin.buffs.ultGain);
    if (!dot) {
      const type = this.levels.frost ? "frost_burst" : this.levels.poison ? "poison_splash" : "arrow_impact";
      this.effects.push({ type, sheetKey: type === "arrow_impact" ? this.skin.effectsKey : undefined, x: enemy.x, y: enemy.y, age: 0, duration: 0.45, size: critical ? 82 : 58 });
      this.labels.push({ text: `${Math.round(amount)}${critical ? "!" : ""}`, x: enemy.x, y: enemy.y, age: 0, duration: 0.55, color: critical ? "#fff0a0" : "#ffffff" });
      this.audio.play("hit", critical ? 1.25 : 0.65);
    }
    if (enemy.hp <= 0) this.killEnemy(enemy);
  }

  areaDamage(origin, amount, radius, ignore) {
    this.effects.push({ type: "fire_explosion", x: origin.x, y: origin.y, age: 0, duration: 0.5, size: radius * 1.4 });
    for (const enemy of this.enemies) if (enemy !== ignore && !enemy.dead && distance(origin, enemy) < radius) this.damageEnemy(enemy, amount, false, true);
  }

  chainDamage(origin, amount) {
    let target = null;
    let best = 150;
    for (const enemy of this.enemies) {
      if (enemy === origin || enemy.dead) continue;
      const gap = distance(origin, enemy);
      if (gap < best) { best = gap; target = enemy; }
    }
    if (target) {
      this.effects.push({ type: "chain_lightning", x: (origin.x + target.x) / 2, y: (origin.y + target.y) / 2, age: 0, duration: 0.3, size: best });
      this.damageEnemy(target, amount, false, true);
    }
  }

  killEnemy(enemy) {
    if (enemy.behavior === "phoenix" && !enemy.egged && !enemy.phaseTriggered) {
      enemy.phaseTriggered = true;
      enemy.egged = true;
      enemy.hp = enemy.maxHp * 0.26;
      enemy.y = this.groundY - enemy.height * 0.3;
      enemy.reviveClock = 5;
      enemy.attackPulse = 1;
      this.callbacks.onBanner("HANCURKAN TELUR PHOENIX");
      return;
    }
    enemy.dead = true;
    if (enemy.anchorForBoss) {
      const boss = this.enemies.find((entry) => entry.id === enemy.anchorForBoss);
      if (boss) boss.shield = Math.max(0, boss.shield - 1);
    }
    const airborne = enemy.state !== "ground" && !enemy.egged;
    if (airborne) {
      this.combo += 1;
      this.multiplier = Math.min(5, 1 + Math.floor(this.combo / 4));
    } else {
      this.combo = 0;
      this.multiplier = 1;
    }
    const base = { common: 90, rare: 220, mini: 1200, boss: 5500 }[enemy.kind];
    this.score += Math.round(base * this.multiplier);
    this.addRage({ common: 6, rare: 12, mini: 24, boss: 45 }[enemy.kind]);
    this.player.ultimate = Math.min(100, this.player.ultimate + { common: 4, rare: 8, mini: 18, boss: 35 }[enemy.kind] * this.skin.buffs.ultGain);
    if ((this.skin.id >= 16 || this.relics.includes(17)) && enemy.state === "ground" && Math.random() < 0.2) this.player.hp = Math.min(this.player.maxHp, this.player.hp + 1);
    const coinCount = Math.min(8, enemy.reward);
    for (let i = 0; i < coinCount; i += 1) this.coins.push({ x: enemy.x + (Math.random() - 0.5) * 35, y: enemy.y, vx: (Math.random() - 0.5) * 80, vy: -60 - Math.random() * 60, age: 0 });
    const effectType = { common: "common_death", rare: "rare_death", mini: "miniboss_death", boss: "boss_finisher" }[enemy.kind];
    this.effects.push({ type: effectType, x: enemy.x, y: enemy.y, age: 0, duration: enemy.kind === "boss" ? 0.8 : 0.5, size: enemy.width * 1.35 });
    this.audio.play("death", enemy.kind === "boss" ? 1.4 : 0.7);
    if (enemy.kind === "boss") { this.shake = 18; this.vibrate([45, 30, 70]); }
  }

  updateCoins(dt) {
    const radius = 70 + (this.levels.magnet || 0) * 42 + (this.relics.includes(6) ? 55 : 0);
    for (const coin of this.coins) {
      coin.age += dt;
      coin.vy += 190 * dt;
      coin.x += coin.vx * dt;
      coin.y += coin.vy * dt;
      coin.vx *= 0.98;
      if (coin.y > this.groundY - 8) { coin.y = this.groundY - 8; coin.vy *= -0.25; }
      const playerPoint = { x: this.player.x, y: this.groundY - this.player.jump - 30 };
      const gap = distance(coin, playerPoint);
      if (gap < radius) {
        coin.x += (playerPoint.x - coin.x) * Math.min(1, dt * 7);
        coin.y += (playerPoint.y - coin.y) * Math.min(1, dt * 7);
      }
      if (gap < 20) {
        coin.dead = true;
        this.runCoins += 1;
        this.audio.play("coin", this.multiplier / 5);
      }
    }
    this.coins = this.coins.filter((coin) => !coin.dead && coin.age < 12);
  }

  updateEffects(dt) {
    for (const effect of this.effects) effect.age += dt;
    for (const particle of this.particles) { particle.age += dt; particle.x += particle.vx * dt; particle.y += particle.vy * dt; }
    for (const label of this.labels) { label.age += dt; label.y -= 32 * dt; }
    this.effects = this.effects.filter((effect) => effect.age < effect.duration);
    this.particles = this.particles.filter((particle) => particle.age < particle.duration);
    this.labels = this.labels.filter((label) => label.age < label.duration);
  }

  finishWave() {
    this.waveEnding = 0;
    if (this.endless) {
      if (this.wave % 5 === 0) {
        this.state = "upgrade";
        this.callbacks.onUpgrade(this);
      } else {
        this.startWave(this.wave + 1);
      }
      return;
    }
    if (this.wave === 15) {
      this.state = "victory";
      this.callbacks.onVictory(this);
      return;
    }
    if (this.wave === 5 || this.wave === 10) {
      this.state = "upgrade";
      this.callbacks.onUpgrade(this);
      return;
    }
    this.startWave(this.wave + 1);
  }
}
