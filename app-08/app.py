import atexit
import json
import re
from pathlib import Path
from typing import Annotated, Literal

import duckdb
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import plotly.express as px
from chatlas import ChatOpenAI
from faicons import icon_svg
from pydantic import Field
from shinywidgets import output_widget, render_plotly

from shiny import App, Inputs, Outputs, Session, reactive, render, ui


# database ----------------------------------------------------------------
app_dir = Path(__file__).resolve().parent
repo_dir = app_dir.parent
paises = pd.read_csv(repo_dir / "data" / "paises.csv")

catalogo = px.data.gapminder(centroids=True, year=2007).reset_index(drop=True)
datos_coinciden = (
    len(catalogo) == len(paises)
    and np.allclose(paises["esperanza_de_vida"], catalogo["lifeExp"])
    and np.array_equal(paises["poblacion"], catalogo["pop"])
    and np.allclose(paises["pib_per_capita"], catalogo["gdpPercap"])
)
if not datos_coinciden:
    raise ValueError("paises.csv no coincide con el catálogo Gapminder incluido en Plotly.")
paises["codigo"] = catalogo["iso_alpha"].to_numpy()
centros = catalogo.set_index("iso_alpha")[["centroid_lat", "centroid_lon"]]

rangos_mapa = {
    "esperanza_de_vida": tuple(paises["esperanza_de_vida"].agg(["min", "max"])),
    "poblacion": tuple(np.log10(paises["poblacion"]).agg(["min", "max"])),
    "pib_per_capita": tuple(np.log10(paises["pib_per_capita"]).agg(["min", "max"])),
}

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
        ui.chat_ui(
            "chat",
            messages=[saludo],
            placeholder="Filtra o controla el mapa...",
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
        ui.card(output_widget("map", height="500px")),
        col_widths=(4, 4, 4, 6, 6),
        row_heights=(1, 3),
    ),
    title=ui.tags.span(
        "App 08 · Tool + mapa",
        ui.tags.small(" · ", ui.output_text("titulo", inline=True)),
    ),
    fillable=True,
    theme=ui.Theme.from_brand(repo_dir / "_brand.yml"),
)


# server ------------------------------------------------------------------
def server(input: Inputs, output: Outputs, session: Session):
    titulo_actual = reactive.value("Todos los países")
    consulta_actual = reactive.value("SELECT * FROM paises")
    variable_mapa = reactive.value("esperanza_de_vida")
    camara_mapa = reactive.value({"latitud": 15.0, "longitud": 0.0, "zoom": 1.0})

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

    @render_plotly
    def map():
        frame = data().copy()
        variable = variable_mapa()
        if variable in ("poblacion", "pib_per_capita"):
            frame["valor_mapa"] = np.log10(frame[variable])
        else:
            frame["valor_mapa"] = frame[variable]

        figura = px.choropleth(
            frame,
            locations="codigo",
            color="valor_mapa",
            hover_name="pais",
            color_continuous_scale=["#dcebea", "#0E4F5A"],
            range_color=rangos_mapa[variable],
        )
        with reactive.isolate():
            camara = camara_mapa()
        figura.update_geos(
            projection_type="orthographic",
            projection_scale=camara["zoom"],
            center={"lat": camara["latitud"], "lon": camara["longitud"]},
            showframe=False,
            showcoastlines=True,
        )
        figura.update_layout(
            margin={"l": 0, "r": 0, "t": 0, "b": 0},
            coloraxis_colorbar={"title": variable},
        )
        return figura

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
        """Filtra, ordena o reinicia los datos mostrados en el dashboard y el mapa."""
        consulta = validar_select(consulta)
        resultado = con.execute(consulta).fetchdf()
        if not set(paises.columns).issubset(resultado.columns):
            raise ValueError("La consulta debe devolver todas las columnas.")

        async with reactive.lock():
            consulta_actual.set(consulta)
            titulo_actual.set(titulo)
            await reactive.flush()

        return {
            "mensaje": "Dashboard y mapa actualizados.",
            "registros": len(resultado),
            "esperanza_promedio": round(resultado["esperanza_de_vida"].mean(), 1),
            "poblacion_total": int(resultado["poblacion"].sum()),
            "pib_promedio": round(resultado["pib_per_capita"].mean()),
        }

    async def cambiar_variable(
        variable: Annotated[
            Literal["esperanza_de_vida", "poblacion", "pib_per_capita"],
            Field(description="Variable con la que se colorea el mapa."),
        ],
    ) -> str:
        """Cambia la variable utilizada para colorear los países del mapa."""
        async with reactive.lock():
            variable_mapa.set(variable)
            await reactive.flush()
        return f"Mapa coloreado por {variable}"

    async def ir_a_pais(
        pais: Annotated[str, Field(description="Nombre del país en español.")],
        zoom: Annotated[float, Field(description="Nivel de zoom, normalmente entre 1 y 6.")] = 4,
    ) -> str:
        """Mueve la cámara del mapa hacia un país mediante el widget existente."""
        ubicacion = con.execute(
            "SELECT DISTINCT pais, codigo FROM paises WHERE lower(pais) = lower(?)",
            [pais],
        ).fetchone()
        if not ubicacion:
            raise ValueError("No encontré ese país.")

        nombre, codigo = ubicacion
        if codigo not in centros.index:
            raise ValueError("No encontré las coordenadas de ese país.")
        centro = centros.loc[codigo]
        camara = {
            "latitud": float(centro["centroid_lat"]),
            "longitud": float(centro["centroid_lon"]),
            "zoom": max(1.0, min(float(zoom), 6.0)),
        }

        async with reactive.lock():
            camara_mapa.set(camara)

        # Proxy: modifica el FigureWidget ya renderizado, sin ejecutar map() otra vez.
        map.widget.update_geos(
            center={"lat": camara["latitud"], "lon": camara["longitud"]},
            projection_scale=camara["zoom"],
        )
        return f"Mapa centrado en {nombre}"

    # chat ----------------------------------------------------------------
    chat = ui.Chat("chat")
    chat_client = ChatOpenAI(model="gpt-5-nano", system_prompt=prompt_sistema)
    chat_client.register_tool(consultar_paises)
    chat_client.register_tool(actualizar_dashboard)
    chat_client.register_tool(cambiar_variable)
    chat_client.register_tool(ir_a_pais)

    @chat.on_user_submit
    async def _(user_input: str):
        stream = await chat_client.stream_async(
            user_input,
            content="all",
            kwargs={"parallel_tool_calls": False},
        )
        await chat.append_message_stream(stream)


app = App(app_ui, server)
