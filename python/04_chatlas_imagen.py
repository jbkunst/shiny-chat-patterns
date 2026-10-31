import string
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

import matplotlib.pyplot as plt
import numpy as np
from chatlas import ChatOpenAI, content_image_file

# tools -------------------------------------------------------------------
def mostrar_puntos() -> object:
    """Genera y devuelve un gráfico aleatorio con puntos identificados por letras."""
    rng = np.random.default_rng()
    puntos = rng.normal(size=(12, 2))
    puntos[-1] = rng.uniform(4, 6, size=2)
    rng.shuffle(puntos)

    figura, eje = plt.subplots(figsize=(7, 5))
    eje.scatter(puntos[:, 0], puntos[:, 1], color="#0E4F5A")
    for nombre, (x, y) in zip(string.ascii_uppercase, puntos):
        eje.annotate(nombre, (x, y), xytext=(0, 8), textcoords="offset points", ha="center")
    eje.set(
        xlim=(puntos[:, 0].min() - 0.5, puntos[:, 0].max() + 0.5),
        ylim=(puntos[:, 1].min() - 0.5, puntos[:, 1].max() + 0.5),
        xlabel="X", ylabel="Y", title="¿Qué punto se separa del grupo?",
    )

    with TemporaryDirectory() as carpeta:
        archivo = Path(carpeta) / "puntos.png"
        figura.savefig(archivo, dpi=100)
        resultado = content_image_file(str(archivo), resize="none")

    if hasattr(sys, "ps1") or "IPython" in sys.modules:
        plt.show(block=False)
    else:
        plt.close(figura)
    return resultado


# prompt ------------------------------------------------------------------
pregunta = "Genera un gráfico e identifica el punto más separado del grupo. Explica por qué."

# chat --------------------------------------------------------------------
# Prueba la función y revisa el objeto de imagen sin llamar al modelo.
resultado = mostrar_puntos()
print(type(resultado))
print({"tipo": resultado.image_content_type, "imagen_base64": len(resultado.data)})

chat = ChatOpenAI(
    model="gpt-5-nano",
    system_prompt=(
        "Responde brevemente en español. Usa mostrar_puntos para observar el gráfico. "
        "Si no tienes la tool disponible, explica que no puedes observar los puntos."
    ),
)

chat.chat(pregunta)

chat.register_tool(mostrar_puntos)

chat.chat("Ahora usa la herramienta disponible. " + pregunta)
