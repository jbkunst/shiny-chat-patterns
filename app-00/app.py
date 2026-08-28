from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from statsmodels.tsa.holtwinters import ExponentialSmoothing

from shiny import App, Inputs, Outputs, Session, render, ui


# data --------------------------------------------------------------------
repo_dir = Path(__file__).parent.parent
pasajeros = pd.read_csv(repo_dir / "data" / "air-passengers.csv", parse_dates=["fecha"])


# user interface ----------------------------------------------------------
app_ui = ui.page_sidebar(
    ui.sidebar(
        ui.input_text("title", "Título", value="Pasajeros aéreos"),
        ui.input_slider("n", "Cantidad de puntos", min=24, max=144, value=48, step=24),
        ui.input_checkbox("forecast", "Mostrar pronóstico", value=False),
    ),
    ui.h2(ui.output_text("plot_title")),
    ui.output_plot("plot"),
    fillable=True,
    title="App 00 · Widgets y outputs",
    theme=ui.Theme.from_brand(repo_dir / "_brand.yml"),
)


# server ------------------------------------------------------------------
def server(input: Inputs, output: Outputs, session: Session):
    @render.text
    def plot_title():
        return input.title()

    @render.plot
    def plot():
        frame = pasajeros.head(input.n())
        figure, axis = plt.subplots()
        axis.plot(frame["fecha"], frame["pasajeros"], color="#0E4F5A", linewidth=2)

        if input.forecast():
            model = ExponentialSmoothing(
                frame["pasajeros"],
                trend="add",
                seasonal="mul",
                seasonal_periods=12,
            ).fit()
            fechas = pd.date_range(frame["fecha"].iloc[-1], periods=25, freq="MS")[1:]
            axis.plot(fechas, model.forecast(24), color="#A56A18", linewidth=2)

        axis.set_xlabel("")
        axis.set_ylabel("Pasajeros (miles)")
        return figure


app = App(app_ui, server)
