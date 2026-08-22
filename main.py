"""
main.py - controls the entire eval flow.

For each model:
  1. load the model (provider-specific langchain class)
  2. run the golden dataset (generate SQL for each question)
  3. run the generated SQL on the DB (get a result)
  4. evaluate (compare to gold, using evaluator.py)
  5. log the score

Supported providers: mistralai, groq, openrouter, openai_compat

Files it depends on:
  - schema.sql
  - golden_dataset.csv
  - models.py               (model definitions -> MODELS)
  - evaluator.py            (comparison logic)

Setup:
  pip install langchain-mistralai langchain-groq langchain-openrouter langchain-openai python-dotenv pandas
  .env file with:  OPENROUTER_API_KEY=sk-or-...  (and others as needed)
"""

import os
import re
import json
import sqlite3
import pandas as pd
from dotenv import load_dotenv
from langchain_core.messages import SystemMessage, HumanMessage

from models import MODELS
from evaluator import evaluate_one

# ---------- CONFIG ----------
load_dotenv()

DB_PATH = "ipl_2021_2024.db"
SCHEMA_PATH = "schema.sql"
GOLDEN_PATH = "golden_dataset.csv"
RESULTS_PATH = "eval_results.csv"
# ----------------------------


# ---------- LLM factory ----------
def make_llm(model_cfg):
    """Create a langchain chat model based on the provider specified in model_cfg."""
    provider = model_cfg["provider"]
    model = model_cfg["model"]

    if provider == "mistralai":
        from langchain_mistralai import ChatMistralAI
        return ChatMistralAI(model=model, temperature=0, max_tokens=800)

    if provider == "groq":
        from langchain_groq import ChatGroq
        api_key = os.getenv("GROQ_API_KEY")
        return ChatGroq(model=model, groq_api_key=api_key, temperature=0, max_tokens=800)

    if provider == "openrouter":
        from langchain_openrouter import ChatOpenRouter
        api_key = os.getenv("OPENROUTER_API_KEY")
        return ChatOpenRouter(model=model, openrouter_api_key=api_key, temperature=0, max_tokens=800)

    if provider == "openai_compat":
        from langchain_openai import ChatOpenAI
        api_key_env = model_cfg.get("api_key_env", "OPENAI_API_KEY")
        api_key = os.getenv(api_key_env)
        base_url = model_cfg.get("base_url")
        return ChatOpenAI(model=model, api_key=api_key, base_url=base_url, temperature=0, max_tokens=800)

    if provider == "google_genai":
        from langchain_google_genai import ChatGoogleGenerativeAI
        api_key = os.getenv("GOOGLE_API_KEY")
        return ChatGoogleGenerativeAI(model=model, google_api_key=api_key, temperature=0, max_tokens=800)

    raise ValueError(f"Unknown provider: {provider}")


# ---------- helpers ----------
def load_schema():
    with open(SCHEMA_PATH, encoding="utf-8") as f:
        return f.read().strip()


def load_golden():
    return pd.read_csv(GOLDEN_PATH)


def clean_sql(raw):
    """Strip markdown fences / prose, return runnable SQL."""
    if not raw:
        return ""
    text = raw.strip()
    fence = re.search(r"```(?:sql)?\s*(.*?)```", text, re.DOTALL | re.IGNORECASE)
    if fence:
        text = fence.group(1).strip()
    text = re.sub(r"^\s*sql\s*\n", "", text, flags=re.IGNORECASE)
    m = re.search(r"\b(SELECT|WITH)\b", text, re.IGNORECASE)
    if m:
        text = text[m.start():]
    return text.strip().strip("`").rstrip(";").strip("`").strip()


def generate_sql(question, schema, llm):
    """Ask one model for SQL. Returns cleaned SQL string."""
    system_msg = (
        "You are a text-to-SQL generator. Given a database schema and a question, "
        "return a single SQL query that answers it. Use SQLite syntax. "
        "Return only the SQL query."
    )
    user_msg = f"Schema:\n{schema}\n\nQuestion: {question}\n\nSQL:"

    response = llm.invoke([
        SystemMessage(content=system_msg),
        HumanMessage(content=user_msg),
    ])

    raw = response.content
    cleaned = clean_sql(raw)
    if not cleaned:
        print(f"  RAW (uncleaned): {repr(raw)[:300]}")

    return cleaned


def run_sql(conn, sql):
    """Run SQL on the DB. Returns a DataFrame, or None if it errored."""
    try:
        return pd.read_sql_query(sql, conn)
    except Exception:
        return None


def gold_result_to_df(gold_result_json):
    """Rebuild the gold result DataFrame from the stored JSON."""
    obj = json.loads(gold_result_json)
    return pd.DataFrame(obj["rows"], columns=obj["columns"])


# ---------- the main flow ----------
def run_eval():
    schema = load_schema()
    golden = load_golden()
    conn = sqlite3.connect(DB_PATH)

    all_rows = []
    scoreboard = {}

    for model_cfg in MODELS:
        name = model_cfg["name"]
        print(f"\n{'='*60}\nMODEL: {name}  ({model_cfg['provider']}/{model_cfg['model']})\n{'='*60}")

        try:
            llm = make_llm(model_cfg)
        except Exception as e:
            print(f"  FAILED to load model: {e}")
            scoreboard[name] = 0
            continue

        correct = 0

        for _, g in golden.iterrows():
            qid = g["id"]
            question = g["question"]
            order_sensitive = str(g["order_sensitive"]).upper() == "TRUE"
            gold_df = gold_result_to_df(g["gold_result_json"])

            # generate SQL
            try:
                sql = generate_sql(question, schema, llm)
            except Exception as e:
                print(f"  #{qid:2} [{g['difficulty']:6}] GEN-ERROR: {e}")
                all_rows.append(dict(model=name, id=qid, difficulty=g["difficulty"],
                                     correct=False, reason="gen_error", sql=""))
                continue

            # run on DB
            gen_df = run_sql(conn, sql)

            # evaluate
            verdict = evaluate_one(gold_df, gen_df, order_sensitive)
            if verdict["correct"]:
                correct += 1

            mark = "OK " if verdict["correct"] else "XX "
            print(f"  #{qid:2} [{g['difficulty']:6}] {mark} {verdict['reason']}")
            all_rows.append(dict(model=name, id=qid, difficulty=g["difficulty"],
                                 correct=verdict["correct"], reason=verdict["reason"],
                                 sql=sql))

        total = len(golden)
        scoreboard[name] = correct
        print(f"\n  SCORE: {correct}/{total} = {100*correct/total:.1f}%")

    conn.close()

    # final scores
    print(f"\n{'='*60}\nFINAL SCOREBOARD (execution accuracy)\n{'='*60}")
    total = len(golden)
    for model_cfg in MODELS:
        c = scoreboard.get(model_cfg["name"], 0)
        print(f"  {model_cfg['name']:25s} {c:2}/{total}  = {100*c/total:5.1f}%")

    pd.DataFrame(all_rows).to_csv(RESULTS_PATH, index=False)
    print(f"\nDetailed results saved -> {RESULTS_PATH}")


if __name__ == "__main__":
    run_eval()
