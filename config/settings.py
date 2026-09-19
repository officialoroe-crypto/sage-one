import os
from pathlib import Path

from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parent.parent

ENV_FILE = Path("C:/SageOne/Backend/.env")
load_dotenv(ENV_FILE)


class Settings:
    APP_NAME = "SAGE ONE"
    ENVIRONMENT = os.getenv("SAGE_ENV", "development")

    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    GROQ_API_KEY = os.getenv("GROQ_API_KEY")
    OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
    CEREBRAS_API_KEY = os.getenv("CEREBRAS_API_KEY")
    GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")

    MODEL = os.getenv(
        "SAGE_MODEL",
        "gemini-3.6-flash",
    )

    GROQ_MODEL = os.getenv(
        "SAGE_GROQ_MODEL",
        "openai/gpt-oss-20b",
    )

    CEREBRAS_MODEL = os.getenv(
        "CEREBRAS_MODEL",
        "gpt-oss-120b",
    )

    OLLAMA_BASE_URL = os.getenv(
        "OLLAMA_BASE_URL",
        "http://127.0.0.1:11434/v1",
    )

    OLLAMA_MODEL = os.getenv(
        "SAGE_OLLAMA_MODEL",
        "llama3.2:3b",
    )

    ROUTING_MODE = os.getenv(
        "SAGE_ROUTING_MODE",
        "auto",
    )

    PREFER_LOCAL = os.getenv(
        "SAGE_PREFER_LOCAL",
        "false",
    ).strip().lower() in {"1", "true", "yes", "on"}


settings = Settings()
