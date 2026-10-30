/*
 * Ajuste local para code_block() + Quarto/codefrag; se carga desde assets/cover.html.
 * code-highlights.js conserva una sola copia del código. También admitimos el motor anterior,
 * que crea una copia por paso: en ese caso la referencia debe seguir el marcador de la copia activa.
 * El tooltip se monta en la slide para evitar el recorte del código; z-index por sí solo
 * no evita ese recorte. La posición superior no usa flip y se calcula en coordenadas de
 * la slide para compensar tanto CSS zoom como transform: scale(). Su apariencia vive en slides.css.
 * Al actualizar Quarto/codefrag, comprobar estos selectores y la API _tippy: son detalles internos.
 * Revisar pasos iniciales/finales, regreso a una slide y dos tamaños de ventana (ver ../README.md).
 */
(() => {
  // Reveal scrolls a separate code clone for each highlight step.
  function visibleAnchor(anchor) {
    const pre = anchor.closest("pre");
    const code = pre.querySelector("code.current-fragment") || pre.querySelector("code:not(.fragment)");
    return code.querySelector(
      `.code-annotation-anchor[data-target-annotation="${anchor.dataset.targetAnnotation}"]`
    ) || anchor;
  }

  function configureTooltips() {
    document.querySelectorAll(".code-annotation-anchor").forEach((anchor) => {
      if (!anchor._tippy) return;
      const pre = anchor.closest("pre");
      const slide = anchor.closest("section");
      const singleCopy = pre.dataset.workshopHighlights ||
        pre.closest("div.sourceCode")?.dataset.workshopHighlights;
      const reference = () => singleCopy ? anchor : visibleAnchor(anchor);
      const onShow = anchor._tippy.props.onShow;
      anchor._tippy.setProps({
        appendTo: slide,
        placement: "top-end",
        maxWidth: 480,
        offset: [0, 12],
        zIndex: 100,
        getReferenceClientRect: () => reference().getBoundingClientRect(),
        onShow(instance) {
          anchor.dispatchEvent(new CustomEvent("workshop-annotation", { bubbles: true }));
          if (singleCopy) {
            // The range is already highlighted. Quarto's extra gutter overlay causes horizontal overflow.
            window.tippy.hideAll();
            anchor.classList.add("code-annotation-active");
            return;
          }
          const marker = reference();
          const code = marker.closest("code");
          const bounds = code.getBoundingClientRect();
          const line = marker.getBoundingClientRect();
          // Restore an offscreen annotation when revisiting a slide or resizing.
          if (line.top < bounds.top || line.bottom > bounds.bottom) {
            const scale = bounds.height / code.offsetHeight;
            code.scrollTop += (line.top - bounds.top) / scale - code.clientHeight / 2;
          }
          return onShow(instance);
        },
        popperOptions: {
          modifiers: [
            { name: "flip", enabled: false },
            { name: "preventOverflow", enabled: false },
            {
              name: "slidePosition",
              enabled: true,
              phase: "beforeWrite",
              requires: ["computeStyles"],
              fn({ state }) {
                const bounds = slide.getBoundingClientRect();
                const scale = bounds.width / slide.offsetWidth;
                const line = reference().getBoundingClientRect();
                const width = state.elements.popper.offsetWidth;
                const height = state.elements.popper.offsetHeight;
                const left = Math.max(16, Math.min(
                  (line.right - bounds.left) / scale - width,
                  slide.offsetWidth - width - 16
                ));
                // Use slide coordinates: Reveal can scale with CSS zoom as well as transforms.
                Object.assign(state.styles.popper, {
                  left: `${left}px`,
                  top: `${(line.top - bounds.top) / scale - height - 12}px`,
                  right: "auto",
                  bottom: "auto",
                  transform: "none"
                });
              }
            }
          ]
        }
      });
    });

    // Popper follows scroll natively for a single copy. Legacy clones need explicit updates.
    document.querySelectorAll("pre.code-annotation-code").forEach((pre) => {
      if (pre.dataset.workshopHighlights || pre.closest("div.sourceCode")?.dataset.workshopHighlights) return;
      const anchors = Array.from(pre.querySelectorAll(".code-annotation-anchor"));
      let frame = null;
      const update = () => {
        if (frame !== null) return;
        frame = requestAnimationFrame(() => {
          frame = null;
          anchors.forEach((anchor) => {
            if (anchor._tippy?.state.isVisible) anchor._tippy.popperInstance?.update();
          });
        });
      };
      pre.querySelectorAll("code").forEach((code) => {
        code.addEventListener("scroll", update, { passive: true });
      });
    });
  }

  // Quarto initializes Tippy in its DOMContentLoaded listener.
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => requestAnimationFrame(configureTooltips));
  } else {
    requestAnimationFrame(configureTooltips);
  }
})();
