/*
 * Ajuste local para code_block() + Quarto/codefrag; se carga desde assets/cover.html.
 * Reveal crea y desplaza una copia del código por cada paso de resaltado. Tippy conserva
 * como referencia el marcador original: en pasos posteriores puede quedar fuera de vista.
 * Por eso usamos el marcador de la copia activa y actualizamos la posición con su scroll.
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
      const onShow = anchor._tippy.props.onShow;
      anchor._tippy.setProps({
        appendTo: anchor.closest("section"),
        placement: "top-end",
        maxWidth: 480,
        offset: [0, 12],
        zIndex: 100,
        getReferenceClientRect: () => visibleAnchor(anchor).getBoundingClientRect(),
        onShow(instance) {
          const marker = visibleAnchor(anchor);
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
                const slide = anchor.closest("section");
                const bounds = slide.getBoundingClientRect();
                const scale = bounds.width / slide.offsetWidth;
                const line = visibleAnchor(anchor).getBoundingClientRect();
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

    // Scroll events come from the active clone, rather than Tippy's original reference.
    document.querySelectorAll("pre.code-annotation-code code").forEach((code) => {
      code.addEventListener("scroll", () => {
        code.closest("pre").querySelectorAll(".code-annotation-anchor").forEach((anchor) => {
          if (anchor._tippy?.state.isVisible) anchor._tippy.popperInstance?.update();
        });
      }, { passive: true });
    });
  }

  // Quarto initializes Tippy in its DOMContentLoaded listener.
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => requestAnimationFrame(configureTooltips));
  } else {
    requestAnimationFrame(configureTooltips);
  }
})();
