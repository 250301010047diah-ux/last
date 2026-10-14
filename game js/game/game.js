import { createSynthAudio } from "./audio.js";
import { AssetStore } from "./assets.js";
import { AREAS, DEFAULT_SAVE, RELICS, SKINS, upgradeChoices } from "./data.js";
import { createInput } from "./input.js";
import { createRenderer } from "./renderer.js";
import { createUI } from "./ui.js";
import { CombatWorld } from "./world.js";

const sanitizeSave = (value) => ({
  ...structuredClone(DEFAULT_SAVE),
  ...(value && typeof value === "object" ? value : {}),
  stats: { ...DEFAULT_SAVE.stats, ...(value?.stats || {}) },
  relics: Array.isArray(value?.relics) ? value.relics.filter((entry) => Number.isInteger(entry) && entry >= 0 && entry < 20) : [],
  selectedSkin: Number.isInteger(value?.selectedSkin) && value.selectedSkin >= 0 && value.selectedSkin < 20 ? value.selectedSkin : null,
});

const scoreValue = (score) => Number.isFinite(score) ? Math.max(0, Math.min(Math.round(score), Number.MAX_SAFE_INTEGER)) : 0;

export function createGame({ mount, sdk, ready, tweaks, assets }) {
  let cleanup = () => {};

  return {
    start() {
      const ui = createUI(mount);
      const store = new AssetStore(assets);
      const tuning = {
        fallSpeed: tweaks.get("fallSpeed"),
        spawnInterval: tweaks.get("spawnInterval"),
        playerSpeed: tweaks.get("playerSpeed"),
        fireRate: tweaks.get("fireRate"),
        enemyHpScale: tweaks.get("enemyHpScale"),
        effectsIntensity: tweaks.get("effectsIntensity"),
        musicVolume: tweaks.get("musicVolume"),
        sfxVolume: tweaks.get("sfxVolume"),
        skillCooldownScale: tweaks.get("skillCooldownScale"),
        rageDuration: tweaks.get("rageDuration"),
      };
      const settings = { reducedShake: false, muted: false };
      const audio = createSynthAudio(sdk, tuning);
      const renderer = createRenderer(ui.canvas, store);
      let save = structuredClone(DEFAULT_SAVE);
      let world = null;
      let activeArea = 0;
      let endless = false;
      let running = true;
      let paused = false;
      let lastTime = performance.now();
      let frameId = 0;

      const persist = () => { void sdk.gameState.save(save).catch(() => {}); };
      const submit = (score) => { void sdk.leaderboard.submit(scoreValue(score)).catch(() => {}); };
      const canVibrate = () => ready && sdk.device.haptics.isSupported();
      const input = createInput(ui.canvas, () => {
        if (!world) return;
        void audio.unlock(world.areaIndex);
        world.engage();
      }, () => world?.jump(), (action) => world?.useAction(action));
      ui.onCombat((action) => world?.useAction(action));

      const tuningCleanup = tweaks.onChange((key, value) => {
        if (Object.hasOwn(tuning, key)) tuning[key] = value;
      });

      const showSkinSelect = (firstTime = false) => {
        paused = true;
        ui.setPlaying(false);
        ui.skinSelect(save.selectedSkin, (skinId) => {
          save.selectedSkin = skinId;
          persist();
          ui.toast(`${SKINS[skinId].name} dipilih`);
          showMap();
        }, firstTime ? null : showMap);
      };

      const showMap = () => {
        paused = true;
        ui.setPlaying(false);
        ui.map(save, (index) => { void startArea(index, false); }, (stat) => {
          const level = save.stats[stat];
          const cost = 40 + level * 35;
          if (level >= 5 || save.coins < cost) { ui.toast("Koin belum cukup"); return; }
          save.coins -= cost;
          save.stats[stat] += 1;
          persist();
          showMap();
        }, () => { void startArea(Math.floor(Math.random() * AREAS.length), true); }, () => showSkinSelect(false));
      };

      const finishDefeat = (defeatedWorld) => {
        paused = true;
        ui.setPlaying(false);
        save.coins += defeatedWorld.runCoins;
        save.bestScore = Math.max(save.bestScore, defeatedWorld.score);
        persist();
        submit(defeatedWorld.score);
        ui.gameOver({ wave: defeatedWorld.wave, score: defeatedWorld.score, coins: defeatedWorld.runCoins, best: save.bestScore, cause: defeatedWorld.cause }, () => { void startArea(activeArea, endless); }, showMap);
      };

      const finishVictory = (victoriousWorld) => {
        if (victoriousWorld.endless) return;
        paused = true;
        ui.setPlaying(false);
        save.coins += victoriousWorld.runCoins;
        save.bestScore = Math.max(save.bestScore, victoriousWorld.score);
        if (!save.relics.includes(activeArea)) save.relics.push(activeArea);
        save.relics.sort((a, b) => a - b);
        save.unlockedArea = Math.max(save.unlockedArea, Math.min(20, activeArea + 2));
        if (activeArea === 19) save.endlessUnlocked = true;
        persist();
        submit(victoriousWorld.score);
        ui.areaClear({ area: AREAS[activeArea], relic: RELICS[activeArea], score: victoriousWorld.score, coins: victoriousWorld.runCoins, hasNext: activeArea < 19 }, () => {
          if (activeArea < 19) void startArea(activeArea + 1, false);
          else void startArea(Math.floor(Math.random() * AREAS.length), true);
        }, showMap);
      };

      const makeWorld = (areaIndex, isEndless) => new CombatWorld({
        area: AREAS[areaIndex],
        areaIndex,
        stats: save.stats,
        relics: save.relics,
        skin: SKINS[save.selectedSkin ?? 0],
        tuning,
        audio,
        haptics: sdk.device.haptics,
        endless: isEndless,
        callbacks: {
          onBanner: (message) => ui.toast(message),
          onUpgrade: (upgradeWorld) => {
            paused = true;
            ui.setPlaying(false);
            const choices = upgradeChoices(upgradeWorld.levels);
            ui.upgrade(choices, upgradeWorld.levels, (id) => {
              ui.hideOverlay();
              paused = false;
              ui.setPlaying(true);
              upgradeWorld.resumeAfterUpgrade(id);
            });
          },
          onDefeat: finishDefeat,
          onVictory: finishVictory,
          onAreaShift: (area) => { audio.setArea(area.id - 1); ui.toast(area.name); },
          getCanvasRect: () => ui.canvas.getBoundingClientRect(),
          canVibrate,
        },
      });

      async function startArea(index, isEndless) {
        activeArea = index;
        endless = isEndless;
        paused = true;
        ui.setPlaying(false);
        ui.loading(isEndless ? "Menyatukan dua puluh retakan…" : `Membuka ${AREAS[index].name}…`);
        try {
          const skin = SKINS[save.selectedSkin ?? 0];
          if (isEndless) await Promise.all([store.loadSkin(skin), ...AREAS.map((area) => store.loadArea(area))]);
          else await Promise.all([store.loadSkin(skin), store.loadArea(AREAS[index])]);
          world = makeWorld(index, isEndless);
          world.resize(renderer.width, renderer.height);
          audio.setArea(index);
          input.resetEngaged();
          ui.ready(AREAS[index], () => {
            ui.hideOverlay();
            ui.setPlaying(true);
            paused = false;
            void audio.unlock(index);
            world.engage();
          }, showMap);
        } catch (error) {
          ui.error(error instanceof Error ? error.message : "Jalur tidak dikenal", () => { void startArea(index, isEndless); });
        }
      }

      ui.pauseButton.addEventListener("click", () => {
        if (!world || paused) return;
        paused = true;
        ui.setPlaying(false);
        ui.pause(() => { audio.setMuted(settings.muted); ui.hideOverlay(); paused = false; ui.setPlaying(true); }, showMap, settings);
      });

      renderer.mount((width, height) => world?.resize(width, height));
      const loop = (time) => {
        if (!running) return;
        const dt = Math.min(0.033, Math.max(0, (time - lastTime) / 1000));
        lastTime = time;
        if (world && !paused) world.update(dt, input.state);
        if (world) { renderer.render(world, settings); ui.updateSkills(world); }
        frameId = requestAnimationFrame(loop);
      };
      frameId = requestAnimationFrame(loop);

      const boot = async () => {
        ui.loading();
        try {
          const [loadedSave] = await Promise.all([sdk.gameState.load().catch(() => null), store.loadGlobal(), store.loadArea(AREAS[0])]);
          save = sanitizeSave(loadedSave);
          if (save.selectedSkin === null) showSkinSelect(true);
          else showMap();
        } catch (error) {
          ui.error(error instanceof Error ? error.message : "Aset tidak dapat dibuka", () => { void boot(); });
        }
      };
      void boot();

      cleanup = () => {
        running = false;
        cancelAnimationFrame(frameId);
        input.destroy();
        renderer.destroy();
        tuningCleanup?.();
        void audio.destroy();
        ui.destroy();
      };
    },
    destroy() {
      cleanup();
      cleanup = () => {};
    },
  };
}
