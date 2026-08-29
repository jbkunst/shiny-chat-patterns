from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from chatlas import ChatOpenAI
from faicons import icon_svg

from shiny import App, Inputs, Outputs, Session, reactive, render, ui


# data --------------------------------------------------------------------
repo_dir = Path(__file__).resolve().parent.parent
paises = pd.read_csv(repo_dir / "data" / "paises.csv")
continentes = ["Todos", *sorted(paises["continente"].unique())]


# prompt ------------------------------------------------------------------
saludo = (
    "Prueba con:\n\n- **¿Cuántos países se muestran?**\n"
    "- **¿Cuál es su esperanza de vida promedio?**"
)


# user interface ----------------------------------------------------------
app_ui = ui.page_sidebar(
    ui.sidebar(
        ui.input_select("continente", "Continente", choices=continentes),
        ui.chat_ui(
            "chat",
            messages=[saludo],
            placeholder="Pregunta sobre los datos visibles...",
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
    title="App 03 · Tool con contexto",
    fillable=True,
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
    def resumir_datos_visibles() -> dict:
        """Resume los países que están visibles en el dashboard."""
        with reactive.isolate():
            frame = data()
            continente = input.continente()

        return {
            "continente": continente,
            "registros": len(frame),
            "poblacion_total": int(frame["poblacion"].sum()),
            "esperanza_promedio": round(frame["esperanza_de_vida"].mean(), 1),
            "pib_promedio": round(frame["pib_per_capita"].mean()),
        }

    # chat ----------------------------------------------------------------
    chat = ui.Chat("chat")
    chat_client = ChatOpenAI(
        model="gpt-5-nano",
        system_prompt=(
            "Responde brevemente en español. Usa resumir_datos_visibles para responder "
            "sobre el dashboard y no inventes resultados."
        ),
    )
    chat_client.register_tool(resumir_datos_visibles)

    @chat.on_user_submit
    async def _(user_input: str):
        stream = await chat_client.stream_async(user_input, content="all")
        await chat.append_message_stream(stream)


app = App(app_ui, server)
