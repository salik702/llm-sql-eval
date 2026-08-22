"""
models.py - Model definitions for evaluation.

Each model is a dict with:
  name      - display name
  provider  - which langchain class to use
  model     - model identifier / slug
  extra     - extra kwargs (base_url, api_key env var, etc.)
"""

MODELS = [
    {
        "name": "Gemini 2.0 Flash (OpenRouter)",
        "provider": "openrouter",
        "model": "google/gemini-2.0-flash-exp:free",
    },
    {
        "name": "Mistral Medium",
        "provider": "mistralai",
        "model": "mistral-medium-latest",
    },
    {
        "name": "Groq GPT-OSS-120B",
        "provider": "groq",
        "model": "openai/gpt-oss-120b",
    },
    {
        "name": "Gemma 4 31B",
        "provider": "openrouter",
        "model": "google/gemma-4-31b-it:free",
    },
    {
        "name": "Qwen Turbo",
        "provider": "openai_compat",
        "model": "qwen-turbo",
        "base_url": "https://dashscope-intl.aliyuncs.com/compatible-mode/v1",
        "api_key_env": "QWEN_API_KEY",
    },

]

if __name__ == "__main__":
    print(f"{len(MODELS)} models under test:")
    for m in MODELS:
        print(f"  {m['name']:25s} [{m['provider']:14s}] {m['model']}")
