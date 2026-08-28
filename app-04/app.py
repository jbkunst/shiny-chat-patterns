import atexit
import json
import re
from pathlib import Path
from typing import Annotated

import duckdb
import matplotlib.pyplot as plt
import pandas as pd
from chatlas import ChatOpenAI
from faicons import icon_svg
from pydantic import Field

from shiny import App, Inputs, Outputs, Session, reactive, render, ui


# database ----------------------------------------------------------------
app_dir = Path(__file__).parent
repo_dir = app_dir.parent
paises = pd.read_csv(repo_dir / "data" / "paises.csv")
continentes = ["Todos", *sorted(paises["continente"].unique())]

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


# prompt ------------------------------------------------------------------
saludo = (app_dir / "greeting.md").read_text(encoding="utf-8")
prompt_sistema = (app_dir / "prompt.md").read_text(encoding="utf-8")


# user interface ----------------------------------------------------------
app_ui = ui.page_sidebar(
    ui.sidebar(
        ui.input_select("continente", "Continente", choices=continentes),
        ui.chat_ui(
            "chat",
            messages=[saludo],
            placeholder="Pregunta por los datos...",
        ),
        width=400,
    ),
    ui.layout_columns(
        ui.value_box(
            "Países",
            ui.output_text("n_filas"),
            showcase=icon_svg("earth-americas"),
            theme="text-primary",
        ),
        ui.value_box(
            "Esperanza de vida",
            ui.output_text("vida"),
            showcase=icon_svg("heart-pulse"),
            theme="text-primary",
        ),
        ui.value_box(
            "Población",
            ui.output_text("poblacion"),
            showcase=icon_svg("people-group"),
            theme="text-primary",
        ),
        ui.card(ui.output_plot("plot")),
        ui.card(ui.output_table("table")),
        col_widths=(4, 4, 4, 6, 6),
        row_heights=(1, 3),
    ),
    fillable=True,
    title="App 04 · Tool SQL",
    theme=ui.Theme.from_brand(repo_dir / "_brand.yml"),
)


# server ------------------------------------------------------------------
def server(input: Inputs, output: Outputs, session: Session):
    @reactive.calc
    def data():
        if input.continente() == "Todos":
            return paises
        return paises[paises["continente"] == input.continente()]

    @render.text
    def n_filas():
        return str(len(data()))

    @render.text
    def vida():
        return f"{data()['esperanza_de_vida'].mean():.1f} años"

    @render.text
    def poblacion():
        return f"{data()['poblacion'].sum() / 1e6:.0f} millones"

    @render.plot
    def plot():
        figure, axis = plt.subplots()
        axis.scatter(paises["pib_per_capita"], paises["esperanza_de_vida"], color="#d2d2d2")
        axis.scatter(
            data()["pib_per_capita"],
            data()["esperanza_de_vida"],
            color="#0E4F5A",
            s=45,
        )
        axis.set_xscale("log")
        axis.set_xlabel("pib_per_capita")
        axis.set_ylabel("esperanza_de_vida")
        return figure

    @render.table
    def table():
        return data()

    # tool ----------------------------------------------------------------
    def consultar_paises(
        consulta: Annotated[
            str,
            Field(description="Consulta DuckDB SELECT sobre la tabla paises, sin punto y coma."),
        ],
    ) -> list[dict]:
        """Ejecuta una consulta SELECT de solo lectura sobre la tabla DuckDB paises."""
        resultado = con.execute(validar_select(consulta)).fetchdf()
        return json.loads(resultado.to_json(orient="records", force_ascii=False))

    # chat ----------------------------------------------------------------
    chat = ui.Chat("chat")
    chat_client = ChatOpenAI(model="gpt-5-nano", system_prompt=prompt_sistema)
    chat_client.register_tool(consultar_paises)

    @chat.on_user_submit
    async def _(user_input: str):
        stream = await chat_client.stream_async(user_input, content="all")
        await chat.append_message_stream(stream)


app = App(app_ui, server)
