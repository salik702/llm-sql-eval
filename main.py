import sqlite3

import pandas as pd
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
from dotenv import load_dotenv

from evaluator import compare_dataframes

load_dotenv()


DATABASE_PATH = "university_eval.db"
DATASET_PATH = "university_golden_dataset_bare_bone.csv"


# --------------------------------------------------
# 1. Load the golden dataset
# --------------------------------------------------

dataset = pd.read_csv(DATASET_PATH)


# --------------------------------------------------
# 2. Connect to the database
# --------------------------------------------------

connection = sqlite3.connect(DATABASE_PATH)


# --------------------------------------------------
# 3. Read the database schema
# --------------------------------------------------

schema_rows = connection.execute("""
    SELECT sql
    FROM sqlite_master
    WHERE type = 'table'
    AND sql IS NOT NULL
""").fetchall()

schema = "\n\n".join(
    row[0]
    for row in schema_rows
)


# --------------------------------------------------
# 4. Create the LangChain SQL-generation chain
# --------------------------------------------------

prompt = ChatPromptTemplate.from_template("""
You are a SQLite expert.

Database schema:

{schema}

Question:

{question}

Return only the SQLite query.
Do not include an explanation or Markdown.
""")


llm = ChatOpenAI(
    model="gpt-4.1"
)


chain = (
    prompt
    | llm
    | StrOutputParser()
)


# --------------------------------------------------
# 5. Run the evaluation
# --------------------------------------------------

results = []

for _, test_case in dataset.iterrows():

    question = test_case["question"]
    gold_query = test_case["query"]

    order_sensitive = (
        str(test_case["order_sensitive"])
        .strip()
        .lower()
        == "true"
    )

    try:
        # Generate SQL from the LLM.
        generated_query = chain.invoke({
            "schema": schema,
            "question": question,
        })

        # Remove Markdown fences if present.
        generated_query = (
            generated_query
            .replace("```sql", "")
            .replace("```", "")
            .strip()
        )

        # Execute both queries.
        gold_df = pd.read_sql_query(
            gold_query,
            connection,
        )

        generated_df = pd.read_sql_query(
            generated_query,
            connection,
        )

        # Compare the two result tables.
        passed = compare_dataframes(
            gold_df,
            generated_df,
            order_sensitive,
        )

        error = ""

    except Exception as exception:
        passed = False
        error = str(exception)

    results.append({
        "question_id": test_case["question_id"],
        "question": question,
        "gold_query": gold_query,
        "generated_query": generated_query,
        "passed": passed,
        "error": error,
    })

    print(
        test_case["question_id"],
        "PASS" if passed else "FAIL",
    )


# --------------------------------------------------
# 6. Save the results
# --------------------------------------------------

connection.close()

results_df = pd.DataFrame(results)

results_df.to_csv(
    "evaluation_results.csv",
    index=False,
)

accuracy = results_df["passed"].mean()

print("\nEvaluation complete")
print(f"Accuracy: {accuracy:.2%}")