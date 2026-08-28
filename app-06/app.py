import atexit
import json
import re
import tempfile
from pathlib import Path
from typing import Annotated, Literal

import duckdb
import matplotlib.pyplot as plt
import pandas as pd
from chatlas import ChatOpenAI, content_image_file
from faicons import icon_svg
from pydantic import Field

from shiny import App, Inputs, Outputs, Session, reactive, render, ui


# database ----------------------------------------------------------------
app_dir = Path(__file__).parent
repo_dir = app_dir.parent
paises = pd.read_csv(repo_dir / "data" / "paises.csv")

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


def dibujar_grafico(frame: pd.DataFrame, x: str, y: str, color: str = ""):
    figure, axis = plt.subplots()
    if color:
        for valor, grupo in frame.groupby(color, sort=False):
            axis.scatter(grupo[x], grupo[y], label=str(valor))
        axis.legend(title=color)
    else:
        axis.scatter(frame[x], frame[y], color="#0E4F5A")
    axis.set_xlabel(x)
    axis.set_ylabel(y)
    return figure


# prompt ------------------------------------------------------------------
saludo = (app_dir / "greeting.md").read_text(encoding="utf-8")
prompt_sistema = (app_dir / "prompt.md").read_text(encoding="utf-8")


# user interface ----------------------------------------------------------
app_ui = ui.page_sidebar(
    ui.sidebar(
        ui.chat_ui(
            "chat",
            messages=[saludo],
            placeholder="Filtra, muestra datos o crea un gráfico...",
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
    title=ui.tags.span(
        "App 06 · Tools de interfaz",
        ui.tags.small(" · ", ui.output_text("titulo", inline=True)),
    ),
    theme=ui.Theme.from_brand(repo_dir / "_brand.yml"),
)


# server ------------------------------------------------------------------
def server(input: Inputs, output: Outputs, session: Session):
    titulo_actual = reactive.value("Todos los países")
    consulta_actual = reactive.value("SELECT * FROM paises")
    tabla_modal = reactive.value(pd.DataFrame())
    grafico_modal = reactive.value(
        {"data": pd.DataFrame(), "x": "poblacion", "y": "esperanza_de_vida", "color": ""}
    )

    @reactive.calc
    def data():
        return con.execute(consulta_actual()).fetchdf()

    @render.text
    def titulo():
        return titulo_actual()

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

    @render.table
    def tabla_en_modal():
        return tabla_modal()

    @render.plot
    def grafico_en_modal():
        especificacion = grafico_modal()
        return dibujar_grafico(
            especificacion["data"],
            especificacion["x"],
            especificacion["y"],
            especificacion["color"],
        )

    # tools ---------------------------------------------------------------
    def consultar_paises(
        consulta: Annotated[
            str,
            Field(description="Consulta DuckDB SELECT sobre la tabla paises, sin punto y coma."),
        ],
    ) -> list[dict]:
        """Ejecuta una consulta SELECT de solo lectura sobre la tabla DuckDB paises."""
        resultado = con.execute(validar_select(consulta)).fetchdf()
        return json.loads(resultado.to_json(orient="records", force_ascii=False))

    async def actualizar_dashboard(
        consulta: Annotated[
            str,
            Field(description="SELECT * FROM paises con WHERE u ORDER BY, sin punto y coma."),
        ],
        titulo: Annotated[
            str,
            Field(description="Título breve que describe los datos mostrados."),
        ],
    ) -> dict:
        """Filtra, ordena o reinicia los datos reactivos mostrados en el dashboard."""
        consulta = validar_select(consulta)
        resultado = con.execute(consulta).fetchdf()
        if not set(paises.columns).issubset(resultado.columns):
            raise ValueError("La consulta debe devolver todas las columnas.")

        async with reactive.lock():
            consulta_actual.set(consulta)
            titulo_actual.set(titulo)
            await reactive.flush()

        return {"mensaje": "Dashboard actualizado.", "registros": len(resultado)}

    async def mostrar_tabla(
        n: Annotated[int, Field(description="Cantidad de filas, entre 1 y 100.")],
        titulo: Annotated[str, Field(description="Título breve del modal.")],
    ) -> list[dict]:
        """Abre en un modal una tabla con los datos visibles en el dashboard."""
        n = max(1, min(int(n), 100))
        with reactive.isolate():
            resultado = data().head(n)

        async with reactive.lock():
            tabla_modal.set(resultado)
            await reactive.flush()

        ui.modal_show(
            ui.modal(
                ui.output_table("tabla_en_modal"),
                title=titulo,
                size="l",
                easy_close=True,
                footer=ui.modal_button("Cerrar"),
            ),
            session=session,
        )
        return json.loads(resultado.to_json(orient="records", force_ascii=False))

    async def mostrar_grafico(
        x: Annotated[
            Literal["poblacion", "esperanza_de_vida", "pib_per_capita"],
            Field(description="Columna para el eje x."),
        ],
        y: Annotated[
            Literal["poblacion", "esperanza_de_vida", "pib_per_capita"],
            Field(description="Columna para el eje y."),
        ],
        color: Annotated[
            Literal["", "continente"],
            Field(description="Columna para el color, o ninguna."),
        ],
        titulo: Annotated[str, Field(description="Título breve del modal.")],
    ):
        """Abre en un modal un gráfico de puntos con los datos visibles en el dashboard."""
        with reactive.isolate():
            frame = data().copy()

        if frame.empty:
            raise ValueError("No hay datos para graficar.")

        async with reactive.lock():
            grafico_modal.set({"data": frame, "x": x, "y": y, "color": color})
            await reactive.flush()

        ui.modal_show(
            ui.modal(
                ui.output_plot("grafico_en_modal", height="500px"),
                title=titulo,
                size="l",
                easy_close=True,
                footer=ui.modal_button("Cerrar"),
            ),
            session=session,
        )

        figure = dibujar_grafico(frame, x, y, color)
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as archivo:
            ruta = Path(archivo.name)
        figure.savefig(ruta, dpi=100, bbox_inches="tight")
        plt.close(figure)
        try:
            return content_image_file(str(ruta), resize="none")
        finally:
            ruta.unlink(missing_ok=True)

    # chat ----------------------------------------------------------------
    chat = ui.Chat("chat")
    chat_client = ChatOpenAI(model="gpt-5-nano", system_prompt=prompt_sistema)
    chat_client.register_tool(consultar_paises)
    chat_client.register_tool(actualizar_dashboard)
    chat_client.register_tool(mostrar_tabla)
    chat_client.register_tool(mostrar_grafico)

    @chat.on_user_submit
    async def _(user_input: str):
        stream = await chat_client.stream_async(
            user_input,
            content="all",
            kwargs={"parallel_tool_calls": False},
        )
        await chat.append_message_stream(stream)


app = App(app_ui, server)
