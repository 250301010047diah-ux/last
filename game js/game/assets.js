import manifest from "../assets.json";

function sidecarUrl(url) {
  const [path, query = ""] = url.split("?");
  return `${path.replace(/\.webp$/u, ".frames.json")}${query ? `?${query}` : ""}`;
}

function loadImage(url) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.decoding = "async";
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error(`Gagal memuat ${url}`));
    image.src = url;
  });
}

export class AssetStore {
  constructor(assetHandle) {
    this.assetHandle = assetHandle;
    this.items = new Map();
    this.loading = new Map();
  }

  url(key) {
    return this.assetHandle?.get(key) || manifest[key];
  }

  async load(key, withFrames = true) {
    if (this.items.has(key)) return this.items.get(key);
    if (this.loading.has(key)) return this.loading.get(key);
    const task = (async () => {
      const url = this.url(key);
      if (!url) throw new Error(`Aset ${key} tidak ditemukan`);
      const image = await loadImage(url);
      let frames = null;
      if (withFrames) {
        const response = await fetch(sidecarUrl(manifest[key] || url));
        if (!response.ok) throw new Error(`Data frame ${key} tidak ditemukan`);
        frames = await response.json();
      }
      const item = {
        image,
        data: frames,
        frameMap: new Map((frames?.frames || []).map((frame) => [frame.name, frame])),
        animations: new Map((frames?.animations || []).map((animation) => [animation.name, animation.frames])),
      };
      this.items.set(key, item);
      return item;
    })();
    this.loading.set(key, task);
    try {
      return await task;
    } finally {
      this.loading.delete(key);
    }
  }

  async loadGlobal() {
    await Promise.all([
      this.load("ASHA_MOVE_SHEET"),
      this.load("ASHA_COMBAT_SHEET"),
      this.load("PROJECTILE_ATLAS"),
      this.load("HUD_ICON_ATLAS"),
      this.load("ARROW_EFFECTS_A"),
      this.load("ARROW_EFFECTS_B"),
      this.load("ENEMY_DEATH_EFFECTS"),
      this.load("DANGER_EFFECTS"),
      this.load("BOSS_PORTRAIT_ATLAS"),
    ]);
  }

  async loadArea(area) {
    await Promise.all([
      this.load(area.backgroundKey, false),
      this.load(area.groundKey),
      this.load(area.moveKey),
      this.load(area.attackKey),
    ]);
  }

  async loadSkin(skin) {
    await Promise.all([
      this.load(skin.moveKey),
      this.load(skin.combatKey),
      this.load(skin.effectsKey),
    ]);
  }

  get(key) {
    return this.items.get(key);
  }
}

export function drawFrameInBox(ctx, sheet, frameName, x, y, width, height, alpha = 1) {
  const frame = sheet?.frameMap.get(frameName);
  if (!frame) return;
  const crop = frame.content || frame.source;
  const scale = Math.min(width / crop.w, height / crop.h);
  const drawWidth = crop.w * scale;
  const drawHeight = crop.h * scale;
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.drawImage(
    sheet.image,
    crop.x,
    crop.y,
    crop.w,
    crop.h,
    x + (width - drawWidth) / 2,
    y + (height - drawHeight) / 2,
    drawWidth,
    drawHeight,
  );
  ctx.restore();
}

export function drawAnimation(ctx, sheet, animationName, time, anchorX, anchorY, targetHeight, flip = false, alpha = 1) {
  const frames = sheet?.animations.get(animationName);
  if (!frames?.length) return;
  const frame = frames[Math.floor(time * 9) % frames.length];
  const crop = frame.content || frame.source;
  const maxHeight = Math.max(...frames.map((entry) => (entry.content || entry.source).h));
  const scale = targetHeight / maxHeight;
  const anchor = frame.anchor || { x: frame.source.x + frame.source.w / 2, y: frame.source.y + frame.source.h };
  const dx = (crop.x - anchor.x) * scale;
  const dy = (crop.y - anchor.y) * scale;
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.translate(anchorX, anchorY);
  if (flip) ctx.scale(-1, 1);
  ctx.drawImage(sheet.image, crop.x, crop.y, crop.w, crop.h, dx, dy, crop.w * scale, crop.h * scale);
  ctx.restore();
}
