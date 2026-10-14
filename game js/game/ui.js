import { AREAS, RELICS, SKINS } from "./data.js";

function button(label, action, extra = "") {
  return `<button class="control-btn ${extra}" data-action="${action}"><span class="control-label">${label}</span></button>`;
}

export function createUI(mount) {
  const shell = document.createElement("section");
  shell.className = "game-shell";
  shell.innerHTML = `
    <canvas class="game-canvas" aria-label="Arena Runtuh Langit"></canvas>
    <button class="pause-button" aria-label="Jeda" hidden>Ⅱ</button>
    <div class="combat-controls" hidden>
      <button data-combat="melee" aria-label="Melee"><b>⚔</b><small>J</small></button>
      <button data-combat="skill1" aria-label="Skill satu"><b>S1</b><small>K</small></button>
      <button data-combat="skill2" aria-label="Skill dua"><b>S2</b><small>L</small></button>
      <button data-combat="ultimate" class="ultimate-button" aria-label="Ultimate"><b>ULT</b><small>U</small></button>
    </div>
    <div class="toast" hidden></div>
    <div class="overlay" hidden></div>
  `;
  mount.replaceChildren(shell);
  const canvas = shell.querySelector("canvas");
  const overlay = shell.querySelector(".overlay");
  const toast = shell.querySelector(".toast");
  const pauseButton = shell.querySelector(".pause-button");
  const combatControls = shell.querySelector(".combat-controls");
  let toastTimer = 0;

  const showOverlay = (html) => {
    overlay.innerHTML = html;
    overlay.hidden = false;
  };

  const bind = (selector, handler) => {
    overlay.querySelectorAll(selector).forEach((element) => element.addEventListener("click", handler));
  };

  return {
    shell,
    canvas,
    pauseButton,
    onCombat(handler) {
      combatControls.querySelectorAll("button").forEach((element) => element.addEventListener("click", () => handler(element.dataset.combat)));
    },
    hideOverlay() { overlay.hidden = true; overlay.innerHTML = ""; },
    setPlaying(playing) { pauseButton.hidden = !playing; combatControls.hidden = !playing; },
    updateSkills(world) {
      const values = {
        melee: world.player.meleeCooldown,
        skill1: world.player.skillOneCooldown,
        skill2: world.player.skillTwoCooldown,
        ultimate: world.player.ultimate >= 100 ? 0 : -1,
      };
      combatControls.querySelectorAll("button").forEach((element) => {
        const value = values[element.dataset.combat];
        element.disabled = value > 0 || value < 0;
        element.classList.toggle("ready", value === 0);
        const small = element.querySelector("small");
        small.textContent = value > 0 ? Math.ceil(value) : value < 0 ? `${Math.floor(world.player.ultimate)}%` : element.dataset.combat === "ultimate" ? "SIAP" : ({ melee: "J", skill1: "K", skill2: "L" }[element.dataset.combat]);
      });
    },
    toast(message, duration = 1100) {
      clearTimeout(toastTimer);
      toast.textContent = message;
      toast.hidden = false;
      toastTimer = window.setTimeout(() => { toast.hidden = true; }, duration);
    },
    loading(message = "Membuka langit…") {
      showOverlay(`<div class="panel compact"><div class="loading-rune"></div><strong>${message}</strong></div>`);
    },
    error(message, retry) {
      showOverlay(`<div class="panel"><p class="eyebrow">JALUR TERPUTUS</p><h2>Aset belum siap</h2><p>${message}</p>${button("Coba Lagi", "retry", "primary")}</div>`);
      bind('[data-action="retry"]', retry);
    },
    ready(area, start, back) {
      showOverlay(`<div class="panel ready-panel">
        <p class="eyebrow">AREA ${area.id} · WAVE 1</p>
        <h2>${area.name}</h2><p>${area.subtitle}</p>
        <div class="ready-controls"><span>↔ Seret untuk bergerak</span><span>↑ Ketuk untuk lompat</span><span>➶ Panah otomatis</span></div>
        ${button("Tahan Tanah", "start", "primary")}${button("Peta", "back", "ghost")}
      </div>`);
      bind('[data-action="start"]', start);
      bind('[data-action="back"]', back);
    },
    skinSelect(selected, choose, back = null) {
      const cards = SKINS.map((skin) => `<button class="skin-card ${selected === skin.id ? "selected" : ""}" data-skin="${skin.id}" style="--skin-hue:${(skin.id * 37) % 360}"><span>${String(skin.id + 1).padStart(2, "0")}</span><strong>${skin.name}</strong><small>${skin.buffLabel}</small></button>`).join("");
      showOverlay(`<div class="skin-panel"><div class="map-head"><div><p class="eyebrow">20 SKIN GRATIS</p><h2>Pilih Asha</h2></div>${selected !== null ? `<div class="coin-total">Skin ${selected + 1}</div>` : ""}</div><div class="skin-grid">${cards}</div>${back ? button("Kembali", "back", "ghost") : ""}</div>`);
      bind("[data-skin]", (event) => choose(Number(event.currentTarget.dataset.skin)));
      if (back) bind('[data-action="back"]', back);
    },
    map(save, selectArea, buyStat, startEndless, changeSkin) {
      const nodes = AREAS.map((area, index) => {
        const unlocked = index < save.unlockedArea;
        const cleared = save.relics.includes(index);
        return `<button class="area-node ${unlocked ? "unlocked" : "locked"} ${cleared ? "cleared" : ""}" data-area="${index}" ${unlocked ? "" : "disabled"} style="--accent:${area.accent}">
          <span class="area-number">${area.id}</span><span>${area.name}</span><small>${cleared ? RELICS[index][0] : unlocked ? "Masuk" : "Terkunci"}</small>
        </button>`;
      }).join("");
      const stats = [
        ["damage", "Damage", save.stats.damage],
        ["fireRate", "Fire Rate", save.stats.fireRate],
        ["moveSpeed", "Move Speed", save.stats.moveSpeed],
      ].map(([id, label, level]) => `<button class="stat-upgrade" data-stat="${id}" ${level >= 5 ? "disabled" : ""}><span>${label}</span><b>${"◆".repeat(level)}${"◇".repeat(5 - level)}</b><small>${level >= 5 ? "MAX" : `${40 + level * 35} koin`}</small></button>`).join("");
      showOverlay(`<div class="map-panel">
        <div class="map-head"><div><p class="eyebrow">20 AREA · 3 BABAK</p><h2>Pilih retakan</h2></div><div class="coin-total">◉ ${save.coins}</div></div>
        <div class="area-grid">${nodes}</div>
        <div class="stat-row">${stats}</div>
        <div class="map-actions">${button(`Skin ${save.selectedSkin + 1}`, "skin", "ghost")}${save.endlessUnlocked ? button("Endless Rift", "endless", "primary endless") : ""}</div>
      </div>`);
      bind("[data-area]", (event) => selectArea(Number(event.currentTarget.dataset.area)));
      bind("[data-stat]", (event) => buyStat(event.currentTarget.dataset.stat));
      bind('[data-action="endless"]', startEndless);
      bind('[data-action="skin"]', changeSkin);
    },
    upgrade(choices, levels, choose) {
      const cards = choices.map((choice) => `<button class="upgrade-card" data-upgrade="${choice.id}"><span class="upgrade-glyph">${choice.element ? "✦" : "➶"}</span><strong>${choice.label}</strong><small>${choice.detail}</small><em>Lv. ${(levels[choice.id] || 0) + 1}</em></button>`).join("");
      showOverlay(`<div class="upgrade-panel"><p class="eyebrow">PILIH BERKAT PANAH</p><h2>Langit memberi celah</h2><div class="upgrade-grid">${cards}</div></div>`);
      bind("[data-upgrade]", (event) => choose(event.currentTarget.dataset.upgrade));
    },
    pause(resume, map, settings) {
      showOverlay(`<div class="panel"><p class="eyebrow">JEDA</p><h2>Napas sejenak</h2>
        ${button("Lanjut", "resume", "primary")}${button(settings.reducedShake ? "Getaran: Ringan" : "Getaran: Penuh", "shake", "ghost")}${button(settings.muted ? "Suara: Mati" : "Suara: Hidup", "mute", "ghost")}${button("Kembali ke Peta", "map", "danger")}
      </div>`);
      bind('[data-action="resume"]', resume);
      bind('[data-action="map"]', map);
      bind('[data-action="shake"]', () => { settings.reducedShake = !settings.reducedShake; this.pause(resume, map, settings); });
      bind('[data-action="mute"]', () => { settings.muted = !settings.muted; this.pause(resume, map, settings); });
    },
    gameOver(result, retry, map) {
      showOverlay(`<div class="panel result-panel"><p class="eyebrow">TANAH RUNTUH</p><h2>Wave ${result.wave}</h2><div class="result-score">${result.score.toLocaleString("id-ID")}</div><p>Skor · ${result.cause}</p><small>Rekor ${result.best.toLocaleString("id-ID")} · +${result.coins} koin</small>${button("Coba Lagi", "retry", "primary")}${button("Peta", "map", "ghost")}</div>`);
      bind('[data-action="retry"]', retry);
      bind('[data-action="map"]', map);
    },
    areaClear(result, next, map) {
      showOverlay(`<div class="panel result-panel victory"><p class="eyebrow">LANGIT DIBERSIHKAN</p><h2>${result.area.name}</h2><div class="relic-seal">✦</div><strong>${result.relic[0]}</strong><p>${result.relic[1]}</p><div class="result-score">${result.score.toLocaleString("id-ID")}</div><small>+${result.coins} koin tersimpan</small>${result.hasNext ? button("Area Berikutnya", "next", "primary") : button("Masuk Endless Rift", "next", "primary")}${button("Peta", "map", "ghost")}</div>`);
      bind('[data-action="next"]', next);
      bind('[data-action="map"]', map);
    },
    destroy() {
      clearTimeout(toastTimer);
      mount.replaceChildren();
    },
  };
}
