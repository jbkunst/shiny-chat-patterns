import sys
from typing import Annotated

import pandas as pd
from chatlas import ChatAuto
from pydantic import Field

# data --------------------------------------------------------------------
paises = pd.read_csv("data/paises.csv")
continentes = paises["continente"].unique().tolist()

# tool --------------------------------------------------------------------
def resumir_continente(
    continente: Annotated[str, Field(
        description="Continente que se quiere resumir.", json_schema_extra={"enum": continentes},
    )],
) -> dict:
    """Resume un continente usando los datos reales de Gapminder."""
    coincidencias = [nombre for nombre in continentes if nombre.lower() == continente.lower()]
    if not coincidencias:
        raise ValueError("Continente no disponible.")
    continente = coincidencias[0]
    frame = paises[paises["continente"] == continente]
    return {
        "continente": continente,
        "registros": len(frame),
        "poblacion_total": int(frame["poblacion"].sum()),
        "esperanza_promedio": round(frame["esperanza_de_vida"].mean(), 1),
        "pib_promedio": round(frame["pib_per_capita"].mean()),
    }


# chat --------------------------------------------------------------------
chat = ChatAuto(
    "openai/gpt-5-nano",
    system_prompt=(
        "Responde brevemente en español. "
        "Usa resumir_continente para toda pregunta sobre los datos y no inventes resultados."
    ),
)

chat.register_tool(resumir_continente)

if hasattr(sys, "ps1") or sys.stdin.isatty():
    chat.console()
