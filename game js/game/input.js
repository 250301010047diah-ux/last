export function createInput(surface, onEngage, onJump, onAction = () => {}) {
  const state = { left: false, right: false, pointer: false, targetX: null, engaged: false };
  let startX = 0;
  let startY = 0;
  let startTime = 0;

  const engage = () => {
    if (state.engaged) return;
    state.engaged = true;
    onEngage();
  };

  const pointerDown = (event) => {
    if (event.target.closest("button, [role='button'], .overlay")) return;
    event.preventDefault();
    engage();
    state.pointer = true;
    startX = event.clientX;
    startY = event.clientY;
    startTime = performance.now();
    state.targetX = event.clientX;
    surface.setPointerCapture?.(event.pointerId);
  };

  const pointerMove = (event) => {
    if (!state.pointer) return;
    event.preventDefault();
    state.targetX = event.clientX;
  };

  const pointerUp = (event) => {
    if (!state.pointer) return;
    const distance = Math.hypot(event.clientX - startX, event.clientY - startY);
    if (performance.now() - startTime < 220 && distance < 14) onJump();
    state.pointer = false;
    state.targetX = null;
  };

  const keyDown = (event) => {
    if (["ArrowLeft", "ArrowRight", "KeyA", "KeyD", "Space", "KeyJ", "KeyK", "KeyL", "KeyU"].includes(event.code)) event.preventDefault();
    if (["ArrowLeft", "KeyA"].includes(event.code)) state.left = true;
    if (["ArrowRight", "KeyD"].includes(event.code)) state.right = true;
    if (event.code === "Space" && !event.repeat) {
      engage();
      onJump();
    }
    if (!event.repeat && event.code === "KeyJ") onAction("melee");
    if (!event.repeat && event.code === "KeyK") onAction("skill1");
    if (!event.repeat && event.code === "KeyL") onAction("skill2");
    if (!event.repeat && event.code === "KeyU") onAction("ultimate");
    engage();
  };

  const keyUp = (event) => {
    if (["ArrowLeft", "KeyA"].includes(event.code)) state.left = false;
    if (["ArrowRight", "KeyD"].includes(event.code)) state.right = false;
  };

  surface.addEventListener("pointerdown", pointerDown);
  surface.addEventListener("pointermove", pointerMove);
  surface.addEventListener("pointerup", pointerUp);
  surface.addEventListener("pointercancel", pointerUp);
  window.addEventListener("keydown", keyDown, { passive: false });
  window.addEventListener("keyup", keyUp);

  return {
    state,
    resetEngaged() {
      state.engaged = false;
    },
    destroy() {
      surface.removeEventListener("pointerdown", pointerDown);
      surface.removeEventListener("pointermove", pointerMove);
      surface.removeEventListener("pointerup", pointerUp);
      surface.removeEventListener("pointercancel", pointerUp);
      window.removeEventListener("keydown", keyDown);
      window.removeEventListener("keyup", keyUp);
    },
  };
}
