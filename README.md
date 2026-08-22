# LLM SQL Evaluation Benchmark

Evaluates LLMs on Text-to-SQL generation using an IPL (Indian Premier League) cricket database (2021-2024).

## Models Under Test

| Model | Provider |
|-------|----------|
| Gemini 2.0 Flash | OpenRouter (free) |
| Mistral Medium | Mistral AI |
| Groq GPT-OSS-120B | Groq |
| Gemma 4 31B | OpenRouter (free) |
| Qwen Turbo | Alibaba Cloud (OpenAI-compatible) |

## Setup

```bash
# Create virtual environment
uv venv

# Install dependencies
uv pip install -r requirements.txt
```

## Environment Variables

Create a `.env` file in the project root:

```env
OPENROUTER_API_KEY=sk-or-...
MISTRAL_API_KEY=...
GROQ_API_KEY=...
QWEN_API_KEY=...
```

## Database Setup

```bash
# Build SQLite database from CSV data
python db.py

# Extract schema for prompts
python schema_extractor.py
```

## Run Evaluation

```bash
# Full evaluation (all models, all 20 questions)
python main.py

# Quick smoke test (single question, single model)
python first_test.py
```

## How It Works

1. **Schema** - Loaded from `schema.sql` (IPL matches + deliveries tables)
2. **Golden Dataset** - 20 questions with known-correct SQL and expected results (`golden_dataset.csv`)
3. **Generation** - Each model generates SQL for each question
4. **Execution** - Generated SQL runs on local SQLite database
5. **Evaluation** - Results compared using execution accuracy (value-based, flexible column count)

## Results

Outputs:
- Console scoreboard with per-model accuracy
- Detailed results in `eval_results.csv`

## Project Structure

```
llm-sql-eval/
├── main.py                 # Main evaluation pipeline
├── models.py               # Model definitions
├── evaluator.py            # Comparison logic
├── first_test.py           # Quick smoke test
├── db.py                   # Database builder
├── schema_extractor.py     # Schema extractor
├── golden_dataset_generator.py  # Golden dataset source
├── make_golden_dataset.py  # Creates golden_hard.csv
├── schema.sql              # Database schema (for prompts)
├── golden_dataset.csv      # 20 benchmark questions
├── ipl_2021_2024.db        # SQLite database
├── data/
│   ├── matches.csv
│   └── deliveries.csv
├── requirements.txt
└── .env                    # API keys (not tracked)
```

## Evaluation Metric

**Execution Accuracy** - Compares actual query results (not SQL strings). Tolerates:
- Different column names (matches by value)
- Extra count column (e.g., name + count vs just name)
- Float/int equivalence (24395 == 24395.0)