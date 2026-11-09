from chatlas import ChatAuto

chat = ChatAuto(
    "openai/gpt-5-nano",
    system_prompt=(
        "Responde brevemente en español sobre los países de Gapminder en su último año. "
        "No inventes resultados numéricos."
    ),
)

chat.console()
