export function createSynthAudio(sdk, tuning) {
  let managed = null;
  let context = null;
  let musicNodes = [];
  let unlocked = false;
  let muted = false;
  let musicMaster = null;

  const stopMusic = () => {
    for (const node of musicNodes) {
      try { node.stop?.(); } catch { /* already stopped */ }
      try { node.disconnect?.(); } catch { /* already disconnected */ }
    }
    musicNodes = [];
  };

  const startMusic = (areaIndex = 0) => {
    if (!context || context.state !== "running") return;
    stopMusic();
    const roots = [98, 82, 110, 73, 92, 65, 104, 123, 58, 55];
    const root = roots[areaIndex] || 82;
    const master = context.createGain();
    master.gain.value = muted ? 0 : tuning.musicVolume * 0.045;
    musicMaster = master;
    master.connect(context.destination);
    const lfo = context.createOscillator();
    const lfoGain = context.createGain();
    lfo.frequency.value = 0.12 + areaIndex * 0.008;
    lfoGain.gain.value = 0.018;
    lfo.connect(lfoGain).connect(master.gain);
    lfo.start();
    musicNodes.push(lfo, lfoGain, master);
    for (const [ratio, type, gainValue] of [[1, "sawtooth", 0.45], [1.5, "triangle", 0.25], [2, "sine", 0.15]]) {
      const osc = context.createOscillator();
      const gain = context.createGain();
      osc.type = type;
      osc.frequency.value = root * ratio;
      gain.gain.value = gainValue;
      osc.connect(gain).connect(master);
      osc.start();
      musicNodes.push(osc, gain);
    }
  };

  const unlock = async (areaIndex = 0) => {
    if (unlocked) return;
    try {
      managed = await sdk.audio.getContext();
      await managed.unlock();
      context = managed.context;
      unlocked = true;
      startMusic(areaIndex);
    } catch {
      // The game remains fully playable without audio.
    }
  };

  const tone = (frequency, duration, type = "triangle", volume = 0.2, slide = 1) => {
    if (!context || context.state !== "running") return;
    const now = context.currentTime;
    const osc = context.createOscillator();
    const gain = context.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(frequency, now);
    osc.frequency.exponentialRampToValueAtTime(Math.max(30, frequency * slide), now + duration);
    gain.gain.setValueAtTime(Math.max(0.001, volume * tuning.sfxVolume), now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + duration);
    osc.connect(gain).connect(context.destination);
    osc.start(now);
    osc.stop(now + duration);
  };

  const noise = (duration = 0.12, volume = 0.1) => {
    if (!context || context.state !== "running") return;
    const length = Math.max(1, Math.floor(context.sampleRate * duration));
    const buffer = context.createBuffer(1, length, context.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < length; i += 1) data[i] = (Math.random() * 2 - 1) * (1 - i / length);
    const source = context.createBufferSource();
    const gain = context.createGain();
    gain.gain.value = volume * tuning.sfxVolume;
    source.buffer = buffer;
    source.connect(gain).connect(context.destination);
    source.start();
  };

  const play = (name, intensity = 1) => {
    if (muted) return;
    const scale = Math.max(0.3, Math.min(1.5, intensity));
    if (name === "shoot") { tone(520, 0.07, "triangle", 0.12 * scale, 1.8); noise(0.05, 0.04); }
    if (name === "hit") { tone(220, 0.09, "square", 0.1 * scale, 0.45); noise(0.07, 0.06 * scale); }
    if (name === "land") { tone(75, 0.18, "sine", 0.22 * scale, 0.5); noise(0.14, 0.11 * scale); }
    if (name === "hurt") { tone(140, 0.2, "sawtooth", 0.16, 0.55); noise(0.09, 0.08); }
    if (name === "death") { tone(300, 0.2, "triangle", 0.12 * scale, 0.32); noise(0.16, 0.08 * scale); }
    if (name === "warning") { tone(92, 0.42, "sawtooth", 0.2, 1.8); }
    if (name === "coin") { tone(760 + scale * 90, 0.07, "sine", 0.09, 1.35); }
    if (name === "upgrade") { tone(440, 0.18, "triangle", 0.15, 2.4); }
    if (name === "jump") { tone(260, 0.08, "sine", 0.08, 1.7); }
  };

  return {
    unlock,
    play,
    setArea(index) { if (unlocked) startMusic(index); },
    setMuted(value) {
      muted = value;
      if (musicMaster && context) musicMaster.gain.setTargetAtTime(muted ? 0 : tuning.musicVolume * 0.045, context.currentTime, 0.05);
    },
    async destroy() {
      stopMusic();
      if (managed) await managed.dispose().catch(() => {});
    },
  };
}
