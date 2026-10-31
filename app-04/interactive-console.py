import atexit
import re
import sys
from pathlib import Path
from typing import Annotated

import duckdb
import pandas as pd
from chatlas import ChatOpenAI
from pydantic import Field

# database ----------------------------------------------------------------
paises = pd.read_csv("data/paises.csv")
con = duckdb.connect(":memory:")
con.register("paises_origen", paises)
con.execute("CREATE TABLE paises AS SELECT * FROM paises_origen")
con.unregister("paises_origen")
con.execute("SET enable_external_access = false")
atexit.register(con.close)


def validar_select(consulta: str) -> str:
    consulta = consulta.strip()
    if not re.match(r"^SELECT\b", consulta, flags=re.IGNORECASE):
        raise ValueError("Solo se permiten consultas SELECT.")
    if not re.search(r"\bpaises\b", consulta, flags=re.IGNORECASE):
        raise ValueError("La consulta debe usar paises.")
    if ";" in consulta:
        raise ValueError("Envía una sola consulta y no incluyas punto y coma.")
    return consulta


# tool --------------------------------------------------------------------
def consultar_paises(
    consulta: Annotated[str, Field(description="Consulta DuckDB SELECT sobre paises, sin punto y coma.")],
) -> list[dict]:
    """Ejecuta una consulta SELECT de solo lectura sobre la tabla DuckDB paises."""
    return con.execute(validar_select(consulta)).fetchdf().to_dict(orient="records")


# chat --------------------------------------------------------------------
prompt_sistema = Path("app-04/prompt.md").read_text(encoding="utf-8")
chat = ChatOpenAI(model="gpt-5-nano", system_prompt=prompt_sistema)

chat.register_tool(consultar_paises)

if hasattr(sys, "ps1") or sys.stdin.isatty():
    try:
        chat.console()
    finally:
        con.close()
