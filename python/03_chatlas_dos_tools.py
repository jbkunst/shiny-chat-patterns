# Ejecuta primero todos los imports al iniciar una consola nueva.
import json
import re
from datetime import date, datetime, timedelta, timezone
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
    if not ciudad.strip():
        raise ValueError("Indica una ciudad.")
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", fecha):
        raise ValueError("Usa una fecha con formato AAAA-MM-DD.")
    dia = date.fromisoformat(fecha)
    hoy = datetime.now(timezone.utc).date()
    if not hoy <= dia <= hoy + timedelta(days=15):
        raise ValueError("La fecha debe estar entre hoy y los próximos 15 días, UTC.")

    parametros = urlencode({"name": ciudad.strip(), "count": 1, "language": "es"})
    with urlopen(f"https://geocoding-api.open-meteo.com/v1/search?{parametros}", timeout=20) as respuesta:
        lugares = json.load(respuesta)
    if not lugares.get("results"):
        raise ValueError("No encontré esa ciudad.")
    lugar = lugares["results"][0]

    parametros = urlencode({
        "latitude": lugar["latitude"], "longitude": lugar["longitude"],
        "daily": "temperature_2m_min,temperature_2m_max,precipitation_probability_max",
        "timezone": "UTC", "start_date": fecha, "end_date": fecha,
    })
    with urlopen(f"https://api.open-meteo.com/v1/forecast?{parametros}", timeout=20) as respuesta:
        pronostico = json.load(respuesta)

    return {
        "ciudad": lugar["name"], "region": lugar.get("admin1"), "pais": lugar.get("country"),
        "fecha": fecha, "pronostico": pronostico["daily"], "unidades": pronostico["daily_units"],
    }


def consultar_fecha_actual() -> dict:
    """Devuelve la fecha actual en UTC. Úsala para interpretar hoy, mañana o en N días."""
    return {"fecha": datetime.now(timezone.utc).date().isoformat(), "zona_horaria": "UTC"}


# prompt ------------------------------------------------------------------
fecha_ejemplo = (datetime.now(timezone.utc).date() + timedelta(days=1)).isoformat()
pregunta = "¿Lloverá en Madrid dentro de tres días? Indica también las temperaturas."

# chat --------------------------------------------------------------------
# Prueba primero la función sin el modelo:
pprint(consultar_pronostico("Madrid", fecha_ejemplo))

chat = ChatAuto(
    "openai/gpt-5-nano",
    system_prompt=(
        "Responde en español. "
        "Para fechas relativas, consulta primero consultar_fecha_actual y calcula la fecha. "
        "Después usa consultar_pronostico. No inventes datos meteorológicos. "
        "Si faltan tools, explica que no puedes obtener el pronóstico."
    ),
)

# Sin registrar las tools: todavía no puede consultar la fecha ni el pronóstico.
chat.chat(pregunta)

# Los type hints y el docstring describen los argumentos al modelo.
chat.register_tool(consultar_pronostico)
chat.register_tool(consultar_fecha_actual)

# Con ambas tools: consulta la fecha actual y luego el pronóstico.
chat.chat("Ahora usa las herramientas disponibles para responder. " + pregunta)
