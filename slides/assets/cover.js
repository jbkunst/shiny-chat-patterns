(() => {
  const cover = document.querySelector(".workshop-cover");
  const canvas = document.getElementById("workshop-canvas");
  if (!cover || !canvas) return;

  const context = canvas.getContext("2d");
  const action = document.getElementById("workshop-action");
  const sceneName = document.getElementById("workshop-scene");
  const toolName = document.getElementById("workshop-tool");
  const reducedMotion = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const revealRoot = document.querySelector(".reveal");
  const slides = revealRoot?.querySelector(":scope > .slides");

  if (revealRoot && slides) revealRoot.insertBefore(cover, slides);

  const scenes = [
    ["widgets", "inputs + outputs", "input → render", "widgets"],
    ["reactividad", "un dashboard", "reactive → plot", "widgets"],
    ["conversación", "chat", "user → model", "chat"],
    ["contexto", "una tool", "model → tool(data)", "tool"],
    ["consultas", "SQL seguro", "SELECT → rows", "tool"],
    ["acciones", "estado reactivo", "tool → reactive", "tool"],
    ["interfaz", "modales", "tool → ui", "tool"],
    ["exploración", "inputs vs chat", "filter ↔ query", "chat"],
    ["orquestación", "mapas + agentes", "agent → tool → ui", "agent"]
  ];
  const pointCount = 52;
  const points = Array.from({ length: pointCount }, (_, index) => ({
    seed: index / (pointCount - 1),
    phase: (index * 2.399) % (Math.PI * 2),
    noise: Math.sin(index * 17.17) * .5 + Math.cos(index * 7.31) * .5
  }));
  let width = 0;
  let height = 0;
  let pixelRatio = 1;

  const ease = (value) => value < .5
    ? 4 * value * value * value
    : 1 - Math.pow(-2 * value + 2, 3) / 2;

  function resize() {
    const bounds = canvas.getBoundingClientRect();
    pixelRatio = Math.min(devicePixelRatio || 1, 2);
    width = bounds.width;
    height = bounds.height;
    canvas.width = Math.round(width * pixelRatio);
    canvas.height = Math.round(height * pixelRatio);
    context.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
  }

  function position(point, scene, now) {
    const left = 30;
    const top = 38;
    const spanX = width - 60;
    const spanY = height - 86;
    const x = left + point.seed * spanX;

    if (scene === 0) {
      const wave = Math.sin(point.seed * 13 + now * .0005) * 38;
      return [x, top + spanY * (.68 - point.seed * .38) + wave];
    }

    if (scene === 1) {
      const wave = Math.sin(point.seed * 17) * 44;
      return [x, top + spanY * (.76 - point.seed * .5) + wave];
    }

    if (scene === 2) {
      const side = point.seed < .5 ? .28 : .72;
      const local = (point.seed * 2) % 1;
      return [
        left + spanX * side + Math.cos(point.phase) * (32 + local * 54),
        top + spanY * (.2 + local * .62) + Math.sin(point.phase) * 22
      ];
    }

    if (scene === 3) {
      const hub = point.seed < .66 ? [.48, .48] : [.8, .26];
      const radius = 42 + (point.seed % .18) * 300;
      return [
        left + spanX * hub[0] + Math.cos(point.phase) * radius,
        top + spanY * hub[1] + Math.sin(point.phase) * radius * .72
      ];
    }

    if (scene === 4) {
      const column = point.index % 7;
      const row = Math.floor(point.index / 7);
      return [left + 36 + column * (spanX - 72) / 6, top + 34 + row * 46];
    }

    if (scene === 5) {
      const group = Math.floor(point.seed * 3);
      const local = (point.seed * 3) % 1;
      const centerX = [.2, .5, .8][Math.min(group, 2)];
      return [
        left + spanX * centerX + Math.cos(point.phase) * (26 + local * 58),
        top + spanY * .5 + Math.sin(point.phase) * (38 + local * 86)
      ];
    }

    if (scene === 6) {
      const group = point.seed < .5 ? .28 : .72;
      const local = (point.seed * 2) % 1;
      return [
        left + spanX * group + Math.cos(point.phase) * 72,
        top + spanY * (.18 + local * .68) + Math.sin(point.phase) * 18
      ];
    }

    if (scene === 7) {
      const longitude = point.phase;
      const latitude = (point.seed - .5) * Math.PI;
      return [
        left + spanX * .55 + Math.cos(latitude) * Math.cos(longitude) * 178,
        top + spanY * .5 + Math.sin(latitude) * 168
      ];
    }

    const lane = point.index % 4;
    const step = Math.floor(point.index / 13);
    return [
      left + spanX * (.13 + step * .245) + Math.cos(point.phase) * 34,
      top + spanY * (.2 + lane * .2) + Math.sin(point.phase) * 16
    ];
  }

  function drawGrid() {
    context.strokeStyle = "rgba(169, 185, 210, .09)";
    context.lineWidth = 1;
    for (let x = 30; x < width - 20; x += 54) {
      context.beginPath();
      context.moveTo(x, 26);
      context.lineTo(x, height - 35);
      context.stroke();
    }
    for (let y = 38; y < height - 30; y += 52) {
      context.beginPath();
      context.moveTo(24, y);
      context.lineTo(width - 24, y);
      context.stroke();
    }
  }

  function drawConnections(positions, scene, opacity) {
    if (![3, 5, 6, 7, 8].includes(scene)) return;
    context.strokeStyle = `rgba(98, 168, 255, ${opacity * .24})`;
    context.lineWidth = 1;
    const stride = scene === 8 ? 13 : 7;
    positions.forEach((positionValue, index) => {
      const next = positions[(index + stride) % positions.length];
      context.beginPath();
      context.moveTo(positionValue[0], positionValue[1]);
      context.lineTo(next[0], next[1]);
      context.stroke();
    });
  }

  function render(now) {
    const duration = 4200;
    const total = scenes.length * duration;
    const timeline = reducedMotion ? 0 : now % total;
    const current = Math.floor(timeline / duration);
    const next = (current + 1) % scenes.length;
    const rawProgress = (timeline % duration) / duration;
    const mix = reducedMotion ? 0 : ease(Math.max(0, (rawProgress - .68) / .32));
    const currentPositions = points.map((point, index) => {
      point.index = index;
      return position(point, current, now);
    });
    const nextPositions = points.map((point) => position(point, next, now));
    const positions = currentPositions.map((value, index) => [
      value[0] + (nextPositions[index][0] - value[0]) * mix,
      value[1] + (nextPositions[index][1] - value[1]) * mix
    ]);

    context.clearRect(0, 0, width, height);
    drawGrid();
    drawConnections(positions, mix > .5 ? next : current, 1);

    positions.forEach(([x, y], index) => {
      const highlight = index % 9 === 0;
      context.beginPath();
      context.arc(x, y, highlight ? 4 : 2.2, 0, Math.PI * 2);
      context.fillStyle = highlight
        ? "rgba(203, 226, 255, 1)"
        : "rgba(98, 168, 255, .82)";
      context.fill();
    });

    const visibleScene = mix > .5 ? next : current;
    const visibleCopy = scenes[visibleScene];
    action.textContent = visibleCopy[0];
    sceneName.textContent = visibleCopy[1];
    toolName.textContent = visibleCopy[2];
    cover.dataset.phase = visibleCopy[3];

    if (!reducedMotion) requestAnimationFrame(render);
  }

  function updateVisibility() {
    const currentSlide = window.Reveal?.getCurrentSlide();
    cover.classList.toggle("is-hidden", currentSlide?.id !== "title-slide");
  }

  addEventListener("resize", resize, { passive: true });
  window.Reveal?.on("ready", updateVisibility);
  window.Reveal?.on("slidechanged", updateVisibility);
  resize();
  updateVisibility();
  requestAnimationFrame(render);
})();
