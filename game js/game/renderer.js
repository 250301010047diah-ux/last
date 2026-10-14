import { drawAnimation, drawFrameInBox } from "./assets.js";

const bossPortraits = ["primate_king", "cave_broodmother", "wind_dragon", "swamp_slime_king", "crown_lich", "ash_phoenix", "ancient_core", "thunder_god", "rift_worm", "void_sky_lord"];

function drawCover(ctx, image, width, height) {
  const scale = Math.max(width / image.width, height / image.height);
  const drawWidth = image.width * scale;
  const drawHeight = image.height * scale;
  ctx.drawImage(image, (width - drawWidth) / 2, (height - drawHeight) / 2, drawWidth, drawHeight);
}

function roundedRect(ctx, x, y, width, height, radius = 10) {
  ctx.beginPath();
  ctx.roundRect(x, y, width, height, radius);
}

export function createRenderer(canvas, store) {
  const ctx = canvas.getContext("2d", { alpha: false });
  let width = 0;
  let height = 0;
  let observer = null;

  const resize = (onResize) => {
    const rect = canvas.getBoundingClientRect();
    if (!rect.width || !rect.height) return;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.round(rect.width * dpr);
    canvas.height = Math.round(rect.height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    width = rect.width;
    height = rect.height;
    onResize(width, height);
  };

  const effectSource = (type) => {
    if (["normal_impact", "critical_impact", "frost_burst", "fire_explosion"].includes(type)) return ["ARROW_EFFECTS_A", type];
    if (["pierce_flash", "chain_lightning", "poison_splash", "arrow_trail"].includes(type)) return ["ARROW_EFFECTS_B", type];
    if (["common_death", "rare_death", "miniboss_death", "boss_finisher"].includes(type)) return ["ENEMY_DEATH_EFFECTS", type];
    if (type === "landing") return ["DANGER_EFFECTS", "landing_shadow"];
    if (type === "laser") return ["DANGER_EFFECTS", "laser_charge"];
    if (type === "dive") return ["DANGER_EFFECTS", "dive_marker"];
    if (type === "shield") return ["DANGER_EFFECTS", "boss_weakpoint"];
    return null;
  };

  const drawEffect = (effect) => {
    const source = effect.sheetKey ? [effect.sheetKey, effect.type] : effectSource(effect.type);
    if (!source) return;
    const sheet = store.get(source[0]);
    const frames = sheet?.animations.get(source[1]);
    if (!frames) return;
    const progress = Math.max(0, Math.min(0.999, effect.age / effect.duration));
    const frame = frames[Math.floor(progress * frames.length)];
    const size = effect.type === "laser" ? Math.max(80, width * 0.18) : effect.size;
    const drawHeight = effect.type === "laser" ? height * 0.82 : effect.size;
    drawFrameInBox(ctx, sheet, frame.name, effect.x - size / 2, effect.y - drawHeight, size, drawHeight, 1 - progress * 0.35);
  };

  const drawGround = (world) => {
    const ground = store.get(world.area.groundKey);
    if (!ground) return;
    const frame = ground.data.frames[0];
    const scale = width / ground.image.width;
    const drawHeight = ground.image.height * scale;
    const drawY = world.groundY - frame.surfaceY * scale;
    ctx.drawImage(ground.image, 0, drawY, width, drawHeight);
  };

  const drawHUD = (world) => {
    const icons = store.get("HUD_ICON_ATLAS");
    const pad = Math.max(7, Math.min(12, width * 0.022));
    const top = pad;
    const badgeHeight = Math.max(38, Math.min(48, height * 0.068));
    ctx.save();
    ctx.font = `700 ${Math.max(13, Math.min(18, width * 0.041))}px Inter, sans-serif`;
    ctx.textBaseline = "middle";

    const heartWidth = Math.min(width * 0.34, world.player.maxHp * 25 + 18);
    roundedRect(ctx, pad, top, heartWidth, badgeHeight, 12);
    ctx.fillStyle = "rgba(5, 16, 23, 0.82)";
    ctx.fill();
    const pip = Math.min(24, (heartWidth - 16) / world.player.maxHp);
    for (let i = 0; i < world.player.maxHp; i += 1) {
      drawFrameInBox(ctx, icons, "heart", pad + 8 + i * pip, top + (badgeHeight - pip) / 2, pip - 2, pip - 2, i < world.player.hp ? 1 : 0.16);
    }

    const centerWidth = Math.min(150, width * 0.36);
    const centerX = (width - centerWidth) / 2;
    roundedRect(ctx, centerX, top, centerWidth, badgeHeight, 12);
    ctx.fillStyle = "rgba(5, 16, 23, 0.86)";
    ctx.fill();
    ctx.fillStyle = "#f8f2df";
    ctx.textAlign = "center";
      ctx.fillText(world.endless ? `RIFT · ${world.wave}` : `${world.area.id} · ${world.wave}/15`, width / 2, top + badgeHeight * 0.38);
    ctx.font = `600 ${Math.max(10, Math.min(13, width * 0.029))}px Inter, sans-serif`;
    ctx.fillStyle = world.area.accent;
    ctx.fillText(`${Math.round(world.score).toLocaleString("id-ID")}  ×${world.multiplier}`, width / 2, top + badgeHeight * 0.72);

    const coinWidth = Math.min(92, width * 0.22);
    const coinX = width - coinWidth - Math.max(52, pad + 44);
    roundedRect(ctx, coinX, top, coinWidth, badgeHeight, 12);
    ctx.fillStyle = "rgba(5, 16, 23, 0.82)";
    ctx.fill();
    drawFrameInBox(ctx, icons, "coin", coinX + 5, top + 7, badgeHeight - 14, badgeHeight - 14);
    ctx.font = `700 ${Math.max(12, Math.min(16, width * 0.036))}px Inter, sans-serif`;
    ctx.fillStyle = "#ffd86a";
    ctx.textAlign = "end";
    ctx.fillText(String(world.runCoins), coinX + coinWidth - 8, top + badgeHeight / 2);
    ctx.restore();

    const meterY = top + badgeHeight + 4;
    const meterW = Math.min(110, width * 0.28);
    const rageX = pad;
    ctx.fillStyle = "rgba(3,8,12,.78)";
    ctx.fillRect(rageX, meterY, meterW, 6);
    ctx.fillStyle = world.player.rageActive > 0 ? "#ff4b2e" : "#d27a42";
    ctx.fillRect(rageX, meterY, meterW * (world.player.rage / 100), 6);
    ctx.fillStyle = "rgba(3,8,12,.78)";
    ctx.fillRect(width - pad - meterW - 48, meterY, meterW, 6);
    ctx.fillStyle = world.player.ultimate >= 100 ? "#fff19a" : "#a56cff";
    ctx.fillRect(width - pad - meterW - 48, meterY, meterW * (world.player.ultimate / 100), 6);

    const boss = world.enemies.find((enemy) => enemy.kind === "boss" && !enemy.dead);
    if (boss) {
      const barX = width * 0.12;
      const barY = top + badgeHeight + 7;
      const barW = width * 0.76;
      const barH = 13;
      roundedRect(ctx, barX, barY, barW, barH, 7);
      ctx.fillStyle = "rgba(4, 8, 16, 0.9)";
      ctx.fill();
      const ratio = Math.max(0, boss.hp / boss.maxHp);
      roundedRect(ctx, barX + 2, barY + 2, (barW - 4) * ratio, barH - 4, 5);
      ctx.fillStyle = boss.egged ? "#ffb52e" : world.area.accent;
      ctx.fill();
      const portrait = bossPortraits[boss.sourceArea ?? world.areaIndex];
      if (portrait) drawFrameInBox(ctx, store.get("BOSS_PORTRAIT_ATLAS"), portrait, Math.max(2, barX - 32), barY - 9, 30, 30);
      ctx.font = `700 ${Math.max(10, Math.min(13, width * 0.029))}px Inter, sans-serif`;
      ctx.fillStyle = "#fff";
      ctx.textAlign = "center";
      ctx.fillText(boss.egged ? `TELUR · ${Math.ceil(boss.reviveClock)}s` : boss.name, width / 2, barY + barH + 10);
    }
  };

  const drawEnemy = (world, enemy) => {
    const attacking = enemy.attackPulse > 0 || enemy.state === "ground" || enemy.egged;
    const sheet = store.get(attacking ? (enemy.attackKey || world.area.attackKey) : (enemy.moveKey || world.area.moveKey));
    const animation = attacking ? enemy.attackAnim : enemy.moveAnim;
    const base = Math.min(enemy.size, height * (enemy.kind === "boss" ? 0.3 : enemy.kind === "mini" ? 0.19 : 0.125));
    const alpha = enemy.behavior === "phase" && enemy.invulnerable ? 0.38 : enemy.preview ? 0.88 : 1;
    if (enemy.state === "fall" && !enemy.preview) {
      const danger = store.get("DANGER_EFFECTS");
      drawAnimation(ctx, danger, "landing_shadow", enemy.age * 1.4, enemy.x, world.groundY + 4, Math.max(34, enemy.width * 0.46), false, Math.min(0.9, 0.25 + enemy.y / world.groundY));
    }
    if (enemy.hitPulse > 0) {
      const gradient = ctx.createRadialGradient(enemy.x, enemy.y, 4, enemy.x, enemy.y, base * 0.7);
      gradient.addColorStop(0, "rgba(255,255,255,.8)");
      gradient.addColorStop(1, "rgba(255,255,255,0)");
      ctx.fillStyle = gradient;
      ctx.fillRect(enemy.x - base, enemy.y - base, base * 2, base * 2);
    }
    drawAnimation(ctx, sheet, animation, enemy.age, enemy.x, enemy.y + base * 0.48, base, enemy.state === "ground" && enemy.x > world.player.x, alpha);
    if (enemy.kind === "mini" || (enemy.kind === "rare" && enemy.hp < enemy.maxHp)) {
      const barW = base * 0.72;
      const barY = enemy.y - base * 0.56;
      ctx.fillStyle = "rgba(0,0,0,.72)";
      ctx.fillRect(enemy.x - barW / 2, barY, barW, 5);
      ctx.fillStyle = world.area.accent;
      ctx.fillRect(enemy.x - barW / 2 + 1, barY + 1, (barW - 2) * Math.max(0, enemy.hp / enemy.maxHp), 3);
    }
  };

  const drawPlayer = (world) => {
    const player = world.player;
    let key = world.skin.moveKey;
    let animation = "idle_aim_up";
    if (player.action) { key = world.skin.combatKey; animation = player.action; }
    else if (world.state === "victory") { key = world.skin.combatKey; animation = "ultimate"; }
    else if (player.shootPulse > 0) animation = "shoot_up";
    else if (player.jump > 0) animation = "jump_up";
    else if (player.move) animation = "run_aim_up";
    const targetHeight = Math.min(128, Math.max(82, height * 0.17));
    const alpha = player.invulnerable > 0 && Math.floor(player.invulnerable * 12) % 2 ? 0.38 : 1;
    if (player.rageActive > 0) {
      const aura = ctx.createRadialGradient(player.x, world.groundY - player.jump - targetHeight * 0.45, 8, player.x, world.groundY - player.jump - targetHeight * 0.45, targetHeight * 0.75);
      aura.addColorStop(0, "rgba(255,80,35,.36)");
      aura.addColorStop(1, "rgba(255,45,20,0)");
      ctx.fillStyle = aura;
      ctx.fillRect(player.x - targetHeight, world.groundY - player.jump - targetHeight * 1.4, targetHeight * 2, targetHeight * 1.6);
    }
    drawAnimation(ctx, store.get(key), animation, world.time, player.x, world.groundY - player.jump, targetHeight, player.facing < 0, alpha);
  };

  const render = (world, settings) => {
    if (!width || !height) return;
    ctx.save();
    if (!settings.reducedShake && world.shake > 0) ctx.translate((Math.random() - 0.5) * world.shake, (Math.random() - 0.5) * world.shake);
    const bg = store.get(world.area.backgroundKey);
    if (bg) drawCover(ctx, bg.image, width, height);
    else { ctx.fillStyle = "#07151b"; ctx.fillRect(0, 0, width, height); }
    const shade = ctx.createLinearGradient(0, 0, 0, height);
    shade.addColorStop(0, "rgba(2,8,14,.12)");
    shade.addColorStop(0.7, "rgba(1,8,12,.03)");
    shade.addColorStop(1, "rgba(1,5,9,.42)");
    ctx.fillStyle = shade;
    ctx.fillRect(0, 0, width, height);

    for (const effect of world.effects.filter((entry) => ["laser", "dive", "landing"].includes(entry.type))) drawEffect(effect);
    drawGround(world);
    for (const coin of world.coins) drawFrameInBox(ctx, store.get("HUD_ICON_ATLAS"), "coin", coin.x - 11, coin.y - 11, 22, 22);
    for (const enemy of world.enemies) drawEnemy(world, enemy);

    const projectileSheet = store.get("PROJECTILE_ATLAS");
    for (const arrow of world.arrows) {
      drawAnimation(ctx, store.get("ARROW_EFFECTS_B"), "arrow_trail", world.time * 1.6, arrow.x, arrow.y + arrow.height * 0.45, 48, false, 0.72);
      drawFrameInBox(ctx, projectileSheet, "hero_arrow", arrow.x - arrow.width / 2, arrow.y - arrow.height / 2, arrow.width, arrow.height);
    }
    for (const projectile of world.projectiles) {
      drawFrameInBox(ctx, projectileSheet, projectile.frame, projectile.x - projectile.width / 2, projectile.y - projectile.height / 2, projectile.width, projectile.height);
    }
    drawPlayer(world);
    for (const effect of world.effects.filter((entry) => !["laser", "dive", "landing"].includes(entry.type))) drawEffect(effect);
    for (const label of world.labels) {
      const fade = 1 - label.age / label.duration;
      ctx.globalAlpha = fade;
      ctx.font = `800 ${Math.max(13, Math.min(20, width * 0.042))}px Inter, sans-serif`;
      ctx.textAlign = "center";
      ctx.fillStyle = "rgba(6,10,14,.76)";
      ctx.fillRect(label.x - 20, label.y - 12, 40, 24);
      ctx.fillStyle = label.color;
      ctx.fillText(label.text, label.x, label.y + 2);
      ctx.globalAlpha = 1;
    }
    drawHUD(world);
    if (world.state === "ready") {
      const promptWidth = Math.min(width - 32, 250);
      roundedRect(ctx, (width - promptWidth) / 2, height * 0.61, promptWidth, 42, 12);
      ctx.fillStyle = "rgba(5, 15, 22, .86)";
      ctx.fill();
      ctx.fillStyle = "#fff7df";
      ctx.font = `700 ${Math.max(13, Math.min(17, width * 0.038))}px Inter, sans-serif`;
      ctx.textAlign = "center";
      ctx.fillText("SENTUH UNTUK BERTAHAN", width / 2, height * 0.61 + 22);
    }
    if (world.flash > 0) {
      ctx.fillStyle = `rgba(255,80,90,${world.flash * 1.8})`;
      ctx.fillRect(0, 0, width, height);
    }
    ctx.restore();
  };

  return {
    get width() { return width; },
    get height() { return height; },
    mount(onResize) {
      resize(onResize);
      observer = new ResizeObserver(() => resize(onResize));
      observer.observe(canvas);
    },
    render,
    destroy() { observer?.disconnect(); },
  };
}
