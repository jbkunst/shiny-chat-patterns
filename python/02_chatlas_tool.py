# Ejecuta primero todos los imports al iniciar una consola nueva.
import json
from datetime import datetime, timedelta, timezone
from pprint import pprint
from urllib.parse import urlencode
from urllib.request import urlopen

from chatlas import ChatAuto

# tools -------------------------------------------------------------------
def consultar_pronostico(ciudad: str, fecha: str) -> dict:
    """Consulta el pronóstico de un día. Usa la primera ciudad coincidente.

    Parameters
    ----------
    ciudad
        Nombre de una ciudad, por ejemplo Madrid o Tokio.
    fecha
        Fecha AAAA-MM-DD, entre hoy y hoy + 15 días, UTC.
    """
    parametros = urlencode({"name": ciudad.strip(), "count": 1, "language": "es"})
    with urlopen(f"https://geocoding-api.open-meteo.com/v1/search?{parametros}") as respuesta:
        lugares = json.load(respuesta)
    lugar = lugares["results"][0]

    parametros = urlencode({
        "latitude": lugar["latitude"], "longitude": lugar["longitude"],
        "daily": "temperature_2m_min,temperature_2m_max,precipitation_probability_max",
        "timezone": "UTC", "start_date": fecha, "end_date": fecha,
    })
    with urlopen(f"https://api.open-meteo.com/v1/forecast?{parametros}") as respuesta:
        pronostico = json.load(respuesta)

    return {
        "ciudad": lugar["name"], "region": lugar.get("admin1"), "pais": lugar.get("country"),
        "fecha": fecha, "pronostico": pronostico["daily"], "unidades": pronostico["daily_units"],
    }


# prompt ------------------------------------------------------------------
fecha_ejemplo = (datetime.now(timezone.utc).date() + timedelta(days=1)).isoformat()
pregunta = f"¿Lloverá en Madrid el {fecha_ejemplo}? Indica también las temperaturas."

# chat --------------------------------------------------------------------
# Prueba primero la función sin el modelo:
pprint(consultar_pronostico("Madrid", fecha_ejemplo))

chat = ChatAuto(
    "openai/gpt-5-nano",
    system_prompt=(
        "Responde en español. Usa consultar_pronostico; no inventes datos meteorológicos. "
        "Si no tienes una tool disponible para consultar el pronóstico, explica que no puedes obtenerlo."
    ),
)

# Sin registrar la tool: el modelo no puede consultar la API.
chat.chat(pregunta)

# Los type hints y el docstring describen los argumentos al modelo.
chat.register_tool(consultar_pronostico)

# Con la tool disponible: vuelve a pedir el pronóstico.
chat.chat("Ahora consulta el pronóstico con la herramienta disponible. " + pregunta)
