/*
 * Resaltado de code_block() con una sola copia del archivo en el DOM.
 * codefrag conserva los avances y las anotaciones; este script cambia las líneas resaltadas
 * y desplaza el bloque existente. Los rangos originales vienen de data-workshop-highlights.
 * single_copy = FALSE en el helper permite volver al resaltado estándar de Quarto.
 */
(() => {
  const blocks = new WeakMap();
  const reducedMotion = matchMedia("(prefers-reduced-motion: reduce)");

  function orderAnnotations(deck) {
    document.querySelectorAll(".reveal .slides section.slide").forEach((slide) => {
      const groups = new Map();
      slide.querySelectorAll(".code-annotation-fragment").forEach((fragment) => {
        const cell = fragment.dataset.targetCell;
        const source = document.getElementById(cell);
        if (!source?.dataset.workshopHighlights || source.dataset.codeAnnotationFragmentIndices) return;
        if (!groups.has(cell)) groups.set(cell, []);
        groups.get(cell).push(fragment);
      });

      let changed = false;
      groups.forEach((fragments) => {
        // Keep this block's slots relative to other slide fragments, but follow the marker numbers.
        const indices = fragments.map((fragment) => Number(fragment.dataset.fragmentIndex));
        if (!indices.every(Number.isFinite)) return;
        indices.sort((a, b) => a - b);
        fragments.sort((a, b) => Number(a.dataset.targetAnnotation) - Number(b.dataset.targetAnnotation));
        fragments.forEach((fragment, index) => {
          if (Number(fragment.dataset.fragmentIndex) === indices[index]) return;
          fragment.dataset.fragmentIndex = String(indices[index]);
          changed = true;
        });
      });
      if (changed) deck.syncFragments(slide);
    });
  }

  function getBlock(pre) {
    if (blocks.has(pre)) return blocks.get(pre);
    const source = pre.closest("div.sourceCode");
    const spec = source?.dataset.workshopHighlights || pre.dataset.workshopHighlights;
    if (!spec) return null;
    const code = pre.querySelector("code");
    const lines = Array.from(code.children).filter((line) => line.tagName === "SPAN");
    const steps = spec.split("|").map((range) => {
      const [first, last = first] = range.split("-").map(Number);
      return lines.slice(first - 1, last);
    });
    const block = { code, cell: source.id, steps, index: -1, selected: [] };
    blocks.set(pre, block);
    pre.classList.add("code-wrapper");
    return block;
  }

  function highlight(block, index, animate, force = false) {
    if (block.index === index && !force) return;
    block.selected.forEach((line) => line.classList.remove("highlight-line"));
    block.index = index;
    block.selected = block.steps[index] || [];
    block.selected.forEach((line) => line.classList.add("highlight-line"));
    block.code.classList.toggle("has-line-highlights", block.selected.length > 0);

    let top = 0;
    if (block.selected.length) {
      const first = block.selected[0];
      const last = block.selected.at(-1);
      const style = getComputedStyle(block.code);
      const padding = parseFloat(style.paddingTop) + parseFloat(style.paddingBottom);
      const viewport = block.code.clientHeight - padding;
      const height = last.offsetTop + last.offsetHeight - first.offsetTop;
      top = first.offsetTop + (Math.min(height, viewport) - viewport) / 2;
    }
    top = Math.max(0, Math.min(top, block.code.scrollHeight - block.code.clientHeight));
    block.code.scrollTo({ top, behavior: animate && !reducedMotion.matches ? "smooth" : "auto" });
  }

  function updateSlide(slide, animate = false, force = false) {
    if (!slide) return;
    const current = Array.from(slide.querySelectorAll(".code-annotation-fragment.current-fragment"));
    slide.querySelectorAll("pre.workshop-code").forEach((pre) => {
      const block = getBlock(pre);
      if (!block) return;
      const step = current.find((fragment) => fragment.dataset.targetCell === block.cell);
      highlight(block, step ? Number(step.dataset.targetAnnotation) - 1 : -1, animate, force);
    });
  }

  function connectReveal() {
    if (!window.Reveal) {
      requestAnimationFrame(connectReveal);
      return;
    }
    const deck = window.Reveal;
    const update = () => updateSlide(deck.getCurrentSlide(), true);
    const ready = () => {
      orderAnnotations(deck);
      updateSlide(deck.getCurrentSlide());
    };
    deck.on("ready", ready);
    deck.on("fragmentshown", update);
    deck.on("fragmenthidden", update);
    deck.on("slidechanged", () => updateSlide(deck.getCurrentSlide(), false, true));
    deck.on("resize", () => updateSlide(deck.getCurrentSlide(), false, true));
    deck.on("pdf-ready", () => {
      // codefrag creates print pages first; each page has its own current annotation.
      document.querySelectorAll(".reveal .slides section.slide").forEach((slide) => {
        updateSlide(slide, false, true);
      });
    });

    // A direct click on a numbered marker follows the same step as keyboard navigation.
    document.addEventListener("workshop-annotation", (event) => {
      const anchor = event.target;
      const pre = anchor.closest("pre");
      const block = pre && getBlock(pre);
      if (!block) return;
      const slide = anchor.closest("section");
      const fragment = Array.from(slide.querySelectorAll(".code-annotation-fragment")).find((step) =>
        step.dataset.targetCell === block.cell &&
        step.dataset.targetAnnotation === anchor.dataset.targetAnnotation
      );
      if (fragment && !fragment.classList.contains("current-fragment") && !deck.isPrintView()) {
        const { h, v } = deck.getIndices(slide);
        deck.slide(h, v, Number(fragment.dataset.fragmentIndex));
      }
      highlight(block, Number(anchor.dataset.targetAnnotation) - 1, false);
    });
    if (deck.isReady()) ready();
  }

  connectReveal();
})();
