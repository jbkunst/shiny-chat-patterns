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
    ["widgets", "inputs + outputs", "input → render"],
    ["reactividad", "un dashboard", "data → plot"],
    ["conversación", "chat + ellmer", "user → model → app"]
  ];
  const points = Array.from({ length: 52 }, (_, index) => ({
    seed: index / 51,
    phase: (index * 2.399) % (Math.PI * 2)
  }));

  let width = 0;
  let height = 0;
  let active = false;
  let frame = null;

  const ease = (value) => value < .5
    ? 4 * value * value * value
    : 1 - Math.pow(-2 * value + 2, 3) / 2;

  function resize() {
    const bounds = canvas.getBoundingClientRect();
    const pixelRatio = Math.min(devicePixelRatio || 1, 2);
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

    const side = point.seed < .5 ? .3 : .7;
    const local = (point.seed * 2) % 1;
    return [
      left + spanX * side + Math.cos(point.phase) * (28 + local * 52),
      top + spanY * (.2 + local * .62) + Math.sin(point.phase) * 20
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

  function draw(now = 0) {
    const duration = 4800;
    const timeline = reducedMotion ? 0 : now % (scenes.length * duration);
    const current = Math.floor(timeline / duration);
    const next = (current + 1) % scenes.length;
    const progress = (timeline % duration) / duration;
    const mix = reducedMotion ? 0 : ease(Math.max(0, (progress - .68) / .32));
    const positions = points.map((point) => {
      const start = position(point, current, now);
      const end = position(point, next, now);
      return [
        start[0] + (end[0] - start[0]) * mix,
        start[1] + (end[1] - start[1]) * mix
      ];
    });

    context.clearRect(0, 0, width, height);
    drawGrid();

    positions.forEach(([x, y], index) => {
      context.beginPath();
      context.arc(x, y, index % 9 === 0 ? 4 : 2.2, 0, Math.PI * 2);
      context.fillStyle = index % 9 === 0
        ? "rgba(203, 226, 255, 1)"
        : "rgba(98, 168, 255, .82)";
      context.fill();
    });

    const visible = scenes[mix > .5 ? next : current];
    action.textContent = visible[0];
    sceneName.textContent = visible[1];
    toolName.textContent = visible[2];

    if (active && !reducedMotion) frame = requestAnimationFrame(draw);
  }

  function updateVisibility() {
    const currentSlide = window.Reveal?.getCurrentSlide();
    active = currentSlide?.id === "title-slide";
    cover.classList.toggle("is-visible", active);

    if (active) {
      resize();
      if (frame === null) frame = requestAnimationFrame(draw);
    } else if (frame !== null) {
      cancelAnimationFrame(frame);
      frame = null;
    }
  }

  function connectReveal() {
    if (!window.Reveal) {
      requestAnimationFrame(connectReveal);
      return;
    }

    window.Reveal.on("ready", updateVisibility);
    window.Reveal.on("slidechanged", updateVisibility);
    updateVisibility();
  }

  addEventListener("resize", () => {
    if (active) resize();
  }, { passive: true });

  connectReveal();
})();
