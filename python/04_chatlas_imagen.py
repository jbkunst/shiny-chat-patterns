import string
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

import matplotlib.pyplot as plt
import numpy as np
from chatlas import ChatAuto, content_image_file
from chatlas.types import ContentText

# tools -------------------------------------------------------------------
def mostrar_puntos() -> list[object]:
    """Genera y devuelve un gráfico de puntos con un patrón aleatorio y letras."""
    rng = np.random.default_rng()
    x = rng.uniform(-3, 3, size=24)
    match rng.choice(["grupos", "tendencia", "curva", "aislado"]):
        case "grupos":
            y = np.repeat([-2, 2], 12) + rng.normal(scale=0.3, size=24)
        case "tendencia":
            y = rng.choice([-1, 1]) * x + rng.normal(scale=0.3, size=24)
        case "curva":
            y = x**2 + rng.normal(scale=0.3, size=24)
        case "aislado":
            y = np.r_[rng.normal(size=23), 6]
    puntos = np.column_stack([x, y])
    rng.shuffle(puntos)

    figura, eje = plt.subplots(figsize=(7, 5))
    eje.scatter(puntos[:, 0], puntos[:, 1], color="#0E4F5A")
    for nombre, (x, y) in zip(string.ascii_uppercase, puntos):
        eje.annotate(nombre, (x, y), xytext=(0, 8), textcoords="offset points", ha="center")
    eje.set(
        xlim=(puntos[:, 0].min() - 0.5, puntos[:, 0].max() + 0.5),
        ylim=(puntos[:, 1].min() - 0.5, puntos[:, 1].max() + 0.5),
        xlabel="X", ylabel="Y", title="¿Qué patrón ves?",
    )

    with TemporaryDirectory() as carpeta:
        archivo = Path(carpeta) / "puntos.png"
        figura.savefig(archivo, dpi=100)
        resultado = content_image_file(str(archivo), resize="none")

    if hasattr(sys, "ps1") or "IPython" in sys.modules:
        plt.show(block=False)
    else:
        plt.close(figura)
    return [ContentText(text="Gráfico generado. Analiza la imagen adjunta y responde."), resultado]


# prompt ------------------------------------------------------------------
pregunta = "Genera un gráfico y describe lo que ves. Identifica patrones y puntos que llamen la atención."

# chat --------------------------------------------------------------------
# Prueba la función y revisa el objeto de imagen sin llamar al modelo.
resultado = mostrar_puntos()
print([type(contenido).__name__ for contenido in resultado])
print({"tipo": resultado[1].image_content_type, "imagen_base64": len(resultado[1].data)})

chat = ChatAuto(
    "openai/gpt-5.6-luna",
    system_prompt=(
        "No describas ningún gráfico sin recibir su imagen mediante mostrar_puntos. "
        "Cada petición de un gráfico nuevo requiere una nueva llamada a mostrar_puntos. "
        "Tras recibir la imagen, descríbela y responde sin llamar otra vez a la tool para esa petición. "
        "Responde brevemente en español; si no tienes la tool, di que no puedes observar el gráfico."
    ),
)

chat.chat(pregunta)

chat.register_tool(mostrar_puntos)

chat.chat("Ahora usa la herramienta disponible. " + pregunta)

chat.chat("Genera otro gráfico y describe lo que ves.")
